#!/usr/bin/env python3
"""Busca y baja clips de Mixamo con la API no oficial (18-11-2026). SOLO para la cuenta del dueño y para clips que él quiera usar en el juego.

  python3 herramientas/mixamo_descargar.py buscar "soccer header"
  python3 herramientas/mixamo_descargar.py bajar ID_DEL_CLIP mx_cabezazo.fbx [--personaje "Y Bot"] [--in-place]

El TOKEN no se guarda nunca en el repo ni en el chat: se toma de la variable de entorno MIXAMO_TOKEN (en la nube, el proxy del entorno lo inyecta
solo: basta MIXAMO_TOKEN=proxy-injected). Cómo conseguirlo: `docs/04_auditorias/MIXAMO_TOKEN.md`. Los FBX NO van al repo (términos de Mixamo):
se bajan a una carpeta aparte (por omisión el directorio temporal) y se convierten con `dinastia-godot/herramientas/mixamo_a_res.gd`.
Ajustes de exportación como en `DORSALES_ANIM_2026-11-17.md`: FBX, sin malla (Without Skin), 30 fps, sin reducción de claves.
Estado: la búsqueda (pública) está probada; exportar y bajar siguen el flujo conocido de la API y NO se han probado con un token válido.
"""
import json
import os
import sys
import tempfile
import time
import urllib.parse
import urllib.request

from ruta_segura import ruta_segura

BASE = "https://www.mixamo.com/api/v1"
CAB = {"X-Api-Key": "mixamo2", "Accept": "application/json"}


def _pedir(ruta, datos=None, metodo=None):
    cab = dict(CAB)
    tok = os.environ.get("MIXAMO_TOKEN", "")
    if tok and tok != "proxy-injected":
        cab["Authorization"] = "Bearer " + tok
    cuerpo = None
    if datos is not None:
        cuerpo = json.dumps(datos).encode()
        cab["Content-Type"] = "application/json"
    req = urllib.request.Request(BASE + ruta, data=cuerpo, headers=cab, method=metodo)
    with urllib.request.urlopen(req, timeout=60) as r:  # NOSONAR(python:S5332): URL fija de la API, solo HTTPS
        return json.loads(r.read().decode())


def buscar(texto):
    q = urllib.parse.quote(texto)
    d = _pedir("/products?page=1&limit=48&order=&type=Motion%2CMotionPack&query=" + q)
    for r in d.get("results", []):
        print(r["id"], "|", r["name"], "|", r["description"][:70], "|", r["type"])


def _personaje(nombre):
    d = _pedir("/characters?page=1&limit=48&order=&type=Character&query=" + urllib.parse.quote(nombre))
    for r in d.get("results", []):
        if r["name"].lower() == nombre.lower():
            return r["id"]
    raise SystemExit("No se encontró el personaje «%s» (¿token válido?)" % nombre)


def bajar(clip_id, salida, personaje, en_sitio):
    pid = _personaje(personaje)
    det = _pedir("/products/%s?similar=0&character_id=%s" % (clip_id, pid))
    gms = det["details"]["gms_hash"]
    gms["inplace"] = en_sitio
    cuerpo = {"character_id": pid, "product_name": det["name"], "type": "Motion",
              "preferences": {"format": "fbx7_2019", "mesh_motionpack": "t-pose", "skin": "false", "fps": "30", "reducekf": "0"},
              "gms_hash": [dict(gms, **{"model-id": det["details"].get("model_id", gms.get("model-id"))})]}
    _pedir("/animations/export", cuerpo, "POST")
    url = None
    for _ in range(40):
        time.sleep(3)
        m = _pedir("/characters/%s/monitor" % pid)
        if m.get("status") == "completed":
            url = m["job_result"]
            break
        if m.get("status") == "failed":
            raise SystemExit("Mixamo no pudo exportar el clip: %s" % m)
    if not url:
        raise SystemExit("Tiempo agotado esperando la exportación")
    destino = ruta_segura(os.path.join(tempfile.gettempdir(), os.path.basename(salida)))
    if not url.startswith("https://"):
        raise SystemExit("La URL de descarga no es HTTPS")
    urllib.request.urlretrieve(url, destino)  # NOSONAR(python:S5332): validado arriba (solo HTTPS)
    print("Bajado:", destino)


def main():
    a = sys.argv[1:]
    if len(a) >= 2 and a[0] == "buscar":
        buscar(" ".join(a[1:]))
    elif len(a) >= 3 and a[0] == "bajar":
        pers = a[a.index("--personaje") + 1] if "--personaje" in a else "Y Bot"
        bajar(a[1], a[2], pers, "--in-place" in a)
    else:
        print(__doc__)
        sys.exit(2)


if __name__ == "__main__":
    main()
