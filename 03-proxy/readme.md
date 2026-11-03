## Vaultwarden Reverse Proxy – Summary

1\. Use a Reverse Proxy (Recommended)

- Vaultwarden recommends using a reverse proxy to handle TLS/SSL.
- Prefer HTTPS on port `443` (standard HTTPS port).
- Avoid using Vaultwarden's built-in HTTPS functionality where possible.

2\. Vaultwarden and Reverse Proxy Setup

- The examples assume Vaultwarden and the reverse proxy run on the same host.
- Vaultwarden listens on port `80` inside the container.
- The container port is exposed to the host using:
  ```
  -p 127.0.0.1:8000:80
  ```
- Vaultwarden should listen on all IPv4 interfaces inside the container:
  ```
  ROCKET_ADDRESS=0.0.0.0
  ROCKET_PORT=80
  ```

3\. Communication Between Reverse Proxy and Vaultwarden

- By default, the reverse proxy connects to Vaultwarden using HTTP:
  ```
  http://127.0.0.1:8000
  ```
- This assumes `ROCKET_TLS` is not configured.
- TLS termination happens at the reverse proxy.

4\. Docker Compose Considerations

- If Vaultwarden and the reverse proxy run in separate Docker containers on the same Docker network, use the service name instead of `127.0.0.1`.
- Example:
  ```
  http://vaultwarden:80
  ```

5\. Supported Reverse Proxies

&#x20; Vaultwarden provides community-contributed configuration examples for:

- Caddy 2.x
- Nginx
- Nginx with sub-path
- Apache
- Traefik v2
- HAProxy
- HAProxy Kubernetes Ingress
- Istio Kubernetes
- Cloudflare Tunnel
- lighttpd
- Pound

6\. TLS/SSL Configuration

- Use secure TLS protocols and cipher configurations.
- TLSref's TLS Configurator can generate recommended configurations.
- The recommended Modern configuration is compatible with supported browsers and Bitwarden mobile apps.

url: https://github.com/dani-garcia/vaultwarden/wiki/Proxy-examples
