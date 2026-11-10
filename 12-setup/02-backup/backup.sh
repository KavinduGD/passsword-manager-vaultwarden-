
#!/bin/bash

set -Eeuo pipefail

# Configuration
SOURCE_DIR="/opt/vaultwarden/vw-data"
BACKUP_DIR="/opt/vaultwarden/backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

DEST_DIR="$BACKUP_DIR/$TIMESTAMP"

# Restrict backup permissions
umask 077

echo "======================================"
echo " Starting Vaultwarden Backup"
echo "======================================"

# Check dependencies
if ! command -v sqlite3 >/dev/null 2>&1; then
    echo "ERROR: sqlite3 is not installed."
    exit 1
fi

# Check source directory
if [ ! -d "$SOURCE_DIR" ]; then
    echo "ERROR: Source directory does not exist: $SOURCE_DIR"
    exit 1
fi

# Check database
if [ ! -f "$SOURCE_DIR/db.sqlite3" ]; then
    echo "ERROR: Vaultwarden database not found."
    exit 1
fi

# Create backup directory
mkdir -p "$DEST_DIR"

echo "[1/3] Backing up SQLite database..."

# SQLite online backup (includes committed WAL transactions)
sqlite3 "$SOURCE_DIR/db.sqlite3" ".backup '$DEST_DIR/db.sqlite3'"

echo "[2/3] Copying attachments and sends..."

for item in attachments sends; do
    if [ -e "$SOURCE_DIR/$item" ]; then
        cp -a "$SOURCE_DIR/$item" "$DEST_DIR/"
    fi
done

echo "[3/3] Copying configuration and RSA key..."

for item in config.json rsa_key.pem; do
    if [ -f "$SOURCE_DIR/$item" ]; then
        cp -a "$SOURCE_DIR/$item" "$DEST_DIR/"
    fi
done

echo "======================================"
echo " Backup completed successfully!"
echo "======================================"

echo "Backup location: $DEST_DIR"

echo ""
echo "Backup contents:"
du -sh "$DEST_DIR"
ls -lah "$DEST_DIR"
