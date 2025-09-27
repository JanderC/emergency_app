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
          if (_incident!.imagenes.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildImages(),
          ],
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
          Text(
            'Imágenes de la Emergencia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _incident!.imagenes.length,
              itemBuilder: (context, index) {
                return Container(
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
                          child: const Icon(Icons.broken_image),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
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