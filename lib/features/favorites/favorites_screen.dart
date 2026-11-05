import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/locale_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteProductsProvider);
    final s = ref.watch(stringsProvider);
    final cols = Responsive.productGridColumns(context);
    final isWide = cols > 2;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: Responsive.maxContentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  s.t('nav_favorites'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: favorites.when(
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ProductGridShimmer(crossAxisCount: cols),
                  ),
                  error: (_, _) => EmptyState(
                    icon: LucideIcons.alertCircle,
                    title: s.t('favorites_load_error'),
                    actionLabel: s.t('retry'),
                    onAction: () => ref.invalidate(favoriteProductsProvider),
                  ),
                  data: (products) => products.isEmpty
                      ? EmptyState(
                          icon: LucideIcons.heart,
                          title: s.t('no_favorites'),
                          subtitle: s.t('no_favorites_sub'),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: isWide ? 0.72 : 0.66,
                          ),
                          itemCount: products.length,
                          itemBuilder: (_, i) =>
                              ProductCard(product: products[i]),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
