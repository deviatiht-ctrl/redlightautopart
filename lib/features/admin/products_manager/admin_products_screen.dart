import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/utils/format.dart';
import '../../../models/product.dart';
import '../../../providers/admin_providers.dart';
import '../../../providers/catalog_providers.dart';
import '../../../providers/core_providers.dart';
import '../../../providers/locale_provider.dart';
import 'product_form_dialog.dart';

class AdminProductsScreen extends ConsumerWidget {
  const AdminProductsScreen({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, Product p) async {
    final s = ref.read(stringsProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.t('delete_product_q')),
        content: Text(s.t('delete_product_warn', {'name': p.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.t('no')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.t('yes_delete'),
              style: const TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(productServiceProvider).deleteProduct(p.id);
      ref.invalidate(adminProductsProvider);
      ref.invalidate(filteredProductsProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.t('delete_product_failed'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(adminProductsProvider);
    final s = ref.watch(stringsProvider);
    final hPadding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  s.t('products'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const ProductFormDialog(),
                  ),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: Text(s.t('add_product')),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: products.when(
                loading: () => const ListShimmer(itemCount: 6),
                error: (_, _) => EmptyState(
                  icon: LucideIcons.alertCircle,
                  title: s.t('products_load_error'),
                  actionLabel: s.t('retry'),
                  onAction: () => ref.invalidate(adminProductsProvider),
                ),
                data: (list) => list.isEmpty
                    ? EmptyState(
                        icon: LucideIcons.package,
                        title: s.t('no_products'),
                        subtitle: s.t('no_products_sub'),
                      )
                    : Card(
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: MediaQuery.sizeOf(context).width - (hPadding * 2) - 32,
                              ),
                              child: DataTable(
                                columns: [
                                  DataColumn(label: Text(s.t('products'))),
                                  DataColumn(label: Text(s.t('category'))),
                                  DataColumn(label: Text(s.t('price'))),
                                  DataColumn(label: Text(s.t('stock'))),
                                  DataColumn(label: Text(s.t('actions'))),
                                ],
                                rows: [
                                  for (final p in list)
                                    DataRow(
                                      cells: [
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: SizedBox(
                                                  width: 40,
                                                  height: 40,
                                                  child: p.imageUrl != null
                                                      ? CachedNetworkImage(
                                                          imageUrl: p.imageUrl!,
                                                          fit: BoxFit.cover,
                                                          errorWidget: (_, _, _) => _fallback(),
                                                        )
                                                      : _fallback(),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              ConstrainedBox(
                                                constraints: const BoxConstraints(maxWidth: 240),
                                                child: Text(
                                                  p.name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                              if (p.isDemo)
                                                Container(
                                                  margin: const EdgeInsets.only(left: 8),
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.warning.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(999),
                                                  ),
                                                  child: Text(
                                                    s.t('demo_product'),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.warning,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        DataCell(Text(p.categoryName ?? '—')),
                                        DataCell(Text(formatPrice(p.price))),
                                        DataCell(Text('${p.stock}')),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(LucideIcons.pencil, size: 18),
                                                tooltip: s.t('edit'),
                                                onPressed: () => showDialog(
                                                  context: context,
                                                  builder: (_) => ProductFormDialog(product: p),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.red),
                                                tooltip: s.t('delete'),
                                                onPressed: () => _delete(context, ref, p),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
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

  Widget _fallback() => Container(
        color: AppColors.borderLight,
        child: const Icon(LucideIcons.package, size: 20, color: AppColors.textMutedLight),
      );
}
