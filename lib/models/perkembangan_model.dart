class PerkembanganModel {
  final int perkembanganId;
  final int kambingId;
  final double? berat;
  final double? tinggi;
  final int? umurBulan;
  final String? kondisi;
  final String? catatan;
  final String? tanggalCatat;

  PerkembanganModel({
    required this.perkembanganId,
    required this.kambingId,
    this.berat,
    this.tinggi,
    this.umurBulan,
    this.kondisi,
    this.catatan,
    this.tanggalCatat,
  });

  factory PerkembanganModel.fromJson(Map<String, dynamic> json) => PerkembanganModel(
        perkembanganId: json['perkembangan_id'] ?? json['id'] ?? 0,
        kambingId: json['kambing_id'] ?? 0,
        berat: json['berat'] != null ? double.tryParse(json['berat'].toString()) : null,
        tinggi: json['tinggi'] != null ? double.tryParse(json['tinggi'].toString()) : null,
        umurBulan: json['umur_bulan'],
        kondisi: json['kondisi'],
        catatan: json['catatan'],
        tanggalCatat: json['tanggal_catat'] ?? json['created_at'],
      );
}

class PerkembanganSummary {
  final List<PerkembanganModel> records;
  final PerkembanganModel? latest;
  final double? beratAwal;
  final double? beratAkhir;
  final double? kenaikanBerat;

  PerkembanganSummary({
    required this.records,
    this.latest,
    this.beratAwal,
    this.beratAkhir,
    this.kenaikanBerat,
  });

  factory PerkembanganSummary.fromJson(Map<String, dynamic> json) {
    final records = (json['records'] as List? ?? json['data'] as List? ?? [])
        .map((e) => PerkembanganModel.fromJson(e))
        .toList();
    return PerkembanganSummary(
      records: records,
      latest: records.isNotEmpty ? records.first : null,
      beratAwal: json['berat_awal'] != null
          ? double.tryParse(json['berat_awal'].toString())
          : null,
      beratAkhir: json['berat_akhir'] != null
          ? double.tryParse(json['berat_akhir'].toString())
          : null,
      kenaikanBerat: json['kenaikan_berat'] != null
          ? double.tryParse(json['kenaikan_berat'].toString())
          : null,
    );
  }
}
