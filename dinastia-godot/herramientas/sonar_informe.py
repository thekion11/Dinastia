#!/usr/bin/env python3
"""Descarga el informe de SonarCloud (rama main) y lo guarda en JSON + Markdown.

Uso:
    SONAR_TOKEN=... python3 herramientas/sonar_informe.py [--rama main]

El token SOLO se lee de la variable de entorno SONAR_TOKEN; nunca se escribe en disco.
Salida (por defecto docs/04_auditorias/): sonar_YYYY-MM-DD.json y sonar_YYYY-MM-DD.md
"""
import argparse
import base64
import collections
import datetime
import json
import os
import re
import sys
import urllib.parse
import urllib.request

BASE = "https://sonarcloud.io/api"
PROYECTO = "thekion11_Dinastia"
SALIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "docs", "04_auditorias")  # fija: sin ruta por argumento
MARCA = "<!-- GESTION: lo de abajo se escribe a mano y se conserva al regenerar -->"
ORDEN_SEV = ["BLOCKER", "CRITICAL", "MAJOR", "MINOR", "INFO"]
LENGUAJES = {
    ".cpp": "C++", ".h": "C++", ".hpp": "C++", ".cc": "C++", ".c": "C",
    ".py": "Python", ".gd": "GDScript", ".sh": "Shell", ".js": "JS",
    ".yml": "Workflows/YAML", ".yaml": "Workflows/YAML", ".json": "JSON",
    "Dockerfile": "Docker",
}


def pedir(ruta, params, token):
    url = BASE + ruta + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url)
    cred = base64.b64encode((token + ":").encode()).decode()
    req.add_header("Authorization", "Basic " + cred)
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


def paginar(ruta, params, token, clave, tam=500, tope=10000):
    todos, pag = [], 1
    while True:
        d = pedir(ruta, dict(params, p=pag, ps=tam), token)
        todos += d.get(clave, [])
        total = d.get("paging", {}).get("total", d.get("total", len(todos)))
        if len(todos) >= total or not d.get(clave) or len(todos) >= tope:
            return todos
        pag += 1


def lenguaje(ruta):
    base = os.path.basename(ruta)
    if base.startswith("Dockerfile"):
        return "Docker"
    if ".github/workflows" in ruta:
        return "Workflows/YAML"
    return LENGUAJES.get(os.path.splitext(base)[1].lower(), "Otro")


def ruta_de(componente):
    return componente.split(":", 1)[-1]


def sev(i):
    return i.get("severity", "INFO")


def tabla(titulo, contador, nivel="###"):
    out = [f"{nivel} {titulo}", "", "| Clave | Cantidad |", "|---|---:|"]
    out += [f"| {k} | {v} |" for k, v in contador.most_common()]
    return out + [""]


def resumen(issues, hotspots, duplic, rama, fecha):
    L = [f"# Informe SonarCloud — {PROYECTO} (rama {rama}) — {fecha}", ""]
    L += [f"- Issues abiertos: **{len(issues)}**  |  Hotspots: **{len(hotspots)}**  "
          f"|  Archivos con duplicación: **{len(duplic)}**", ""]
    L += tabla("Por tipo", collections.Counter(i["type"] for i in issues))
    L += tabla("Por severidad", collections.Counter(sev(i) for i in issues))
    L += tabla("Por lenguaje", collections.Counter(lenguaje(ruta_de(i["component"])) for i in issues))
    L += ["## Por severidad → regla → archivo", ""]
    for s in ORDEN_SEV:
        deesta = [i for i in issues if sev(i) == s]
        if not deesta:
            continue
        L += [f"### {s} ({len(deesta)})", ""]
        por_regla = collections.defaultdict(list)
        for i in deesta:
            por_regla[i["rule"]].append(i)
        for regla, lst in sorted(por_regla.items(), key=lambda kv: -len(kv[1])):
            L += [f"#### `{regla}` ({len(lst)}) — {lst[0].get('message', '')[:140]}", ""]
            por_arch = collections.Counter(ruta_de(i["component"]) for i in lst)
            for arch, n in por_arch.most_common():
                lineas = sorted({i.get("line", 0) for i in lst if ruta_de(i["component"]) == arch})
                L.append(f"- `{arch}` ×{n} (líneas {', '.join(map(str, lineas[:15]))}"
                         f"{'…' if len(lineas) > 15 else ''})")
            L.append("")
    L += ["## Security hotspots", ""]
    if not hotspots:
        L += ["Ninguno.", ""]
    for h in hotspots:
        L.append(f"- [{h.get('vulnerabilityProbability')}] `{ruta_de(h['component'])}:{h.get('line', 0)}` "
                 f"{h.get('securityCategory')} — {h.get('message', '')}")
    L += ["", "## Duplicaciones (archivos con más líneas duplicadas)", "",
          "| Archivo | Líneas dup. | % |", "|---|---:|---:|"]
    for d in duplic[:40]:
        L.append(f"| `{d['path']}` | {d['lineas']} | {d['pct']} |")
    return "\n".join(L) + "\n"


def duplicaciones(token, rama):
    comps = paginar("/measures/component_tree", {
        "component": PROYECTO, "branch": rama, "qualifiers": "FIL",
        "metricKeys": "duplicated_lines,duplicated_lines_density",
        "metricSort": "duplicated_lines", "s": "metric", "asc": "false"},
        token, "components", tam=100, tope=300)
    res = []
    for c in comps:
        m = {x["metric"]: x.get("value", "0") for x in c.get("measures", [])}
        if int(m.get("duplicated_lines", "0")) > 0:
            res.append({"path": c.get("path", c["key"]), "lineas": int(m["duplicated_lines"]),
                        "pct": m.get("duplicated_lines_density", "0")})
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rama", default="main")
    a = ap.parse_args()
    if not re.fullmatch(r"[\w./-]+", a.rama):
        sys.exit("Nombre de rama no válido.")
    token = os.environ.get("SONAR_TOKEN")
    if not token:
        sys.exit("Falta la variable de entorno SONAR_TOKEN.")
    base = {"componentKeys": PROYECTO, "branch": a.rama, "resolved": "false"}
    issues = paginar("/issues/search", base, token, "issues")
    hotspots = paginar("/hotspots/search", {"projectKey": PROYECTO, "branch": a.rama, "status": "TO_REVIEW"},
                       token, "hotspots")
    duplic = duplicaciones(token, a.rama)
    fecha = datetime.date.today().isoformat()
    os.makedirs(SALIDA, exist_ok=True)
    pj = os.path.join(SALIDA, f"sonar_{fecha}.json")
    pm = os.path.join(SALIDA, f"sonar_{fecha}.md")
    with open(pj, "w", encoding="utf-8") as f:
        json.dump({"fecha": fecha, "rama": a.rama, "issues": issues, "hotspots": hotspots,
                   "duplicaciones": duplic}, f, ensure_ascii=False, indent=1)
    gestion = ""  # sección manual (falsos positivos, excepciones) que sobrevive a regenerar el informe
    if os.path.exists(pm):
        previo = open(pm, encoding="utf-8").read()
        if MARCA in previo:
            gestion = previo[previo.index(MARCA):]
    with open(pm, "w", encoding="utf-8") as f:
        f.write(resumen(issues, hotspots, duplic, a.rama, fecha) + (gestion or MARCA + "\n"))
    print(f"Issues: {len(issues)}  Hotspots: {len(hotspots)}  Duplicados: {len(duplic)}")
    print("Escrito:", os.path.normpath(pj), "y", os.path.normpath(pm))


if __name__ == "__main__":
    main()
