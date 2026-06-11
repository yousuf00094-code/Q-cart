import 'api_client.dart';

class CartService {
  static Future<Map<String, dynamic>> getCart() async {
    return ApiClient.get('/cart');
  }

  static Future<void> addItem(String productId, int quantity) async {
    await ApiClient.post('/cart/items', {'product_id': productId, 'quantity': quantity});
  }

  static Future<void> updateItem(String itemId, int quantity) async {
    await ApiClient.patch('/cart/items/$itemId', {'quantity': quantity});
  }

  static Future<void> removeItem(String itemId) async {
    await ApiClient.delete('/cart/items/$itemId');
  }

  static Future<void> clearCart() async {
    await ApiClient.delete('/cart');
  }

  static Future<Map<String, dynamic>?> validateCoupon(String code) async {
    try {
      final res = await ApiClient.post('/coupons/validate', {'code': code});
      return res['data'] as Map<String, dynamic>?;
    } on ApiException catch (e) {
      if (e.statusCode == 422 || e.statusCode == 404) return null;
      rethrow;
    }
  }
}
