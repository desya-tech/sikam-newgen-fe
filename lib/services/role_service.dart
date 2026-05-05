import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/role_model.dart';

class RoleService {
  final _api = ApiClient();

  Future<List<RoleDetailModel>> getAll() async {
    final data = await _api.get(ApiConstants.role);
    if (data is List) {
      return data.map((e) => RoleDetailModel.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  Future<RoleDetailModel> getById(int id) async {
    final data = await _api.get(ApiConstants.roleDetail(id));
    return RoleDetailModel.fromJson(Map<String, dynamic>.from(data));
  }

  // Response: [{grup: 'Dashboard', permissions: [{permission_id, kode, nama, grup}]}, ...]
  Future<List<PermissionModel>> getAllPermissions() async {
    final data = await _api.get(ApiConstants.rolePermissions);
    final result = <PermissionModel>[];
    if (data is List) {
      for (final group in data) {
        final groupMap = Map<String, dynamic>.from(group);
        final perms = groupMap['permissions'] as List? ?? [];
        for (final p in perms) {
          result.add(PermissionModel.fromJson(Map<String, dynamic>.from(p)));
        }
      }
    }
    return result;
  }

  Future<RoleDetailModel> create(Map<String, dynamic> payload) async {
    final data = await _api.post(ApiConstants.role, data: payload);
    return RoleDetailModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<RoleDetailModel> update(int id, Map<String, dynamic> payload) async {
    final data = await _api.put(ApiConstants.roleDetail(id), data: payload);
    return RoleDetailModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> delete(int id) async {
    await _api.delete(ApiConstants.roleDetail(id));
  }
}