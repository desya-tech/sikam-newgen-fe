import 'package:flutter/foundation.dart';
import '../models/statistik_model.dart';
import '../models/kambing_model.dart';
import '../services/monitoring_service.dart';

class MonitoringProvider extends ChangeNotifier {
  final _service = MonitoringService();

  StatistikModel? _statistik;
  StatistikKelamin? _kelamin;
  List<StatistikJenis> _perJenis = [];
  List<KambingModel> _sakit = [];
  List<KambingModel> _perluPerhatian = [];

  String _penambahanFilter = 'bulan'; // minggu, bulan, tahun
  List<StatistikPenambahan> _penambahanData = [];

  bool _isLoading = false;
  String? _error;

  StatistikModel? get statistik => _statistik;
  StatistikKelamin? get kelamin => _kelamin;
  List<StatistikJenis> get perJenis => _perJenis;
  List<KambingModel> get sakit => _sakit;
  List<KambingModel> get perluPerhatian => _perluPerhatian;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get penambahanFilter => _penambahanFilter;
  List<StatistikPenambahan> get penambahanData => _penambahanData.isNotEmpty ? _penambahanData : (_statistik?.penambahan ?? []);

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getStatistik(),
        _service.getStatistikKelamin(),
        _service.getStatistikJenis(),
        _service.getKambingSakit(),
        _service.getPerluPerhatian(),
      ]);
      _statistik = results[0] as StatistikModel;
      _kelamin = results[1] as StatistikKelamin;
      _perJenis = results[2] as List<StatistikJenis>;
      _sakit = results[3] as List<KambingModel>;
      _perluPerhatian = results[4] as List<KambingModel>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ubahFilterPenambahan(String filter) async {
    _penambahanFilter = filter;
    notifyListeners();
    try {
      final data = await _service.getPenambahan(filter);
      _penambahanData = data;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Gagal load penambahan: $e');
    }
  }
}
