// lib/screens/firefighter/approve_firefighters_screen.dart
import 'package:flutter/material.dart';
import 'package:app_emergency/services/firefighter_approval_service.dart';
import 'package:app_emergency/models/pending_firefighter.dart';

class ApproveFirefightersScreen extends StatefulWidget {
  const ApproveFirefightersScreen({super.key});

  @override
  State<ApproveFirefightersScreen> createState() =>
      _ApproveFirefightersScreenState();
}

class _ApproveFirefightersScreenState extends State<ApproveFirefightersScreen> {
  final _approvalService = FirefighterApprovalService();
  List<PendingFirefighter> _pendingFirefighters = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadPendingFirefighters();
  }

  Future<void> _loadPendingFirefighters() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final firefighters = await _approvalService.getPendingFirefighters();
      setState(() {
        _pendingFirefighters = firefighters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _showApprovalDialog(PendingFirefighter firefighter) async {
    final codigoController = TextEditingController();
    final passwordController = TextEditingController();
    bool isPasswordVisible = false;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.verified_user, color: Colors.green.shade600, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Aprobar Bombero',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información del bombero
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firefighter.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.badge, firefighter.codigoBombero),
                      _buildInfoRow(Icons.email, firefighter.email),
                      _buildInfoRow(Icons.credit_card, firefighter.cedula),
                      _buildInfoRow(Icons.phone, firefighter.telefono),
                      _buildInfoRow(
                        Icons.location_on,
                        firefighter.estacionPertenencia,
                      ),
                      _buildInfoRow(
                        Icons.military_tech,
                        firefighter.rango.toUpperCase(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Credenciales del jefe
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
                          Icon(Icons.security, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Verificación de Jefe',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: codigoController,
                        decoration: InputDecoration(
                          labelText: 'Código de Jefe',
                          prefixIcon: const Icon(Icons.badge),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (codigoController.text.isEmpty ||
                    passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Complete todos los campos'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                _approveFirefighter(
                  firefighter.id,
                  codigoController.text,
                  passwordController.text,
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Aprobar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRejectDialog(PendingFirefighter firefighter) async {
    final codigoController = TextEditingController();
    final passwordController = TextEditingController();
    bool isPasswordVisible = false;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red.shade600, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Rechazar Solicitud',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Estás seguro de rechazar la solicitud de ${firefighter.nombre}?',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),

                // Credenciales del jefe
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.security, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Verificación de Jefe',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: codigoController,
                        decoration: InputDecoration(
                          labelText: 'Código de Jefe',
                          prefixIcon: const Icon(Icons.badge),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (codigoController.text.isEmpty ||
                    passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Complete todos los campos'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                _rejectFirefighter(
                  firefighter.id,
                  codigoController.text,
                  passwordController.text,
                );
              },
              icon: const Icon(Icons.close),
              label: const Text('Rechazar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveFirefighter(
    String bomberoId,
    String codigoJefe,
    String passwordJefe,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      final result = await _approvalService.approveFirefighter(
        bomberoId: bomberoId,
        codigoJefe: codigoJefe,
        passwordJefe: passwordJefe,
      );

      if (mounted) {
        Navigator.pop(context); // Cerrar loading

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(result['message'])),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadPendingFirefighters(); // Recargar lista
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(result['message'])),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<void> _rejectFirefighter(
    String bomberoId,
    String codigoJefe,
    String passwordJefe,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      final result = await _approvalService.rejectFirefighter(
        bomberoId: bomberoId,
        codigoJefe: codigoJefe,
        passwordJefe: passwordJefe,
      );

      if (mounted) {
        Navigator.pop(context);

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(result['message'])),
                ],
              ),
              backgroundColor: Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadPendingFirefighters();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(result['message'])),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Aprobar Bomberos'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingFirefighters,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.red),
            )
          : _error.isNotEmpty
              ? _buildErrorState()
              : _pendingFirefighters.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadPendingFirefighters,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pendingFirefighters.length,
                        itemBuilder: (context, index) {
                          final firefighter = _pendingFirefighters[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: _buildFirefighterCard(firefighter),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildFirefighterCard(PendingFirefighter firefighter) {
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.orange.shade600,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firefighter.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        firefighter.codigoBombero,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'PENDIENTE',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Información
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.email, 'Email', firefighter.email),
                  _buildDetailRow(
                      Icons.credit_card, 'Cédula', firefighter.cedula),
                  _buildDetailRow(Icons.phone, 'Teléfono', firefighter.telefono),
                  _buildDetailRow(Icons.location_on, 'Estación',
                      firefighter.estacionPertenencia),
                  _buildDetailRow(Icons.military_tech, 'Rango',
                      firefighter.rango.toUpperCase()),
                  _buildDetailRow(Icons.work, 'Experiencia',
                      '${firefighter.experienciaAnos} años'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(firefighter),
                    icon: const Icon(Icons.close),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade600),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApprovalDialog(firefighter),
                    icon: const Icon(Icons.check),
                    label: const Text('Aprobar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 80, color: Colors.green.shade300),
            const SizedBox(height: 16),
            const Text(
              'No hay solicitudes pendientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Todas las solicitudes han sido procesadas',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
              'Error al cargar solicitudes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_error, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPendingFirefighters,
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
}