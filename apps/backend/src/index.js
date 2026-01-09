import express from "express";
import cors from "cors";
import { EventBridgeClient, PutEventsCommand } from "@aws-sdk/client-eventbridge";
import pg from "pg";
import { v4 as uuidv4 } from "uuid";

const app = express();
app.use(cors());
app.use(express.json());

const {
  REGION,
  EVENT_BUS_NAME,
  DB_HOST,
  DB_PORT,
  DB_NAME,
  DB_USER,
  DB_PASSWORD
} = process.env;

/**
 * AWS EventBridge client
 */
const eb = new EventBridgeClient({ region: REGION });

/**
 * ✅ PostgreSQL (AWS RDS compatible)
 * - SSL REQUIRED
 * - rejectUnauthorized=false for AWS cert chain
 */
const pool = new pg.Pool({
  host: DB_HOST,
  port: Number(DB_PORT || 5432),
  database: DB_NAME,
  user: DB_USER,
  password: DB_PASSWORD,
  ssl: {
    rejectUnauthorized: false
  }
});

/**
 * Ensure deployments table exists
 */
async function ensureTable() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS deployments (
      id TEXT PRIMARY KEY,
      requested_at TIMESTAMPTZ NOT NULL,
      difficulty TEXT NOT NULL,
      instance_id TEXT,
      status TEXT NOT NULL
    );
  `);
}

ensureTable().catch((e) => {
  console.error("DB init failed", e);
});

/**
 * Health check
 */
app.get("/healthz", (_req, res) => {
  res.json({ ok: true });
});

/**
 * Get deployments
 */
app.get("/api/deployments", async (_req, res) => {
  try {
    const r = await pool.query(
      "SELECT * FROM deployments ORDER BY requested_at DESC LIMIT 50"
    );
    res.json(r.rows);
  } catch (e) {
    console.error("DB query failed", e);
    res.status(500).json({ error: "db_error" });
  }
});

/**
 * Create deployment request
 */
app.post("/api/deploy", async (req, res) => {
  const difficulty = (req.body?.difficulty || "").toLowerCase();

  if (!["easy", "medium", "hard"].includes(difficulty)) {
    return res.status(400).json({ error: "invalid_difficulty" });
  }

  const id = uuidv4();
  const requested_at = new Date().toISOString();

  try {
    await pool.query(
      "INSERT INTO deployments (id, requested_at, difficulty, status) VALUES ($1, $2, $3, $4)",
      [id, requested_at, difficulty, "QUEUED"]
    );
  } catch (e) {
    console.error("DB insert failed", e);
    return res.status(500).json({ error: "db_insert_failed" });
  }

  const detail = { id, difficulty, requested_at };

  try {
    await eb.send(
      new PutEventsCommand({
        Entries: [
          {
            EventBusName: EVENT_BUS_NAME,
            Source: "training-platform.backend",
            DetailType: "deploy-request",
            Detail: JSON.stringify(detail)
          }
        ]
      })
    );
  } catch (e) {
    console.error("EventBridge publish failed", e);
    await pool
      .query("UPDATE deployments SET status=$1 WHERE id=$2", ["FAILED_PUBLISH", id])
      .catch(() => {});
    return res.status(500).json({ error: "eventbridge_publish_failed" });
  }

  res.json({ ok: true, id });
});

/**
 * Start server
 */
const port = Number(process.env.PORT || 8080);
app.listen(port, () => {
  console.log(`backend listening on :${port}`);
});
