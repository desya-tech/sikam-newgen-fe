class RoleDetailModel {
  final int roleId;
  final String namaRole;
  final String? deskripsi;
  final List<String> permissions;      // kode saja: ['DASHBOARD_VIEW', ...]
  final Map<String, List<String>> menu; // grup → [kode, ...]

  RoleDetailModel({
    required this.roleId,
    required this.namaRole,
    this.deskripsi,
    required this.permissions,
    required this.menu,
  });

  factory RoleDetailModel.fromJson(Map<String, dynamic> json) {
    // permissions bisa berupa List<String> atau List<Map>
    final rawPerms = json['permissions'] as List? ?? [];
    final List<String> permKodes = rawPerms.map((p) {
      if (p is String) return p;
      if (p is Map) return (p['kode'] ?? '').toString();
      return '';
    }).where((k) => k.isNotEmpty).toList();

    // Bangun menu dari permissions (grup → [kode])
    final Map<String, List<String>> menu = {};
    for (final p in rawPerms) {
      if (p is Map) {
        final grup = (p['grup'] ?? 'Lainnya').toString();
        final kode = (p['kode'] ?? '').toString();
        if (kode.isNotEmpty) {
          menu.putIfAbsent(grup, () => []).add(kode);
        }
      }
    }

    return RoleDetailModel(
      roleId:      json['role_id'] ?? 0,
      namaRole:    json['nama_role'] ?? '',
      deskripsi:   json['deskripsi'],
      permissions: permKodes,
      menu:        menu,
    );
  }
}

class PermissionModel {
  final int permissionId;
  final String kode;
  final String nama;
  final String grup;

  PermissionModel({
    required this.permissionId,
    required this.kode,
    required this.nama,
    required this.grup,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) => PermissionModel(
    permissionId: json['permission_id'] ?? 0,
    kode:  json['kode']  ?? '',
    nama:  json['nama']  ?? '',
    grup:  json['grup']  ?? '',
  );
}