import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/kambing_model.dart';
import '../models/statistik_model.dart';

class MonitoringService {
  final _api = ApiClient();

  Future<StatistikModel> getStatistik() async {
    final data = await _api.get(ApiConstants.kambingStatistik);
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    return StatistikModel.fromJson(map);
  }

  Future<StatistikKelamin> getStatistikKelamin() async {
    final data = await _api.get(ApiConstants.kambingStatistikKelamin);
    if (data is List) {
      int jantan = 0;
      int betina = 0;
      for (var item in data) {
        if (item is Map) {
          final k = item['kelamin']?.toString().toLowerCase();
          final v = int.tryParse(item['total']?.toString() ?? item['jumlah']?.toString() ?? '0') ?? 0;
          if (k == 'jantan') jantan = v;
          if (k == 'betina') betina = v;
        }
      }
      return StatistikKelamin(jantan: jantan, betina: betina);
    }
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    return StatistikKelamin.fromJson(map);
  }

  Future<List<StatistikJenis>> getStatistikJenis() async {
    final data = await _api.get(ApiConstants.kambingStatistikJenis);
    if (data is List) {
      return data
          .map((e) => StatistikJenis.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (data is Map && data.containsKey('data')) {
      return (data['data'] as List)
          .map((e) => StatistikJenis.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<List<KambingModel>> getKambingSakit() async {
    final data = await _api.get(ApiConstants.kambingSakit);
    if (data is List) {
      return data
          .map((e) => KambingModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (data is Map && data.containsKey('data')) {
      return (data['data'] as List)
          .map((e) => KambingModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<List<KambingModel>> getPerluPerhatian() async {
    final data = await _api.get(ApiConstants.kambingPerluPerhatian);
    if (data is List) {
      return data
          .map((e) => KambingModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (data is Map && data.containsKey('data')) {
      return (data['data'] as List)
          .map((e) => KambingModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<List<StatistikPenambahan>> getPenambahan(String filter) async {
    final data = await _api.get('${ApiConstants.kambingStatistik}/penambahan?filter=$filter');
    if (data is List) {
      return data
          .map((e) => StatistikPenambahan.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (data is Map && data.containsKey('data')) {
      return (data['data'] as List)
          .map((e) => StatistikPenambahan.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}