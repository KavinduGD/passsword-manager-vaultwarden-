
#!/bin/bash

set -Eeuo pipefail

# Configuration
SOURCE_DIR="$HOME/vaultwarden/vw-data"
BACKUP_DIR="$HOME/vaultwarden/backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

DEST_DIR="$BACKUP_DIR/$TIMESTAMP"

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
    echo "ERROR: Source directory does not exist."
    exit 1
fi

# Create backup directory
mkdir -p "$DEST_DIR"

echo "[1/3] Backing up SQLite database..."

# SQLite online backup (includes committed WAL transactions)
sqlite3 "$SOURCE_DIR/db.sqlite3" ".backup '$DEST_DIR/db.sqlite3'"

echo "[2/3] Copying attachments and sends..."

cp -a "$SOURCE_DIR/attachments" "$DEST_DIR/"
cp -a "$SOURCE_DIR/sends" "$DEST_DIR/"

echo "[3/3] Copying configuration and RSA key..."

cp -a "$SOURCE_DIR/config.json" "$DEST_DIR/"
cp -a "$SOURCE_DIR/rsa_key.pem" "$DEST_DIR/"

echo "======================================"
echo " Backup completed successfully!"
echo "======================================"

echo "Backup location: $DEST_DIR"

echo ""
echo "Backup contents:"
du -sh "$DEST_DIR"
ls -lah "$DEST_DIR"
