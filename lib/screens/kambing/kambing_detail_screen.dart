import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/permission_helper.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../providers/kambing_provider.dart';
import '../../services/kambing_service.dart';
import '../../widgets/common/app_widgets.dart';

class KambingDetailScreen extends StatefulWidget {
  final int id;
  const KambingDetailScreen({super.key, required this.id});
  @override
  State<KambingDetailScreen> createState() => _KambingDetailScreenState();
}

class _KambingDetailScreenState extends State<KambingDetailScreen> {
  final _svc        = KambingService();
  bool _regenLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<KambingProvider>();
      p.loadDetail(widget.id);
      p.loadPerkembangan(widget.id);
    });
  }

  // ── Regenerate QR ───────────────────────────────────────────────
  Future<void> _regenerateQr() async {
    setState(() => _regenLoading = true);
    try {
      await _svc.regenerateQr(widget.id);
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'QR Code berhasil di-regenerate');
      context.read<KambingProvider>().loadDetail(widget.id);
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _regenLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KambingProvider>();
    final k = provider.selected;

    if (provider.isLoading) {
      return Scaffold(appBar: AppBar(title: const Text('Detail Kambing')),
          body: const Center(child: CircularProgressIndicator()));
    }
    if (provider.error != null) {
      return Scaffold(appBar: AppBar(title: const Text('Detail Kambing')),
          body: ErrorStateWidget(message: provider.error!, onRetry: () => provider.loadDetail(widget.id)));
    }
    if (k == null) {
      return Scaffold(appBar: AppBar(title: const Text('Detail Kambing')),
          body: const EmptyState(message: 'Data tidak ditemukan', icon: Icons.pets));
    }

    Color kondisiColor;
    switch (k.kondisi.toLowerCase()) {
      case 'sakit':           kondisiColor = AppColors.sakit;     break;
      case 'dalam perawatan': kondisiColor = AppColors.perawatan; break;
      default:                kondisiColor = AppColors.sehat;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 56),
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.pets, size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(k.namaKambing,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              title: Text(k.namaKambing,
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
              titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
            ),
            actions: [
              if (PermissionHelper.canUpdateKambing)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: () => context.push('/kambing/${k.kambingId}/edit', extra: {'kambing': k}),
                ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Status Badges ──────────────────────────────────
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _Badge(k.status, k.isHidup ? AppColors.sehat : AppColors.mati),
                    _Badge(k.kondisi, kondisiColor),
                    _Badge(k.kelamin, AppColors.info),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Info Card ──────────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Informasi Kambing',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 12),
                        _InfoRow('Jenis',     k.jenisKambing),
                        _InfoRow('Kelamin',   k.kelamin),
                        _InfoRow('Tgl Lahir', DateFormatter.formatDate(k.tanggalLahir)),
                        if (k.umur != null)
                          _InfoRow('Umur',    '${k.umur} bulan'),
                        if (k.beratLahir != null)
                          _InfoRow('Berat',   '${k.beratLahir} kg'),
                        if (k.tinggi != null)
                          _InfoRow('Tinggi',  '${k.tinggi} cm'),
                        if (k.deskripsi != null && k.deskripsi!.isNotEmpty)
                          _InfoRow('Deskripsi', k.deskripsi!),
                        _InfoRow('Diupdate', DateFormatter.timeAgo(k.updatedAt)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── QR + Icon Card ─────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('QR Code',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 16),

                        // QR Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: k.qrCodePath != null
                              ? Image.network(
                            '${ApiConstants.baseUrl}${k.qrCodePath!}',
                            width: 200, height: 200,
                            errorBuilder: (_, __, ___) => QrImageView(
                              data: '${ApiConstants.baseUrl}/kambing/scan/${k.kambingId}',
                              version: QrVersions.auto, size: 200,
                            ),
                          )
                              : QrImageView(
                            data: '${ApiConstants.baseUrl}/kambing/scan/${k.kambingId}',
                            version: QrVersions.auto, size: 200,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Regenerate QR Button
                        _regenLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _regenerateQr,
                            icon: const Icon(Icons.qr_code),
                            label: const Text('Regenerate QR'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Perkembangan Card ──────────────────────────────
                _buildPerkembanganCard(provider),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerkembanganCard(KambingProvider provider) {
    final p = provider.perkembangan;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Perkembangan',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                if (PermissionHelper.canViewPerkembangan)
                  TextButton(
                    onPressed: () => context.push('/kambing/${widget.id}/perkembangan'),
                    child: const Text('Lihat Semua'),
                  ),
                if (PermissionHelper.canCreatePerkembangan)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                    onPressed: () => context.push('/kambing/${widget.id}/perkembangan/tambah'),
                  ),
              ],
            ),
            if (p == null || p.records.isEmpty)
              const Text('Belum ada data perkembangan',
                  style: TextStyle(color: AppColors.textSecondary))
            else ...[
              if (p.latest != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniStat('Berat',
                        p.latest!.berat != null ? '${p.latest!.berat} kg' : '-',
                        AppColors.primary),
                    const SizedBox(width: 8),
                    _MiniStat('Tinggi',
                        p.latest!.tinggi != null ? '${p.latest!.tinggi} cm' : '-',
                        AppColors.info),
                    const SizedBox(width: 8),
                    _MiniStat('Umur',
                        p.latest!.umurBulan != null ? '${p.latest!.umurBulan} bln' : '-',
                        AppColors.secondary),
                  ],
                ),
              ],
              if (p.kenaikanBerat != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.trending_up, color: AppColors.sehat, size: 18),
                  const SizedBox(width: 6),
                  Text('Kenaikan berat: +${p.kenaikanBerat} kg',
                      style: const TextStyle(color: AppColors.sehat, fontWeight: FontWeight.w600)),
                ]),
              ],
              const SizedBox(height: 6),
              Text('${p.records.length} catatan perkembangan',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label; final Color color;
  const _Badge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 90,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
        const Text(': ', style: TextStyle(color: AppColors.textSecondary)),
        Expanded(child: Text(value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
      ],
    ),
  );
}

class _MiniStat extends StatelessWidget {
  final String label, value; final Color color;
  const _MiniStat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      ]),
    ),
  );
}