import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/glass_nav_bar.dart';
import '../../providers/cart_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';

/// Shell app kliyan adaptif:
/// - Sou mobil & tablèt (< 900px) : GlassNavBar flottant anba (santre, max 520px)
/// - Sou laptop & desktop (>= 900px) : Top Web Header avèk logo, lyen, lang, tèm ak panyen
class ClientShell extends ConsumerWidget {
  const ClientShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final currentIndex = navigationShell.currentIndex;

    void onTabTap(int index) {
      navigationShell.goBranch(
        index,
        initialLocation: index == currentIndex,
      );
    }

    return Scaffold(
      extendBody: true,
      appBar: isDesktop
          ? PreferredSize(
              preferredSize: const Size.fromHeight(68),
              child: _DesktopWebHeader(
                currentIndex: currentIndex,
                onTap: onTabTap,
              ),
            )
          : null,
      body: navigationShell,
      bottomNavigationBar: isDesktop
          ? null
          : GlassNavBar(
              currentIndex: currentIndex,
              onTap: onTabTap,
            ),
    );
  }
}

class _DesktopWebHeader extends ConsumerWidget {
  const _DesktopWebHeader({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _navItems = [
    (LucideIcons.home, 'nav_home'),
    (LucideIcons.search, 'nav_search'),
    (LucideIcons.shoppingCart, 'nav_cart'),
    (LucideIcons.heart, 'nav_favorites'),
    (LucideIcons.user, 'nav_profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cartCount = ref.watch(cartCountProvider);
    final isAdmin = ref.watch(isAdminProvider).asData?.value == true;
    final currentLocale = ref.watch(localeProvider);

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101216) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF232732) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: ResponsiveContainer(
        maxWidth: Responsive.maxContentWidth,
        alignment: Alignment.center,
        child: Row(
          children: [
            // Logo & Tit
            GestureDetector(
              onTap: () => onTap(0),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/images/logo.jpeg',
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: AppColors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.car, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.appName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'PIÈCES D\'ORIGINE & PERFORMANCE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 36),

            // Navigation Tabs Desktop
            Expanded(
              child: Row(
                children: [
                  for (var i = 0; i < _navItems.length; i++)
                    _WebNavLink(
                      icon: _navItems[i].$1,
                      label: s.t(_navItems[i].$2),
                      selected: i == currentIndex,
                      badge: i == 2 && cartCount > 0 ? cartCount : null,
                      onTap: () => onTap(i),
                    ),
                ],
              ),
            ),

            // Aksyon sou bò dwat: Chanje Lang + Dark Mode + Admin
            Row(
              children: [
                // Seleksyon lang rapid
                PopupMenuButton<String>(
                  tooltip: 'Lang / Language',
                  initialValue: currentLocale.languageCode,
                  onSelected: (code) =>
                      ref.read(localeProvider.notifier).setLocale(code),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'fr', child: Text('🇫🇷 Français')),
                    PopupMenuItem(value: 'ht', child: Text('🇭🇹 Kreyòl Ayisyen')),
                    PopupMenuItem(value: 'en', child: Text('🇺🇸 English')),
                    PopupMenuItem(value: 'es', child: Text('🇪🇸 Español')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2129) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2C313E) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.globe, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          currentLocale.languageCode.toUpperCase(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.chevronDown, size: 12),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Tèm Sombre / Clè toggle
                IconButton(
                  tooltip: isDark ? 'Mòd Clè' : 'Mòd Sombre',
                  onPressed: () {
                    final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
                    ref.read(themeModeProvider.notifier).update(newMode);
                  },
                  icon: Icon(
                    isDark ? LucideIcons.sun : LucideIcons.moon,
                    size: 19,
                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF4B5563),
                  ),
                ),

                if (kIsWeb || isAdmin) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => context.go('/admin'),
                    icon: const Icon(LucideIcons.shieldCheck, size: 15),
                    label: const Text(
                      'Admin',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WebNavLink extends StatelessWidget {
  const _WebNavLink({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.red.withValues(alpha: isDark ? 0.2 : 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected
                        ? AppColors.red
                        : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
                  ),
                  if (badge != null && badge! > 0)
                    Positioned(
                      top: -6,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? AppColors.red
                      : (isDark ? Colors.white : const Color(0xFF374151)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
