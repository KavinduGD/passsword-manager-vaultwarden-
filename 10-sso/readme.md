# SSO

- A master password will still be required and not controlled by the SSO (depending on your point of view this might be a feature ;).
- This introduces another way to control who can use the vault without having to use invitation or using an LDAP.
- The callback URL is automatically generated from the DOMAIN. If you set DOMAIN=https://vaultwarden.example.tld your callback URL will be https://vaultwarden.example.tld/identity/connect/oidc-signin.

---

## Microsoft Entra ID

- Create an "App registration" in Entra ID following Identity | Applications | App registrations.
- From the "Overview" of your "App registration", you'll need the "Directory (tenant) ID" for the SSO_AUTHORITY variable and the "Application (client) ID" as the SSO_CLIENT_ID value.
- In "Certificates & Secrets" create an "App secret" , you'll need the "Secret Value" for the SSO_CLIENT_SECRET variable.
- In "Authentication" add https://vaultwarden.example.tld/identity/connect/oidc-signin as "Web Redirect URI".
- In "API Permissions" make sure you have profile, email and offline_access listed under "API / Permission name" (offline_access is required, otherwise no refresh_token is returned, see https://github.com/MicrosoftDocs/azure-docs/issues/17134).
- Only the v2 endpoint is compliant with the OpenID spec, see https://github.com/MicrosoftDocs/azure-docs/issues/38427 and https://github.com/ramosbugs/openidconnect-rs/issues/122.

Your configuration should look like this:

- SSO_AUTHORITY=https://login.microsoftonline.com/${Directory_ID}/v2.0 #tenant
- SSO_SCOPES=openid profile offline_access User.Read
- SSO_CLIENT_ID=${Application_ID} #client
- SSO_CLIENT_SECRET=${Secret_Value}

url: https://github.com/dani-garcia/vaultwarden/wiki/Enabling-SSO-support-using-OpenId-Connect
