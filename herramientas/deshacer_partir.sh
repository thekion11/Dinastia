#!/bin/sh
# Deshace un reparto en capas que aún no se ha confirmado: restaura los .gd modificados y borra las capas _pN.
cd "$(dirname "$0")/.." || exit 1
git diff --name-only -- '*.gd' | xargs -r git checkout --
git ls-files --others --exclude-standard | grep -E '_p[0-9]+\.gd(\.uid)?$' | xargs -r rm -f
