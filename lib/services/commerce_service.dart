import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class CommerceException implements Exception {
  const CommerceException(this.code);
  final String code;
  @override
  String toString() => code;
}

class CommerceService {
  CommerceService(this.client);
  final SupabaseClient client;

  Future<Map<String, dynamic>> call(String action, Map<String, dynamic> body) async {
    try {
      final response = await client.functions.invoke('commerce', body: {'action': action, ...body});
      final data = Map<String, dynamic>.from(response.data as Map);
      if (data['error'] != null) throw CommerceException(data['error'].toString());
      return data;
    } on FunctionException catch (error) {
      final details = error.details;
      throw CommerceException(details is Map ? '${details['error'] ?? 'SERVICE_UNAVAILABLE'}' : 'SERVICE_UNAVAILABLE');
    }
  }

  Future<List<Map<String, dynamic>>> paymentMethods() => client.from('redlight_payment_methods').select().order('sort_order');

  Future<String> uploadLogo(Uint8List bytes, String extension) async {
    final ext = extension.toLowerCase().replaceAll('jpg', 'jpeg');
    if (!['png', 'jpeg', 'webp'].contains(ext) || bytes.length > 2 * 1024 * 1024) {
      throw const CommerceException('INVALID_IMAGE');
    }
    final path = '${const Uuid().v4()}.$ext';
    await client.storage.from('redlight-payment-logos').uploadBinary(path, bytes, fileOptions: FileOptions(contentType: 'image/$ext'));
    return client.storage.from('redlight-payment-logos').getPublicUrl(path);
  }
}
