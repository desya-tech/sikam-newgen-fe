import 'package:flutter/foundation.dart';
import '../models/kambing_model.dart';
import '../models/perkembangan_model.dart';
import '../services/kambing_service.dart';

class KambingProvider extends ChangeNotifier {
  final _service = KambingService();

  List<KambingModel> _list = [];
  KambingModel? _selected;
  PerkembanganSummary? _perkembangan;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  String? _filterStatus;
  String? _filterKondisi;
  String _search = '';

  List<KambingModel> get list => _list;
  KambingModel? get selected => _selected;
  PerkembanganSummary? get perkembangan => _perkembangan;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  Future<void> loadAll({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      _list = await _service.getAll(
        status: _filterStatus,
        kondisi: _filterKondisi,
        search: _search.isEmpty ? null : _search,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDetail(int id) async {
    _isLoading = true;
    _error = null;
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

  Future<void> loadPerkembangan(int id) async {
    try {
      _perkembangan = await _service.getPerkembangan(id);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> create(Map<String, dynamic> payload) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
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
    _isSubmitting = true;
    _error = null;
    notifyListeners();
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
      _list.removeWhere((k) => k.kambingId == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addPerkembangan(int kambingId, Map<String, dynamic> payload) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _service.addPerkembangan(kambingId, payload);
      await loadPerkembangan(kambingId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<KambingModel?> scanQr(String token) async {
    try {
      return await _service.scanQr(token);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void setSearch(String q) {
    _search = q;
    loadAll(silent: true);
  }

  void setFilter({String? status, String? kondisi, bool silent = false}) {
    _filterStatus = status;
    _filterKondisi = kondisi;
    loadAll(silent: silent);
  }

  void clearFilters() {
    _filterStatus = null;
    _filterKondisi = null;
    _search = '';
    loadAll();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}