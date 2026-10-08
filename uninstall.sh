#!/bin/bash
# moode-cd-player uninstaller
# License: GPL-3.0-or-later

[ "$(id -u)" -eq 0 ] || { echo "Run with sudo: sudo bash uninstall.sh"; exit 1; }

rm -f /etc/udev/rules.d/99-moode-cd-player.rules
udevadm control --reload-rules

rm -f /etc/systemd/system/mpd.service.d/moode-cd-player.conf
rmdir --ignore-fail-on-non-empty /etc/systemd/system/mpd.service.d 2>/dev/null
systemctl daemon-reload
systemctl restart mpd

HASH=$(php -r 'echo md5(dirname("cdda:///1"));')
rm -f /var/lib/mpd/playlists/CD.m3u \
      /var/local/www/imagesw/playlist-covers/CD.jpg \
      "/var/local/www/imagesw/thmcache/$HASH.jpg" \
      "/var/local/www/imagesw/thmcache/${HASH}_sm.jpg"
rm -rf "/var/lib/mpd/music/cdda:"
rm -rf /usr/local/lib/moode-cd-player
rm -f /var/log/moode-cd-player.log /run/moode-cd-player.lock

echo "moode-cd-player removed."
echo "Dependencies were kept (cdparanoia, python3-libdiscid, python3-musicbrainzngs)."
echo "To remove them: sudo apt-get remove cdparanoia python3-libdiscid python3-musicbrainzngs"
