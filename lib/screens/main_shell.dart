import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/permission_helper.dart';
import '../providers/auth_provider.dart';

// Global controller agar bisa diakses dari screen manapun
final advancedDrawerController = AdvancedDrawerController();

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final navItems = _buildNavItems();
    final currentIndex = _currentNavIndex(location, navItems);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return AdvancedDrawer(
      controller: advancedDrawerController,
      backdropColor: AppColors.primaryDark,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),
      animateChildDecoration: true,
      rtlOpening: false,
      openScale: 0.85,
      openRatio: 0.72,
      childDecoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 30,
            offset: Offset(-10, 0),
          ),
        ],
      ),
      drawer: SafeArea(
        child: _DrawerContent(
          user: user,
          currentLocation: location,
          onClose: () => advancedDrawerController.hideDrawer(),
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex < 0 ? 0 : currentIndex,
          onDestinationSelected: (i) => context.go(navItems[i].route),
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primaryContainer,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: navItems
              .map((item) => NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.icon, color: AppColors.primary),
                    label: item.label,
                  ))
              .toList(),
        ),
      ),
    );
  }

  int _currentNavIndex(String location, List<_NavItem> items) {
    for (int i = 0; i < items.length; i++) {
      if (location.startsWith(items[i].route)) return i;
    }
    return 0;
  }

  List<_NavItem> _buildNavItems() {
    final items = <_NavItem>[
      _NavItem(Icons.dashboard_outlined, 'Dashboard', '/dashboard'),
    ];
    if (PermissionHelper.canViewKambing) {
      items.add(_NavItem(Icons.pets_outlined, 'Kambing', '/kambing'));
    }
    if (PermissionHelper.canScanKambing) {
      items.add(_NavItem(Icons.qr_code_scanner, 'Scan QR', '/scan'));
    }
    if (PermissionHelper.canViewStatistik || PermissionHelper.canViewMonitoring) {
      items.add(_NavItem(Icons.monitor_heart_outlined, 'Monitoring', '/monitoring'));
    }
    // Tambahkan Info/Berita ke bottom nav
    items.add(_NavItem(Icons.article_outlined, 'Info', '/info'));
    return items;
  }
}

// ─── Drawer Content ──────────────────────────────────────────────────────────

class _DrawerContent extends StatelessWidget {
  final dynamic user;
  final String currentLocation;
  final VoidCallback onClose;

  const _DrawerContent({
    required this.user,
    required this.currentLocation,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header Avatar ────────────────────────────────────────────
        const SizedBox(height: 16),
        // Avatar circle
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2.5),
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 14),
        Text(
          user?.username ?? 'Pengguna',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? '',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Text(
            user?.role?.namaRole ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Divider(color: Colors.white.withOpacity(0.15), indent: 24, endIndent: 24),
        const SizedBox(height: 8),

        // ── Menu Items ───────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _SectionLabel('Navigasi Utama'),
              _DrawerTile(icon: Icons.dashboard_outlined, label: 'Dashboard', route: '/dashboard', current: currentLocation, onClose: onClose),
              if (PermissionHelper.canViewKambing)
                _DrawerTile(icon: Icons.pets_outlined, label: 'Data Kambing', route: '/kambing', current: currentLocation, onClose: onClose),
              if (PermissionHelper.canScanKambing)
                _DrawerTile(icon: Icons.qr_code_scanner, label: 'Scan QR', route: '/scan', current: currentLocation, onClose: onClose),
              if (PermissionHelper.canViewStatistik || PermissionHelper.canViewMonitoring)
                _DrawerTile(icon: Icons.monitor_heart_outlined, label: 'Monitoring', route: '/monitoring', current: currentLocation, onClose: onClose),
              _SectionLabel('Informasi'),
              _DrawerTile(icon: Icons.article_outlined, label: 'Info & Berita', route: '/info', current: currentLocation, onClose: onClose),
              if (PermissionHelper.canViewUser || PermissionHelper.canViewRole)
                _SectionLabel('Administrasi'),
              if (PermissionHelper.canViewUser)
                _DrawerTile(icon: Icons.people_outline, label: 'Manajemen User', route: '/user', current: currentLocation, onClose: onClose),
              if (PermissionHelper.canViewRole)
                _DrawerTile(icon: Icons.shield_outlined, label: 'Manajemen Role', route: '/role', current: currentLocation, onClose: onClose),
              _SectionLabel('Akun'),
              _DrawerTile(icon: Icons.person_outline, label: 'Profil Saya', route: '/profile', current: currentLocation, onClose: onClose),
            ],
          ),
        ),

        // ── Logout ───────────────────────────────────────────────────
        Divider(color: Colors.white.withOpacity(0.15), indent: 24, endIndent: 24),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
          ),
          title: const Text('Keluar',
            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700, fontSize: 14)),
          onTap: () async {
            onClose();
            await Future.delayed(const Duration(milliseconds: 300));
            if (!context.mounted) return;
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Konfirmasi Keluar'),
                content: const Text('Apakah Anda yakin ingin keluar?'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      minimumSize: const Size(0, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Keluar'),
                  ),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              await context.read<AuthProvider>().logout();
            }
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Drawer Tile ─────────────────────────────────────────────────────────────

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String current;
  final VoidCallback onClose;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.route,
    required this.current,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current.startsWith(route);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(icon, color: isActive ? Colors.white : Colors.white60, size: 22),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: isActive
            ? Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              )
            : null,
        onTap: () {
          onClose();
          Future.delayed(const Duration(milliseconds: 250), () {
            if (context.mounted) context.go(route);
          });
        },
      ),
    );
  }
}

// ─── Section Label ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white.withOpacity(0.5),
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ─── Nav Item Model ──────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  _NavItem(this.icon, this.label, this.route);
}
