import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/permission_helper.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../providers/kambing_provider.dart';
import '../../models/kambing_model.dart';
import '../../widgets/common/app_widgets.dart';

class KambingListScreen extends StatefulWidget {
  const KambingListScreen({super.key});
  @override
  State<KambingListScreen> createState() => _KambingListScreenState();
}

class _KambingListScreenState extends State<KambingListScreen> {
  final _searchCtrl = TextEditingController();
  String? _filterStatus;
  String? _filterKondisi;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KambingProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    context.read<KambingProvider>().setSearch(q);
  }

  void _applyFilter() {
    context.read<KambingProvider>().setFilter(
      status: _filterStatus,
      kondisi: _filterKondisi,
    );
  }

  void _showFilter(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (_, setS) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Semua', 'Hidup', 'Mati'].map((s) {
                  final selected = (s == 'Semua' && _filterStatus == null) || _filterStatus == s;
                  return FilterChip(
                    label: Text(s),
                    selected: selected,
                    onSelected: (_) => setS(() => _filterStatus = s == 'Semua' ? null : s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Kondisi', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Semua', 'Sehat', 'Sakit', 'Dalam Perawatan'].map((k) {
                  final selected = (k == 'Semua' && _filterKondisi == null) || _filterKondisi == k;
                  return FilterChip(
                    label: Text(k),
                    selected: selected,
                    onSelected: (_) => setS(() => _filterKondisi = k == 'Semua' ? null : k),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Terapkan Filter',
                onPressed: () {
                  Navigator.pop(ctx);
                  _applyFilter();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext ctx, KambingModel k) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kambing'),
        content: Text('Yakin ingin menghapus ${k.namaKambing}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(_, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true && ctx.mounted) {
      final provider = ctx.read<KambingProvider>();
      final success = await provider.delete(k.kambingId);
      if (ctx.mounted) {
        if (success) {
          SnackbarHelper.showSuccess(ctx, 'Kambing berhasil dihapus');
        } else {
          SnackbarHelper.showError(ctx, provider.error ?? 'Gagal menghapus');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KambingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Kambing'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () => _showFilter(context)),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => provider.loadAll()),
        ],
      ),
      floatingActionButton: PermissionHelper.canCreateKambing
          ? FloatingActionButton.extended(
        onPressed: () => context.push('/kambing/tambah'),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Cari nama kambing...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchCtrl.clear();
                    _onSearch('');
                  },
                )
                    : null,
                isDense: true,
              ),
            ),
          ),
          if (_filterStatus != null || _filterKondisi != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Filter: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  if (_filterStatus != null)
                    Chip(label: Text(_filterStatus!), onDeleted: () { setState(() => _filterStatus = null); _applyFilter(); }),
                  if (_filterKondisi != null)
                    Chip(label: Text(_filterKondisi!), onDeleted: () { setState(() => _filterKondisi = null); _applyFilter(); }),
                ],
              ),
            ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null
                ? ErrorStateWidget(message: provider.error!, onRetry: provider.loadAll)
                : provider.list.isEmpty
                ? const EmptyState(
              message: 'Belum ada data kambing',
              sub: 'Tambah kambing baru dengan tombol + di bawah',
              icon: Icons.pets,
            )
                : RefreshIndicator(
              onRefresh: provider.loadAll,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: provider.list.length,
                itemBuilder: (ctx, i) {
                  final k = provider.list[i];
                  return _KambingCard(
                    kambing: k,
                    onTap: () => context.push('/kambing/${k.kambingId}'),
                    onEdit: PermissionHelper.canUpdateKambing
                        ? () => context.push('/kambing/${k.kambingId}/edit', extra: {'kambing': k})
                        : null,
                    onDelete: PermissionHelper.canDeleteKambing
                        ? () => _confirmDelete(context, k)
                        : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KambingCard extends StatelessWidget {
  final KambingModel kambing;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _KambingCard({
    required this.kambing,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  Color get _kondisiColor {
    switch (kambing.kondisi.toLowerCase()) {
      case 'sakit': return AppColors.sakit;
      case 'dalam perawatan': return AppColors.perawatan;
      default: return AppColors.sehat;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                    Icons.pets, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(kambing.namaKambing,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (!kambing.isHidup)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8,
                                vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.mati.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Mati', style: TextStyle(
                                color: AppColors.mati,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${kambing.jenisKambing} • ${kambing.kelamin}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kondisiColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(kambing.kondisi,
                              style: TextStyle(color: _kondisiColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                    Icons.more_vert, color: AppColors.textSecondary),
                onSelected: (v) {
                  if (v == 'detail') onTap();
                  if (v == 'edit' && onEdit != null) onEdit!();
                  if (v == 'delete' && onDelete != null) onDelete!();
                },
                itemBuilder: (_) =>
                [
                  const PopupMenuItem(value: 'detail',
                      child: ListTile(leading: Icon(Icons.info_outline),
                          title: Text('Detail'),
                          dense: true)),
                  if (onEdit != null)
                    const PopupMenuItem(value: 'edit',
                        child: ListTile(leading: Icon(Icons.edit_outlined),
                            title: Text('Edit'),
                            dense: true)),
                  if (onDelete != null)
                    const PopupMenuItem(value: 'delete',
                        child: ListTile(leading: Icon(
                            Icons.delete_outline, color: AppColors.error),
                            title: Text('Hapus', style: TextStyle(
                                color: AppColors.error)),
                            dense: true)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }}