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
  
  String _tipo = 'Tipo I';
  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ambulanceData = {
        'placa': _placaController.text,
        'modelo': _modeloController.text,
        'tipo': _tipo,
        'capacidad': int.parse(_capacidadController.text),
        'estacion_pertenencia': _estacionController.text,
      };

      final result = await _ambulanceService.registerAmbulance(ambulanceData);

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
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _placaController.dispose();
    _modeloController.dispose();
    _capacidadController.dispose();
    _estacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Ambulancia'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Placa
              TextFormField(
                controller: _placaController,
                decoration: const InputDecoration(
                  labelText: 'Placa',
                  hintText: 'Ej: ABC-123',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la placa';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Modelo
              TextFormField(
                controller: _modeloController,
                decoration: const InputDecoration(
                  labelText: 'Modelo',
                  hintText: 'Ej: Toyota Hiace 2022',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el modelo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Tipo
              const Text(
                'Tipo de Ambulancia:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              RadioListTile<String>(
                title: const Text('Tipo I - Soporte Vital Básico'),
                value: 'Tipo I',
                groupValue: _tipo,
                onChanged: (value) {
                  setState(() {
                    _tipo = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Tipo II - Soporte Vital Avanzado'),
                value: 'Tipo II',
                groupValue: _tipo,
                onChanged: (value) {
                  setState(() {
                    _tipo = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Tipo III - UCI Móvil'),
                value: 'Tipo III',
                groupValue: _tipo,
                onChanged: (value) {
                  setState(() {
                    _tipo = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Capacidad
              TextFormField(
                controller: _capacidadController,
                decoration: const InputDecoration(
                  labelText: 'Capacidad (personas)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la capacidad';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Ingrese un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Estación
              TextFormField(
                controller: _estacionController,
                decoration: const InputDecoration(
                  labelText: 'Estación de Pertenencia',
                  hintText: 'Ej: Estación Central',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la estación';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Botón de envío
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Registrar Ambulancia'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
