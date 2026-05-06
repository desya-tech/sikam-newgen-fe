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
  bool _isUploadingIcon = false;

  // Gemini API Key
  final _geminiKeyCtrl = TextEditingController();
  bool _geminiKeyVisible = false;
  bool _geminiKeyDirty = false; // apakah ada perubahan

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = context.read<AuthProvider>().geminiApiKey ?? '';
      _geminiKeyCtrl.text = key;
    });
  }

  @override
  void dispose() {
    _geminiKeyCtrl.dispose();
    super.dispose();
  }

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

  // ── Simpan Gemini API Key ──────────────────────────────────────
  Future<void> _saveGeminiKey() async {
    final key = _geminiKeyCtrl.text.trim();
    final auth = context.read<AuthProvider>();
    final ok = await auth.saveGeminiKey(key);
    if (mounted) {
      if (ok) {
        setState(() => _geminiKeyDirty = false);
        SnackbarHelper.showSuccess(context,
            key.isEmpty ? 'Gemini API Key berhasil dihapus' : 'Gemini API Key berhasil disimpan');
      } else {
        SnackbarHelper.showError(context, auth.error ?? 'Gagal menyimpan API Key');
      }
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
                    _InfoTile(Icons.person_outline, 'Username', user?.username ?? '-'),
                    const Divider(height: 1, indent: 56),
                    _InfoTile(Icons.email_outlined, 'Email', user?.email ?? '-'),
                    const Divider(height: 1, indent: 56),
                    _InfoTile(Icons.phone_outlined, 'No. HP', user?.noHp ?? '-'),
                    const Divider(height: 1, indent: 56),
                    _InfoTile(Icons.shield_outlined, 'Role', user?.role.namaRole ?? '-'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Gemini AI API Key ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4285F4).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.auto_awesome,
                                color: Color(0xFF4285F4), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Gemini AI Key',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 15)),
                                Text('Untuk fitur Analisis AI Kambing',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          // Badge status
                          _GeminiKeyBadge(hasKey: auth.geminiApiKey?.isNotEmpty == true),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Input field
                      TextField(
                        controller: _geminiKeyCtrl,
                        obscureText: !_geminiKeyVisible,
                        onChanged: (_) => setState(() => _geminiKeyDirty = true),
                        decoration: InputDecoration(
                          hintText: 'Masukkan Gemini API Key...',
                          prefixIcon: const Icon(Icons.key_outlined, size: 20),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(_geminiKeyVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                    size: 20),
                                onPressed: () =>
                                    setState(() => _geminiKeyVisible = !_geminiKeyVisible),
                                tooltip: _geminiKeyVisible ? 'Sembunyikan' : 'Tampilkan',
                              ),
                              if (_geminiKeyCtrl.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _geminiKeyCtrl.clear();
                                    setState(() => _geminiKeyDirty = true);
                                  },
                                  tooltip: 'Hapus',
                                ),
                            ],
                          ),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Info cara generate
                      GestureDetector(
                        onTap: () => _showGeminiKeyInfo(context),
                        child: const Row(
                          children: [
                            Icon(Icons.help_outline,
                                size: 14, color: Color(0xFF4285F4)),
                            SizedBox(width: 6),
                            Text(
                              'Cara mendapatkan Gemini API Key →',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4285F4),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Tombol simpan
                      SizedBox(
                        width: double.infinity,
                        child: auth.isSavingGeminiKey
                            ? const Center(child: CircularProgressIndicator())
                            : FilledButton.icon(
                          onPressed: _geminiKeyDirty ? _saveGeminiKey : null,
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text('Simpan API Key'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4285F4),
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
                            Text('Mengupload icon...',
                                style: TextStyle(
                                    color: AppColors.textSecondary, fontSize: 12)),
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
                        const Expanded(
                            child: Text('Permissions Saya',
                                style: TextStyle(fontWeight: FontWeight.w700))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text('${user?.role.permissions.length ?? 0}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
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
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: entry.value
                                    .map((perm) => Chip(
                                  label: Text(perm,
                                      style: const TextStyle(fontSize: 10)),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ))
                                    .toList(),
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

  void _showGeminiKeyInfo(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF4285F4)),
                SizedBox(width: 10),
                Text('Cara Mendapatkan Gemini API Key',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 20),
            _StepTile(
              step: '1',
              title: 'Buka Google AI Studio',
              desc: 'Kunjungi aistudio.google.com (login dengan akun Google)',
            ),
            _StepTile(
              step: '2',
              title: 'Klik "Get API Key"',
              desc: 'Pilih "Create API key in new project" atau pilih project yang ada',
            ),
            _StepTile(
              step: '3',
              title: 'Salin API Key',
              desc: 'Copy API key yang dihasilkan (format: AIzaSy...)',
            ),
            _StepTile(
              step: '4',
              title: 'Paste di sini',
              desc: 'Tempelkan di kolom "Gemini API Key" di atas, lalu tekan Simpan',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'API Key tersimpan di database server Anda sendiri, bukan di cloud pihak ketiga.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Subwidgets ────────────────────────────────────────────────────────────────

class _GeminiKeyBadge extends StatelessWidget {
  final bool hasKey;
  const _GeminiKeyBadge({required this.hasKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: hasKey
            ? AppColors.sehat.withOpacity(0.12)
            : AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasKey ? Icons.check_circle_outline : Icons.warning_amber_outlined,
            size: 14,
            color: hasKey ? AppColors.sehat : AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            hasKey ? 'Tersimpan' : 'Belum ada',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: hasKey ? AppColors.sehat : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String step, title, desc;
  const _StepTile({required this.step, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(step,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
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