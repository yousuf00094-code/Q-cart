const CartModel   = require('../models/cart.model');
const ProductModel = require('../models/product.model');
const { AppError } = require('../middleware/errorHandler');

const getCart = async (req, res, next) => {
  try {
    const cart = await CartModel.getWithItems(req.user.id);
    res.json({ data: cart });
  } catch (err) { next(err); }
};

const addItem = async (req, res, next) => {
  try {
    const { product_id, quantity = 1 } = req.body;

    const product = await ProductModel.findById(product_id);
    if (!product || !product.is_active) {
      throw new AppError('Product not found or unavailable.', 404, 'NOT_FOUND');
    }

    // Check how much is currently in the cart
    const currentCart = await CartModel.getWithItems(req.user.id);
    const existing = currentCart.items.find((i) => i.product_id === product_id);
    const totalRequested = (existing?.quantity || 0) + quantity;

    if (totalRequested > product.available_quantity) {
      throw new AppError(
        `Only ${product.available_quantity} units available.`,
        409,
        'INSUFFICIENT_STOCK',
        { available: product.available_quantity }
      );
    }

    await CartModel.addItem(req.user.id, product_id, quantity);
    const cart = await CartModel.getWithItems(req.user.id);
    res.status(200).json({ data: cart });
  } catch (err) { next(err); }
};

const updateItem = async (req, res, next) => {
  try {
    const { quantity } = req.body;
    const cart = await CartModel.getOrCreate(req.user.id);
    const item = await CartModel.findItem(cart.id, req.params.itemId);

    if (!item) throw new AppError('Cart item not found.', 404, 'NOT_FOUND');

    if (quantity > 0) {
      const product = await ProductModel.findById(item.product_id);
      if (product && quantity > product.available_quantity) {
        throw new AppError(
          `Only ${product.available_quantity} units available.`,
          409,
          'INSUFFICIENT_STOCK',
          { available: product.available_quantity }
        );
      }
    }

    await CartModel.updateItem(req.user.id, req.params.itemId, quantity);
    const updated = await CartModel.getWithItems(req.user.id);
    res.json({ data: updated });
  } catch (err) { next(err); }
};

const removeItem = async (req, res, next) => {
  try {
    const removed = await CartModel.removeItem(req.user.id, req.params.itemId);
    if (!removed) throw new AppError('Cart item not found.', 404, 'NOT_FOUND');
    const cart = await CartModel.getWithItems(req.user.id);
    res.json({ data: cart });
  } catch (err) { next(err); }
};

const clearCart = async (req, res, next) => {
  try {
    await CartModel.clear(req.user.id);
    const cart = await CartModel.getWithItems(req.user.id);
    res.json({ data: cart });
  } catch (err) { next(err); }
};

const mergeCart = async (req, res, next) => {
  try {
    const { items } = req.body; // [{ product_id, quantity }]
    const cart = await CartModel.mergeItems(req.user.id, items);
    res.json({ data: cart });
  } catch (err) { next(err); }
};

module.exports = { getCart, addItem, updateItem, removeItem, clearCart, mergeCart };
