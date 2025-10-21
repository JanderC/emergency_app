// lib/screens/firefighter/quick_report_action_screen.dart
import 'package:flutter/material.dart';
import 'package:app_emergency/services/quick_report_service.dart';
import 'package:app_emergency/models/quick_report.dart';
import 'package:provider/provider.dart';
import 'package:app_emergency/services/auth_service.dart';
import 'dart:convert';
import 'dart:typed_data';

class QuickReportActionScreen extends StatefulWidget {
  final String reportId;
  
  const QuickReportActionScreen({
    super.key,
    required this.reportId,
  });

  @override
  State<QuickReportActionScreen> createState() => _QuickReportActionScreenState();
}

class _QuickReportActionScreenState extends State<QuickReportActionScreen> {
  final QuickReportService _quickReportService = QuickReportService();
  
  bool _isLoading = true;
  bool _isUpdating = false;
  String _error = '';
  QuickReport? _report;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Obtener el reporte específico por ID
      final report = await _quickReportService.getReportById(widget.reportId);
      
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

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

  void _showFullImage(String base64Image) {
    final imageBytes = _decodeBase64Image(base64Image);
    if (imageBytes == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Evidencia Fotográfica'),
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

  Future<void> _takeReport() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final userId = Provider.of<AuthService>(context, listen: false).userId;
      
      final result = await _quickReportService.assignFirefighter(
        widget.reportId,
        userId!,
      );

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(result['message'])),
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

  Future<void> _completeReport() async {
    final notes = await _showNotesDialog();
    
    setState(() {
      _isUpdating = true;
    });

    try {
      final result = await _quickReportService.completeReport(
        widget.reportId,
        notas: notes,
      );
      
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Reporte completado exitosamente'),
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

  Future<String?> _showNotesDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Completar Reporte Rápido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Agrega notas sobre la atención brindada (opcional):'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Notas de atención',
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Completar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<AuthService>(context).userId;
    final isAssignedToMe = _report?.bomberoAsignadoId == userId;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Reporte Rápido'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(isAssignedToMe),
    );
  }

  Widget _buildBody(bool isAssignedToMe) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.purple),
      );
    }

    if (_error.isNotEmpty) {
      return _buildErrorState();
    }

    if (_report == null) {
      return const Center(
        child: Text('No se encontró el reporte'),
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
                _buildReportInfo(),
                const SizedBox(height: 16),
                _buildLocationInfo(),
                const SizedBox(height: 16),
                _buildPhotoSection(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        _buildActionButtons(isAssignedToMe),
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
              onPressed: _loadReport,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
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
          colors: [Colors.purple.shade600, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flash_on, color: Colors.purple.shade600, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'REPORTE RÁPIDO',
                  style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _report!.tipoEmergencia.replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(_report!.estado),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _report!.estado.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportInfo() {
    return _buildCard(
      title: 'Información del Reporte',
      icon: Icons.info_outline,
      children: [
        _buildInfoRow(
          'Tipo de Emergencia',
          _report!.tipoEmergencia.replaceAll('_', ' ').toUpperCase(),
          Icons.warning_amber,
        ),
        const Divider(height: 24),
        _buildInfoRow(
          'Fecha de Reporte',
          _formatFullDate(_report!.fechaReporte),
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
        _buildInfoRow('Dirección', _report!.direccion, Icons.place),
        if (_report!.lat != null && _report!.lng != null) ...[
          const Divider(height: 24),
          _buildInfoRow(
            'Coordenadas',
            '${_report!.lat!.toStringAsFixed(6)}, ${_report!.lng!.toStringAsFixed(6)}',
            Icons.map,
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoSection() {
    final imageBytes = _decodeBase64Image(_report!.foto);

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
                  Icon(Icons.photo_library, color: Colors.purple.shade600, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Evidencia Fotográfica',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (imageBytes != null)
                GestureDetector(
                  onTap: () => _showFullImage(_report!.foto),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.memory(
                          imageBytes,
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Toca para ampliar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No se pudo cargar la imagen'),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
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
                Icon(icon, color: Colors.purple.shade600, size: 24),
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

  Widget _buildActionButtons(bool isAssignedToMe) {
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
          if (_report!.estado == 'pendiente') ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isUpdating ? null : _takeReport,
                icon: _isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.assignment_turned_in),
                label: const Text(
                  'Tomar Reporte',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
          if (_report!.estado == 'asignado' && isAssignedToMe) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isUpdating ? null : _completeReport,
                icon: _isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: const Text(
                  'Completar Reporte',
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
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange.shade600;
      case 'asignado':
        return Colors.blue.shade600;
      case 'atendido':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatFullDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}