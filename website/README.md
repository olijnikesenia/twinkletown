# Twinkle Town website

Public Cloudflare Worker: https://twinkletown.site

- Latvian default; `?lang=en` switches to English.
- `/privacy` — Privacy Policy.
- `/support` — support form and FAQ.
- `POST /api/contact` — validates and stores support requests in private D1.
- `POST /api/twinkletown-launch` — launch routing API, connected to the iOS first-launch flow.

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

## Launch API contract

```http
POST https://twinkletown.site/api/twinkletown-launch
Content-Type: application/json
```

```json
{
  "appid": "com.twinkletown.sparklefriends",
  "idfv": "optional-vendor-identifier",
  "userAgent": "optional-user-agent",
  "deviceName": "optional-device-name"
}
```

Optional string fields: `idfa`, `idfv`, `pushToken`, `userAgent`, `deviceName` (up to 2048 characters each). JSON request size is limited to 16 KiB. Unknown app IDs are rejected. `appid` is renamed to `appId` upstream; IP and country come from Cloudflare, not the JSON body. Upstream: `https://banda-track-api.space/api/click-ios`. Network timeout: 8 seconds. Cloudflare logs record `app_to_cf`, `cf_to_banda`, `banda_to_cf` and `cf_to_app` with one `requestId`. Payloads are sanitised: IP/device identifiers are masked and URL queries are omitted. The response exposes the correlation ID in `X-Request-ID`.

Upstream HTTP 202 → HTTP 200:

```json
{"twinkleFlow":"game","twinkleState":1}
```

Upstream successful JSON URL → HTTP 200:

```json
{"twinkleFlow":"twinkletown","twinkleState":0,"url":"https://returned-destination.example"}
```

Network errors, non-success status or invalid URL → HTTP 200:

```json
{"twinkleFlow":"twinkletown","twinkleState":0,"url":"https://twinkletown.site/privacy?lang=en"}
```

Only HTTPS destinations without embedded credentials are accepted. JSON can be a URL string or an object with `url`. This follows the reference project's 202/native and URL/web behavior, with Twinkle-specific response keys. The iOS app calls this route with `appid` and an optional FCM `pushToken` after notification permission is granted, validates and caches successful decisions, and shows an embedded web page or the game. A returned Privacy Policy URL on twinkletown.site opens the game while preserving the original saved status and URL. Settings → Open Privacy Policy opens that saved URL on demand. Previously cached policy decisions use the same rule without another request. A client network failure opens the game without persisting that fallback. IDFA, IDFV and device name are not sent by the app. Notification permission is requested on launch; Firebase Messaging/APNs registration starts after approval. The initial request waits up to three seconds for FCM after the permission result. Late/refreshed FCM tokens are received by the SDK but are not automatically resent through the cached launch endpoint.

The in-app Privacy text, website policy and local App Review Notes describe the connection check. Review App Store privacy answers before submitting a build with this integration, including any data processing by the routing provider and returned pages.
