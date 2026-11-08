import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/config.dart';
import 'core/theme/colors.dart';
import 'core/theme/dark_theme.dart';
import 'providers/core_providers.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // .env (fallback si --dart-define pa itilize)
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env pa obligatwa
  }

  final prefs = await SharedPreferences.getInstance();

  var configured = AppConfig.isConfigured;
  if (configured) {
    try {
      await SupabaseService.init();
    } catch (_) {
      configured = false;
    }
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER_ERROR: ${details.exceptionAsString()}');
  };
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF1E2025),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.alertTriangle, color: AppColors.red, size: 36),
              const SizedBox(height: 12),
              Text(
                'Erè afichaj: ${details.exceptionAsString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: configured ? const RedlightApp() : const _ConfigMissingApp(),
    ),
  );
}

/// Montre si kle Supabase yo manke — pa janm yon ekran blan.
class _ConfigMissingApp extends ConsumerWidget {
  const _ConfigMissingApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/logo.jpeg',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 24),
                const Icon(
                  LucideIcons.shieldAlert,
                  size: 40,
                  color: AppColors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Clés Supabase manquantes / Supabase keys missing',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Set SUPABASE_URL and SUPABASE_ANON_KEY in .env '
                  'or pass them with --dart-define.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMutedDark, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
