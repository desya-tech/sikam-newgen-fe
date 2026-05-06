import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';

class UserService {
  final _api = ApiClient();

  Future<List<UserModel>> getAll() async {
    final data = await _api.get(ApiConstants.user);
    if (data is List) {
      return data.map((e) => UserModel.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  Future<UserModel> getById(int id) async {
    final data = await _api.get(ApiConstants.userDetail(id));
    return UserModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<UserModel> create(Map<String, dynamic> payload) async {
    final data = await _api.post(ApiConstants.user, data: payload);
    return UserModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<UserModel> update(int id, Map<String, dynamic> payload) async {
    final data = await _api.put(ApiConstants.userDetail(id), data: payload);
    return UserModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> delete(int id) async {
    await _api.delete(ApiConstants.userDetail(id));
  }

  /// Simpan Gemini API Key ke server (tabel m_user.gemini_api_key)
  Future<void> saveGeminiKey(int userId, String apiKey) async {
    await _api.put(ApiConstants.userGeminiKey(userId), data: {'api_key': apiKey});
  }

  /// Ambil Gemini API Key dari server
  Future<String?> getGeminiKey(int userId) async {
    final data = await _api.get(ApiConstants.userGeminiKey(userId));
    if (data is Map) {
      return data['gemini_api_key']?.toString();
    }
    return null;
  }
}