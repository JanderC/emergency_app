import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_emergency/services/auth_service.dart';
import 'package:app_emergency/services/incident_service.dart';
import 'package:app_emergency/services/emergency_services.dart';
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
  final EmergencyService _emergencyService = EmergencyService();
  
  List<Incident> _incidents = [];
  List<Incident> _myEmergencies = [];
  bool _isLoading = true;
  String _error = '';
  int _selectedFilter = 0; // 0: Disponibles, 1: Mis emergencias, 2: Completados

  final List<String> _filterLabels = ['Disponibles', 'Mis Emergencias', 'Completados'];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await Future.wait([
        _loadIncidents(),
        _loadMyEmergencies(),
      ]);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadIncidents() async {
    try {
      List<Incident> incidents;
      
      switch (_selectedFilter) {
        case 0: // Disponibles
          incidents = await _emergencyService.getAvailableEmergencies();
          break;
        case 1: // Mis emergencias
          incidents = await _emergencyService.getMyEmergencies();
          break;
        case 2: // Completados
          incidents = await _emergencyService.getMyEmergencies(estado: 'completado');
          break;
        default:
          incidents = await _emergencyService.getAvailableEmergencies();
      }

      setState(() {
        _incidents = incidents;
      });
    } catch (e) {
      print('Error al cargar incidentes: $e');
    }
  }

  Future<void> _loadMyEmergencies() async {
    try {
      final myEmergencies = await _emergencyService.getMyEmergencies(estado: 'en_proceso');
      setState(() {
        _myEmergencies = myEmergencies;
      });
    } catch (e) {
      print('Error al cargar mis emergencias: $e');
    }
  }

  Future<void> _onFilterChanged(int index) async {
    setState(() {
      _selectedFilter = index;
    });
    await _loadIncidents();
  }

  void _logout() {
    Provider.of<AuthService>(context, listen: false).logout();
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(user),
          SliverToBoxAdapter(child: _buildQuickStats()),
          SliverToBoxAdapter(child: _buildQuickActions()),
          SliverToBoxAdapter(child: _buildFilterTabs()),
          _buildIncidentsList(),
        ],
      ),
    );
  }

  Widget _buildAppBar(user) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.red.shade600,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade600, Colors.red.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(
                  Icons.local_fire_department,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Bombero ${user?.nombre ?? 'Usuario'}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Sistema de Emergencias Bomberos Rubio',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.local_hospital, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AmbulanceManagementScreen()),
            ).then((_) => _loadDashboardData());
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FirefighterProfileScreen()),
                ).then((_) => _loadDashboardData());
                break;
              case 'logout':
                _logout();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 8),
                  Text('Mi Perfil'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Cerrar Sesión'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Disponibles',
              _selectedFilter == 0 ? _incidents.length.toString() : '0',
              Icons.assignment,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'En Proceso',
              _myEmergencies.length.toString(),
              Icons.assignment_turned_in,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Ambulancias',
              'Gestionar',
              Icons.local_hospital,
              Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AmbulanceManagementScreen()),
                ).then((_) => _loadDashboardData());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              'Emergencias',
              'Disponibles',
              Icons.warning_amber,
              Colors.red,
              () => _onFilterChanged(0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              'Mis',
              'Asignaciones',
              Icons.assignment_ind,
              Colors.blue,
              () => _onFilterChanged(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(_filterLabels.length, (index) {
          final isSelected = _selectedFilter == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onFilterChanged(index),
              child: Container(
                margin: EdgeInsets.only(right: index < _filterLabels.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red.shade600 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.red.shade600 : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  _filterLabels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildIncidentsList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    if (_error.isNotEmpty) {
      return SliverFillRemaining(
        child: _buildErrorState(),
      );
    }

    if (_incidents.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final incident = _incidents[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildIncidentCard(incident),
            );
          },
          childCount: _incidents.length,
        ),
      ),
    );
  }

  Widget _buildIncidentCard(Incident incident) {
    return GestureDetector(
      onTap: () => _navigateToAction(incident.id),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getIncidentIcon(incident.tipoEmergencia),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incident.tipoEmergencia.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          incident.ubicacion,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _getStatusChip(incident.estado),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                incident.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getUrgencyColor(incident.nivelUrgencia).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.priority_high,
                          size: 16,
                          color: _getUrgencyColor(incident.nivelUrgencia),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          incident.nivelUrgencia.toUpperCase(),
                          style: TextStyle(
                            color: _getUrgencyColor(incident.nivelUrgencia),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(incident.fechaReporte),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
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
              onPressed: _loadDashboardData,
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

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    switch (_selectedFilter) {
      case 0:
        message = 'No hay emergencias disponibles';
        icon = Icons.check_circle_outline;
        break;
      case 1:
        message = 'No tienes emergencias asignadas';
        icon = Icons.assignment_outlined;
        break;
      case 2:
        message = 'No tienes emergencias completadas';
        icon = Icons.history;
        break;
      default:
        message = 'No hay datos disponibles';
        icon = Icons.inbox_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
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

  Widget _getIncidentIcon(String tipoEmergencia) {
    IconData iconData;
    Color color;
    
    switch (tipoEmergencia.toLowerCase()) {
      case 'incendio':
        iconData = Icons.local_fire_department;
        color = Colors.red;
        break;
      case 'rescate':
        iconData = Icons.person_pin_circle;
        color = Colors.blue;
        break;
      case 'accidente_vehicular':
        iconData = Icons.car_crash;
        color = Colors.orange;
        break;
      case 'emergencia_medica':
        iconData = Icons.medical_services;
        color = Colors.purple;
        break;
      case 'inundacion':
        iconData = Icons.water;
        color = Colors.blue.shade700;
        break;
      case 'temblor':
        iconData = Icons.landscape;
        color = Colors.brown;
        break;
      case 'explosion':
        iconData = Icons.flash_on;
        color = Colors.yellow.shade700;
        break;
      case 'fuga_gas':
        iconData = Icons.cloud;
        color = Colors.grey;
        break;
      default:
        iconData = Icons.warning;
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  Widget _getStatusChip(String estado) {
    Color color;
    String label;
    
    switch (estado.toLowerCase()) {
      case 'reportado':
        color = Colors.orange;
        label = 'Reportado';
        break;
      case 'en_proceso':
        color = Colors.blue;
        label = 'En Proceso';
        break;
      case 'completado':
        color = Colors.green;
        label = 'Completado';
        break;
      default:
        color = Colors.grey;
        label = estado;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToAction(String incidentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncidentActionScreen(incidentId: incidentId),
      ),
    ).then((_) => _loadDashboardData());
  }
}