int _parseInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;
double _parseDouble(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0;

class StatistikModel {
  final int total;
  final int totalHidup;
  final int totalMati;
  final double persenHidup;
  final double persenMati;
  final int totalJantan;
  final int totalBetina;
  final List<StatistikPenambahan> penambahan;
  final List<StatistikJenis> perJenis;

  StatistikModel({
    required this.total,
    required this.totalHidup,
    required this.totalMati,
    required this.persenHidup,
    required this.persenMati,
    required this.totalJantan,
    required this.totalBetina,
    required this.penambahan,
    required this.perJenis,
  });

  factory StatistikModel.fromJson(Map<String, dynamic> json) {
    int jCount = _parseInt(json['total_jantan'] ?? json['jantan']);
    int bCount = _parseInt(json['total_betina'] ?? json['betina']);
    final pkList = json['per_kelamin'] ?? json['perKelamin'];
    if (pkList is List) {
      for (var item in pkList) {
        if (item is Map) {
          final k = item['kelamin']?.toString().toLowerCase();
          final v = _parseInt(item['jumlah'] ?? item['total']);
          if (k == 'jantan') jCount = v;
          if (k == 'betina') bCount = v;
        }
      }
    }

    return StatistikModel(
      total:       _parseInt(json['total']),
      totalHidup:  _parseInt(json['total_hidup']  ?? json['hidup']),
      totalMati:   _parseInt(json['total_mati']   ?? json['mati']),
      persenHidup: _parseDouble(json['persentase_hidup'] ?? json['persen_hidup'] ?? json['persenHidup']),
      persenMati:  _parseDouble(json['persentase_mati'] ?? json['persen_mati']  ?? json['persenMati']),
      totalJantan: jCount,
      totalBetina: bCount,
      penambahan: ((json['per_bulan'] ?? json['perBulan'] ?? json['penambahan'] ?? []) as List)
          .map((e) => StatistikPenambahan.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      perJenis: ((json['per_jenis'] ?? json['perJenis'] ?? []) as List)
          .map((e) => StatistikJenis.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class StatistikPenambahan {
  final String label;
  final int jumlah;

  StatistikPenambahan({required this.label, required this.jumlah});

  factory StatistikPenambahan.fromJson(Map<String, dynamic> json) => StatistikPenambahan(
    label:  json['label']?.toString() ?? json['bulan']?.toString() ?? json['month']?.toString() ?? '',
    jumlah: _parseInt(json['jumlah'] ?? json['count'] ?? json['total']),
  );
}

class StatistikJenis {
  final String jenis;
  final int jumlah;

  StatistikJenis({required this.jenis, required this.jumlah});

  factory StatistikJenis.fromJson(Map<String, dynamic> json) => StatistikJenis(
    jenis:  json['jenis_kambing']?.toString() ?? json['jenis']?.toString() ?? '',
    jumlah: _parseInt(json['jumlah'] ?? json['count'] ?? json['total']),
  );
}

class StatistikKelamin {
  final int jantan;
  final int betina;

  StatistikKelamin({required this.jantan, required this.betina});

  factory StatistikKelamin.fromJson(Map<String, dynamic> json) => StatistikKelamin(
    jantan: _parseInt(json['jantan'] ?? json['total_jantan']),
    betina: _parseInt(json['betina'] ?? json['total_betina']),
  );
}