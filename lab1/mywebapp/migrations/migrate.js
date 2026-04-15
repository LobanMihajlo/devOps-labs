const { Pool } = require("pg");
const fs = require("fs");

const config = JSON.parse(fs.readFileSync("/etc/mywebapp/config.json", "utf8"));
const pool = new Pool(config.database);

const migrationSql = `
CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
`;

(async function runMigration() {
  try {
    await pool.query(migrationSql);
    console.log("Migration successful: Table 'tasks' is ready.");
    process.exit(0);
  } catch (err) {
    console.error("Migration failed:", err);
    process.exit(1);
  }
})();
