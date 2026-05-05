class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class UnauthorizedException extends AppException {
  UnauthorizedException() : super('Sesi habis. Silakan login kembali.', statusCode: 401);
}

class ForbiddenException extends AppException {
  ForbiddenException() : super('Anda tidak memiliki akses ke fitur ini.', statusCode: 403);
}

class NotFoundException extends AppException {
  NotFoundException(String resource) : super('$resource tidak ditemukan.', statusCode: 404);
}

class ServerException extends AppException {
  ServerException() : super('Terjadi kesalahan pada server. Coba lagi.', statusCode: 500);
}

class NetworkException extends AppException {
  NetworkException() : super('Tidak dapat terhubung ke server. Periksa koneksi internet.', statusCode: 0);
}

class ValidationException extends AppException {
  final Map<String, String>? errors;
  ValidationException(String message, {this.errors}) : super(message, statusCode: 422);
}
