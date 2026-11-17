#!/usr/bin/env python3
"""Rasgos de aspecto de jugadores conocidos (17-11-2026): piel, pelo y barba a partir de descripciones públicas.

Solo RASGOS (nada de fotos): tono de piel de 7, color de pelo de 16, corte de los 24 del juego y barba (números de
`Cara._barba`: 0 nada, 2 perilla, 4 barba completa, 5 barba de días). Son aproximaciones ESTIMADAS (el aspecto cambia
con el tiempo); el parecido fino lo da la biblioteca de caras. Quien no está en la tabla usa el promedio de su país
con variación estable por id (`CaraPrior`).

  1. `MANO` (clave = nombre real) se escribe en `pack_real.json` como tabla `RASGOS_JUG` (solo uso privado):
         python3 herramientas/rasgos_jugadores.py --aplicar
  2. `base_ficticia.py` la publica con la clave del NOMBRE DE GUIÑO (`publicos`), nunca el nombre real.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ruta_segura import ruta_segura, RAIZ_REPO  # noqa: E402

DATOS = os.path.join(RAIZ_REPO, "dinastia-godot", "datos")
## Mismas paletas que `Cara` (tablas PIELES y PELOC); el índice se resuelve contra la tabla real al aplicar.
## piel 0 muy clara … 6 muy oscura. pelo: 0 negro, 1 castaño oscuro, 2 castaño, 3 castaño medio, 4 castaño claro, 5 rubio oscuro,
## 6 rubio, 7 pelirrojo, 8 canoso, 9 blanco.
## (piel, color de pelo, corte, barba)
MANO = {
    "Erling Haaland": (0, 6, "coleta", 0), "Kylian Mbappé": (4, 0, "corto", 5), "Lionel Messi": (2, 2, "corto", 4),
    "Cristiano Ronaldo": (2, 1, "corto", 0), "Neymar": (3, 0, "fade", 5), "Vinícius Júnior": (5, 0, "corto", 5),
    "Jude Bellingham": (3, 0, "corto", 0), "Harry Kane": (1, 4, "corto", 5), "Mohamed Salah": (3, 0, "rizado", 4),
    "Lautaro Martínez": (2, 1, "corto", 5), "Bukayo Saka": (5, 0, "rizado", 0), "Phil Foden": (1, 5, "corto", 0),
    "Declan Rice": (1, 2, "corto", 0), "Rodri": (2, 1, "corto", 5), "Kevin De Bruyne": (0, 7, "corto", 4),
    "Bruno Fernandes": (2, 1, "entradas", 5), "Marcus Rashford": (4, 0, "corto", 5), "Virgil van Dijk": (5, 0, "corto", 4),
    "Alisson": (2, 0, "corto", 5), "Son Heung-min": (1, 0, "corto", 0), "Martin Ødegaard": (0, 5, "corto", 0),
    "Gabriel Jesus": (4, 0, "corto", 5), "Bernardo Silva": (2, 1, "corto", 0), "Rúben Dias": (2, 1, "corto", 4),
    "Cole Palmer": (3, 0, "corto", 0), "Alexander Isak": (5, 0, "corto", 0), "Darwin Núñez": (3, 1, "corto", 5),
    "Luka Modrić": (1, 5, "melena", 0), "Toni Kroos": (0, 5, "corto", 0), "Karim Benzema": (2, 0, "corto", 4),
    "Robert Lewandowski": (1, 2, "corto", 5), "Antoine Griezmann": (1, 5, "corto", 5), "Pedri": (2, 0, "corto", 0),
    "Gavi": (2, 1, "corto", 0), "Lamine Yamal": (3, 0, "corto", 0), "Raphinha": (4, 0, "corto", 5),
    "Jan Oblak": (1, 1, "corto", 5), "Thibaut Courtois": (1, 2, "corto", 4), "Dani Carvajal": (2, 1, "corto", 4),
    "Federico Valverde": (2, 1, "corto", 4), "Aurélien Tchouaméni": (5, 0, "corto", 0), "Eduardo Camavinga": (5, 0, "corto", 0),
    "Marcus Thuram": (5, 0, "corto", 0), "Nicolò Barella": (2, 0, "corto", 5), "Federico Chiesa": (2, 1, "corto", 5),
    "Rafael Leão": (5, 0, "rizado", 0), "Khvicha Kvaratskhelia": (1, 1, "corto", 5), "Paulo Dybala": (2, 1, "corto", 4),
    "Victor Osimhen": (6, 0, "corto", 5), "Dusan Vlahovic": (1, 2, "corto", 5), "Joshua Kimmich": (1, 5, "corto", 5),
    "Jamal Musiala": (3, 0, "rizado", 0), "Florian Wirtz": (1, 5, "corto", 0), "Manuel Neuer": (1, 5, "corto", 5),
    "Leroy Sané": (4, 0, "corto", 5), "Thomas Müller": (1, 4, "corto", 0), "Harry Maguire": (1, 5, "rapado", 5),
    "Achraf Hakimi": (3, 0, "corto", 5), "Ousmane Dembélé": (4, 0, "corto", 5), "Marquinhos": (3, 0, "corto", 4),
    "Vitinha": (2, 1, "corto", 0), "Gianluigi Donnarumma": (2, 1, "corto", 5),
    "Ángel Di María": (2, 1, "corto", 4), "Julián Álvarez": (2, 1, "corto", 5), "Enzo Fernández": (2, 1, "corto", 0),
    "Alexis Mac Allister": (1, 5, "corto", 0), "Emiliano Martínez": (2, 1, "corto", 5), "Rodrigo De Paul": (2, 1, "coleta", 4),
    "Nicolás Otamendi": (2, 1, "rapado", 4), "Giovani Lo Celso": (2, 1, "corto", 5), "Luis Suárez": (2, 1, "corto", 5),
    "Casemiro": (3, 0, "corto", 4), "Gabriel Barbosa": (4, 0, "corto", 5), "Endrick": (4, 0, "corto", 0),
    "Arturo Vidal": (2, 1, "mohicano", 4), "Alexis Sánchez": (3, 0, "corto", 0),
}


def construir_real(tablas):
    """{nombre real: {piel, peloC, pelo, barba}} con los hex de las paletas de `tablas` (PIELES y PELOC de la base)."""
    pieles, peloc = tablas["PIELES"], tablas["PELOC"]
    res = {}
    for nombre, (p, c, corte, barba) in MANO.items():
        res[nombre.strip()] = {"piel": pieles[p], "peloC": peloc[c], "pelo": corte, "barba": barba}
    return res


def publicos(rasgos_real, reales_real, reales_pub, nombre_club_pub):
    """Tabla pública: la misma de `rasgos_real` pero con la clave del NOMBRE DE GUIÑO. Las filas de `reales_pub` conservan el orden
    de `reales_real` (`jugadores_guino.tabla_base`), así que se emparejan por posición dentro del club. `nombre_club_pub(club_real)`
    da el nombre ficticio del club (o None si el club no se publica)."""
    pub = {}
    for club, filas_r in reales_real.items():
        filas_p = reales_pub.get(nombre_club_pub(club) or "", [])
        for fr, fp in zip(filas_r, filas_p):
            nom_r = fr.split("|")[0]
            if nom_r in rasgos_real:
                pub[fp.split("|")[0]] = dict(rasgos_real[nom_r])
    return pub


def main():
    pack_ruta = ruta_segura(os.path.join(DATOS, "pack_real.json"))
    base_ruta = ruta_segura(os.path.join(DATOS, "tablas.json"))
    with open(base_ruta, encoding="utf-8") as f:
        base = json.load(f)   ## tablas.json es un diccionario plano de tablas
    with open(pack_ruta, encoding="utf-8") as f:
        pack = json.load(f)
    nombres = {x.split("|")[0] for v in pack["tablas"]["REALES"].values() for x in v}
    tabla = construir_real(base)
    faltan = sorted(n for n in tabla if n not in nombres)
    print(f"rasgos a mano: {len(tabla)}; no están en el pack (se ignoran): {len(faltan)}")
    for n in faltan:
        print("  falta:", n)
    if "--aplicar" in sys.argv:
        pack["tablas"]["RASGOS_JUG"] = {n: v for n, v in tabla.items() if n in nombres}
        with open(pack_ruta, "w", encoding="utf-8") as f:
            json.dump(pack, f, ensure_ascii=False, separators=(",", ":"))
        print("pack actualizado: RASGOS_JUG con", len(pack["tablas"]["RASGOS_JUG"]))


if __name__ == "__main__":
    main()
