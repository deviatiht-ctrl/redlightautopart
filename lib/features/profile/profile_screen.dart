import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/primary_button.dart';
import '../../l10n/app_strings.dart';
import '../../models/app_user.dart';
import '../../providers/core_providers.dart';
import '../../providers/theme_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/auth_service.dart';
import '../language/language_screen.dart' show LanguageTile;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 800,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
            Text(
              s.t('profile'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            if (user == null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1B1E26)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2C3240)
                        : const Color(0xFFE5E7EB),
                    width: 1.2,
                  ),
                  boxShadow: AppShadows.elevated(Theme.of(context).brightness == Brightness.dark),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF252932)
                            : const Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.user,
                        size: 30,
                        color: AppColors.textMutedDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.t('guest'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.t('guest_sub'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMutedDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: s.t('sign_in_or_create'),
                      onPressed: () => context.push('/auth'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Builder(
                builder: (context) {
                  final appUser = AppUser.fromSupabase(user);
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B1E26) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
                        width: 1.2,
                      ),
                      boxShadow: AppShadows.elevated(isDark),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.red.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.user,
                            size: 26,
                            color: AppColors.red,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (appUser.fullName != null)
                                Text(
                                  appUser.fullName!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              Text(
                                appUser.email,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMutedDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              if (AuthService.isKnownAdminEmail(user.email) || (ref.watch(isAdminProvider).asData?.value ?? false)) ...[
                _ProfileTile(
                  icon: LucideIcons.shieldCheck,
                  label: s.t('admin_panel'),
                  color: AppColors.red,
                  onTap: () => context.go('/admin'),
                ),
                const SizedBox(height: 10),
              ],
              _ProfileTile(icon: LucideIcons.user, label: s.t('edit_profile'), onTap: () => context.push('/account/profile')),
              _ProfileTile(icon: LucideIcons.lock, label: s.t('change_password'), onTap: () => context.push('/account/password')),
              _ProfileTile(
                icon: LucideIcons.receipt,
                label: s.t('my_orders'),
                onTap: () => context.push('/orders'),
              ),
              _ProfileTile(
                icon: LucideIcons.heart,
                label: s.t('my_favorites'),
                onTap: () => context.go('/favorites'),
              ),
              const SizedBox(height: 20),
              _ProfileTile(
                icon: LucideIcons.logOut,
                label: s.t('sign_out'),
                color: AppColors.red,
                onTap: () async {
                  try {
                    await ref.read(localStoreProvider).setGuestMode(false);
                    await ref.read(localStoreProvider).saveFavorites({});
                    await ref.read(cartProvider.notifier).clear();
                    ref.invalidate(favoritesProvider);
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) context.go('/auth');
                  } catch (_) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('generic_error'))));
                  }
                },
              ),
            ],
            const SizedBox(height: 10),
            _ProfileTile(
              icon: LucideIcons.languages,
              label: s.t('language'),
              onTap: () => _openLanguageSheet(context, ref),
            ),
            const SizedBox(height: 16),
            Text(s.t('settings'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownButtonFormField<ThemeMode>(
              initialValue: ref.watch(themeModeProvider),
              decoration: InputDecoration(labelText: s.t('appearance'), prefixIcon: const Icon(Icons.brightness_6_outlined)),
              items: [for (final mode in ThemeMode.values) DropdownMenuItem(value: mode, child: Text(s.t('theme_${mode.name}')))],
              onChanged: (mode) { if (mode != null) ref.read(themeModeProvider.notifier).update(mode); },
            ),
            const SizedBox(height: 16),
            for (final (kind, icon) in [('terms', LucideIcons.fileText), ('privacy', LucideIcons.shield), ('support', LucideIcons.mail)])
              _ProfileTile(icon: icon, label: s.t(kind), onTap: () => context.push('/legal/$kind')),
            _ProfileTile(icon: LucideIcons.info, label: s.t('about_app'), onTap: () => showAboutDialog(context: context, applicationName: AppConstants.appName, applicationVersion: '1.0.0', applicationLegalese: AppConstants.poweredBy)),
            if (user != null && ref.watch(isAdminProvider).value == true)
              _ProfileTile(icon: LucideIcons.settings, label: s.t('commerce_admin'), onTap: () => context.go('/admin')),
            if (user != null)
              _ProfileTile(icon: LucideIcons.trash2, label: s.t('delete_account'), color: AppColors.red, onTap: () => context.push('/account/delete')),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                AppConstants.poweredBy,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMutedDark,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  /// Sheet chanjman lang — tout UI chanje imedyatman via localeProvider.
  void _openLanguageSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => const _LanguageSheet(),
    );
  }
}

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final s = ref.watch(stringsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            s.t('choose_language'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          for (final (code, name, _) in languageOptions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LanguageTile(
                name: name,
                selected: locale.languageCode == code,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(code);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1E26) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
            width: 1.2,
          ),
          boxShadow: AppShadows.subtle(isDark),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: color ?? (isDark ? Colors.white : Colors.black87)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: color ?? (isDark ? Colors.white : const Color(0xFF1F2937)),
                      ),
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.textMutedDark,
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
