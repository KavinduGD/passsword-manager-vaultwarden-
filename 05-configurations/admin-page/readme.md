# Enabling admin page

- The Vaultwarden Admin panel allows a server administrator to configure Vaultwarden, view all the registered users and organizations and also to delete them.
- **It allows inviting new users even when registration has been disabled. And it provides a diagnostics page in which you can generate the Support String.**
- To enable the admin page you need to configure an authentication token. This token can be anything but it's recommended to use a long, randomly generated string of characters. For example by running openssl rand -base64 32.

url: https://github.com/dani-garcia/vaultwarden/wiki/Enabling-admin-page
