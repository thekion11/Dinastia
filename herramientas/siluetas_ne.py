#!/usr/bin/env python3
"""Siluetas de país para `ui/mapa_pais.gd` desde Natural Earth (dominio público), 26-10-2026.

  curl -sS -o /tmp/ne/paises.geojson \
    https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_50m_admin_0_countries.geojson
  python3 herramientas/siluetas_ne.py /tmp/ne/paises.geojson POR:PRT NED:NLD BEL:BEL CRO:HRV DEN:DNK

Toma el polígono más grande del país (la parte continental), lo proyecta con cos(latitud),
lo simplifica (Douglas-Peucker) a unos 18 vértices y lo normaliza a 0-1 en un recuadro cuadrado
centrado, sin deformarlo, como las siluetas a mano. Imprime las líneas para pegar en SILUETAS."""
import json, math, sys

def area(p):
    return abs(sum(p[i][0] * p[i - 1][1] - p[i - 1][0] * p[i][1] for i in range(len(p)))) / 2

def dp(p, eps):
    if len(p) < 3:
        return p
    a, b = p[0], p[-1]
    dx, dy = b[0] - a[0], b[1] - a[1]
    n = math.hypot(dx, dy) or 1e-9
    d = [abs(dy * (q[0] - a[0]) - dx * (q[1] - a[1])) / n for q in p[1:-1]]
    i = max(range(len(d)), key=d.__getitem__) if d else 0
    if d and d[i] > eps:
        return dp(p[:i + 2], eps)[:-1] + dp(p[i + 1:], eps)
    return [a, b]

def silueta(geom, objetivo=18):
    polis = geom["coordinates"] if geom["type"] == "MultiPolygon" else [geom["coordinates"]]
    anillo = max((pol[0] for pol in polis), key=area)
    lat0 = sum(q[1] for q in anillo) / len(anillo)
    pts = [(q[0] * math.cos(math.radians(lat0)), -q[1]) for q in anillo]
    if pts[0] == pts[-1]:
        pts = pts[:-1]
    ## Un anillo cerrado se parte en dos mitades (DP necesita extremos distintos).
    m = len(pts) // 2
    def simplificar(eps):
        return dp(pts[:m + 1], eps)[:-1] + dp(pts[m:] + [pts[0]], eps)[:-1]
    eps = 0.001
    s = simplificar(eps)
    while len(s) > objetivo:
        eps *= 1.25
        s = simplificar(eps)
    xs, ys = [q[0] for q in s], [q[1] for q in s]
    lado = max(max(xs) - min(xs), max(ys) - min(ys))
    ox = min(xs) - (lado - (max(xs) - min(xs))) / 2
    oy = min(ys) - (lado - (max(ys) - min(ys))) / 2
    return [((x - ox) / lado, (y - oy) / lado) for x, y in s]

def main():
    gj = json.load(open(sys.argv[1], encoding="utf-8"))
    por_iso = {f["properties"]["ADM0_A3"]: f["geometry"] for f in gj["features"]}
    for par in sys.argv[2:]:
        juego, iso = par.split(":")
        s = silueta(por_iso[iso])
        print('\t"%s": [%s],' % (juego, ",".join("[%.2f,%.2f]" % q for q in s)))

if __name__ == "__main__":
    main()
