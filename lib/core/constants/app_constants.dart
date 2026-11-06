import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Konstan global yo.
abstract final class AppConstants {
  static const appName = 'Redlight Autoparts';
  static const poweredBy = 'Powered by Cvisual';
  static const currency = 'HTG';
  static const storageBucket = 'redlight-product-images';

  /// Mòd peman yo soti nan tab `redlight_payment_methods` (admin ka aktive/dezaktive).
  /// Label yo tradui nan app_strings.dart ak account_strings.dart (`payment_<code>`).
  static const orderStatuses = <String>[
    'pending',
    'confirmed',
    'shipped',
    'delivered',
    'cancelled',
  ];

  static Color orderStatusColor(String status) => switch (status) {
    'pending' => AppColors.warning,
    'confirmed' => AppColors.info,
    'shipped' => AppColors.violet,
    'delivered' => AppColors.success,
    'cancelled' => AppColors.red,
    _ => AppColors.textMutedDark,
  };
}
