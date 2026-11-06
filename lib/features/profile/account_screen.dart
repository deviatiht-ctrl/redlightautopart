import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';
import '../../providers/commerce_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/commerce_service.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key, required this.section});
  final String section;
  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _currentPassword = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final metadata = ref.read(currentUserProvider)?.userMetadata;
    _name.text = metadata?['full_name'] as String? ?? '';
    _phone.text = metadata?['phone'] as String? ?? '';
    _address.text = metadata?['address'] as String? ?? '';
  }

  @override
  void dispose() {
    for (final controller in [_name,_phone,_address,_password,_currentPassword,_confirm]) { controller.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    final s = ref.read(stringsProvider);
    if (widget.section == 'delete') {
      final confirmation = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: Text(s.t('delete_account')), content: Text(s.t('delete_warning')),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s.t('yes_delete')))],
      ));
      if (confirmation != true) return;
    }
    setState(() => _busy = true);
    try {
      final auth = ref.read(authServiceProvider);
      switch (widget.section) {
        case 'profile':
          await auth.updateProfile(name: _name.text, phone: _phone.text, address: _address.text);
        case 'password':
          await auth.changePassword(_password.text);
        case 'delete':
          final user = ref.read(currentUserProvider);
          if (user == null || user.email == null) throw const CommerceException('AUTHENTICATION_REQUIRED');
          if (_currentPassword.text.isNotEmpty) await auth.signIn(user.email!, _currentPassword.text);
          await ref.read(commerceServiceProvider).call('account.delete', {'confirmation': 'DELETE'});
          await ref.read(localStoreProvider).setGuestMode(false);
          await ref.read(localStoreProvider).saveFavorites({});
          await ref.read(cartProvider.notifier).clear();
          ref.invalidate(favoritesProvider);
          await auth.signOut();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('saved'))));
        context.go(widget.section == 'delete' ? '/auth' : '/profile');
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t(error is CommerceException ? 'commerce_${error.code}' : 'account_update_failed'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final user = ref.watch(currentUserProvider);
    if (!const {'profile','password','delete'}.contains(widget.section)) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(s.t('generic_error'))));
    }
    final title = s.t(switch(widget.section) { 'password' => 'change_password', 'delete' => 'delete_account', _ => 'edit_profile' });
    return Scaffold(appBar: AppBar(title: Text(title)), body: user == null
      ? Center(child: TextButton(onPressed: () => context.go('/auth'), child: Text(s.t('sign_in'))))
      : Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: Form(key: _form, child: ListView(padding: const EdgeInsets.all(24), children: [
        if (widget.section == 'profile') ...[
          ListTile(contentPadding: EdgeInsets.zero, leading: Icon(user.emailConfirmedAt == null ? Icons.mail_outline : Icons.verified_user_outlined), title: Text(user.email ?? ''), subtitle: Text(s.t(user.emailConfirmedAt == null ? 'email_unverified' : 'email_verified'))),
          TextFormField(controller: _name, maxLength: 100, decoration: InputDecoration(labelText: s.t('full_name')), validator: (v) => (v?.trim().length ?? 0) < 2 ? s.t('required_field') : null),
          const SizedBox(height: 16),
          TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: s.t('phone'), hintText: '509XXXXXXXX'), validator: (v) => v!.isNotEmpty && !RegExp(r'^509\d{8}$').hasMatch(v.trim()) ? s.t('invalid_phone') : null),
          const SizedBox(height: 16),
          TextFormField(controller: _address, maxLength: 1000, maxLines: 3, decoration: InputDecoration(labelText: s.t('delivery_address'))),
        ],
        if (widget.section == 'password') ...[
          Text(s.t('password_security_notice')),
          const SizedBox(height: 20),
          TextFormField(controller: _password, obscureText: true, autofillHints: const [AutofillHints.newPassword], decoration: InputDecoration(labelText: s.t('new_password')), validator: (v) => (v?.length ?? 0) < 8 ? s.t('password_minimum') : null),
          const SizedBox(height: 16),
          TextFormField(controller: _confirm, obscureText: true, decoration: InputDecoration(labelText: s.t('confirm_password')), validator: (v) => v != _password.text ? s.t('password_mismatch') : null),
        ],
        if (widget.section == 'delete') ...[
          const Icon(Icons.delete_forever_outlined, size: 64),
          const SizedBox(height: 20),
          Text(s.t('delete_warning')),
          const SizedBox(height: 20),
          Text(s.t('reauth_notice')),
          const SizedBox(height: 20),
          if (user.appMetadata['providers'] is List && (user.appMetadata['providers'] as List).contains('email')) TextFormField(controller: _currentPassword, obscureText: true, decoration: InputDecoration(labelText: s.t('password')), validator: (v) => v == null || v.isEmpty ? s.t('required_field') : null),
          const SizedBox(height: 16),
          TextFormField(controller: _confirm, decoration: InputDecoration(labelText: s.t('type_delete')), validator: (v) => v != 'DELETE' ? s.t('type_delete') : null),
        ],
        const SizedBox(height: 24),
        FilledButton(onPressed: _busy ? null : _save, style: widget.section == 'delete' ? FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error) : null, child: Text(widget.section == 'delete' ? s.t('delete_account') : s.t('save'))),
        if (_busy) const LinearProgressIndicator(),
      ])))));
  }
}

class LegalScreen extends ConsumerWidget {
  const LegalScreen({super.key, required this.kind});
  final String kind;
  static const _kinds = {'terms', 'privacy', 'support'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider).languageCode;
    if (!_kinds.contains(kind)) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(s.t('document_unavailable'))));
    }
    return Scaffold(appBar: AppBar(title: Text(s.t(kind))), body: FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.watch(supabaseClientProvider).from('redlight_legal_documents').select().eq('kind', kind).inFilter('locale', [locale, 'fr']),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        final rows = snapshot.data ?? [];
        final localized = rows.where((r) => r['locale'] == locale);
        final row = localized.isNotEmpty ? localized.first : (rows.isNotEmpty ? rows.first : null);
        return ListView(padding: const EdgeInsets.all(24), children: [
          if (row != null) ...[
            Text(row['title'], style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16), SelectableText(row['body'], style: const TextStyle(height: 1.6)),
          ] else Text(s.t(snapshot.hasError ? 'connection_error' : 'document_unavailable')),
        ]);
      },
    ));
  }
}
