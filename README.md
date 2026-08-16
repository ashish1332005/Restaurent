# Atithi Restaurant SaaS

Multi-tenant restaurant platform with customer QR ordering, restaurant operations, SaaS Super Admin, subscription management and verified Razorpay customer payments.

## Production architecture

- `restaurant-app-main`: Flutter web application served by Nginx.
- `restaurant-backend-main`: Node.js API and authenticated Socket.IO server.
- MongoDB Atlas or another replica-set MongoDB deployment. Transactions used by billing and inventory do not work on a standalone MongoDB server.
- A TLS reverse proxy or managed load balancer exposes the frontend and API over HTTPS.

## Required production configuration

1. Copy `deployment.env.example` to a root `.env` file and set the public API URL. The URL must end in `/api/v1`.
2. Configure `restaurant-backend-main/.env` from its `.env.example`.
3. Use a strong unique JWT secret and production MongoDB credentials.
4. Set `CORS_ORIGIN` to the exact frontend HTTPS origin. Multiple origins are comma separated; do not use `*` in production.
5. Configure Razorpay live keys only after test-mode verification.
6. Keep every `.env` file outside version control and in the deployment secret manager where available.

Minimum backend values:

```env
NODE_ENV=production
PORT=5000
MONGO_URI=mongodb+srv://...
JWT_SECRET=<strong-random-secret>
JWT_EXPIRE=7d
CORS_ORIGIN=https://app.example.com
RAZORPAY_ENABLED=true
RAZORPAY_KEY_ID=...
RAZORPAY_KEY_SECRET=...
RAZORPAY_WEBHOOK_SECRET=...
```

## Docker deployment

From the repository root:

```powershell
Copy-Item deployment.env.example .env
# Edit .env and restaurant-backend-main/.env with production values.
docker compose -f docker-compose.production.yml config
docker compose -f docker-compose.production.yml build
docker compose -f docker-compose.production.yml up -d
docker compose -f docker-compose.production.yml ps
```

The default ports bind to `127.0.0.1` so they are not directly exposed to the internet. Route public HTTPS traffic through a reverse proxy:

- `https://app.example.com` → `127.0.0.1:8080`
- `https://api.example.com` → `127.0.0.1:5000`

The proxy must support WebSocket upgrades for Socket.IO.

## Razorpay webhook

Create a Razorpay webhook for `payment_link.paid`:

```text
https://api.example.com/api/v1/payments/razorpay/webhook
```

The Dashboard webhook secret must exactly match `RAZORPAY_WEBHOOK_SECRET`. Never use the API key secret as the webhook secret.

## Release verification

Set the deployed URLs and run the non-destructive smoke suite:

```powershell
$env:SMOKE_BACKEND_URL='https://api.example.com'
$env:SMOKE_FRONTEND_URL='https://app.example.com'
$env:SMOKE_TABLE_QR_CODE='<active-test-table-token>' # optional
npm --prefix restaurant-backend-main run smoke:production
```

Optional admin authentication can be tested by setting `SMOKE_ADMIN_PHONE` and `SMOKE_ADMIN_PASSWORD`. Tokens and secrets are never printed.

The smoke suite checks health, database readiness, security headers, CORS, webhook rejection, API 404 behavior, public frontend routes and the optional QR contract.

## Backups and rollback

- Enable automated MongoDB backups and test restoration before launch.
- Record the deployed image tag and Flutter build commit for every release.
- Before a schema-changing release, take an on-demand database snapshot.
- Roll back by redeploying the previous immutable image tags; do not overwrite or delete production data.
- Rotate credentials immediately if a secret is exposed in source control, logs or chat.

## Operational endpoints

- API liveness: `/health`
- API and database readiness: `/ready`
- Frontend container health: `/health`

Do not place credentials, customer data or payment payloads in public logs.