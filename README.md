# moode-cd-player

Audio CD playback for [moOde audio player](https://moodeaudio.org), with track titles, artist, album and cover art.

> **Unofficial project.** Not affiliated with or endorsed by moOde audio player. moOde™ is a trademark of its respective owner.

[Español](#español) · [English](#english)

---

## Español

### Qué hace

- Al insertar un CD de audio, carga la cola de moOde con los temas **sin reproducir**: le das Play cuando quieras.
- Identifica el disco en [MusicBrainz](https://musicbrainz.org) y muestra **título, artista y álbum**.
- Descarga la **carátula** desde [Cover Art Archive](https://coverartarchive.org) y la muestra en la pantalla de reproducción, en las miniaturas de la cola y en la playlist **CD**.
- Al expulsar el disco, limpia la cola (solo si contiene temas del CD) y borra la playlist y la carátula.
- Sin internet, o si el disco no está en MusicBrainz, funciona igual con los temas numerados.

**No modifica ningún archivo de moOde**: solo agrega un script, una regla de udev y un permiso para MPD. Las actualizaciones de moOde no lo afectan.

### Requisitos

- moOde audio player con MPD compilado con soporte de CD (`cdio_paranoia`). Probado en moOde sobre Debian Trixie, Raspberry Pi 5.
- Lectora de CD/DVD USB.
- Conexión a internet para títulos y carátulas (opcional).

### Instalación

```bash
git clone https://github.com/kabexa22/moode-cd-player.git
cd moode-cd-player
sudo bash install.sh
```

### Uso

1. Insertá un CD de audio y esperá unos 20 segundos.
2. En moOde aparecen los temas en la cola. Dale **Play**.

Si la Pi arranca con un CD ya puesto, sacalo y volvelo a insertar.

### Raspberry Pi 5 y alimentación

Sin la fuente oficial de 27 W, la Pi 5 limita los puertos USB a 600 mA. Una lectora alimentada por USB puede cortarse o tardar en arrancar. Opciones:

- Fuente oficial Raspberry Pi 27 W (recomendado).
- Hub USB con alimentación propia para la lectora.
- Agregar `usb_max_current_enable=1` en `/boot/firmware/config.txt` y reiniciar (solo si tu fuente entrega 5 A reales).

### Limitaciones

- Reproducción directa desde el disco: el inicio y el cambio de tema pueden tardar unos segundos.
- Debajo de la carátula moOde muestra "File does not exist". Es solo visual.
- En **Library → Folders** aparece una carpeta `cdda:`. La usa el complemento para la carátula: no la borres.
- Si cargás el disco desde **Playlists → CD**, se reproduce pero sin títulos. Usá la cola que se carga sola al insertar.

### Desinstalación

```bash
sudo bash uninstall.sh
```

### Diagnóstico

```bash
sudo tail -n 20 /var/log/moode-cd-player.log
```

---

## English

### What it does

- On audio CD insert, loads the moOde queue with the tracks **without starting playback**.
- Identifies the disc on [MusicBrainz](https://musicbrainz.org) and shows **title, artist and album**.
- Downloads the **cover art** from [Cover Art Archive](https://coverartarchive.org) and shows it in the playback view, queue thumbnails and the **CD** playlist.
- On eject, clears the queue (only if it contains CD tracks only) and removes the playlist and cover.
- Works offline or with unknown discs, using numbered tracks.

**It does not modify any moOde file**: it only adds a script, a udev rule and an MPD permission. moOde updates do not affect it.

### Requirements

- moOde audio player with MPD built with CD support (`cdio_paranoia`). Tested on moOde (Debian Trixie), Raspberry Pi 5.
- USB CD/DVD drive.
- Internet connection for titles and cover art (optional).

### Install

```bash
git clone https://github.com/kabexa22/moode-cd-player.git
cd moode-cd-player
sudo bash install.sh
```

### Usage

1. Insert an audio CD and wait about 20 seconds.
2. The tracks appear in the moOde queue. Press **Play**.

If the Pi boots with a disc already inserted, eject and re-insert it.

### Raspberry Pi 5 and power

Without the official 27W power supply, the Pi 5 limits USB ports to 600 mA. A bus-powered drive may stutter or be slow to start. Options:

- Official Raspberry Pi 27W PSU (recommended).
- Powered USB hub for the drive.
- Add `usb_max_current_enable=1` to `/boot/firmware/config.txt` and reboot (only if your PSU really delivers 5 A).

### Limitations

- Direct playback from the disc: starting and changing tracks may take a few seconds.
- moOde shows "File does not exist" under the cover. Cosmetic only.
- A `cdda:` folder appears in **Library → Folders**. It holds the cover art: don't delete it.
- Loading the disc from **Playlists → CD** plays without titles. Use the queue loaded automatically on insert.

### Uninstall

```bash
sudo bash uninstall.sh
```

### Troubleshooting

```bash
sudo tail -n 20 /var/log/moode-cd-player.log
```

---

## Credits

- Track metadata: [MusicBrainz](https://musicbrainz.org) (CC0).
- Cover art: [Cover Art Archive](https://coverartarchive.org). Images are downloaded on each device for personal use and are not distributed with this project.

## License

[GPL-3.0-or-later](LICENSE)
