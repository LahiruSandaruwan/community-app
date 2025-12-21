# Build Configuration Guide

This document explains how to build EduConnect for different environments.

## Environment Variables

The app uses compile-time environment variables for configuration. These are set using the `--dart-define` flag.

### Available Variables

- `ENVIRONMENT` - Environment name (development, staging, production)
- `POCKETBASE_URL` - PocketBase server URL

## Building for Different Environments

### Development (Default)

Uses localhost PocketBase server:

```bash
flutter run
# or explicitly
flutter run --dart-define=ENVIRONMENT=development --dart-define=POCKETBASE_URL=http://127.0.0.1:8090
```

### Staging

```bash
flutter run --dart-define=ENVIRONMENT=staging --dart-define=POCKETBASE_URL=https://staging-api.educonnect.com

# Build APK
flutter build apk --release \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=POCKETBASE_URL=https://staging-api.educonnect.com

# Build App Bundle
flutter build appbundle --release \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=POCKETBASE_URL=https://staging-api.educonnect.com
```

### Production

```bash
flutter run --dart-define=ENVIRONMENT=production --dart-define=POCKETBASE_URL=https://api.educonnect.com

# Build APK
flutter build apk --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=POCKETBASE_URL=https://api.educonnect.com

# Build App Bundle (Google Play Store)
flutter build appbundle --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=POCKETBASE_URL=https://api.educonnect.com
```

## Safety Checks

The app includes built-in validation that will:

1. **Prevent production builds with localhost URL** - App will crash on startup if production environment uses localhost
2. **Require HTTPS in production** - Production builds must use HTTPS URLs
3. **Print configuration in debug mode** - Development/staging builds will print current configuration on startup

## Using Configuration Files

For convenience, you can create shell scripts for each environment:

### `scripts/run_dev.sh`
```bash
#!/bin/bash
flutter run \
  --dart-define=ENVIRONMENT=development \
  --dart-define=POCKETBASE_URL=http://127.0.0.1:8090
```

### `scripts/build_staging.sh`
```bash
#!/bin/bash
flutter build appbundle --release \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=POCKETBASE_URL=https://staging-api.educonnect.com
```

### `scripts/build_production.sh`
```bash
#!/bin/bash
flutter build appbundle --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=POCKETBASE_URL=https://api.educonnect.com
```

Make scripts executable:
```bash
chmod +x scripts/*.sh
```

## Verifying Configuration

When the app starts in development or staging mode, it will print the current configuration:

```
=== Environment Configuration ===
Environment: production
PocketBase URL: https://api.educonnect.com
Firebase Project: educonnect-prod
Debug Logs: false
Analytics: true
Crash Reporting: true
================================
```

## CI/CD Integration

Example GitHub Actions workflow:

```yaml
- name: Build Production APK
  run: |
    flutter build apk --release \
      --dart-define=ENVIRONMENT=production \
      --dart-define=POCKETBASE_URL=${{ secrets.POCKETBASE_URL }}
```

Store sensitive URLs in GitHub Secrets or your CI/CD platform's secret management.

## PocketBase Server Setup

Before deploying to production:

1. Set up PocketBase server with HTTPS (using nginx/Caddy as reverse proxy)
2. Configure CORS to allow your app's requests
3. Set up proper security rules in PocketBase
4. Enable SSL certificate (Let's Encrypt recommended)
5. Update the `POCKETBASE_URL` in your build commands

Example PocketBase deployment:
```bash
# On your server
./pocketbase serve --http=127.0.0.1:8090

# Nginx reverse proxy configuration
server {
    listen 443 ssl;
    server_name api.educonnect.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://127.0.0.1:8090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Troubleshooting

### App crashes on startup (production)

Check the error message. Common causes:
- Using localhost URL in production
- Using HTTP instead of HTTPS in production

### Configuration not updating

- Clean build artifacts: `flutter clean && flutter pub get`
- Ensure you're passing `--dart-define` flags correctly
- Check that environment variables don't have typos

### Cannot connect to PocketBase

- Verify the URL is correct and accessible
- Check network permissions in AndroidManifest.xml
- Verify CORS settings on PocketBase server
- Check if server is running and accessible from your device/emulator
