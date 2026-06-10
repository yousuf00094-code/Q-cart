const ReviewModel  = require('../models/review.model');
const { query }    = require('../config/database');
const { AppError } = require('../middleware/errorHandler');

const createReview = async ({ productId, userId, orderId, rating, title, body, images }) => {
  if (orderId) {
    // Verify user actually purchased this product
    const { rows } = await query(
      `SELECT oi.id FROM order_items oi
       JOIN orders o ON o.id = oi.order_id
       WHERE o.id = $1 AND o.user_id = $2
         AND oi.product_id = $3 AND o.status = 'delivered'`,
      [orderId, userId, productId]
    );
    if (!rows.length) throw new AppError('Purchase required to review this product.', 403, 'PURCHASE_REQUIRED');
  }

  const existing = await ReviewModel.findByProductAndUser(productId, userId, orderId || null);
  if (existing) throw new AppError('You have already reviewed this product for this order.', 409, 'ALREADY_REVIEWED');

  const review = await ReviewModel.create({
    productId, userId, orderId: orderId || null,
    rating, title, body, images,
    isVerified: !!orderId,
  });

  if (orderId) {
    await query(
      'UPDATE order_items SET is_reviewed = TRUE WHERE order_id = $1 AND product_id = $2',
      [orderId, productId]
    );
  }

  return review;
};

module.exports = { createReview };
