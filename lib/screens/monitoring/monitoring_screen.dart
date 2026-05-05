import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/kambing_model.dart';
import '../../providers/monitoring_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../main_shell.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});
  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MonitoringProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<MonitoringProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Monitoring Kesehatan', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => advancedDrawerController.showDrawer(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: m.loadAll),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: [
            const Tab(text: 'Statistik'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Sakit'),
                  if (m.sakit.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)),
                      child: Text('${m.sakit.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Perhatian'),
                  if (m.perluPerhatian.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(10)),
                      child: Text('${m.perluPerhatian.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.document_scanner_outlined, size: 16),
                  SizedBox(width: 4),
                  Text('Analisis AI'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: m.isLoading
          ? const Center(child: CircularProgressIndicator())
          : m.error != null
          ? ErrorStateWidget(message: m.error!, onRetry: m.loadAll)
          : TabBarView(
        controller: _tab,
        children: [
          _StatistikTab(m),
          _KambingListTab(items: m.sakit, type: 'sakit'),
          _KambingListTab(items: m.perluPerhatian, type: 'perhatian'),
          const _AiTab(),
        ],
      ),
    );
  }
}

// ─── Tab 1: Statistik ────────────────────────────────────────────────────────

class _StatistikTab extends StatelessWidget {
  final MonitoringProvider m;
  const _StatistikTab(this.m);

  @override
  Widget build(BuildContext context) {
    final s = m.statistik;
    if (s == null) return const EmptyState(message: 'Data statistik tidak tersedia', icon: Icons.bar_chart);

    return RefreshIndicator(
      onRefresh: m.loadAll,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                _StatCard('Total', '${s.total}', Icons.pets, AppColors.primary),
                const SizedBox(width: 16),
                _StatCard('Hidup', '${s.totalHidup}', Icons.favorite, AppColors.sehat),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatCard('Mati', '${s.totalMati}', Icons.heart_broken, AppColors.mati),
                const SizedBox(width: 16),
                _StatCard('Sakit', '${m.sakit.length}', Icons.local_hospital, AppColors.sakit),
              ],
            ),
            const SizedBox(height: 24),

            // Hidup vs Mati Pie
            _ChartCard(
              title: 'Status Kambing',
              child: SizedBox(
                height: 160,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sections: [
                            if (s.totalHidup > 0)
                              PieChartSectionData(
                                value: s.totalHidup.toDouble(),
                                color: AppColors.sehat,
                                title: '${s.totalHidup}',
                                radius: 55,
                                titleStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            if (s.totalMati > 0)
                              PieChartSectionData(
                                value: s.totalMati.toDouble(),
                                color: AppColors.mati,
                                title: '${s.totalMati}',
                                radius: 55,
                                titleStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                          ],
                          sectionsSpace: 4,
                          centerSpaceRadius: 30,
                        ),
                      ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Legend('Hidup (${s.persenHidup.toStringAsFixed(1)}%)', AppColors.sehat),
                        const SizedBox(height: 12),
                        _Legend('Mati (${s.persenMati.toStringAsFixed(1)}%)', AppColors.mati),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Jenis Bar Chart
            if (m.perJenis.isNotEmpty)
              _ChartCard(
                title: 'Jumlah per Jenis',
                child: SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      barGroups: m.perJenis.asMap().entries.map<BarChartGroupData>((e) {
                        final color = AppColors.chartColors[e.key % AppColors.chartColors.length];
                        return BarChartGroupData(x: e.key, barRods: [
                          BarChartRodData(
                            toY: e.value.jumlah.toDouble(),
                            color: color,
                            width: 22,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: (m.perJenis.map((item) => item.jumlah).reduce((a, b) => a > b ? a : b)).toDouble() * 1.2,
                              color: color.withOpacity(0.05),
                            ),
                          ),
                        ]);
                      }).toList(),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true, 
                          reservedSize: 32,
                          getTitlesWidget: (v, _) {
                            if (v % 1 != 0) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.right),
                            );
                          },
                        )),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (v, _) {
                              if (v % 1 != 0) return const SizedBox.shrink();
                              final idx = v.toInt();
                              if (idx < 0 || idx >= m.perJenis.length) return const SizedBox.shrink();
                              final label = m.perJenis[idx].jenis;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  label.length > 7 ? '${label.substring(0, 5)}..' : label,
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Kelamin Donut
            if (s.totalJantan + s.totalBetina > 0)
              _ChartCard(
                title: 'Distribusi Kelamin',
                child: SizedBox(
                  height: 140,
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(PieChartData(
                          sections: [
                            PieChartSectionData(value: s.totalJantan.toDouble(), color: AppColors.info, title: '${s.totalJantan}', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            PieChartSectionData(value: s.totalBetina.toDouble(), color: AppColors.secondary, title: '${s.totalBetina}', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                          sectionsSpace: 4,
                          centerSpaceRadius: 28,
                        )).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Legend('Jantan', AppColors.info),
                          const SizedBox(height: 12),
                          _Legend('Betina', AppColors.secondary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

          ].animate(interval: 100.ms).fade(duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad),
        ),
      ),
    );
  }
}

// ─── Tab 2 & 3: Kambing List ─────────────────────────────────────────────────

class _KambingListTab extends StatelessWidget {
  final List<KambingModel> items;
  final String type;
  const _KambingListTab({required this.items, required this.type});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyState(
        message: type == 'sakit'
            ? 'Tidak ada kambing yang sakit 🎉'
            : 'Semua kambing terupdate 🎉',
        sub: type == 'sakit'
            ? 'Semua kambing dalam kondisi baik'
            : 'Tidak ada yang perlu perhatian khusus',
        icon: type == 'sakit' ? Icons.local_hospital_outlined : Icons.notification_important_outlined,
      ).animate().fade().scale();
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final k = items[i];
        final color = type == 'sakit' ? AppColors.sakit : AppColors.warning;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/kambing/${k.kambingId}'),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        type == 'sakit' ? Icons.local_hospital_outlined : Icons.warning_amber_outlined,
                        color: color,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(k.namaKambing,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3)),
                          const SizedBox(height: 4),
                          Text('${k.jenisKambing} • ${k.kelamin}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(k.kondisi,
                                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 8),
                              if (k.updatedAt != null)
                                Expanded(
                                  child: Text('Update: ${DateFormatter.timeAgo(k.updatedAt)}',
                                      style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                                      overflow: TextOverflow.ellipsis),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fade(delay: (i * 50).ms).slideX(begin: 0.1, curve: Curves.easeOut);
      },
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
              ],
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  const _Legend(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─── AI Tab ─────────────────────────────────────────────────────────────────

class _AiTab extends StatefulWidget {
  const _AiTab();

  @override
  State<_AiTab> createState() => _AiTabState();
}

class _AiTabState extends State<_AiTab> {
  File? _image;
  bool _isLoading = false;
  String? _error;
  String? _geminiResult;
  final TextEditingController _apiKeyController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('gemini_api_key');
    if (savedKey != null && savedKey.isNotEmpty) {
      _apiKeyController.text = savedKey;
    }
  }

  Future<void> _saveApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _apiKeyController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key berhasil disimpan ke penyimpanan lokal perangkat!')),
      );
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _geminiResult = null;
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Gagal mengambil gambar: $e');
    }
  }

  Future<void> _analyzeImage() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      setState(() => _error = 'Masukkan API Key Gemini terlebih dahulu.');
      return;
    }
    if (_image == null) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
      _geminiResult = null;
    });

    try {
      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$apiKey';
      final res = await _dio.post(
        url,
        data: {
          "contents": [
            {
              "parts": [
                {"text": "Analisis gambar kambing ini. Sebutkan kemungkinan jenis/ras kambingnya, perkiraan umur jika bisa, dan apakah terlihat sehat atau sakit secara fisik. Berikan jawaban yang deskriptif, terstruktur, dan informatif dalam bahasa Indonesia."},
                {
                  "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }
          ]
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (res.statusCode == 200 && res.data != null) {
        final candidates = res.data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final text = candidates[0]['content']['parts'][0]['text'];
          setState(() {
            _geminiResult = text;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Tidak ada respons dari Gemini.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Gagal menganalisis. Coba lagi.';
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      String msg = 'Gagal terhubung ke AI: ${e.message}';
      if (e.response?.statusCode == 400) {
        msg = 'API Key tidak valid atau permintaan ditolak.';
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        msg = 'Koneksi ke server AI terputus/timeout.';
      }
      setState(() {
        _error = msg;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Analisis foto kambing menggunakan Google Gemini AI. Dapatkan informasi mendalam tentang kemungkinan jenis kambing dan kondisi fisiknya.',
                    style: TextStyle(fontSize: 13, color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Input API Key
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _apiKeyController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Gemini API Key',
                          hintText: 'Masukkan API Key',
                          prefixIcon: Icon(Icons.key, size: 20),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _saveApiKey,
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Simpan'),
                    ),
                  ],
                ),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Aman: API Key hanya disimpan secara lokal (di perangkat Anda saja) dan tidak pernah dikirim ke server aplikasi ini.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Area Gambar
          if (_image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(_image!, height: 250, width: double.infinity, fit: BoxFit.cover),
            ).animate().fade().scale(begin: const Offset(0.95, 0.95))
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 48, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text('Belum ada foto yang dipilih', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          
          const SizedBox(height: 20),

          // Tombol Pilih Gambar
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Kamera'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeri'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Tombol Analisis
          ElevatedButton(
            onPressed: (_image == null || _isLoading) ? null : _analyzeImage,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Analisis Gambar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 24),

          // Error Message
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ).animate().fade(),

          // Hasil
          if (_geminiResult != null) ...[
            const Text('Hasil Analisis Gemini AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Text(
                _geminiResult!,
                style: const TextStyle(height: 1.6, fontSize: 14, color: AppColors.textPrimary),
              ),
            ).animate().fade().slideY(begin: 0.1),
          ],
        ],
      ),
    );
  }
}