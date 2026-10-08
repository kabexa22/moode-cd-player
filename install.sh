#!/bin/bash
# moode-cd-player installer (unofficial add-on for moOde audio player)
# License: GPL-3.0-or-later
set -e

LIB=/usr/local/lib/moode-cd-player
RULE=/etc/udev/rules.d/99-moode-cd-player.rules
DROPIN_DIR=/etc/systemd/system/mpd.service.d
DROPIN=$DROPIN_DIR/moode-cd-player.conf
SRC_DIR="$(cd "$(dirname "$0")" && pwd)/src"

ok()   { echo -e "\e[32m[OK]\e[0m $*"; }
warn() { echo -e "\e[33m[!]\e[0m $*"; }
fail() { echo -e "\e[31m[ERROR]\e[0m $*"; exit 1; }

[ "$(id -u)" -eq 0 ] || fail "Run with sudo: sudo ./install.sh"
[ -f /var/www/inc/mpd.php ] || fail "moOde audio player not detected."
[ -f "$SRC_DIR/moode-cd-player.py" ] || fail "Files not found in $SRC_DIR"
for d in /var/lib/mpd/music /var/lib/mpd/playlists /var/local/www/imagesw/playlist-covers /var/local/www/imagesw/thmcache; do
    [ -d "$d" ] || fail "Expected moOde directory not found: $d"
done
ok "moOde detected"

# MPD must support audio CD (cdio_paranoia)
mpd --version 2>/dev/null | grep -q "cdda://" || fail "This MPD build has no audio CD support (cdio_paranoia)."
ok "MPD supports audio CD"

# Dependencies (install only; never upgrade existing packages)
echo "Installing dependencies..."
apt-get install -y --no-install-recommends --no-upgrade \
    cdparanoia python3-libdiscid python3-musicbrainzngs python3-requests > /dev/null
ok "Dependencies installed"

# Files
install -d "$LIB"
install -m 755 "$SRC_DIR/moode-cd-player.py" "$LIB/"
install -m 755 "$SRC_DIR/moode-cd-player.sh" "$LIB/"
ok "Scripts installed in $LIB"

# MPD access to the drive
usermod -aG cdrom mpd
install -d "$DROPIN_DIR"
printf "[Service]\nSupplementaryGroups=cdrom\n" > "$DROPIN"
systemctl daemon-reload
systemctl restart mpd
ok "MPD can access the CD drive"

# udev rule (insert/eject)
echo 'SUBSYSTEM=="block", KERNEL=="sr[0-9]*", ACTION=="change", RUN+="/usr/bin/systemd-run --no-block '"$LIB"'/moode-cd-player.sh /dev/%k"' > "$RULE"
udevadm control --reload-rules
ok "udev rule installed"

# Power warning for Raspberry Pi 5
MODEL=$(tr -d '\0' < /proc/device-tree/model 2>/dev/null || true)
if [[ "$MODEL" == *"Raspberry Pi 5"* ]]; then
    if ! vcgencmd get_config usb_max_current_enable 2>/dev/null | grep -q "=1"; then
        warn "Raspberry Pi 5: USB ports are limited to 600 mA without the official 27W PSU."
        warn "A bus-powered CD drive may stutter. Use a powered USB hub, the official PSU,"
        warn "or add 'usb_max_current_enable=1' to /boot/firmware/config.txt and reboot."
    fi
fi

# Process a disc already in the drive
if ls /dev/sr[0-9]* > /dev/null 2>&1; then
    DEV=$(ls /dev/sr[0-9]* | head -n 1)
    systemd-run --no-block "$LIB/moode-cd-player.sh" "$DEV" > /dev/null 2>&1 || true
    ok "Drive found: $DEV"
else
    warn "No CD drive found right now. Connect it and insert a disc."
fi

echo
ok "Done. Insert an audio CD, wait ~20 s and press Play in moOde."
echo "    Log: /var/log/moode-cd-player.log"
