import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/permission_helper.dart';
import '../../providers/kambing_provider.dart';
import '../../widgets/common/app_widgets.dart';

class PerkembanganScreen extends StatefulWidget {
  final int kambingId;
  const PerkembanganScreen({super.key, required this.kambingId});
  @override
  State<PerkembanganScreen> createState() => _PerkembanganScreenState();
}

class _PerkembanganScreenState extends State<PerkembanganScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KambingProvider>().loadPerkembangan(widget.kambingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<KambingProvider>().perkembangan;

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Perkembangan')),
      floatingActionButton: PermissionHelper.canCreatePerkembangan
          ? FloatingActionButton(
        onPressed: () => context.push('/kambing/${widget.kambingId}/perkembangan/tambah'),
        child: const Icon(Icons.add),
      )
          : null,
      body: p == null
          ? const Center(child: CircularProgressIndicator())
          : p.records.isEmpty
          ? EmptyState(
        message: 'Belum ada data perkembangan',
        icon: Icons.timeline,
        onAction: PermissionHelper.canCreatePerkembangan
            ? () => context.push('/kambing/${widget.kambingId}/perkembangan/tambah')
            : null,
        actionLabel: 'Catat Pertama',
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Berat Chart
            if (p.records.any((r) => r.berat != null))
              _buildChart(p.records
                  .asMap()
                  .entries
                  .where((e) => e.value.berat != null)
                  .map<FlSpot>((e) => FlSpot(e.key.toDouble(), e.value.berat!))
                  .toList(), 'Grafik Berat (kg)', AppColors.primary),

            const SizedBox(height: 16),

            // Tinggi Chart
            if (p.records.any((r) => r.tinggi != null))
              _buildChart(p.records
                  .asMap()
                  .entries
                  .where((e) => e.value.tinggi != null)
                  .map<FlSpot>((e) => FlSpot(e.key.toDouble(), e.value.tinggi!))
                  .toList(), 'Grafik Tinggi (cm)', AppColors.info),

            const SizedBox(height: 16),

            // Records List
            Card(
              child: Column(
                children: p.records.map((r) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryContainer,
                    child: const Icon(Icons.straighten, color: AppColors.primary, size: 18),
                  ),
                  title: Row(children: [
                    if (r.berat != null) Text('${r.berat} kg', style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (r.berat != null && r.tinggi != null) const Text(' • ', style: TextStyle(color: AppColors.textSecondary)),
                    if (r.tinggi != null) Text('${r.tinggi} cm', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (r.umurBulan != null) Text('Umur: ${r.umurBulan} bulan'),
                      if (r.kondisi != null) Text('Kondisi: ${r.kondisi}'),
                      if (r.catatan != null && r.catatan!.isNotEmpty) Text(r.catatan!),
                    ],
                  ),
                  trailing: Text(DateFormatter.formatDate(r.tanggalCatat),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<FlSpot> spots, String title, Color color) {
    if (spots.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
                    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}