import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static late SharedPreferences _prefs;

  // lib/utils/shared_prefs.dart
  static Future<void> init() async {
    try {
      print('Intentando inicializar SharedPreferences...');
      _prefs = await SharedPreferences.getInstance();
      print('SharedPreferences inicializado correctamente');
    } catch (e) {
      print('Error al inicializar SharedPreferences: $e');
      // Puedes manejar el error aquí o relanzarlo
      rethrow;
    }
  }

  // Token
  static Future<bool> setToken(String token) async {
    return await _prefs.setString('token', token);
  }

  static String? getToken() {
    return _prefs.getString('token');
  }

  // User ID
  static Future<bool> setUserId(String userId) async {
    return await _prefs.setString('userId', userId);
  }

  static String? getUserId() {
    return _prefs.getString('userId');
  }

  // User Role
  static Future<bool> setIsBombero(bool isBombero) async {
    return await _prefs.setBool('isBombero', isBombero);
  }

  static bool getIsBombero() {
    return _prefs.getBool('isBombero') ?? false;
  }

  // User Data
  static Future<bool> setUserData(String userData) async {
    return await _prefs.setString('userData', userData);
  }

  static String? getUserData() {
    return _prefs.getString('userData');
  }

  // Clear all data
  static Future<bool> clear() async {
    return await _prefs.clear();
  }
}
