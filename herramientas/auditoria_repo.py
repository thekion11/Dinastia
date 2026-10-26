#!/usr/bin/env python3
"""Mide el estado del repositorio (mega auditoría 3, 24-10-2026) y escribe un JSON con las cifras.

  python3 herramientas/auditoria_repo.py [salida.json]

Solo LEE el repo. Todo lo que dice `docs/04_auditorias/MEGA_AUDITORIA_3.md` sale de aquí (o de otra
medición citada en ese documento), para que se pueda repetir.
"""
import collections
import json
import os
import re
import subprocess
import sys

J = "dinastia-godot"


def lst():
    out = subprocess.check_output(["git", "-c", "core.quotepath=false", "ls-files"]).decode()
    return [f for f in out.split("\n") if f]


def leer(f):
    try:
        return open(f, encoding="utf-8", errors="ignore").read()
    except OSError:
        return ""


def main():
    ficheros = lst()
    r = {}
    gd = [f for f in ficheros if f.endswith(".gd") and f.startswith(J + "/")]
    prod = [f for f in gd if "/pruebas/" not in f]
    txt = {f: leer(f) for f in gd}

    # --- código
    lineas = {f: txt[f].count("\n") + 1 for f in gd}
    def funcs(t):
        pos = [m.start() for m in re.finditer(r"^(?:static\s+)?func\s+\w+", t, re.M)]
        return [(t[p:t.find("\n", p)][:70], t[p:(pos[i + 1] if i + 1 < len(pos) else len(t))].count("\n")) for i, p in enumerate(pos)]
    todas = []
    for f in gd:
        for nombre, n in funcs(txt[f]):
            todas.append((n, f, nombre))
    todas.sort(reverse=True)
    marcas = collections.Counter()
    for f in gd:
        for m in re.findall(r"\b(TODO|FIXME|HACK|XXX)\b", txt[f]):
            marcas[m] += 1
    r["codigo"] = {
        "scripts": len(gd), "scripts_juego": len(prod), "lineas": sum(lineas.values()),
        "lineas_juego": sum(lineas[f] for f in prod),
        "capas_pN": len([f for f in gd if re.search(r"_p\d+\.gd$", f)]),
        "mayor_script": max(lineas.values()),
        "funciones": len(todas),
        "funciones_mas_de_100_lineas": len([t for t in todas if t[0] > 100]),
        "funciones_mas_de_200_lineas": len([t for t in todas if t[0] > 200]),
        "top_funciones": [{"lineas": n, "archivo": f, "firma": s} for n, f, s in todas[:12]],
        "marcas_TODO_FIXME": dict(marcas),
        "defs_process": sum(len(re.findall(r"^func _process\(", txt[f], re.M)) for f in prod),
        "defs_physics_process": sum(len(re.findall(r"^func _physics_process\(", txt[f], re.M)) for f in prod),
        "print_en_juego": sum(len(re.findall(r"^\s*print\(", txt[f], re.M)) for f in prod),
        "push_error_warning": sum(len(re.findall(r"push_(?:error|warning)\(", txt[f])) for f in prod),
        "is_instance_valid": sum(txt[f].count("is_instance_valid") for f in prod),
        "signals_declaradas": sum(len(re.findall(r"^signal\s", txt[f], re.M)) for f in prod),
        "class_name": sum(len(re.findall(r"^class_name\s", txt[f], re.M)) for f in prod),
    }

    # --- pruebas
    tscn_p = [f for f in ficheros if f.startswith(J + "/pruebas/") and f.endswith(".tscn")]
    corpus_doc = "\n".join(leer(f) for f in ficheros if f.endswith((".md", ".sh", ".py")) and "pruebas/capturas" not in f)
    corpus_gd = "\n".join(txt[f] for f in gd)
    huerfanas = [f for f in tscn_p if os.path.basename(f)[:-5] not in corpus_doc and os.path.basename(f) not in corpus_gd]
    r["pruebas"] = {"escenas": len(tscn_p), "escenas_sin_ninguna_mencion": len(huerfanas),
                    "capturas_en_git": len([f for f in ficheros if "pruebas/capturas/" in f]),
                    "ejemplos_sin_mencion": [os.path.basename(f) for f in huerfanas[:15]]}

    # --- assets y texturas importadas
    imp = [f for f in ficheros if f.startswith(J + "/") and f.endswith(".import")]
    modos = collections.Counter()
    for f in imp:
        t = leer(f)
        if 'importer="texture"' in t:
            m = re.search(r"compress/mode=(\d+)", t)
            modos[m.group(1) if m else "?"] += 1
    r["texturas"] = {"importadas": sum(modos.values()), "modo_compresion": dict(modos),
                     "nota": "0 = sin pérdida, 1 = con pérdida, 2 = VRAM comprimida, 3 = VRAM Basis Universal"}
    corpus_ref = "\n".join(leer(f) for f in ficheros if f.startswith(J + "/") and f.endswith((".gd", ".tscn", ".tres", ".json", ".cfg", ".gdshader", ".gdshaderinc", ".import")))
    exts = (".png", ".jpg", ".jpeg", ".glb", ".fbx", ".ogg", ".wav", ".mp3", ".svg", ".webp")
    cand = [f for f in ficheros if f.startswith(J + "/assets/") and f.lower().endswith(exts)]
    sin_ref, peso_sin = [], 0
    for f in cand:
        b = os.path.basename(f)
        ruta = f[len(J) + 1:]
        if b not in corpus_ref and ruta not in corpus_ref:
            sin_ref.append(f)
            try:
                peso_sin += os.path.getsize(f)
            except OSError:
                pass
    r["assets"] = {"candidatos": len(cand), "sin_ninguna_referencia_por_nombre": len(sin_ref),
                   "peso_bytes_sin_referencia(punteros LFS cuentan poco)": peso_sin,
                   "ejemplos": sin_ref[:15]}

    # --- proyecto Godot
    pg = leer(J + "/project.godot")
    r["proyecto"] = {
        "addons": [f for f in ficheros if f.startswith(J + "/addons/")][:5],
        "editor_plugins": "editor_plugins" in pg,
        "autoloads": re.findall(r'^(\w+)="\*?res://', pg.split("[autoload]", 1)[-1].split("\n[", 1)[0], re.M),
        "escenas": len([f for f in ficheros if f.startswith(J + "/") and f.endswith(".tscn") and "/pruebas/" not in f]),
        "shaders": len([f for f in ficheros if f.startswith(J + "/") and f.endswith((".gdshader", ".gdshaderinc"))]),
    }

    # --- git / LFS / pesos
    r["repo"] = {"archivos_rastreados": len(ficheros),
                 "lfs": len(subprocess.run(["git", "lfs", "ls-files"], capture_output=True).stdout.decode().splitlines())}
    # --- documentos
    docs = [f for f in ficheros if f.endswith(".md") and "pruebas/capturas" not in f]
    r["documentos"] = {"md": len(docs), "md_kb": sum(os.path.getsize(f) for f in docs if os.path.exists(f)) // 1024,
                       "mayores": sorted(((os.path.getsize(f) // 1024, f) for f in docs if os.path.exists(f)), reverse=True)[:6]}
    # --- idiomas
    try:
        d = json.load(open(J + "/datos/idiomas_extra.json", encoding="utf-8"))
        r["idiomas"] = {"idiomas_extra": [k for k in d if k != "patrones"], "frases_en": len(d.get("en", {})), "patrones": len(d.get("patrones", []))}
    except OSError:
        pass
    r["idiomas"]["frases_sin_traducir_medidas"] = sum(1 for l in leer("docs/05_referencia/textos_sin_traducir.txt").splitlines() if l and not l.startswith("#"))
    out = sys.argv[1] if len(sys.argv) > 1 else "-"
    s = json.dumps(r, ensure_ascii=False, indent=1)
    if out == "-":
        print(s)
    else:
        open(out, "w", encoding="utf-8").write(s + "\n")
        print("escrito", out)


if __name__ == "__main__":
    main()
