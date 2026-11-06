import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/format.dart';
import '../../providers/commerce_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/locale_provider.dart';
import '../../providers/orders_provider.dart';
import '../../services/commerce_service.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with WidgetsBindingObserver {
  final _phone = TextEditingController();
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _payment;
  String? _error;
  bool _busy = false;
  Timer? _pollTimer;
  Timer? _ussdCountdownTimer;
  int _ussdSecondsLeft = 90;
  int _polls = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _ussdCountdownTimer?.cancel();
    _phone.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _payment != null) {
      _verify();
    }
  }

  Future<void> _load() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      final order = await client
          .from('redlight_orders')
          .select()
          .eq('id', widget.orderId)
          .eq('user_id', user.id)
          .single();
      final payment = await client
          .from('redlight_payments')
          .select()
          .eq('order_id', widget.orderId)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _order = order;
        _payment = payment;
        _error = null;
      });

      if (payment != null) {
        if (payment['status'] == 'paid') return;
        _startPolling();
        await _verify();
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'generic_error');
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _polls = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted) {
        _pollTimer?.cancel();
        return;
      }
      if (++_polls > 35 || _payment?['status'] == 'paid') {
        _pollTimer?.cancel();
        return;
      }
      await _verify(silent: true);
    });
  }

  void _startUssdCountdown() {
    _ussdCountdownTimer?.cancel();
    setState(() => _ussdSecondsLeft = 90);
    _ussdCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_payment?['status'] == 'paid') {
        timer.cancel();
        return;
      }
      if (_ussdSecondsLeft <= 1) {
        timer.cancel();
        setState(() => _ussdSecondsLeft = 0);
        _verify();
      } else {
        setState(() => _ussdSecondsLeft--);
      }
    });
  }

  Future<void> _start() async {
    if (_busy) return;
    final isUssd = _order?['payment_method'] == 'moncash_ussd';
    if (isUssd && !RegExp(r'^509\d{8}$').hasMatch(_phone.text.trim())) {
      setState(() => _error = 'invalid_phone');
      return;
    }

    await _request('payment.start');
    if (!mounted) return;

    if (_payment != null && _payment?['status'] != 'paid') {
      if (isUssd) {
        _startUssdCountdown();
        _startPolling();
      } else if (_payment?['redirect_url'] != null) {
        _startPolling();
        await _openInAppPayment();
      }
    }
  }

  Future<void> _verify({bool silent = false}) =>
      _request('payment.verify', silent: silent);

  Future<void> _request(String action, {bool silent = false}) async {
    if (_busy && !silent) return;
    if (!silent) {
      setState(() {
        _busy = true;
        _error = null;
      });
    }

    try {
      final result = await ref.read(commerceServiceProvider).call(action, {
        'order_id': widget.orderId,
        'phone_number': _phone.text.trim(),
      });
      if (mounted) {
        setState(() => _payment = result);
      }
      ref.invalidate(myOrdersProvider);
      ref.invalidate(orderTrackingProvider(widget.orderId));
    } catch (error) {
      if (mounted && !silent) {
        setState(() => _error = error is CommerceException
            ? 'commerce_${error.code}'
            : 'generic_error');
      }
    } finally {
      if (mounted && !silent) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _openInAppPayment() async {
    final rawUrl = _payment?['redirect_url'] as String?;
    final uri = Uri.tryParse(rawUrl ?? '');
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      setState(() => _error = 'open_payment_failed');
      return;
    }

    if (kIsWeb) {
      // Sou Web: louvri nan fenèt/ongle separe pou sekirite
      try {
        await launchUrl(uri,
            mode: LaunchMode.platformDefault, webOnlyWindowName: '_blank');
      } catch (_) {
        if (mounted) setState(() => _error = 'open_payment_failed');
      }
      return;
    }

    // Sou Mobil (Android & iOS): louvri In-App WebView san kite aplikasyon an
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _InAppWebViewSheet(
        url: uri,
        onClose: () async {
          Navigator.of(modalContext).pop();
          if (mounted) await _verify();
        },
        onPaymentFinished: () async {
          Navigator.of(modalContext).pop();
          if (mounted) await _verify();
        },
      ),
    );

    if (mounted) {
      await _verify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final paid = _payment?['status'] == 'paid';
    final status = _payment?['status'] ?? 'unpaid';
    final isUssd = _order?['payment_method'] == 'moncash_ussd';

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('secure_payment')),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/orders'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            children: [
              if (paid)
                _buildSuccessState(s)
              else if ((status == 'pending' || status == 'review') &&
                  _payment != null)
                _buildPendingState(s, isUssd)
              else
                _buildInitialState(s, isUssd),

              if (_busy) ...[
                const SizedBox(height: 24),
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(strokeWidth: 2.5),
                      SizedBox(height: 12),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.go('/orders'),
                icon: const Icon(LucideIcons.package, size: 16),
                label: Text(s.t('view_my_orders')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState(dynamic s) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.checkCircle2,
              size: 48,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            s.t('payment_success'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.t('payment_success_desc'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 20),
          if (_order != null)
            Text(
              formatPrice((_order!['total'] as num).toDouble()),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          const SizedBox(height: 14),
          if (_payment?['transaction_id'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Text(
                'ID: ${_payment!['transaction_id']}',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 28),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => context.go('/orders'),
            icon: const Icon(LucideIcons.truck, size: 18),
            label: Text(
              s.t('track_order'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingState(dynamic s, bool isUssd) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isUssd ? LucideIcons.smartphone : LucideIcons.creditCard,
            size: 64,
            color: AppColors.red,
          ),
          const SizedBox(height: 16),
          Text(
            s.t('payment_state_${_payment?['status'] ?? 'pending'}'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (_order != null)
            Text(
              formatPrice((_order!['total'] as num).toDouble()),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.red,
              ),
            ),
          const SizedBox(height: 12),
          if (_payment?['status'] == 'review') ...[
            Text(
              s.t('payment_review_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
          ],
          _buildPaymentIds(s),
          const SizedBox(height: 16),
          if (isUssd) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.bellRing,
                          color: AppColors.info, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.t('ussd_step_tip'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _ussdSecondsLeft / 90.0,
                    backgroundColor: AppColors.info.withValues(alpha: 0.2),
                    color: AppColors.info,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.t('ussd_timer', {'sec': '$_ussdSecondsLeft'}),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              s.t('payment_instructions'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            if (_payment?['redirect_url'] != null)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _busy ? null : _openInAppPayment,
                icon: const Icon(LucideIcons.externalLink, size: 18),
                label: Text(s.t('open_payment')),
              ),
          ],
          const SizedBox(height: 16),
          if (_error != null)
            _buildErrorBanner(s)
          else if (_ussdSecondsLeft == 0 && isUssd)
            _buildFailedBanner(s),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
            onPressed: _busy ? null : () => _verify(),
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: Text(s.t('verify_payment')),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _busy
                ? null
                : () {
                    _pollTimer?.cancel();
                    _ussdCountdownTimer?.cancel();
                    setState(() {
                      _payment = null;
                      _error = null;
                    });
                  },
            icon: const Icon(LucideIcons.rotateCcw, size: 15),
            label: Text(s.t('retry_payment')),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentIds(dynamic s) {
    final reference = _payment?['reference'];
    final transactionId = _payment?['transaction_id'];
    if (reference == null && transactionId == null) {
      return const SizedBox.shrink();
    }
    const mono = TextStyle(
      fontSize: 12,
      fontFamily: 'monospace',
      fontWeight: FontWeight.w600,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reference != null)
            SelectableText('${s.t('payment_reference')}: $reference',
                style: mono),
          if (transactionId != null)
            SelectableText('ID: $transactionId', style: mono),
          const SizedBox(height: 6),
          Text(
            s.t('payment_auto_check'),
            style: const TextStyle(fontSize: 11, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(dynamic s, bool isUssd) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.shieldCheck, size: 64, color: AppColors.red),
          const SizedBox(height: 16),
          Text(
            s.t('secure_payment'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (_order != null)
            Text(
              formatPrice((_order!['total'] as num).toDouble()),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.red,
              ),
            ),
          const SizedBox(height: 16),
          if (isUssd) ...[
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: s.t('phone'),
                hintText: '509XXXXXXXX',
                prefixIcon: const Icon(LucideIcons.phone),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_error != null) ...[
            _buildErrorBanner(s),
            const SizedBox(height: 16),
          ],
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _busy || _order == null ? null : _start,
            icon: const Icon(LucideIcons.arrowRight, size: 18),
            label: Text(
              s.t('start_payment'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(dynamic s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.alertCircle, color: AppColors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              s.t(_error!),
              style: const TextStyle(
                color: AppColors.red,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedBanner(dynamic s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.clockAlert,
                  color: AppColors.warning, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.t('payment_failed'),
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            s.t('payment_failed_desc'),
            style: const TextStyle(fontSize: 12, height: 1.3),
          ),
        ],
      ),
    );
  }
}

/// Modal BottomSheet ki monte anndan aplikasyon an pou kouri pòtay peman Plop Plop
/// san kliyan an pa bezwen sòti sou Chrome oswa Safari.
class _InAppWebViewSheet extends StatefulWidget {
  const _InAppWebViewSheet({
    required this.url,
    required this.onClose,
    required this.onPaymentFinished,
  });

  final Uri url;
  final VoidCallback onClose;
  final VoidCallback onPaymentFinished;

  @override
  State<_InAppWebViewSheet> createState() => _InAppWebViewSheetState();
}

class _InAppWebViewSheetState extends State<_InAppWebViewSheet> {
  late final WebViewController _controller;
  double _loadingProgress = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress / 100.0;
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _isLoading = false);
            // Si URL la montre yon estati siksè oswa callback
            if (url.toLowerCase().contains('success') ||
                url.toLowerCase().contains('callback') ||
                url.toLowerCase().contains('completed')) {
              widget.onPaymentFinished();
            }
          },
          onWebResourceError: (error) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.lock, size: 18, color: AppColors.success),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Plop Plop — Peman Sekirize',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.onClose,
                  icon: const Icon(LucideIcons.x, size: 16),
                  label: const Text('Fèmen'),
                ),
              ],
            ),
          ),
          if (_isLoading)
            LinearProgressIndicator(
              value: _loadingProgress > 0 ? _loadingProgress : null,
              minHeight: 3,
              color: AppColors.red,
            ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
