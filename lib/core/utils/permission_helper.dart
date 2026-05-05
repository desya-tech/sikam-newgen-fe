import '../storage/local_storage.dart';

class PermissionHelper {
  static List<String> _permissions = [];

  static void load() {
    _permissions = LocalStorage.getPermissions();
  }

  static bool has(String permission) => _permissions.contains(permission);

  static bool hasAny(List<String> permissions) =>
      permissions.any((p) => _permissions.contains(p));

  static bool hasAll(List<String> permissions) =>
      permissions.every((p) => _permissions.contains(p));

  // Kambing
  static bool get canViewKambing => has('KAMBING_VIEW');
  static bool get canCreateKambing => has('KAMBING_CREATE');
  static bool get canUpdateKambing => has('KAMBING_UPDATE');
  static bool get canDeleteKambing => has('KAMBING_DELETE');
  static bool get canScanKambing => has('KAMBING_SCAN');

  // Perkembangan
  static bool get canViewPerkembangan => has('PERKEMBANGAN_VIEW');
  static bool get canCreatePerkembangan => has('PERKEMBANGAN_CREATE');

  // Monitoring
  static bool get canViewStatistik => has('STATISTIK_VIEW');
  static bool get canViewMonitoring => has('MONITORING_KESEHATAN');
  static bool get canViewRecordMati => has('RECORD_MATI_VIEW');

  // User
  static bool get canViewUser => has('USER_VIEW');
  static bool get canCreateUser => has('USER_CREATE');
  static bool get canUpdateUser => has('USER_UPDATE');
  static bool get canDeleteUser => has('USER_DELETE');

  // Role
  static bool get canViewRole => has('ROLE_VIEW');
  static bool get canCreateRole => has('ROLE_CREATE');
  static bool get canUpdateRole => has('ROLE_UPDATE');
  static bool get canDeleteRole => has('ROLE_DELETE');

  // Dashboard
  static bool get canViewDashboard => has('DASHBOARD_VIEW');

  // Upload
  static bool get canUploadIcon => has('UPLOAD_ICON');
}
