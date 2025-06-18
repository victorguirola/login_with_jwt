// frontend/lib/services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/secure_storage.dart';

class AuthService with ChangeNotifier {
  // Ajusta esta URL para que tu frontend acceda al backend de Docker.
  // Si Flutter Web se ejecuta en tu máquina host y el backend en Docker,
  // 'localhost' está bien si el puerto está mapeado (ej. 3000:3000).
  // Si el frontend también se ejecuta en un contenedor, usa 'http://host.docker.internal:3000'
  // Si el backend está en un servidor remoto, usa su IP o dominio.
  //static const String _baseUrl = 'http://localhost:3000/api'; // URL de tu API Express
  static const String _baseUrl = 'http://host.docker.internal:3000/api'; // URL de tu API Express  

  User? _currentUser;
  String? _jwtToken;
  bool _isLoading = false;
  String? _errorMessage;

  final SecureStorage _secureStorage = SecureStorage();

  User? get currentUser => _currentUser;
  String? get jwtToken => _jwtToken;
  bool get isAuthenticated => _jwtToken != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthService() {
    _loadJwtToken(); // Intenta cargar el token al iniciar el servicio
  }

  Future<void> _loadJwtToken() async {
    _jwtToken = await _secureStorage.getJwtToken();
    if (_jwtToken != null) {
      // Opcional: Decodificar el token para obtener info del usuario si es necesario
      // Pero para este ejemplo, solo nos importa su presencia para isAuthenticated
      print('Token JWT cargado: $_jwtToken');
    } else {
      print('No hay token JWT almacenado.');
    }
    notifyListeners();
  }

  // --- Métodos de Autenticación ---

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        _jwtToken = responseData['token'];
        await _secureStorage.saveJwtToken(_jwtToken!);
        _currentUser = User(id: -1, username: username); // Solo un placeholder de usuario
        print('Login exitoso. Token: $_jwtToken');
        return true;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        _errorMessage = errorData['message'] ?? 'Error de inicio de sesión.';
        print('Error de login: $_errorMessage');
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error de conexión: $e';
      print('Excepción de login: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      if (response.statusCode == 201) { // 201 Created
        _errorMessage = null; // Limpiar cualquier error anterior
        print('Registro exitoso.');
        return true;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        _errorMessage = errorData['message'] ?? 'Error de registro.';
        print('Error de registro: $_errorMessage');
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error de conexión: $e';
      print('Excepción de registro: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() async {
    _jwtToken = null;
    _currentUser = null;
    _errorMessage = null;
    await _secureStorage.deleteJwtToken();
    print('Sesión cerrada.');
    notifyListeners();
  }

  // --- Método para acceder a una ruta protegida (ejemplo) ---
  Future<String> getProtectedData() async {
    if (!isAuthenticated) {
      return 'No autenticado para acceder a datos protegidos.';
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/protected'),
        headers: {
          'Authorization': 'Bearer $_jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['message'] ?? 'Datos protegidos obtenidos.';
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Token inválido o expirado, forzar logout
        logout();
        return 'Sesión expirada o inválida. Por favor, inicie sesión de nuevo.';
      } else {
        return 'Error al obtener datos protegidos: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error de conexión al obtener datos protegidos: $e';
    }
  }
}