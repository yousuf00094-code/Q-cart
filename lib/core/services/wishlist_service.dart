import 'api_client.dart';

class WishlistService {
  static Future<List<Map<String, dynamic>>> getWishlist() async {
    final res = await ApiClient.get('/wishlist');
    final data = res['data'] as List<dynamic>? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  static Future<void> addItem(String productId) async {
    await ApiClient.post('/wishlist', {'product_id': productId});
  }

  static Future<void> removeItem(String productId) async {
    await ApiClient.delete('/wishlist/$productId');
  }
}
