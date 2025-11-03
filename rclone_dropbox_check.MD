 Ein script der Prüft, ob der rclone-Mount noch aktiv ist, und ihn bei Bedarf neu startet.

Hier ist ein fertiges Beispiel, das du einfach als `/usr/local/bin/rclone_dropbox_check.sh` speichern kannst:

```bash
#!/bin/bash
# rclone_dropbox_check.sh
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
```

---

### **Anleitung zur Nutzung**

1. Skript erstellen:

```bash
sudo nano /usr/local/bin/rclone_dropbox_check.sh
```

* Inhalt einfügen, speichern und schließen.

2. Ausführbar machen:

```bash
sudo chmod +x /usr/local/bin/rclone_dropbox_check.sh
```

3. Optional: Cronjob einrichten, damit das Skript alle 5 Minuten läuft:

```bash
sudo crontab -e
```

* Folgende Zeile hinzufügen:

```
*/5 * * * * /usr/local/bin/rclone_dropbox_check.sh >> /var/log/rclone_dropbox_check.log 2>&1
```

* Das schreibt die Logs in `/var/log/rclone_dropbox_check.log` und prüft alle 5 Minuten den Mount.

---