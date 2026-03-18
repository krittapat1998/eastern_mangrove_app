const http = require('http');

function makeRequest(options, data) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, res => {
      let body = '';
      res.on('data', d => body += d);
      res.on('end', () => resolve({ status: res.statusCode, body }));
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

async function main() {
  // Step 1: Login
  const loginData = JSON.stringify({ email: 'admin@easternmangrove.th', password: 'admin123!' });
  const loginRes = await makeRequest({
    port: 3002,
    path: '/api/auth/login',
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(loginData) }
  }, loginData);
  const token = JSON.parse(loginRes.body).data.token;
  console.log('1. Login OK, token:', token.substring(0, 20) + '...');

  const authHeaders = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
  };

  // Step 2: Check-duplicate with unique name
  const uniqueName = 'ชุมชนทดสอบอัตโนมัติ_' + Date.now();
  const uniqueEmail = 'unique_auto_' + Date.now() + '@test.com';
  const checkData = JSON.stringify({ communityName: uniqueName, email: uniqueEmail });
  const checkRes = await makeRequest({
    port: 3002,
    path: '/api/admin/communities/check-duplicate',
    method: 'POST',
    headers: { ...authHeaders, 'Content-Length': Buffer.byteLength(checkData) }
  }, checkData);
  console.log('2. Check-duplicate status:', checkRes.status);
  console.log('   Body:', checkRes.body);

  // Step 3: Create community
  const createData = JSON.stringify({
    communityName: uniqueName,
    location: 'ที่อยู่ทดสอบ',
    contactPerson: 'ผู้ทดสอบ',
    phoneNumber: '0812345678',
    email: uniqueEmail,
    password: 'test1234!',
    description: 'ชุมชนทดสอบอัตโนมัติ'
  });
  const createRes = await makeRequest({
    port: 3002,
    path: '/api/admin/communities',
    method: 'POST',
    headers: { ...authHeaders, 'Content-Length': Buffer.byteLength(createData) }
  }, createData);
  console.log('3. Create community status:', createRes.status);
  console.log('   Body:', createRes.body);
}

main().catch(e => console.error('Error:', e));
