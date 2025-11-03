#!/bin/bash
# rclone-dropbox-check.sh
# Health-Check für rclone Dropbox Mount
# Prüft, ob /media/dropbox gemountet ist, startet Service neu wenn nicht

MOUNT_POINT="/media/dropbox"
SERVICE_NAME="rclone-dropbox.service"

# Prüfen, ob Mount aktiv ist
if mount | grep -q "$MOUNT_POINT"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Mount aktiv: $MOUNT_POINT"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') Mount nicht gefunden! Starte Service neu..."
    sudo systemctl restart $SERVICE_NAME
    sleep 2
    # Prüfen, ob der Neustart erfolgreich war
    if mount | grep -q "$MOUNT_POINT"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') Mount erfolgreich wiederhergestellt."
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') WARNUNG: Mount konnte nicht wiederhergestellt werden!"
    fi
fi
