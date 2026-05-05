import 'package:flutter/foundation.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';
import '../core/storage/local_storage.dart';
import '../core/utils/permission_helper.dart';

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  AuthModel? _user;
  bool _isLoading = false;
  String? _error;

  AuthModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null && LocalStorage.isLoggedIn;

  AuthProvider() {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final jsonStr = LocalStorage.getUserData();
    if (jsonStr != null) {
      _user = AuthModel.fromJsonString(jsonStr);
      if (_user != null) {
        // Load permissions dari role object
        final perms = _user!.role.permissions;
        LocalStorage.setPermissions(perms);
        PermissionHelper.load();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final auth = await _service.login(email, password);
      _user = auth;

      // Simpan token dan data user
      await LocalStorage.setToken(auth.token);
      await LocalStorage.setUserData(auth.toJsonString());

      // Simpan permissions (kode string dari role)
      final perms = auth.role.permissions;
      print('SAVING PERMISSIONS: $perms');
      await LocalStorage.setPermissions(perms);
      PermissionHelper.load();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await LocalStorage.clear();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}