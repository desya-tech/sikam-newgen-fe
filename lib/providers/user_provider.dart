import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final _service = UserService();

  List<UserModel> _list = [];
  UserModel? _selected;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  List<UserModel> get list => _list;
  UserModel? get selected => _selected;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;


  Future<void> loadAll({bool silent = false}) async {
    if (!silent) { _isLoading = true; _error = null; notifyListeners(); }
    try {
      _list = await _service.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDetail(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _selected = await _service.getById(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create(Map<String, dynamic> payload) async {
    _isSubmitting = true; _error = null; notifyListeners();
    try {
      await _service.create(payload);
      await loadAll(silent: true);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> update(int id, Map<String, dynamic> payload) async {
    _isSubmitting = true; _error = null; notifyListeners();
    try {
      await _service.update(id, payload);
      await loadAll(); // force full reload
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> delete(int id) async {
    try {
      await _service.delete(id);
      _list.removeWhere((u) => u.userId == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }




  void clearError() { _error = null; notifyListeners(); }
}