import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (ok) {
      context.go('/dashboard');
    } else {
      SnackbarHelper.showError(context, auth.error ?? 'Login gagal');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              height: size.height - MediaQuery.of(context).padding.top,
              child: Column(
                children: [
                  // Header
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(Icons.pets, size: 48, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        const Text('SIKAM',
                            style: TextStyle(color: Colors.white, fontSize: 32,
                                fontWeight: FontWeight.w800, letterSpacing: 3)),
                        const SizedBox(height: 6),
                        Text('Sistem Informasi Kambing',
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                      ],
                    ),
                  ),

                  // Form Card
                  Expanded(
                    flex: 5,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width > 600 ? size.width * 0.15 : 24,
                        vertical: 32,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Selamat Datang',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            const Text('Masuk untuk melanjutkan',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                            const SizedBox(height: 28),

                            AppTextField(
                              label: 'Email',
                              hint: 'contoh@email.com',
                              controller: _emailCtrl,
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Email wajib diisi';
                                if (!v.contains('@')) return 'Format email tidak valid';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            AppTextField(
                              label: 'Password',
                              hint: 'Masukkan password',
                              controller: _passCtrl,
                              obscure: true,
                              prefixIcon: Icons.lock_outline,
                              textInputAction: TextInputAction.done,
                              validator: (v) => v == null || v.isEmpty ? 'Password wajib diisi' : null,
                            ),
                            const SizedBox(height: 8),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => context.push('/auth/forgot-password'),
                                child: const Text('Lupa password?'),
                              ),
                            ),
                            const SizedBox(height: 8),

                            Consumer<AuthProvider>(
                              builder: (_, auth, __) => AppButton(
                                label: 'Masuk',
                                isLoading: auth.isLoading,
                                onPressed: _login,
                                icon: Icons.login_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}