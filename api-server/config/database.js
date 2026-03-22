const { Pool } = require('pg');

// Create PostgreSQL connection pool
const isProduction = process.env.NODE_ENV === 'production';

const poolConfig = {
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  ssl: isProduction ? { rejectUnauthorized: false } : false,
  max: 20, // maximum number of connections in the pool
  idleTimeoutMillis: 30000, // close connections after 30 seconds of inactivity
  connectionTimeoutMillis: 10000, // return an error after 10 seconds if connection could not be established
  // Set default search_path so all queries find tables in eastern_mangrove_communities schema
  options: '-c search_path=eastern_mangrove_communities,public',
};

// Only add password if it exists and is not empty
if (process.env.DB_PASSWORD && process.env.DB_PASSWORD.trim() !== '') {
  poolConfig.password = process.env.DB_PASSWORD;
}

const pool = new Pool(poolConfig);

// Event listeners for pool
pool.on('connect', (client) => {
  // Set default schema so all queries find eastern_mangrove_communities tables
  client.query('SET search_path TO eastern_mangrove_communities, public');
  console.log('🔗 New PostgreSQL client connected');
});

pool.on('error', (err, client) => {
  console.error('💥 Unexpected error on idle PostgreSQL client', err);
  process.exit(-1);
});

// Helper function to get a client from the pool
const getClient = async () => {
  try {
    const client = await pool.connect();
    return client;
  } catch (error) {
    console.error('❌ Error getting PostgreSQL client:', error);
    throw error;
  }
};

// Helper function to execute queries
const query = async (text, params) => {
  const client = await getClient();
  try {
    const start = Date.now();
    const result = await client.query(text, params);
    const duration = Date.now() - start;
    console.log('⚡ Executed query:', { text, duration, rows: result.rowCount });
    return result;
  } catch (error) {
    console.error('❌ Query error:', { text, error: error.message });
    throw error;
  } finally {
    client.release();
  }
};

// Test database connection
const testConnection = async () => {
  try {
    const client = await getClient();
    const result = await client.query('SELECT NOW() as time, version() as version');
    console.log('✅ PostgreSQL connected successfully at:', result.rows[0].time);
    console.log('📊 PostgreSQL version:', result.rows[0].version.split(' ')[0] + ' ' + result.rows[0].version.split(' ')[1]);
    client.release();
    return true;
  } catch (error) {
    console.error('❌ PostgreSQL connection failed:', error.message);
    return false;
  }
};

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🔄 Gracefully shutting down PostgreSQL connections...');
  await pool.end();
  console.log('✅ PostgreSQL connection pool closed.');
  process.exit(0);
});

module.exports = {
  pool,
  query,
  getClient,
  testConnection
};