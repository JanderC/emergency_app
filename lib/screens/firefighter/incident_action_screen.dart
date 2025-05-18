import 'package:flutter/material.dart';
import 'package:app_emergency/services/incident_service.dart';
import 'package:app_emergency/services/ambulance_service.dart';
import 'package:app_emergency/models/incident.dart';
import 'package:app_emergency/models/ambulance.dart';
import 'package:provider/provider.dart';
import 'package:app_emergency/services/auth_service.dart';

class IncidentActionScreen extends StatefulWidget {
  final String incidentId;
  
  const IncidentActionScreen({
    super.key,
    required this.incidentId,
  });

  @override
  State<IncidentActionScreen> createState() => _IncidentActionScreenState();
}

class _IncidentActionScreenState extends State<IncidentActionScreen> {
  final IncidentService _incidentService = IncidentService();
  final AmbulanceService _ambulanceService = AmbulanceService();
  
  bool _isLoading = true;
  bool _isUpdating = false;
  String _error = '';
  Incident? _incident;
  List<Ambulance> _availableAmbulances = [];
  Ambulance? _selectedAmbulance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Cargar detalles del incidente
      final incident = await _incidentService.getIncidentById(widget.incidentId);
      
      // Cargar ambulancias disponibles
      final ambulances = await _ambulanceService.getAmbulances(
        filters: {'estado': 'disponible'},
      );
      
      setState(() {
        _incident = incident;
        _availableAmbulances = ambulances;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _takeIncident() async {
    final bomberoId = Provider.of<AuthService>(context, listen: false).userId;
    
    setState(() {
      _isUpdating = true;
    });

    try {
      final result = await _incidentService.updateIncidentStatus(
        widget.incidentId,
        'en proceso',
        bomberoId: bomberoId,
        ambulanciaId: _selectedAmbulance?.id,
      );

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
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

  Future<void> _completeIncident() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final result = await _incidentService.updateIncidentStatus(
        widget.incidentId,
        'completado',
      );

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    final bomberoId = Provider.of<AuthService>(context).userId;
    final isAssignedToBombero = _incident?.bomberoAsignadoId == bomberoId;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Emergencia'),
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
                          // Estado
                          Center(
                            child: Chip(
                              label: Text(
                                _incident!.estado.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: _getStatusColor(_incident!.estado),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Información del incidente
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Detalles de la Emergencia',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow('Tipo', _incident!.tipoEmergencia),
                                  _buildInfoRow('Descripción', _incident!.descripcion),
                                  _buildInfoRow('Ubicación', _incident!.ubicacion),
                                  _buildInfoRow('Nivel de Urgencia', _incident!.nivelUrgencia.toUpperCase()),
                                  _buildInfoRow('Fecha de Reporte', _formatDate(_incident!.fechaReporte)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Selección de ambulancia (solo si el incidente está pendiente)
                          if (_incident!.estado == 'pendiente') ...[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Seleccionar Ambulancia',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    if (_availableAmbulances.isEmpty)
                                      const Text('No hay ambulancias disponibles')
                                    else
                                      DropdownButtonFormField<Ambulance>(
                                        decoration: const InputDecoration(
                                          labelText: 'Ambulancia',
                                          border: OutlineInputBorder(),
                                        ),
                                        hint: const Text('Seleccionar ambulancia'),
                                        value: _selectedAmbulance,
                                        items: _availableAmbulances.map((ambulance) {
                                          return DropdownMenuItem<Ambulance>(
                                            value: ambulance,
                                            child: Text('${ambulance.placa} - ${ambulance.tipo}'),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedAmbulance = value;
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Botón para tomar el incidente
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _isUpdating ? null : _takeIncident,
                                icon: const Icon(Icons.assignment_turned_in),
                                label: _isUpdating
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('Tomar Emergencia'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          
                          // Botón para completar el incidente (solo si está en proceso y asignado a este bombero)
                          if (_incident!.estado == 'en proceso' && isAssignedToBombero) ...[
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _isUpdating ? null : _completeIncident,
                                icon: const Icon(Icons.check_circle),
                                label: _isUpdating
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('Completar Emergencia'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
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
    try {
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return date.toString();
    }
  }
}
