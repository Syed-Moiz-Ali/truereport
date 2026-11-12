# Web URL Strategy

The TrueReport Flutter web apps (`platform_admin_app`, `workshop_admin_app`) use
**path-based URLs** instead of hash-based URLs.

| Before                | After              |
| --------------------- | ------------------ |
| `/#/workshops`        | `/workshops`       |
| `/#/workshops/42`     | `/workshops/42`    |

This is enabled in `lib/main.dart` via `configureWebUrlStrategy()`, which calls
`usePathUrlStrategy()` from `package:flutter_web_plugins/url_strategy.dart` on
web builds (and is a no-op on other platforms via a conditional import).

## Server rewrite requirement

Because paths such as `/workshops/42` do not exist as files on disk, the hosting
server **MUST rewrite unknown paths to `index.html`**. Without this rewrite,
deep links and page refreshes will return **404 Not Found** (the app only works
when navigating from the root URL).

The rewrite must not apply to existing static assets (JS, CSS, images, fonts);
serve those normally, and fall back to `index.html` for everything else.

### Nginx

```nginx
server {
    listen 80;
    server_name admin.example.com;
    root /var/www/truereport-admin;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### Firebase Hosting (`firebase.json`)

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

### Netlify (`_redirects` in the publish directory)

```text
/*    /index.html   200
```

### Apache (`.htaccess` in the document root)

```apache
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase /
    RewriteRule ^index\.html$ - [L]
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule . /index.html [L]
</IfModule>
```

## Notes

- The rewrite is required for **both** apps individually; each deployment target
  needs the same configuration.
- If a CDN or reverse proxy sits in front of the origin, ensure it forwards the
  path unchanged and does not cache 404 responses for app routes.
- Update saved links and bookmarks to the path form (`/workshops` instead of
  `/#/workshops`). Path URLs are the canonical form for both apps.
