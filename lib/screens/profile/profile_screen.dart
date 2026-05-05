import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/permission_helper.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../providers/auth_provider.dart';
import '../../services/upload_service.dart';
import '../../widgets/common/app_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploadingAvatar = false;
  bool _isUploadingIcon   = false;

  // ── Upload Avatar ───────────────────────────────────────────────
  Future<void> _uploadAvatar() async {
    final image = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;
    setState(() => _isUploadingAvatar = true);
    try {
      await UploadService().uploadAvatar(image.path);
      if (mounted) SnackbarHelper.showSuccess(context, 'Foto profil berhasil diperbarui');
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  // ── Upload Icon QR (Global) ────────────────────────────────────
  Future<void> _uploadIconQr() async {
    // Konfirmasi dulu
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.qr_code, color: AppColors.primary),
          SizedBox(width: 10),
          Text('Upload Icon QR'),
        ]),
        content: const Text(
          'Icon yang diupload akan digunakan di SEMUA QR Code kambing.\n\n'
              'Setelah upload, lakukan Regenerate QR pada setiap kambing untuk menerapkan icon baru.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(_, true), child: const Text('Upload')),
        ],
      ),
    );
    if (ok != true) return;

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 256,
      maxHeight: 256,
    );
    if (image == null) return;

    setState(() => _isUploadingIcon = true);
    try {
      await UploadService().uploadIcon(image.path);
      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          'Icon QR berhasil diupload! Lakukan Regenerate QR pada tiap kambing untuk menerapkan.',
        );
      }
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isUploadingIcon = false);
    }
  }

  // ── Logout ─────────────────────────────────────────────────────
  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(_, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AuthProvider>().logout();
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header Foto Profil ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _uploadAvatar,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        _isUploadingAvatar
                            ? const CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primaryContainer,
                          child: CircularProgressIndicator(color: AppColors.primary),
                        )
                            : user?.fotoProfil != null
                            ? CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(
                            ApiConstants.uploads(user!.fotoProfil!),
                          ),
                          onBackgroundImageError: (_, __) {},
                        )
                            : CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            user?.username.isNotEmpty == true
                                ? user!.username[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(user?.username ?? '-',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '-',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(user?.role.namaRole ?? '-',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Info Card ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Column(
                  children: [
                    _InfoTile(Icons.person_outline,  'Username', user?.username ?? '-'),
                    const Divider(height: 1, indent: 56),
                    _InfoTile(Icons.email_outlined,  'Email',    user?.email    ?? '-'),
                    const Divider(height: 1, indent: 56),
                    _InfoTile(Icons.phone_outlined,  'No. HP',   user?.noHp     ?? '-'),
                    const Divider(height: 1, indent: 56),
                    _InfoTile(Icons.shield_outlined, 'Role',     user?.role.namaRole ?? '-'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Upload Icon QR (hanya Admin dengan permission) ──
            if (PermissionHelper.canUploadIcon)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.qr_code, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text('Icon QR Code Global',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ]),
                        const SizedBox(height: 8),
                        const Text(
                          'Upload icon yang akan tampil di tengah semua QR Code kambing. '
                              'Setelah upload, lakukan Regenerate QR pada tiap kambing.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        _isUploadingIcon
                            ? const Center(
                          child: Column(children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('Mengupload icon...', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ]),
                        )
                            : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _uploadIconQr,
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('Upload Icon QR'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
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
              ),

            if (PermissionHelper.canUploadIcon) const SizedBox(height: 16),

            // ── Permissions Card ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.security, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Permissions Saya',
                            style: TextStyle(fontWeight: FontWeight.w700))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text('${user?.role.permissions.length ?? 0}',
                              style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      if (user?.role.menu != null)
                        ...user!.role.menu.entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.key,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6, runSpacing: 4,
                                children: entry.value.map((perm) => Chip(
                                  label: Text(perm, style: const TextStyle(fontSize: 10)),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                )).toList(),
                              ),
                            ],
                          ),
                        )),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Logout ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppButton(
                label: 'Keluar',
                onPressed: _logout,
                color: AppColors.error,
                icon: Icons.logout_rounded,
                outlined: true,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoTile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.primary, size: 22),
    title: Text(label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
    subtitle: Text(value,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
  );
}