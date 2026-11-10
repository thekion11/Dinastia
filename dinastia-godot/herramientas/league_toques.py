#!/usr/bin/env python3
"""CATÁLOGO DE TOQUES DE BALÓN DE LEAGUE-SOCCER (10-11-2026, fase 4 de docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md).

Lee las animaciones originales (terceros/league_soccer/animaciones/<tipo>/<velocidad>/*.anim, Apache 2.0) y guarda en
datos/league_toques.json, por tipo de golpeo y velocidad, cada animación con toque: el CUADRO del toque (10 ms), dónde está el
balón en ese cuadro respecto al jugador (marco de League: el jugador mira a -Y, su izquierda es +X, Z arriba), cuánto se
desplazó el cuerpo hasta ese cuadro, la duración y sus variables (dirección del balón que entra y que sale, dificultad,
«última oportunidad»). Lo usa `visor/league_toques.gd` para el filtro de alcance del original (L humanoid.cpp).
Uso: python3 herramientas/league_toques.py   (rutas fijas dentro del proyecto)
"""
import json
import os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIGEN = os.path.join(RAIZ, "terceros", "league_soccer", "animaciones")
DESTINO = os.path.join(RAIZ, "datos", "league_toques.json")
TIPOS = ["interfere", "sliding", "pass", "shot", "highpass", "trap", "ballcontrol", "deflect"]


def _vec(txt):
    return [round(float(v), 4) for v in txt.strip().split(",")[:3]]


def _clave(lineas, etiqueta):
    """Valor de <etiqueta>…</etiqueta> (la línea siguiente) o None."""
    for i, linea in enumerate(lineas):
        if linea.strip() == "<%s>" % etiqueta and i + 1 < len(lineas):
            return lineas[i + 1].strip()
    return None


def _cuerpo_en(campos, cuadro):
    """Posición del cuerpo (línea «player»: cuadro,x,y,z por clave) interpolada en `cuadro`."""
    claves = []
    for k in range(1, len(campos) - 3, 4):
        claves.append((int(campos[k]), [float(campos[k + 1]), float(campos[k + 2]), float(campos[k + 3])]))
    previa = claves[0]
    for c in claves:
        if c[0] >= cuadro:
            if c[0] == previa[0]:
                return c[1], claves[-1][0]
            f = (cuadro - previa[0]) / float(c[0] - previa[0])
            return [previa[1][j] + (c[1][j] - previa[1][j]) * f for j in range(3)], claves[-1][0]
        previa = c
    return claves[-1][1], claves[-1][0]


def leer(ruta):
    with open(ruta, encoding="utf-8") as f:
        lineas = f.read().splitlines()
    toque = None
    cuerpo = None
    for linea in lineas:
        campos = linea.split(",")
        if campos[0] == "player":
            cuerpo = campos
        elif campos[0] == "extension" and len(campos) >= 6 and campos[1] == "football":
            toque = [int(campos[2]), float(campos[3]), float(campos[4]), float(campos[5])]
    if toque is None or cuerpo is None:
        return None
    pos_cuerpo, fin = _cuerpo_en(cuerpo, toque[0])
    r = {"nombre": os.path.splitext(os.path.basename(ruta))[0], "cuadro": toque[0],
         "balon": [round(toque[1], 4), round(toque[2], 4), round(toque[3], 4)],
         "cuerpo": [round(v, 4) for v in pos_cuerpo], "cuadros": fin}
    for etiqueta, clave in (("incomingballdirection", "entra"), ("balldirection", "sale")):
        v = _clave(lineas, etiqueta)
        if v:
            r[clave] = _vec(v)
    for etiqueta, clave in (("touch_difficultyfactor", "dificultad"), ("touch_maxpowerfactor", "potencia")):
        v = _clave(lineas, etiqueta)
        if v:
            r[clave] = float(v)
    if _clave(lineas, "lastditch") == "true":
        r["ultima"] = True
    return r


def main():
    catalogo = {}
    for tipo in TIPOS:
        carpeta = os.path.join(ORIGEN, tipo)
        catalogo[tipo] = {}
        for vel in sorted(os.listdir(carpeta)):
            sub = os.path.join(carpeta, vel)
            if not os.path.isdir(sub):
                continue
            lista = [leer(os.path.join(sub, n)) for n in sorted(os.listdir(sub)) if n.endswith(".anim")]
            catalogo[tipo][vel] = [a for a in lista if a is not None]
    with open(DESTINO, "w", encoding="utf-8") as f:
        json.dump(catalogo, f, ensure_ascii=False, indent=1)
    total = sum(len(v) for t in catalogo.values() for v in t.values())
    print("league_toques: %d animaciones con toque -> %s" % (total, os.path.relpath(DESTINO, RAIZ)))


if __name__ == "__main__":
    main()
