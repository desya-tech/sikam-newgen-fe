import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/auth_model.dart';

class AuthService {
  final _api = ApiClient();

  Future<AuthModel> login(String email, String password) async {
    print('LOGIN dengan: $email');
    try {
      final data = await _api.post(
        ApiConstants.login,
        data: {'EMAIL': email, 'PASSWORD': password},
      );
      print('LOGIN RESPONSE: $data');
      if (data is Map) print('ROLE FROM LOGIN: ${data["role"]}');
      final auth = AuthModel.fromJson(Map<String, dynamic>.from(data));
      print('LOGIN OK: ${auth.username}');
      return auth;
    } catch (e) {
      print('LOGIN ERROR: $e');
      rethrow;
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    String? noHp,
  }) async {
    await _api.post(ApiConstants.register, data: {
      'username': username,
      'email': email,
      'password': password,
      if (noHp != null) 'no_hp': noHp,
    });
  }

  Future<void> forgotPassword(String email) async {
    await _api.post(ApiConstants.forgotPassword, data: {'email': email});
  }
}