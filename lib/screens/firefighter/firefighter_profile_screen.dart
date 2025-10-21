import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_emergency/services/auth_service.dart';
import 'package:app_emergency/services/firefighter_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class FirefighterProfileScreen extends StatefulWidget {
  const FirefighterProfileScreen({super.key});

  @override
  State<FirefighterProfileScreen> createState() => _FirefighterProfileScreenState();
}

class _FirefighterProfileScreenState extends State<FirefighterProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirefighterService _firefighterService = FirefighterService();
  
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _telefonoController;
  late TextEditingController _codigoBomberoController;
  late TextEditingController _estacionController;
  late TextEditingController _experienciaController;
  
  File? _profileImage;
  String? _profileImageBase64;
  List<String> _especialidades = [];
  List<String> _certificaciones = [];
  String _rango = 'bombero';
  bool _isLoading = false;
  bool _isImageLoading = false;

  final List<String> _especialidadesDisponibles = [
    'rescate', 'primeros_auxilios', 'incendios', 'materiales_peligrosos',
    'rescate_vehicular', 'rescate_acuatico', 'rescate_en_alturas'
  ];

  final List<String> _certificacionesDisponibles = [
    'RCP', 'Rescate Vehicular', 'HAZMAT', 'Primeros Auxilios',
    'Rescate en Alturas', 'Rescate Acuático', 'Manejo de Incendios'
  ];

  final List<String> _rangosDisponibles = [
    'bombero', 'cabo', 'teniente', 'capitan', 'comandante'
  ];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).user;
    
    _nombreController = TextEditingController(text: user?.nombre ?? '');
    _apellidoController = TextEditingController(text: user?.apellido ?? '');
    _telefonoController = TextEditingController(text: user?.telefono ?? '');
    _codigoBomberoController = TextEditingController();
    _estacionController = TextEditingController();
    _experienciaController = TextEditingController();
    
    _profileImageBase64 = user?.fotoPerfil;
    _loadFirefighterProfile();
  }


  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _codigoBomberoController.dispose();
    _estacionController.dispose();
    _experienciaController.dispose();
    super.dispose();
  }

  Future<void> _loadFirefighterProfile() async {
    try {
      final profile = await _firefighterService.getFirefighterProfile();
      setState(() {
        _codigoBomberoController.text = profile['codigo_bombero'] ?? '';
        _estacionController.text = profile['estacion_pertenencia'] ?? '';
        _experienciaController.text = profile['experiencia_anos']?.toString() ?? '';
        _rango = profile['rango'] ?? 'bombero';
        _especialidades = List<String>.from(profile['especialidades'] ?? []);
        _certificaciones = List<String>.from(profile['certificaciones'] ?? []);
        if (profile['foto_perfil'] != null && profile['foto_perfil'].isNotEmpty) {
          _profileImageBase64 = profile['foto_perfil'];
        }
      });
    } catch (e) {
      print('Error al cargar perfil de bombero: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      setState(() {
        _isImageLoading = true;
      });

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        final bytes = await imageFile.readAsBytes();
        final base64String = base64Encode(bytes);
        
        setState(() {
          _profileImage = imageFile;
          _profileImageBase64 = base64String;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Imagen seleccionada correctamente'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error al seleccionar imagen: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isImageLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profileData = {
        'telefono': _telefonoController.text.trim(),
        'especialidades': _especialidades,
        'certificaciones': _certificaciones,
      };

      // Manejar la imagen de perfil con el formato correcto
      if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
        String fotoBase64 = _profileImageBase64!;

        // Si NO tiene prefijo, agregarlo correctamente
        if (!fotoBase64.startsWith('data:image/')) {
          profileData['foto_perfil'] = 'data:image/jpeg;base64,$fotoBase64';
        } else {
          // Si ya lo tiene, enviarlo tal cual
          profileData['foto_perfil'] = fotoBase64;
        }
      }

      final result = await _firefighterService.updateFirefighterProfile(profileData);

      if (mounted) {
        if (result['success']) {
          // Actualizar el usuario en AuthService
          final userData = {
            'nombre': _nombreController.text.trim(),
            'apellido': _apellidoController.text.trim(),
            'telefono': _telefonoController.text.trim(),
          };
          
          if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
            String fotoBase64 = _profileImageBase64!;
            if (!fotoBase64.startsWith('data:image/')) {
              userData['foto_perfil'] = 'data:image/jpeg;base64,$fotoBase64';
            } else {
              userData['foto_perfil'] = fotoBase64;
            }
          }
          
          await Provider.of<AuthService>(context, listen: false).updateProfile(userData);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Perfil actualizado exitosamente'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
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

  ImageProvider? _getProfileImage() {
    if (_profileImage != null) {
      return FileImage(_profileImage!);
    }

    if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
      try {
        String base64String = _profileImageBase64!;

        // Limpiar cualquier prefijo malformado
        if (base64String.startsWith('data:image/')) {
          // Buscar donde empieza el base64 real (después de la coma o de las barras)
          if (base64String.contains(',')) {
            base64String = base64String.split(',').last;
          } else {
            // Si no tiene coma, quitar "data:image/" y todo lo que no sea base64
            base64String = base64String.replaceAll(
              RegExp(r'^data:image/[^/]*'),
              '',
            );
          }
        }

        // Limpiar espacios en blanco
        base64String = base64String.trim();

        final bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } catch (e) {
        print('❌ Error decodificando imagen: $e');
        return null;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Mi Perfil de Bombero'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(user),
            const SizedBox(height: 24),
            _buildFirefighterInfo(),
            const SizedBox(height: 16),
            _buildEditForm(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade600, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _getProfileImage(),
                  backgroundColor: Colors.grey.shade300,
                  child:
                      _isImageLoading
                          ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          )
                          : (_getProfileImage() == null
                              ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey.shade600,
                              )
                              : null),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: _isImageLoading ? null : _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${user?.nombre ?? ''} ${user?.apellido ?? ''}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            _rango.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_codigoBomberoController.text.isNotEmpty)
            Text(
              'Código: ${_codigoBomberoController.text}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFirefighterInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                Icon(Icons.local_fire_department, color: Colors.red.shade600),
                const SizedBox(width: 12),
                Text(
                  'Información de Bombero',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_estacionController.text.isNotEmpty)
              _buildInfoRow('Estación', _estacionController.text, Icons.location_on),
            if (_experienciaController.text.isNotEmpty) ...[
              const Divider(height: 24),
              _buildInfoRow('Experiencia', '${_experienciaController.text} años', Icons.schedule),
            ],
            if (_especialidades.isNotEmpty) ...[
              const Divider(height: 24),
              _buildListInfo('Especialidades', _especialidades, Icons.star),
            ],
            if (_certificaciones.isNotEmpty) ...[
              const Divider(height: 24),
              _buildListInfo('Certificaciones', _certificaciones, Icons.verified),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListInfo(String label, List<String> items, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.map((item) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_outlined, color: Colors.red.shade600),
                  const SizedBox(width: 12),
                  Text(
                    'Editar Información',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _telefonoController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              Text(
                'Especialidades',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _especialidadesDisponibles.map((especialidad) {
                  final isSelected = _especialidades.contains(especialidad);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _especialidades.remove(especialidad);
                        } else {
                          _especialidades.add(especialidad);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red.shade600 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.red.shade600 : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        especialidad,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Certificaciones',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _certificacionesDisponibles.map((certificacion) {
                  final isSelected = _certificaciones.contains(certificacion);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _certificaciones.remove(certificacion);
                        } else {
                          _certificaciones.add(certificacion);
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
                      child: Text(
                        certificacion,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
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
                          'Guardar Cambios',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}