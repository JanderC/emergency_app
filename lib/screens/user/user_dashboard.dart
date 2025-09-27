import 'package:app_emergency/models/incident.dart';
import 'package:app_emergency/screens/user/incident_details_screen.dart';
import 'package:app_emergency/screens/user/report_incident_screen.dart';
import 'package:app_emergency/screens/user/user_profile_screen.dart';
import 'package:app_emergency/services/auth_service.dart';
import 'package:app_emergency/services/incident_service.dart';
import 'package:app_emergency/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final IncidentService _incidentService = IncidentService();
  final UserService _userService = UserService();
  
  List<Incident> _incidents = [];
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String _error = '';
  int _selectedFilter = 0; // 0: Todos, 1: Activos, 2: Completados

  final List<String> _filterLabels = ['Todos', 'Activos', 'Completados'];

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
        _loadNotifications(),
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
      Map<String, String>? filters;
      
      switch (_selectedFilter) {
        case 1: // Activos
          filters = {'estado': 'reportado,en_proceso'};
          break;
        case 2: // Completados
          filters = {'estado': 'completado'};
          break;
        default: // Todos
          filters = null;
      }

      final incidents = await _incidentService.getIncidents(filters: filters);
      setState(() {
        _incidents = incidents;
      });
    } catch (e) {
      print('Error al cargar incidentes: $e');
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _userService.getUserNotifications(soloNoLeidas: true);
      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      print('Error al cargar notificaciones: $e');
    }
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      await _userService.markNotificationAsRead(notificationId);
      _loadNotifications();
    } catch (e) {
      print('Error al marcar notificación: $e');
    }
  }

  void _onFilterChanged(int index) {
    setState(() {
      _selectedFilter = index;
    });
    _loadIncidents();
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
          SliverToBoxAdapter(child: _buildNotificationsBanner()),
          SliverToBoxAdapter(child: _buildQuickActions()),
          SliverToBoxAdapter(child: _buildFilterTabs()),
          _buildIncidentsList(),
        ],
      ),
      floatingActionButton: _buildFAB(),
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
                child: Text(
                  user?.nombre.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hola, ${user?.nombre ?? 'Usuario'}',
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
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: _showNotifications,
            ),
            if (_notifications.isNotEmpty)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '${_notifications.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserProfileScreen()),
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

  Widget _buildNotificationsBanner() {
    if (_notifications.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8), // Reducido el margin bottom
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active, color: Colors.orange.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tienes ${_notifications.length} notificación${_notifications.length == 1 ? '' : 'es'} nueva${_notifications.length == 1 ? '' : 's'}',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _showNotifications,
            child: const Text('Ver'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap( // Cambiar Row por Wrap para evitar overflow
        spacing: 10,
        runSpacing: 10,
        children: [
          SizedBox(
            width: (MediaQuery.of(context).size.width - 52) / 3, // Calcular ancho dinámicamente
            child: _buildQuickActionCard(
              'Reportar',
              'Emergencia',
              Icons.add_circle,
              Colors.red,
              () => _navigateToReport(),
            ),
          ),
          SizedBox(
            width: (MediaQuery.of(context).size.width - 52) / 3,
            child: _buildQuickActionCard(
              'Mis',
              'Incidentes',
              Icons.list_alt,
              Colors.blue,
              () => _onFilterChanged(1),
            ),
          ),
          SizedBox(
            width: (MediaQuery.of(context).size.width - 52) / 3,
            child: _buildQuickActionCard(
              'Historial',
              'Completo',
              Icons.history,
              Colors.green,
              () => _onFilterChanged(0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80, // Altura fija para evitar overflow
        padding: const EdgeInsets.all(8),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
      onTap: () => _navigateToDetails(incident.id),
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
                    child: Text(
                      'Urgencia: ${incident.nivelUrgencia.toUpperCase()}',
                      style: TextStyle(
                        color: _getUrgencyColor(incident.nivelUrgencia),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 0
                  ? 'No tienes incidentes reportados'
                  : _selectedFilter == 1
                      ? 'No tienes incidentes activos'
                      : 'No tienes incidentes completados',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToReport,
              icon: const Icon(Icons.add),
              label: const Text('Reportar Emergencia'),
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

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _navigateToReport,
      backgroundColor: Colors.red.shade600,
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
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
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportIncidentScreen()),
    ).then((_) => _loadDashboardData());
  }

  void _navigateToDetails(String incidentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncidentDetailsScreen(incidentId: incidentId),
      ),
    ).then((_) => _loadDashboardData());
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Notificaciones',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return ListTile(
                        leading: const Icon(Icons.notifications),
                        title: Text(notification['titulo'] ?? 'Notificación'),
                        subtitle: Text(notification['mensaje'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () => _markNotificationAsRead(notification['id']),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}