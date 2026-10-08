#!/usr/bin/env python3
# moode-cd-player - Audio CD playback for moOde audio player (unofficial)
# Copyright (C) 2026  moode-cd-player contributors
# License: GPL-3.0-or-later (see LICENSE)
#
# On CD insert: identifies the disc on MusicBrainz, loads the moOde queue
# with title/artist/album tags (without starting playback), writes a "CD"
# playlist and downloads the cover from the Cover Art Archive.
# On CD eject: removes the playlist/cover and clears the queue if it only
# contains CD tracks.

import os
import re
import socket
import subprocess
import sys
import tempfile

VERSION = "1.0.0"
REPO_URL = "https://github.com/kabexa22/moode-cd-player"

DEV = sys.argv[1] if len(sys.argv) > 1 else "/dev/sr0"
PLAYLIST = "/var/lib/mpd/playlists/CD.m3u"
COVER = "/var/local/www/imagesw/playlist-covers/CD.jpg"
MPD_HOST, MPD_PORT = "127.0.0.1", 6600

socket.setdefaulttimeout(10)


def q(value):
    """Quote an argument for the MPD protocol."""
    return '"' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"'


class MPD:
    def __init__(self):
        self.sock = socket.create_connection((MPD_HOST, MPD_PORT))
        self.f = self.sock.makefile("rwb")
        self.f.readline()  # greeting

    def cmd(self, command):
        self.f.write((command + "\n").encode())
        self.f.flush()
        out = []
        while True:
            line = self.f.readline().decode("utf-8", "replace").rstrip("\n")
            if line == "OK":
                return out
            if line.startswith("ACK") or line == "":
                print("MPD error:", command, line)
                return out
            out.append(line)

    def close(self):
        self.sock.close()


def count_tracks():
    r = subprocess.run(["cdparanoia", "-d", DEV, "-Q"], capture_output=True, text=True)
    return len(re.findall(r"^\s+\d+\.", r.stdout + r.stderr, re.M))


def lookup():
    """Return {mbid, artist, album, titles} from MusicBrainz, or None."""
    try:
        import libdiscid
        import musicbrainzngs
        disc = libdiscid.read(DEV)
        musicbrainzngs.set_useragent("moode-cd-player", VERSION, REPO_URL)
        res = musicbrainzngs.get_releases_by_discid(disc.id, includes=["artists", "recordings"])
        for rel in res.get("disc", {}).get("release-list", []):
            for medium in rel.get("medium-list", []):
                if any(d.get("id") == disc.id for d in medium.get("disc-list", [])):
                    titles = [t.get("title") or t["recording"]["title"]
                              for t in medium.get("track-list", [])]
                    return {"mbid": rel["id"],
                            "artist": rel.get("artist-credit-phrase", ""),
                            "album": rel.get("title", ""),
                            "titles": titles}
        print("Disc not found on MusicBrainz:", disc.id)
    except Exception as e:
        print("Lookup error:", e)
    return None


def atomic_write(path, data, mode):
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path))
    with os.fdopen(fd, "wb") as f:
        f.write(data)
    os.chmod(tmp, mode)
    os.replace(tmp, path)


def remove(*paths):
    for p in paths:
        if os.path.exists(p):
            os.remove(p)


def get_cover(mbid):
    try:
        import requests
        r = requests.get(f"https://coverartarchive.org/release/{mbid}/front-500",
                         headers={"User-Agent": f"moode-cd-player/{VERSION} ({REPO_URL})"},
                         timeout=15)
        if r.ok:
            atomic_write(COVER, r.content, 0o644)
            return
        print("No cover art:", r.status_code)
    except Exception as e:
        print("Cover error:", e)
    remove(COVER)


def title_for(i, info):
    if info and i <= len(info["titles"]):
        return info["titles"][i - 1]
    return f"Track {i}"


def load_queue(n, info):
    m = MPD()
    m.cmd("clear")
    for i in range(1, n + 1):
        r = m.cmd(f"addid {q(f'cdda:///{i}')}")
        sid = next((l.split(": ", 1)[1] for l in r if l.startswith("Id:")), None)
        if not sid:
            continue
        m.cmd(f"addtagid {sid} Title {q(title_for(i, info))}")
        m.cmd(f"addtagid {sid} Track {i}")
        if info:
            m.cmd(f"addtagid {sid} Artist {q(info['artist'])}")
            m.cmd(f"addtagid {sid} Album {q(info['album'])}")
    m.close()


def clear_if_cd():
    try:
        m = MPD()
        files = [l[6:] for l in m.cmd("playlistinfo") if l.startswith("file: ")]
        if files and all(f.startswith("cdda://") for f in files):
            m.cmd("clear")
        m.close()
    except Exception as e:
        print("Queue clear error:", e)


def main():
    n = count_tracks()
    if n == 0:
        remove(PLAYLIST, COVER)
        clear_if_cd()
        return

    info = lookup()
    lines = ["#EXTM3U"]
    for i in range(1, n + 1):
        lines += [f"#EXTINF:-1,{i:02d}. {title_for(i, info)}", f"cdda:///{i}"]
    atomic_write(PLAYLIST, ("\n".join(lines) + "\n").encode(), 0o666)

    if info:
        get_cover(info["mbid"])
    else:
        remove(COVER)

    load_queue(n, info)
    print(f"Loaded {n} tracks", f"({info['artist']} - {info['album']})" if info else "(no metadata)")


if __name__ == "__main__":
    main()
