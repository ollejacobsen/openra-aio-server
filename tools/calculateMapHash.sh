#!/bin/sh

#./calculateMapHash.sh /path/to/maps /path/to/openra-utility

if [ $# -ne 2 ]; then
  echo "Usage: $0 <mapFolder> <utility>"
  exit 1
fi

mapFolder="$1"
utility="$2"

found=0
for mapfile in "$mapFolder"/*.oramap; do
  if [ -f "$mapfile" ]; then
    found=1
    echo "Hash for $mapfile:"
    hash=$("$utility" ra --map-hash "$mapfile")
    if [ -n "$hash" ]; then
      outFile="${mapfile}.${hash}"
      echo "Creating $outFile"
      touch "$outFile"
    fi
  fi
done

if [ $found -eq 0 ]; then
  echo "No .oramap files found in $mapFolder"
fi