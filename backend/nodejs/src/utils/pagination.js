const DEFAULT_LIMIT = parseInt(process.env.DEFAULT_PAGE_LIMIT || '24', 10);
const MAX_LIMIT     = parseInt(process.env.MAX_PAGE_LIMIT    || '100', 10);

const parsePagination = (query) => {
  const page  = Math.max(1, parseInt(query.page  || '1',  10));
  const limit = Math.min(MAX_LIMIT, Math.max(1, parseInt(query.limit || String(DEFAULT_LIMIT), 10)));
  const offset = (page - 1) * limit;
  return { page, limit, offset };
};

const buildMeta = (total, page, limit) => ({
  total,
  page,
  limit,
  total_pages: Math.ceil(total / limit),
});

module.exports = { parsePagination, buildMeta };
