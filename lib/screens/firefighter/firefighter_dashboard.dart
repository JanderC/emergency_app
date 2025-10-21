import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_emergency/services/auth_service.dart';
import 'package:app_emergency/services/incident_service.dart';
import 'package:app_emergency/services/emergency_services.dart';
import 'package:app_emergency/services/quick_report_service.dart';
import 'package:app_emergency/models/incident.dart';
import 'package:app_emergency/models/quick_report.dart';
import 'package:app_emergency/screens/firefighter/firefighter_profile_screen.dart';
import 'package:app_emergency/screens/firefighter/incident_action_screen.dart';
import 'package:app_emergency/screens/firefighter/quick_report_action_screen.dart';
import 'package:app_emergency/screens/firefighter/ambulance_management_screen.dart';
import 'package:app_emergency/screens/firefighter/approve_firefighters_screen.dart';
import 'package:app_emergency/services/bombero_service.dart';

class FirefighterDashboard extends StatefulWidget {
  const FirefighterDashboard({super.key});

  @override
  State<FirefighterDashboard> createState() => _FirefighterDashboardState();
}

class _FirefighterDashboardState extends State<FirefighterDashboard>
    with SingleTickerProviderStateMixin {
  final IncidentService _incidentService = IncidentService();
  final EmergencyService _emergencyService = EmergencyService();
  final QuickReportService _quickReportService = QuickReportService();
  
  bool _esJefeBombero = false;

  List<Incident> _incidents = [];
  List<QuickReport> _quickReports = [];
  List<Incident> _myEmergencies = [];
  
  bool _isLoading = true;
  String _error = '';
  
  // Tabs: 0 = Incidentes, 1 = Reportes Rápidos
  late TabController _tabController;
  int _selectedIncidentFilter = 0; // 0: Disponibles, 1: Mis emergencias, 2: Completados
  int _selectedQuickReportFilter = 0; // 0: Pendientes, 1: Mis asignados

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
        _loadDashboardData();
      }
    });
    _checkIfChief();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      if (_tabController.index == 0) {
        // Tab de Incidentes
        await Future.wait([_loadIncidents(), _loadMyEmergencies()]);
      } else {
        // Tab de Reportes Rápidos
        await _loadQuickReports();
      }
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

  Future<void> _checkIfChief() async {
  try {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userEmail = authService.user?.email;

    setState(() {
      _esJefeBombero = userEmail == 'jefe@bomberos.com';
    });
  } catch (e) {
    print('Error verificando si es jefe: $e');
  }
}

  Future<void> _loadIncidents() async {
    try {
      List<Incident> incidents;

      switch (_selectedIncidentFilter) {
        case 0: // Disponibles
          incidents = await _emergencyService.getAvailableEmergencies();
          break;
        case 1: // Mis emergencias
          incidents = await _emergencyService.getMyEmergencies();
          break;
        case 2: // Completados
          incidents = await _emergencyService.getMyEmergencies(
            estado: 'completado',
          );
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
      final myEmergencies = await _emergencyService.getMyEmergencies(
        estado: 'en_proceso',
      );
      setState(() {
        _myEmergencies = myEmergencies;
      });
    } catch (e) {
      print('Error al cargar mis emergencias: $e');
    }
  }

  Future<void> _loadQuickReports() async {
    try {
      List<QuickReport> reports;

      switch (_selectedQuickReportFilter) {
        case 0: // Pendientes
          reports = await _quickReportService.getPendingReports();
          break;
        case 1: // Mis asignados
          reports = await _quickReportService.getMyReports();
          break;
        default:
          reports = await _quickReportService.getPendingReports();
      }

      setState(() {
        _quickReports = reports;
      });
    } catch (e) {
      print('Error al cargar reportes rápidos: $e');
    }
  }

  Future<void> _onIncidentFilterChanged(int index) async {
    setState(() {
      _selectedIncidentFilter = index;
    });
    await _loadIncidents();
  }

  Future<void> _onQuickReportFilterChanged(int index) async {
    setState(() {
      _selectedQuickReportFilter = index;
    });
    await _loadQuickReports();
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildAppBar(user),
            SliverToBoxAdapter(child: _buildQuickStats()),
            SliverToBoxAdapter(child: _buildQuickActions()),
            _buildTabBar(),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildIncidentsTab(),
            _buildQuickReportsTab(),
          ],
        ),
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
                child: const Icon(
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
              MaterialPageRoute(
                builder: (context) => const AmbulanceManagementScreen(),
              ),
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
                  MaterialPageRoute(
                    builder: (context) => const FirefighterProfileScreen(),
                  ),
                ).then((_) => _loadDashboardData());
                break;
              case 'approve':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ApproveFirefightersScreen(),
                  ),
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
            if (_esJefeBombero)
              const PopupMenuItem(
                value: 'approve',
                child: Row(
                  children: [
                    Icon(Icons.verified_user, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Aprobar Bomberos'),
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
    final incidentesDisponibles = _selectedIncidentFilter == 0 ? _incidents.length : 0;
    final reportesRapidos = _quickReports.length;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Incidentes',
              incidentesDisponibles.toString(),
              Icons.assignment,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Reportes Rápidos',
              reportesRapidos.toString(),
              Icons.flash_on,
              Colors.purple,
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
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
      child: Column(
        children: [
          if (_esJefeBombero)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ApproveFirefightersScreen(),
                    ),
                  ).then((_) => _loadDashboardData());
                },
                icon: const Icon(Icons.verified_user, size: 24),
                label: const Text(
                  'Aprobar Solicitudes de Bomberos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: Colors.red.shade600,
          labelColor: Colors.red.shade600,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(
              icon: Icon(Icons.list_alt),
              text: 'Incidentes',
            ),
            Tab(
              icon: Icon(Icons.flash_on),
              text: 'Reportes Rápidos',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentsTab() {
    return Column(
      children: [
        _buildIncidentFilterTabs(),
        Expanded(child: _buildIncidentsList()),
      ],
    );
  }

  Widget _buildQuickReportsTab() {
    return Column(
      children: [
        _buildQuickReportFilterTabs(),
        Expanded(child: _buildQuickReportsList()),
      ],
    );
  }

  Widget _buildIncidentFilterTabs() {
    final labels = ['Disponibles', 'Mis Emergencias', 'Completados'];
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = _selectedIncidentFilter == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onIncidentFilterChanged(index),
              child: Container(
                margin: EdgeInsets.only(right: index < labels.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red.shade600 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.red.shade600 : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuickReportFilterTabs() {
    final labels = ['Pendientes', 'Mis Asignados'];
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = _selectedQuickReportFilter == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onQuickReportFilterChanged(index),
              child: Container(
                margin: EdgeInsets.only(right: index < labels.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.purple.shade600 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.purple.shade600 : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  labels[index],
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
      return const Center(
        child: CircularProgressIndicator(color: Colors.red),
      );
    }

    if (_error.isNotEmpty) {
      return _buildErrorState();
    }

    if (_incidents.isEmpty) {
      return _buildEmptyState('No hay incidentes disponibles');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _incidents.length,
      itemBuilder: (context, index) {
        final incident = _incidents[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildIncidentCard(incident),
        );
      },
    );
  }

  Widget _buildQuickReportsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.purple),
      );
    }

    if (_error.isNotEmpty) {
      return _buildErrorState();
    }

    if (_quickReports.isEmpty) {
      return _buildEmptyState('No hay reportes rápidos disponibles');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _quickReports.length,
      itemBuilder: (context, index) {
        final report = _quickReports[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildQuickReportCard(report),
        );
      },
    );
  }

  Widget _buildIncidentCard(Incident incident) {
    return GestureDetector(
      onTap: () => _navigateToIncidentAction(incident.id),
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
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReportCard(QuickReport report) {
    return GestureDetector(
      onTap: () => _navigateToQuickReportAction(report.id!),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.shade100, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.1),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.flash_on,
                      color: Colors.purple.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade600,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'REPORTE RÁPIDO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.tipoEmergencia.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _getQuickReportStatusChip(report.estado),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.direccion,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.photo, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Evidencia fotográfica incluida',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(report.fechaReporte),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _tabController.index == 0 
                ? Icons.assignment_outlined 
                : Icons.flash_on_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _tabController.index == 0 
                  ? Colors.red.shade600 
                  : Colors.purple.shade600,
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

  Widget _getQuickReportStatusChip(String estado) {
    Color color;
    String label;

    switch (estado.toLowerCase()) {
      case 'pendiente':
        color = Colors.orange;
        label = 'Pendiente';
        break;
      case 'asignado':
        color = Colors.blue;
        label = 'Asignado';
        break;
      case 'atendido':
        color = Colors.green;
        label = 'Atendido';
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
      case 'critica':
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

  void _navigateToIncidentAction(String incidentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncidentActionScreen(incidentId: incidentId),
      ),
    ).then((_) => _loadDashboardData());
  }

  void _navigateToQuickReportAction(String reportId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuickReportActionScreen(reportId: reportId),
      ),
    ).then((_) => _loadDashboardData());
  }
}

// Delegate para el TabBar pegajoso
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}