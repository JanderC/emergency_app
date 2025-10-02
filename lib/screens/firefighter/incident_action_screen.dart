import 'package:flutter/material.dart';
import 'package:app_emergency/services/incident_service.dart';
import 'package:app_emergency/services/ambulance_service.dart';
import 'package:app_emergency/services/emergency_services.dart';
import 'package:app_emergency/services/firefighter_service.dart';
import 'package:app_emergency/models/incident.dart';
import 'package:app_emergency/models/ambulance.dart';
import 'package:provider/provider.dart';
import 'package:app_emergency/services/auth_service.dart';
import 'dart:convert';
import 'dart:typed_data';

class IncidentActionScreen extends StatefulWidget {
  final String incidentId;
  
  const IncidentActionScreen({
    super.key,
    required this.incidentId,
  });

  @override
  State<IncidentActionScreen> createState() => _IncidentActionScreenState();
}

class _IncidentActionScreenState extends State<IncidentActionScreen> {
  final IncidentService _incidentService = IncidentService();
  final AmbulanceService _ambulanceService = AmbulanceService();
  final EmergencyService _emergencyService = EmergencyService();
  final FirefighterService _firefighterService = FirefighterService();
  
  bool _isLoading = true;
  bool _isUpdating = false;
  String _error = '';
  Incident? _incident;
  List<Ambulance> _availableAmbulances = [];
  Ambulance? _selectedAmbulance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final incident = await _incidentService.getIncidentById(widget.incidentId);
      final ambulances = await _ambulanceService.getAmbulances(
        filters: {'disponible': 'true'},
      );
      
      setState(() {
        _incident = incident;
        _availableAmbulances = ambulances;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Convierte una imagen base64 a bytes para mostrarla
  Uint8List? _decodeBase64Image(String base64String) {
    try {
      String base64Data = base64String;
      if (base64String.contains(',')) {
        base64Data = base64String.split(',')[1];
      }
      return base64Decode(base64Data);
    } catch (e) {
      print('Error decodificando imagen base64: $e');
      return null;
    }
  }

  /// Muestra una imagen en pantalla completa
  void _showFullImage(String base64Image, int index) {
    final imageBytes = _decodeBase64Image(base64Image);
    if (imageBytes == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text('Imagen ${index + 1} de ${_incident!.imagenes.length}'),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _takeIncident() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final result = await _emergencyService.takeEmergency(widget.incidentId);

      if (mounted) {
        if (result['success']) {
          if (_selectedAmbulance != null) {
            await _ambulanceService.assignAmbulance(_selectedAmbulance!.id);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(result['message']),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(result['message'])),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _completeIncident() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await _firefighterService.completeIncident(widget.incidentId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Emergencia completada exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _releaseIncident() async {
    final reason = await _showReleaseDialog();
    if (reason == null || reason.isEmpty) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final result = await _emergencyService.releaseEmergency(widget.incidentId, reason);
      
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(result['message']),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<String?> _showReleaseDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Liberar Emergencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Indica el motivo por el cual liberas esta emergencia:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Motivo de liberación',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Liberar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bomberoId = Provider.of<AuthService>(context).userId;
    final isAssignedToBombero = _incident?.bomberoAsignadoId == bomberoId;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Gestionar Emergencia'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(isAssignedToBombero),
    );
  }

  Widget _buildBody(bool isAssignedToBombero) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.red),
      );
    }

    if (_error.isNotEmpty) {
      return _buildErrorState();
    }

    if (_incident == null) {
      return const Center(
        child: Text('No se encontró el incidente'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildStatusHeader(),
                const SizedBox(height: 16),
                _buildIncidentInfo(),
                const SizedBox(height: 16),
                _buildLocationInfo(),
                const SizedBox(height: 16),
                _buildImages(),
                if (_incident!.estado == 'reportado') ...[
                  const SizedBox(height: 16),
                  _buildAmbulanceSelection(),
                ],
                if (_incident!.bomberoAsignadoId != null || _incident!.ambulanciaId != null) ...[
                  const SizedBox(height: 16),
                  _buildAssignmentInfo(),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        _buildActionButtons(isAssignedToBombero),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar los datos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_error, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade600, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _getStatusColor(_incident!.estado),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _incident!.estado.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _incident!.tipoEmergencia.replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentInfo() {
    return _buildCard(
      title: 'Información de la Emergencia',
      icon: Icons.info_outline,
      children: [
        _buildInfoRow('Descripción', _incident!.descripcion, Icons.description),
        const Divider(height: 24),
        _buildInfoRow(
          'Nivel de Urgencia',
          _incident!.nivelUrgencia.toUpperCase(),
          Icons.priority_high,
          valueColor: _getUrgencyColor(_incident!.nivelUrgencia),
        ),
        const Divider(height: 24),
        _buildInfoRow(
          'Fecha de Reporte',
          _formatDate(_incident!.fechaReporte),
          Icons.calendar_today,
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return _buildCard(
      title: 'Ubicación',
      icon: Icons.location_on,
      children: [
        _buildInfoRow('Dirección', _incident!.ubicacion, Icons.place),
        const Divider(height: 24),
        _buildInfoRow(
          'Coordenadas',
          '${_incident!.latitud}, ${_incident!.longitud}',
          Icons.map,
        ),
      ],
    );
  }

  Widget _buildImages() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.photo_library, color: Colors.red.shade600, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Evidencia Fotográfica',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  if (_incident!.imagenes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_incident!.imagenes.length}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_incident!.imagenes.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sin evidencia fotográfica',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _incident!.imagenes.length,
                        itemBuilder: (context, index) {
                          final base64Image = _incident!.imagenes[index];
                          final imageBytes = _decodeBase64Image(base64Image);

                          return GestureDetector(
                            onTap: () => _showFullImage(base64Image, index),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imageBytes != null
                                    ? Stack(
                                        children: [
                                          Image.memory(
                                            imageBytes,
                                            height: 120,
                                            width: 120,
                                            fit: BoxFit.cover,
                                          ),
                                          Positioned(
                                            bottom: 4,
                                            right: 4,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.6),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${index + 1}/${_incident!.imagenes.length}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned.fill(
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () => _showFullImage(base64Image, index),
                                                child: Center(
                                                  child: Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withOpacity(0.5),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.zoom_in,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Container(
                                        height: 120,
                                        width: 120,
                                        color: Colors.grey.shade300,
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toca una imagen para verla en tamaño completo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmbulanceSelection() {
    return _buildCard(
      title: 'Seleccionar Ambulancia',
      icon: Icons.local_hospital,
      children: [
        if (_availableAmbulances.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade600),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('No hay ambulancias disponibles en este momento'),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<Ambulance>(
            decoration: InputDecoration(
              labelText: 'Ambulancia (opcional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            hint: const Text('Seleccionar ambulancia'),
            value: _selectedAmbulance,
            items: _availableAmbulances.map((ambulance) {
              return DropdownMenuItem<Ambulance>(
                value: ambulance,
                child: Text(
                  '${ambulance.placa}${ambulance.modelo != null ? " - ${ambulance.modelo}" : ""}',
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedAmbulance = value;
              });
            },
          ),
      ],
    );
  }

  Widget _buildAssignmentInfo() {
    return _buildCard(
      title: 'Información de Asignación',
      icon: Icons.assignment_ind,
      children: [
        if (_incident!.bomberoAsignadoId != null)
          _buildInfoRow(
            'Bombero Asignado',
            'ID: ${_incident!.bomberoAsignadoId}',
            Icons.person,
          ),
        if (_incident!.ambulanciaId != null) ...[
          if (_incident!.bomberoAsignadoId != null) const Divider(height: 24),
          _buildInfoRow(
            'Ambulancia Asignada',
            'ID: ${_incident!.ambulanciaId}',
            Icons.local_hospital,
          ),
        ],
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.red.shade600, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: valueColor ?? Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isAssignedToBombero) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_incident!.estado == 'reportado') ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isUpdating ? null : _takeIncident,
                icon: _isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.assignment_turned_in),
                label: const Text(
                  'Tomar Emergencia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
          if (_incident!.estado == 'en_proceso' && isAssignedToBombero) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isUpdating ? null : _completeIncident,
                icon: _isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle),
                label: const Text(
                  'Completar Emergencia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isUpdating ? null : _releaseIncident,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Liberar Emergencia'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'reportado':
        return Colors.orange.shade600;
      case 'en_proceso':
        return Colors.blue.shade600;
      case 'completado':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getUrgencyColor(String urgencia) {
    switch (urgencia.toLowerCase()) {
      case 'alta':
        return Colors.red.shade600;
      case 'media':
        return Colors.orange.shade600;
      case 'baja':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}