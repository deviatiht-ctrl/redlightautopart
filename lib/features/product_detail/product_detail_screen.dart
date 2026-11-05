import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/icon_mapper.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../core/utils/format.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/locale_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  int _imageIndex = 0;

  Future<void> _addToCart() async {
    final product = ref.read(productProvider(widget.productId)).value;
    if (product == null) return;
    await ref
        .read(cartProvider.notifier)
        .add(product, quantity: _quantity);
    if (!mounted) return;
    final s = ref.read(stringsProvider);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.t('added_to_cart')),
        action: SnackBarAction(
          label: s.t('view_cart'),
          onPressed: () => context.go('/cart'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productProvider(widget.productId));
    final isFavorite = ref.watch(
      favoritesProvider.select((s) => s.contains(widget.productId)),
    );
    final s = ref.watch(stringsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () =>
                context.canPop() ? context.pop() : context.go('/'),
            child: const GlassContainer(
              borderRadius: 999,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(LucideIcons.arrowLeft, size: 20),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ref
                    .read(favoritesProvider.notifier)
                    .toggle(widget.productId);
              },
              child: GlassContainer(
                borderRadius: 999,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    LucideIcons.heart,
                    size: 20,
                    color: isFavorite ? AppColors.red : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: productAsync.when(
        loading: () => const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 340, width: double.infinity),
                SizedBox(height: 20),
                ShimmerBox(height: 24, width: 220),
                SizedBox(height: 12),
                ShimmerBox(height: 20, width: 120),
                SizedBox(height: 24),
                ShimmerBox(height: 90, width: double.infinity),
              ],
            ),
          ),
        ),
        error: (_, _) => SafeArea(
          child: Center(
            child: TextButton.icon(
              onPressed: () => ref.invalidate(productProvider(widget.productId)),
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text(s.t('retry')),
            ),
          ),
        ),
        data: (product) => Stack(
          children: [
            ResponsiveContainer(
              maxWidth: Responsive.maxDetailWidth,
              child: CustomScrollView(
              slivers: [
                // Galeri imaj
                SliverToBoxAdapter(
                  child: Container(
                    height: 380,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF14171E)
                          : const Color(0xFFF9FAFB),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                      boxShadow: AppShadows.subtle(Theme.of(context).brightness == Brightness.dark),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: product.images.isEmpty
                        ? Container(
                            alignment: Alignment.center,
                            child: const Icon(
                              LucideIcons.package,
                              size: 80,
                              color: AppColors.textMutedDark,
                            ),
                          )
                        : Stack(
                            children: [
                              PageView.builder(
                                itemCount: product.images.length,
                                onPageChanged: (i) =>
                                    setState(() => _imageIndex = i),
                                itemBuilder: (_, i) => Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: CachedNetworkImage(
                                    imageUrl: product.images[i],
                                    fit: BoxFit.contain,
                                    placeholder: (_, _) =>
                                        const ShimmerBox(radius: 0),
                                    errorWidget: (_, _, _) => Container(
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        LucideIcons.package,
                                        size: 80,
                                        color: AppColors.textMutedDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (product.images.length > 1)
                                Positioned(
                                  bottom: 16,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      for (var i = 0;
                                          i < product.images.length;
                                          i++)
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                          ),
                                          width: i == _imageIndex ? 20 : 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: i == _imageIndex
                                                ? AppColors.red
                                                : Colors.white.withValues(
                                                    alpha: 0.4,
                                                  ),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            StockBadge(stock: product.stock),
                          ],
                        ),
                        if (product.categoryName != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                lucideIcon(null),
                                size: 14,
                                color: AppColors.textMutedDark,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                product.categoryName!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMutedDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          formatPrice(product.price),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.red,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (product.compatibleModels.isNotEmpty) ...[
                          Text(
                            s.t('compatible_with'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final model in product.compatibleModels)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? const Color(0xFF1B1E26)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? const Color(0xFF2C3240)
                                          : const Color(0xFFE5E7EB),
                                      width: 1.2,
                                    ),
                                    boxShadow: AppShadows.subtle(Theme.of(context).brightness == Brightness.dark),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        LucideIcons.car,
                                        size: 14,
                                        color: AppColors.red,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        model,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (product.description != null &&
                            product.description!.isNotEmpty) ...[
                          Text(
                            s.t('description'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF1B1E26)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF2C3240)
                                    : const Color(0xFFE5E7EB),
                                width: 1.2,
                              ),
                              boxShadow: AppShadows.subtle(Theme.of(context).brightness == Brightness.dark),
                            ),
                            child: Text(
                              product.description!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF4B5563),
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bar anba glassmorphic: kantite + ajoute
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: GlassContainer(
                    borderRadius: 999,
                    padding: const EdgeInsets.all(8),
                    child: Row(
                  children: [
                    _QtyButton(
                      icon: LucideIcons.minus,
                      onTap: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _QtyButton(
                      icon: LucideIcons.plus,
                      onTap:
                          product.stock <= 0 || _quantity >= product.stock
                          ? null
                          : () => setState(() => _quantity++),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: product.isInStock ? _addToCart : null,
                          icon: const Icon(LucideIcons.shoppingCart, size: 20),
                          label: Text(
                            s.t(
                              product.isInStock
                                  ? 'add_to_cart'
                                  : 'out_of_stock',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onTap == null
              ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.4)
              : Theme.of(context).colorScheme.outline,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? Theme.of(context).disabledColor : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
