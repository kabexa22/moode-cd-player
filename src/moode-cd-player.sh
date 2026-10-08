#!/bin/bash
# moode-cd-player launcher - called by udev (via systemd-run) on CD insert/eject
# License: GPL-3.0-or-later

DEV="${1:-/dev/sr0}"
LIB=/usr/local/lib/moode-cd-player
LOG=/var/log/moode-cd-player.log

# Run one event at a time, in order
exec 9>/run/moode-cd-player.lock
flock 9

# Wait up to 20 s for the disc to be ready
for i in $(seq 1 10); do
    sleep 2
    cdparanoia -d "$DEV" -Q 2>&1 | grep -qE '^\s+[0-9]+\.' && break
done

echo "--- $(date '+%F %T') $DEV" >> "$LOG"
/usr/bin/python3 "$LIB/moode-cd-player.py" "$DEV" >> "$LOG" 2>&1
tail -n 500 "$LOG" > "$LOG.tmp" && mv -f "$LOG.tmp" "$LOG"

# Cover for moOde's playback view, queue thumbnails and playbar
SRC=/var/local/www/imagesw/playlist-covers/CD.jpg
HASH=$(php -r 'echo md5(dirname("cdda:///1"));')
THM="/var/local/www/imagesw/thmcache/$HASH"
DIR="/var/lib/mpd/music/cdda:"
mkdir -p "$DIR"
if [ -f "$SRC" ]; then
    cp -f "$SRC" "$DIR/folder.jpg"
    cp -f "$SRC" "$THM.jpg"
    cp -f "$SRC" "${THM}_sm.jpg"
else
    rm -f "$DIR/folder.jpg" "$THM.jpg" "${THM}_sm.jpg"
fi
