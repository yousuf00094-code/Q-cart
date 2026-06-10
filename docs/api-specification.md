# Q Cart – REST API Specification

**Base URL:** `https://api.qcart.qa/v1`  
**Format:** JSON  
**Auth:** Bearer JWT (access token, 15 min TTL) + HTTP-only refresh cookie (7 days)  
**Rate limiting:** 100 req/min per IP (unauthenticated), 300 req/min per user

---

## Conventions

- All timestamps are ISO 8601 UTC: `2026-06-10T08:30:00Z`
- Prices are in **QAR**, returned as strings to avoid float precision loss: `"35.00"`
- Pagination uses cursor-based for lists, offset for admin endpoints
- Error responses follow RFC 7807 Problem Details

**Success envelope:**
```json
{ "data": { … }, "meta": { … } }
```

**Error envelope:**
```json
{
  "error": {
    "code": "PRODUCT_NOT_FOUND",
    "message": "Product with id abc123 was not found.",
    "details": {}
  }
}
```

**Common error codes:**

| Code | HTTP | Meaning |
|---|---|---|
| `UNAUTHORIZED` | 401 | Missing or invalid token |
| `FORBIDDEN` | 403 | Token valid but insufficient role |
| `NOT_FOUND` | 404 | Resource does not exist |
| `VALIDATION_ERROR` | 422 | Invalid request body / params |
| `CONFLICT` | 409 | Duplicate resource |
| `RATE_LIMITED` | 429 | Too many requests |

---

## 1. Authentication

### `POST /auth/register`

Create a new customer account.

**Request:**
```json
{
  "full_name": "Yousuf Al-Rashid",
  "email": "yousuf@example.com",
  "phone": "+97455123456",
  "password": "SecurePass1!"
}
```

**Response `201`:**
```json
{
  "data": {
    "user": {
      "id": "uuid",
      "full_name": "Yousuf Al-Rashid",
      "email": "yousuf@example.com",
      "phone": "+97455123456",
      "role": "customer",
      "is_email_verified": false
    },
    "access_token": "eyJ…",
    "expires_in": 900
  }
}
```

---

### `POST /auth/login`

**Request:**
```json
{ "email": "yousuf@example.com", "password": "SecurePass1!" }
```

**Response `200`:**
```json
{
  "data": {
    "user": { "id": "uuid", "full_name": "…", "role": "customer" },
    "access_token": "eyJ…",
    "expires_in": 900
  }
}
```
Sets `Set-Cookie: refresh_token=<token>; HttpOnly; Secure; SameSite=Strict`

---

### `POST /auth/refresh`

Exchange refresh cookie for a new access token.

**Response `200`:**
```json
{ "data": { "access_token": "eyJ…", "expires_in": 900 } }
```

---

### `POST /auth/logout`

Invalidates the refresh token server-side and clears the cookie.

**Response `204`:** No content.

---

### `POST /auth/forgot-password`

**Request:** `{ "email": "yousuf@example.com" }`  
**Response `202`:** Always returns 202 to prevent email enumeration.

---

### `POST /auth/reset-password`

**Request:**
```json
{ "token": "<reset_token>", "password": "NewSecurePass1!" }
```
**Response `200`:** `{ "data": { "message": "Password updated successfully." } }`

---

### `POST /auth/verify-email`

**Request:** `{ "token": "<email_verification_token>" }`  
**Response `200`:** `{ "data": { "message": "Email verified." } }`

---

## 2. Users

> Requires `Authorization: Bearer <token>`

### `GET /users/me`

Returns the authenticated user's profile.

**Response `200`:**
```json
{
  "data": {
    "id": "uuid",
    "full_name": "Yousuf Al-Rashid",
    "email": "yousuf@example.com",
    "phone": "+97455123456",
    "avatar_url": "https://cdn.qcart.qa/avatars/uuid.jpg",
    "role": "customer",
    "is_email_verified": true,
    "loyalty_balance": 240,
    "created_at": "2024-01-15T10:00:00Z"
  }
}
```

---

### `PATCH /users/me`

Update profile fields (name, phone, avatar).

**Request:** `{ "full_name": "Yousuf A.", "phone": "+97455999000" }`  
**Response `200`:** Updated user object.

---

### `PUT /users/me/password`

**Request:**
```json
{ "current_password": "OldPass1!", "new_password": "NewPass2!" }
```
**Response `200`:** `{ "data": { "message": "Password changed." } }`

---

### `POST /users/me/avatar`

Multipart form upload.

**Request:** `Content-Type: multipart/form-data`, field `avatar` (JPEG/PNG ≤ 5 MB)  
**Response `200`:** `{ "data": { "avatar_url": "https://cdn.qcart.qa/…" } }`

---

### Addresses

#### `GET /users/me/addresses`
Returns all saved addresses.

#### `POST /users/me/addresses`

**Request:**
```json
{
  "label": "Home",
  "type": "home",
  "full_name": "Yousuf Al-Rashid",
  "phone": "+97455123456",
  "line1": "Villa 14, Street 22, Al Waab",
  "city": "Doha",
  "area": "Al Waab",
  "country": "Qatar",
  "latitude": 25.263562,
  "longitude": 51.424872,
  "is_default": true
}
```
**Response `201`:** Created address object.

#### `PUT /users/me/addresses/:id`
Full update of an address.

#### `DELETE /users/me/addresses/:id`
**Response `204`**

#### `PATCH /users/me/addresses/:id/default`
Sets address as default; clears previous default.  
**Response `200`:** Updated address.

---

## 3. Categories

### `GET /categories`

Returns root categories with child counts.

**Query params:** `include_inactive=false`

**Response `200`:**
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Groceries",
      "slug": "groceries",
      "image_url": "https://cdn.qcart.qa/categories/groceries.jpg",
      "product_count": 128,
      "children": []
    }
  ]
}
```

---

### `GET /categories/:slug`

Single category with direct children.

---

### `GET /categories/:slug/products`

Paginated products within a category.

**Query params:**

| Param | Type | Default | Description |
|---|---|---|---|
| `page` | int | 1 | Page number |
| `limit` | int | 24 | Items per page (max 100) |
| `sort` | string | `created_at_desc` | `price_asc`, `price_desc`, `rating_desc`, `sold_desc` |
| `min_price` | number | — | Filter by minimum price |
| `max_price` | number | — | Filter by maximum price |
| `rating` | number | — | Minimum average rating |
| `in_stock` | boolean | false | Only in-stock products |

**Response `200`:**
```json
{
  "data": [ { "id": "uuid", "name": "…", "price": "35.00", "…": "…" } ],
  "meta": { "total": 128, "page": 1, "limit": 24, "total_pages": 6 }
}
```

---

## 4. Products

### `GET /products`

Global product listing with the same query params as categories/:slug/products plus `q` (text search) and `category_slug`.

---

### `GET /products/:id`

**Response `200`:**
```json
{
  "data": {
    "id": "uuid",
    "category": { "id": "uuid", "name": "Groceries", "slug": "groceries" },
    "supplier": { "id": "uuid", "name": "Al Meera" },
    "name": "Organic Dates 500g",
    "slug": "organic-dates-500g",
    "description": "Rich, natural Medjool dates …",
    "short_description": "Premium organic dates from Saudi Arabia.",
    "sku": "GR-DATES-500",
    "price": "35.00",
    "compare_at_price": "45.00",
    "weight_grams": 550,
    "images": [
      { "url": "https://cdn.qcart.qa/products/dates-1.jpg", "alt": "Organic Dates", "sort": 0 }
    ],
    "attributes": { "origin": "Saudi Arabia", "weight": "500g", "type": "Organic" },
    "tags": ["dates", "organic", "halal"],
    "is_active": true,
    "is_featured": true,
    "average_rating": 4.5,
    "review_count": 238,
    "total_sold": 1420,
    "in_stock": true,
    "available_quantity": 84
  }
}
```

---

### `GET /products/:id/reviews`

**Query params:** `page`, `limit`, `rating` (filter), `sort` (`recent` \| `helpful`)

**Response `200`:**
```json
{
  "data": [
    {
      "id": "uuid",
      "user": { "id": "uuid", "full_name": "A. Mohammed", "avatar_url": null },
      "rating": 5,
      "title": "Excellent quality",
      "body": "Best dates I've tried …",
      "images": [],
      "is_verified": true,
      "helpful_count": 12,
      "reply": null,
      "created_at": "2026-05-20T14:22:00Z"
    }
  ],
  "meta": { "total": 238, "average_rating": 4.5, "rating_breakdown": { "5": 180, "4": 40, "3": 12, "2": 4, "1": 2 } }
}
```

---

## 5. Cart

> Authenticated users: cart identified by JWT.  
> Guests: `X-Session-ID: <uuid>` header.

### `GET /cart`

**Response `200`:**
```json
{
  "data": {
    "id": "uuid",
    "items": [
      {
        "id": "uuid",
        "product": { "id": "uuid", "name": "Organic Dates 500g", "image_url": "…", "slug": "…" },
        "quantity": 2,
        "unit_price": "35.00",
        "subtotal": "70.00",
        "in_stock": true
      }
    ],
    "coupon": null,
    "subtotal": "70.00",
    "discount": "0.00",
    "delivery_fee": "15.00",
    "total": "85.00",
    "item_count": 2
  }
}
```

---

### `POST /cart/items`

**Request:** `{ "product_id": "uuid", "quantity": 2 }`  
**Response `201`:** Full cart object.

---

### `PATCH /cart/items/:item_id`

**Request:** `{ "quantity": 3 }`  
**Response `200`:** Full cart object.

---

### `DELETE /cart/items/:item_id`

**Response `200`:** Full cart object.

---

### `DELETE /cart`

Clear all items.  
**Response `200`:** Empty cart.

---

### `POST /cart/coupon`

**Request:** `{ "code": "WELCOME20" }`  
**Response `200`:** Full cart with discount applied.

**Error `422`:** `COUPON_INVALID`, `COUPON_EXPIRED`, `COUPON_USAGE_EXCEEDED`, `ORDER_BELOW_MINIMUM`

---

### `DELETE /cart/coupon`

Remove applied coupon. **Response `200`:** Cart without coupon.

---

## 6. Orders

### `GET /orders`

Authenticated user's order history.

**Query params:** `status`, `page`, `limit`

**Response `200`:**
```json
{
  "data": [
    {
      "id": "uuid",
      "order_number": "QC-010042",
      "status": "delivered",
      "payment_status": "paid",
      "item_count": 3,
      "total": "183.00",
      "created_at": "2026-06-05T09:15:00Z",
      "delivered_at": "2026-06-05T12:30:00Z"
    }
  ],
  "meta": { "total": 12, "page": 1, "limit": 10 }
}
```

---

### `GET /orders/:id`

Full order detail including items, address snapshot, and tracking.

**Response `200`:**
```json
{
  "data": {
    "id": "uuid",
    "order_number": "QC-010042",
    "status": "out_for_delivery",
    "payment_method": "card",
    "payment_status": "paid",
    "items": [
      {
        "product_id": "uuid",
        "product_name": "Organic Dates 500g",
        "product_image": "https://cdn.qcart.qa/…",
        "quantity": 2,
        "unit_price": "35.00",
        "total_price": "70.00",
        "is_reviewed": false
      }
    ],
    "address": {
      "full_name": "Yousuf Al-Rashid",
      "line1": "Villa 14, Street 22, Al Waab",
      "city": "Doha",
      "country": "Qatar",
      "phone": "+97455123456"
    },
    "subtotal": "183.00",
    "discount_amount": "9.15",
    "delivery_fee": "0.00",
    "total": "173.85",
    "tracking": [
      { "step": "order_placed",       "label": "Order Placed",       "completed": true,  "timestamp": "2026-06-10T09:00:00Z" },
      { "step": "confirmed",          "label": "Confirmed",          "completed": true,  "timestamp": "2026-06-10T09:05:00Z" },
      { "step": "processing",         "label": "Processing",         "completed": true,  "timestamp": "2026-06-10T09:20:00Z" },
      { "step": "out_for_delivery",   "label": "Out for Delivery",   "completed": true,  "timestamp": "2026-06-10T10:10:00Z" },
      { "step": "delivered",          "label": "Delivered",          "completed": false, "timestamp": null }
    ],
    "estimated_delivery": "2026-06-10T11:00:00Z",
    "created_at": "2026-06-10T09:00:00Z"
  }
}
```

---

### `POST /orders/:id/cancel`

Cancel a pending or confirmed order.

**Request:** `{ "reason": "Changed my mind" }`  
**Response `200`:** Updated order with `status: "cancelled"`.

**Error `409`:** `ORDER_NOT_CANCELLABLE` if status is beyond `confirmed`.

---

### `POST /orders/:id/reorder`

Adds all items from a previous order back into the active cart.  
**Response `200`:** Full cart object.

---

## 7. Checkout

### `POST /checkout`

Creates an order from the current cart. Atomically:
1. Validates stock availability
2. Validates coupon (if any)
3. Calculates final totals
4. Creates order + order_items
5. Reserves inventory
6. Clears cart
7. Sends confirmation notification

**Request:**
```json
{
  "address_id": "uuid",
  "payment_method": "card",
  "payment_token": "tok_visa_xxxx",
  "notes": "Please leave at the door"
}
```

**Response `201`:**
```json
{
  "data": {
    "order_id": "uuid",
    "order_number": "QC-010043",
    "status": "confirmed",
    "payment_status": "paid",
    "total": "173.85",
    "estimated_delivery": "2026-06-10T11:00:00Z"
  }
}
```

**Error `409`:** `INSUFFICIENT_STOCK` — includes `out_of_stock_items: [{ product_id, available }]`.

---

### `POST /checkout/estimate`

Calculate totals without placing the order.

**Request:**
```json
{
  "address_id": "uuid",
  "coupon_code": "WELCOME20"
}
```

**Response `200`:**
```json
{
  "data": {
    "subtotal": "183.00",
    "discount_amount": "9.15",
    "delivery_fee": "0.00",
    "total": "173.85",
    "coupon_applied": true,
    "free_delivery": true,
    "estimated_delivery_minutes": 45
  }
}
```

---

## 8. Reviews

### `POST /products/:id/reviews`

> User must have a delivered order containing the product.

**Request:**
```json
{
  "order_id": "uuid",
  "rating": 5,
  "title": "Excellent quality",
  "body": "Best dates I have ever tried …",
  "images": ["https://cdn.qcart.qa/reviews/img1.jpg"]
}
```
**Response `201`:** Created review object.

**Error `409`:** `ALREADY_REVIEWED` (same product + order).  
**Error `403`:** `PURCHASE_REQUIRED`.

---

### `PATCH /reviews/:id`

Update own review within 30 days.

---

### `DELETE /reviews/:id`

Delete own review.  **Response `204`**

---

### `POST /reviews/:id/helpful`

Toggle helpful vote. **Response `200`:** `{ "helpful_count": 13 }`

---

## 9. Suppliers

> `Admin` role required for write operations. `GET` endpoints are public.

### `GET /suppliers`

**Query params:** `status`, `page`, `limit`

**Response `200`:** Paginated supplier list.

---

### `GET /suppliers/:id`

Single supplier with product count.

---

### `POST /suppliers`  *(Admin)*

**Request:**
```json
{
  "name": "Al Meera Consumer Goods",
  "email": "partner@almeera.com.qa",
  "phone": "+97444123456",
  "contact_person": "Hassan Al-Kuwari",
  "address": "P.O. Box 3862, Doha, Qatar"
}
```
**Response `201`:** Created supplier.

---

### `PUT /suppliers/:id`  *(Admin)*

Full update.

---

### `PATCH /suppliers/:id/status`  *(Admin)*

**Request:** `{ "status": "active" }`  
**Response `200`:** Updated supplier.

---

### `GET /suppliers/:id/products`

Products belonging to this supplier. Supports same query params as product listing.

---

## 10. Inventory

> `Admin` or `Supplier` role required.

### `GET /inventory`  *(Admin)*

**Query params:** `low_stock=true`, `product_id`, `page`, `limit`

**Response `200`:**
```json
{
  "data": [
    {
      "product_id": "uuid",
      "product_name": "Organic Dates 500g",
      "sku": "GR-DATES-500",
      "quantity": 84,
      "reserved": 6,
      "available": 78,
      "reorder_point": 20,
      "is_low_stock": false
    }
  ]
}
```

---

### `GET /inventory/:product_id`

Single product inventory record.

---

### `POST /inventory/:product_id/adjust`  *(Admin)*

Manual stock adjustment.

**Request:**
```json
{
  "txn_type": "restock",
  "quantity_delta": 200,
  "notes": "Weekly delivery from Al Meera"
}
```
**Response `200`:** Updated inventory + transaction record.

---

### `GET /inventory/:product_id/transactions`  *(Admin)*

**Query params:** `txn_type`, `from`, `to`, `page`, `limit`

**Response `200`:** Paginated transaction log.

---

### `GET /inventory/alerts`  *(Admin)*

Products at or below `reorder_point`.

**Response `200`:**
```json
{
  "data": [
    {
      "product_id": "uuid",
      "product_name": "Saffron Pack 5g",
      "quantity": 8,
      "reorder_point": 10,
      "reorder_qty": 50,
      "supplier": { "id": "uuid", "name": "Qatar Spices Co." }
    }
  ]
}
```

---

## Webhooks

Q Cart emits webhook events to registered supplier endpoints.

| Event | Payload |
|---|---|
| `order.placed` | `{ order_id, items, supplier_id }` |
| `order.cancelled` | `{ order_id, reason }` |
| `inventory.low_stock` | `{ product_id, quantity, reorder_point }` |
| `review.created` | `{ review_id, product_id, rating }` |

All webhook payloads include `X-QCart-Signature: sha256=<hmac>` for verification.
