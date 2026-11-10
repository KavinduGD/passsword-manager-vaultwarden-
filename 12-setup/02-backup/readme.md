# Backup Setup

- for active database do not just copy the database file, use the .backup command in the SQLite CLI (sqlite3) to back up the database file. (which SQLite documents as the best way to back up a database file that may be in active use.)
- before tunning the backup.sh need to have sqlite3
- currently we do not copy the db.sqlite3-wal file (change this if needed)
- we copy db.sqlite3, attachments, sends, config.json, rsa_key.pem
