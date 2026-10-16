CREATE TABLE IF NOT EXISTS support_requests (
 id TEXT PRIMARY KEY,
 email TEXT NOT NULL,
 topic TEXT NOT NULL,
 message TEXT NOT NULL,
 locale TEXT NOT NULL,
 created_at INTEGER NOT NULL,
 notified INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS support_created ON support_requests(created_at);
CREATE TABLE IF NOT EXISTS request_limits (
 key TEXT PRIMARY KEY,
 window INTEGER NOT NULL,
 count INTEGER NOT NULL
);
