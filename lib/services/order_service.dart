import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_order.dart';
import '../models/cart_item.dart';
import '../models/order_tracking.dart';

/// Sèvis kòmand — placeOrder pase pa fonksyon SQL `place_order`
/// (atomik: order + items + degrese stock nan yon sèl tranzaksyon).
class OrderService {
  OrderService(this._client);

  final SupabaseClient _client;

  static const _selectWithItems =
      '*, redlight_order_items(*, redlight_products(name, images))';

  Future<String> placeOrder({
    required List<CartItem> items,
    required String checkoutKey,
    required String deliveryAddress,
    required String paymentMethod,
  }) async {
    final payload = items
        .map(
          (e) => {
            'product_id': e.product.id,
            'quantity': e.quantity,
          },
        )
        .toList();

    final orderId = await _client.rpc(
      'redlight_checkout_order',
      params: {
        'p_items': payload,
        'p_checkout_key': checkoutKey,
        'p_delivery_address': deliveryAddress,
        'p_payment_method': paymentMethod,
      },
    );
    return orderId as String;
  }

  Future<List<AppOrder>> fetchMyOrders() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    final data = await _client
        .from('redlight_orders')
        .select(_selectWithItems)
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return data.map((e) => AppOrder.fromJson(e)).toList();
  }

  /// Admin: tout kòmand.
  Future<List<AppOrder>> fetchAllOrders() async {
    final data = await _client
        .from('redlight_orders')
        .select(_selectWithItems)
        .order('created_at', ascending: false);
    return data.map((e) => AppOrder.fromJson(e)).toList();
  }

  /// Kliyan: kansèle yon kòmand "pending" (RLS la verifye sa).
  Future<void> cancelOrder(String orderId) => updateStatus(orderId, 'cancelled');

  /// Admin: chanje estati nenpòt kòmand.
  Future<void> updateStatus(String orderId, String status) async {
    await _client.rpc('redlight_change_order_status', params: {'p_order_id': orderId, 'p_status': status});
  }

  /// Pozisyon kounye a + istorik etap yo pou yon kòmand.
  /// RLS: kliyan an wè kòmand li a sèlman; admin wè tout.
  Future<OrderTrackingInfo> fetchTracking(String orderId) async {
    final row = await _client
        .from('redlight_order_tracking')
        .select()
        .eq('order_id', orderId)
        .maybeSingle();
    final events = await _client
        .from('redlight_order_tracking_events')
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: false);
    return OrderTrackingInfo(
      tracking: row == null ? null : OrderTracking.fromJson(row),
      events: events.map((e) => TrackingEvent.fromJson(e)).toList(),
    );
  }

  /// Admin: mete pozisyon/ETA/anprevu ajou (upsert sou order_id).
  Future<void> upsertTracking(
    String orderId, {
    String? location,
    double? latitude,
    double? longitude,
    DateTime? etaAt,
    String? delayNote,
  }) async {
    final note = delayNote?.trim();
    await _client.from('redlight_order_tracking').upsert({
      'order_id': orderId,
      'location': location?.trim().isEmpty ?? true ? null : location!.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'eta_at': etaAt?.toIso8601String(),
      'delay_note': note == null || note.isEmpty ? null : note,
      'updated_by': _client.auth.currentUser?.id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Admin: ajoute yon etap nan istorik la (checkpoint oswa 'delay').
  Future<void> addTrackingEvent(
    String orderId, {
    String kind = 'checkpoint',
    String? location,
    String? note,
    double? latitude,
    double? longitude,
  }) async {
    final loc = location?.trim();
    final n = note?.trim();
    await _client.from('redlight_order_tracking_events').insert({
      'order_id': orderId,
      'kind': kind,
      'location': loc == null || loc.isEmpty ? null : loc,
      'note': n == null || n.isEmpty ? null : n,
      'latitude': latitude,
      'longitude': longitude,
      'created_by': _client.auth.currentUser?.id,
    });
  }
}
