// lib/screens/user/report_incident_screen.dart
import 'package:flutter/material.dart';
import 'package:app_emergency/services/incident_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _incidentService = IncidentService();
  
  final _tipoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  
  String _nivelUrgencia = 'media';
  final List<File> _selectedImages = [];
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Enviando reporte de incidente...');
      
      // En una implementación real, aquí subirías las imágenes a un servidor
      // y obtendrías URLs para incluir en el reporte
      List<String> imageUrls = [];
      
      final incidentData = {
        'tipo_emergencia': _tipoController.text,
        'descripcion': _descripcionController.text,
        'ubicacion': _ubicacionController.text,
        'coordenadas_lat': _latController.text,
        'coordenadas_lng': _lngController.text,
        'nivel_urgencia': _nivelUrgencia,
        'imagenes': imageUrls,
      };

      print('Datos del incidente: $incidentData');
      final result = await _incidentService.reportIncident(incidentData);
      print('Resultado del reporte: $result');

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
      print('Error al reportar incidente: $e');
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
    _tipoController.dispose();
    _descripcionController.dispose();
    _ubicacionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Emergencia'),
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
              // Instrucciones
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Información importante',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Complete todos los campos con información precisa para que los bomberos puedan atender la emergencia lo más rápido posible.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Tipo de emergencia
              TextFormField(
                controller: _tipoController,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Emergencia',
                  hintText: 'Ej: Incendio, Accidente, Emergencia médica',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el tipo de emergencia';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Descripción
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Describa la situación de emergencia',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Ubicación
              TextFormField(
                controller: _ubicacionController,
                decoration: const InputDecoration(
                  labelText: 'Ubicación',
                  hintText: 'Dirección o referencia del lugar',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la ubicación';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Coordenadas
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      decoration: const InputDecoration(
                        labelText: 'Latitud',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      decoration: const InputDecoration(
                        labelText: 'Longitud',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Nivel de urgencia
              const Text(
                'Nivel de Urgencia:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              RadioListTile<String>(
                title: const Text('Baja'),
                value: 'baja',
                groupValue: _nivelUrgencia,
                onChanged: (value) {
                  setState(() {
                    _nivelUrgencia = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Media'),
                value: 'media',
                groupValue: _nivelUrgencia,
                onChanged: (value) {
                  setState(() {
                    _nivelUrgencia = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Alta'),
                value: 'alta',
                groupValue: _nivelUrgencia,
                onChanged: (value) {
                  setState(() {
                    _nivelUrgencia = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Imágenes
              const Text(
                'Imágenes:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              if (_selectedImages.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            Image.file(
                              _selectedImages[index],
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  color: Colors.red,
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_camera),
                label: const Text('Agregar Imagen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                ),
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
                      : const Text('Reportar Emergencia'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}