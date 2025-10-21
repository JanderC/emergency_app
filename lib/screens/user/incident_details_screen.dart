import 'package:flutter/material.dart';
import 'package:app_emergency/services/incident_service.dart';
import 'package:app_emergency/models/incident.dart';
import 'dart:convert';
import 'dart:typed_data';

class IncidentDetailsScreen extends StatefulWidget {
  final String incidentId;

  const IncidentDetailsScreen({
    super.key,
    required this.incidentId,
  });

  @override
  State<IncidentDetailsScreen> createState() => _IncidentDetailsScreenState();
}

class _IncidentDetailsScreenState extends State<IncidentDetailsScreen> {
  final IncidentService _incidentService = IncidentService();
  bool _isLoading = true;
  String _error = '';
  Incident? _incident;

  @override
  void initState() {
    super.initState();
    _loadIncidentDetails();
  }

  Future<void> _loadIncidentDetails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final incident = await _incidentService.getIncidentById(widget.incidentId);
      setState(() {
        _incident = incident;
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
      // Si la cadena tiene el prefijo data:image, quitarlo
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Detalles de Emergencia'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStatusHeader(),
          const SizedBox(height: 16),
          _buildMainInfo(),
          const SizedBox(height: 16),
          _buildLocationInfo(),
          const SizedBox(height: 16),
          _buildTimestamps(),
          if (_incident!.bomberoAsignadoId != null || _incident!.ambulanciaId != null)
            ...[
              const SizedBox(height: 16),
              _buildAssignmentInfo(),
            ],
          const SizedBox(height: 16),
          _buildImages(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar los detalles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadIncidentDetails,
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
            _incident!.tipoEmergencia.toUpperCase(),
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

  Widget _buildMainInfo() {
    return _buildCard(
      title: 'Información Principal',
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

  Widget _buildTimestamps() {
    return _buildCard(
      title: 'Fechas',
      icon: Icons.schedule,
      children: [
        _buildInfoRow(
          'Fecha de Reporte',
          _formatDate(_incident!.fechaReporte),
          Icons.calendar_today,
        ),
        if (_incident!.fechaAtencion != null) ...[
          const Divider(height: 24),
          _buildInfoRow(
            'Fecha de Atención',
            _formatDate(_incident!.fechaAtencion!),
            Icons.check_circle,
          ),
        ],
      ],
    );
  }

  Widget _buildAssignmentInfo() {
    return _buildCard(
      title: 'Asignación',
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

  Widget _buildImages() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library, color: Colors.red.shade600, size: 24),
              const SizedBox(width: 12),
              Text(
                'Imágenes de la Emergencia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                    'No hay imágenes adjuntas',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
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
          if (_incident!.imagenes.isNotEmpty) ...[
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
        ],
      ),
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