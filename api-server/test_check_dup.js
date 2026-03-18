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
  const loginData = JSON.stringify({ email: 'admin@easternmangrove.th', password: 'admin123!' });
  const loginRes = await makeRequest({
    port: 3002,
    path: '/api/auth/login',
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(loginData) }
  }, loginData);

  const token = JSON.parse(loginRes.body).data.token;
  console.log('Token OK:', token.substring(0, 20) + '...');

  const checkData = JSON.stringify({ communityName: 'ชุมชนทดสอบใหม่', email: 'brand_new@test.com' });
  const checkRes = await makeRequest({
    port: 3002,
    path: '/api/admin/communities/check-duplicate',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(checkData),
      'Authorization': 'Bearer ' + token
    }
  }, checkData);

  console.log('check-duplicate status:', checkRes.status);
  console.log('check-duplicate body:', checkRes.body);
}

main().catch(e => console.error('Error:', e));
