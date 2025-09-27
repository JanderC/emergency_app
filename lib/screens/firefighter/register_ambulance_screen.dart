import 'package:flutter/material.dart';
import 'package:app_emergency/services/ambulance_service.dart';

class RegisterAmbulanceScreen extends StatefulWidget {
  const RegisterAmbulanceScreen({super.key});

  @override
  State<RegisterAmbulanceScreen> createState() => _RegisterAmbulanceScreenState();
}

class _RegisterAmbulanceScreenState extends State<RegisterAmbulanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ambulanceService = AmbulanceService();
  
  final _placaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _capacidadController = TextEditingController();
  final _estacionController = TextEditingController();
  
  String _estado = 'operativa';
  String _combustible = 'completo';
  List<String> _equipamiento = [];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _estadosDisponibles = [
    {'value': 'operativa', 'label': 'Operativa', 'color': Colors.green, 'icon': Icons.check_circle},
    {'value': 'mantenimiento', 'label': 'Mantenimiento', 'color': Colors.orange, 'icon': Icons.build},
    {'value': 'fuera_de_servicio', 'label': 'Fuera de Servicio', 'color': Colors.red, 'icon': Icons.cancel},
  ];

  final List<Map<String, dynamic>> _combustibleOptions = [
    {'value': 'completo', 'label': 'Completo', 'color': Colors.green},
    {'value': 'medio', 'label': 'Medio', 'color': Colors.orange},
    {'value': 'bajo', 'label': 'Bajo', 'color': Colors.red},
  ];

  final List<String> _equipamientoDisponible = [
    'desfibrilador', 'oxígeno', 'camilla', 'monitor_signos_vitales',
    'ventilador', 'medicamentos_emergencia', 'kit_trauma', 'inmovilizadores',
    'aspirador', 'tabla_espinal', 'collar_cervical', 'botiquín_avanzado'
  ];

  @override
  void dispose() {
    _placaController.dispose();
    _modeloController.dispose();
    _capacidadController.dispose();
    _estacionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ambulanceData = {
        'placa': _placaController.text.trim().toUpperCase(),
        'modelo': _modeloController.text.trim(),
        'tipo': 'Tipo I', // Tipo fijo según la clase
        'capacidad': int.parse(_capacidadController.text ?? '4'),
        'estado': _estado,
        'estacion_pertenencia': _estacionController.text.trim(),
      };

      final result = await _ambulanceService.registerAmbulance(ambulanceData);

      if (mounted) {
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
          Navigator.pop(context, true);
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Registrar Ambulancia'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 16),
                    _buildBasicInfoCard(),
                    const SizedBox(height: 16),
                    _buildStatusCard(),
                  ],
                ),
              ),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade600, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nueva Ambulancia',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Registra una nueva unidad de emergencia médica',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return _buildCard(
      title: 'Información Básica',
      icon: Icons.info_outline,
      children: [
        TextFormField(
          controller: _placaController,
          decoration: InputDecoration(
            labelText: 'Placa',
            hintText: 'ABC-123',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textCapitalization: TextCapitalization.characters,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La placa es requerida';
            }
            if (value.trim().length < 6) {
              return 'Mínimo 6 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _modeloController,
          decoration: InputDecoration(
            labelText: 'Modelo',
            hintText: 'Ford Transit 2020',
            prefixIcon: const Icon(Icons.directions_car),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El modelo es requerido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _capacidadController,
          decoration: InputDecoration(
            labelText: 'Capacidad (personas)',
            hintText: '4',
            prefixIcon: const Icon(Icons.people),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'La capacidad es requerida';
            }
            final capacity = int.tryParse(value);
            if (capacity == null || capacity < 1) {
              return 'Ingrese una capacidad válida';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _estacionController,
          decoration: InputDecoration(
            labelText: 'Estación de Pertenencia',
            hintText: 'Estación Central',
            prefixIcon: const Icon(Icons.location_city),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La estación es requerida';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return _buildCard(
      title: 'Estado y Condición',
      icon: Icons.assessment,
      children: [
        Text(
          'Estado Operativo:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _estadosDisponibles.map((estado) {
            final isSelected = _estado == estado['value'];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _estado = estado['value']),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? estado['color'] : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? estado['color'] : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        estado['icon'],
                        color: isSelected ? Colors.white : estado['color'],
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        estado['label'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : estado['color'],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text(
          'Nivel de Combustible:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _combustibleOptions.map((option) {
            final isSelected = _combustible == option['value'];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _combustible = option['value']),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? option['color'] : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? option['color'] : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    option['label'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : option['color'],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEquipmentCard() {
    return _buildCard(
      title: 'Equipamiento Médico',
      icon: Icons.medical_services,
      children: [
        Text(
          'Selecciona el equipamiento disponible:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _equipamientoDisponible.map((equipo) {
            final isSelected = _equipamiento.contains(equipo);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _equipamiento.remove(equipo);
                  } else {
                    _equipamiento.add(equipo);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade600 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    if (isSelected) const SizedBox(width: 4),
                    Text(
                      equipo.replaceAll('_', ' '),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMaintenanceCard() {
    return _buildCard(
      title: 'Información de Mantenimiento',
      icon: Icons.settings,
      children: [
        TextFormField(
          controller: TextEditingController(),
          decoration: InputDecoration(
            labelText: 'Kilometraje Actual',
            hintText: '15000',
            prefixIcon: const Icon(Icons.speed),
            suffixText: 'km',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El kilometraje es requerido';
            }
            if (int.tryParse(value) == null) {
              return 'Ingrese un número válido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Registrar Ambulancia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}