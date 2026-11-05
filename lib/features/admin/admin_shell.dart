import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../l10n/app_strings.dart';
import '../../providers/core_providers.dart';
import '../../providers/locale_provider.dart';

/// Shell panel admin — adaptif sou tout gwosè ekran:
/// - Desktop (>= 900px) : Sidebar goch pèmanan + kontni
/// - Mobil & Tablèt (< 900px) : AppBar ak bouton meni (hamburger) + Drawer + kontni plen ekran
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  static const _items = [
    (LucideIcons.layoutDashboard, 'dashboard', '/admin'),
    (LucideIcons.sparkles, 'admin_offers', '/admin/offers'),
    (LucideIcons.package, 'products', '/admin/products'),
    (LucideIcons.tag, 'categories', '/admin/categories'),
    (LucideIcons.receipt, 'orders', '/admin/orders'),
    (LucideIcons.creditCard, 'commerce_admin', '/admin/commerce'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final s = ref.watch(stringsProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return isAdmin.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.red)),
      ),
      error: (_, _) => Scaffold(body: _accessDenied(context, ref, s)),
      data: (admin) {
        if (!admin) return Scaffold(body: _accessDenied(context, ref, s));

        if (isDesktop) {
          // Layout Desktop
          return Scaffold(
            body: Row(
              children: [
                _AdminSidebar(items: _items, s: s),
                const VerticalDivider(width: 1, color: AppColors.borderLight),
                Expanded(child: child),
              ],
            ),
          );
        }

        // Layout Mobil & Tablèt ak Drawer
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 1,
            title: Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/logo.jpeg',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(LucideIcons.shieldCheck, color: AppColors.red),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'REDLIGHT ADMIN',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(LucideIcons.store, size: 16, color: AppColors.red),
                label: Text(
                  s.t('view_store'),
                  style: const TextStyle(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          drawer: Drawer(
            child: _AdminSidebar(items: _items, s: s, isDrawer: true),
          ),
          body: child,
        );
      },
    );
  }

  Widget _accessDenied(BuildContext context, WidgetRef ref, S s) {
    return EmptyState(
      icon: LucideIcons.shieldAlert,
      title: s.t('access_denied'),
      subtitle: s.t('not_admin'),
      actionLabel: s.t('sign_out'),
      onAction: () async {
        await ref.read(authServiceProvider).signOut();
        if (context.mounted) context.go('/auth');
      },
    );
  }
}

class _AdminSidebar extends ConsumerWidget {
  const _AdminSidebar({
    required this.items,
    required this.s,
    this.isDrawer = false,
  });

  final List<(IconData, String, String)> items;
  final S s;
  final bool isDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;

    return Container(
      width: isDrawer ? null : 240,
      color: AppColors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/logo.jpeg',
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REDLIGHT',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'ADMIN PANEL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMutedLight,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final (icon, labelKey, path) in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      child: _SidebarItem(
                        icon: icon,
                        label: s.t(labelKey),
                        selected: location == path,
                        onTap: () {
                          if (isDrawer) Navigator.pop(context);
                          context.go(path);
                        },
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderLight),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _SidebarItem(
                    icon: LucideIcons.store,
                    label: s.t('view_store'),
                    selected: false,
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      context.go('/');
                    },
                  ),
                  const SizedBox(height: 4),
                  _SidebarItem(
                    icon: LucideIcons.logOut,
                    label: s.t('sign_out'),
                    selected: false,
                    onTap: () async {
                      if (isDrawer) Navigator.pop(context);
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go('/auth');
                    },
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

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.red.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.red : AppColors.textMutedLight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    color: selected ? AppColors.red : AppColors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
