#!/usr/bin/env bash
# Convierte una foto en retrato dithered estilo CRT (tinte azul + scanlines)
# y lo deja en assets/portrait.png listo para el README.
# Uso: ./scripts/make_portrait.sh tu-foto.jpg
set -euo pipefail
IN="${1:?Uso: $0 foto.jpg}"
OUT="$(cd "$(dirname "$0")/.." && pwd)/assets/portrait.png"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# 1) Paleta de 8 tonos: fondo oscuro -> azul acento (misma paleta que las cards)
ffmpeg -y -v error -t 0.05 -f lavfi -i "gradients=s=256x64:c0=0x0b0e14:c1=0x7aa2f7:x0=0:y0=32:x1=255:y1=32" \
  -vf "palettegen=max_colors=12:reserve_transparent=0" -frames:v 1 "$TMP/palette.png"

# 2) Gris + contraste -> reducir a 180px -> dither bayer -> pixeles 4x -> scanlines -> marco
ffmpeg -y -v error -i "$IN" -i "$TMP/palette.png" -frames:v 1 -filter_complex \
  "[0:v]scale=180:-2,format=gray,eq=contrast=1.15:brightness=-0.04,format=rgb24[s];
   [s][1:v]paletteuse=dither=bayer:bayer_scale=1[d];
   [d]scale=iw*4:ih*4:flags=neighbor,format=rgb24,
   geq=r='if(mod(Y,4),r(X,Y),r(X,Y)*0.45)':g='if(mod(Y,4),g(X,Y),g(X,Y)*0.45)':b='if(mod(Y,4),b(X,Y),b(X,Y)*0.45)',
   pad=iw+48:ih+48:24:24:0x0b0e14,pad=iw+4:ih+4:2:2:0x1f2937" \
  "$OUT"

echo "OK -> $OUT"
