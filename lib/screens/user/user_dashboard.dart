// lib/screens/user/user_dashboard.dart
import 'package:app_emergency/models/incident.dart';
import 'package:app_emergency/screens/user/incident_details_screen.dart';
import 'package:app_emergency/screens/user/report_incident_screen.dart';
import 'package:app_emergency/screens/user/user_profile_screen.dart';
import 'package:app_emergency/services/auth_service.dart';
import 'package:app_emergency/services/incident_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final IncidentService _incidentService = IncidentService();
  List<Incident> _incidents = [];
  bool _isLoading = true;
  String _error = '';

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
      final userId = Provider.of<AuthService>(context, listen: false).userId;
      print('Cargando incidentes para el usuario: $userId');
      
      if (userId == null) {
        throw Exception('ID de usuario no disponible');
      }
      
      final incidents = await _incidentService.getIncidents(
        filters: {'usuario_id': userId},
      );
      
      print('Incidentes cargados: ${incidents.length}');
      
      setState(() {
        _incidents = incidents;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar incidentes: $e');
      setState(() {
        _error = 'Error al cargar incidentes: $e';
        _isLoading = false;
      });
    }
  }

  void _logout() {
    Provider.of<AuthService>(context, listen: false).logout();
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    print('Construyendo UserDashboard para: ${user?.nombreCompleto}');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Usuario'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
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
          // Bienvenida al usuario
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red.shade50,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.red.shade100,
                  radius: 30,
                  child: Text(
                    user?.nombre.substring(0, 1) ?? 'U',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenido, ${user?.nombre ?? 'Usuario'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Aquí puedes ver y reportar emergencias',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
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
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No tienes incidentes reportados',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ReportIncidentScreen(),
                                        ),
                                      ).then((_) => _loadIncidents());
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Reportar una emergencia'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
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
                                          builder: (context) => IncidentDetailsScreen(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReportIncidentScreen(),
            ),
          ).then((_) => _loadIncidents());
        },
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
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