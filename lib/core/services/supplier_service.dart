import 'api_client.dart';

class SupplierService {
  // ── Analytics ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDashboard() async {
    final res = await ApiClient.get('/supplier/analytics');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getDailyRevenue({int days = 30}) async {
    final res = await ApiClient.get('/supplier/analytics/revenue?days=$days');
    return res['data'] as List<dynamic>;
  }

  static Future<List<dynamic>> getTopProducts({int limit = 10}) async {
    final res = await ApiClient.get('/supplier/analytics/top-products?limit=$limit');
    return res['data'] as List<dynamic>;
  }

  static Future<List<dynamic>> getOrderStatusBreakdown() async {
    final res = await ApiClient.get('/supplier/analytics');
    // breakdown comes from a separate call on the analytics endpoint
    // fall back to empty list if not present
    final data = res['data'] as Map<String, dynamic>? ?? {};
    final breakdown = data['order_status_breakdown'];
    return breakdown is List ? breakdown : <dynamic>[];
  }

  // ── Ratings ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getRatings({
    int page = 1,
    int? rating,
    String? productId,
    bool? replied,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      if (rating != null) 'rating': rating.toString(),
      if (productId != null) 'product_id': productId,
      if (replied != null) 'replied': replied.toString(),
    };
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return ApiClient.get('/supplier/ratings?$qs');
  }

  static Future<Map<String, dynamic>> getRatingsSummary() async {
    final res = await ApiClient.get('/supplier/ratings/summary');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> replyToReview(String reviewId, String reply) async {
    await ApiClient.post('/supplier/ratings/$reviewId/reply', {'reply': reply});
  }

  // ── Payouts ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getPayouts({
    int page = 1,
    String? status,
  }) async {
    final qs =
        'page=$page${status != null ? '&status=${Uri.encodeComponent(status)}' : ''}';
    return ApiClient.get('/supplier/payouts?$qs');
  }

  static Future<Map<String, dynamic>> getPayout(String id) async {
    final res = await ApiClient.get('/supplier/payouts/$id');
    return res['data'] as Map<String, dynamic>;
  }

  // ── Shipments ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getShipments({
    int page = 1,
    String? status,
  }) async {
    final qs =
        'page=$page${status != null ? '&status=${Uri.encodeComponent(status)}' : ''}';
    return ApiClient.get('/supplier/shipments?$qs');
  }

  static Future<Map<String, dynamic>> getShipment(String id) async {
    final res = await ApiClient.get('/supplier/shipments/$id');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createShipment(
      Map<String, dynamic> data) async {
    final res = await ApiClient.post('/supplier/shipments', data);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateShipment(
    String id,
    Map<String, dynamic> data,
  ) async {
    final res = await ApiClient.patch('/supplier/shipments/$id', data);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> addShipmentEvent(
    String shipmentId,
    Map<String, dynamic> event,
  ) async {
    await ApiClient.post('/supplier/shipments/$shipmentId/events', event);
  }

  // ── Products ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getProducts({
    int page = 1,
    String? status,
    String? search,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      if (status != null) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return ApiClient.get('/supplier/products?$qs');
  }

  static Future<Map<String, dynamic>> submitProduct(
      Map<String, dynamic> data) async {
    final res = await ApiClient.post('/products', data);
    return res['data'] as Map<String, dynamic>;
  }

  // ── Orders ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getOrders({
    int page = 1,
    String? status,
    String? search,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      if (status != null) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return ApiClient.get('/supplier/orders?$qs');
  }

  // ── Inventory ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getInventory({
    int page = 1,
    bool? lowStock,
    String? search,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      if (lowStock == true) 'low_stock': 'true',
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return ApiClient.get('/supplier/inventory?$qs');
  }

  static Future<void> adjustInventory(
      String productId, int delta, String reason) async {
    await ApiClient.post('/supplier/inventory/$productId/adjust', {
      'quantity_delta': delta,
      'notes': reason,
    });
  }

  static Future<Map<String, dynamic>> updateOrderStatus(
      String orderId, String status) async {
    final res = await ApiClient.patch('/supplier/orders/$orderId/status', {
      'status': status,
    });
    return res['data'] as Map<String, dynamic>;
  }

  // ── Categories (for product submission) ──────────────────────────────────

  static Future<List<Map<String, dynamic>>> getCategories() async {
    final res = await ApiClient.get('/categories');
    final data = res['data'] as List<dynamic>? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> submitProduct(
      Map<String, dynamic> data) async {
    final res = await ApiClient.post('/supplier/products', data);
    return res['data'] as Map<String, dynamic>;
  }
}
