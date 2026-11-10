What is the maximum file size for API calls in the Vaultwarden

invitations false , signon false, sso_signon true - users can crate account using sso, also and invite user to organizations (to invite users must be already created their accounts)

By default the API calls are limited to 10MB. (JSON)

```
    config.temp_dir = canonicalize(CONFIG.tmp_folder()).unwrap().into();
    config.cli_colors = false; // Make sure Rocket does not color any values for logging.
    config.limits = Limits::new()
        .limit("json", 20.megabytes()) // 20MB should be enough for very large imports, something like 5000+ vault entries
        .limit("data-form", 525.megabytes()) // This needs to match the maximum allowed file size for Send
        .limit("file", 525.megabytes()); // This needs to match the maximum allowed file size for attachments

```

access token full logged in nginx (disable access logs and error logs)
token check after copy as cookies

did not work when i changed the user
Setting up Fail2ban will prevent attackers to brute force your vault logins.
Switch Your KDF to Argon2id

- The number of hours after which an organization invite token, emergency access invite token,email verification token and deletion request token will expire (must be at least 1) = INVITATION_EXPIRATION_HOURS=120

attachment encryption

### does user deletion by admin delete his data

- Account recovery administration (only available if mail is enabled) https://bitwarden.com/help/policies/#account-recovery-administration

- what happen when user lost their 2 factor auth device

- Emergency access

- change algoritham from, user settings argo2

- add 2 factor authentication , recovery code

- SSO_ALLOW_UNKNOWN_EMAIL_VERIFICATION: "false"

- need a good smtp

- log file remove? storage problem

- enforce https
