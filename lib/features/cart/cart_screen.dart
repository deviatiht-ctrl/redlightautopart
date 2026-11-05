import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../core/utils/format.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/locale_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final s = ref.watch(stringsProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 850;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: Responsive.maxDetailWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  s.t('cart_title'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: cart.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(20),
                    child: ListShimmer(),
                  ),
                  error: (_, _) => EmptyState(
                    icon: LucideIcons.alertCircle,
                    title: s.t('cart_load_error'),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return EmptyState(
                        icon: LucideIcons.shoppingCart,
                        title: s.t('cart_empty'),
                        subtitle: s.t('cart_empty_sub'),
                      );
                    }

                    if (isDesktop) {
                      // 2-kolòn Desktop layout: Lis pwodwi sou goch + Rezime kòmand sou dwat
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: ListView.separated(
                                itemCount: items.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 12),
                                itemBuilder: (_, i) => _CartTile(item: items[i]),
                              ),
                            ),
                            const SizedBox(width: 24),
                            SizedBox(
                              width: 340,
                              child: _OrderSummaryBox(total: total, s: s),
                            ),
                          ],
                        ),
                      );
                    }

                    // Mobil & ti ekran: stacked layout
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                            itemCount: items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (_, i) => _CartTile(item: items[i]),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                          child: _OrderSummaryBox(total: total, s: s),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSummaryBox extends StatelessWidget {
  const _OrderSummaryBox({required this.total, required this.s});

  final double total;
  final dynamic s;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E26) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
          width: 1.2,
        ),
        boxShadow: AppShadows.elevated(isDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.t('total'),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textMutedDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                formatPrice(total),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: s.t('checkout'),
            icon: LucideIcons.chevronRight,
            onPressed: () => context.push('/checkout'),
          ),
        ],
      ),
    );
  }
}

class _CartTile extends ConsumerWidget {
  const _CartTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = item.product;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 72,
              height: 72,
              color: isDark ? const Color(0xFF14171E) : const Color(0xFFF9FAFB),
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.contain,
                      errorWidget: (_, _, _) => const Icon(
                        LucideIcons.package,
                        color: AppColors.textMutedDark,
                      ),
                    )
                  : const Icon(
                      LucideIcons.package,
                      color: AppColors.textMutedDark,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatPrice(product.price),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MiniButton(
                icon: LucideIcons.minus,
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(cartProvider.notifier).setQuantity(product.id, item.quantity - 1);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _MiniButton(
                icon: LucideIcons.plus,
                onTap: item.quantity >= product.stock
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        ref.read(cartProvider.notifier).setQuantity(product.id, item.quantity + 1);
                      },
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(
                  LucideIcons.trash2,
                  size: 18,
                  color: AppColors.textMutedDark,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(cartProvider.notifier).remove(product.id);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap == null
              ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.outline,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: onTap == null
              ? Theme.of(context).disabledColor
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
