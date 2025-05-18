import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app_emergency/utils/shared_prefs.dart';
import 'package:app_emergency/models/user.dart';

class AuthService with ChangeNotifier {
  String? _token;
  String? _userId;
  bool _isBombero = false;
  User? _user;

  bool get isAuth => _token != null;
  String? get token => _token;
  String? get userId => _userId;
  bool get isBombero => _isBombero;
  User? get user => _user;

  Future<bool> tryAutoLogin() async {
    final token = SharedPrefs.getToken();
    print('Token recuperado de SharedPrefs: $token');

    if (token == null) {
      print('No hay token guardado');
      return false;
    }

    _token = token;
    _userId = SharedPrefs.getUserId();
    _isBombero = SharedPrefs.getIsBombero();

    print('Usuario ID recuperado: $_userId');
    print('Es bombero recuperado: $_isBombero');

    final userData = SharedPrefs.getUserData();
    if (userData != null) {
      try {
        _user = User.fromJson(json.decode(userData));
        print('Datos de usuario recuperados: ${_user?.toJson()}');
      } catch (e) {
        print('Error al decodificar datos de usuario: $e');
        return false;
      }
    }

    notifyListeners();
    return true;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Intentando login con: $email');
      print('URL: https://emergencyapi-production.up.railway.app/api/auth/login');

      final body = json.encode({'email': email, 'password': password});
      print('Body: $body');

      final response = await http.post(
        Uri.parse('https://emergencyapi-production.up.railway.app/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode != 200) {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error de autenticación',
        };
      }

      // Decodificar la respuesta
      final responseData = json.decode(response.body);
      print('Datos decodificados: $responseData');

      try {
        // Extraer los datos necesarios
        _token = responseData['access_token'];
        print('Token extraído: $_token');

        _userId = responseData['usuario']['id'].toString();
        print('ID de usuario extraído: $_userId');

        _isBombero = responseData['usuario']['es_bombero'] ?? false;
        print('Es bombero extraído: $_isBombero');

        _user = User.fromJson(responseData['usuario']);
        print('Usuario extraído: ${_user?.toJson()}');

        // Guardar datos en SharedPreferences
        print('Guardando token en SharedPrefs: $_token');
        final tokenSaved = await SharedPrefs.setToken(_token!);
        print('Token guardado: $tokenSaved');

        print('Guardando ID de usuario en SharedPrefs: $_userId');
        final userIdSaved = await SharedPrefs.setUserId(_userId!);
        print('ID de usuario guardado: $userIdSaved');

        print('Guardando es_bombero en SharedPrefs: $_isBombero');
        final isBomberoSaved = await SharedPrefs.setIsBombero(_isBombero);
        print('Es bombero guardado: $isBomberoSaved');

        print('Guardando datos de usuario en SharedPrefs');
        final userDataSaved = await SharedPrefs.setUserData(
          json.encode(responseData['usuario']),
        );
        print('Datos de usuario guardados: $userDataSaved');

        notifyListeners();
        return {'success': true};
      } catch (e) {
        print('Error al procesar los datos de respuesta: $e');
        return {
          'success': false,
          'message': 'Error desconocido. No se pudo completar la operación.',
        };
      }
    } catch (error) {
      print('Excepción capturada: $error');
      return {
        'success': false,
        'message': 'No se pudo conectar al servidor. Verifica tu conexión.',
      };
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _isBombero = false;
    _user = null;
    await SharedPrefs.clear();
    notifyListeners();
  }

  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('https://emergencyapi-production.up.railway.app/api/usuarios/perfil'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode(userData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al actualizar perfil',
        };
      }

      // Actualizar datos del usuario
      _user = User.fromJson(responseData['usuario']);
      await SharedPrefs.setUserData(json.encode(responseData['usuario']));

      notifyListeners();
      return {'success': true};
    } catch (error) {
      return {
        'success': false,
        'message': 'No se pudo conectar al servidor. Verifica tu conexión.',
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String nombre,
    required String apellido,
    required String email,
    required String telefono,
    required String password,
    required bool esBombero,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://emergencyapi-production.up.railway.app/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre': nombre,
          'apellido': apellido,
          'email': email,
          'telefono': telefono,
          'password': password,
          'es_bombero': esBombero,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode >= 400) {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error en el registro',
        };
      }

      return {
        'success': true,
        'message': responseData['mensaje'] ?? 'Usuario registrado exitosamente',
      };
    } catch (error) {
      print('Error en el registro: $error');
      return {
        'success': false,
        'message': 'Error en la conexión. Intente nuevamente.',
      };
    }
  }
}
