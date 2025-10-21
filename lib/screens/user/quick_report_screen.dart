// lib/screens/user/quick_report_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:app_emergency/services/quick_report_service.dart';
import 'package:app_emergency/models/quick_report.dart';

class QuickReportScreen extends StatefulWidget {
  const QuickReportScreen({super.key});

  @override
  State<QuickReportScreen> createState() => _QuickReportScreenState();
}

class _QuickReportScreenState extends State<QuickReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quickReportService = QuickReportService();
  final _direccionController = TextEditingController();
  
  String _tipoEmergenciaSeleccionado = 'choque_fuerte';
  File? _imagenSeleccionada;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _tiposEmergencia = [
    {
      'value': 'choque_fuerte',
      'label': 'Choque Fuerte',
      'icon': Icons.car_crash,
      'color': Colors.red
    },
    {
      'value': 'incendio',
      'label': 'Incendio',
      'icon': Icons.local_fire_department,
      'color': Colors.orange
    },
    {
      'value': 'accidente_grave',
      'label': 'Accidente Grave',
      'icon': Icons.emergency,
      'color': Colors.red.shade700
    },
    {
      'value': 'persona_atrapada',
      'label': 'Persona Atrapada',
      'icon': Icons.person_pin_circle,
      'color': Colors.purple
    },
    {
      'value': 'explosion',
      'label': 'Explosión',
      'icon': Icons.flash_on,
      'color': Colors.yellow.shade700
    },
    {
      'value': 'otro',
      'label': 'Otra Emergencia',
      'icon': Icons.warning,
      'color': Colors.grey
    },
  ];

  @override
  void dispose() {
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imagenSeleccionada = File(pickedFile.path);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto seleccionada correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar imagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitQuickReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imagenSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una foto de la emergencia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Confirmar envío
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red.shade600, size: 28),
            const SizedBox(width: 12),
            const Text('¡Enviar Emergencia!'),
          ],
        ),
        content: const Text(
          '¿Confirmas que deseas enviar este reporte de emergencia?\n\n'
          'Los bomberos serán notificados inmediatamente.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('ENVIAR AHORA'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Convertir imagen a base64
      final bytes = await _imagenSeleccionada!.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final report = QuickReport(
        tipoEmergencia: _tipoEmergenciaSeleccionado,
        foto: base64Image,
        nombreFoto: 'emergencia_${DateTime.now().millisecondsSinceEpoch}.jpg',
        direccion: _direccionController.text.trim(),
        fechaReporte: DateTime.now(),
      );

      final result = await _quickReportService.createQuickReport(report);

      if (mounted) {
        if (result['success']) {
          _showSuccessDialog();
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 32),
            const SizedBox(width: 12),
            const Text('¡Emergencia Reportada!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tu reporte ha sido enviado exitosamente.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.local_fire_department,
                      color: Colors.red.shade600, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Los bomberos han sido notificados y están en camino',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pop(); // Volver al dashboard
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: const Text('Reporte Rápido de Emergencia'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Banner de advertencia
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade700, Colors.red.shade500],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '¡EMERGENCIA DE ALTA PRIORIDAD!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Solo completa 3 campos para enviar',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Selector de tipo de emergencia
                    _buildCard(
                      title: '1. Tipo de Emergencia',
                      icon: Icons.emergency,
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _tiposEmergencia.length,
                        itemBuilder: (context, index) {
                          final tipo = _tiposEmergencia[index];
                          final isSelected =
                              _tipoEmergenciaSeleccionado == tipo['value'];

                          return GestureDetector(
                            onTap: () => setState(() =>
                                _tipoEmergenciaSeleccionado = tipo['value']),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? tipo['color']
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? tipo['color']
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: tipo['color'].withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : [],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    tipo['icon'],
                                    color: isSelected
                                        ? Colors.white
                                        : tipo['color'],
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    tipo['label'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey.shade800,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selector de foto
                    _buildCard(
                      title: '2. Foto de la Emergencia',
                      icon: Icons.camera_alt,
                      child: Column(
                        children: [
                          if (_imagenSeleccionada != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _imagenSeleccionada!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _showImageSourceDialog,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Cambiar Foto'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blue.shade600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  onPressed: () => setState(() =>
                                      _imagenSeleccionada = null),
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red.shade600,
                                ),
                              ],
                            ),
                          ] else ...[
                            Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo,
                                      size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No hay foto seleccionada',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _showImageSourceDialog,
                                icon: const Icon(Icons.camera_alt, size: 28),
                                label: const Text(
                                  'TOMAR/SELECCIONAR FOTO',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo de dirección
                    _buildCard(
                      title: '3. Dirección del Incidente',
                      icon: Icons.location_on,
                      child: TextFormField(
                        controller: _direccionController,
                        decoration: InputDecoration(
                          hintText: 'Ej: Av. Principal con Calle 10',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(Icons.place,
                              color: Colors.red.shade600),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La dirección es requerida';
                          }
                          if (value.trim().length < 10) {
                            return 'Por favor sea más específico';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botón de envío
            Container(
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
                height: 64,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitQuickReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.send, size: 28),
                            SizedBox(width: 12),
                            Text(
                              '¡ENVIAR EMERGENCIA AHORA!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.red.shade600, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
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
}