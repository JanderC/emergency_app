import 'package:flutter/material.dart';
import 'package:app_emergency/services/incident_service.dart';
import 'package:app_emergency/models/incident.dart';

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
      print('Cargando detalles del incidente: ${widget.incidentId}');
      final incident = await _incidentService.getIncidentById(widget.incidentId);
      print('Detalles del incidente cargados: ${incident.tipoEmergencia}');

      setState(() {
        _incident = incident;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar detalles: $e');
      setState(() {
        _error = 'Error al cargar detalles: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Emergencia'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
              : _incident == null
                  ? const Center(child: Text('No se encontró el incidente'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(_incident!.estado),
                                borderRadius: BorderRadius.circular(20),
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
                          ),
                          const SizedBox(height: 24),

                          // Información principal
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoSection('Tipo de Emergencia', _incident!.tipoEmergencia, Icons.warning),
                                  const Divider(),
                                  _buildInfoSection('Descripción', _incident!.descripcion, Icons.description),
                                  const Divider(),
                                  _buildInfoSection('Ubicación', _incident!.ubicacion, Icons.location_on),
                                  const Divider(),
                                  _buildInfoSection(
                                    'Coordenadas',
                                    '${_incident!.latitud}, ${_incident!.longitud}',
                                    Icons.map,
                                  ),
                                  const Divider(),
                                  _buildInfoSection(
                                    'Nivel de Urgencia',
                                    _incident!.nivelUrgencia.toUpperCase(),
                                    Icons.priority_high,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Fechas
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Fechas',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoSection(
                                    'Fecha de Reporte',
                                    _formatDate(_incident!.fechaReporte),
                                    Icons.calendar_today,
                                  ),
                                  if (_incident!.fechaAtencion != null) ...[
                                    const Divider(),
                                    _buildInfoSection(
                                      'Fecha de Atención',
                                      _formatDate(_incident!.fechaAtencion!),
                                      Icons.check_circle,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Asignación
                          if (_incident!.bomberoAsignadoId != null || _incident!.ambulanciaId != null)
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Asignación',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    if (_incident!.bomberoAsignadoId != null)
                                      _buildInfoSection(
                                        'Bombero Asignado',
                                        'ID: ${_incident!.bomberoAsignadoId}',
                                        Icons.person,
                                      ),
                                    if (_incident!.ambulanciaId != null)
                                      _buildInfoSection(
                                        'Ambulancia Asignada',
                                        'ID: ${_incident!.ambulanciaId}',
                                        Icons.local_hospital,
                                      ),
                                  ],
                                ),
                              ),
                            ),

                          // Imágenes
                          if (_incident!.imagenes.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Text(
                              'Imágenes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _incident!.imagenes.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Image.network(
                                      _incident!.imagenes[index],
                                      height: 120,
                                      width: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: 120,
                                          width: 120,
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.error),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.red),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'en proceso':
        return Colors.blue;
      case 'completado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
