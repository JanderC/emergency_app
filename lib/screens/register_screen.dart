// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_emergency/services/auth_service.dart';
import 'package:app_emergency/utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _cedulaController = TextEditingController(); // NUEVO
  final _direccionController = TextEditingController(); // NUEVO
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Campos para bomberos
  final _codigoBomberoController = TextEditingController();
  final _estacionController = TextEditingController();

  bool _esBombero = false;
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  String _rangoSeleccionado = 'bombero';

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;

  final List<String> _rangosDisponibles = [
    'bombero',
    'cabo',
    'teniente',
    'capitan',
    'comandante',
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _animationController.reverse().then((_) {
        _animationController.forward();
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await Provider.of<AuthService>(
        context,
        listen: false,
      ).register(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        email: _emailController.text.trim(),
        cedula: _cedulaController.text.trim(), // NUEVO
        direccion: _direccionController.text.trim(), // NUEVO
        telefono: _telefonoController.text.trim(),
        password: _passwordController.text,
        esBombero: _esBombero,
        // Campos adicionales para bomberos
        codigoBombero: _esBombero ? _codigoBomberoController.text.trim() : null,
        estacionPertenencia:
            _esBombero ? _estacionController.text.trim() : null,
        rango: _esBombero ? _rangoSeleccionado : null,
        especialidades: [],
        certificaciones: [],
        experienciaAnos: 0,
      );

      if (mounted) {
        if (!result['success']) {
          _showSnackBar(result['message'], Colors.red, Icons.error);
        } else {
          // Mostrar mensaje especial para bomberos
          if (_esBombero) {
            _showApprovalDialog();
          } else {
            _showSnackBar(
              'Usuario registrado exitosamente. Ahora puede iniciar sesión.',
              Colors.green,
              Icons.check_circle,
            );
            await _animationController.reverse();
            Navigator.of(context).pop();
          }
        }
      }
    } catch (error) {
      print('Error en registro: $error');
      if (mounted) {
        _showSnackBar('Error al registrar: $error', Colors.red, Icons.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showApprovalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.schedule, color: Colors.orange.shade600, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Solicitud Enviada',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tu solicitud de registro como bombero ha sido enviada exitosamente.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, 
                        color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Próximos pasos:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    '1',
                    'El jefe de estación revisará tu solicitud',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    '2',
                    'Recibirás una notificación cuando sea aprobada',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    '3',
                    'Una vez aprobada, podrás iniciar sesión',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '⏱️ El proceso puede tomar entre 24-48 horas',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pop(); // Volver a login
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Entendido',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.orange.shade600,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool? showPasswordToggle,
    VoidCallback? onPasswordToggle,
    int delay = 0,
    int? maxLines = 1,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * (delay * 0.1 + 1)),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                obscureText: obscureText,
                validator: validator,
                maxLines: maxLines,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.red),
                  ),
                  suffixIcon:
                      showPasswordToggle == true
                          ? IconButton(
                            icon: Icon(
                              obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: onPasswordToggle,
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.05),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _cedulaController.dispose(); // NUEVO
    _direccionController.dispose(); // NUEVO
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codigoBomberoController.dispose();
    _estacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.withOpacity(0.1),
              Colors.white,
              Colors.red.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.red),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Registro de Usuario',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Container(
                                height: 120,
                                width: 120,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.red, Colors.red.shade700],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(60),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_add,
                                  size: 70,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Text(
                          'Crear Cuenta',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Únete a nuestra comunidad de emergencias',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildAnimatedTextField(
                              controller: _nombreController,
                              label: 'Nombre',
                              icon: Icons.person,
                              validator: (value) => Validators.name(value, 'Nombre'),
                              delay: 1,
                            ),
                            const SizedBox(height: 20),

                            _buildAnimatedTextField(
                              controller: _apellidoController,
                              label: 'Apellido',
                              icon: Icons.person_outline,
                              validator: (value) => Validators.name(value, 'Apellido'),
                              delay: 2,
                            ),
                            const SizedBox(height: 20),

                            _buildAnimatedTextField(
                              controller: _emailController,
                              label: 'Correo electrónico',
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) => Validators.email(value),
                              delay: 3,
                            ),
                            const SizedBox(height: 20),

                            // NUEVO: Campo de Cédula
                            _buildAnimatedTextField(
                              controller: _cedulaController,
                              label: 'Cédula',
                              icon: Icons.badge,
                              keyboardType: TextInputType.number,
                              validator: (value) => Validators.cedula(value),
                              delay: 4,
                            ),
                            const SizedBox(height: 20),

                            // NUEVO: Campo de Dirección
                            _buildAnimatedTextField(
                              controller: _direccionController,
                              label: 'Dirección',
                              icon: Icons.home,
                              maxLines: 2,
                              validator: (value) => Validators.direccion(value),
                              delay: 5,
                            ),
                            const SizedBox(height: 20),

                            _buildAnimatedTextField(
                              controller: _telefonoController,
                              label: 'Teléfono',
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              validator: (value) => Validators.telefono(value),
                              delay: 6,
                            ),
                            const SizedBox(height: 20),

                            _buildAnimatedTextField(
                              controller: _passwordController,
                              label: 'Contraseña',
                              icon: Icons.lock,
                              obscureText: !_passwordVisible,
                              showPasswordToggle: true,
                              onPasswordToggle: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                              validator: (value) => Validators.password(value),
                              delay: 7,
                            ),
                            const SizedBox(height: 20),

                            _buildAnimatedTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirmar Contraseña',
                              icon: Icons.lock_outline,
                              obscureText: !_confirmPasswordVisible,
                              showPasswordToggle: true,
                              onPasswordToggle: () {
                                setState(() {
                                  _confirmPasswordVisible =
                                      !_confirmPasswordVisible;
                                });
                              },
                              validator: (value) => Validators.confirmPassword(value, _passwordController.text),
                              delay: 8,
                            ),
                            const SizedBox(height: 24),

                            // Checkbox para bombero
                            AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                    0,
                                    _slideAnimation.value * 0.9,
                                  ),
                                  child: FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            _esBombero
                                                ? Colors.red.withOpacity(0.1)
                                                : Colors.grey.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color:
                                              _esBombero
                                                  ? Colors.red
                                                  : Colors.transparent,
                                          width: 1,
                                        ),
                                      ),
                                      child: CheckboxListTile(
                                        title: Row(
                                          children: [
                                            Icon(
                                              Icons.local_fire_department,
                                              color:
                                                  _esBombero
                                                      ? Colors.red
                                                      : Colors.grey,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Registrarse como bombero',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        value: _esBombero,
                                        activeColor: Colors.red,
                                        onChanged: (value) {
                                          setState(() {
                                            _esBombero = value ?? false;
                                          });
                                        },
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Campos adicionales para bomberos
                            if (_esBombero) ...[
                              const SizedBox(height: 20),
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.local_fire_department,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Información de Bombero',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      _buildAnimatedTextField(
                                        controller: _codigoBomberoController,
                                        label: 'Código de Bombero',
                                        icon: Icons.badge,
                                        validator: (value) => Validators.codigoBombero(value),
                                        delay: 9,
                                      ),
                                      const SizedBox(height: 16),

                                      _buildAnimatedTextField(
                                        controller: _estacionController,
                                        label: 'Estación de Pertenencia',
                                        icon: Icons.location_on,
                                        validator: (value) => Validators.estacion(value),
                                        delay: 10,
                                      ),
                                      const SizedBox(height: 16),

                                      // Dropdown para rango
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: DropdownButtonFormField<String>(
                                          value: _rangoSeleccionado,
                                          decoration: InputDecoration(
                                            labelText: 'Rango',
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.military_tech,
                                                color: Colors.red,
                                              ),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: BorderSide.none,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: const BorderSide(
                                                color: Colors.red,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          items:
                                              _rangosDisponibles.map((rango) {
                                                return DropdownMenuItem<String>(
                                                  value: rango,
                                                  child: Text(
                                                    rango
                                                            .substring(0, 1)
                                                            .toUpperCase() +
                                                        rango.substring(1),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _rangoSeleccionado = value!;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 32),

                            // Botón de registro
                            AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                    0,
                                    _slideAnimation.value * 1.1,
                                  ),
                                  child: FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: Container(
                                      width: double.infinity,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.3),
                                            blurRadius: 15,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                        child:
                                            _isLoading
                                                ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      _esBombero
                                                          ? 'Registrando Bombero...'
                                                          : 'Registrando...',
                                                    ),
                                                  ],
                                                )
                                                : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      _esBombero
                                                          ? Icons
                                                              .local_fire_department
                                                          : Icons.person_add,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      _esBombero
                                                          ? 'Registrar Bombero'
                                                          : 'Registrarse',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
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