#!/usr/bin/env python3
"""CATÁLOGO DE MOVIMIENTO DE LEAGUE-SOCCER (10-11-2026, fase 4c de docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md).

Lee las animaciones de locomoción originales (terceros/league_soccer/animaciones/movement/**.anim y templates/, Apache 2.0) y
guarda en datos/league_movimiento.json, por cada una, lo que el original calcula de su pista de raíz «player» y de «body»
(L utils/animation.cpp): velocidad de entrada y de salida ya escalonadas (0 / 3,5 / 5 / 7 m/s, GetIncomingVelocity y
GetOutgoingVelocity), el ángulo de salida (GetOutgoingAngle: el del último tramo de la raíz o, parado, el giro del cuerpo), el
giro del cuerpo al terminar (GetOutgoingBodyAngle), el nivel de reposo («idlelevel»), los pasos («steps»: con un número impar
el pie que toca cambia, GetOutgoingFoot) y la duración. Marco de League: el jugador
mira a -Y, su izquierda es +X; ángulo positivo = hacia la izquierda (igual que nuestro giro en Y). El espejo se obtiene
cambiando el signo de los ángulos. Lo usa `visor/league_movimiento.gd`.
Uso: python3 herramientas/league_movimiento.py   (rutas fijas dentro del proyecto)
"""
import json
import math
import os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ANIMS = os.path.join(RAIZ, "terceros", "league_soccer", "animaciones")
DESTINO = os.path.join(RAIZ, "datos", "league_movimiento.json")


def _escalon(v):
    """Como el original: < 1,8 parado; < 4,2 «dribble» 3,5; < 6,0 «walk» 5; si no «sprint» 7."""
    if v < 1.8:
        return 0.0
    if v < 4.2:
        return 3.5
    if v < 6.0:
        return 5.0
    return 7.0


def _modular(a):
    while a > math.pi:
        a -= 2.0 * math.pi
    while a < -math.pi:
        a += 2.0 * math.pi
    return a


def _claves(linea, n):
    """Pista «nombre,cuadro,v1..vn,cuadro,…» → [(cuadro, [v…])]."""
    campos = linea.strip().split(",")
    sal = []
    for k in range(1, len(campos) - n, n + 1):
        sal.append((int(campos[k]), [float(x) for x in campos[k + 1:k + 1 + n]]))
    return sal


def _giro_z(q):
    """Ángulo en Z (vertical de League) de un cuaternión x, y, z, w."""
    x, y, z, w = q
    return math.atan2(2.0 * (w * z + x * y), 1.0 - 2.0 * (y * y + z * z))


def _leer(ruta):
    pistas = {}
    variables = {}
    lineas = open(ruta, encoding="utf-8").read().split("\n")
    for i, linea in enumerate(lineas):
        if linea.startswith("player,"):
            pistas["player"] = _claves(linea, 3)
        elif linea.startswith("body,"):
            pistas["body"] = _claves(linea, 4)
        elif linea.strip().startswith("<") and not linea.strip().startswith("</") and i + 1 < len(lineas):
            variables[linea.strip()[1:-1]] = lineas[i + 1].strip()
    return pistas, variables


def _ficha(ruta):
    pistas, variables = _leer(ruta)
    pl = pistas.get("player", [])
    cuerpo = pistas.get("body", [])
    if len(pl) < 2 or not cuerpo:
        return None
    (f0, p0), (f1, p1) = pl[0], pl[1]
    (fa, pa), (fb, pb) = pl[-2], pl[-1]
    v_in = math.hypot(p1[0] - p0[0], p1[1] - p0[1]) / (f1 - f0) * 100.0
    dx, dy = pb[0] - pa[0], pb[1] - pa[1]
    v_out = math.hypot(dx, dy) / (fb - fa) * 100.0
    giro_fin = _modular(_giro_z(cuerpo[-1][1]))
    if _escalon(v_out) >= 1.8:
        ang = _modular(math.atan2(dy, dx) + 0.5 * math.pi)   ## FixAngle: «abajo» en Y en vez de «derecha» en X
        if abs(ang) > 0.95 * math.pi:
            lado = 1.0 if giro_fin >= 0.0 else -1.0
            ang = math.pi * 0.99 * lado
    else:
        ang = giro_fin
    return {
        "entra": _escalon(v_in), "sale": _escalon(v_out), "ang": round(ang, 4), "cuerpo": round(giro_fin, 4),
        "cuerpo_ini": round(_modular(_giro_z(cuerpo[0][1])), 4),
        "reposo": int(variables.get("idlelevel", "1") or 1), "largo": round(pl[-1][0] / 100.0, 3),
        "pasos": int(variables.get("steps", "1") or 1),
    }


def main():
    """Toda `movement/` (también las «angled»: el cuerpo girado respecto a la marcha) y las 10 plantillas (`templates/`, pasos
    estables con el cuerpo a 0, ±45 o ±135 grados; en el original, de ellas salen las animaciones autogeneradas)."""
    sal = {}
    for carpeta in ("movement", "templates"):
        base = os.path.join(ANIMS, carpeta)
        for raiz, _dirs, archivos in sorted(os.walk(base)):
            for nombre in sorted(archivos):
                if not nombre.endswith(".anim"):
                    continue
                ruta = os.path.join(raiz, nombre)
                f = _ficha(ruta)
                if f is None:
                    continue
                if carpeta == "templates":
                    f["plantilla"] = True
                rel = os.path.relpath(ruta, ANIMS)[:-5].replace(os.sep, "__")
                sal["ls_" + rel] = f
    with open(DESTINO, "w", encoding="utf-8") as h:
        json.dump(sal, h, ensure_ascii=False, indent=1, sort_keys=True)
    print("animaciones de movimiento:", len(sal))


if __name__ == "__main__":
    main()
