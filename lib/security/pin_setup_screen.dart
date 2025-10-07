import 'package:flutter/material.dart';
import 'pin_manager.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _userPinController = TextEditingController();
  final _adminPinController = TextEditingController();
  final _confirmUserPinController = TextEditingController();
  final _confirmAdminPinController = TextEditingController();
  bool _isLoading = false;

  Future<void> _setupPins() async {
    if (_userPinController.text.length < 4 || _adminPinController.text.length < 4) {
      _showError('Los PINs deben tener al menos 4 dígitos');
      return;
    }

    if (_userPinController.text != _confirmUserPinController.text) {
      _showError('Los PINs de usuario no coinciden');
      return;
    }

    if (_adminPinController.text != _confirmAdminPinController.text) {
      _showError('Los PINs de administrador no coinciden');
      return;
    }

    if (_userPinController.text == _adminPinController.text) {
      _showError('El PIN de usuario y administrador deben ser diferentes');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await PinManager.setupPins(_userPinController.text, _adminPinController.text);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    } catch (e) {
      _showError('Error al configurar PINs: $e');
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
        title: const Text('Configuración Inicial de Seguridad'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
            const Text(
              'Configure los PINs de seguridad para la aplicación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _userPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'PIN de Usuario (acceso diario)',
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
                labelText: 'Confirmar PIN de Usuario',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _adminPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'PIN de Administrador (gestión)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmAdminPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Confirmar PIN de Administrador',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _setupPins,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Configurar PINs'),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}