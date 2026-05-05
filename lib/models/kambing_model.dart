class KambingModel {
  final int kambingId;
  final String namaKambing;
  final String jenisKambing;
  final String kelamin;
  final String? tanggalLahir;
  final double? beratLahir;
  final double? tinggi;
  final int? umur;
  final String kondisi;
  final String status;
  final String? qrCodePath;
  final String? deskripsi;
  final String? createdAt;
  final String? updatedAt;

  KambingModel({
    required this.kambingId,
    required this.namaKambing,
    required this.jenisKambing,
    required this.kelamin,
    this.tanggalLahir,
    this.beratLahir,
    this.tinggi,
    this.umur,
    required this.kondisi,
    required this.status,
    this.qrCodePath,
    this.deskripsi,
    this.createdAt,
    this.updatedAt,
  });

  factory KambingModel.fromJson(Map<String, dynamic> json) => KambingModel(
    kambingId:    _toInt(json['id_kambing'] ?? json['kambing_id'] ?? json['id']) ?? 0,
    namaKambing:  json['nama'] ?? json['nama_kambing'] ?? '',
    jenisKambing: json['jenis'] ?? json['jenis_kambing'] ?? '',
    kelamin:      json['kelamin'] ?? '',
    tanggalLahir: json['tanggal_lahir'],
    beratLahir:   _toDouble(json['berat'] ?? json['berat_lahir']),
    tinggi:       _toDouble(json['tinggi']),
    umur:         _toInt(json['umur']),
    kondisi:      json['kondisi'] ?? 'Sehat',
    status:       json['status'] ?? 'Hidup',
    qrCodePath:   json['qr_code'] ?? json['qr_code_path'],
    deskripsi:    json['deskripsi'],
    createdAt:    json['created_at'],
    updatedAt:    json['updated_at'],
  );

  bool get isHidup => status.toLowerCase() == 'hidup';
  bool get isSehat => kondisi.toLowerCase() == 'sehat';
  bool get isSakit => kondisi.toLowerCase() == 'sakit';
}

double? _toDouble(dynamic v) => v != null ? double.tryParse(v.toString()) : null;
int? _toInt(dynamic v) => v != null ? int.tryParse(v.toString()) : null;