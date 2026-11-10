#!/usr/bin/env python3
"""LIGAS COMPLETAS (10-11-2026, orden del dueño: cada liga con sus CLUBES REALES y su CANTIDAD REAL, temporada 2025-26;
en las ligas de año natural —ARG, BRA, COL, PER, MEX, USA, JPN— se tomó la temporada 2026). Mismo patrón que `liga_paises_bajos.py`.

Lo REAL (nombres, colores, reputación, aforo) solo entra en el PACK (`pack_real.json`): `asegurar(real)` añade al final de cada liga los
clubes que faltan (idempotente) y `base_ficticia.py` hace el resto (nombre ficticio de `CLUBES`, aspecto, estadio). Fila de club:
[nombre del pack, color 1, color 2, media, aforo]. `ESTILOS` = {nombre FICTICIO: [formación, estilo]} para `estilos_clubes.json`.
Chile (DATA_P1/DATA_P2), NED, URU, ECU, BOL, MAR y RSA no se tocan (ya tienen la cantidad real).

REGLA DE TAMAÑO: no se quita ningún club del pack (orden del dueño). Donde la liga actual conserva clubes DESCENDIDOS, solo se añaden
los que caben hasta el tamaño real, por orden de reputación; el resto va en `RESERVA` (faltan en el pack, no se añaden). Si el dueño
autoriza quitar a los descendidos, hay que borrar sus filas (y sus entradas en `CLUBES`, `aspecto_clubes/*.txt`, historia,
palmarés, estadios) y pasar los de `RESERVA` a `NUEVOS`.

DESCENDIDOS (clubes ACTUALES del pack que NO están en primera división 2025-26; se conservan):
  ENG: ninguno · ESP: ninguno · MEX: ninguno · USA: ninguno
  ITA: Sampdoria, Monza · GER: Bochum · FRA: Montpellier, Reims
  BRA (2026): Goiás, Fortaleza · ARG (2026): Godoy Cruz, Colón
  COL (2026): La Equidad, Envigado · PER (2026): Municipal, C. Vallejo, Binacional, Ayacucho
  JPN (2026): Consadole S., «Shimonoseki» (no es de J1), Albirex N., Shonan B.
  KSA: Al-Raed, Al-Wehda · EGY: Baladiyat (Fut. R1se pasó a llamarse Modern Sport: es el mismo club)
  PAR (12 reales; NO se quita nada ahora): Sol de América, Doce de Octubre, Tacuary, Gral. Caballero, Fernando Mora, Resistencia
    (los 12 de 2026: 2 de Mayo, Cerro Porteño, Guaraní, Libertad, Nacional, Olimpia, Recoleta, Rubio Ñu, San Lorenzo, Sp. Ameliano,
    Sp. Luqueño, Sp. Trinidense; faltan en el pack: Recoleta y San Lorenzo)
  KOR (12 reales; NO se quita nada ahora): Suwon FC, Daegu, Seongnam, Busan IPark, Ansan G., Chungbuk Cheongju
    (faltan en el pack: FC Anyang y Bucheon FC)
  AUS (12 reales; NO se quita nada ahora): Western United, Canberra United, Geelong FC, Darwin City

RESERVA (reales de primera que faltan y NO se añaden por culpa de los descendidos):
  ITA: Cremonese, Pisa · GER: Heidenheim · FRA: Le Havre, Metz · BRA: Chapecoense, Remo · ARG: Gimnasia (Mendoza), Estudiantes (Río Cuarto)
  COL: Jaguares, Llaneros · PER: Alianza Atlético, Cajamarca, Moquegua, Juan Pablo II · JPN: Fagiano Okayama, JEF United, Mito HollyHock,
  V-Varen Nagasaki · KSA: Al-Najma, Al-Kholood · EGY: Kahraba Ismailia
DUDAS: PER 2026 tiene 18 clubes (no 19). Los colores de varios clubes modestos (PER, EGY, COL, KSA, USA) son aproximados.
"""
PAIS_TAM = {"ENG": 20, "ESP": 20, "ITA": 20, "GER": 18, "FRA": 18, "BRA": 20, "ARG": 30, "COL": 20, "PER": 18,
            "MEX": 18, "USA": 30, "JPN": 20, "KSA": 18, "EGY": 21}

# (país, nombre del pack, nombre ficticio, color 1, color 2, media, aforo, formación, estilo)
NUEVOS = [
    # ---- Inglaterra (20)
    ("ENG", "B0urnemouth", "Bahia Cerezas", "#da291c", "#000000", 77, 11300, "4-2-3-1", "presion"),
    ("ENG", "Burnl3y", "Pennine Claret", "#6c1d45", "#99d6ea", 74, 21900, "4-4-2", "directo"),
    ("ENG", "Le3ds", "Aire Blanco FC", "#ffffff", "#1d428a", 78, 37600, "4-3-3", "presion"),
    ("ENG", "Sund3rland", "Wear Gatos", "#eb172b", "#ffffff", 75, 49000, "4-2-3-1", "equilibrado"),
    # ---- España (20)
    ("ESP", "Al4vés", "Gasteiz Azul", "#0057b8", "#ffffff", 74, 19800, "4-4-2", "bloque"),
    ("ESP", "Elch3", "Palmeral FC", "#00843d", "#ffffff", 72, 31400, "4-4-2", "equilibrado"),
    ("ESP", "L3vante", "Turia Granota", "#d50032", "#0057b8", 72, 26400, "4-4-2", "contra"),
    ("ESP", "Real Ov1edo", "Carbayon FC", "#0057b8", "#ffffff", 71, 30500, "4-4-2", "bloque"),
    # ---- Italia (20): 16 + 4 (quedan Cremonese y Pisa en RESERVA)
    ("ITA", "C0mo", "Lario FC", "#0057b8", "#ffffff", 74, 13600, "4-2-3-1", "posesion"),
    ("ITA", "Parm4", "Ducato Cruzado", "#ffd100", "#0057b8", 74, 22400, "3-4-3", "posesion"),
    ("ITA", "Cagl1ari", "Casteddu FC", "#d50032", "#0b2a5b", 73, 16500, "3-5-2", "contra"),
    ("ITA", "Hellas V3rona", "Scala Mastini", "#ffd100", "#0057b8", 72, 38400, "3-4-3", "vertical"),
    # ---- Alemania (18): 16 + 2 (queda Heidenheim en RESERVA)
    ("GER", "H4mburgo", "Elba Rauten", "#0057b8", "#ffffff", 76, 57000, "4-2-3-1", "ofensivo"),
    ("GER", "St. P4uli", "Reeperbahn FC", "#5c3a21", "#ffffff", 75, 29500, "4-2-3-1", "presion"),
    # ---- Francia (18): 16 + 2 (quedan Le Havre y Metz en RESERVA)
    ("FRA", "Par1s FC", "Lutecia FC", "#1f4e9c", "#ffffff", 73, 20000, "4-3-3", "posesion"),
    ("FRA", "Ang3rs", "Anjou Noir", "#000000", "#ffffff", 71, 17000, "4-4-2", "bloque"),
    # ---- Brasil (20, temporada 2026): 16 + 4 (quedan Chapecoense y Remo en RESERVA)
    ("BRA", "Bragant1no", "Massa Bruta FC", "#ffffff", "#d50032", 77, 17000, "4-2-3-1", "presion"),
    ("BRA", "M1rassol", "Maiao Dorado", "#ffd100", "#00843d", 75, 15000, "4-3-3", "equilibrado"),
    ("BRA", "V1tória", "Leao da Barra", "#d50032", "#000000", 74, 30000, "4-4-2", "directo"),
    ("BRA", "C0ritiba", "Coxa Verde", "#00843d", "#ffffff", 74, 40000, "4-2-3-1", "bloque"),
    # ---- Argentina (30, 2026): 16 + 14 (quedan Gimnasia M. y Estudiantes RC en RESERVA)
    ("ARG", "Argentin0s Jrs", "Paternal Bichos", "#d50032", "#ffffff", 76, 25000, "4-3-3", "posesion"),
    ("ARG", "Belgr4no", "Pirata Cordobes", "#5ab4e5", "#ffffff", 74, 38500, "4-4-2", "equilibrado"),
    ("ARG", "Gimnas1a LP", "Lobo del Bosque", "#ffffff", "#0057b8", 74, 26500, "4-4-2", "garra"),
    ("ARG", "Atl. Tucum4n", "Decano Tucuman", "#5ab4e5", "#ffffff", 72, 32700, "4-4-2", "garra"),
    ("ARG", "Ind. R1vadavia", "Mendoza Azul", "#0057b8", "#ffffff", 72, 24000, "4-3-3", "presion"),
    ("ARG", "Def3nsa y J.", "Halcon Varela", "#ffd100", "#00843d", 71, 12000, "4-4-2", "contra"),
    ("ARG", "Plat3nse", "Calamar Norte", "#5c3a21", "#ffffff", 71, 22500, "4-4-2", "contra"),
    ("ARG", "Central Córd0ba", "Santiago Ferro", "#000000", "#ffffff", 70, 34000, "4-4-2", "bloque"),
    ("ARG", "Inst1tuto", "Gloria Cordobesa", "#d50032", "#ffffff", 70, 26500, "4-3-3", "equilibrado"),
    ("ARG", "T1gre", "Matador Norte", "#0057b8", "#d50032", 68, 26300, "4-4-2", "directo"),
    ("ARG", "Sarm1ento", "Verde Junin", "#00843d", "#ffffff", 66, 19000, "4-4-2", "bloque"),
    ("ARG", "Ald0sivi", "Puerto Tiburon", "#ffd100", "#00843d", 66, 35200, "5-3-2", "bloque"),
    ("ARG", "Barrac4s Central", "Barracas Oeste", "#d50032", "#ffffff", 66, 4400, "4-4-2", "bloque"),
    ("ARG", "R1estra", "Riestra Sur", "#000000", "#ffffff", 65, 3000, "5-4-1", "bloque"),
    # ---- Colombia (20, 2026): 16 + 4 (quedan Jaguares y Llaneros en RESERVA)
    ("COL", "Cúcut4 Dep.", "Motilon FC", "#d50032", "#000000", 66, 32200, "4-4-2", "garra"),
    ("COL", "Dep. P4sto", "Volcan Galeras", "#ffd100", "#d50032", 66, 20700, "4-4-2", "contra"),
    ("COL", "Águil4s Doradas", "Dorados Rionegro", "#ffd100", "#000000", 66, 12000, "4-3-3", "vertical"),
    ("COL", "Inter Bog0tá", "Inter Capital", "#d50032", "#ffffff", 62, 10000, "4-4-2", "equilibrado"),
    # ---- Perú (18, 2026): 16 + 2 (quedan 4 en RESERVA)
    ("PER", "Sport Hu4ncayo", "Huanca Rojo", "#d50032", "#ffffff", 64, 20000, "4-4-2", "directo"),
    ("PER", "Comerci4ntes Unidos", "Cutervo Unidos", "#d50032", "#ffd100", 62, 13700, "4-4-2", "bloque"),
    # ---- México (18)
    ("MEX", "Atl. S4n Luis", "Potosino FC", "#d50032", "#ffffff", 72, 27000, "4-3-3", "equilibrado"),
    ("MEX", "Juár3z", "Bravos Frontera", "#00843d", "#000000", 70, 19700, "4-4-2", "contra"),
    # ---- Estados Unidos (30)
    ("USA", "Vancouv3r W.", "Cumbres Blancas", "#0b2a5b", "#5ab4e5", 74, 22100, "4-2-3-1", "vertical"),
    ("USA", "M1nnesota Utd", "Lagos Norte", "#000000", "#8bc7e8", 74, 19400, "4-2-3-1", "presion"),
    ("USA", "NY R3d Bulls", "Toro Rojo Hudson", "#d50032", "#ffd100", 74, 25000, "4-2-3-1", "presion"),
    ("USA", "S4n Diego FC", "Costa Dorada", "#0b2a5b", "#f58220", 74, 35000, "4-3-3", "vertical"),
    ("USA", "R3al Salt Lake", "Lago Salado FC", "#8b1a3a", "#0057b8", 73, 20200, "4-4-2", "equilibrado"),
    ("USA", "H0uston Dynamo", "Bayou Naranja", "#f58220", "#5ab4e5", 72, 22000, "4-4-2", "contra"),
    ("USA", "FC D4llas", "Texas Norte FC", "#d50032", "#0057b8", 72, 20500, "4-3-3", "bandas"),
    ("USA", "Ch1cago Fire", "Lago Ventoso", "#d50032", "#0a2240", 72, 25000, "4-2-3-1", "equilibrado"),
    ("USA", "D.C. Un1ted", "Potomac United", "#d50032", "#000000", 72, 20000, "4-4-2", "directo"),
    ("USA", "Sp0rting KC", "Pradera Celeste", "#8bc7e8", "#0b2a5b", 72, 18500, "4-3-3", "presion"),
    ("USA", "T0ronto FC", "Lago Ontario FC", "#d50032", "#7a8b99", 72, 28400, "4-2-3-1", "equilibrado"),
    ("USA", "C0lorado Rapids", "Montana Rocosa", "#8b1a3a", "#5ab4e5", 71, 18100, "4-4-2", "bloque"),
    ("USA", "CF M0ntréal", "Saint Laurent FC", "#0057b8", "#000000", 70, 19600, "4-2-3-1", "posesion"),
    ("USA", "S4n Jose", "Sismos Silicon", "#0057b8", "#000000", 70, 18000, "4-4-2", "vertical"),
    # ---- Japón (20, 2026): 12 + 4 (quedan 4 en RESERVA)
    ("JPN", "Mach1da Z.", "Tokio Oeste FC", "#0057b8", "#ffd100", 75, 15300, "4-4-2", "presion"),
    ("JPN", "Kash1wa R.", "Girasol Chiba", "#ffd100", "#000000", 74, 15100, "4-3-3", "posesion"),
    ("JPN", "Sh1mizu S.", "Pulso Naranja", "#f58220", "#ffffff", 72, 19600, "4-4-2", "equilibrado"),
    ("JPN", "T. V3rdy", "Verde Tokio", "#00843d", "#ffffff", 70, 47000, "4-4-2", "posesion"),
    # ---- Arabia Saudí (18): 14 + 2 (quedan Najma y Kholood en RESERVA)
    ("KSA", "Al-Q4dsiah", "Khobar Amarillo", "#ffd100", "#0057b8", 76, 22000, "4-2-3-1", "ofensivo"),
    ("KSA", "Ne0m SC", "Costa Futura", "#0b2a5b", "#00b2a9", 66, 12000, "4-3-3", "equilibrado"),
    # ---- Egipto (21): 15 + 5 (queda Kahraba en RESERVA)
    ("EGY", "Al It1ihad Alex.", "Faro Alejandria", "#00843d", "#ffffff", 69, 19000, "4-4-2", "bloque"),
    ("EGY", "Petr0jet", "Oro Negro Suez", "#d50032", "#ffffff", 66, 28500, "4-4-2", "contra"),
    ("EGY", "Har4s El Hodoud", "Guardia Frontera", "#00843d", "#ffffff", 65, 22000, "5-3-2", "bloque"),
    ("EGY", "Wadi D3gla", "Valle Palmeras", "#0057b8", "#ffffff", 65, 16000, "4-4-2", "equilibrado"),
    ("EGY", "Ghazl El M4halla", "Textil Mahalla", "#d50032", "#ffffff", 64, 14600, "4-4-2", "garra"),
]

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
    """Añade al final de cada liga del pack los clubes que faltan (idempotente)."""
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
    formas = ["escudo", "clasico", "circulo", "ojiva"]
    sal = []
    for i, f in enumerate(NUEVOS):
        n = _limpio(f[1])
        letras = "".join(c for c in n if c.isalpha() and c.isascii() and c.isupper())[:3] or n[:3].upper()
        if len(letras) < 2:
            letras = "".join(c for c in n if c.isascii() and c.isalpha()).upper()[:3]
        franjas = i % 3 == 0
        c1, c2 = f[3], f[4]
        sal.append("|".join([n, formas[i % 4], "franjas" if franjas else "liso", letras, "franjas" if franjas else "liso",
                             c1, c2, c2, c1, c1, c2]))
    return sal


if __name__ == "__main__":
    import os
    ruta = os.path.join(os.path.dirname(os.path.abspath(__file__)), "aspecto_clubes", "ligas_completas.txt")
    with open(ruta, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("# Generado por herramientas/ligas_completas.py (no editar a mano): aspecto base de los clubes añadidos el 10-11-2026.\n")
        fh.write("\n".join(aspecto()) + "\n")
    print("escrito", ruta, len(NUEVOS), "clubes")
