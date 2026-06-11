const CategoryModel = require('../models/category.model');
const { AppError }  = require('../middleware/errorHandler');

const list = async (req, res, next) => {
  try {
    const includeInactive = req.user?.role === 'admin' && req.query.include_inactive === 'true';
    const categories = await CategoryModel.listRoots(includeInactive);

    if (!categories.length) return res.json({ data: [] });

    // Fetch all children for all root categories in one query instead of N queries
    const parentIds = categories.map((c) => c.id);
    const allChildren = await CategoryModel.listChildrenBatch(parentIds);

    const childrenByParent = {};
    for (const child of allChildren) {
      if (!childrenByParent[child.parent_id]) childrenByParent[child.parent_id] = [];
      childrenByParent[child.parent_id].push(child);
    }

    const withChildren = categories.map((c) => ({
      ...c,
      children: childrenByParent[c.id] || [],
    }));

    res.json({ data: withChildren });
  } catch (err) { next(err); }
};

const getOne = async (req, res, next) => {
  try {
    const cat = await CategoryModel.findBySlug(req.params.slug);
    if (!cat) throw new AppError('Category not found.', 404, 'NOT_FOUND');
    const children = await CategoryModel.listChildren(cat.id);
    res.json({ data: { ...cat, children } });
  } catch (err) { next(err); }
};

const create = async (req, res, next) => {
  try {
    const category = await CategoryModel.create(req.body);
    res.status(201).json({ data: category });
  } catch (err) { next(err); }
};

const update = async (req, res, next) => {
  try {
    const cat = await CategoryModel.findById(req.params.id);
    if (!cat) throw new AppError('Category not found.', 404, 'NOT_FOUND');
    const updated = await CategoryModel.update(req.params.id, req.body);
    res.json({ data: updated });
  } catch (err) { next(err); }
};

const remove = async (req, res, next) => {
  try {
    const deleted = await CategoryModel.remove(req.params.id);
    if (!deleted) throw new AppError('Category not found.', 404, 'NOT_FOUND');
    res.status(204).send();
  } catch (err) { next(err); }
};

module.exports = { list, getOne, create, update, remove };
