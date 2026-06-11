import 'api_client.dart';

class AdminService {
  // ── Supplier Applications ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getSupplierApplications({
    int page = 1,
    String? status,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      if (status != null) 'status': status,
    };
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return ApiClient.get('/suppliers?$qs');
  }

  static Future<Map<String, dynamic>> updateSupplierStatus(
    String supplierId,
    String status, {
    String? reason,
  }) async {
    final res = await ApiClient.patch('/suppliers/$supplierId/status', {
      'status': status,
      if (reason != null) 'reason': reason,
    });
    return res['data'] as Map<String, dynamic>;
  }

  // ── Supplier Performance ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getSupplierPerformance({
    int page = 1,
    int limit = 24,
  }) async {
    return ApiClient.get('/admin/supplier-performance?page=$page&limit=$limit');
  }

  // ── Supplier Risk Scores ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getSupplierRiskScores({
    int page = 1,
    String? riskLevel,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      if (riskLevel != null) 'risk_level': riskLevel,
    };
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return ApiClient.get('/admin/supplier-risk?$qs');
  }

  static Future<Map<String, dynamic>> recomputeRiskScore(
      String supplierId) async {
    final res =
        await ApiClient.post('/admin/supplier-risk/$supplierId/recompute', {});
    return res['data'] as Map<String, dynamic>;
  }

  // ── Product Management ─────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getProducts({
    int page = 1,
    String? supplierId,
    String? status,
    String? search,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      if (supplierId != null) 'supplier_id': supplierId,
      if (status != null) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return ApiClient.get('/products?$qs');
  }

  static Future<Map<String, dynamic>> updateProductStatus(
    String productId, {
    required bool isActive,
  }) async {
    final res = await ApiClient.patch('/products/$productId', {
      'is_active': isActive,
    });
    return res['data'] as Map<String, dynamic>;
  }
}
