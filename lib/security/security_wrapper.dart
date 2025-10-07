import 'package:flutter/material.dart';
import 'pin_manager.dart';
import 'pin_setup_screen.dart';
import 'pin_entry_screen.dart';

class SecurityWrapper extends StatefulWidget {
  final Widget child;
  
  const SecurityWrapper({super.key, required this.child});

  @override
  State<SecurityWrapper> createState() => _SecurityWrapperState();
}

class _SecurityWrapperState extends State<SecurityWrapper> {
  bool _isLoading = true;
  bool _pinsSetup = false;
  bool _needsPinEntry = false;

  @override
  void initState() {
    super.initState();
    _checkSecurityStatus();
  }

  Future<void> _checkSecurityStatus() async {
    try {
      final pinsSetup = await PinManager.arePinsSetup();
      
      if (pinsSetup) {
        final isExpired = await PinManager.isUserPinExpired();
        if (mounted) {
          setState(() {
            _pinsSetup = true;
            _needsPinEntry = isExpired;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _pinsSetup = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pinsSetup = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_pinsSetup) {
      return const PinSetupScreen();
    }

    if (_needsPinEntry) {
      return const PinEntryScreen();
    }

    return widget.child;
  }
}