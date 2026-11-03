## Backup

Things to include in your backup:

- The environment file used when starting Vaultwarden
- The `data` directory
- The Vaultwarden database
  - Use the database backup features of MariaDB/PostgreSQL/MySQL/SQLite to create a backup

Make sure you document the procedure and locations where backups are stored!

## Restore

- Install Vaultwarden
- Restore your database from backup
- Restore the environment file
- Restore your `data` directory to the correct location

## Backing up data

- By default, vaultwarden stores all of its data under a directory called data (in the same directory as the vaultwarden executable).
- This location can be changed by setting the DATA_FOLDER environment variable.
- If you run vaultwarden with SQLite (this is the most common setup), then the SQL database is just a file in the data folder.
- When running with MySQL or PostgreSQL backends, the directory structure is the same, except there are no SQLite files. You'll still want to back up files in the data directory, as well as a dump of your MySQL or PostgreSQL tables.

### SQLite database files

- **Backup required**
- The SQLite database file (db.sqlite3) stores almost all important vaultwarden data/state (database entries, user/org/device metadata, etc.), with the main exception being attachments, which are stored as separate files on the filesystem.
- Copy both db.sqlite3, db.sqlite3-wal. (db.sqlite3-shm is not needed for backup, but it can be copied if you want to be thorough.)
- You should generally use the .backup command in the SQLite CLI (sqlite3) to back up the database file. (which SQLite documents as the best way to back up a database file that may be in active use.)
- Also you can use docker exec -it vaultwarden /vaultwarden backup
- **Do not copy the database file while vaultwarden is running**. If you do, you may end up with a corrupted backup.

### The attachments dir

- **Backup required**
- File attachments are the only important class of data not stored in database tables, mainly because they can be arbitrarily large, and SQL databases generally aren't designed to handle large blobs efficiently

### The sends dir

- **Backup optional**
- Backup optional.

### The config.json file

- **Backup recommended**
- If you use the admin page to configure your vaultwarden instance and don't have your configuration backed up some other way, then you probably want to back up this file so you don't have to figure out your preferred configuration all over again

### The rsa_key\* files

- **Backup recommended.**
- These files are used to sign the JWTs (authentication tokens) of users currently logged in. Deleting them would simply log out each user, forcing them to log in again and it would also invalidate any open invitation tokens that have been sent via mail.

### The icon_cache dir

- The icon cache stores website icons so that they don't need to be fetched from the login site repeatedly. It's probably not worth backing up unless you really want to avoid refetching a large cache of icons.

---

## Restoring backup data

- Make sure vaultwarden is stopped, and then simply replace each file or directory in the data dir with its backed up version.
