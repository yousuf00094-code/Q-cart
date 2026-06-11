import 'api_client.dart';

class CustomerService {
  // ── Products ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 20,
    String? categoryId,
    String? search,
    double? minPrice,
    double? maxPrice,
    String sort = 'newest',
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'sort': sort,
      if (categoryId != null) 'category_id': categoryId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
    };
    final qs = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return ApiClient.get('/products?$qs');
  }

  static Future<Map<String, dynamic>> getProduct(String id) async {
    return ApiClient.get('/products/$id');
  }

  static Future<Map<String, dynamic>> getProductReviews(String productId, {int page = 1}) async {
    return ApiClient.get('/products/$productId/reviews?page=$page');
  }

  static Future<void> addReview(String productId, int rating, String comment) async {
    await ApiClient.post('/products/$productId/reviews', {'rating': rating, 'comment': comment});
  }

  // ── Categories ────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getCategories() async {
    final res = await ApiClient.get('/categories');
    final data = res['data'] as List<dynamic>? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // ── Addresses ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAddresses() async {
    final res = await ApiClient.get('/addresses');
    final data = res['data'] as List<dynamic>? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createAddress(Map<String, dynamic> data) async {
    final res = await ApiClient.post('/addresses', data);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> deleteAddress(String id) async {
    await ApiClient.delete('/addresses/$id');
  }

  static Future<void> setDefaultAddress(String id) async {
    await ApiClient.patch('/addresses/$id/default', {});
  }

  // ── Orders ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> placeOrder({
    required String addressId,
    required String paymentMethod,
    String? couponCode,
  }) async {
    final body = <String, dynamic>{
      'address_id': addressId,
      'payment_method': paymentMethod,
      if (couponCode != null && couponCode.isNotEmpty) 'coupon_code': couponCode,
    };
    final res = await ApiClient.post('/orders/checkout', body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getOrders({int page = 1, String? status}) async {
    final qs = 'page=$page${status != null ? '&status=${Uri.encodeComponent(status)}' : ''}';
    return ApiClient.get('/orders?$qs');
  }

  static Future<Map<String, dynamic>> getOrder(String id) async {
    return ApiClient.get('/orders/$id');
  }

  static Future<void> cancelOrder(String id) async {
    await ApiClient.post('/orders/$id/cancel', {});
  }

  // ── User Profile ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getUserProfile() async {
    final res = await ApiClient.get('/users/me');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final res = await ApiClient.patch('/users/me', data);
    return res['data'] as Map<String, dynamic>;
  }
}
