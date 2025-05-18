import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_emergency/services/auth_service.dart';
import 'package:app_emergency/services/incident_service.dart';
import 'package:app_emergency/models/incident.dart';
import 'package:app_emergency/screens/firefighter/firefighter_profile_screen.dart';
import 'package:app_emergency/screens/firefighter/incident_action_screen.dart';
import 'package:app_emergency/screens/firefighter/ambulance_management_screen.dart';

class FirefighterDashboard extends StatefulWidget {
  const FirefighterDashboard({super.key});

  @override
  State<FirefighterDashboard> createState() => _FirefighterDashboardState();
}

class _FirefighterDashboardState extends State<FirefighterDashboard> {
  final IncidentService _incidentService = IncidentService();
  List<Incident> _incidents = [];
  bool _isLoading = true;
  String _error = '';
  String _filter = 'pendiente'; // Por defecto, mostrar incidentes pendientes

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final incidents = await _incidentService.getIncidents(
        filters: {'estado': _filter},
      );
      
      setState(() {
        _incidents = incidents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar incidentes: $e';
        _isLoading = false;
      });
    }
  }

  void _logout() {
    Provider.of<AuthService>(context, listen: false).logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Bombero'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.local_hospital),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AmbulanceManagementScreen(),
                ),
              ).then((_) => _loadIncidents());
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FirefighterProfileScreen(),
                ),
              ).then((_) => _loadIncidents());
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Filtrar por: '),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Pendientes'),
                  selected: _filter == 'pendiente',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filter = 'pendiente';
                      });
                      _loadIncidents();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('En proceso'),
                  selected: _filter == 'en proceso',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filter = 'en proceso';
                      });
                      _loadIncidents();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Completados'),
                  selected: _filter == 'completado',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filter = 'completado';
                      });
                      _loadIncidents();
                    }
                  },
                ),
              ],
            ),
          ),
          
          // Lista de incidentes
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadIncidents,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                      ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
                      : _incidents.isEmpty
                          ? Center(child: Text('No hay incidentes ${_getFilterText()}'))
                          : ListView.builder(
                              itemCount: _incidents.length,
                              itemBuilder: (ctx, index) {
                                final incident = _incidents[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    leading: _getIncidentIcon(incident.tipoEmergencia),
                                    title: Text(incident.tipoEmergencia),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(incident.ubicacion),
                                        Text(
                                          'Urgencia: ${incident.nivelUrgencia.toUpperCase()}',
                                          style: TextStyle(
                                            color: _getUrgencyColor(incident.nivelUrgencia),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: _getStatusChip(incident.estado),
                                    isThreeLine: true,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => IncidentActionScreen(
                                            incidentId: incident.id,
                                          ),
                                        ),
                                      ).then((_) => _loadIncidents());
                                    },
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterText() {
    switch (_filter) {
      case 'pendiente':
        return 'pendientes';
      case 'en proceso':
        return 'en proceso';
      case 'completado':
        return 'completados';
      default:
        return '';
    }
  }

  Widget _getIncidentIcon(String tipoEmergencia) {
    IconData iconData;
    
    switch (tipoEmergencia.toLowerCase()) {
      case 'incendio':
        iconData = Icons.local_fire_department;
        break;
      case 'accidente':
        iconData = Icons.car_crash;
        break;
      case 'emergencia médica':
        iconData = Icons.medical_services;
        break;
      default:
        iconData = Icons.warning;
    }
    
    return CircleAvatar(
      backgroundColor: Colors.red.shade100,
      child: Icon(iconData, color: Colors.red),
    );
  }

  Widget _getStatusChip(String estado) {
    Color color;
    
    switch (estado.toLowerCase()) {
      case 'pendiente':
        color = Colors.orange;
        break;
      case 'en proceso':
        color = Colors.blue;
        break;
      case 'completado':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    
    return Chip(
      label: Text(
        estado,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }

  Color _getUrgencyColor(String nivelUrgencia) {
    switch (nivelUrgencia.toLowerCase()) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baja':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
