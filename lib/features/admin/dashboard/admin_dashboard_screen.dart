import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/utils/format.dart';
import '../../../providers/admin_providers.dart';
import '../../../providers/locale_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);
    final orders = ref.watch(adminOrdersProvider);
    final s = ref.watch(stringsProvider);
    final hPadding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: RefreshIndicator(
        color: AppColors.red,
        onRefresh: () async {
          ref.invalidate(adminProductsProvider);
          ref.invalidate(adminOrdersProvider);
        },
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 24),
          children: [
            Text(
              s.t('dashboard'),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            stats.when(
              loading: () => const SizedBox(height: 120, child: ListShimmer(itemCount: 1, itemHeight: 110)),
              error: (_, _) => Text(s.t('stats_load_error')),
              data: (stats) => LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final isSmallMobile = totalWidth < 340;
                  final isMobile = totalWidth < 700;
                  final double spacing = isMobile ? 12 : 16;

                  double cardWidth;
                  if (isSmallMobile) {
                    cardWidth = totalWidth;
                  } else if (isMobile) {
                    cardWidth = (totalWidth - spacing) / 2; // 2 kolòn sou telefòn
                  } else if (totalWidth < 1050) {
                    cardWidth = (totalWidth - (spacing * 2)) / 3;
                  } else {
                    cardWidth = (totalWidth - (spacing * 3)) / 4; // 4 kolòn sou gwo ekran
                  }

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      _StatCard(
                        width: cardWidth,
                        compact: isMobile,
                        icon: LucideIcons.package,
                        label: s.t('products'),
                        value: '${stats.productCount}',
                      ),
                      _StatCard(
                        width: cardWidth,
                        compact: isMobile,
                        icon: LucideIcons.receipt,
                        label: s.t('orders_today'),
                        value: '${stats.ordersToday}',
                      ),
                      _StatCard(
                        width: cardWidth,
                        compact: isMobile,
                        icon: LucideIcons.clock,
                        label: s.t('pending'),
                        value: '${stats.pendingOrders}',
                      ),
                      _StatCard(
                        width: cardWidth,
                        compact: isMobile,
                        icon: LucideIcons.trendingUp,
                        label: s.t('total_sales'),
                        value: formatPrice(stats.totalRevenue),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 36),
            Text(
              s.t('recent_orders'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            orders.when(
              loading: () => const ListShimmer(itemCount: 3, itemHeight: 60),
              error: (_, _) => Text(s.t('orders_load_error')),
              data: (list) => list.isEmpty
                  ? Text(
                      s.t('no_orders'),
                      style: const TextStyle(
                        color: AppColors.textMutedLight,
                      ),
                    )
                  : Card(
                      child: Column(
                        children: [
                          for (final order in list.take(6))
                            ListTile(
                              leading: const Icon(LucideIcons.receipt, size: 20),
                              title: Text(
                                '#${order.id.substring(0, 8).toUpperCase()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${formatDate(order.createdAt)} • ${s.t('items_count', {'count': '${order.itemCount}'})}',
                              ),
                              trailing: Text(
                                formatPrice(order.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                AppConstants.poweredBy,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMutedLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.width,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final double width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: EdgeInsets.all(compact ? 12 : 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 34 : 40,
            height: compact ? 34 : 40,
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(compact ? 8 : 10),
            ),
            child: Icon(icon, size: compact ? 17 : 20, color: AppColors.red),
          ),
          SizedBox(height: compact ? 10 : 16),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 17 : 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 11 : 13,
              color: AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}
