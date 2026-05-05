import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/permission_helper.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../main_shell.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});
  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadAll();
    });
  }

  Future<void> _confirmDelete(BuildContext ctx, UserModel u) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Hapus User'),
        content: Text('Yakin ingin menghapus user "${u.username}"?'),
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
      final provider = ctx.read<UserProvider>();
      final success = await provider.delete(u.userId);
      if (ctx.mounted) {
        if (success) {
          SnackbarHelper.showSuccess(ctx, 'User berhasil dihapus');
        } else {
          SnackbarHelper.showError(ctx, provider.error ?? 'Gagal menghapus user');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen User'),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => advancedDrawerController.showDrawer(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => provider.loadAll()),
        ],
      ),
      floatingActionButton: PermissionHelper.canCreateUser
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/user/tambah'),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Tambah User'),
            )
          : null,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? ErrorStateWidget(message: provider.error!, onRetry: provider.loadAll)
              : provider.list.isEmpty
                  ? const EmptyState(
                      message: 'Belum ada user',
                      icon: Icons.people_outline,
                    )
                  : RefreshIndicator(
                      onRefresh: provider.loadAll,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: provider.list.length,
                        itemBuilder: (ctx, i) {
                          final u = provider.list[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              leading: u.fotoProfil != null
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        ApiConstants.uploads(u.fotoProfil!),
                                      ),
                                      onBackgroundImageError: (_, __) {},
                                    )
                                  : CircleAvatar(
                                      backgroundColor: AppColors.primaryContainer,
                                      child: Text(
                                        u.username.isNotEmpty ? u.username[0].toUpperCase() : 'U',
                                        style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                              title: Text(u.username,
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.email,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  if (u.namaRole != null)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryContainer,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(u.namaRole!,
                                          style: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                                onSelected: (v) {
                                  if (v == 'edit') {
                                    context.push('/user/${u.userId}/edit', extra: {'user': u});
                                  } else if (v == 'delete') {
                                    _confirmDelete(context, u);
                                  }
                                },
                                itemBuilder: (_) => [
                                  if (PermissionHelper.canUpdateUser)
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: ListTile(
                                        leading: Icon(Icons.edit_outlined),
                                        title: Text('Edit'),
                                        dense: true,
                                      ),
                                    ),
                                  if (PermissionHelper.canDeleteUser)
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(Icons.delete_outline, color: AppColors.error),
                                        title: Text('Hapus', style: TextStyle(color: AppColors.error)),
                                        dense: true,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

