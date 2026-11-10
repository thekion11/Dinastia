#!/usr/bin/env python3
"""SEGUNDAS DIVISIONES (10-11-2026, orden 35 del dueño: «SEGUNDAS DIVISIONES con clubes REALES y su cantidad real»). Mismo patrón que
`ligas_completas.py`: lo REAL (nombres, colores, reputación, aforo) solo entra en el PACK; `base_ficticia.py` hace el resto (nombre
ficticio ≤ 16 caracteres, aspecto, estadio genérico por aforo, estilo).

La segunda división de un país cuelga de su fila de `PAISES_LIGAS` como `"segunda": {"liga": nombre, "clubes": [[nombre, c1, c2, media, aforo]…]}`
(así nadie que recorra `PAISES_LIGAS` por país se encuentra una «liga» de más). Chile no está aquí: su Primera B ya vive en `DATA_P2`.

Por pasos (el líder los pide uno a uno): 1) ENG Championship (24). Los siguientes países se añaden a `NUEVOS` y a `LIGA2`.
DUDAS: los aforos y las medias de los clubes modestos son aproximados (temporada 2025-26, sin red para verificar: nombres y tamaño de la
liga, de memoria; revisar si se puede).
"""
# país -> (nombre real de la liga con dígitos, nombre ficticio, clubes que tiene la liga REAL)
LIGA2 = {"ENG": ("Championsh1p", "Liga de Plata ING", 24)}

# (país, nombre del pack, nombre ficticio, color 1, color 2, media, aforo, formación, estilo)
NUEVOS = [
    # ---- Inglaterra, Championship 2025-26 (24)
    ("ENG", "B1rmingham City", "Brummie Azul", "#0057b8", "#ffffff", 70, 29400, "4-3-3", "presion"),
    ("ENG", "Bl4ckburn", "Ewood Mitades", "#0057b8", "#ffffff", 68, 31400, "4-4-2", "directo"),
    ("ENG", "Br1stol City", "Avon Petirrojos", "#d50032", "#ffffff", 68, 27000, "4-2-3-1", "equilibrado"),
    ("ENG", "Charlt0n", "Valley Rojo", "#d50032", "#ffffff", 67, 27100, "4-4-2", "bloque"),
    ("ENG", "C0ventry", "Sky Celeste", "#5ab4e5", "#ffffff", 71, 32600, "4-2-3-1", "posesion"),
    ("ENG", "D3rby County", "Carnero Pride", "#ffffff", "#000000", 68, 33600, "4-4-2", "directo"),
    ("ENG", "Hull C1ty", "Tigre Humber", "#f5a81c", "#000000", 68, 25600, "4-2-3-1", "vertical"),
    ("ENG", "Ipsw1ch", "Orwell Azules", "#0057b8", "#ffffff", 72, 29800, "4-2-3-1", "equilibrado"),
    ("ENG", "Le1cester", "Soar Zorros", "#0057b8", "#ffffff", 73, 32300, "4-3-3", "contra"),
    ("ENG", "M1ddlesbrough", "Tees Rojo", "#d50032", "#ffffff", 70, 34000, "3-4-3", "ofensivo"),
    ("ENG", "M1llwall", "Leones Docks", "#0b2a5b", "#ffffff", 67, 20100, "4-4-2", "garra"),
    ("ENG", "Norw1ch", "Canario Wensum", "#ffd100", "#00843d", 70, 27200, "4-3-3", "posesion"),
    ("ENG", "Oxf0rd United", "Oxon Amarillo", "#ffd100", "#0b2a5b", 66, 12500, "4-2-3-1", "presion"),
    ("ENG", "P0rtsmouth", "Solent Azul", "#0057b8", "#ffffff", 68, 20800, "4-4-2", "garra"),
    ("ENG", "Pr3ston", "Deepdale Blanco", "#ffffff", "#0b2a5b", 67, 23400, "4-4-2", "bloque"),
    ("ENG", "Q.P.R.", "Loftus Aros", "#0057b8", "#ffffff", 66, 18400, "4-3-3", "posesion"),
    ("ENG", "Sheff1eld Utd", "Acero Blades", "#d50032", "#ffffff", 71, 32000, "3-5-2", "directo"),
    ("ENG", "Sheff1eld Wed", "Hillsboro Buho", "#0057b8", "#ffffff", 67, 39700, "4-4-2", "garra"),
    ("ENG", "S0uthampton", "Santos Itchen", "#d50032", "#ffffff", 71, 32400, "4-3-3", "posesion"),
    ("ENG", "St0ke", "Trent Alfareros", "#d50032", "#ffffff", 69, 30100, "4-4-2", "directo"),
    ("ENG", "Swans3a", "Cisnes Tawe", "#ffffff", "#000000", 69, 21100, "4-2-3-1", "posesion"),
    ("ENG", "Watf0rd", "Colmena Amarilla", "#ffd100", "#d50032", 69, 22200, "4-3-3", "contra"),
    ("ENG", "W. Br0m", "Zorzal Azul", "#0b2a5b", "#ffffff", 69, 26900, "4-2-3-1", "equilibrado"),
    ("ENG", "Wr3xham", "Dragon Gales", "#d50032", "#ffffff", 68, 13300, "4-4-2", "presion"),
]

# Historia con guiño (fundado, apodo, estadio, guiño), clave = nombre real limpio. Lo lee `historia_clubes.H` (base_ficticia.py).
HISTORIA = {
    "Birmingham City": (1875, "los Blues", "St Andrew's", "El club de la segunda ciudad de Inglaterra, con una grada que no se rinde ni en la categoría de plata."),
    "Blackburn": (1875, "los Rovers", "Ewood Park", "Fundador de la liga y campeón inglés en los noventa gracias al dinero de un mecenas."),
    "Bristol City": (1894, "los Robins", "Ashton Gate", "Un club del suroeste que sube y baja con el mismo orgullo de ciudad portuaria."),
    "Charlton": (1905, "los Addicks", "The Valley", "Volvió a su estadio tras años de exilio, con los hinchas organizados para recuperarlo."),
    "Coventry": (1883, "los Sky Blues", "la Arena de Coventry", "Del cielo azul de los ochenta a vagar por el país sin estadio propio; ahora vuelve."),
    "Derby County": (1884, "los Rams", "Pride Park", "Campeón inglés con un entrenador de leyenda, y desde entonces vive de esa memoria."),
    "Hull City": (1904, "los Tigers", "el estadio del estuario", "Un tigre amarillo y negro en un puerto del norte que nunca fue de grandes ligas."),
    "Ipswich": (1878, "los Tractor Boys", "Portman Road", "El club de la campiña que ganó una copa continental con una plantilla de pueblo."),
    "Leicester": (1884, "los Foxes", "el King Power", "Ganó la liga con una probabilidad de cinco mil contra uno y nadie lo olvida."),
    "Middlesbrough": (1876, "el Boro", "el Riverside", "El club del río Tees, siempre a un paso de la gloria y a otro del barro."),
    "Millwall": (1885, "los Leones", "The Den", "Nació en los muelles y juega como si todavía tuviera que defenderlos."),
    "Norwich": (1902, "los Canarios", "Carrow Road", "El club amarillo del este, famoso por su juego limpio y sus subidas y bajadas."),
    "Oxford United": (1893, "los Yellows", "el Kassam", "Campeón de una copa de liga en los ochenta y hoy un equipo de ciudad universitaria."),
    "Portsmouth": (1898, "los Pompey", "Fratton Park", "El club naval, con la grada que más ruido hace en la costa sur."),
    "Preston": (1880, "los Lilywhites", "Deepdale", "Campeón invicto en la primera liga de la historia, hace más de un siglo."),
    "Q.P.R.": (1882, "los Hoops", "Loftus Road", "Un estadio chico en el oeste de Londres con camiseta de aros azules y blancos."),
    "Sheffield Utd": (1889, "los Blades", "Bramall Lane", "Comparte ciudad con su rival eterno y juega en el campo de fútbol profesional más antiguo."),
    "Sheffield Wed": (1867, "los Owls", "Hillsborough", "Uno de los clubes más antiguos del mundo, con un búho como emblema."),
    "Southampton": (1885, "los Saints", "St Mary's", "El club del puerto que forma jugadores para media Europa."),
    "Stoke": (1863, "los Potters", "el Bet365", "Alfareros en la cuna de la cerámica, con fama de campo duro en invierno."),
    "Swansea": (1912, "los Swans", "el Liberty", "El club galés que jugó en la liga inglesa y se hizo famoso por tocar el balón."),
    "Watford": (1881, "los Hornets", "Vicarage Road", "Una avispa amarilla que sube y baja entre divisiones desde hace décadas."),
    "W. Brom": (1878, "los Baggies", "The Hawthorns", "Un club de las Midlands del Oeste con un zorzal por escudo y mucha historia de copa."),
    "Wrexham": (1864, "los Red Dragons", "el Racecourse", "El club profesional más antiguo de Gales, renacido en los últimos años."),
}

# Nombre real limpio (sin dígitos) -> ficticio; `base_ficticia.py` lo suma a `CLUBES`.
UNLEET = {"0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "8": "b", "9": "g"}


def _limpio(n):
    """Mismo algoritmo que `base_ficticia.limpiar` (copiado para no importar circularmente)."""
    def letra(c):
        u = ord(c)
        return (65 <= u <= 90) or (97 <= u <= 122) or (0xC0 <= u <= 0x17F)
    o = ""
    for i, c in enumerate(n):
        if c in UNLEET and ((i > 0 and letra(n[i - 1])) or (i + 1 < len(n) and letra(n[i + 1]))):
            o += UNLEET[c]
        else:
            o += c
    return o


CLUBES = {_limpio(f[1]): f[2] for f in NUEVOS}
ESTILOS = {f[2]: [f[7], f[8]] for f in NUEVOS}
PAISES = sorted({f[0] for f in NUEVOS})


def asegurar(real: dict) -> None:
    """Quita de cada liga los clubes de `QUITAR` y añade al final los que faltan (idempotente)."""
    fuera = {_limpio(n) for l in QUITAR.values() for n in l}
    for pais, d in real["PAISES_LIGAS"].items():
        d["clubes"] = [f for f in d["clubes"] if _limpio(f[0]) not in fuera]
    for tabla in ("REALES", "EQUIP_REAL"):
        for k in [k for k in real.get(tabla, {}) if _limpio(k) in fuera]:
            del real[tabla][k]
    for pais, nombre, _fic, c1, c2, media, aforo, _f, _e in NUEVOS:
        clubes = real["PAISES_LIGAS"][pais]["clubes"]
        if all(_limpio(f[0]) != _limpio(nombre) for f in clubes):
            clubes.append([nombre, c1, c2, media, aforo])


def estadios():
    """Arquitectura del estadio de cada club nuevo, según su aforo (clave = nombre real limpio) para `estadios_reales.ESTADIOS`."""
    from estadios_reales_p2 import e
    sal = {}
    for f in NUEVOS:
        aforo = f[6]
        niv = 1 if aforo < 15000 else (2 if aforo < 40000 else 3)
        forma = "ingles" if aforo < 8000 else ("rect" if aforo < 40000 else "oval")
        techo = "sin" if aforo < 8000 else ("parcial" if aforo < 40000 else "anillo")
        sal[_limpio(f[1])] = e(forma, niv, techo, False, "torres", "hormigon", "")
    return sal


def aspecto():
    """Líneas de `aspecto_clubes/ligas_completas.txt`: nombre|forma|patrón|siglas|camiseta|k1|k2|pantalón|medias|esc1|esc2."""
    formas = ["escudo", "clasico", "circulo", "ojiva", "penta", "hex", "cruzado", "banderin"]
    patrones = ["liso", "banda", "franjas", "mitad", "aro", "cruz", "chevron"]
    sal = []
    for i, f in enumerate(NUEVOS):
        n = _limpio(f[1])
        letras = "".join(c for c in n if c.isalpha() and c.isascii() and c.isupper())[:3] or n[:3].upper()
        if len(letras) < 2:
            letras = "".join(c for c in n if c.isascii() and c.isalpha()).upper()[:3]
        franjas = i % 3 == 0
        c1, c2 = f[3], f[4]
        ## El escudo de cada club es único (prueba M-062): forma por i % 8 y patrón desplazado según el grupo de ocho.
        sal.append("|".join([n, formas[i % 8], patrones[(i // 8 + i) % 7], letras, "franjas" if franjas else "liso",
                             c1, c2, c2, c1, c1, c2]))
    return sal


LIGAS_FICTICIAS = {pais: v[1] for pais, v in LIGA2.items()}


def asegurar(real: dict) -> None:
    """Cuelga de cada país su `segunda` con los clubes de `NUEVOS` (idempotente: reconstruye la lista en el mismo orden)."""
    for pais, (liga_real, _fic, _n) in LIGA2.items():
        clubes = [[n, c1, c2, media, aforo] for p, n, _f, c1, c2, media, aforo, _fo, _e in NUEVOS if p == pais]
        real["PAISES_LIGAS"][pais]["segunda"] = {"liga": liga_real, "clubes": clubes}


def comprobar() -> list:
    """Fallos de coherencia: cada país de `LIGA2` tiene exactamente su cantidad real de clubes."""
    fallos = []
    for pais, (_l, _f, n) in LIGA2.items():
        tiene = sum(1 for f in NUEVOS if f[0] == pais)
        if tiene != n:
            fallos.append("%s: %d clubes en la segunda y la real tiene %d" % (pais, tiene, n))
    return fallos


if __name__ == "__main__":
    import os
    ruta = os.path.join(os.path.dirname(os.path.abspath(__file__)), "aspecto_clubes", "segundas_divisiones.txt")
    with open(ruta, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("# Generado por herramientas/segundas_divisiones.py (no editar a mano): aspecto base de los clubes de las segundas divisiones.\n")
        fh.write("\n".join(aspecto()) + "\n")
    print("escrito", ruta, len(NUEVOS), "clubes", comprobar())
