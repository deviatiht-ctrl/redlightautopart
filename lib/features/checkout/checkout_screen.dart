import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/format.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/cart_provider.dart';
import '../../providers/commerce_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/locale_provider.dart';
import '../../providers/orders_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  late final String _checkoutKey;
  String? _method;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _checkoutKey = prefs.getString('pending_checkout_key') ?? const Uuid().v4();
    _address.text = ref.read(currentUserProvider)?.userMetadata?['address'] as String? ?? '';
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_placing || !_formKey.currentState!.validate() || _method == null) return;
    final items = ref.read(cartProvider).value ?? [];
    if (items.isEmpty) return;
    setState(() => _placing = true);
    try {
      await ref.read(localStoreProvider).saveCart(items.map((e) => e.toJson()).toList());
      await ref.read(sharedPreferencesProvider).setString('pending_checkout_key', _checkoutKey);
      final id = await ref.read(orderServiceProvider).placeOrder(
        items: items, checkoutKey: _checkoutKey, deliveryAddress: _address.text.trim(), paymentMethod: _method!,
      );
      await ref.read(cartProvider.notifier).clear();
      await ref.read(sharedPreferencesProvider).remove('pending_checkout_key');
      ref.invalidate(myOrdersProvider);
      if (mounted) context.go('/payment/$id');
    } catch (error) {
      if (mounted) {
        final s = ref.read(stringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t(error.toString().contains('insufficient_stock') ? 'insufficient_stock' : 'order_failed'))));
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final user = ref.watch(currentUserProvider);
    // Checkout mande yon kont — envite dwe konekte anvan.
    if (user == null || user.isAnonymous) {
      return Scaffold(appBar: AppBar(title: Text(s.t('order'))), body: Center(child: FilledButton(
        onPressed: () => context.go('/auth?redirect=/checkout'), child: Text(s.t('sign_in_to_continue')),
      )));
    }
    final items = ref.watch(cartProvider).value ?? [];
    final methods = ref.watch(paymentMethodsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('order'))),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: Responsive.maxFormWidth,
          child: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(24), children: [
        Text(s.t('delivery_address'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextFormField(controller: _address, maxLines: 3, maxLength: 1000,
          decoration: InputDecoration(hintText: s.t('address_hint')),
          validator: (value) => (value?.trim().length ?? 0) < 5 ? s.t('address_invalid') : null),
        const SizedBox(height: 24),
        Text(s.t('payment_method'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        methods.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => TextButton(onPressed: () => ref.invalidate(paymentMethodsProvider), child: Text(s.t('retry'))),
          data: (all) {
            final enabled = all.where((m) => m['enabled'] == true).toList();
            if (enabled.isEmpty) return Text(s.t('payments_unavailable'));
            return Column(children: [for (final method in enabled) Card(
              child: ListTile(
                leading: method['logo_url'] == null ? const Icon(Icons.account_balance_wallet_outlined) : Image.network(method['logo_url'], width: 42, height: 42, errorBuilder: (_, _, _) => const Icon(Icons.payment)),
                title: Text(method['name']),
                trailing: Icon(_method == method['code'] ? Icons.radio_button_checked : Icons.radio_button_off),
                onTap: _placing ? null : () => setState(() => _method = method['code']),
              ),
            )]);
          },
        ),
        const SizedBox(height: 24),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          for (final item in items) ListTile(contentPadding: EdgeInsets.zero, title: Text('${item.product.name} ×${item.quantity}'), trailing: Text(formatPrice(item.lineTotal))),
          const Divider(),
          ListTile(contentPadding: EdgeInsets.zero, title: Text(s.t('total')), trailing: Text(formatPrice(ref.watch(cartTotalProvider)))),
        ]))),
        const SizedBox(height: 16),
        Text(s.t('server_total_notice'), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 24),
        PrimaryButton(label: s.t('continue_payment'), loading: _placing, onPressed: items.isEmpty || _method == null ? null : _placeOrder),
      ])))),
    );
  }
}
