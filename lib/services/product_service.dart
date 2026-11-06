import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../models/category.dart';
import '../models/product.dart';

/// CRUD pwodwi + kategori + upload imaj.
class ProductService {
  ProductService(this._client);

  final SupabaseClient _client;

  // ---------- Kategori ----------

  Future<List<Category>> fetchCategories() async {
    final data = await _client.from('redlight_categories').select().order('name');
    return data.map((e) => Category.fromJson(e)).toList();
  }

  Future<Category> createCategory(String name, String? icon, {String? imageUrl}) async {
    final payload = <String, dynamic>{
      'name': name,
      'icon': icon,
      'image_url': ?imageUrl,
    };
    try {
      final data = await _client
          .from('redlight_categories')
          .insert(payload)
          .select()
          .single();
      return Category.fromJson(data);
    } catch (_) {
      payload.remove('image_url');
      final data = await _client
          .from('redlight_categories')
          .insert(payload)
          .select()
          .single();
      return Category.fromJson({...data, 'image_url': ?imageUrl});
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await _client
          .from('redlight_categories')
          .update(category.toJson())
          .eq('id', category.id);
    } catch (_) {
      final fallbackPayload = {'name': category.name, 'icon': category.icon};
      await _client
          .from('redlight_categories')
          .update(fallbackPayload)
          .eq('id', category.id);
    }
  }

  Future<void> deleteCategory(String id) =>
      _client.from('redlight_categories').delete().eq('id', id);

  /// Upload yon imaj pou kategori nan bucket `product-images`, retounen URL piblik la.
  Future<String> uploadCategoryImage(Uint8List bytes, String extension) async {
    final ext = extension.toLowerCase().replaceAll('jpg', 'jpeg');
    final path = 'categories/${DateTime.now().millisecondsSinceEpoch}_${bytes.length}.$ext';
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

  // ---------- Pwodwi ----------

  Future<List<Product>> fetchProducts({
    String? categoryId,
    String? search,
    double? minPrice,
    double? maxPrice,
    String sort = 'newest',
    int? limit,
  }) async {
    var query = _client.from('redlight_products').select('*, redlight_categories(name)');

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }
    if (search != null && search.trim().isNotEmpty) {
      final term = search.trim().replaceAll(RegExp(r'[%,()]'), ' ');
      query = query.or('name.ilike.%$term%,description.ilike.%$term%');
    }
    if (minPrice != null) query = query.gte('price', minPrice);
    if (maxPrice != null) query = query.lte('price', maxPrice);

    var ordered = switch (sort) {
      'price_asc' => query.order('price'),
      'price_desc' => query.order('price', ascending: false),
      'name_asc' => query.order('name'),
      _ => query.order('created_at', ascending: false),
    };

    final data = await (limit != null ? ordered.limit(limit) : ordered);
    return data.map((e) => Product.fromJson(e)).toList();
  }

  /// Pi popilè = pwodwi ki gen plis vant (kalkile sou order_items reyèl).
  Future<List<Product>> fetchPopular({int limit = 10}) async {
    final data = await _client
        .from('redlight_products')
        .select('*, redlight_categories(name), redlight_order_items(quantity)');
    final products = data.map((e) => Product.fromJson(e)).toList();
    products.sort((a, b) => b.soldCount.compareTo(a.soldCount));
    return products.take(limit).toList();
  }

  Future<Product> fetchProduct(String id) async {
    final data = await _client
        .from('redlight_products')
        .select('*, redlight_categories(name)')
        .eq('id', id)
        .single();
    return Product.fromJson(data);
  }

  Future<List<Product>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final data = await _client
        .from('redlight_products')
        .select('*, redlight_categories(name)')
        .inFilter('id', ids);
    return data.map((e) => Product.fromJson(e)).toList();
  }

  // ---------- Admin ----------

  Future<Product> createProduct(Map<String, dynamic> payload) async {
    final data = await _client
        .from('redlight_products')
        .insert(payload)
        .select('*, redlight_categories(name)')
        .single();
    return Product.fromJson(data);
  }

  Future<Product> updateProduct(String id, Map<String, dynamic> payload) async {
    final data = await _client
        .from('redlight_products')
        .update(payload)
        .eq('id', id)
        .select('*, redlight_categories(name)')
        .single();
    return Product.fromJson(data);
  }

  Future<void> deleteProduct(String id) =>
      _client.from('redlight_products').delete().eq('id', id);

  /// Upload yon imaj nan bucket `product-images`, retounen URL piblik la.
  Future<String> uploadProductImage(Uint8List bytes, String extension) async {
    final ext = extension.toLowerCase().replaceAll('jpg', 'jpeg');
    final path =
        'products/${DateTime.now().millisecondsSinceEpoch}_${bytes.length}.$ext';
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
}
