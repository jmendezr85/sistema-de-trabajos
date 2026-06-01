import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'pb_service.dart';

class AuthProvider extends ChangeNotifier {
  final PocketBaseService _pbService = PocketBaseService();

  String? _userId;
  String? _email;
  String? _role;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  String? get userId => _userId;
  String? get email => _email;
  String? get role => _role;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  bool get isAdmin => _role == 'admin';
  bool get isCajero => _role == 'cajero';

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _pbService.iniciarSesion(email, password);
      if (success) {
        final user = await _pbService.obtenerUsuarioActual();
        _userId = user['id'];
        _email = user['email'];
        _role = user['role'] ?? 'cajero';
        
        developer.log('Login exitoso - Role: $_role, Email: $_email');
        
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Error en login: $e');
      _isAuthenticated = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _pbService.cerrarSesion();
    _userId = null;
    _email = null;
    _role = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> checkAuthentication() async {
    try {
      if (_pbService.pb.authStore.isValid) {
        final user = await _pbService.obtenerUsuarioActual();
        _userId = user['id'];
        _email = user['email'];
        _role = user['role'] ?? 'cajero';
        
        developer.log('Verificación de auth - Role: $_role, Email: $_email');
        
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      developer.log('Error en checkAuthentication: $e');
      _isAuthenticated = false;
    }
    notifyListeners();
  }
}
