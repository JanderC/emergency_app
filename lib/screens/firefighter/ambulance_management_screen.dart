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
  bool _isLoading = true;
  String _error = '';
  String _filter = ''; // Filtro vacío para mostrar todas las ambulancias

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
      Map<String, String>? filters;
      if (_filter.isNotEmpty) {
        filters = {'estado': _filter};
      }
      
      final ambulances = await _ambulanceService.getAmbulances(filters: filters);
      
      setState(() {
        _ambulances = ambulances;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar ambulancias: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _assignAmbulance(String ambulanceId) async {
    try {
      final result = await _ambulanceService.assignAmbulance(ambulanceId);
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        _loadAmbulances();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red[900]!,
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
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        _loadAmbulances();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Ambulancias'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
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
                  label: const Text('Todas'),
                  selected: _filter.isEmpty,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filter = '';
                      });
                      _loadAmbulances();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Disponibles'),
                  selected: _filter == 'disponible',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filter = 'disponible';
                      });
                      _loadAmbulances();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('En servicio'),
                  selected: _filter == 'en_servicio',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filter = 'en_servicio';
                      });
                      _loadAmbulances();
                    }
                  },
                ),
              ],
            ),
          ),
          
          // Lista de ambulancias
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAmbulances,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                      ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
                      : _ambulances.isEmpty
                          ? const Center(child: Text('No hay ambulancias disponibles'))
                          : ListView.builder(
                              itemCount: _ambulances.length,
                              itemBuilder: (ctx, index) {
                                final ambulance = _ambulances[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              ambulance.placa,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            _getStatusChip(ambulance.estado),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Modelo: ${ambulance.modelo}'),
                                        Text('Tipo: ${ambulance.tipo}'),
                                        Text('Capacidad: ${ambulance.capacidad} personas'),
                                        Text('Estación: ${ambulance.estacionPertenencia}'),
                                        
                                        if (ambulance.bomberoAsignadoId != null)
                                          Text('Bombero asignado: ${ambulance.bomberoAsignadoId}'),
                                        
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            if (ambulance.estado == 'disponible') ...[
                                              ElevatedButton.icon(
                                                onPressed: () => _assignAmbulance(ambulance.id),
                                                icon: const Icon(Icons.assignment_ind),
                                                label: const Text('Asignar'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue,
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                            ] else if (ambulance.estado == 'en_servicio' && 
                                                      ambulance.bomberoAsignadoId != null) ...[
                                              ElevatedButton.icon(
                                                onPressed: () => _updateAmbulanceStatus(ambulance.id, 'disponible'),
                                                icon: const Icon(Icons.check_circle),
                                                label: const Text('Liberar'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
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
              builder: (context) => const RegisterAmbulanceScreen(),
            ),
          ).then((_) => _loadAmbulances());
        },
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _getStatusChip(String estado) {
    Color color;
    String label;
    
    switch (estado) {
      case 'disponible':
        color = Colors.green;
        label = 'Disponible';
        break;
      case 'en_servicio':
        color = Colors.blue;
        label = 'En servicio';
        break;
      case 'mantenimiento':
        color = Colors.orange;
        label = 'Mantenimiento';
        break;
      default:
        color = Colors.grey;
        label = estado;
    }
    
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }
}
