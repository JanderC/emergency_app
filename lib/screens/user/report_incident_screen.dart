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
  
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  
  String _tipoEmergencia = 'incendio';
  String _nivelUrgencia = 'media';
  final List<File> _selectedImages = [];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _tiposEmergencia = [
    {'value': 'incendio', 'label': 'Incendio', 'icon': Icons.local_fire_department, 'color': Colors.red},
    {'value': 'rescate', 'label': 'Rescate', 'icon': Icons.person_pin_circle, 'color': Colors.blue},
    {'value': 'accidente_vehicular', 'label': 'Accidente Vehicular', 'icon': Icons.car_crash, 'color': Colors.orange},
    {'value': 'emergencia_medica', 'label': 'Emergencia Médica', 'icon': Icons.medical_services, 'color': Colors.purple},
    {'value': 'inundacion', 'label': 'Inundación', 'icon': Icons.water, 'color': Colors.blue.shade700},
    {'value': 'deslizamiento', 'label': 'Deslizamiento', 'icon': Icons.landscape, 'color': Colors.brown},
    {'value': 'explosion', 'label': 'Explosión', 'icon': Icons.flash_on, 'color': Colors.yellow.shade700},
    {'value': 'fuga_gas', 'label': 'Fuga de Gas', 'icon': Icons.cloud, 'color': Colors.grey},
    {'value': 'otro', 'label': 'Otro', 'icon': Icons.warning, 'color': Colors.grey.shade600},
  ];

  @override
  void dispose() {
    _descripcionController.dispose();
    _ubicacionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    // En una implementación real, usarías geolocator para obtener la ubicación
    setState(() {
      _latController.text = '7.893456';
      _lngController.text = '-72.456789';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ubicación obtenida automáticamente'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final incidentData = {
        'tipo_emergencia': _tipoEmergencia,
        'descripcion': _descripcionController.text.trim(),
        'ubicacion': _ubicacionController.text.trim(),
        'coordenadas_lat': double.parse(_latController.text),
        'coordenadas_lng': double.parse(_lngController.text),
        'nivel_urgencia': _nivelUrgencia,
        'imagenes': [], // En implementación real, subirías las imágenes primero
      };

      final result = await _incidentService.reportIncident(incidentData);

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
        title: const Text('Reportar Emergencia'),
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
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildEmergencyTypeCard(),
                    const SizedBox(height: 16),
                    _buildDescriptionCard(),
                    const SizedBox(height: 16),
                    _buildLocationCard(),
                    const SizedBox(height: 16),
                    _buildUrgencyCard(),
                    const SizedBox(height: 16),
                    _buildImagesCard(),
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

  Widget _buildInfoCard() {
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
          const Icon(Icons.info_outline, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información Importante',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete todos los campos con información precisa para una atención rápida.',
                  style: TextStyle(color: Colors.red.shade50),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTypeCard() {
    return _buildCard(
      title: 'Tipo de Emergencia',
      icon: Icons.warning_amber,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _tiposEmergencia.length,
        itemBuilder: (context, index) {
          final tipo = _tiposEmergencia[index];
          final isSelected = _tipoEmergencia == tipo['value'];
          
          return GestureDetector(
            onTap: () => setState(() => _tipoEmergencia = tipo['value']),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? tipo['color'] : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? tipo['color'] : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    tipo['icon'],
                    color: isSelected ? Colors.white : tipo['color'],
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tipo['label'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return _buildCard(
      title: 'Descripción',
      icon: Icons.description,
      child: TextFormField(
        controller: _descripcionController,
        decoration: const InputDecoration(
          hintText: 'Describa la situación de emergencia con detalle',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(16),
        ),
        maxLines: 4,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'La descripción es requerida';
          }
          if (value.trim().length < 10) {
            return 'La descripción debe tener al menos 10 caracteres';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildLocationCard() {
    return _buildCard(
      title: 'Ubicación',
      icon: Icons.location_on,
      child: Column(
        children: [
          TextFormField(
            controller: _ubicacionController,
            decoration: const InputDecoration(
              hintText: 'Dirección o referencia del lugar',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La ubicación es requerida';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
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
                    if (double.tryParse(value) == null) {
                      return 'Formato inválido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
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
                    if (double.tryParse(value) == null) {
                      return 'Formato inválido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.my_location, size: 20),
            label: const Text('Obtener ubicación actual'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyCard() {
    return _buildCard(
      title: 'Nivel de Urgencia',
      icon: Icons.priority_high,
      child: Row(
        children: [
          _buildUrgencyOption('baja', 'Baja', Colors.green),
          _buildUrgencyOption('media', 'Media', Colors.orange),
          _buildUrgencyOption('alta', 'Alta', Colors.red),
        ],
      ),
    );
  }

  Widget _buildUrgencyOption(String value, String label, Color color) {
    final isSelected = _nivelUrgencia == value;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _nivelUrgencia = value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagesCard() {
    return _buildCard(
      title: 'Imágenes',
      icon: Icons.photo_camera,
      child: Column(
        children: [
          if (_selectedImages.isNotEmpty) ...[
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImages[index],
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImages.removeAt(index)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
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
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Agregar Imagen'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue.shade600,
              side: BorderSide(color: Colors.blue.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
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
            child,
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
                  'Reportar Emergencia',
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