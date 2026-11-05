import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../core/utils/format.dart';
import '../../l10n/app_strings.dart';
import '../../models/app_order.dart';
import '../../providers/core_providers.dart';
import '../../providers/locale_provider.dart';
import '../../providers/orders_provider.dart';
import 'order_tracking_card.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);
    final user = ref.watch(currentUserProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(s.t('my_orders')),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 800,
          child: user == null
              ? EmptyState(
                  icon: LucideIcons.lock,
                  title: s.t('sign_in_to_see_orders'),
                  actionLabel: s.t('sign_in'),
                  onAction: () => context.push('/auth?redirect=/orders'),
                )
              : orders.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(20),
                    child: ListShimmer(itemCount: 4, itemHeight: 110),
                  ),
                  error: (_, _) => EmptyState(
                    icon: LucideIcons.alertCircle,
                    title: s.t('orders_load_error'),
                    actionLabel: s.t('retry'),
                    onAction: () => ref.invalidate(myOrdersProvider),
                  ),
                  data: (orders) => orders.isEmpty
                      ? EmptyState(
                          icon: LucideIcons.package,
                          title: s.t('no_orders'),
                          subtitle: s.t('no_orders_sub'),
                        )
                      : RefreshIndicator(
                          color: AppColors.red,
                          onRefresh: () async =>
                              ref.invalidate(myOrdersProvider),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: orders.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => _OrderCard(order: orders[i]),
                          ),
                        ),
                ),
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});

  final AppOrder order;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final s = ref.read(stringsProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.t('cancel_order_q')),
        content: Text(s.t('cancel_order_warn')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.t('no')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.t('yes_cancel'),
              style: const TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(orderServiceProvider).cancelOrder(order.id);
      ref.invalidate(myOrdersProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.t('cancel_order_failed'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = AppConstants.orderStatusColor(order.status);
    final s = ref.watch(stringsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  orderStatusLabel(s, order.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            formatDate(order.createdAt),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMutedDark,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${item.productName ?? s.t('part')} ×${item.quantity}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMutedDark,
                ),
              ),
            ),
          const Divider(height: 20),
          Text(s.t('payment_state_${order.paymentStatus}')),
          if (order.status != 'cancelled')
            TextButton.icon(
              onPressed: () => context.push('/payment/${order.id}'),
              icon: const Icon(Icons.payment),
              label: Text(s.t(order.paymentStatus == 'paid' ? 'secure_payment' : 'continue_payment')),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  formatPrice(order.total),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.red,
                  ),
                ),
              ),
              Text(
                paymentLabel(s, order.paymentMethod),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMutedDark,
                ),
              ),
              if (order.status == 'pending') ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _cancel(context, ref),
                  child: Text(
                    s.t('cancel'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.red,
                    ),
                  ),
                ),
              ],
            ],
          ),
          OrderTrackingSection(order: order),
        ],
      ),
    );
  }
}
