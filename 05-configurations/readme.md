# Configuration overview

Vaultwarden supports configuring settings through two methods:

1. Environment variables – Defined in docker-compose.yml or .env.
2. Admin panel – Configured through the web-based /admin interface.
   However, when both are configured, Vaultwarden's config.json takes precedence over environment variables for settings managed by the admin panel.

** verify this**

## How to configure Vaultwarden

There are basically three different ways to configure Vaultwarden:

- setting up environment variables,
- using an ENV_FILE and
- via a config.json, not recommended (which can be generated and managed via the admin page).

---

- **You can find a documented list of most configuration options in the .env.template file. Typically the commented values will indicate the default values but that is not a guarantee. In case it's not, the source of truth will be src/config.rs.** https://github.com/dani-garcia/vaultwarden/blob/main/src/config.rs
- If you enable the admin page, you can also see the configuration options with the configured values (and if you are using config.json an indication whether the value has been changed from the initial value).
- Be aware that the config.json file is NOT the recommended way to configure your settings! Either use environment variables which you can configure in several ways for your container environment (Docker, Docker-Compose, K8s etc..) Or, when using a standalone binary (not distributed by Vaultwarden itself) use a .env file located in your current working directory.
- The settings in config.json will override any other configuration method and you will be warned on startup which settings have been overwritten by config.json.
- Since this generated config.json will include all editable options when saved, be aware that once you generate the configuration file via the /admin page, you cannot modify those options via any of the other methods (at least not without modifying or removing the config.json file).
- Some environment variables are not part of Vaultwardens configuration system and therefore cannot be set via config.json (e.g. ROCKET_ADDRESS or ROCKET_PORT).

### Configuration precedence

- On compilation the defaults are hard coded via src/config.rs.
- Those defaults can be changed without recompiling the binary by providing an ENV_FILE and also
- by setting the environment variables (which will overrule settings in the ENV_FILE).
- The end user (with access to /admin panel) optionally can create a config.json which will take the highest precedence.

---

## Configurations

## SIGNUPS_ALLOWED , INVITATIONS_ALLOWED

After users are invited, they can register with the invited email even if SIGNUPS_ALLOWED is actually set to false

## SSO

### SSO_ENABLED

- ables or disables OpenID Connect authentication. This is the master switch for SSO.
- true - Users can authenticate using an OIDC identity provider
- false - SSO authentication is disabled

### SSO_ONLY

- Determines whether users must authenticate through SSO instead of using the normal Vaultwarden login method.
- true - Users must authenticate through SSO (but also at the master password after sso, SSO in mandatory)
- false - Users can use normal authentication (can log only with Master password ) or SSO (If user went with SSO, they will still need to enter their master password after SSO authentication)

### SSO_SIGNUPS_ALLOWED

- Controls whether a new Vaultwarden account can be created through the SSO authentication flow.
- SSO_SIGNUPS_ALLOWED=false (New accounts cannot be created through SSO.Need a invitation to create an account)

### SSO_SIGNUPS_MATCH_EMAIL

- Determines whether Vaultwarden should associate an SSO identity with an existing Vaultwarden account when their email addresses match.
- This setting is particularly important when migrating from traditional authentication to SSO.
- Consider this example. You already have a Vaultwarden account:

```
Email: employee@company.com
Authentication: Master password
Vault data: Existing passwords and secure notes
```

- Later, you enable Microsoft SSO.
- when SSO_SIGNUPS_MATCH_EMAIL=true, Vaultwarden can associate the Microsoft identity with the existing Vaultwarden account based on the matching email address, subject to its email verification checks.

### SSO_ALLOW_UNKNOWN_EMAIL_VERIFICATION

- Controls whether Vaultwarden accepts an SSO identity when the email verification status is unknown.
- Controls whether Vaultwarden accepts an SSO identity when the email verification status is unknown.
- First, understand that an identity provider can provide an email address along with information about whether that email address has been verified.
- For example, Microsoft might provide identity information containing:

```
{
  "email": "employee@company.com",
  "email_verified": true
}
```

- The email_verified claim indicates that the identity provider considers the email address verified.
- However, sometimes the verification status might be missing or unknown.
- when SSO_ALLOW_UNKNOWN_EMAIL_VERIFICATION=false, Vaultwarden does not allow an unknown email-verification status to satisfy the verification requirement for automatically matching an existing account.
