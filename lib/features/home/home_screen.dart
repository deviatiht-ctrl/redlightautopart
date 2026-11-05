import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/format.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../models/category.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/locale_provider.dart';
import '../../providers/offers_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedVehicle = 'BMW 1 Hatchback (E81)';
  String _selectedVehicleSpec = '116d 2.0 (66 KW / 90 PS) (01.2011 - 12.2011)';

  Future<void> _refresh() async {
    ref.invalidate(categoriesProvider);
    ref.invalidate(popularProductsProvider);
    ref.invalidate(newProductsProvider);
    ref.invalidate(todayOffersProvider);
  }

  void _showVehicleSelector(BuildContext context) {
    final s = ref.read(stringsProvider);
    final vehicles = [
      ('BMW 1 Hatchback (E81)', '116d 2.0 (66 KW / 90 PS) (01.2011 - 12.2011)'),
      ('Toyota Corolla (E210)', '1.8 Hybrid (90 KW / 122 PS) (01.2019 - ...)'),
      ('Honda Civic X (FC/FK)', '1.5 VTEC (134 KW / 182 PS) (02.2017 - ...)'),
      ('Nissan Patrol (Y61)', '3.0 DTi (118 KW / 160 PS) (05.2000 - ...)'),
      ('Ford Ranger (T6)', '3.2 TDCi 4x4 (147 KW / 200 PS) (04.2011 - ...)'),
      ('Hyundai Tucson (TL)', '2.0 CRDi (136 KW / 185 PS) (06.2015 - ...)'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(LucideIcons.car, color: AppColors.red, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    s.t('change_vehicle'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: vehicles.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final (car, spec) = vehicles[i];
                    final isCurrent = car == _selectedVehicle;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCurrent ? AppColors.red.withValues(alpha: 0.15) : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.car,
                          color: isCurrent ? AppColors.red : Colors.grey.shade700,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        car,
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                          color: isCurrent ? AppColors.red : null,
                        ),
                      ),
                      subtitle: Text(
                        spec,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      trailing: isCurrent ? const Icon(LucideIcons.check, color: AppColors.red, size: 20) : null,
                      onTap: () {
                        setState(() {
                          _selectedVehicle = car;
                          _selectedVehicleSpec = spec;
                        });
                        Navigator.pop(ctx);
                      },
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

  void _showWelcomeOfferDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(LucideIcons.gift, color: Color(0xFFFF5000), size: 24),
            SizedBox(width: 10),
            Text('Offre de bienvenue', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profitez de 10% de réduction immédiate sur votre première commande de pièces auto !',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5000).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF5000).withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Code Promo :', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(
                    'REDLIGHT10',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF5000),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5000),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/catalog');
            },
            child: const Text('Voir le catalogue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : const Color(0xFFF7F8FA),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.red,
          onRefresh: _refresh,
          child: ResponsiveContainer(
            maxWidth: Responsive.maxContentWidth,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
              // Top Vehicle Header Bar
              SliverToBoxAdapter(
                child: _VehicleHeader(
                  carName: _selectedVehicle,
                  carSpec: _selectedVehicleSpec,
                  onTap: () => _showVehicleSelector(context),
                  onAdminTap: kIsWeb ? () => context.go('/admin') : null,
                ),
              ),

              // Search Bar + Action Icon
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.go('/catalog'),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E2025) : const Color(0xFFEFF1F4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.search,
                                  size: 18,
                                  color: isDark ? Colors.white60 : const Color(0xFF8E95A2),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    s.t('search_hint'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark ? Colors.white60 : const Color(0xFF8E95A2),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Action icon with red notification badge
                      GestureDetector(
                        onTap: () => _showVehicleSelector(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2025) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                LucideIcons.car,
                                size: 20,
                                color: Color(0xFFFF5000),
                              ),
                              Positioned(
                                top: 7,
                                right: 7,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // TODAY'S OFFERS Carousel with Auto-Swipe
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _SectionTitle(s.t('todays_offers')),
                      ),
                      const SizedBox(height: 12),
                      const _TodayOffersCarousel(),
                    ],
                  ),
                ),
              ),

              // NEW AT REDLIGHT (Uniform compact cards)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _SectionTitle(s.t('new_at_redlight')),
                      ),
                      const SizedBox(height: 12),
                      const _NewProductsRow(),
                    ],
                  ),
                ),
              ),

              // TRENDING NOW (Clean cutout cards)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _SectionTitle(s.t('trending_now')),
                      ),
                      const SizedBox(height: 12),
                      const _TrendingProductsRow(),
                    ],
                  ),
                ),
              ),

              // SEASONAL OFFERS (Bigger product cards with photo, name, and bold price)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _SectionTitle(s.t('seasonal_offers')),
                      ),
                      const SizedBox(height: 12),
                      const _SeasonalOffersRow(),
                    ],
                  ),
                ),
              ),

              // SOMETHING FOR YOU (Dark promo banner)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(s.t('something_for_you')),
                      const SizedBox(height: 12),
                      _SomethingForYouBanner(
                        onTap: () => _showWelcomeOfferDialog(context),
                      ),
                    ],
                  ),
                ),
              ),

              // CATEGORIES (Wide rectangular horizontal cards with depth)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(s.t('categories')),
                      const SizedBox(height: 4),
                      Consumer(
                        builder: (_, ref, _) {
                          final count = ref.watch(newProductsProvider).asData?.value.length ?? 38552;
                          return Text(
                            s.t('items_available', {'count': '$count'}),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      const _CategoriesList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

// -----------------------------------------------------------------------------
// TOP VEHICLE HEADER BAR
// -----------------------------------------------------------------------------
class _VehicleHeader extends StatelessWidget {
  const _VehicleHeader({
    required this.carName,
    required this.carSpec,
    required this.onTap,
    this.onAdminTap,
  });

  final String carName;
  final String carSpec;
  final VoidCallback onTap;
  final VoidCallback? onAdminTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF111317),
      child: Row(
        children: [
          // Orange circular car icon badge
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.car,
                  size: 20,
                  color: Color(0xFFFF5000),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Vehicle Info
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          carName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.chevronDown, size: 14, color: Colors.white70),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    carSpec,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onAdminTap != null)
            TextButton.icon(
              onPressed: onAdminTap,
              icon: const Icon(LucideIcons.shieldCheck, size: 14, color: AppColors.red),
              label: const Text(
                'Admin',
                style: TextStyle(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SECTION TITLE
// -----------------------------------------------------------------------------
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TODAY'S OFFERS CAROUSEL WITH AUTO-SWIPE & REPOSITIONABLE BUTTON
// -----------------------------------------------------------------------------
class _TodayOffersCarousel extends ConsumerStatefulWidget {
  const _TodayOffersCarousel();

  @override
  ConsumerState<_TodayOffersCarousel> createState() => _TodayOffersCarouselState();
}

class _TodayOffersCarouselState extends ConsumerState<_TodayOffersCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
    _startAutoSwipe();
  }

  void _startAutoSwipe() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final offers = ref.read(todayOffersProvider).asData?.value ?? [];
      if (offers.length <= 1) return;
      final int nextPage = (_currentPage + 1) % offers.length;
      _controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Color _parseHex(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFFFF5000);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offersAsync = ref.watch(todayOffersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return offersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ShimmerBox(width: double.infinity, height: 190, radius: 18),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (offers) {
        if (offers.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _controller,
                itemCount: offers.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final offer = offers[index];
                  final btnColor = _parseHex(offer.buttonColor);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1B1E26) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
                          width: 1.2,
                        ),
                        boxShadow: AppShadows.elevated(isDark),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Background Banner Flyer Image
                          CachedNetworkImage(
                            imageUrl: offer.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => const ShimmerBox(radius: 0),
                            errorWidget: (_, _, _) => Container(
                              color: const Color(0xFF23252A),
                              child: const Icon(LucideIcons.image, color: Colors.white30, size: 48),
                            ),
                          ),
                          // Subtle dark overlay gradient for readability
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.black.withValues(alpha: 0.45),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          // Subtitle & Title if configured
                          if (offer.title.isNotEmpty || (offer.subtitle != null && offer.subtitle!.isNotEmpty))
                            Positioned(
                              left: 20,
                              top: 22,
                              right: 140,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (offer.subtitle != null && offer.subtitle!.isNotEmpty) ...[
                                    Text(
                                      offer.subtitle!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  if (offer.title.isNotEmpty)
                                    Text(
                                      offer.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        height: 1.2,
                                        shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
                                      ),
                                    ),
                                ],
                              ),
                            ),

                          // Interactive Repositioned SHOP NOW button
                          Align(
                            alignment: Alignment(offer.buttonAlignmentX, offer.buttonAlignmentY),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: GestureDetector(
                                onTap: () {
                                  if (offer.productId != null && offer.productId!.isNotEmpty) {
                                    context.push('/product/${offer.productId}');
                                  } else {
                                    context.go('/catalog');
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: btnColor,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    offer.buttonText.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      letterSpacing: 0.8,
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
                },
              ),
            ),
            const SizedBox(height: 10),
            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < offers.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _currentPage ? 18 : 6,
                    height: 5,
                    decoration: BoxDecoration(
                      color: i == _currentPage ? const Color(0xFFFF5000) : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// NEW AT REDLIGHT (Compact cards: centered cutout photo + clean text)
// -----------------------------------------------------------------------------
class _NewProductsRow extends ConsumerWidget {
  const _NewProductsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(newProductsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return productsAsync.when(
      loading: () => const SizedBox(
        height: 128,
        child: Row(
          children: [
            SizedBox(width: 16),
            ShimmerBox(width: 102, height: 128, radius: 14),
            SizedBox(width: 10),
            ShimmerBox(width: 102, height: 128, radius: 14),
            SizedBox(width: 10),
            ShimmerBox(width: 102, height: 128, radius: 14),
          ],
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 128,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final product = products[i];
              return GestureDetector(
                onTap: () => context.push('/product/${product.id}'),
                child: Container(
                  width: 102,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B1E26) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
                      width: 1.2,
                    ),
                    boxShadow: AppShadows.elevated(isDark),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Product photo clean cutout
                      Expanded(
                        child: Center(
                          child: product.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: product.imageUrl!,
                                  fit: BoxFit.contain,
                                  placeholder: (_, _) => const ShimmerBox(radius: 6),
                                  errorWidget: (_, _, _) => const Icon(
                                    LucideIcons.package,
                                    size: 32,
                                    color: Colors.grey,
                                  ),
                                )
                              : const Icon(LucideIcons.package, size: 32, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// TRENDING NOW (Clean cutout items without messy backgrounds)
// -----------------------------------------------------------------------------
class _TrendingProductsRow extends ConsumerWidget {
  const _TrendingProductsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popularAsync = ref.watch(popularProductsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return popularAsync.when(
      loading: () => const SizedBox(
        height: 128,
        child: Row(
          children: [
            SizedBox(width: 16),
            ShimmerBox(width: 102, height: 128, radius: 14),
            SizedBox(width: 10),
            ShimmerBox(width: 102, height: 128, radius: 14),
          ],
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 128,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final product = products[i];
              return GestureDetector(
                onTap: () => context.push('/product/${product.id}'),
                child: Container(
                  width: 102,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B1E26) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
                      width: 1.2,
                    ),
                    boxShadow: AppShadows.elevated(isDark),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: product.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: product.imageUrl!,
                                  fit: BoxFit.contain,
                                  placeholder: (_, _) => const ShimmerBox(radius: 6),
                                  errorWidget: (_, _, _) => const Icon(
                                    LucideIcons.package,
                                    size: 32,
                                    color: Colors.grey,
                                  ),
                                )
                              : const Icon(LucideIcons.package, size: 32, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// SEASONAL OFFERS (Bigger card: large photo, name, bold price)
// -----------------------------------------------------------------------------
class _SeasonalOffersRow extends ConsumerWidget {
  const _SeasonalOffersRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(newProductsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return productsAsync.when(
      loading: () => const SizedBox(
        height: 245,
        child: Row(
          children: [
            SizedBox(width: 16),
            ShimmerBox(width: 175, height: 245, radius: 16),
            SizedBox(width: 12),
            ShimmerBox(width: 175, height: 245, radius: 16),
          ],
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 245,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final product = products[i];
              return GestureDetector(
                onTap: () => context.push('/product/${product.id}'),
                child: Container(
                  width: 175,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B1E26) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
                      width: 1.2,
                    ),
                    boxShadow: AppShadows.elevated(isDark),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Large photo
                      Container(
                        height: 135,
                        width: double.infinity,
                        color: isDark ? const Color(0xFF14171E) : const Color(0xFFF9FAFB),
                        padding: const EdgeInsets.all(10),
                        child: product.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: product.imageUrl!,
                                fit: BoxFit.contain,
                                placeholder: (_, _) => const ShimmerBox(radius: 0),
                                errorWidget: (_, _, _) => const Icon(
                                  LucideIcons.package,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              )
                            : const Icon(LucideIcons.package, size: 40, color: Colors.grey),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF111827),
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              formatPrice(product.price),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// SOMETHING FOR YOU (Dark promo container with gift box)
// -----------------------------------------------------------------------------
class _SomethingForYouBanner extends StatelessWidget {
  const _SomethingForYouBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 105,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161920) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
            width: 1.2,
          ),
          boxShadow: AppShadows.elevated(isDark),
        ),
        child: Row(
          children: [
            // Festive Gift box graphic
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFF252932),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.gift,
                  size: 38,
                  color: Color(0xFFFF6A00),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'For new users only!',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Welcome offer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Get it now',
                        style: TextStyle(
                          color: Color(0xFFFF5000),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFFFF5000)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CATEGORIES LIST (Wide horizontal rectangular cards with depth effect)
// -----------------------------------------------------------------------------
class _CategoriesList extends ConsumerWidget {
  const _CategoriesList();

  static const _defaultCategoryImages = <String, String>{
    'tyres': 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=500&q=80',
    'pneus': 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=500&q=80',
    'fren': 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?w=500&q=80',
    'frein': 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?w=500&q=80',
    'brake': 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?w=500&q=80',
    'motè': 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?w=500&q=80',
    'moteur': 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?w=500&q=80',
    'engine': 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?w=500&q=80',
    'batri': 'https://images.unsplash.com/photo-1597762470488-3877b1f538c6?w=500&q=80',
    'batterie': 'https://images.unsplash.com/photo-1597762470488-3877b1f538c6?w=500&q=80',
    'battery': 'https://images.unsplash.com/photo-1597762470488-3877b1f538c6?w=500&q=80',
    'lwil': 'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?w=500&q=80',
    'huile': 'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?w=500&q=80',
    'oil': 'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?w=500&q=80',
  };

  String _getCategoryImageUrl(Category cat) {
    if (cat.imageUrl != null && cat.imageUrl!.isNotEmpty) {
      return cat.imageUrl!;
    }
    final lower = cat.name.toLowerCase();
    for (final entry in _defaultCategoryImages.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?w=500&q=80';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return categoriesAsync.when(
      loading: () => Column(
        children: const [
          ShimmerBox(width: double.infinity, height: 86, radius: 16),
          SizedBox(height: 12),
          ShimmerBox(width: double.infinity, height: 86, radius: 16),
        ],
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            final cols = Responsive.categoryColumns(context);
            if (cols == 1) {
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _buildCategoryTile(context, ref, categories[i], isDark),
              );
            }
            const spacing = 12.0;
            final itemWidth = (constraints.maxWidth - (spacing * (cols - 1))) / cols;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final cat in categories)
                  SizedBox(
                    width: itemWidth,
                    child: _buildCategoryTile(context, ref, cat, isDark),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryTile(BuildContext context, WidgetRef ref, Category cat, bool isDark) {
    final imgUrl = _getCategoryImageUrl(cat);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        ref.read(catalogFilterProvider.notifier).update(
              CatalogFilter(categoryId: cat.id),
            );
        GoRouter.of(context).go('/catalog');
      },
      child: Container(
            height: 86,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1E26) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
                width: 1.2,
              ),
              boxShadow: AppShadows.elevated(isDark),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                // Component image on left
                SizedBox(
                  width: 110,
                  height: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: imgUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const ShimmerBox(radius: 0),
                    errorWidget: (_, _, _) => const Icon(LucideIcons.wrench, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                // Category Name on right
                Expanded(
                  child: Text(
                    cat.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ),
                const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
                const SizedBox(width: 14),
              ],
            ),
          ),
        );
  }
}
