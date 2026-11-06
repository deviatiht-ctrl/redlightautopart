import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/commerce_service.dart';
import 'core_providers.dart';

final commerceServiceProvider = Provider<CommerceService>((ref) => CommerceService(ref.watch(supabaseClientProvider)));
final paymentMethodsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) => ref.watch(commerceServiceProvider).paymentMethods());
final withdrawalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  ref.watch(currentUserProvider);
  return ref.watch(supabaseClientProvider).from('redlight_merchant_withdrawals').select().order('created_at', ascending: false).limit(50);
});
