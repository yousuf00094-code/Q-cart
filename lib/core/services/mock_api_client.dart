import '../data/mock_data.dart';

class MockApiClient {
  MockApiClient._();

  // ── In-memory state ──────────────────────────────────────────────────────

  static final List<Map<String, dynamic>> _cartItems = [];
  static int _cartItemCounter = 1;

  static final List<Map<String, dynamic>> _wishlistItems = [];
  static int _wishlistItemCounter = 1;

  static final List<Map<String, dynamic>> _orders = [];
  static int _orderCounter = 1;

  static Map<String, dynamic>? _currentUser;

  // ── Router ───────────────────────────────────────────────────────────────

  static Map<String, dynamic> handle(
      String method, String path, Map<String, dynamic>? body) {
    final uri = Uri.parse('http://mock$path');
    final seg = uri.pathSegments;
    final q = uri.queryParameters;

    if (seg.isEmpty) return _notFound(path);

    switch (seg[0]) {
      // ── Products ──────────────────────────────────────────────────────────
      case 'products':
        if (seg.length == 1) return _listProducts(q);
        if (seg.length == 2) return _getProduct(seg[1]);
        if (seg.length == 3 && seg[2] == 'reviews') {
          if (method == 'POST') return _addReview(seg[1], body ?? {});
          return _getReviews(seg[1], q);
        }
        break;

      // ── Categories ────────────────────────────────────────────────────────
      case 'categories':
        return {'data': MockData.categories, 'meta': null};

      // ── Cart ──────────────────────────────────────────────────────────────
      case 'cart':
        if (seg.length == 1) {
          if (method == 'DELETE') return _clearCart();
          return _getCart();
        }
        if (seg.length == 2 && seg[1] == 'items' && method == 'POST') {
          return _addToCart(body ?? {});
        }
        if (seg.length == 3 && seg[1] == 'items') {
          if (method == 'PATCH') return _updateCartItem(seg[2], body ?? {});
          if (method == 'DELETE') return _removeCartItem(seg[2]);
        }
        break;

      // ── Wishlist ──────────────────────────────────────────────────────────
      case 'wishlist':
        if (seg.length == 1) {
          if (method == 'GET') return _getWishlist();
          if (method == 'POST') return _addToWishlist(body ?? {});
        }
        if (seg.length == 2 && method == 'DELETE') {
          return _removeFromWishlist(seg[1]);
        }
        break;

      // ── Coupons ───────────────────────────────────────────────────────────
      case 'coupons':
        if (seg.length == 2 && seg[1] == 'validate') {
          return _validateCoupon(body ?? {});
        }
        break;

      // ── Auth ──────────────────────────────────────────────────────────────
      case 'auth':
        if (seg.length == 2) {
          if (seg[1] == 'login') return _login(body ?? {});
          if (seg[1] == 'logout') return _logout();
          if (seg[1] == 'register') return _register(body ?? {});
          if (seg[1] == 'refresh') return {'data': {'access_token': 'mock_token_refreshed'}};
        }
        break;

      // ── Users ─────────────────────────────────────────────────────────────
      case 'users':
        if (seg.length == 2 && seg[1] == 'me') {
          if (method == 'GET') return _getProfile();
          if (method == 'PATCH') return _updateProfile(body ?? {});
        }
        break;

      // ── Addresses ────────────────────────────────────────────────────────
      case 'addresses':
        if (seg.length == 1) {
          if (method == 'GET') return _getAddresses();
          if (method == 'POST') return _createAddress(body ?? {});
        }
        if (seg.length == 2) {
          if (method == 'PUT') return _updateAddress(seg[1], body ?? {});
          if (method == 'DELETE') return {'data': null};
        }
        if (seg.length == 3 && seg[2] == 'default' && method == 'PATCH') {
          return {'data': null};
        }
        break;

      // ── Orders ────────────────────────────────────────────────────────────
      case 'orders':
        if (seg.length == 1 && method == 'GET') return _getOrders();
        if (seg.length == 2 && seg[1] == 'checkout' && method == 'POST') {
          return _checkout(body ?? {});
        }
        if (seg.length == 2 && method == 'GET') return _getOrder(seg[1]);
        if (seg.length == 3 && seg[2] == 'cancel' && method == 'POST') {
          return {'data': null};
        }
        break;

      // ── Payment ───────────────────────────────────────────────────────────
      case 'payment':
        if (seg.length == 2 && seg[1] == 'initiate') {
          return {
            'data': {
              'invoice_id': 'mock_inv_${DateTime.now().millisecondsSinceEpoch}',
              'amount': 0.0,
              'payment_url': 'https://pay.example.com/mock',
            }
          };
        }
        if (seg.length == 2 && seg[1] == 'verify') {
          return {'data': {'status': 'success', 'order_id': 'mock_order'}};
        }
        if (seg.length == 2 && seg[1] == 'fcm-token') return {'data': null};
        break;
    }

    return _notFound(path);
  }

  // ── Product image generation ─────────────────────────────────────────────

  static String _productImage(String catId, int n, bool flip) {
    return '/img/products/p$n.png';
  }

  static Map<String, dynamic> _withImages(Map<String, dynamic> p) {
    final catId = p['category_id'] as String? ?? 'cat_1';
    final n = int.tryParse((p['id'] as String? ?? 'p1').replaceFirst('p', '')) ?? 1;
    final productForCart = {
      ...p,
      'images': <dynamic>[
        _productImage(catId, n, false),
        _productImage(catId, n, true),
      ],
    };
    return productForCart;
  }

  // ── Products ─────────────────────────────────────────────────────────────

  static Map<String, dynamic> _listProducts(Map<String, String> q) {
    var items = List<Map<String, dynamic>>.from(MockData.products);

    final categoryId = q['category_id'];
    if (categoryId != null && categoryId.isNotEmpty) {
      items = items.where((p) => p['category_id'] == categoryId).toList();
    }

    final search = q['search'];
    if (search != null && search.isNotEmpty) {
      final lower = search.toLowerCase();
      items = items.where((p) {
        final name = (p['name'] as String).toLowerCase();
        final desc = (p['description'] as String).toLowerCase();
        return name.contains(lower) || desc.contains(lower);
      }).toList();
    }

    if (q['featured'] == 'true') {
      items = items.where((p) {
        final tags = p['tags'] as List<dynamic>;
        return tags.contains('featured');
      }).toList();
    }

    if (q['flash_deals'] == 'true') {
      items = items.where((p) => (p['compare_at_price'] as double?) != null).toList();
      items.sort((a, b) {
        final ap = a['price'] as double;
        final ac = a['compare_at_price'] as double;
        final bp = b['price'] as double;
        final bc = b['compare_at_price'] as double;
        final discA = 1 - ap / ac;
        final discB = 1 - bp / bc;
        return discB.compareTo(discA);
      });
    }

    final minPrice = double.tryParse(q['min_price'] ?? '');
    final maxPrice = double.tryParse(q['max_price'] ?? '');
    if (minPrice != null) {
      items = items.where((p) => (p['price'] as double) >= minPrice).toList();
    }
    if (maxPrice != null) {
      items = items.where((p) => (p['price'] as double) <= maxPrice).toList();
    }

    final sort = q['sort'] ?? 'created_at_desc';
    switch (sort) {
      case 'sold_desc':
        items.sort((a, b) {
          final aBS = (a['tags'] as List<dynamic>).contains('best_seller') ? 1 : 0;
          final bBS = (b['tags'] as List<dynamic>).contains('best_seller') ? 1 : 0;
          if (aBS != bBS) return bBS - aBS;
          return (b['review_count'] as int) - (a['review_count'] as int);
        });
        break;
      case 'rating_desc':
        items.sort((a, b) =>
            ((b['average_rating'] as double) - (a['average_rating'] as double))
                .sign
                .toInt());
        break;
      case 'price_asc':
        items.sort((a, b) =>
            ((a['price'] as double) - (b['price'] as double)).sign.toInt());
        break;
      case 'price_desc':
        items.sort((a, b) =>
            ((b['price'] as double) - (a['price'] as double)).sign.toInt());
        break;
      default: // created_at_desc (newest first)
        items.sort((a, b) =>
            (b['created_at'] as String).compareTo(a['created_at'] as String));
    }

    final page = int.tryParse(q['page'] ?? '1') ?? 1;
    final limit = int.tryParse(q['limit'] ?? '20') ?? 20;
    final total = items.length;
    final totalPages = (total / limit).ceil().clamp(1, 999);
    final start = ((page - 1) * limit).clamp(0, total);
    final end = (start + limit).clamp(0, total);
    final pageItems = items.sublist(start, end).map(_withImages).toList();

    return {
      'data': pageItems,
      'meta': {
        'total': total,
        'total_pages': totalPages,
        'page': page,
        'limit': limit,
      }
    };
  }

  static Map<String, dynamic> _getProduct(String id) {
    final product = MockData.findProduct(id);
    if (product == null) {
      return _error(404, 'NOT_FOUND', 'Product not found');
    }
    return {'data': _withImages(product)};
  }

  static Map<String, dynamic> _getReviews(String productId, Map<String, String> q) {
    final reviews = MockData.getReviews(productId);
    return {
      'data': reviews,
      'meta': {'total': reviews.length, 'page': 1},
    };
  }

  static Map<String, dynamic> _addReview(
      String productId, Map<String, dynamic> body) {
    return {'data': null};
  }

  // ── Cart ─────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _getCart() {
    final subtotal = _cartItems.fold<double>(0.0, (sum, item) {
      final product = item['product'] as Map<String, dynamic>;
      return sum +
          (product['price'] as double) * (item['quantity'] as int);
    });
    return {
      'data': {
        'items': _cartItems,
        'subtotal': subtotal,
        'item_count': _cartItems.length,
      }
    };
  }

  static Map<String, dynamic> _addToCart(Map<String, dynamic> body) {
    final productId = body['product_id']?.toString() ?? '';
    final quantity = (body['quantity'] as int?) ?? 1;

    final alreadyIn = _cartItems.any((i) => i['product_id'] == productId);
    if (alreadyIn) {
      return _error(409, 'CONFLICT', 'Item already in cart');
    }

    final product = MockData.findProduct(productId);
    if (product == null) {
      return _error(404, 'NOT_FOUND', 'Product not found');
    }

    final enriched = _withImages(product);
    _cartItems.add({
      'id': 'ci_${_cartItemCounter++}',
      'product_id': productId,
      'quantity': quantity,
      'product': {
        'id': enriched['id'],
        'name': enriched['name'],
        'price': enriched['price'],
        'images': enriched['images'],
        'category_id': enriched['category_id'],
      },
    });

    return {'data': null};
  }

  static Map<String, dynamic> _updateCartItem(
      String itemId, Map<String, dynamic> body) {
    final quantity = body['quantity'] as int? ?? 1;
    final idx = _cartItems.indexWhere((i) => i['id'] == itemId);
    if (idx >= 0) {
      _cartItems[idx] = {..._cartItems[idx], 'quantity': quantity};
    }
    return {'data': null};
  }

  static Map<String, dynamic> _removeCartItem(String itemId) {
    _cartItems.removeWhere((i) => i['id'] == itemId);
    return {'data': null};
  }

  static Map<String, dynamic> _clearCart() {
    _cartItems.clear();
    return {'data': null};
  }

  // ── Wishlist ─────────────────────────────────────────────────────────────

  static Map<String, dynamic> _getWishlist() {
    return {'data': _wishlistItems};
  }

  static Map<String, dynamic> _addToWishlist(Map<String, dynamic> body) {
    final productId = body['product_id']?.toString() ?? '';
    final alreadyIn = _wishlistItems.any((i) => i['product_id'] == productId);
    if (alreadyIn) {
      return _error(409, 'CONFLICT', 'Already in wishlist');
    }
    final product = MockData.findProduct(productId);
    if (product == null) {
      return _error(404, 'NOT_FOUND', 'Product not found');
    }
    final enrichedW = _withImages(product);
    _wishlistItems.add({
      'id': 'wl_${_wishlistItemCounter++}',
      'product_id': productId,
      'product': {
        'id': enrichedW['id'],
        'name': enrichedW['name'],
        'price': enrichedW['price'],
        'images': enrichedW['images'],
        'created_at': enrichedW['created_at'],
      },
    });
    return {'data': null};
  }

  static Map<String, dynamic> _removeFromWishlist(String productId) {
    _wishlistItems.removeWhere((i) => i['product_id'] == productId);
    return {'data': null};
  }

  // ── Coupons ───────────────────────────────────────────────────────────────

  static const _coupons = {
    'SAVE10': 10.0,
    'WELCOME20': 20.0,
    'QCART15': 15.0,
    'DEMO25': 25.0,
  };

  static Map<String, dynamic> _validateCoupon(Map<String, dynamic> body) {
    final code = (body['code'] as String? ?? '').toUpperCase();
    final pct = _coupons[code];
    if (pct == null) {
      return _error(422, 'INVALID_COUPON', 'Coupon code is invalid or expired');
    }
    return {
      'data': {
        'id': 'coupon_$code',
        'code': code,
        'discount_percentage': pct,
        'valid': true,
      }
    };
  }

  // ── Auth ─────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _login(Map<String, dynamic> body) {
    final email = body['email']?.toString() ?? 'demo@qcart.com';
    final name = email.split('@')[0].replaceAll('.', ' ');
    _currentUser = {
      'id': 'mock_user_1',
      'email': email,
      'full_name': _capitalize(name),
      'phone': '+971 50 000 0001',
      'avatar_url': null,
      'role': 'customer',
      'created_at': '2024-01-01T00:00:00Z',
    };
    return {
      'data': {
        'access_token': 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
        'user': _currentUser,
      }
    };
  }

  static Map<String, dynamic> _logout() {
    _currentUser = null;
    return {'data': null};
  }

  static Map<String, dynamic> _register(Map<String, dynamic> body) {
    final email = body['email']?.toString() ?? 'new@qcart.com';
    _currentUser = {
      'id': 'mock_user_new',
      'email': email,
      'full_name': body['full_name']?.toString() ?? 'New User',
      'phone': body['phone']?.toString() ?? '',
      'avatar_url': null,
      'role': 'customer',
      'created_at': DateTime.now().toIso8601String(),
    };
    return {
      'data': {
        'access_token': 'mock_access_token_new',
        'user': _currentUser,
      }
    };
  }

  // ── User Profile ──────────────────────────────────────────────────────────

  static Map<String, dynamic> _getProfile() {
    return {
      'data': _currentUser ?? {
        'id': 'mock_guest',
        'email': 'guest@qcart.com',
        'full_name': 'Guest User',
        'phone': '',
        'avatar_url': null,
        'role': 'customer',
        'created_at': '2024-01-01T00:00:00Z',
      }
    };
  }

  static Map<String, dynamic> _updateProfile(Map<String, dynamic> body) {
    if (_currentUser != null) {
      _currentUser = {..._currentUser!, ...body};
    }
    return _getProfile();
  }

  // ── Addresses ────────────────────────────────────────────────────────────

  static final List<Map<String, dynamic>> _addresses = [
    {
      'id': 'addr_1',
      'label': 'Home',
      'street': '42 Al Wasl Road',
      'city': 'Dubai',
      'state': 'Dubai',
      'postal_code': '12345',
      'country': 'UAE',
      'is_default': true,
    },
    {
      'id': 'addr_2',
      'label': 'Office',
      'street': 'DIFC Gate Building, Level 5',
      'city': 'Dubai',
      'state': 'Dubai',
      'postal_code': '12346',
      'country': 'UAE',
      'is_default': false,
    },
  ];

  static Map<String, dynamic> _getAddresses() {
    return {'data': _addresses};
  }

  static Map<String, dynamic> _createAddress(Map<String, dynamic> body) {
    final newAddr = {
      'id': 'addr_${_addresses.length + 1}',
      ...body,
      'is_default': false,
    };
    _addresses.add(newAddr);
    return {'data': newAddr};
  }

  static Map<String, dynamic> _updateAddress(
      String id, Map<String, dynamic> body) {
    final idx = _addresses.indexWhere((a) => a['id'] == id);
    if (idx >= 0) {
      _addresses[idx] = {..._addresses[idx], ...body};
      return {'data': _addresses[idx]};
    }
    return _error(404, 'NOT_FOUND', 'Address not found');
  }

  // ── Orders ────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _checkout(Map<String, dynamic> body) {
    final orderNumber = 'QC${10000 + _orderCounter}';
    final order = {
      'id': 'order_${_orderCounter++}',
      'order_number': orderNumber,
      'status': 'confirmed',
      'total_amount': _cartItems.fold<double>(0.0, (sum, item) {
        final product = item['product'] as Map<String, dynamic>;
        return sum + (product['price'] as double) * (item['quantity'] as int);
      }),
      'items': List<Map<String, dynamic>>.from(_cartItems),
      'created_at': DateTime.now().toIso8601String(),
    };
    _orders.insert(0, order);
    _cartItems.clear();
    return {'data': order};
  }

  static Map<String, dynamic> _getOrders() {
    return {
      'data': _orders,
      'meta': {'total_pages': 1, 'page': 1, 'total': _orders.length},
    };
  }

  static Map<String, dynamic> _getOrder(String id) {
    try {
      final order = _orders.firstWhere((o) => o['id'] == id);
      return {'data': order};
    } catch (_) {
      return _error(404, 'NOT_FOUND', 'Order not found');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Map<String, dynamic> _error(int status, String code, String msg) {
    return {
      '__mock_error__': true,
      'statusCode': status,
      'code': code,
      'message': msg,
    };
  }

  static Map<String, dynamic> _notFound(String path) {
    return _error(404, 'NOT_FOUND', 'Mock: no handler for $path');
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }
}
