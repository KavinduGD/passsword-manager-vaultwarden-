Vaultwarden supports configuring settings through two methods:

1. Environment variables – Defined in docker-compose.yml or .env.
2. Admin panel – Configured through the web-based /admin interface.
   However, when both are configured, Vaultwarden's config.json takes precedence over environment variables for settings managed by the admin panel.

** verify this**
