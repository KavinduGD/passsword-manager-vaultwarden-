I'll give you a Docker Compose deployment with the following architecture:

- Vaultwarden: Password manager running in Docker.
- Nginx: Reverse proxy handling HTTP and HTTPS.
- Let's Encrypt + Certbot: Automatically provides free SSL certificates.
- Docker volumes: Persist Vaultwarden data and SSL certificates.

Your domain:

`vault.sri-lankan-parliment-shooter-mini-game.website`

## Deployment architecture

Internet / Client

HTTPS · Port 443

Nginx Reverse Proxy

SSL termination · HTTP → HTTPS redirect

Vaultwarden

Docker internal network · Port 80

Certbot manages Let's Encrypt certificates.

## 1. Project structure

Create a directory:

```
mkdir -p ~/vaultwarden/{nginx/conf.d,certbot/www,certbot/conf,vw-data}
cd ~/vaultwarden
```

Your directory structure:

```
vaultwarden/
├── docker-compose.yml
├── .env
├── nginx/
│   └── conf.d/
│       └── vaultwarden.conf
├── certbot/
│   ├── conf/
│   └── www/
└── vw-data/
```

- ** we need to change the vw-data directory permission to 1000:1000 because the vaultwarden container runs as user 1000. Otherwise, it will not be able to write to the data directory.**

```bash
sudo chown -R 1000:1000 vw-data
```

## 2. Docker Compose

Create `docker-compose.yml`:

````yaml
services:
  vaultwarden:
    image: vaultwarden/server:1.37.5-alpine
    container_name: vaultwarden
    user: 1000:1000
    restart: unless-stopped
    environment:
      # Domain settings
      ## The domain must match the address from where you access the server
      ## It's recommended to configure this value, otherwise certain functionality might not work,
      ## like attachment downloads, email links and U2F.
      ## For U2F to work, the server must use HTTPS, you can use Let's Encrypt for free certs
      ## To use HTTPS, the recommended way is to put Vaultwarden behind a reverse proxy
      DOMAIN: "https://vault.sri-lankan-parliment-shooter-mini-game.website"

      ## Controls if new users can register
      ##   SIGNUPS_ALLOWED must be false because we use SSO only
      SIGNUPS_ALLOWED: "false"

      SHOW_PASSWORD_HINT: "false"

      ## Controls if new users need to verify their email address upon registration
      ## On new client versions, this will require the user to verify their email at signup time.
      ## On older clients, it will require the user to verify their email before they can log in.
      ## The welcome email will include a verification link, and login attempts will periodically
      ## trigger another verification email to be sent.
      ## need to have SIGNUPS_ALLOWED set to true for this to have any effect
      ## Only happen when try to create an account with an email address. Not happen when try to create account from invitation
      # SIGNUPS_VERIFY: false

      ## If SIGNUPS_VERIFY is set to true, this limits how many seconds after the last time
      ## an email verification link has been sent another verification email will be sent
      # SIGNUPS_VERIFY_RESEND_TIME: 60

      ## If SIGNUPS_VERIFY is set to true, this limits how many times an email verification
      ## email will be re-sent upon an attempted login.
      # SIGNUPS_VERIFY_RESEND_LIMIT: 100

      ## INVITATIONS_ALLOWED can be false can still logged in users can be invited
      INVITATIONS_ALLOWED: "false"
      ## Enable websocket notifications
      ENABLE_WEBSOCKET: "true"

      # ==========================Admin Panel=============================
      ## Token for the admin interface, preferably an Argon2 PCH string
      ## Vaultwarden has a built-in generator by calling `vaultwarden hash`
      ## For details see: https://github.com/dani-garcia/vaultwarden/wiki/Enabling-admin-page#secure-the-admin_token
      ## If not set, the admin panel is disabled
      ## New Argon2 PHC string
      ## Note that for some environments, like docker-compose you need to escape all the dollar signs `$` with an extra dollar sign like `$$`
      ## Also, use single quotes (') instead of double quotes (") to enclose the string when needed
      ## Old plain text string (Will generate warnings in favor of Argon2)
      ADMIN_TOKEN: "${ADMIN_TOKEN}"

      ## Set the lifetime of admin sessions to this value (in minutes).
      # ADMIN_SESSION_LIFETIME=20

      ## Controls whether users can enable emergency access to their accounts.
      ## This setting applies globally to all users.
      # EMERGENCY_ACCESS_ALLOWED=true

      # ==========================Logs=============================
      ## Logging to file
      LOG_FILE: "/data/vaultwarden.log"

      ## Enable extended logging, which shows timestamps and targets in the logs
      EXTENDED_LOGGING: "true"

      ## Logging to Syslog
      ## This requires extended logging
      USE_SYSLOG: "true"

      # ==========================SMTP=============================
      SMTP_HOST: "smtp.gmail.com"
      SMTP_PORT: "587"
      SMTP_SECURITY: "starttls"
      SMTP_FROM: "kavidudharmasiri90@gmail.com"
      SMTP_FROM_NAME: "Vaultwarden"
      SMTP_USERNAME: "kavidudharmasiri90@gmail.com"
      SMTP_PASSWORD: "${SMTP_PASSWORD}"

      # ==========================Network=============================
      # Vaultwarden listens on port 80 inside its container.

      # ==========================SSO=================================

      # ### SSO_ENABLED

      # - ables or disables OpenID Connect authentication. This is the master switch for SSO.
      # - true - Users can authenticate using an OIDC identity provider
      # - false - SSO authentication is disabled

      # ### SSO_ONLY

      # - Determines whether users must authenticate through SSO instead of using the normal Vaultwarden login method.
      # - true - Users must authenticate through SSO (but also at the master password after sso, SSO in mandatory)
      # - false - Users can use normal authentication (can log only with Master password ) or SSO (If user went with SSO, they will still need to enter their master password after SSO authentication)

      # ### SSO_SIGNUPS_ALLOWED

      # - Controls whether a new Vaultwarden account can be created through the SSO authentication flow.
      # - SSO_SIGNUPS_ALLOWED=false (New accounts cannot be created through SSO.Need a invitation to create an account)

      # ### SSO_SIGNUPS_MATCH_EMAIL

      # - Determines whether Vaultwarden should associate an SSO identity with an existing Vaultwarden account when their email addresses match.
      # - This setting is particularly important when migrating from traditional authentication to SSO.
      # - Consider this example. You already have a Vaultwarden account:

      # ```
      # Email: employee@company.com
      # Authentication: Master password
      # Vault data: Existing passwords and secure notes
      # ```

      # - Later, you enable Microsoft SSO.
      # - when SSO_SIGNUPS_MATCH_EMAIL=true, Vaultwarden can associate the Microsoft identity with the existing Vaultwarden account based on the matching email address, subject to its email verification checks.

      # ### SSO_ALLOW_UNKNOWN_EMAIL_VERIFICATION

      # - Controls whether Vaultwarden accepts an SSO identity when the email verification status is unknown.
      # - Controls whether Vaultwarden accepts an SSO identity when the email verification status is unknown.
      # - First, understand that an identity provider can provide an email address along with information about whether that email address has been verified.
      # - For example, Microsoft might provide identity information containing:

      # ```
      # {
      #   "email": "employee@company.com",
      #   "email_verified": true
      # }
      # ```

      # - The email_verified claim indicates that the identity provider considers the email address verified.
      # - However, sometimes the verification status might be missing or unknown.
      # - when SSO_ALLOW_UNKNOWN_EMAIL_VERIFICATION=false, Vaultwarden does not allow an unknown email-verification status to satisfy the verification requirement for automatically matching an existing account.

      SSO_ENABLED: "true"
      SSO_ONLY: "true"
      SSO_SIGNUPS_ALLOWED: "true"
      SSO_SIGNUPS_MATCH_EMAIL: "true"
      #  SSO_ALLOW_UNKNOWN_EMAIL_VERIFICATION must be false
      SSO_ALLOW_UNKNOWN_EMAIL_VERIFICATION: "false"

      SSO_AUTHORITY: "https://login.microsoftonline.com/02069dfb-a6ec-40f7-b2e2-c11c3ab010b5/v2.0"
      SSO_SCOPES: "openid profile email offline_access User.Read"
      SSO_CLIENT_ID: "${SSO_CLIENT_ID}"
      SSO_CLIENT_SECRET: "${SSO_CLIENT_SECRET}"
    volumes:
      # Mount the persistent data directory to /data inside the container
      - ./vw-data:/data
      # required for syslog logging
      - /dev/log:/dev/log
    networks:
      - vaultwarden-network

  nginx:
    image: nginx:stable-alpine
    container_name: vaultwarden-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./certbot/www:/var/www/certbot:ro
      - ./certbot/conf:/etc/letsencrypt:ro
    depends_on:
      - vaultwarden
    networks:
      - vaultwarden-network

  certbot:
    image: certbot/certbot:latest
    container_name: vaultwarden-certbot
    restart: unless-stopped
    volumes:
      - ./certbot/www:/var/www/certbot
      - ./certbot/conf:/etc/letsencrypt
    entrypoint: /bin/sh
    command: >
      -c 'trap exit TERM;
      while :; do
        certbot renew --webroot -w /var/www/certbot;
        sleep 12h;
      done'

networks:
  vaultwarden-network:
    driver: bridge
````

## 3. Environment variables

Generate a secure admin token:

```

echo -n 'MySecretPassword' | argon2 "$(openssl rand -base64 32)" -e -id -k 65540 -t 3 -p 4
# use single quotes (') instead of double quotes (") to enclose the string when needed

```

Create `.env`:

```

ADMIN_TOKEN=PASTE_YOUR_GENERATED_TOKEN_HERE
SMTP_PASSWORD=YOUR_SMTP_PASSWORD
SSO_CLIENT_ID=YOUR_SSO_CLIENT_ID
SSO_CLIENT_SECRET=YOUR_SSO_CLIENT_SECRET
```

Protect the file:

```

chmod 600 .env

```

Keep this token private. It protects the Vaultwarden administration panel at `/admin`.

## 4. Configure Nginx

Create:

`nginx/conf.d/vaultwarden.conf`

We need to obtain the initial SSL certificate before enabling the HTTPS configuration. So first, use this temporary HTTP-only configuration.

Initial configuration:

```

server {
listen 80;
listen [::]:80;

    server_name vault.sri-lankan-parliment-shooter-mini-game.website;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        proxy_pass http://vaultwarden:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

}

```

Start the containers:

```

docker compose up -d

```

## 5. Obtain the HTTPS certificate

Before running Certbot, make sure:

- Your domain's DNS A record points to your server's public IP.
- Port 80 is accessible from the internet.
- Port 443 is allowed through your firewall/security group.

Run:

```

docker compose run --rm \
--entrypoint certbot \
certbot certonly \
--webroot \
-w /var/www/certbot \
-d vault.sri-lankan-parliment-shooter-mini-game.website \
--email kavidudharmasiri90@gmail.com \
--agree-tos \
--no-eff-email

```

Replace `YOUR_EMAIL_ADDRESS` with your email address.

If successful, certificates will be generated at:

```

certbot/conf/live/vault.sri-lankan-parliment-shooter-mini-game.website/
├── fullchain.pem
└── privkey.pem

```

SSL certificate obtained

## 6. Replace Nginx configuration with HTTPS

Now replace your temporary `vaultwarden.conf` with this production configuration:

```
server_names_hash_bucket_size 128;

upstream vaultwarden-default {
    zone vaultwarden-default 64k;
    server vaultwarden:80;
    keepalive 2;
}

map $http_upgrade $connection_upgrade {
    default upgrade;
    '' "";
}

# HTTP to HTTPS redirect
server {
    listen 80;
    listen [::]:80;

    server_name vault.sri-lankan-parliment-shooter-mini-game.website;

    access_log off;
    error_log /dev/null emerg;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

# Reject direct IP access and unknown HTTPS hostnames
server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;

    server_name _;

    access_log off;
    error_log /dev/null emerg;

    ssl_reject_handshake on;
}

# HTTPS server
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;

    server_name vault.sri-lankan-parliment-shooter-mini-game.website;

    access_log off;
    error_log /dev/null emerg;

    ssl_certificate /etc/letsencrypt/live/vault.sri-lankan-parliment-shooter-mini-game.website/fullchain.pem;

    ssl_certificate_key /etc/letsencrypt/live/vault.sri-lankan-parliment-shooter-mini-game.website/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;

    client_max_body_size 525M;

    proxy_http_version 1.1;

    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    location / {
        proxy_pass http://vaultwarden-default;

        # Increase upstream response header buffers
        proxy_buffer_size 16k;
        proxy_buffers 8 16k;
        proxy_busy_buffers_size 32k;
    }
}
```

Restart Nginx:

```

docker compose exec nginx nginx -t
docker compose restart nginx

```

Your Vaultwarden instance should now be accessible through:

`https://vault.sri-lankan-parliment-shooter-mini-game.website`

## 7. Configure automatic certificate renewal

Let's Encrypt certificates are valid for 90 days.

Your Certbot container already runs renewal checks every 12 hours. However, Nginx must reload after a certificate is renewed.

Add a host cron job:

```

crontab -e

```

Add:

```

0 _/12 _ \* \* cd /home/ubuntu/vaultwarden && docker compose exec -T certbot certbot renew --webroot -w /var/www/certbot && docker compose exec -T nginx nginx -s reload

```

Change `/home/ubuntu/vaultwarden` to your actual deployment directory.

This checks for renewals every 12 hours and reloads Nginx afterward.

## 8. Verify deployment

Run these commands:

Check containers:

```

docker compose ps

```

Check Nginx configuration:

```

docker compose exec nginx nginx -t

```

Check Vaultwarden logs:

```

docker compose logs -f vaultwarden

```

Check SSL certificate:

```

openssl s_client \
-connect vault.sri-lankan-parliment-shooter-mini-game.website:443 \
-servername vault.sri-lankan-parliment-shooter-mini-game.website

```

## Important security recommendations

1. Keep `SIGNUPS_ALLOWED=false` after creating your account.
2. Never expose Vaultwarden's internal port directly to the internet.
3. Keep `ADMIN_TOKEN` secret and use a strong token (preferably an Argon2 PHC hash for production).
4. Back up the entire `vw-data` directory and your `.env` file securely.
5. Keep Docker images updated.

Expected result

| Component   | Port | Exposure                |
| ----------- | ---- | ----------------------- |
| Nginx HTTP  | 80   | Public                  |
| Nginx HTTPS | 443  | Public                  |
| Vaultwarden | 80   | Internal Docker network |
| Certbot     | None | Internal                |

One important note: If you are using Cloudflare, make sure the DNS record points to your server and that Cloudflare's proxy configuration permits the HTTP-01 certificate challenge. You can initially use DNS-only mode while obtaining the certificate.
