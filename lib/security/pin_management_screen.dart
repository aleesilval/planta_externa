import 'package:flutter/material.dart';
import 'pin_manager.dart';

class PinManagementScreen extends StatefulWidget {
  const PinManagementScreen({super.key});

  @override
  State<PinManagementScreen> createState() => _PinManagementScreenState();
}

class _PinManagementScreenState extends State<PinManagementScreen> {
  final _adminPinController = TextEditingController();
  final _newUserPinController = TextEditingController();
  final _confirmUserPinController = TextEditingController();
  bool _isLoading = false;
  bool _adminVerified = false;

  Future<void> _verifyAdminPin() async {
    if (_adminPinController.text.length < 4) {
      _showError('Ingrese un PIN válido');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isValid = await PinManager.verifyAdminPin(_adminPinController.text);
      if (isValid) {
        setState(() => _adminVerified = true);
      } else {
        _showError('PIN de administrador incorrecto');
        _adminPinController.clear();
      }
    } catch (e) {
      _showError('Error al verificar PIN: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeUserPin() async {
    if (_newUserPinController.text.length < 4) {
      _showError('El nuevo PIN debe tener al menos 4 dígitos');
      return;
    }

    if (_newUserPinController.text != _confirmUserPinController.text) {
      _showError('Los PINs no coinciden');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await PinManager.changeUserPin(_newUserPinController.text);
      await PinManager.resetUserAccess();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN de usuario cambiado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('Error al cambiar PIN: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetUserAccess() async {
    setState(() => _isLoading = true);

    try {
      await PinManager.resetUserAccess();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acceso de usuario restablecido'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error al restablecer acceso: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de PINs'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: !_adminVerified ? _buildAdminVerification() : _buildManagementOptions(),
        ),
      ),
    );
  }

  Widget _buildAdminVerification() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.admin_panel_settings,
          size: 80,
          color: Colors.orange,
        ),
        const SizedBox(height: 32),
        const Text(
          'Verificación de Administrador',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Ingrese su PIN de administrador para acceder a la gestión',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _adminPinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          decoration: const InputDecoration(
            labelText: 'PIN de Administrador',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          onSubmitted: (_) => _verifyAdminPin(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyAdminPin,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Verificar'),
          ),
        ),
      ],
    );
  }

  Widget _buildManagementOptions() {
    return Column(
      children: [
        const Text(
          'Gestión de PINs',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cambiar PIN de Usuario',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newUserPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Nuevo PIN de Usuario',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmUserPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Nuevo PIN',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changeUserPin,
                    child: const Text('Cambiar PIN de Usuario'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Restablecer Acceso',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fuerza al usuario a ingresar su PIN nuevamente',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetUserAccess,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Restablecer Acceso de Usuario'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}