import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/format.dart';
import '../../providers/commerce_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/locale_provider.dart';
import '../../services/commerce_service.dart';

class CommerceAdminScreen extends ConsumerStatefulWidget {
  const CommerceAdminScreen({super.key});
  @override
  ConsumerState<CommerceAdminScreen> createState() => _CommerceAdminScreenState();
}

class _CommerceAdminScreenState extends ConsumerState<CommerceAdminScreen> {
  final _amount = TextEditingController();
  final _recipient = TextEditingController();
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _method = 'moncash';
  String _kind = 'terms';
  String _locale = 'fr';
  bool _busy = false;
  bool _documentLoaded = false;

  @override
  void dispose() {
    _amount.dispose(); _recipient.dispose(); _title.dispose(); _body.dispose();
    super.dispose();
  }

  Future<T?> _run<T>(Future<T> Function() action) async {
    if (_busy) return null;
    setState(() => _busy = true);
    try { return await action(); } catch (error) {
      if (mounted) {
        final s = ref.read(stringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t(error is CommerceException ? 'commerce_${error.code}' : 'generic_error'))));
      }
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logo(Map<String, dynamic> method) => _run(() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (image == null) return;
    final url = await ref.read(commerceServiceProvider).uploadLogo(await image.readAsBytes(), image.name.split('.').last);
    await ref.read(supabaseClientProvider).from('redlight_payment_methods').update({'logo_url': url}).eq('code', method['code']);
    ref.invalidate(paymentMethodsProvider);
  });

  Future<void> _withdraw() async {
    final service = ref.read(commerceServiceProvider);
    final Map<String, dynamic>? row = await _run(() => service.call('withdrawal.prepare', {
      'amount': double.tryParse(_amount.text.replaceAll(',', '.')),
      'method': _method, 'recipient': _recipient.text.trim(),
    }));
    if (!mounted || row == null) return;
    final s = ref.read(stringsProvider);
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(s.t('confirm_withdrawal')),
      content: Text('${formatPrice((row['amount'] as num).toDouble())}\n${row['method']} · ${row['recipient']}\n\n${s.t('withdrawal_warning')}'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.t('cancel'))),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s.t('confirm_withdrawal')))],
    ));
    if (confirmed != true) return;
    try {
      await service.call('withdrawal.execute', {'reference': row['reference'], 'confirmation': row['reference']});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('withdrawal_complete'))));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t(error is CommerceException ? 'commerce_${error.code}' : 'generic_error'))));
    } finally { ref.invalidate(withdrawalsProvider); }
  }

  Future<void> _loadDocument() => _run(() async {
    final row = await ref.read(supabaseClientProvider).from('redlight_legal_documents').select().eq('kind', _kind).eq('locale', _locale).maybeSingle();
    _title.text = row?['title'] ?? '';
    _body.text = row?['body'] ?? '';
    if (mounted) setState(() => _documentLoaded = true);
  });

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final methods = ref.watch(paymentMethodsProvider);
    final withdrawals = ref.watch(withdrawalsProvider);
    return DefaultTabController(length: 3, child: Scaffold(
      appBar: AppBar(title: Text(s.t('commerce_admin')), bottom: TabBar(isScrollable: true, tabs: [
        Tab(text: s.t('payment_method')), Tab(text: s.t('withdrawals')), Tab(text: s.t('legal_documents')),
      ])),
      body: Column(children: [if (_busy) const LinearProgressIndicator(), Expanded(child: TabBarView(children: [
        methods.when(loading: () => const Center(child: CircularProgressIndicator()), error: (_, _) => Center(child: TextButton(onPressed: () => ref.invalidate(paymentMethodsProvider), child: Text(s.t('retry')))), data: (list) => ListView(padding: const EdgeInsets.all(24), children: [
          Text(s.t('payment_activation_notice')),
          const SizedBox(height: 16),
          for (final method in list) Card(child: ListTile(
            leading: method['logo_url'] == null ? const Icon(Icons.payment) : Image.network(method['logo_url'], width: 48, height: 48, errorBuilder: (_, _, _) => const Icon(Icons.payment)),
            title: Text(method['name']), subtitle: Text(method['code']),
            trailing: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
              IconButton(tooltip: s.t('upload_logo'), onPressed: _busy ? null : () => _logo(method), icon: const Icon(Icons.upload)),
              Switch(value: method['enabled'] == true, onChanged: _busy ? null : (value) => _run(() async {
                await ref.read(supabaseClientProvider).from('redlight_payment_methods').update({'enabled': value}).eq('code', method['code']);
                ref.invalidate(paymentMethodsProvider);
              })),
            ]),
          )),
        ])),
        ListView(padding: const EdgeInsets.all(24), children: [
          Text(s.t('withdrawal_warning')),
          const SizedBox(height: 16),
          TextField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: '${s.t('amount')} (HTG)')),
          const SizedBox(height: 12),
          TextField(controller: _recipient, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: s.t('recipient'), hintText: '509XXXXXXXX')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(initialValue: _method, items: const [DropdownMenuItem(value: 'moncash', child: Text('MonCash')), DropdownMenuItem(value: 'natcash', child: Text('NatCash'))], onChanged: _busy ? null : (v) => setState(() => _method = v!)),
          const SizedBox(height: 12),
          FilledButton(onPressed: _busy ? null : _withdraw, child: Text(s.t('prepare_withdrawal'))),
          const SizedBox(height: 24),
          withdrawals.when(loading: () => const LinearProgressIndicator(), error: (_, _) => TextButton(onPressed: () => ref.invalidate(withdrawalsProvider), child: Text(s.t('retry'))), data: (rows) => Column(children: [for (final row in rows) Card(child: ListTile(
            title: Text('${formatPrice((row['amount'] as num).toDouble())} · ${row['recipient']}'),
            subtitle: SelectableText('${row['status']}\n${row['reference']}${row['error_code'] == null ? '' : '\n${row['error_code']}'}'),
            trailing: row['status'] == 'prepared' ? null : IconButton(tooltip: s.t('verify_payment'), onPressed: _busy ? null : () => _run(() async {
              await ref.read(commerceServiceProvider).call('withdrawal.verify', {'reference': row['reference']});
              ref.invalidate(withdrawalsProvider);
            }), icon: const Icon(Icons.refresh)),
          ))])),
        ]),
        ListView(padding: const EdgeInsets.all(24), children: [
          Text(s.t('legal_admin_notice')),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(initialValue: _kind, items: [for (final kind in ['terms','privacy','support']) DropdownMenuItem(value: kind, child: Text(s.t(kind)))], onChanged: _busy ? null : (v) => setState(() { _kind = v!; _documentLoaded = false; })),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(initialValue: _locale, items: [for (final locale in ['fr','ht','en','es']) DropdownMenuItem(value: locale, child: Text(locale))], onChanged: _busy ? null : (v) => setState(() { _locale = v!; _documentLoaded = false; })),
          TextButton(onPressed: _busy ? null : _loadDocument, child: Text(s.t('load_document'))),
          if (_documentLoaded) ...[
            TextField(controller: _title, decoration: InputDecoration(labelText: s.t('title'))),
            const SizedBox(height: 12),
            TextField(controller: _body, minLines: 10, maxLines: 25, decoration: InputDecoration(labelText: s.t('content'))),
            const SizedBox(height: 16),
            FilledButton(onPressed: _busy ? null : () => _run(() async {
              if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) throw const CommerceException('INVALID_DOCUMENT');
              await ref.read(supabaseClientProvider).from('redlight_legal_documents').upsert({'kind': _kind, 'locale': _locale, 'title': _title.text.trim(), 'body': _body.text.trim(), 'updated_at': DateTime.now().toUtc().toIso8601String()});
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('saved'))));
            }), child: Text(s.t('save'))),
          ],
        ]),
      ]))]),
    ));
  }
}
