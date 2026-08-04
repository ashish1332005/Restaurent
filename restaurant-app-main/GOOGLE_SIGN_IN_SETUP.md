# Google Sign-In configuration

Google Cloud Console must contain OAuth clients for the app package
`com.restaurant.restaurant_automation` and its Android signing SHA-1/SHA-256.

1. Put the Web OAuth client ID in the backend environment as `GOOGLE_CLIENT_ID`.
2. Use that same Web client ID as the mobile server client ID.
3. Start Flutter with:

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID
```

For Flutter Web, also pass:

```bash
--dart-define=GOOGLE_CLIENT_ID=YOUR_WEB_CLIENT_ID
```

The backend and Flutter client IDs must match so the backend can verify the
Google ID-token audience.
