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

// Friendly Thai messages for "the user sent bad data" database errors, keyed by
// constraint name (or a prefix of it). Anything not listed falls back to a
// generic message per error class. error.code is left untouched so callers that
// check it (e.g. '23505') keep working.
const CONSTRAINT_MESSAGES = {
  economic_data_unique: 'มีข้อมูลรายได้ของปีและไตรมาสนี้อยู่แล้ว กรุณาแก้ไขรายการเดิมแทน',
  ecosystem_services_service_type_check: 'ประเภทบริการนิเวศไม่ถูกต้อง',
  ecosystem_services_category_check: 'หมวดหมู่บริการนิเวศไม่ถูกต้อง',
  ecosystem_services_month_check: 'เดือนต้องอยู่ระหว่าง 1 ถึง 12',
  ecosystem_services_year_check: 'ปีไม่ถูกต้อง',
  ecosystem_services_economic_value_check: 'มูลค่าทางเศรษฐกิจต้องไม่ติดลบ',
  ecosystem_services_beneficiaries_count_check: 'จำนวนผู้รับประโยชน์ต้องไม่ติดลบ',
  ecosystem_services_confidence_level_check: 'ระดับความเชื่อมั่นไม่ถูกต้อง',
  pollution_reports_report_type_check: 'ประเภทมลพิษไม่ถูกต้อง',
  pollution_reports_severity_level_check: 'ระดับความรุนแรงไม่ถูกต้อง',
  pollution_reports_status_check: 'สถานะรายงานไม่ถูกต้อง',
  mangrove_areas_conservation_status_check: 'สถานะการอนุรักษ์ไม่ถูกต้อง',
  mangrove_areas_size_hectares_check: 'ขนาดพื้นที่ต้องมากกว่า 0',
  mangrove_areas_established_year_check: 'ปีที่ก่อตั้งไม่ถูกต้อง',
  economic_data_quarter_check: 'ไตรมาสต้องอยู่ระหว่าง 1 ถึง 4',
  economic_data_year_check: 'ปีไม่ถูกต้อง',
  economic_data_employment_count_check: 'จำนวนการจ้างงานต้องไม่ติดลบ',
  economic_data_income_fishery_check: 'รายได้ต้องไม่ติดลบ',
  economic_data_income_tourism_check: 'รายได้ต้องไม่ติดลบ',
  economic_data_income_agriculture_check: 'รายได้ต้องไม่ติดลบ',
  economic_data_income_others_check: 'รายได้ต้องไม่ติดลบ',
};

// Turns Postgres data errors into 4xx errors with a readable message.
const friendlyDbError = (error) => {
  const byCode = {
    '23505': [409, 'ข้อมูลนี้มีอยู่แล้วในระบบ'],
    '23503': [400, 'ข้อมูลที่อ้างอิงไม่มีอยู่ในระบบ'],
    '23502': [400, 'กรุณากรอกข้อมูลที่จำเป็นให้ครบ'],
    '23514': [400, 'ข้อมูลไม่ถูกต้องตามเงื่อนไขของระบบ'],
    '22P02': [400, 'รูปแบบข้อมูลไม่ถูกต้อง'],
    '22003': [400, 'ตัวเลขมีค่ามากหรือน้อยเกินไป'],
    '22001': [400, 'ข้อความยาวเกินกำหนด'],
    '22007': [400, 'รูปแบบวันที่ไม่ถูกต้อง'],
    '22008': [400, 'วันที่ไม่ถูกต้อง'],
  };
  const hit = error && byCode[error.code];
  if (!hit) return error;
  error.dbMessage = error.message;
  error.status = hit[0];
  error.message = CONSTRAINT_MESSAGES[error.constraint] || hit[1];
  return error;
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
    throw friendlyDbError(error);
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