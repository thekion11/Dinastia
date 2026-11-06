#!/usr/bin/env python3
"""Busca en el código de CADA FOTOGRAMA (_process, _physics_process y lo que llaman directamente, solo el cuerpo)
patrones que cuestan rendimiento: load(), instanciar escenas, buscar por grupo/nombre, crear colecciones.
Uso: python3 herramientas/auditoria_fotograma.py [--json]   (5-11-2026; evidencia = recuento por patrón y archivo)
--verificar: falla si un recuento SUBE por encima de TOPES (medidos el 5-11; bajarlos al arreglar, subirlos solo con motivo en el commit)."""
import re, sys, json, pathlib
RAIZ = pathlib.Path(__file__).resolve().parent.parent
PAT = {
 "load": re.compile(r"(?<![\w.])load\("),
 "instanciar": re.compile(r"\.instantiate\(|\.new\("),
 "grupo": re.compile(r"get_nodes_in_group\("),
 "buscar_nodo": re.compile(r"find_child\(|find_children\(|get_node\(|get_node_or_null\("),
 "coleccion_nueva": re.compile(r"(?<![\w.])(Array|Dictionary|PackedVector3Array|PackedFloat32Array)\.?\(?\)?\s*$|=\s*(\[\]|\{\})\s*$"),
 "string_fmt": re.compile(r"str\(|%\s*\[|String\.num|\.format\("),
}
TOPES = {"load": 1, "grupo": 0, "buscar_nodo": 2, "instanciar": 4}   ## medicion.gd es una medición puntual
def cuerpos(txt):
    L = txt.split("\n"); i = 0
    while i < len(L):
        m = re.match(r"^(\t*)func (_process|_physics_process)\(", L[i])
        if m:
            ind = len(m.group(1)); j = i + 1
            while j < len(L) and (L[j].strip() == "" or len(L[j]) - len(L[j].lstrip("\t")) > ind): j += 1
            yield i + 1, L[i:j]; i = j
        else: i += 1
def main():
    tot = {k: 0 for k in PAT}; por = {}
    for f in sorted(RAIZ.rglob("*.gd")):
        r = f.relative_to(RAIZ).as_posix()
        if r.startswith(("pruebas/", "terceros/", "addons/", "herramientas/")): continue
        for n0, cuerpo in cuerpos(f.read_text(errors="ignore")):
            for k, p in PAT.items():
                for off, ln in enumerate(cuerpo):
                    if ln.strip().startswith("#"): continue
                    if p.search(ln):
                        tot[k] += 1; por.setdefault(k, []).append("%s:%d" % (r, n0 + off))
    if "--verificar" in sys.argv:
        mal = [k for k, v in TOPES.items() if tot[k] > v]
        for k in mal: print("FALLO", k, tot[k], ">", TOPES[k], por[k])
        print("FIN AUDITORÍA DE FOTOGRAMA. %d fallos" % len(mal)); sys.exit(1 if mal else 0)
    if "--json" in sys.argv: print(json.dumps({"total": tot, "donde": por}, indent=1)); return
    print("Patrones DENTRO de _process/_physics_process:", tot)
    for k in ("load", "grupo", "buscar_nodo", "instanciar"):
        print("\n==", k, len(por.get(k, [])))
        for x in por.get(k, [])[:60]: print("  ", x)
main()
