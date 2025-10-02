import 'package:flutter/material.dart';
import 'package:app_emergency/services/ambulance_service.dart';
import 'package:app_emergency/models/ambulance.dart';
import 'package:app_emergency/screens/firefighter/register_ambulance_screen.dart';

class AmbulanceManagementScreen extends StatefulWidget {
  const AmbulanceManagementScreen({super.key});

  @override
  State<AmbulanceManagementScreen> createState() => _AmbulanceManagementScreenState();
}

class _AmbulanceManagementScreenState extends State<AmbulanceManagementScreen> {
  final AmbulanceService _ambulanceService = AmbulanceService();
  List<Ambulance> _ambulances = [];
  List<Ambulance> _filteredAmbulances = [];
  bool _isLoading = true;
  String _error = '';
  String _searchQuery = '';
  int _selectedFilter = 0;

  final List<String> _filterLabels = ['Todas', 'Operativas', 'En Servicio', 'Mantenimiento'];

  @override
  void initState() {
    super.initState();
    _loadAmbulances();
  }

  Future<void> _loadAmbulances() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final ambulances = await _ambulanceService.getAmbulances();
      setState(() {
        _ambulances = ambulances;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Ambulance> filtered = List.from(_ambulances);

    switch (_selectedFilter) {
      case 1:
        filtered = filtered.where((a) => a.estado == 'operativa').toList();
        break;
      case 2:
        filtered = filtered.where((a) => a.estado == 'en_servicio').toList();
        break;
      case 3:
        filtered = filtered.where((a) => a.estado == 'mantenimiento').toList();
        break;
      default:
        break;
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((ambulance) {
        final placa = ambulance.placa.toLowerCase();
        final modelo = ambulance.modelo?.toLowerCase() ?? '';
        final estacion = ambulance.estacionPertenencia?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        
        return placa.contains(query) || 
               modelo.contains(query) || 
               estacion.contains(query);
      }).toList();
    }

    setState(() {
      _filteredAmbulances = filtered;
    });
  }

  void _onFilterChanged(int index) {
    setState(() {
      _selectedFilter = index;
    });
    _applyFilters();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  Future<void> _assignAmbulance(String ambulanceId) async {
    try {
      final result = await _ambulanceService.assignAmbulance(ambulanceId);
      
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
        _loadAmbulances();
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _releaseAmbulance(String ambulanceId) async {
    try {
      final result = await _ambulanceService.releaseAmbulance(ambulanceId);
      
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
        _loadAmbulances();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _updateAmbulanceStatus(String ambulanceId, String newStatus) async {
    try {
      final result = await _ambulanceService.updateAmbulanceStatus(ambulanceId, newStatus);
      
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
        _loadAmbulances();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildStatsCards()),
          SliverToBoxAdapter(child: _buildSearchAndFilters()),
          _buildAmbulancesList(),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar() {
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Gestión de Ambulancias',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Administra la flota de vehículos de emergencia',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final operativas = _ambulances.where((a) => a.estado == 'operativa').length;
    final enServicio = _ambulances.where((a) => a.estado == 'en_servicio').length;
    final mantenimiento = _ambulances.where((a) => a.estado == 'mantenimiento').length;
    final total = _ambulances.length;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Total', total.toString(), Icons.local_hospital, Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Operativas', operativas.toString(), Icons.check_circle, Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('En Servicio', enServicio.toString(), Icons.emergency, Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Mantenimiento', mantenimiento.toString(), Icons.build, Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
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
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por placa, modelo o estación...',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
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
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAmbulancesList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    if (_error.isNotEmpty) {
      return SliverFillRemaining(child: _buildErrorState());
    }

    if (_filteredAmbulances.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState());
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final ambulance = _filteredAmbulances[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildAmbulanceCard(ambulance),
            );
          },
          childCount: _filteredAmbulances.length,
        ),
      ),
    );
  }

  Widget _buildAmbulanceCard(Ambulance ambulance) {
    return Container(
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(ambulance.estado).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(ambulance.estado),
                    color: _getStatusColor(ambulance.estado),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            ambulance.placa,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          _getStatusChip(ambulance.estado),
                        ],
                      ),
                      Text(
                        ambulance.modelo ?? 'Sin modelo',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoGrid(ambulance),
            const SizedBox(height: 16),
            _buildActionButtons(ambulance),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid(Ambulance ambulance) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                Icons.category,
                'Tipo',
                ambulance.tipo ?? 'No especificado',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                Icons.people,
                'Capacidad',
                ambulance.capacidad != null 
                    ? '${ambulance.capacidad} personas'
                    : 'No especificada',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          Icons.location_city,
          'Estación',
          ambulance.estacionPertenencia ?? 'No asignada',
        ),
        if (ambulance.bomberoAsignadoId != null) ...[
          const SizedBox(height: 12),
          _buildInfoItem(
            Icons.person,
            'Bombero Asignado',
            ambulance.bomberoInfo != null
                ? ambulance.bomberoInfo!['nombre'] ?? 'Desconocido'
                : 'ID: ${ambulance.bomberoAsignadoId}',
          ),
        ],
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Ambulance ambulance) {
    return Row(
      children: [
        if (ambulance.estado == 'operativa') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _assignAmbulance(ambulance.id),
              icon: const Icon(Icons.assignment_ind, size: 18),
              label: const Text('Asignar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _updateAmbulanceStatus(ambulance.id, 'mantenimiento'),
              icon: const Icon(Icons.build, size: 18),
              label: const Text('Mantenimiento'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade600,
                side: BorderSide(color: Colors.orange.shade600),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ] else if (ambulance.estado == 'en_servicio') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _releaseAmbulance(ambulance.id),
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Liberar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ] else if (ambulance.estado == 'mantenimiento') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateAmbulanceStatus(ambulance.id, 'operativa'),
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Reparada'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
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
              'Error al cargar ambulancias',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_error, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAmbulances,
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
    String message = _searchQuery.isNotEmpty 
        ? 'No se encontraron ambulancias que coincidan con "$_searchQuery"'
        : _selectedFilter == 0 
            ? 'No hay ambulancias registradas'
            : 'No hay ambulancias ${_filterLabels[_selectedFilter].toLowerCase()}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterAmbulanceScreen()),
                ).then((_) => _loadAmbulances());
              },
              icon: const Icon(Icons.add),
              label: const Text('Registrar Ambulancia'),
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
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RegisterAmbulanceScreen()),
        ).then((result) {
          if (result == true) {
            _loadAmbulances();
          }
        });
      },
      backgroundColor: Colors.red.shade600,
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    );
  }

  Widget _getStatusChip(String estado) {
    Color color = _getStatusColor(estado);
    String label = _getStatusLabel(estado);
    
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

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'operativa':
        return Colors.green;
      case 'en_servicio':
        return Colors.blue;
      case 'mantenimiento':
        return Colors.orange;
      case 'fuera_de_servicio':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String estado) {
    switch (estado) {
      case 'operativa':
        return Icons.check_circle;
      case 'en_servicio':
        return Icons.emergency;
      case 'mantenimiento':
        return Icons.build;
      case 'fuera_de_servicio':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusLabel(String estado) {
    switch (estado) {
      case 'operativa':
        return 'Operativa';
      case 'en_servicio':
        return 'En Servicio';
      case 'mantenimiento':
        return 'Mantenimiento';
      case 'fuera_de_servicio':
        return 'Fuera de Servicio';
      default:
        return estado;
    }
  }
}