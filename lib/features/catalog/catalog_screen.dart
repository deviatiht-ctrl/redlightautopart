import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/icon_mapper.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/locale_provider.dart';

/// Dènye rechèch yo (persiste lokalman).
class RecentSearchesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => ref.watch(localStoreProvider).recentSearches;

  Future<void> add(String query) async {
    await ref.read(localStoreProvider).addRecentSearch(query);
    ref.invalidateSelf();
  }

  Future<void> clear() async {
    await ref.read(localStoreProvider).clearRecentSearches();
    ref.invalidateSelf();
  }
}

final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(
      RecentSearchesNotifier.new,
    );

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(catalogFilterProvider).query;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref
          .read(catalogFilterProvider.notifier)
          .update(ref.read(catalogFilterProvider).copyWith(query: value));
    });
  }

  void _commitSearch(String value) {
    if (value.trim().isNotEmpty) {
      ref.read(recentSearchesProvider.notifier).add(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(catalogFilterProvider);
    final categories = ref.watch(categoriesProvider);
    final products = ref.watch(filteredProductsProvider);
    final recentSearches = ref.watch(recentSearchesProvider);
    final s = ref.watch(stringsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasActiveFilter = filter.brand != null ||
        filter.minPrice != null ||
        filter.maxPrice != null ||
        filter.sort != 'newest';

    final cols = Responsive.productGridColumns(context);
    final isWide = cols > 2;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: Responsive.maxContentWidth,
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1B1E26) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
                              width: 1.2,
                            ),
                            boxShadow: AppShadows.subtle(isDark),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            onSubmitted: _commitSearch,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: s.t('search_hint'),
                              prefixIcon: const Icon(LucideIcons.search, size: 20),
                              suffixIcon: filter.query.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(LucideIcons.x, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged('');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _openFilterSheet(context, ref, filter),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1B1E26) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
                              width: 1.2,
                            ),
                            boxShadow: AppShadows.subtle(isDark),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                LucideIcons.slidersHorizontal,
                                size: 20,
                                color: isDark ? Colors.white : const Color(0xFF1F2937),
                              ),
                              if (hasActiveFilter)
                                Positioned(
                                  top: 10,
                                  right: 10,
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
                  const SizedBox(height: 12),
                  // Chips kategori
                  categories.maybeWhen(
                    data: (cats) => SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: cats.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            return ChoiceChip(
                              label: Text(s.t('all')),
                              selected: filter.categoryId == null,
                              onSelected: (_) => ref
                                  .read(catalogFilterProvider.notifier)
                                  .update(
                                    filter.copyWith(categoryId: null),
                                  ),
                            );
                          }
                          final cat = cats[i - 1];
                          return ChoiceChip(
                            avatar: Icon(
                              lucideIcon(cat.icon),
                              size: 16,
                              color: filter.categoryId == cat.id
                                  ? AppColors.white
                                  : AppColors.red,
                            ),
                            label: Text(cat.name),
                            selected: filter.categoryId == cat.id,
                            onSelected: (selected) => ref
                                .read(catalogFilterProvider.notifier)
                                .update(
                                  filter.copyWith(
                                    categoryId: selected ? cat.id : null,
                                  ),
                                ),
                          );
                        },
                      ),
                    ),
                    orElse: () => const SizedBox(height: 40),
                  ),
                  if (filter.query.isEmpty && recentSearches.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.clock,
                            size: 14,
                            color: AppColors.textMutedDark,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final q in recentSearches.take(5))
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ActionChip(
                                        label: Text(q),
                                        onPressed: () {
                                          _searchController.text = q;
                                          _onSearchChanged(q);
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: products.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ProductGridShimmer(),
                ),
                error: (_, _) => EmptyState(
                  icon: LucideIcons.alertCircle,
                  title: s.t('products_load_error'),
                  subtitle: s.t('connection_error'),
                  actionLabel: s.t('retry'),
                  onAction: () => ref.invalidate(filteredProductsProvider),
                ),
                data: (products) => products.isEmpty
                    ? EmptyState(
                        icon: LucideIcons.searchX,
                        title: s.t('no_results'),
                        subtitle: s.t('no_results_sub'),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
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

  void _openFilterSheet(
    BuildContext context,
    WidgetRef ref,
    CatalogFilter filter,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(current: filter),
    );
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.current});

  final CatalogFilter current;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late String _sort;
  String? _brand;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  static const _sortOptions = [
    ('newest', 'sort_newest'),
    ('price_asc', 'sort_price_asc'),
    ('price_desc', 'sort_price_desc'),
    ('name_asc', 'sort_name_asc'),
  ];

  @override
  void initState() {
    super.initState();
    _sort = widget.current.sort;
    _brand = widget.current.brand;
    _minController = TextEditingController(
      text: widget.current.minPrice?.toStringAsFixed(0) ?? '',
    );
    _maxController = TextEditingController(
      text: widget.current.maxPrice?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _apply() {
    final notifier = ref.read(catalogFilterProvider.notifier);
    notifier.update(
      widget.current.copyWith(
        sort: _sort,
        brand: _brand,
        minPrice: double.tryParse(_minController.text),
        maxPrice: double.tryParse(_maxController.text),
      ),
    );
    Navigator.of(context).pop();
  }

  void _reset() {
    ref.read(catalogFilterProvider.notifier).reset();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final brands = ref.watch(brandsProvider);
    final s = ref.watch(stringsProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              s.t('filters'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              s.t('sort_by'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textMutedDark,
              ),
            ),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _sort,
              onChanged: (v) => setState(() => _sort = v ?? _sort),
              child: Column(
                children: [
                  for (final (value, labelKey) in _sortOptions)
                    RadioListTile<String>(
                      value: value,
                      title: Text(s.t(labelKey)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.t('car_brand'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textMutedDark,
              ),
            ),
            const SizedBox(height: 8),
            brands.maybeWhen(
              data: (list) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final b in list)
                    ChoiceChip(
                      label: Text(b),
                      selected: _brand == b,
                      onSelected: (selected) =>
                          setState(() => _brand = selected ? b : null),
                    ),
                ],
              ),
              orElse: () => const ShimmerBox(height: 40),
            ),
            const SizedBox(height: 16),
            Text(
              s.t('price_htg'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textMutedDark,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(hintText: s.t('min')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(hintText: s.t('max')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    child: Text(s.t('reset')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _apply,
                    child: Text(s.t('apply')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
