import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/kambing_model.dart';
import '../models/perkembangan_model.dart';

class KambingService {
  final _api = ApiClient();

  Future<List<KambingModel>> getAll({String? status, String? kondisi, String? search}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (kondisi != null) params['kondisi'] = kondisi;
    if (search != null) params['search'] = search;

    final data = await _api.get(ApiConstants.kambing, params: params.isEmpty ? null : params);
    if (data is List) {
      return data.map((e) => KambingModel.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    if (data is Map && data.containsKey('data')) {
      return (data['data'] as List)
          .map((e) => KambingModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<KambingModel> getById(int id) async {
    final data = await _api.get(ApiConstants.kambingDetail(id));
    return KambingModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<KambingModel> create(Map<String, dynamic> payload) async {
    final data = await _api.post(ApiConstants.kambing, data: payload);
    return KambingModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<KambingModel> update(int id, Map<String, dynamic> payload) async {
    final data = await _api.put(ApiConstants.kambingDetail(id), data: payload);
    return KambingModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> delete(int id) async {
    await _api.delete(ApiConstants.kambingDetail(id));
  }

  Future<KambingModel> scanQr(String token) async {
    final data = await _api.get(ApiConstants.kambingScan(token));
    return KambingModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> regenerateQr(int id) async {
    await _api.post(ApiConstants.kambingRegenerateQr(id));
  }

  Future<PerkembanganSummary> getPerkembangan(int id) async {
    final data = await _api.get(ApiConstants.kambingPerkembangan(id));
    if (data is List) {
      final records = data
          .map((e) => PerkembanganModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return PerkembanganSummary(records: records);
    }
    return PerkembanganSummary.fromJson(Map<String, dynamic>.from(data));
  }

  Future<PerkembanganModel> addPerkembangan(int kambingId, Map<String, dynamic> payload) async {
    final data = await _api.post(ApiConstants.kambingPerkembangan(kambingId), data: payload);
    return PerkembanganModel.fromJson(Map<String, dynamic>.from(data));
  }
}