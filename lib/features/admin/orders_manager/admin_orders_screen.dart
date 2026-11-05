import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_strings.dart';
import '../../../models/app_order.dart';
import '../../../providers/admin_providers.dart';
import '../../../providers/core_providers.dart';
import '../../../providers/locale_provider.dart';
import 'tracking_editor.dart';

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    AppOrder order,
    String status,
  ) async {
    try {
      await ref.read(orderServiceProvider).updateStatus(order.id, status);
      ref.invalidate(adminOrdersProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(stringsProvider).t('status_change_failed'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(adminOrdersProvider);
    final s = ref.watch(stringsProvider);

    final hPadding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.t('orders'),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: orders.when(
                loading: () => const ListShimmer(itemCount: 6, itemHeight: 90),
                error: (_, _) => EmptyState(
                  icon: LucideIcons.alertCircle,
                  title: s.t('orders_load_error'),
                  actionLabel: s.t('retry'),
                  onAction: () => ref.invalidate(adminOrdersProvider),
                ),
                data: (list) => list.isEmpty
                    ? EmptyState(
                        icon: LucideIcons.receipt,
                        title: s.t('no_orders_admin'),
                      )
                    : ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) =>
                            _AdminOrderCard(
                              order: list[i],
                              onStatusChanged: (st) =>
                                  _changeStatus(context, ref, list[i], st),
                            ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminOrderCard extends ConsumerWidget {
  const _AdminOrderCard({required this.order, required this.onStatusChanged});

  final AppOrder order;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = AppConstants.orderStatusColor(order.status);
    final s = ref.watch(stringsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      formatDate(order.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatPrice(order.total),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Builder(builder: (context) {
                      // change_order_status() pèmèt sèlman confirmed→shipped→delivered
                      // lè peman an 'paid'. Montre sèlman tranzisyon valab yo.
                      final next = switch (order.status) {
                        'confirmed' when order.paymentStatus == 'paid' => 'shipped',
                        'shipped' when order.paymentStatus == 'paid' => 'delivered',
                        _ => null,
                      };
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: next == null
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  orderStatusLabel(s, order.status),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              )
                            : DropdownButton<String>(
                                value: order.status,
                                underline: const SizedBox.shrink(),
                                isDense: true,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                                items: [
                                  for (final st in [order.status, next])
                                    DropdownMenuItem(
                                      value: st,
                                      child: Text(orderStatusLabel(s, st)),
                                    ),
                                ],
                                onChanged: (v) {
                                  if (v != null && v != order.status) onStatusChanged(v);
                                },
                              ),
                      );
                    }),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(s.t('payment_state_${order.paymentStatus}'), style: TextStyle(color: AppConstants.orderStatusColor(order.status), fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${item.productName ?? s.t('part')} ×${item.quantity} — ${formatPrice(item.unitPrice)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMutedLight,
                  ),
                ),
              ),
            if (order.deliveryAddress != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    LucideIcons.mapPin,
                    size: 14,
                    color: AppColors.textMutedLight,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.deliveryAddress!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMutedLight,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Text(
              '${s.t('payment')}: ${paymentLabel(s, order.paymentMethod)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMutedLight,
              ),
            ),
            if (order.status != 'cancelled')
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      TrackingEditorDialog.open(context, order),
                  icon: const Icon(LucideIcons.truck, size: 15),
                  label: Text(s.t('manage_tracking')),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
