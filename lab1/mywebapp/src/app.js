const express = require("express");
const { Pool } = require("pg");
const fs = require("fs");

const config = JSON.parse(fs.readFileSync("../config.json", "utf8"));
const app = express();
const pool = new Pool(config.database);

app.use(express.json());

const sendResponse = (req, res, jsonData, htmlTable) => {
  const accept = req.headers.accept || "";
  if (accept.includes("application/json")) {
    return res.json(jsonData);
  }
  res.send(`<html><body>${htmlTable}</body></html>`);
};

app.get("/", (req, res) => {
  res.send(`
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
  await pool.query("INSERT INTO tasks (title, status) VALUES ($1, $2)", [
    title,
    "pending",
  ]);
  res.status(201).send("Task Created");
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

const server = app.listen(config.server.port, () => {
  console.log(`App listening on port ${config.server.port}`);
});
