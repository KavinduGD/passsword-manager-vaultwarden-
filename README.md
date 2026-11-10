# Project Proposal: Enterprise Self-Hosted Password Management Infrastructure (Vaultwarden)

## 1. Executive Summary

### 1.1 Purpose & Problem Statement

In modern organizational environments, password management is one of the highest-risk operational security vulnerabilities. Without a centralized, secure credential management platform, organizations suffer from:

- Credential sprawl, insecure sharing (chat apps, spreadsheets, sticky notes).
- Weak, reused, and unrotated master passwords across critical systems.
- Unmonitored offboarding risks (departed personnel retaining credentials).
- High licensing costs associated with enterprise SaaS password managers ($4–$8/user/month).

### 1.2 Proposed Solution

This project establishes a **fully self-hosted, enterprise-hardened, zero-knowledge password management service** utilizing **Vaultwarden**, fully compatible with official Bitwarden desktop, mobile, CLI, and browser extensions.

Key capabilities delivered:

1. **Zero-Knowledge Cryptographic Architecture:** Passwords, notes, and attachments are encrypted client-side using **AES-CBC 256-bit with HMAC-SHA256 authentication**; the server never receives or stores plaintext credentials or master keys.
2. **Enterprise Single Sign-On (SSO):** Seamless user authentication integrated with **Microsoft Entra ID (Azure AD)** via OpenID Connect (OIDC v2), enforcing centralized identity governance while preserving client-side zero-knowledge encryption via user master passwords.
3. **Enterprise Organization & Sharing:** Secure password sharing using Organization Collections, Emergency Access contacts, and Bitwarden Send (time-limited, access-counted encrypted text and file drops).
4. **Negligible Infrastructure Overhead:** Written in Rust, Vaultwarden operates under **< 100 MB RAM** in production (compared to official Bitwarden's 4–8 GB RAM requirement for MSSQL and multiple .NET microservices).
5. **Zero Licensing Costs:** Eliminates per-seat licensing fees for premium features such as SSO, TOTP authenticator generation, file attachments, and organization sharing.
6. **Automated Maintenance & Disaster Recovery:** Non-blocking SQLite WAL online automated backups (`backup.sh`) and automated Let's Encrypt TLS renewal.

---

## 2. Business Case & Comparative Evaluation

A thorough evaluation was conducted against major market alternatives: official Bitwarden Self-Hosted and Passbolt.

### 2.1 Solution Comparison Matrix

| Feature / Capability              | Proposed Solution (Vaultwarden)                             | Bitwarden Official (Self-Hosted)               | Passbolt (Self-Hosted Community) |
| :-------------------------------- | :---------------------------------------------------------- | :--------------------------------------------- | :------------------------------- |
| **Upstream Client Compatibility** | **100% Native** (Bitwarden mobile, web, desktop, extension) | Native                                         | Passbolt-only apps               |
| **Azure AD / Entra ID SSO**       | **Supported Free (Built-in OIDC)**                          | Requires Enterprise Paid License               | Requires Pro / Enterprise Plan   |
| **Organization & Collections**    | **Included Free**                                           | Requires Paid Plan                             | Limited in Community             |
| **Built-in TOTP Authenticator**   | **Included Free**                                           | Requires Premium License ($/user)              | Paid / Extension                 |
| **Secure Send (Encrypted Drops)** | **Included Free**                                           | Requires Premium License ($/user)              | Not natively equivalent          |
| **File Attachments**              | **Supported (up to 525 MB)**                                | Requires Premium License                       | Community storage restrictions   |
| **Memory Footprint**              | **~50 MB – 150 MB RAM**                                     | **4 GB – 8 GB RAM** (MSSQL + 12 microservices) | ~1 GB – 2 GB RAM                 |
| **Database Engines**              | **SQLite (WAL)**, PostgreSQL, MariaDB                       | Microsoft SQL Server (Resource heavy)          | MySQL / MariaDB                  |
| **License & Recurring Fees**      | **\$0 (Open Source, AGPLv3)**                               | \$40 – \$72 / user / year                      | €39 – €59 / user / year          |

### 2.2 Cost-Benefit & TCO Summary

- **Annual License Savings:** \$0 annual recurring software cost vs. thousands of dollars annually for commercial enterprise tiers.
- **Hardware Efficiency:** Can operate comfortably on a shared low-cost VM or lightweight container instance (2 vCPUs, 1–2 GB RAM).

For detailed comparative research and screenshots, refer to:

- [`intro`](./00-intro/readme.md)

---

## 3. Security, Cryptography & Compliance Architecture

The security posture adheres to the **ISO 27001 ISMS standard** and Bitwarden Security Architecture principles.

### 3.1 Zero-Knowledge Encryption Flow

1. **Client-Side Key Derivation:** The user's Master Password never leaves the client device. It is combined with the user's email address as cryptographic salt using **PBKDF2-HMAC-SHA-256** (600,000 iterations default) or **Argon2id**.
2. **Master Key & HKDF:** A 256-bit Master Key is generated and stretched via HKDF to derive:
   - An encryption key for encrypting and decrypting vault data locally.
   - A secondary authentication hash transmitted over TLS to authenticate with the server.
3. **Data at Rest:** All credentials, usernames, notes, and file attachments are stored on the server exclusively as encrypted ciphertext (`AES-CBC 256-bit with HMAC integrity authentication`). Even with full server-level root access, an adversary cannot decrypt stored passwords.
4. **Key Upgrade to Argon2id:** The system supports user migration to **Argon2id** (memory-hard, GPU/ASIC crack-resistant KDF), significantly improving resilience against brute-force attacks.

For cryptographic analysis and upstream validation, refer to:

- [`encryption`](./08-encryption/encryption/readme.md)
- [`web-vault`](./08-encryption/web-vault/readme.md)

### 3.2 Single Sign-On (Microsoft Entra ID / Azure AD)

Enterprise identity management is implemented using OpenID Connect (v2 endpoint):

- **Centralized Deprovisioning:** When an employee is disabled or removed in Entra ID, access to Vaultwarden is immediately cut off.
- **Two-Tiered Authentication Barrier:** Even after successful SSO identity validation, users must unlock their local cryptographic vault with their Master Password, ensuring identity federation does not compromise zero-knowledge encryption.
- **SSO Parameters:**
  - `SSO_ENABLED=true`
  - `SSO_ONLY=true` (Disables standard password-only bypass)
  - `SSO_SIGNUPS_ALLOWED=true`
  - `SSO_SIGNUPS_MATCH_EMAIL=true`
  - `SSO_ALLOW_UNKNOWN_EMAIL_VERIFICATION=false` (Strict email verification enforcement)

For SSO configuration guidelines, refer to:

- [`sso`](./10-sso/readme.md)

### 3.3 Security Hardening & Threat Mitigation

The implementation applies strict defense-in-depth principles:

- **Registration & Invitation Lockdown:** `SIGNUPS_ALLOWED=false` and `INVITATIONS_ALLOWED=false` prevent rogue external account creation. Only administrators can issue authorized invites or onboard through Entra ID.
- **Strict SNI & Direct IP Handshake Rejection:** Nginx rejects unauthenticated TLS connections hitting raw IP addresses (`ssl_reject_handshake on`).
- **Access Token Sanitation in Logs:** WebSockets pass ephemeral JWT tokens via URL query parameters (`/notifications/hub?access_token=...`). Nginx access logs are suppressed or sanitized to prevent credential leakages into logging sinks.
- **Non-Root Execution:** Vaultwarden containers run with an unprivileged user (`user: 1000:1000`).
- **Argon2 PHC Admin Token:** The administrative portal (`/admin`) is secured using an Argon2id PHC password hash (`ADMIN_TOKEN`), preventing unauthorized access.
- **Disabled Password Hints:** `SHOW_PASSWORD_HINT=false` stops metadata leaks.

For the comprehensive hardening policy, refer to:

- [`09-securiy/readme.md`](./09-securiy/readme.md)
- [`05-configurations/admin-page/readme.md`](./05-configurations/admin-page/readme.md)

---

## 4. Technical Architecture & Deployment Options

Two production deployment options have been implemented and validated in this repository:

### 4.1 Deployment Architecture Diagram

### 4.2 Architecture Option 1: Docker Compose + Nginx + Certbot (Standard Production)

- **Container Stack:**
  - `vaultwarden`: Alpine-based, port 80 internal network.
  - `nginx`: Reverse proxy with HTTP-to-HTTPS redirection, strict SNI, client payload handling up to 525 MB, and WebSocket upgrading.
  - `certbot`: Automated certificate renewal daemon running every 12 hours.
- **Configuration Files:**
  - Compose Definition: [`docker-compose.yaml`](./compose-files/nginx/docker-compose.yaml)
  - Nginx Server Config: [`nginx.conf`](./compose-files/nginx/nginx.conf)
  - Detailed Step-by-Step Runbook: [`steps.md`](./compose-files/nginx/stesps.md)

### 4.3 Architecture Option 2: MicroK8s Kubernetes + Ansible Automation (Enterprise Cluster)

- **Container Stack:**
  - MicroK8s Ingress Controller handling ingress traffic and TLS termination.
  - Cert-Manager `ClusterIssuer` automating ACME HTTP-01 challenges.
  - Automated deployment via Ansible playbooks (`vaultwarden.yml`).
- **Configuration Files:**
  - MicroK8s Compose: [`compose-files/microk8s/docker-compose.yaml`](./compose-files/microk8s/docker-compose.yaml)
  - Kubernetes Manifests: [`compose-files/microk8s/manifests/`](./compose-files/microk8s/manifests)
    - [`ingress.yaml`](./compose-files/microk8s/manifests/ingress.yaml)
    - [`issuer.yaml`](./compose-files/microk8s/manifests/issuer.yaml)
    - [`vaultwarden-service.yaml`](./compose-files/microk8s/manifests/vaultwarden-service.yaml)

### 4.4 Real-Time WebSocket Synchronization

- Native WebSocket support (`ENABLE_WEBSOCKET=true`) maintains real-time synchronisation between clients across devices (instant sync when a password is added, updated, or deleted without polling latency).

For configuration specifics, refer to:

- [`03-proxy/readme.md`](./03-proxy/readme.md)
- [`04-tls/readme.md`](./04-tls/readme.md)
- [`05-configurations/readme.md`](./05-configurations/readme.md)
- [`05-configurations/web-socket/readme.md`](./05-configurations/web-socket/readme.md)

---

## 5. Data Persistence, Backup & Disaster Recovery

### 5.1 Storage Engine: SQLite with WAL Mode

Vaultwarden utilizes SQLite with **Write-Ahead Logging (WAL)** enabled by default. WAL improves write concurrency, eliminates database locks, and guarantees ACID transaction safety under high multi-client load.

For database options, refer to:

- [`06-database/readme.md`](./06-database/readme.md)

### 5.2 Automated Non-Blocking Backup Strategy

Live database copying while SQLite is active can cause corrupt backups. Therefore, this repository includes an enterprise-ready, automated backup script utilizing SQLite's online backup API:

- Script: [`07-backup/backup.sh`](./07-backup/backup.sh)

```bash
# Automated Online Non-Blocking SQLite Backup
sqlite3 "$SOURCE_DIR/db.sqlite3" ".backup '$DEST_DIR/db.sqlite3'"
```

#### Backup Asset Inventory:

| Asset          | Criticality     | Purpose                                                                  |
| :------------- | :-------------- | :----------------------------------------------------------------------- |
| `db.sqlite3`   | **Critical**    | Core database (vault ciphers, user accounts, organizations, permissions) |
| `attachments/` | **Critical**    | Encrypted file attachments uploaded to vault items                       |
| `sends/`       | **Important**   | Ephemeral file drops created via Bitwarden Send                          |
| `config.json`  | **Recommended** | Runtime settings configured via Admin UI                                 |
| `rsa_key.pem`  | **Important**   | Private RSA signing key for active JWT tokens and email invites          |

### 5.3 Disaster Recovery & Cold Restore Procedure

To restore from backup:

1. Stop Vaultwarden container (`docker compose down`).
2. Restore `db.sqlite3`, `attachments/`, `sends/`, `config.json`, and `rsa_key.pem` to `./vw-data/`.
3. Verify file ownership (`chown -R 1000:1000 ./vw-data`).
4. Restart container (`docker compose up -d`).

For backup and restore procedures, refer to:

- [`07-backup/readme.md`](./07-backup/readme.md)

---

## 6. System Requirements & Operational Costs

Based on official benchmarks and guidance from Vaultwarden core maintainers:

```
"2 vCPUs, 1GB of RAM, and adequate attachment storage... Vaultwarden can operate with under 100MB RAM independently."
— BlackDex, Vaultwarden Core Contributor
```
