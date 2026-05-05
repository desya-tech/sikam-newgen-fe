class UserModel {
  final int userId;
  final String username;
  final String email;
  final String? noHp;
  final String? fotoProfil;
  final int? roleId;
  final String? namaRole;
  final String? createdAt;

  UserModel({
    required this.userId,
    required this.username,
    required this.email,
    this.noHp,
    this.fotoProfil,
    this.roleId,
    this.namaRole,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // role selalu object: {role_id, nama_role, ...}
    final role     = json['role'];
    final roleId   = _toInt(json['roleid'] ?? json['role_id'] ?? (role is Map ? role['role_id'] : null));
    final namaRole = role is Map ? role['nama_role']?.toString() : null;

    return UserModel(
      userId:     _toInt(json['user_id'] ?? json['id']) ?? 0,
      username:   json['username']?.toString() ?? '',
      email:      json['email']?.toString() ?? '',
      noHp:       json['no_hp']?.toString(),
      fotoProfil: json['foto_profil']?.toString(),
      roleId:     roleId,
      namaRole:   namaRole,
      createdAt:  json['created_at']?.toString(),
    );
  }
}

int? _toInt(dynamic v) => v != null ? int.tryParse(v.toString()) : null;