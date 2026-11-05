import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../../core/theme/colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/core_providers.dart';
import '../../providers/locale_provider.dart';
import '../../services/auth_service.dart';
import '../../app.dart' show routerProvider;

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.redirect});

  /// Kote pou ale apre login reyisi (ex: '/checkout').
  final String? redirect;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;
  bool _accepted = false;

  Future<void> _google() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final opened = await ref.read(authServiceProvider).signInWithGoogle();
      if (!opened && mounted) {
        _showError(ref.read(stringsProvider).t('generic_error'));
      } else {
        await ref.read(localStoreProvider).setGuestMode(false);
        ref.invalidate(isAdminProvider);
        final email = ref.read(authServiceProvider).currentUser?.email;
        bool isAdmin = AuthService.isKnownAdminEmail(email);
        if (!isAdmin) {
          try {
            isAdmin = await ref.read(authServiceProvider).isAdmin();
          } catch (_) {
            isAdmin = false;
          }
        }
        if (isAdmin) {
          if (mounted) {
            context.go('/admin');
          } else {
            ref.read(routerProvider).go('/admin');
          }
        }
      }
    } catch (_) {
      if (mounted) _showError(ref.read(stringsProvider).t('generic_error'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final s = ref.read(stringsProvider);
    if (!_emailController.text.contains('@')) { _showError(s.t('email_invalid')); return; }
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).resetPassword(_emailController.text);
      if (mounted) _showError(s.t('reset_email_sent'));
    } catch (_) {
      if (mounted) _showError(s.t('generic_error'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goNext() {
    final target = widget.redirect;
    context.go(target != null && target.startsWith('/') && !target.startsWith('//') && !target.startsWith('/auth') ? target : '/');
  }

  Future<void> _guest() async {
    await ref.read(localStoreProvider).setGuestMode(true);
    if (mounted) context.go('/');
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate() || (!_isLogin && !_accepted)) return;
    setState(() => _loading = true);
    final auth = ref.read(authServiceProvider);
    final s = ref.read(stringsProvider);
    final email = _emailController.text.trim().toLowerCase();
    final isKnownAdmin = AuthService.isKnownAdminEmail(email);

    try {
      if (_isLogin) {
        await auth.signIn(
          email,
          _passwordController.text,
        );
      } else {
        final res = await auth.signUp(
          email,
          _passwordController.text,
          fullName: _nameController.text.trim(),
        );
        if (res.session == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.t('account_created'))),
          );
          return;
        }
      }
      await ref.read(localStoreProvider).setGuestMode(false);
      ref.invalidate(isAdminProvider);
      bool isAdmin = isKnownAdmin;
      if (!isAdmin) {
        try {
          isAdmin = await auth.isAdmin();
        } catch (_) {
          isAdmin = false;
        }
      }
      if (isAdmin) {
        if (mounted) {
          context.go('/admin');
        } else {
          ref.read(routerProvider).go('/admin');
        }
      } else {
        if (mounted) {
          _goNext();
        }
      }
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) _showError(s.t('generic_error'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.jpeg',
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            color: AppColors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.wrench, color: Colors.white, size: 48),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(s.t(_isLogin ? 'welcome_back' : 'create_account'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(s.t('auth_subtitle'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 28),
                  OutlinedButton.icon(onPressed: _loading ? null : _google, icon: const Icon(Icons.account_circle_outlined), label: Text(s.t('google_sign_in'))),
                  const SizedBox(height: 16),
                  Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(s.t('or_email'))), const Expanded(child: Divider())]),
                  const SizedBox(height: 24),
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: s.t('full_name'),
                        prefixIcon: const Icon(LucideIcons.user, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || !v.contains('@'))
                            ? s.t('email_invalid')
                            : null,
                    decoration: InputDecoration(
                      hintText: s.t('email'),
                      prefixIcon: const Icon(LucideIcons.mail, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) => (v == null || v.length < (_isLogin ? 1 : 8))
                        ? s.t('password_minimum')
                        : null,
                    decoration: InputDecoration(
                      hintText: s.t('password'),
                      prefixIcon: const Icon(LucideIcons.lock, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  if (_isLogin) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _loading ? null : _forgotPassword, child: Text(s.t('forgot_password')))),
                  if (!_isLogin) CheckboxListTile(contentPadding: EdgeInsets.zero, value: _accepted, onChanged: (v) => setState(() => _accepted = v ?? false), title: Text(s.t('accept_terms'))),
                  Wrap(alignment: WrapAlignment.center, children: [
                    TextButton(onPressed: () => context.go('/legal/terms'), child: Text(s.t('terms'))),
                    TextButton(onPressed: () => context.go('/legal/privacy'), child: Text(s.t('privacy'))),
                  ]),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: s.t(_isLogin ? 'sign_in' : 'create_account'),
                    loading: _loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      s.t(_isLogin ? 'no_account' : 'have_account'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _guest,
                    icon: const Icon(LucideIcons.user, size: 18),
                    label: Text(s.t('continue_guest')),
                  ),
                ],
              ),
            )),
          ),
        ),
      ),
    );
  }
}
