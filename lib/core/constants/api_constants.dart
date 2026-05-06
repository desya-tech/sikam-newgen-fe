class ApiConstants {
  // Untuk Android emulator gunakan 10.0.2.2
  // Untuk device fisik gunakan IP LAN komputer: 192.168.x.x
  static const String baseUrl = 'http://192.168.1.91:3000';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Kambing
  static const String kambing = '/kambing';
  static String kambingDetail(int id) => '/kambing/$id';
  static String kambingPerkembangan(int id) => '/kambing/$id/perkembangan';
  static String kambingRegenerateQr(int id) => '/kambing/$id/regenerate-qr';
  static String kambingScan(String token) => '/kambing/scan/$token';
  static const String kambingStatistik = '/kambing/statistik';
  static const String kambingStatistikKelamin = '/kambing/statistik/kelamin';
  static const String kambingStatistikJenis = '/kambing/statistik/jenis';
  static const String kambingSakit = '/kambing/sakit';
  static const String kambingPerluPerhatian = '/kambing/perlu-perhatian';

  // User
  static const String user = '/user';
  static String userDetail(int id) => '/user/$id';
  static String userGeminiKey(int id) => '/user/$id/gemini-key';
  static String userAvatar(int id) => '/user/$id/avatar';

  // Role
  static const String role = '/role';
  static String roleDetail(int id) => '/role/$id';
  static const String rolePermissions = '/role/permissions';

  // Upload
  static const String uploadIcon = '/upload/icon';
  static const String uploadAvatar = '/upload/avatar';

  // Static files
  static String uploads(String path) => '$baseUrl/uploads/$path';
}
