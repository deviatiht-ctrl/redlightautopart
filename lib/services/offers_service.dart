import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../models/today_offer.dart';

class OffersService {
  OffersService(this._client, this._prefs);

  final SupabaseClient _client;
  final SharedPreferences _prefs;

  static const _kOffersCache = 'redlight_today_offers_cache';

  static final List<TodayOffer> _defaultOffers = [
    TodayOffer(
      id: 'offer-winter-tyres',
      title: 'Get your tyres winter-ready today',
      subtitle: 'Freeze warning ahead',
      imageUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=1200&q=80',
      buttonText: 'SHOP NOW',
      buttonAlignmentX: -0.72,
      buttonAlignmentY: 0.65,
      buttonColor: '#FF5000',
      buttonTextColor: '#FFFFFF',
      isActive: true,
      sortOrder: 1,
    ),
    TodayOffer(
      id: 'offer-brake-systems',
      title: 'High Performance Brake Systems',
      subtitle: 'Up to 25% OFF this week',
      imageUrl: 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?w=1200&q=80',
      buttonText: 'SHOP NOW',
      buttonAlignmentX: -0.72,
      buttonAlignmentY: 0.65,
      buttonColor: '#E10600',
      buttonTextColor: '#FFFFFF',
      isActive: true,
      sortOrder: 2,
    ),
  ];

  Future<List<TodayOffer>> fetchOffers({bool onlyActive = true}) async {
    try {
      var query = _client.from('redlight_today_offers').select();
      if (onlyActive) {
        query = query.eq('is_active', true);
      }
      final data = await query.order('sort_order').order('created_at', ascending: false);
      final list = (data as List).map((e) => TodayOffer.fromJson(e as Map<String, dynamic>)).toList();
      if (list.isNotEmpty) {
        await _saveToLocal(list);
        return list;
      }
    } catch (_) {
      // Fallback sou cache lokal si table pa egziste oswa offline
    }

    // Li nan cache lokal
    final cached = _getFromLocal();
    if (cached.isNotEmpty) {
      return onlyActive ? cached.where((o) => o.isActive).toList() : cached;
    }

    // Done pa defo
    return onlyActive ? _defaultOffers.where((o) => o.isActive).toList() : _defaultOffers;
  }

  Future<TodayOffer> saveOffer(TodayOffer offer) async {
    TodayOffer saved = offer;
    try {
      final payload = offer.toJson();
      if (payload['id'] != null && payload['id'].toString().startsWith('offer-')) {
        // Nouvo ID si se te yon ID tanporè
        payload.remove('id');
      }
      final res = await _client
          .from('redlight_today_offers')
          .upsert(payload)
          .select()
          .single();
      saved = TodayOffer.fromJson(res);
    } catch (_) {
      // Si Supabase echwe, nou konsève lokalman
    }

    final current = _getFromLocal().isEmpty ? [..._defaultOffers] : _getFromLocal();
    final index = current.indexWhere((e) => e.id == offer.id);
    if (index >= 0) {
      current[index] = saved;
    } else {
      current.insert(0, saved);
    }
    await _saveToLocal(current);
    return saved;
  }

  Future<void> deleteOffer(String id) async {
    try {
      await _client.from('redlight_today_offers').delete().eq('id', id);
    } catch (_) {}

    final current = _getFromLocal().isEmpty ? [..._defaultOffers] : _getFromLocal();
    current.removeWhere((e) => e.id == id);
    await _saveToLocal(current);
  }

  Future<String> uploadBannerImage(Uint8List bytes, String extension) async {
    final ext = extension.toLowerCase().replaceAll('jpg', 'jpeg');
    final path = 'offers/${DateTime.now().millisecondsSinceEpoch}_${bytes.length}.$ext';
    await _client.storage
        .from(AppConstants.storageBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$ext',
            upsert: true,
          ),
        );
    return _client.storage.from(AppConstants.storageBucket).getPublicUrl(path);
  }

  List<TodayOffer> _getFromLocal() {
    final raw = _prefs.getString(_kOffersCache);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => TodayOffer.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _saveToLocal(List<TodayOffer> list) async {
    final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
    await _prefs.setString(_kOffersCache, encoded);
  }
}
