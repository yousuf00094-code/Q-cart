const DEFAULT_LIMIT = parseInt(process.env.DEFAULT_PAGE_LIMIT || '24', 10);
const MAX_LIMIT     = parseInt(process.env.MAX_PAGE_LIMIT    || '100', 10);

// ── Offset-based pagination (admin / analytics endpoints) ──────────────────

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

// ── Cursor-based pagination (product / order listings) ─────────────────────
// Cursor encodes { id, created_at } of the last seen row. This gives stable
// results as new rows are inserted and avoids the O(offset) scan on large tables.

const encodeCursor = (id, createdAt) =>
  Buffer.from(JSON.stringify({ id, ts: new Date(createdAt).toISOString() })).toString('base64url');

const decodeCursor = (cursor) => {
  try {
    const { id, ts } = JSON.parse(Buffer.from(cursor, 'base64url').toString('utf8'));
    if (!id || !ts) return null;
    return { id, created_at: ts };
  } catch {
    return null;
  }
};

const parseCursorPagination = (query) => {
  const limit  = Math.min(MAX_LIMIT, Math.max(1, parseInt(query.limit || String(DEFAULT_LIMIT), 10)));
  const cursor = query.cursor ? decodeCursor(query.cursor) : null;
  return { limit, cursor };
};

// Pass rows fetched with limit+1 to detect the next page without a COUNT query.
const buildCursorMeta = (rows, limit) => {
  const hasMore = rows.length > limit;
  const data    = hasMore ? rows.slice(0, limit) : rows;
  const last    = data[data.length - 1];
  return {
    data,
    meta: {
      limit,
      has_more: hasMore,
      next_cursor: hasMore && last ? encodeCursor(last.id, last.created_at) : null,
    },
  };
};

module.exports = { parsePagination, buildMeta, parseCursorPagination, buildCursorMeta, encodeCursor, decodeCursor };
