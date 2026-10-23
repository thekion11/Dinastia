#!/usr/bin/env python3
"""ENSAYO / REESCRITURA de la historia para bajar el peso del repo (23-10-2026).

Quita de TODAS las versiones antiguas los binarios que ya no están en el árbol de la
rama de referencia (capturas, modelos, mallas, builds); NUNCA toca código (lo que no
es binario y pesa menos de 5 MB se conserva siempre). El árbol de la rama de referencia
queda idéntico.

Uso (siempre en un clon ESPEJO aparte, nunca en el repo de trabajo):
  git clone --mirror https://github.com/thekion11/Dinastia ensayo.git
  cd ensayo.git
  git ls-tree -r <rama> | awk '{print $3}' | sort -u > ../keep.txt
  git ls-tree -r <rama> > ../antes.txt
  python3 ../reescribir_historia.py ../keep.txt
  git ls-tree -r <rama> | diff ../antes.txt -        # debe salir vacío
Subir a GitHub exige un «sí, empuja» del dueño (ver MEGAPLAN_REESTRUCTURACION.md §9.3).
"""
import sys
import git_filter_repo as fr

MIN_BINARIO = 100_000     # binarios más pesados que esto, si no están en `keep`, se van
MIN_DATOS = 5_000_000     # cualquier archivo más pesado que esto (mallas de caras…)

keep = set(open(sys.argv[1]).read().split())
quitados = {"n": 0, "bytes": 0}

def blob_cb(blob, metadata):
    if blob.original_id.decode() in keep:
        return
    d = blob.data
    if (len(d) > MIN_BINARIO and b"\0" in d[:8000]) or len(d) > MIN_DATOS:
        quitados["n"] += 1
        quitados["bytes"] += len(d)
        blob.skip()

fr.RepoFilter(fr.FilteringOptions.parse_args(["--force"]), blob_callback=blob_cb).run()
print("blobs viejos quitados:", quitados["n"], round(quitados["bytes"] / 1e6), "MB")
