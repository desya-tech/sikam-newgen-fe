import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/permission_helper.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/role_model.dart';
import '../../providers/role_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../main_shell.dart';

class RoleListScreen extends StatefulWidget {
  const RoleListScreen({super.key});
  @override
  State<RoleListScreen> createState() => _RoleListScreenState();
}

class _RoleListScreenState extends State<RoleListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoleProvider>().loadAll();
    });
  }

  Future<void> _confirmDelete(BuildContext ctx, RoleDetailModel r) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Role'),
        content: Text('Yakin ingin menghapus role "${r.namaRole}"?\nUser yang memiliki role ini tidak akan bisa login.'),
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
      final provider = ctx.read<RoleProvider>();
      final success = await provider.delete(r.roleId);
      if (ctx.mounted) {
        if (success) {
          SnackbarHelper.showSuccess(ctx, 'Role berhasil dihapus');
        } else {
          SnackbarHelper.showError(ctx, provider.error ?? 'Gagal menghapus role');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Role'),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => advancedDrawerController.showDrawer(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => provider.loadAll()),
        ],
      ),
      floatingActionButton: PermissionHelper.canCreateRole
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/role/tambah'),
              icon: const Icon(Icons.add_moderator_outlined),
              label: const Text('Tambah Role'),
            )
          : null,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? ErrorStateWidget(message: provider.error!, onRetry: provider.loadAll)
              : provider.list.isEmpty
                  ? const EmptyState(
                      message: 'Belum ada role',
                      icon: Icons.shield_outlined,
                    )
                  : RefreshIndicator(
                      onRefresh: provider.loadAll,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: provider.list.length,
                        itemBuilder: (ctx, i) {
                          final r = provider.list[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ExpansionTile(
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
                              ),
                              title: Text(r.namaRole,
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text(
                                '${r.permissions.length} permission',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (PermissionHelper.canUpdateRole)
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                      onPressed: () => context.push('/role/${r.roleId}/edit', extra: {'role': r}),
                                    ),
                                  if (PermissionHelper.canDeleteRole)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                                      onPressed: () => _confirmDelete(context, r),
                                    ),
                                  const Icon(Icons.expand_more, color: AppColors.textSecondary),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: r.menu.entries.map((entry) {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8, bottom: 4),
                                            child: Text(entry.key,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                    color: AppColors.textSecondary)),
                                          ),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: entry.value.map((perm) => Chip(
                                              label: Text(perm, style: const TextStyle(fontSize: 10)),
                                              padding: EdgeInsets.zero,
                                              visualDensity: VisualDensity.compact,
                                            )).toList(),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

