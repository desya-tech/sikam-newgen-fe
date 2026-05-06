import 'package:flutter/foundation.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../core/storage/local_storage.dart';
import '../core/utils/permission_helper.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();
  final _userService = UserService();

  AuthModel? _user;
  bool _isLoading = false;
  String? _error;

  // Gemini API Key state
  bool _isSavingGeminiKey = false;

  AuthModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null && LocalStorage.isLoggedIn;
  bool get isSavingGeminiKey => _isSavingGeminiKey;

  /// Gemini API Key milik user yang login
  String? get geminiApiKey => _user?.geminiApiKey;

  AuthProvider() {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final jsonStr = LocalStorage.getUserData();
    if (jsonStr != null) {
      _user = AuthModel.fromJsonString(jsonStr);
      if (_user != null) {
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
      final auth = await _authService.login(email, password);
      _user = auth;

      await LocalStorage.setToken(auth.token);
      await LocalStorage.setUserData(auth.toJsonString());

      final perms = auth.role.permissions;
      print('SAVING PERMISSIONS: $perms');
      await LocalStorage.setPermissions(perms);
      PermissionHelper.load();

      // Load gemini key dari server setelah login
      _loadGeminiKeyFromServer(auth.userId);

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

  /// Load gemini key dari server (background, tidak block UI)
  Future<void> _loadGeminiKeyFromServer(int userId) async {
    try {
      final key = await _userService.getGeminiKey(userId);
      if (key != null && key.isNotEmpty && _user != null) {
        _user = _user!.copyWith(geminiApiKey: key);
        await LocalStorage.setUserData(_user!.toJsonString());
        notifyListeners();
      }
    } catch (_) {
      // Gagal load key tidak blocking
    }
  }

  /// Simpan Gemini API Key ke server dan update local state
  Future<bool> saveGeminiKey(String apiKey) async {
    if (_user == null) return false;

    _isSavingGeminiKey = true;
    notifyListeners();

    try {
      await _userService.saveGeminiKey(_user!.userId, apiKey.trim());

      // Update local state & storage
      _user = _user!.copyWith(geminiApiKey: apiKey.trim());
      await LocalStorage.setUserData(_user!.toJsonString());

      _isSavingGeminiKey = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSavingGeminiKey = false;
      notifyListeners();
      return false;
    }
  }

  /// Hapus Gemini API Key
  Future<bool> removeGeminiKey() async {
    if (_user == null) return false;
    try {
      await _userService.saveGeminiKey(_user!.userId, '');
      _user = _user!.copyWith(geminiApiKey: '');
      await LocalStorage.setUserData(_user!.toJsonString());
      notifyListeners();
      return true;
    } catch (_) {
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