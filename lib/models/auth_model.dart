import 'dart:convert';

class AuthModel {
  final int userId;
  final String username;
  final String email;
  final String? noHp;
  final String? fotoProfil;
  final RoleModel role;
  final String token;

  AuthModel({
    required this.userId,
    required this.username,
    required this.email,
    this.noHp,
    this.fotoProfil,
    required this.role,
    required this.token,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) => AuthModel(
    userId:     json['user_id'] ?? 0,
    username:   json['username'] ?? '',
    email:      json['email'] ?? '',
    noHp:       json['no_hp'],
    fotoProfil: json['foto_profil'],
    role:       RoleModel.fromJson(json['role'] ?? {}),
    token:      json['token'] ?? '',
  );

  String toJsonString() => jsonEncode(toJson());

  Map<String, dynamic> toJson() => {
    'user_id':    userId,
    'username':   username,
    'email':      email,
    'no_hp':      noHp,
    'foto_profil': fotoProfil,
    'role':       role.toJson(),
    'token':      token,
  };

  static AuthModel? fromJsonString(String? jsonString) {
    if (jsonString == null) return null;
    try {
      return AuthModel.fromJson(jsonDecode(jsonString));
    } catch (_) {
      return null;
    }
  }
}

class RoleModel {
  final int roleId;
  final String namaRole;
  final List<String> permissions;
  final Map<String, List<String>> menu;

  RoleModel({
    required this.roleId,
    required this.namaRole,
    required this.permissions,
    required this.menu,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    // permissions bisa List<String> atau List<Map>
    final rawPerms = json['permissions'] as List? ?? [];
    final List<String> permKodes = rawPerms.map((p) {
      if (p is String) return p;
      if (p is Map) return (p['kode'] ?? '').toString();
      return '';
    }).where((k) => k.isNotEmpty).toList();

    // menu bisa Map<String, List<String>> atau Map<String, List<Map>>
    final rawMenu = json['menu'] as Map<String, dynamic>? ?? {};
    final Map<String, List<String>> menu = rawMenu.map((k, v) {
      if (v is List) {
        return MapEntry(k, v.map((item) {
          if (item is String) return item;
          if (item is Map) return (item['kode'] ?? '').toString();
          return '';
        }).where((s) => s.isNotEmpty).toList());
      }
      return MapEntry(k, <String>[]);
    });

    return RoleModel(
      roleId:      json['role_id'] ?? 0,
      namaRole:    json['nama_role'] ?? '',
      permissions: permKodes,
      menu:        menu,
    );
  }

  Map<String, dynamic> toJson() => {
    'role_id':     roleId,
    'nama_role':   namaRole,
    'permissions': permissions,
    'menu':        menu,
  };
}