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

  // Filter state lokal — disinkronkan ke provider saat "Terapkan"
  String? _filterStatus;
  String? _filterKondisi;

  // State sementara di dalam bottom sheet
  String? _tempStatus;
  String? _tempKondisi;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KambingProvider>().loadAll();
    });
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {}); // rebuild agar suffix clear icon muncul/hilang
    context.read<KambingProvider>().setSearch(_searchCtrl.text.trim());
  }

  void _clearSearch() {
    _searchCtrl.clear();
    // listener sudah memanggil setSearch
  }

  void _applyFilter() {
    setState(() {
      _filterStatus = _tempStatus;
      _filterKondisi = _tempKondisi;
    });
    context.read<KambingProvider>().setFilter(
      status: _filterStatus,
      kondisi: _filterKondisi,
    );
  }

  void _removeStatusFilter() {
    setState(() => _filterStatus = null);
    context.read<KambingProvider>().setFilter(
      status: null,
      kondisi: _filterKondisi,
      silent: true,
    );
  }

  void _removeKondisiFilter() {
    setState(() => _filterKondisi = null);
    context.read<KambingProvider>().setFilter(
      status: _filterStatus,
      kondisi: null,
      silent: true,
    );
  }

  void _showFilter(BuildContext ctx) {
    // Salin state saat ini ke state sementara
    _tempStatus = _filterStatus;
    _tempKondisi = _filterKondisi;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (_, setS) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Kambing',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () {
                      setS(() {
                        _tempStatus = null;
                        _tempKondisi = null;
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status filter
              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['Semua', 'Hidup', 'Mati'].map((s) {
                  final isSelected = (s == 'Semua' && _tempStatus == null) ||
                      _tempStatus == s;
                  return ChoiceChip(
                    label: Text(s),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    onSelected: (_) => setS(
                      () => _tempStatus = s == 'Semua' ? null : s,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Kondisi filter
              const Text(
                'Kondisi',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['Semua', 'Sehat', 'Sakit', 'Dalam Perawatan']
                    .map((k) {
                  final isSelected =
                      (k == 'Semua' && _tempKondisi == null) ||
                          _tempKondisi == k;
                  return ChoiceChip(
                    label: Text(k),
                    selected: isSelected,
                    selectedColor: _kondisiColor(k),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    onSelected: (_) => setS(
                      () => _tempKondisi = k == 'Semua' ? null : k,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _applyFilter();
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Terapkan Filter',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _kondisiColor(String k) {
    switch (k.toLowerCase()) {
      case 'sakit':
        return AppColors.sakit;
      case 'dalam perawatan':
        return AppColors.perawatan;
      default:
        return AppColors.sehat;
    }
  }

  Future<void> _confirmDelete(BuildContext ctx, KambingModel k) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kambing'),
        content: Text('Yakin ingin menghapus ${k.namaKambing}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(_, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
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

  bool get _hasActiveFilter => _filterStatus != null || _filterKondisi != null;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KambingProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Kambing'),
        actions: [
          // Indikator filter aktif
          if (_hasActiveFilter)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Badge(
                label: Text(
                  (_filterStatus != null ? 1 : 0) +
                          (_filterKondisi != null ? 1 : 0) ==
                      1
                      ? '1'
                      : '2',
                ),
                child: IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => _showFilter(context),
                  tooltip: 'Filter aktif',
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilter(context),
              tooltip: 'Filter',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadAll(),
            tooltip: 'Refresh',
          ),
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
          // ── Search Bar ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari nama kambing...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: _clearSearch,
                        tooltip: 'Hapus pencarian',
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // ── Active Filter Chips ──────────────────────────────
          if (_hasActiveFilter)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Filter:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_filterStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        label: Text(
                          _filterStatus!,
                          style: const TextStyle(fontSize: 12),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: _removeStatusFilter,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  if (_filterKondisi != null)
                    Chip(
                      label: Text(
                        _filterKondisi!,
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: _removeKondisiFilter,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),

          // ── List ─────────────────────────────────────────────
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null
                    ? ErrorStateWidget(
                        message: provider.error!,
                        onRetry: provider.loadAll,
                      )
                    : provider.list.isEmpty
                        ? EmptyState(
                            message: _searchCtrl.text.isNotEmpty ||
                                    _hasActiveFilter
                                ? 'Tidak ada kambing yang sesuai'
                                : 'Belum ada data kambing',
                            sub: _searchCtrl.text.isNotEmpty ||
                                    _hasActiveFilter
                                ? 'Coba ubah kata kunci atau filter'
                                : 'Tambah kambing baru dengan tombol + di bawah',
                            icon: Icons.pets,
                          )
                        : RefreshIndicator(
                            onRefresh: provider.loadAll,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 100),
                              itemCount: provider.list.length,
                              itemBuilder: (ctx, i) {
                                final k = provider.list[i];
                                return _KambingCard(
                                  kambing: k,
                                  onTap: () =>
                                      context.push('/kambing/${k.kambingId}'),
                                  onEdit: PermissionHelper.canUpdateKambing
                                      ? () => context.push(
                                            '/kambing/${k.kambingId}/edit',
                                            extra: {'kambing': k},
                                          )
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

// ══════════════════════════════════════════════════════════════
//  _KambingCard
// ══════════════════════════════════════════════════════════════

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
      case 'sakit':
        return AppColors.sakit;
      case 'dalam perawatan':
        return AppColors.perawatan;
      default:
        return AppColors.sehat;
    }
  }

  IconData get _kelaminIcon =>
      kambing.kelamin.toLowerCase() == 'jantan' ? Icons.male : Icons.female;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: kambing.isHidup
                      ? AppColors.primaryContainer
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.pets,
                  color: kambing.isHidup ? AppColors.primary : Colors.grey[500],
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama + status mati
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            kambing.namaKambing,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!kambing.isHidup)
                          _Badge(
                            label: 'Mati',
                            color: AppColors.mati,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Jenis & kelamin
                    Row(
                      children: [
                        Icon(_kelaminIcon,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${kambing.jenisKambing} · ${kambing.kelamin}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Kondisi + berat/umur
                    Row(
                      children: [
                        _Badge(
                          label: kambing.kondisi,
                          color: _kondisiColor,
                        ),
                        if (kambing.beratLahir != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${kambing.beratLahir!.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (kambing.umur != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${kambing.umur} bln',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    color: AppColors.textSecondary, size: 22),
                onSelected: (v) {
                  if (v == 'detail') onTap();
                  if (v == 'edit' && onEdit != null) onEdit!();
                  if (v == 'delete' && onDelete != null) onDelete!();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'detail',
                    child: ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Detail'),
                      dense: true,
                    ),
                  ),
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit'),
                        dense: true,
                      ),
                    ),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading:
                            Icon(Icons.delete_outline, color: AppColors.error),
                        title: Text(
                          'Hapus',
                          style: TextStyle(color: AppColors.error),
                        ),
                        dense: true,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}