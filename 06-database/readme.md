# Database

- The SQLite backend is the most widely used/tested, and recommended for most users unless there is a specific need to use a different database backend.

## Available Database Backends

- SQLite (default)
- MySQL / MariaDB
- PostgreSQL

## Database Configuration

By default during the startup vaultwarden will try to enable WAL for the DB. Adding this improves performance and in the past helped preventing failed requests under some circumstances.

url: https://github.com/dani-garcia/vaultwarden/wiki/Running-without-WAL-enabled
