import express from 'express';
import { Pool } from 'pg';
import dotenv from 'dotenv';



const pool = new Pool({
   host: "log.cxcqga0m4dkc.eu-west-1.rds.amazonaws.com",
   user: "root",
  password: "admin2025pass",
  database: "prostgresdb",
   port: "5432",
   idleTimeoutMillis: "30000",
 });

export default pool;

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

const pool = new Pool({
  connectionString: process.log.cxcqga0m4dkc.eu-west-1.rds.amazonaws.com,
});

app.use(express.json());

// Create table if not exists
pool.query(`
  CREATE TABLE IF NOT EXISTS log (
    id SERIAL PRIMARY KEY,
    inserted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    json JSON NOT NULL
  );
`).catch(console.error);

// Insert log entry
app.post('/log', async (req, res) => {
  try {
    const { json } = req.body;
    if (!json) {
      return res.status(400).json({ error: 'JSON data is required' });
    }
    const result = await pool.query(
      'INSERT INTO log (json) VALUES ($1) RETURNING *',
      [json]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// List log entries
app.get('/log', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM log ORDER BY inserted_at DESC');
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});

export default app;
