import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/role_provider.dart';
import '../../widgets/common/app_widgets.dart';

class UserFormScreen extends StatefulWidget {
  final UserModel? user;
  const UserFormScreen({super.key, this.user});
  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _usernameCtrl = TextEditingController(text: widget.user?.username);
  late final _emailCtrl    = TextEditingController(text: widget.user?.email);
  late final _noHpCtrl     = TextEditingController(text: widget.user?.noHp);
  final _passCtrl          = TextEditingController();
  int? _roleId;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    _roleId = widget.user?.roleId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoleProvider>().loadAll(silent: true);
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _noHpCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = <String, dynamic>{
      'username': _usernameCtrl.text.trim(),
      'email':    _emailCtrl.text.trim(),
      if (_noHpCtrl.text.isNotEmpty)   'no_hp':    _noHpCtrl.text.trim(),
      if (_roleId != null)              'roleid':   _roleId,
    };

    if (!_isEdit) {
      payload['password'] = _passCtrl.text;
    } else if (_passCtrl.text.isNotEmpty) {
      payload['password'] = _passCtrl.text;
    }

    final provider = context.read<UserProvider>();
    final ok = _isEdit
        ? await provider.update(widget.user!.userId, payload)
        : await provider.create(payload);

    if (!mounted) return;
    if (ok) {
      SnackbarHelper.showSuccess(context, _isEdit ? 'User berhasil diperbarui' : 'User berhasil ditambahkan');
      context.pop();
    } else {
      SnackbarHelper.showError(context, provider.error ?? 'Gagal menyimpan data user');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final roleProvider = context.watch<RoleProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit User' : 'Tambah User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Username *',
                hint: 'Masukkan username',
                controller: _usernameCtrl,
                prefixIcon: Icons.person_outline,
                validator: (v) => v == null || v.isEmpty ? 'Username wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Email *',
                hint: 'contoh@email.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email wajib diisi';
                  if (!v.contains('@')) return 'Format email tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: _isEdit ? 'Password Baru (kosongkan jika tidak diubah)' : 'Password *',
                hint: '••••••••',
                controller: _passCtrl,
                obscure: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) {
                  if (!_isEdit && (v == null || v.isEmpty)) return 'Password wajib diisi';
                  if (v != null && v.isNotEmpty && v.length < 6) return 'Password minimal 6 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'No. HP',
                hint: 'Contoh: 081234567890',
                controller: _noHpCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 16),

              // Role Dropdown
              DropdownButtonFormField<int>(
                value: _roleId,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.shield_outlined),
                ),
                items: roleProvider.list.map((r) => DropdownMenuItem(
                  value: r.roleId,
                  child: Text(r.namaRole),
                )).toList(),
                onChanged: (v) => setState(() => _roleId = v),
                hint: const Text('Pilih role'),
              ),

              const SizedBox(height: 28),
              AppButton(
                label: _isEdit ? 'Simpan Perubahan' : 'Tambah User',
                isLoading: userProvider.isSubmitting,
                onPressed: _submit,
                icon: _isEdit ? Icons.save_outlined : Icons.person_add_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}