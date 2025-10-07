import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class PinManager {
  static const String _userPinKey = 'user_pin';
  static const String _adminPinKey = 'admin_pin';
  static const String _lastUserAccessKey = 'last_user_access';
  static const String _pinsSetupKey = 'pins_setup';

  static String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  static Future<bool> arePinsSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinsSetupKey) ?? false;
  }

  static Future<void> setupPins(String userPin, String adminPin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userPinKey, _hashPin(userPin));
    await prefs.setString(_adminPinKey, _hashPin(adminPin));
    await prefs.setBool(_pinsSetupKey, true);
  }

  static Future<bool> verifyUserPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_userPinKey);
    if (storedHash == null) return false;
    
    final isValid = storedHash == _hashPin(pin);
    if (isValid) {
      await prefs.setInt(_lastUserAccessKey, DateTime.now().millisecondsSinceEpoch);
    }
    return isValid;
  }

  static Future<bool> verifyAdminPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_adminPinKey);
    return storedHash != null && storedHash == _hashPin(pin);
  }

  static Future<bool> isUserPinExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAccess = prefs.getInt(_lastUserAccessKey);
    if (lastAccess == null) return true;

    final lastAccessDate = DateTime.fromMillisecondsSinceEpoch(lastAccess);
    final today = DateTime.now();
    
    return lastAccessDate.day != today.day || 
           lastAccessDate.month != today.month || 
           lastAccessDate.year != today.year;
  }

  static Future<void> changeUserPin(String newPin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userPinKey, _hashPin(newPin));
  }

  static Future<void> resetUserAccess() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastUserAccessKey);
  }
}