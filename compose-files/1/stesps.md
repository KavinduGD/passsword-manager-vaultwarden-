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

## 2. Docker Compose

Create `docker-compose.yml`:

```
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
    environment:
      DOMAIN: "https://vault.sri-lankan-parliment-shooter-mini-game.website"
      SIGNUPS_ALLOWED: "false"
      WEBSOCKET_ENABLED: "true"
      ADMIN_TOKEN: "${ADMIN_TOKEN}"
    volumes:
      - ./vw-data:/data
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
```

## 3. Environment variables

Generate a secure admin token:

```
openssl rand -base64 48
```

Create `.env`:

```
ADMIN_TOKEN=PASTE_YOUR_GENERATED_TOKEN_HERE
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

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;

    server_name vault.sri-lankan-parliment-shooter-mini-game.website;

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
0 */12 * * * cd /home/ubuntu/vaultwarden && docker compose exec -T certbot certbot renew --webroot -w /var/www/certbot && docker compose exec -T nginx nginx -s reload
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
