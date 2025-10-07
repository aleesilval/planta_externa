import 'package:flutter/material.dart';
import 'pin_manager.dart';

class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _showAdminOption = false;
  String _currentMode = 'user'; // 'user' or 'admin'

  @override
  void initState() {
    super.initState();
    _checkPinExpiration();
  }

  Future<void> _checkPinExpiration() async {
    final isExpired = await PinManager.isUserPinExpired();
    if (!isExpired) {
      // PIN de usuario aún válido, ir directamente a la app
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    }
  }

  Future<void> _verifyPin() async {
    if (_pinController.text.length < 4) {
      _showError('Ingrese un PIN válido');
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool isValid = false;
      
      if (_currentMode == 'user') {
        isValid = await PinManager.verifyUserPin(_pinController.text);
      } else {
        isValid = await PinManager.verifyAdminPin(_pinController.text);
      }

      if (isValid) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/welcome');
        }
      } else {
        _showError('PIN incorrecto');
        _pinController.clear();
      }
    } catch (e) {
      _showError('Error al verificar PIN: $e');
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
        title: Text(_currentMode == 'user' ? 'Acceso de Usuario' : 'Acceso de Administrador'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Icon(
              _currentMode == 'user' ? Icons.person : Icons.admin_panel_settings,
              size: 80,
              color: _currentMode == 'user' ? Colors.blue : Colors.orange,
            ),
            const SizedBox(height: 32),
            Text(
              _currentMode == 'user' 
                  ? 'Ingrese su PIN de Usuario'
                  : 'Ingrese su PIN de Administrador',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: const InputDecoration(
                labelText: 'PIN',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              onSubmitted: (_) => _verifyPin(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyPin,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Ingresar'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentMode = _currentMode == 'user' ? 'admin' : 'user';
                  _pinController.clear();
                });
              },
              child: Text(
                _currentMode == 'user' 
                    ? 'Acceso como Administrador'
                    : 'Acceso como Usuario',
              ),
            ),
            if (_currentMode == 'admin')
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/pin-management');
                },
                child: const Text('Gestionar PINs'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}