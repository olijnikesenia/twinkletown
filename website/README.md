# Twinkle Town website

Public Cloudflare Worker: https://twinkletown.site

- Latvian default; `?lang=en` switches to English.
- `/privacy` — Privacy Policy.
- `/support` — support form and FAQ.
- `POST /api/contact` — validates and stores support requests in private D1.
- `POST /api/launcher` — retained server endpoint; the iOS app does not call it.
- `POST /api/twinkletown-launch` — temporary compatibility alias for earlier builds.

No runtime dependencies. Screenshots are compressed WebP files, served as embedded Worker assets. Cloudflare R2 was not enabled in this account; it is not needed for this site. No Cloudflare or S3 credentials are stored in the repository.

## Local development

```sh
cd website
npm run build
npm test
npm run dev
```

Preview runs at http://localhost:4173. The local preview has no production D1 binding; support writes return 503 locally. Tests use a fake binding; production saving has also been checked against D1.

To redeploy: `npm run build`, then use the official Wrangler CLI with `CLOUDFLARE_API_TOKEN` supplied securely through your environment. Run `wrangler deploy` from this directory. The `RATE_LIMIT_SALT` secret already exists on the deployed Worker; preserve it. Never put access tokens in frontend files or commit them.

## Support inbox

Cloudflare dashboard → Workers & Pages → D1 → `twinkletown-support` → Console:

```sql
SELECT id, email, topic, message, locale,
       datetime(created_at / 1000, 'unixepoch') AS submitted_utc,
       notified
FROM support_requests
ORDER BY created_at DESC
LIMIT 100;
```

Owner: Pedro Lord. Contact: info@pedrolord8578w.site.

Requests are stored immediately. Daily cleanup at 03:00 UTC deletes requests older than 90 days and rate-limit entries older than 24 hours. D1 backups/time-travel are controlled separately by Cloudflare. There is no public endpoint exposing submissions.

Email notifications are implemented but not enabled: supply a `RESEND_API_KEY` secret and `CONTACT_FROM_EMAIL` from a verified Resend sender/domain. Notifications go to `info@pedrolord8578w.site`; a provider outage does not discard the stored request. No notification delivery was claimed or tested without these credentials.

## Retained launch endpoint

POST `/api/launcher` (alias `/api/twinkletown-launch`) accepts `appid`, `requestId` (install UUID from the Keychain) and optional `pushToken`. The Worker forwards the unchanged payload to Banda, waits (8 s timeout) and keeps Banda's URL only for HTTP 200 + `https:` + `hostname === "twinkletown.site"`; everything else resolves to `https://twinkletown.site/privacy?lang=en`.

The endpoint remains deployed for compatibility and diagnostics, but current iOS builds do not call it.

Server secrets and variables are managed in Cloudflare and are not bundled with the app.

The app opens the game directly. Privacy Policy and Website are available from Settings in the existing embedded browser.
