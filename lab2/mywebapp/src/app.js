const express = require("express");
const { Pool } = require("pg");
const fs = require("fs");

const config = JSON.parse(fs.readFileSync("/etc/mywebapp/config.json", "utf8"));
const app = express();
const pool = new Pool(config.database);

app.use(express.json());

const sendResponse = (req, res, jsonData, htmlTable, status = 200) => {
  const accept = req.headers.accept || "";
  if (accept.includes("application/json")) {
    return res.status(status).json(jsonData);
  }
  return res
    .status(status)
    .type("text/html")
    .send(`<html><body>${htmlTable}</body></html>`);
};

app.get("/", (req, res) => {
  res.type("text/html").send(`
        <h1>Task Tracker API</h1>
        <ul>
            <li><a href="/tasks">GET /tasks</a></li>
            <li>POST /tasks</li>
            <li>POST /tasks/:id/done</li>
        </ul>
    `);
});

app.get("/tasks", async (req, res) => {
  const result = await pool.query(
    "SELECT id, title, status, created_at FROM tasks",
  );
  const rows = result.rows;

  let html =
    "<table><tr><th>ID</th><th>Title</th><th>Status</th><th>Created</th></tr>";
  rows.forEach((r) => {
    html += `<tr><td>${r.id}</td><td>${r.title}</td><td>${r.status}</td><td>${r.created_at}</td></tr>`;
  });
  html += "</table>";

  sendResponse(req, res, rows, html);
});

app.post("/tasks", async (req, res) => {
  const { title } = req.body;
  const result = await pool.query(
    "INSERT INTO tasks (title, status) VALUES ($1, $2) RETURNING id, title, status, created_at",
    [title, "pending"],
  );

  const createdTask = result.rows[0];
  const html = `<h1>Task Created</h1><p>ID: ${createdTask.id}</p><p>Title: ${createdTask.title}</p><p>Status: ${createdTask.status}</p><p>Created: ${createdTask.created_at}</p>`;
  return sendResponse(req, res, createdTask, html, 201);
});

app.post("/tasks/:id/done", async (req, res) => {
  const id = Number.parseInt(req.params.id, 10);

  if (!Number.isInteger(id) || id <= 0) {
    return res.status(400).send("Invalid task id");
  }

  const result = await pool.query(
    "UPDATE tasks SET status = $1 WHERE id = $2 RETURNING id, title, status, created_at",
    ["done", id],
  );

  if (result.rowCount === 0) {
    return res.status(404).send("Task not found");
  }

  const updatedTask = result.rows[0];
  const html = `<h1>Task Updated</h1><p>ID: ${updatedTask.id}</p><p>Title: ${updatedTask.title}</p><p>Status: ${updatedTask.status}</p><p>Created: ${updatedTask.created_at}</p>`;
  return sendResponse(req, res, updatedTask, html, 200);
});

app.get("/health/alive", (req, res) => res.status(200).send("OK"));

app.get("/health/ready", async (req, res) => {
  try {
    await pool.query("SELECT 1");
    res.status(200).send("OK");
  } catch (err) {
    res.status(500).send("DB Connection Failed");
  }
});

const hasSystemdSocket =
  Number(process.env.LISTEN_FDS || "0") >= 1 &&
  Number(process.env.LISTEN_PID || "0") === process.pid;

if (hasSystemdSocket) {
  app.listen({ fd: 3 }, () => {
    console.log("App listening via systemd socket activation");
  });
} else {
  app.listen(config.server.port, () => {
    console.log(`App listening on port ${config.server.port}`);
  });
}
