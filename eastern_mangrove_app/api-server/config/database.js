const { Pool } = require('pg');

// Database connection configuration — supports Render DATABASE_URL or individual vars
const isProduction = process.env.NODE_ENV === 'production';

const poolConfig = process.env.DATABASE_URL
  ? {
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 10000,
    }
  : {
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT) || 5432,
      database: process.env.DB_NAME || 'eastern_mangrove_communities',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD,
      ssl: isProduction ? { rejectUnauthorized: false } : false,
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 10000,
    };

const pool = new Pool(poolConfig);

// Test database connection
pool.on('connect', () => {
  console.log('🐘 Connected to PostgreSQL database');
});

pool.on('error', (err) => {
  console.error('💥 PostgreSQL connection error:', err);
  process.exit(-1);
});

// Helper function to execute queries
async function query(text, params) {
  const client = await pool.connect();
  try {
    const result = await client.query(text, params);
    return result;
  } catch (err) {
    console.error('Database query error:', err);
    throw err;
  } finally {
    client.release();
  }
}

// Helper function for transactions
async function transaction(callback) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// Helper function to get a single row
async function queryOne(text, params) {
  const result = await query(text, params);
  return result.rows[0];
}

// Helper function to check if record exists
async function exists(table, conditions) {
  const whereClause = Object.keys(conditions)
    .map((key, index) => `${key} = $${index + 1}`)
    .join(' AND ');
  
  const values = Object.values(conditions);
  const result = await query(
    `SELECT 1 FROM ${table} WHERE ${whereClause} LIMIT 1`,
    values
  );
  
  return result.rows.length > 0;
}

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('🔌 Closing database connections...');
  await pool.end();
});

process.on('SIGTERM', async () => {
  console.log('🔌 Closing database connections...');
  await pool.end();
});

module.exports = {
  pool,
  query,
  queryOne,
  transaction,
  exists
};