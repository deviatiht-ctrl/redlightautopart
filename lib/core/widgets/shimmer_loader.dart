import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/colors.dart';
import '../utils/responsive.dart';

/// Bwòs shimmer — tout loading state nan app la pase pa la.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.radius = 12,
    this.margin,
  });

  final double? width;
  final double? height;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: Shimmer.fromColors(
        baseColor: isDark ? AppColors.surfaceDark : AppColors.borderLight,
        highlightColor: isDark ? AppColors.borderDark : AppColors.white,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }
}

/// Shimmer pou grid pwodwi (katalòg / home).
class ProductGridShimmer extends StatelessWidget {
  const ProductGridShimmer({super.key, this.itemCount = 6, this.crossAxisCount});

  final int itemCount;
  final int? crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final cols = crossAxisCount ?? Responsive.productGridColumns(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.66,
      ),
      itemCount: itemCount,
      itemBuilder: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Expanded(child: ShimmerBox(width: double.infinity)),
          SizedBox(height: 8),
          ShimmerBox(height: 14, width: 120),
          SizedBox(height: 6),
          ShimmerBox(height: 14, width: 70),
        ],
      ),
    );
  }
}

/// Shimmer pou lis orizontal (home "Pi popilè").
class HorizontalCardShimmer extends StatelessWidget {
  const HorizontalCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 235,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => const SizedBox(
          width: 170,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: ShimmerBox(width: double.infinity)),
              SizedBox(height: 8),
              ShimmerBox(height: 14, width: 120),
              SizedBox(height: 6),
              ShimmerBox(height: 14, width: 70),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer pou lis siple (kòmand, admin tablo).
class ListShimmer extends StatelessWidget {
  const ListShimmer({super.key, this.itemCount = 5, this.itemHeight = 76});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < itemCount; i++)
          ShimmerBox(
            height: itemHeight,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
          ),
      ],
    );
  }
}
