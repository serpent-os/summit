#!/bin/bash
set -e
set -x

rm static/img/favicon* -fv 

for size in 16 32 64 96 160 196; do
    inkscape dashboard.svg -D -o "static/img/favicon-${size}x${size}.png" -w "${size}" -h "${size}"
done

# Construct the 16x16 favico
convert static/img/favicon-16x16.png static/img/favicon.ico

# Install the SVG asset
cp dashboard.svg static/img/favicon.svg