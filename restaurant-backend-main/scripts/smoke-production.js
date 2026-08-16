const required = (name) => { const value = String(process.env[name] || '').trim().replace(/\/$/, ''); if (!value) throw new Error(`${name} is required`); return value; };
const request = async (url, options = {}) => { const controller = new AbortController(); const timer = setTimeout(() => controller.abort(), 10000); try { return await fetch(url, { ...options, signal: controller.signal }); } finally { clearTimeout(timer); } };
const pass = (name) => console.log(`PASS ${name}`);
(async () => {
  const backend = required('SMOKE_BACKEND_URL'), frontend = required('SMOKE_FRONTEND_URL');
  if (!/^https:\/\//.test(backend) || !/^https:\/\//.test(frontend)) throw new Error('Smoke URLs must use HTTPS');
  const health = await request(`${backend}/health`);
  if (health.status !== 200) throw new Error(`Health failed (${health.status})`);
  pass('backend health');
  if (!health.headers.get('x-content-type-options') || !health.headers.get('content-security-policy')) throw new Error('Security headers are missing');
  pass('Helmet security headers');
  const ready = await request(`${backend}/ready`);
  if (ready.status !== 200) throw new Error(`Readiness failed (${ready.status})`);
  pass('database readiness');
  const cors = await request(`${backend}/api/v1/auth/login`, { method: 'OPTIONS', headers: { Origin: frontend, 'Access-Control-Request-Method': 'POST' } });
  if (cors.headers.get('access-control-allow-origin') !== frontend) throw new Error('CORS origin mismatch');
  pass('CORS pairing');
  const unsignedWebhook = await request(`${backend}/api/v1/payments/razorpay/webhook`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: '{}' });
  if (unsignedWebhook.status !== 401) throw new Error(`Unsigned webhook was not rejected (${unsignedWebhook.status})`);
  pass('unsigned Razorpay webhook rejection');
  const unknownApi = await request(`${backend}/api/v1/does-not-exist`);
  if (unknownApi.status !== 404) throw new Error(`Unknown API did not return 404 (${unknownApi.status})`);
  pass('API 404 handling');
  for (const path of ['/', '/legal/privacy', '/legal/terms', '/offline']) {
    const page = await request(`${frontend}${path}`);
    if (page.status !== 200) throw new Error(`Frontend route ${path} failed (${page.status})`);
  }
  pass('frontend and public production routes');
  const qrCode = String(process.env.SMOKE_TABLE_QR_CODE || '').trim();
  if (qrCode) {
    const qr = await request(`${backend}/api/v1/qr/table/${encodeURIComponent(qrCode)}`);
    if (qr.status !== 200) throw new Error(`Public QR lookup failed (${qr.status})`);
    const body = await qr.json();
    if (!body.success || !body.data?.table || !Array.isArray(body.data?.menu)) throw new Error('Public QR response contract mismatch');
    pass('public QR table/menu contract');
  } else console.log('SKIP public QR contract: SMOKE_TABLE_QR_CODE not set');
  const phone = String(process.env.SMOKE_ADMIN_PHONE || '').trim(), password = String(process.env.SMOKE_ADMIN_PASSWORD || '');
  if (phone && password) {
    const login = await request(`${backend}/api/v1/auth/login`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ phone, password }) });
    const body = await login.json().catch(() => ({}));
    if (login.status !== 200 || !body.token) throw new Error(`Admin login failed (${login.status})`);
    const me = await request(`${backend}/api/v1/auth/me`, { headers: { Authorization: `Bearer ${body.token}` } });
    if (me.status !== 200) throw new Error(`Authenticated profile failed (${me.status})`);
    pass('admin authentication (token not printed)');
  } else console.log('SKIP admin authentication: smoke credentials not set');
  console.log('Production smoke test passed.');
})().catch((error) => { console.error(`FAIL ${error.message}`); process.exit(1); });