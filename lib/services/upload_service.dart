import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';

class UploadService {
  final _api = ApiClient();

  Future<String> uploadIcon(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });
    final data = await _api.postFormData(ApiConstants.uploadIcon, formData);
    print('=== UPLOAD ICON RESPONSE: $data ===');
    // Backend bisa return gambar_id, filename, atau path
    return data['gambar_id']?.toString() ??
        data['filename']?.toString() ??
        data['path']?.toString() ??
        data.toString();
  }

  Future<String> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });
    final data = await _api.postFormData(ApiConstants.uploadAvatar, formData);
    print('=== UPLOAD AVATAR RESPONSE: $data ===');
    return data['foto_profil']?.toString() ??
        data['filename']?.toString() ??
        data['path']?.toString() ??
        data.toString();
  }
}