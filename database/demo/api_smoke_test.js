// Local API smoke/CRUD test against the DEMO database (http://127.0.0.1:3002)
const B = 'http://127.0.0.1:3002/api';
let pass = 0, fail = 0;
const ok = (name, cond, extra = '') => { (cond ? pass++ : fail++); console.log(`${cond ? 'PASS' : 'FAIL'}  ${name}${cond ? '' : '  ' + extra}`); };
const call = async (method, path, token, body) => {
  const r = await fetch(B + path, { method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: 'Bearer ' + token } : {}) }, body: body ? JSON.stringify(body) : undefined });
  let j = null; try { j = await r.json(); } catch (_) {}
  return { s: r.status, j };
};

(async () => {
  // --- auth
  const bad = await call('POST', '/auth/login', null, { username: 'demo_admin', password: 'wrong-password' });
  ok('login with wrong password rejected', bad.s === 401, JSON.stringify(bad));
  const a = await call('POST', '/auth/login', null, { username: 'demo_admin', password: 'DemoAdmin#2026' });
  const c1 = await call('POST', '/auth/login', null, { username: 'demo_community', password: 'DemoCommunity#2026' });
  const c2 = await call('POST', '/auth/login', null, { username: 'demo_community2', password: 'DemoCommunity#2026' });
  const TA = a.j?.data?.token, T1 = c1.j?.data?.token, T2 = c2.j?.data?.token;
  ok('admin login', !!TA, JSON.stringify(a.j)); ok('community1 login', !!T1); ok('community2 login', !!T2);

  // --- authorization
  ok('community token cannot reach admin API', (await call('GET', '/admin/communities', T1)).s === 403);
  ok('no token cannot reach community API', (await call('GET', '/ecosystem/services')).s === 401);

  // --- ecosystem services CRUD
  const list0 = await call('GET', '/ecosystem/services', T1);
  const n0 = (list0.j?.data?.services || list0.j?.data || []).length;
  const created = await call('POST', '/ecosystem/services', T1, { category: 'resource', serviceType: 'crab', serviceName: 'ปูม้า (ทดสอบ)', quantity: 10, unit: 'กก.', unitPrice: 300, economicValue: 3000, year: 2026, month: 10, description: 'api test', beneficiariesCount: 5 });
  const sid = created.j?.data?.id || created.j?.data?.service?.id;
  ok('create ecosystem service', created.s === 201 || created.s === 200, JSON.stringify(created.j)?.slice(0, 200));
  ok('created service has id', !!sid, JSON.stringify(created.j)?.slice(0, 200));
  const list1 = await call('GET', '/ecosystem/services', T1);
  ok('list grew by 1', (list1.j?.data?.services || list1.j?.data || []).length === n0 + 1);
  const upd = await call('PUT', `/ecosystem/services/${sid}`, T1, { category: 'resource', serviceType: 'crab', serviceName: 'ปูม้า (แก้ไข)', quantity: 20, unit: 'กก.', unitPrice: 300, economicValue: 6000, year: 2026, month: 10, description: 'api test 2', beneficiariesCount: 5 });
  ok('update ecosystem service', upd.s === 200, JSON.stringify(upd.j)?.slice(0, 200));
  const x = await call('PUT', `/ecosystem/services/${sid}`, T2, { category: 'resource', serviceType: 'crab', serviceName: 'hijack', quantity: 1, unit: 'กก.', unitPrice: 1, economicValue: 1, year: 2026, month: 10 });
  ok('other community cannot edit my service', x.s === 404 || x.s === 403, `status ${x.s}`);
  const xd = await call('DELETE', `/ecosystem/services/${sid}`, T2);
  ok('other community cannot delete my service', xd.s === 404 || xd.s === 403, `status ${xd.s}`);
  ok('delete ecosystem service', (await call('DELETE', `/ecosystem/services/${sid}`, T1)).s === 200);
  const badSvc = await call('POST', '/ecosystem/services', T1, { category: 'resource', serviceType: 'NOT_A_TYPE', serviceName: 'x', year: 2026, month: 1 });
  ok('invalid service type rejected (no 500)', badSvc.s >= 400 && badSvc.s < 500, `status ${badSvc.s} ${JSON.stringify(badSvc.j)?.slice(0, 150)}`);

  // --- pollution reports CRUD
  const pr = await call('POST', '/pollution/reports', T1, { reportType: 'Water Pollution', pollutionSource: 'api test', severityLevel: 'low', description: 'api test report', latitude: 12.52, longitude: 102.08, status: 'pending' });
  const rid = pr.j?.data?.id || pr.j?.data?.report?.id;
  ok('create pollution report', (pr.s === 201 || pr.s === 200) && !!rid, JSON.stringify(pr.j)?.slice(0, 200));
  const pu = await call('PUT', `/pollution/reports/${rid}`, T1, { reportType: 'Water Pollution', pollutionSource: 'api test', severityLevel: 'medium', description: 'api test report edited', latitude: 12.52, longitude: 102.08, status: 'investigating' });
  ok('update pollution report', pu.s === 200, JSON.stringify(pu.j)?.slice(0, 200));
  const pi = await call('POST', '/pollution/reports', T1, { reportType: 'Water Pollution', pollutionSource: 'impact test', severityLevel: 'low', description: 'impact', expectedImpact: 'ปลาตาย รากโกงกางเน่า', latitude: 12.52, longitude: 102.08 });
  const piId = pi.j?.data?.id;
  ok('pollution report stores expected impact', pi.j?.data?.expected_impact === 'ปลาตาย รากโกงกางเน่า', JSON.stringify(pi.j)?.slice(0, 200));
  const pl = await call('GET', '/pollution/reports', T1);
  ok('list returns expected_impact', (pl.j?.data || []).some(r => r.id === piId && r.expected_impact === 'ปลาตาย รากโกงกางเน่า'));
  const pu2 = await call('PUT', `/pollution/reports/${piId}`, T1, { reportType: 'Water Pollution', pollutionSource: 'impact test', severityLevel: 'low', description: 'impact', expectedImpact: 'แก้ไขแล้ว', latitude: 12.52, longitude: 102.08, status: 'pending' });
  ok('update changes expected impact', pu2.j?.data?.expected_impact === 'แก้ไขแล้ว', JSON.stringify(pu2.j)?.slice(0, 200));
  await call('DELETE', `/pollution/reports/${piId}`, T1);
  ok('other community cannot delete my report', [403, 404].includes((await call('DELETE', `/pollution/reports/${rid}`, T2)).s));
  ok('delete pollution report', (await call('DELETE', `/pollution/reports/${rid}`, T1)).s === 200);
  const badRep = await call('POST', '/pollution/reports', T1, { reportType: 'Alien Pollution', pollutionSource: 'x', severityLevel: 'low', description: 'x' });
  ok('invalid report type rejected (no 500)', badRep.s >= 400 && badRep.s < 500, `status ${badRep.s}`);

  // --- economic data CRUD
  const ec = await call('POST', '/economic/data', T1, { year: 2026, quarter: 4, incomeFishery: 1000, incomeTourism: 2000, incomeAgriculture: 300, incomeOthers: 40, employmentCount: 12, notes: 'api test' });
  const eid = ec.j?.data?.id || ec.j?.data?.economicData?.id;
  ok('create economic data', (ec.s === 201 || ec.s === 200) && !!eid, JSON.stringify(ec.j)?.slice(0, 200));
  const ec2 = await call('POST', '/economic/data', T1, { year: 2026, quarter: 4, incomeFishery: 1, incomeTourism: 1, incomeAgriculture: 1, incomeOthers: 1, employmentCount: 1 });
  ok('duplicate year/quarter handled (no 500)', ec2.s !== 500, `status ${ec2.s} ${JSON.stringify(ec2.j)?.slice(0, 150)}`);
  const ecNeg = await call('POST', '/economic/data', T1, { year: 2026, quarter: 4, incomeFishery: -5, incomeTourism: 0, incomeAgriculture: 0, incomeOthers: 0 });
  ok('negative income rejected (no 500)', ecNeg.s >= 400 && ecNeg.s < 500, `status ${ecNeg.s}`);
  ok('delete economic data', (await call('DELETE', `/economic/data/${eid}`, T1)).s === 200);

  // --- admin: areas CRUD
  const ar = await call('POST', '/admin/mangrove-areas', TA, { area_name: 'พื้นที่ทดสอบ API', location: 'ต.ทดสอบ', province: 'ตราด', size_hectares: 12.5, conservation_status: 'good', latitude: 12.2, longitude: 102.4, mangrove_species: ['แสมขาว'] });
  const aid = ar.j?.data?.id || ar.j?.data?.area?.id;
  const ac = await call('POST', '/admin/mangrove-areas', TA, { area_name: 'พื้นที่ติดต่อ', location: 'ต.ทดสอบ', province: 'ตราด', size_hectares: 1, contact_person: 'ผู้ติดต่อทดสอบ', contact_channel: 'LINE test_id' });
  ok('admin area stores contact person/channel', ac.j?.data?.contact_person === 'ผู้ติดต่อทดสอบ' && ac.j?.data?.contact_channel === 'LINE test_id', JSON.stringify(ac.j)?.slice(0, 200));
  const al = await call('GET', '/admin/mangrove-areas', TA);
  ok('admin list returns contact', (al.j?.data || []).some(a => a.contact_channel === 'LINE test_id'));
  const pubC = await call('GET', '/public/areas');
  ok('public API does NOT expose area contact', !JSON.stringify(pubC.j).includes('LINE test_id') && !JSON.stringify(pubC.j).includes('ผู้ติดต่อทดสอบ'));
  if (ac.j?.data?.id) await call('DELETE', `/admin/mangrove-areas/${ac.j.data.id}`, TA);
  ok('admin create area', (ar.s === 201 || ar.s === 200) && !!aid, JSON.stringify(ar.j)?.slice(0, 200));
  const pubAreas = await call('GET', '/public/areas');
  ok('new area visible on public endpoint', JSON.stringify(pubAreas.j).includes('พื้นที่ทดสอบ API'));
  const au = await call('PUT', `/admin/mangrove-areas/${aid}`, TA, { area_name: 'พื้นที่ทดสอบ API (แก้)', location: 'ต.ทดสอบ', province: 'ตราด', size_hectares: 13, conservation_status: 'good', latitude: 12.2, longitude: 102.4 });
  ok('admin update area', au.s === 200, JSON.stringify(au.j)?.slice(0, 200));
  ok('admin delete area', (await call('DELETE', `/admin/mangrove-areas/${aid}`, TA)).s === 200);
  const arBad = await call('POST', '/admin/mangrove-areas', TA, { area_name: 'x', location: 'y', province: 'z', conservation_status: 'unknown_status', size_hectares: -1 });
  ok('invalid area rejected (no 500)', arBad.s >= 400 && arBad.s < 500, `status ${arBad.s}`);

  // --- admin: approve / reject pending
  const pend = await call('GET', '/admin/communities/pending', TA);
  const plist = pend.j?.data?.communities || pend.j?.data || [];
  ok('2 pending communities listed', plist.length === 2, `got ${plist.length}`);
  if (plist.length >= 2) {
    const ap = await call('PUT', `/admin/communities/${plist[0].id}/approve`, TA, { notes: 'api test' });
    ok('admin approve community', ap.s === 200, JSON.stringify(ap.j)?.slice(0, 250));
    const rj = await call('PUT', `/admin/communities/${plist[1].id}/reject`, TA, { reason: 'api test' });
    ok('admin reject community', rj.s === 200, JSON.stringify(rj.j)?.slice(0, 250));
  }
  const st = await call('GET', '/admin/dashboard/stats', TA);
  ok('admin dashboard stats', st.s === 200, JSON.stringify(st.j)?.slice(0, 200));

  // --- public
  for (const p of ['/public/areas', '/public/statistics', '/public/service-summary', '/public/service-breakdown'])
    ok(`public ${p} 200 w/o token`, (await call('GET', p)).s === 200);

  console.log(`\n${pass} passed, ${fail} failed`);
  process.exit(fail ? 1 : 0);
})().catch(e => { console.error(e); process.exit(2); });
