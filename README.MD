# Rclone Dropbox Mount mit Samba unter Linux

## Inhaltsverzeichnis
- [Einleitung](#einleitung)
- [Voraussetzungen](#voraussetzungen)
- [Schritt 0: Dropbox-Gruppe und Benutzer einrichten](#schritt-0-dropbox-gruppe-und-benutzer-einrichten)
- [Schritt 1: Rclone Installation](#schritt-1-rclone-installation)
- [Schritt 2: Dropbox Remote einrichten](#schritt-2-dropbox-remote-einrichten)
- [Schritt 3: Systemd-Service für automatisches Mounten](#schritt-3-systemd-service-für-automatisches-mounten)
- [Schritt 4: Mount-Punkt Berechtigungen](#schritt-4-mount-punkt-berechtigungen)
- [Schritt 5: Samba konfigurieren](#schritt-5-samba-konfigurieren)
- [Fehlerbehebung](#fehlerbehebung)
- [Test und Nutzung](#test-und-nutzung)
- [FAQ](#faq)

## Einleitung
Diese Anleitung zeigt, wie man Dropbox unter Linux mit **rclone** mountet, die Berechtigungen für die Gruppe `dropbox` setzt und den Mount über **Samba** für Netzwerkbenutzer freigibt. Sie behandelt auch typische Probleme wie Token-Autorisierung, FUSE-Zugriffsrechte und Schreibrechte über SMB.

## Voraussetzungen
- Linux-System (z. B. Linux Mint, Raspberry Pi OS)
- Samba installiert: `sudo apt install samba`
- Rclone installiert: `sudo apt install rclone`
- Benutzer `pi` oder andere Netzwerkbenutzer

## Schritt 0: Dropbox-Gruppe und Benutzer einrichten
1. Gruppe `dropbox` erstellen:
```bash
sudo groupadd dropbox
````

2. Benutzer zu dieser Gruppe hinzufügen:

```bash
sudo usermod -aG dropbox pi
sudo usermod -aG dropbox dein Benutzer
```

> Hinweis: Alle Benutzer, die über Samba auf Dropbox zugreifen sollen, müssen Mitglied dieser Gruppe sein.

## Schritt 1: Rclone Installation

```bash
curl https://rclone.org/install.sh | sudo bash
rclone version
```

## Schritt 2: Dropbox Remote einrichten

1. Konfiguration starten:

```bash
rclone config
```

2. Neues Remote anlegen:

```
n) New remote
name> Dropbox
Storage> 9 (Dropbox)
client_id> [leer lassen für Standard]
client_secret> [leer lassen für Standard]
Edit advanced config? (y/n) n
Use auto config? y
```

**Hinweis:** Falls der Browser nicht automatisch öffnet oder Token nicht abgeholt werden kann, wähle `n` und führe auf einem Gerät mit Browser aus:

```bash
rclone authorize "dropbox"
```

Dann das JSON-Ergebnis in rclone config einfügen.

3. Remote testen:

```bash
rclone lsd Dropbox:
```

## Schritt 3: Systemd-Service für automatisches Mounten

1. Service-Datei erstellen:

```bash
sudo nano /etc/systemd/system/rclone-dropbox.service
```

2. Inhalt einfügen (ganze Zeile für ExecStart):

```ini
[Unit]
Description=Mount Dropbox via rclone
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/bin/rclone mount Dropbox: /media/dropbox --config /home/pi/.config/rclone/rclone.conf --vfs-cache-mode writes --allow-other --uid 0 --gid 1006 --umask 0002
ExecStop=/bin/fusermount -uz /media/dropbox
Restart=always
RestartSec=10
StartLimitIntervalSec=0

[Install]
WantedBy=multi-user.target
```

> Hinweis: `--gid 1006` muss die GID der Gruppe `dropbox` sein. Prüfen mit `getent group dropbox`.

3. Service aktivieren und starten:

```bash
sudo systemctl daemon-reload
sudo systemctl enable rclone-dropbox.service
sudo systemctl start rclone-dropbox.service
systemctl status rclone-dropbox.service
```

## Schritt 4: Mount-Punkt Berechtigungen

```bash
sudo mkdir -p /media/dropbox
sudo chown root:dropbox /media/dropbox
sudo chmod 2775 /media/dropbox
```

* SetGID (`2`) → neue Dateien erben automatisch die Gruppe `dropbox`
* FUSE konfigurieren:

```bash
sudo nano /etc/fuse.conf
# Zeile sicherstellen:
user_allow_other
```

## Schritt 5: Samba konfigurieren

1. Samba-Share hinzufügen:

```bash
sudo nano /etc/samba/smb.conf
```

```ini
[dropbox]
   path = /media/dropbox
   browseable = yes
   writable = yes
   valid users = dein Benutzer, pi
   force group = dropbox
   create mask = 0664
   directory mask = 2775
   read only = no
```

2. Samba-User prüfen oder hinzufügen:

```bash
sudo smbpasswd -a dein Benutzer
sudo smbpasswd -a pi
```

3. Samba neu starten:

```bash
sudo systemctl restart smbd nmbd
```

## Fehlerbehebung

| Problem                                        | Lösung                                                                                                                         |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| Browser öffnet sich nicht bei rclone authorize | Auf anderem Gerät `rclone authorize "dropbox"` ausführen, JSON in config einfügen                                              |
| Schreibrechte über SMB fehlen                  | rclone mit `--allow-other --uid 0 --gid 1006 --umask 0002` mounten, SetGID auf `/media/dropbox`, Samba `force group = dropbox` |
| Mount-Punkt leer oder Socket getrennt          | `sudo systemctl restart rclone-dropbox.service`                                                                                |
| Samba zeigt alte Rechte                        | `sudo systemctl restart smbd nmbd`                                                                                             |

## Test und Nutzung

* Prüfen, ob Dropbox gemountet ist:

```bash
ls -l /media/dropbox
```

* Test über SMB-Client:

```
\\<RaspberryPi-IP>\dropbox
```

* Testdatei schreiben → sollte funktionieren
* Mount automatisch beim Boot: Service ist bereits enabled

## FAQ

**F: Warum kann ich über SSH schreiben, aber über SMB nicht?**
**A:** Dateien gehören root:dropbox, Samba-Benutzer muss Mitglied der Gruppe dropbox sein und `--allow-other` sowie SetGID/umask korrekt gesetzt sein.

**F: Was tun, wenn rclone hängt oder der Mount weg ist?**
**A:** Service neu starten:

```bash
sudo systemctl restart rclone-dropbox.service
```

Ende der Anleitung ✅
Jetzt ist Dropbox stabil gemountet und über SMB für alle Netzwerkbenutzer zugänglich.

