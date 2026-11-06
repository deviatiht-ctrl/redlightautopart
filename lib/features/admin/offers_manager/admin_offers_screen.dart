import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../models/today_offer.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/offers_provider.dart';
import 'offer_form_dialog.dart';

class AdminOffersScreen extends ConsumerWidget {
  const AdminOffersScreen({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, TodayOffer offer) async {
    final s = ref.read(stringsProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.t('delete_offer_q')),
        content: Text(s.t('delete_offer_warn')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.t('delete_offer'),
              style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await ref.read(offersServiceProvider).deleteOffer(offer.id);
      ref.invalidate(adminOffersProvider);
      ref.invalidate(todayOffersProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erè pandan sipresyon an.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(adminOffersProvider);
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.t('admin_offers'),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jere bandwòl ak flyers pou paj akèy la (Today\'s Offers)',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const OfferFormDialog(),
                  ),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: Text(s.t('add_offer')),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: offersAsync.when(
                loading: () => const ListShimmer(itemCount: 4),
                error: (e, _) => EmptyState(
                  icon: LucideIcons.alertCircle,
                  title: 'Erè pandan chajman òf yo',
                  subtitle: '$e',
                  actionLabel: s.t('retry'),
                  onAction: () => ref.invalidate(adminOffersProvider),
                ),
                data: (offers) {
                  if (offers.isEmpty) {
                    return EmptyState(
                      icon: LucideIcons.sparkles,
                      title: s.t('no_offers'),
                      subtitle: 'Kreye premye flyer ou pou atire kliyan yo sou paj akèy la.',
                      actionLabel: s.t('add_offer'),
                      onAction: () => showDialog(
                        context: context,
                        builder: (_) => const OfferFormDialog(),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: offers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final offer = offers[index];
                      return LayoutBuilder(
                        builder: (context, cardConstraints) {
                          final isCardMobile = cardConstraints.maxWidth < 620;

                          Widget buildThumbnail({double? width, double? height, double aspectRatio = 2.3}) {
                            final image = Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: offer.imageUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => Container(
                                    color: Colors.grey.shade300,
                                    child: const Icon(LucideIcons.imageOff, color: Colors.grey),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment(offer.buttonAlignmentX, offer.buttonAlignmentY),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade800,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      offer.buttonText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 7,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: width != null && height != null
                                  ? SizedBox(width: width, height: height, child: image)
                                  : AspectRatio(aspectRatio: aspectRatio, child: image),
                            );
                          }

                          if (isCardMobile) {
                            // Layout Mobil: Bannière sou tout lajè a, detay ak aksyon anba
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  buildThumbnail(aspectRatio: 2.2),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          offer.title.isEmpty ? 'Flyer Promo' : offer.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: offer.isActive
                                              ? AppColors.success.withValues(alpha: 0.15)
                                              : Colors.grey.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          offer.isActive ? s.t('active') : s.t('inactive'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: offer.isActive ? AppColors.success : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (offer.subtitle != null && offer.subtitle!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      offer.subtitle!,
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(LucideIcons.mousePointerClick, size: 13, color: Colors.grey.shade500),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Bouton: "${offer.buttonText}"',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(LucideIcons.pencil, size: 18),
                                        tooltip: s.t('edit_offer'),
                                        onPressed: () => showDialog(
                                          context: context,
                                          builder: (_) => OfferFormDialog(offer: offer),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.red),
                                        tooltip: s.t('delete_offer'),
                                        onPressed: () => _delete(context, ref, offer),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.borderLight),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                buildThumbnail(width: 140, height: 80),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            offer.title.isEmpty ? 'Flyer Promo' : offer.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: offer.isActive
                                                  ? AppColors.success.withValues(alpha: 0.15)
                                                  : Colors.grey.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              offer.isActive ? s.t('active') : s.t('inactive'),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: offer.isActive ? AppColors.success : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (offer.subtitle != null && offer.subtitle!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          offer.subtitle!,
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(LucideIcons.mousePointerClick, size: 14, color: Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Bouton: "${offer.buttonText}" (X: ${offer.buttonAlignmentX.toStringAsFixed(1)}, Y: ${offer.buttonAlignmentY.toStringAsFixed(1)})',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                          ),
                                          if (offer.productId != null) ...[
                                            const SizedBox(width: 12),
                                            Icon(LucideIcons.link2, size: 14, color: Colors.grey.shade500),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Produit lié',
                                              style: TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.pencil, size: 18),
                                  tooltip: s.t('edit_offer'),
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (_) => OfferFormDialog(offer: offer),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.red),
                                  tooltip: s.t('delete_offer'),
                                  onPressed: () => _delete(context, ref, offer),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
