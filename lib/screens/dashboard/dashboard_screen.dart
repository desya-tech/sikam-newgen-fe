import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../main_shell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Dio _dio = Dio();
  List<Map<String, dynamic>> _newsList = [];
  bool _isLoadingNews = true;
  String? _newsError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    context.read<MonitoringProvider>().loadAll();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    if (!mounted) return;
    setState(() {
      _isLoadingNews = true;
      _newsError = null;
    });
    try {
      const rssUrl = 'https://news.google.com/rss/search?q=ternak+kambing&hl=id&gl=ID&ceid=ID:id';
      final url = 'https://api.rss2json.com/v1/api.json?rss_url=${Uri.encodeComponent(rssUrl)}';
      final res = await _dio.get(url);
      if (res.data['status'] == 'ok') {
        final items = res.data['items'] as List;
        if (mounted) {
          setState(() {
            _newsList = items.take(3).cast<Map<String, dynamic>>().toList();
            _isLoadingNews = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _newsError = 'Gagal memuat berita';
            _isLoadingNews = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _newsError = 'Kesalahan jaringan: ${e.toString()}';
          _isLoadingNews = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.inAppBrowserView)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan')),
        );
      }
    }
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final m    = context.watch<MonitoringProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ── App Bar ──────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.primary,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => advancedDrawerController.showDrawer(),
              ),
              title: const Text(
                'Dashboard',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadData,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  // kToolbarHeight(56) + status bar ≈ 80dp top padding
                  padding: const EdgeInsets.fromLTRB(24, 88, 24, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${auth.user?.username ?? ''} 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fade(duration: 400.ms).slideX(begin: -0.1),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          auth.user?.role.namaRole ?? '',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ).animate().fade(delay: 200.ms).slideX(begin: -0.1),
                    ],
                  ),
                ),
              ),
            ),

            // ── Body ─────────────────────────────────────────────
            if (m.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (m.error != null)
              SliverFillRemaining(
                child: ErrorStateWidget(message: m.error!, onRetry: _loadData),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _statsGrid(m),
                    const SizedBox(height: 20),
                    if ((m.statistik?.totalJantan ?? 0) + (m.statistik?.totalBetina ?? 0) > 0) ...[
                      _kelaminChart(m),
                      const SizedBox(height: 20),
                    ],
                    if (m.perJenis.isNotEmpty) ...[
                      _jenisChart(m),
                      const SizedBox(height: 20),
                    ],
                    if (m.penambahanData.isNotEmpty) ...[
                      _perBulanChart(m),
                      const SizedBox(height: 20),
                    ],
                    _alertSection(m),
                    const SizedBox(height: 24),
                    _newsSection(),
                  ].animate(interval: 100.ms).fade(duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Stats Grid ─────────────────────────────────────────────────
  Widget _statsGrid(m) {
    final s = m.statistik;
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4, // Diubah agar card lebih tinggi, mencegah overflow
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _StatCard('Total Kambing', '${s?.total ?? 0}',    Icons.pets,           AppColors.primary),
        _StatCard('Hidup',         '${s?.totalHidup ?? 0}', Icons.favorite,     AppColors.sehat),
        _StatCard('Jantan',        '${s?.totalJantan ?? 0}', Icons.male,        AppColors.info),
        _StatCard('Betina',        '${s?.totalBetina ?? 0}', Icons.female,      AppColors.secondary),
      ],
    );
  }

  // ── Kelamin Pie ────────────────────────────────────────────────
  Widget _kelaminChart(m) {
    final jantan = (m.statistik?.totalJantan ?? 0).toDouble();
    final betina = (m.statistik?.totalBetina ?? 0).toDouble();
    return _ChartCard(
      title: 'Distribusi Kelamin',
      child: SizedBox(
        height: 160,
        child: Row(
          children: [
            Expanded(
              child: PieChart(PieChartData(
                sections: [
                  PieChartSectionData(value: jantan, color: AppColors.info,
                      title: '$jantan', radius: 55,
                      titleStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  PieChartSectionData(value: betina, color: AppColors.secondary,
                      title: '$betina', radius: 55,
                      titleStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
                sectionsSpace: 4, centerSpaceRadius: 30,
              )).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            ),
            const SizedBox(width: 16),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              _Legend('Jantan', AppColors.info),
              const SizedBox(height: 12),
              _Legend('Betina', AppColors.secondary),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Jenis Bar ──────────────────────────────────────────────────
  Widget _jenisChart(m) {
    final jenis = m.perJenis;
    return _ChartCard(
      title: 'Per Jenis Kambing',
      child: SizedBox(
        height: 200,
        child: BarChart(BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: jenis.asMap().entries.map<BarChartGroupData>((e) {
            final color = AppColors.chartColors[e.key % AppColors.chartColors.length];
            return BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(
                  toY: e.value.jumlah.toDouble(), 
                  color: color,
                  width: 22, 
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: (jenis.map((e) => e.jumlah).reduce((a, b) => a > b ? a : b)).toDouble() * 1.2,
                    color: color.withOpacity(0.05),
                  )
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
            rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, _) {
                if (v % 1 != 0) return const SizedBox.shrink();
                final idx = v.toInt();
                if (idx < 0 || idx >= jenis.length) return const SizedBox.shrink();
                final label = jenis[idx].jenis;
                return Padding(padding: const EdgeInsets.only(top: 8),
                    child: Text(label.length > 7 ? '${label.substring(0, 5)}..' : label,
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)));
              },
            )),
          ),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
        )),
      ),
    );
  }

  // ── Penambahan Line ─────────────────────────────────────────────
  Widget _perBulanChart(m) {
    final penambahan = m.penambahanData;
    final filter = m.penambahanFilter;
    final spots = penambahan.asMap().entries
        .map<FlSpot>((e) => FlSpot(e.key.toDouble(), e.value.jumlah.toDouble()))
        .toList();
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Penambahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: filter,
                    isDense: true,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                    items: const [
                      DropdownMenuItem(value: 'minggu', child: Text('Per Minggu')),
                      DropdownMenuItem(value: 'bulan', child: Text('Per Bulan')),
                      DropdownMenuItem(value: 'tahun', child: Text('Per Tahun')),
                    ],
                    onChanged: (val) {
                      if (val != null) m.ubahFilterPenambahan(val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: spots, isCurved: true,
                  color: AppColors.primary, barWidth: 3, isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: AppColors.primary
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true, 
                    gradient: LinearGradient(
                      colors: [AppColors.primary.withOpacity(0.3), AppColors.primary.withOpacity(0.0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (v, _) {
                    if (v % 1 != 0) return const SizedBox.shrink();
                    final idx = v.toInt();
                    if (idx < 0 || idx >= penambahan.length) return const SizedBox.shrink();
                    final label = penambahan[idx].label;
                    String display = label;
                    if (filter == 'minggu' && label.contains('-')) {
                      // format 2026-18 -> Mg 18
                      final parts = label.split('-');
                      if (parts.length == 2) display = 'Mg ${parts[1]}';
                    } else if (filter == 'bulan' && label.length == 7 && label.contains('-')) {
                      final parts = label.split('-');
                      if (parts.length == 2 && parts[0].length == 4) {
                         display = '${parts[1]}/${parts[0].substring(2)}';
                      }
                    } else if (label.length > 6) {
                       display = label.substring(0, 6);
                    }
                    return Padding(padding: const EdgeInsets.only(top: 8),
                        child: Text(display, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)));
                  },
                )),
              ),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) => LineTooltipItem(
                      '${spot.y.toInt()} Ekor',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    )).toList();
                  },
                )
              ),
            )),
          ),
        ],
      ),
    );
  }

  // ── Alert Section ──────────────────────────────────────────────
  Widget _alertSection(m) {
    if (m.sakit.isEmpty && m.perluPerhatian.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('⚠️ Perlu Perhatian',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const SizedBox(height: 12),
        if (m.sakit.isNotEmpty)
          _AlertCard(
            count: m.sakit.length,
            title: 'Kambing Sakit',
            subtitle: 'Segera tangani',
            color: AppColors.error,
            icon: Icons.local_hospital_outlined,
            onTap: () => context.go('/monitoring'),
          ),
        if (m.sakit.isNotEmpty && m.perluPerhatian.isNotEmpty) const SizedBox(height: 10),
        if (m.perluPerhatian.isNotEmpty)
          _AlertCard(
            count: m.perluPerhatian.length,
            title: 'Butuh Perhatian',
            subtitle: 'Tidak ada update > 7 hari',
            color: AppColors.warning,
            icon: Icons.warning_amber_outlined,
            onTap: () => context.go('/monitoring'),
          ),
      ],
    );
  }

  // ── News Section ───────────────────────────────────────────────
  Widget _newsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('📰 Berita Peternakan',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
            TextButton(
              onPressed: () => context.go('/info'),
              child: const Text('Lihat Semua',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingNews)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ))
        else if (_newsError != null)
          Center(
              child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(_newsError!,
                style: const TextStyle(color: AppColors.error)),
          ))
        else if (_newsList.isEmpty)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('Belum ada berita.'),
          ))
        else
          Column(
            children: _newsList.map((news) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () => _launchUrl(news['link'] ?? ''),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.newspaper_outlined,
                              color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                news['title'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(news['pubDate'] ?? ''),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
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
                width: 38, height: 38,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(value,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
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
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
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
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 12, height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    ],
  );
}

class _AlertCard extends StatelessWidget {
  final int count;
  final String title, subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _AlertCard({
    required this.count, required this.title, required this.subtitle, 
    required this.color, required this.icon, required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$count $title', style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textSecondary.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}