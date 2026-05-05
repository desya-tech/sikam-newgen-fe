import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/role_model.dart';
import '../../providers/role_provider.dart';
import '../../widgets/common/app_widgets.dart';

class RoleFormScreen extends StatefulWidget {
  final RoleDetailModel? role;
  const RoleFormScreen({super.key, this.role});
  @override
  State<RoleFormScreen> createState() => _RoleFormScreenState();
}

class _RoleFormScreenState extends State<RoleFormScreen> {
  final _formKey       = GlobalKey<FormState>();
  late final _namaCtrl = TextEditingController(text: widget.role?.namaRole);
  late final _deskCtrl = TextEditingController(text: widget.role?.deskripsi);

  // Simpan permission_id (int) untuk dikirim ke backend
  final Set<int> _selectedIds = {};

  bool get _isEdit => widget.role != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<RoleProvider>().loadAll(silent: true);
      // Pre-select permissions kalau edit
      if (_isEdit) {
        final provider = context.read<RoleProvider>();
        final selectedKodes = widget.role!.permissions.toSet();
        setState(() {
          for (final p in provider.allPermissions) {
            if (selectedKodes.contains(p.kode)) {
              _selectedIds.add(p.permissionId);
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _deskCtrl.dispose();
    super.dispose();
  }

  bool _isGroupAllSelected(List<PermissionModel> perms) =>
      perms.isNotEmpty && perms.every((p) => _selectedIds.contains(p.permissionId));

  bool _isGroupPartial(List<PermissionModel> perms) =>
      perms.any((p) => _selectedIds.contains(p.permissionId)) &&
          !_isGroupAllSelected(perms);

  void _toggleGroup(List<PermissionModel> perms, bool select) {
    setState(() {
      for (final p in perms) {
        if (select) {
          _selectedIds.add(p.permissionId);
        } else {
          _selectedIds.remove(p.permissionId);
        }
      }
    });
  }

  void _togglePerm(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIds.isEmpty) {
      SnackbarHelper.showWarning(context, 'Pilih minimal satu permission');
      return;
    }

    final provider = context.read<RoleProvider>();
    final payload = {
      'nama_role':       _namaCtrl.text.trim(),
      if (_deskCtrl.text.isNotEmpty) 'deskripsi': _deskCtrl.text.trim(),
      'permission_ids':  _selectedIds.toList(),
    };

    final ok = _isEdit
        ? await provider.update(widget.role!.roleId, payload)
        : await provider.create(payload);

    if (!mounted) return;
    if (ok) {
      SnackbarHelper.showSuccess(
          context, _isEdit ? 'Role berhasil diperbarui' : 'Role berhasil dibuat');
      context.pop();
    } else {
      SnackbarHelper.showError(context, provider.error ?? 'Gagal menyimpan role');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoleProvider>();
    final grouped  = provider.permissionsByGroup;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Role' : 'Tambah Role')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Nama Role *',
                hint: 'Contoh: Supervisor',
                controller: _namaCtrl,
                prefixIcon: Icons.shield_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Nama role wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Deskripsi',
                hint: 'Deskripsi singkat role ini',
                controller: _deskCtrl,
                maxLines: 2,
                prefixIcon: Icons.description_outlined,
              ),
              const SizedBox(height: 24),

              // Header
              Row(children: [
                const Expanded(child: Text('Permissions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                TextButton(
                  onPressed: () => setState(() {
                    for (final p in provider.allPermissions) _selectedIds.add(p.permissionId);
                  }),
                  child: const Text('Pilih Semua'),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedIds.clear()),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Hapus Semua'),
                ),
              ]),

              if (provider.isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ))
              else if (grouped.isEmpty)
                const Text('Tidak ada permission tersedia',
                    style: TextStyle(color: AppColors.textSecondary))
              else
                ...grouped.entries.map((entry) {
                  final perms    = entry.value;
                  final allSel   = _isGroupAllSelected(perms);
                  final partial  = _isGroupPartial(perms);
                  final selCount = perms.where((p) => _selectedIds.contains(p.permissionId)).length;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Group header
                        InkWell(
                          onTap: () => _toggleGroup(perms, !allSel),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(children: [
                              Checkbox(
                                value: partial ? null : allSel,
                                tristate: true,
                                activeColor: AppColors.primary,
                                onChanged: (_) => _toggleGroup(perms, !allSel),
                              ),
                              const SizedBox(width: 4),
                              Expanded(child: Text(entry.key,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('$selCount/${perms.length}',
                                    style: const TextStyle(color: AppColors.primary,
                                        fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                            ]),
                          ),
                        ),
                        const Divider(height: 1),

                        // Individual permissions
                        ...perms.map((perm) => CheckboxListTile(
                          key: ValueKey(perm.permissionId),
                          dense: true,
                          value: _selectedIds.contains(perm.permissionId),
                          activeColor: AppColors.primary,
                          title: Text(perm.nama, style: const TextStyle(fontSize: 13)),
                          subtitle: Text(perm.kode,
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          onChanged: (_) => _togglePerm(perm.permissionId),
                          controlAffinity: ListTileControlAffinity.leading,
                        )),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('${_selectedIds.length} permission dipilih',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 24),

              AppButton(
                label: _isEdit ? 'Simpan Perubahan' : 'Buat Role',
                isLoading: provider.isSubmitting,
                onPressed: _submit,
                icon: _isEdit ? Icons.save_outlined : Icons.add_moderator_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}