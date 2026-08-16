# Production deployment

## Backend

Build from `restaurant-backend-main/Dockerfile`. Configure these runtime variables:

- `NODE_ENV=production`
- `PORT` (the platform may inject it)
- `MONGO_URI` (MongoDB replica set/Atlas is required for transactions)
- `JWT_SECRET` (random, at least 32 characters)
- `JWT_EXPIRE=7d`
- `CORS_ORIGIN=https://your-frontend-domain.example`

Health checks: `/health` for liveness and `/ready` for MongoDB readiness.

## Flutter web

`API_BASE_URL` is a compile-time Docker build argument and must include `/api/v1`.

```powershell
docker build --build-arg API_BASE_URL=https://api.example.com/api/v1 -t restaurant-web ./restaurant-app-main
docker build -t restaurant-api ./restaurant-backend-main
```

Optional web OAuth build arguments: `GOOGLE_CLIENT_ID` and `GOOGLE_SERVER_CLIENT_ID`.
The Nginx configuration includes Flutter SPA fallback, so `/admin` and `/super-admin` work after browser refresh.

## Final domain pairing

Backend `CORS_ORIGIN` must exactly match the deployed frontend origin. Do not use `*` in production. Serve both applications over HTTPS. Never commit the real `.env` file.

## Non-mutating production smoke test

After both domains are deployed, set `SMOKE_BACKEND_URL` and `SMOKE_FRONTEND_URL`, then run from `restaurant-backend-main`:

```powershell
npm run smoke:production
```

Optional `SMOKE_ADMIN_PHONE` and `SMOKE_ADMIN_PASSWORD` add login/profile verification. The script never prints the token and does not create or update application data.
