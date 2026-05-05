import 'package:flutter/foundation.dart';
import '../models/role_model.dart';
import '../services/role_service.dart';

class RoleProvider extends ChangeNotifier {
  final _service = RoleService();

  List<RoleDetailModel> _list = [];
  List<PermissionModel> _allPermissions = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  List<RoleDetailModel> get list => _list;
  List<PermissionModel> get allPermissions => _allPermissions;
  Map<String, List<PermissionModel>> get permissionsByGroup {
    final map = <String, List<PermissionModel>>{};
    for (final p in _allPermissions) {
      map.putIfAbsent(p.grup, () => []).add(p);
    }
    return map;
  }
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;


  Future<void> loadAll({bool silent = false}) async {
    if (!silent) { _isLoading = true; _error = null; notifyListeners(); }
    try {
      final results = await Future.wait([
        _service.getAll(),
        _service.getAllPermissions(),
      ]);
      _list = results[0] as List<RoleDetailModel>;
      _allPermissions = results[1] as List<PermissionModel>;
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

  Future<bool> delete(int id) async {
    try {
      await _service.delete(id);
      _list.removeWhere((r) => r.roleId == id);
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
