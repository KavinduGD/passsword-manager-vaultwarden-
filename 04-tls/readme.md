# HTTPS

There are a few ways you can enable HTTPS:

- (Recommended) Put vaultwarden behind a reverse proxy that handles HTTPS connections on behalf of vaultwarden.
- (Not recommended) Enable the HTTPS functionality built into vaultwarden (via the Rocket web framework). Rocket's HTTPS implementation is relatively immature and limited.

For an HTTPS server to work, it also needs an SSL/TLS certificate, so you'll need to decide how to obtain this. Again, there are a few options:

- (Recommended) Get Let's Encrypt certificates using an ACME client. Some reverse proxies (e.g., Caddy) also have built-in support for obtaining certs using the ACME protocol.
- (Recommended) If you trust Cloudflare to proxy your traffic, you can let them handle issuance of your SSL/TLS certs. Note that the upstream Bitwarden web vault (https://vault.bitwarden.com/) runs behind Cloudflare.
- (Not recommended) Set up a private CA and issue your own (self-signed) certificates. There are various pitfalls and inconveniences associated with this, so consider yourself warned.

url: https://github.com/dani-garcia/vaultwarden/wiki/Enabling-HTTPS
