#!/usr/bin/env python3
"""POR, BEL, CRO y DEN CON CLUBES REALES (10-11-2026, orden 35 del dueño vía el líder): hasta hoy sus 64 clubes eran INVENTADOS en
`datos/paises_extra.json`. Ahora, como NED (`liga_paises_bajos.py`): lo REAL (nombres con dígitos, colores, reputación, aforo, nombre de la liga y de
la copa) solo entra en el PACK; `base_ficticia.py` hace el resto. Cantidad real 2025-26: POR 18, BEL 16, CRO 10, DEN 12.

COMPATIBILIDAD: los clubes inventados que tienen equivalente real CONSERVAN su nombre ficticio (Tejo Lisboa = Benfica, Douro FC = Porto…): así no
se pierde su historia ni hay que migrar nada, y las partidas guardadas (que guardan los nombres) siguen abriendo. Los inventados sin equivalente
(CRO 16→10, DEN 16→12, y 5 de POR) desaparecen del mundo nuevo; los reales que no tenían inventado reciben nombre ficticio nuevo.
`paises_extra.json` conserva de cada país todo lo demás (selección, nivel, globo, bolsas de nombres, torneos europeos).
DUDAS (de memoria, sin red): plantillas 2025-26 de las cuatro ligas; colores, medias y aforos aproximados.
"""
# país -> (liga real con dígitos, liga ficticia, copa real, copa ficticia)
LIGAS = {
    "POR": ("Pr1meira Liga", "Liga Portuguesa", "Taça de Portugal", "Copa de Portugal"),
    "BEL": ("Pr0 League", "Liga Belga", "Copa de Bélgica", "Copa de Bélgica"),
    "CRO": ("Prva HNL", "Liga Croata", "Copa de Croacia", "Copa de Croacia"),
    "DEN": ("Superl1ga", "Liga Danesa", "Copa de Dinamarca", "Copa de Dinamarca"),
}
# (país, nombre real LIMPIO, nombre ficticio, color 1, color 2, media, aforo, fundado, apodo, estadio, guiño)
FILAS = [
    # ---- Portugal (18)
    ("POR", "Benfica", "Tejo Lisboa", "#d50032", "#ffffff", 84, 64000, 1904, "las Águilas", "la Catedral de Lisboa", "El club con más socios del país y una grada que no se sienta."),
    ("POR", "Porto", "Douro FC", "#0057b8", "#ffffff", 84, 50000, 1893, "los Dragones", "el estadio del dragón", "Campeón de Europa dos veces con entrenadores de leyenda."),
    ("POR", "Sporting CP", "Belém Atlético", "#00843d", "#ffffff", 81, 50000, 1906, "los Leones", "el estadio del león", "El club verde y blanco que formó a media Europa."),
    ("POR", "Braga", "Minho SC", "#d50032", "#ffffff", 76, 30000, 1921, "los Arsenalistas", "el estadio excavado en una cantera", "Un estadio excavado en la roca de una cantera."),
    ("POR", "Vitória Guimarães", "Castelo SC", "#ffffff", "#000000", 74, 30000, 1922, "los Conquistadores", "el estadio de la cuna de la nación", "El club de la ciudad donde nació el país."),
    ("POR", "Famalicão", "Famalicao Norte", "#0057b8", "#ffffff", 68, 5000, 1931, "los Famalicenses", "el estadio de la ciudad textil", "Un club del norte que sorprendió en Europa."),
    ("POR", "Gil Vicente", "Barcelos Galo", "#d50032", "#0057b8", 68, 12000, 1924, "los Gilistas", "el estadio del gallo", "El club del gallo de Barcelos."),
    ("POR", "Estoril", "Cascais Costa", "#ffd100", "#0057b8", 69, 8000, 1939, "los Canarinhos", "el estadio de la costa", "El club de la costa dorada, junto al casino."),
    ("POR", "Moreirense", "Moreira Verde", "#00843d", "#ffffff", 64, 6000, 1938, "os Cónegos", "el estadio de los canónigos", "Un club pequeño del interior del Miño."),
    ("POR", "Rio Ave", "Ave Vila Nova", "#00843d", "#ffffff", 68, 5000, 1939, "os Rioavistas", "el estadio del río Ave", "El club de la ciudad de los astilleros."),
    ("POR", "Santa Clara", "Azores Atlantico", "#d50032", "#ffffff", 63, 12000, 1927, "os Açorianos", "el estadio de la isla", "El club de las islas del Atlántico."),
    ("POR", "Casa Pia", "Lisboa Pia", "#ffffff", "#000000", 63, 8000, 1920, "os Gansos", "el estadio de la Pia", "Un club histórico de la ciudad."),
    ("POR", "Arouca", "Serra da Estrela", "#ffd100", "#0057b8", 65, 5000, 1951, "os Arouquenses", "el estadio de la sierra", "El club de un pueblo de la sierra."),
    ("POR", "Nacional Madeira", "Funchal Ilhéu", "#000000", "#ffffff", 68, 10000, 1910, "os Alvinegros", "el estadio de la isla de Madeira", "El club de la isla de Madeira."),
    ("POR", "Estrela Amadora", "Amadora Estrela", "#d50032", "#00843d", 62, 9000, 1932, "os Estrelas", "el estadio de la Reboleira", "Un club del extrarradio de Lisboa."),
    ("POR", "AVS", "Aves Vila", "#d50032", "#ffffff", 61, 5000, 1930, "os Avenses", "el estadio de Vila das Aves", "Un club sociedad anónima de nuevo cuño."),
    ("POR", "Alverca", "Alverca Tejo", "#d50032", "#ffd100", 60, 8000, 1939, "os Ribatejanos", "el estadio del Tajo", "Un club ribereño de regreso a Primera."),
    ("POR", "Tondela", "Tondela Beira", "#00843d", "#ffd100", 61, 5000, 1933, "os Beirões", "el estadio de las Beiras", "Un club de interior que llegó arriba por constancia."),
    # ---- Bélgica (16)
    ("BEL", "Anderlecht", "Senne Bruselas", "#5b2d8e", "#ffffff", 83, 22000, 1908, "los Malvas", "el estadio de la capital", "El club más laureado del país, de camiseta malva."),
    ("BEL", "Club Brugge", "Reie FC", "#0057b8", "#000000", 83, 29000, 1891, "los Azules y Negros", "el estadio de Brujas", "El club de Brujas, finalista de Europa."),
    ("BEL", "Genk", "Kempen FC", "#0057b8", "#ffffff", 79, 23000, 1988, "de Smurfen", "el estadio de las minas", "El club de la cuenca minera."),
    ("BEL", "Standard Lieja", "Mosa Lieja", "#d50032", "#ffffff", 77, 30000, 1898, "les Rouches", "el estadio de Sclessin", "El club rojo de la ciudad del Mosa."),
    ("BEL", "Gent", "Leie Gante", "#0057b8", "#ffffff", 77, 20000, 1900, "de Buffalo's", "el estadio de Gante", "El club de la ciudad de los canales."),
    ("BEL", "Union SG", "Schelde FC", "#ffd100", "#0057b8", 76, 16000, 1897, "les Unionistes", "el estadio del parque", "Un club de la capital que volvió tras medio siglo."),
    ("BEL", "Charleroi", "Sambre FC", "#000000", "#ffffff", 71, 15000, 1904, "les Zèbres", "el estadio de la ciudad negra", "El club de la región minera."),
    ("BEL", "Mechelen", "Dijle FC", "#d50032", "#ffd100", 70, 16000, 1904, "de Malinwa", "el estadio de Malinas", "El club de la ciudad del carillón."),
    ("BEL", "Cercle Brugge", "Costa Ostende", "#00843d", "#000000", 65, 8000, 1899, "de Groen-Zwarten", "el estadio compartido", "El hermano pequeño de Brujas."),
    ("BEL", "Antwerp", "Oud-Brabant", "#d50032", "#ffffff", 68, 10000, 1880, "the Great Old", "el estadio de Amberes", "El club más antiguo del país."),
    ("BEL", "Westerlo", "Nete FC", "#ffd100", "#0057b8", 67, 8000, 1933, "de Kemphanen", "el estadio de la Kempen", "Un club de pueblo que sorprendió."),
    ("BEL", "OH Lovaina", "Leuven Dijle", "#ffffff", "#000000", 66, 14000, 2002, "de Leuvense", "el estadio de la universidad", "Un club de la ciudad universitaria."),
    ("BEL", "Sint-Truiden", "Haspengouw FC", "#ffd100", "#0057b8", 66, 14000, 1924, "de Kanaries", "el estadio de las frutas", "El club de la región de la fruta."),
    ("BEL", "Zulte Waregem", "Flandes Oeste", "#d50032", "#00843d", 66, 9000, 2001, "de Essevee", "el estadio de Flandes", "Un club de Flandes Occidental."),
    ("BEL", "Dender", "Dender Azul", "#d50032", "#ffffff", 62, 8000, 1919, "de Denderleeuw", "el estadio del Dender", "Un club chico llegado a Primera."),
    ("BEL", "La Louvière", "Louvain Minas", "#d50032", "#000000", 60, 8000, 1909, "les Loups", "el estadio del Tivoli", "Un club del Hainaut con camiseta roja."),
    # ---- Croacia (10)
    ("CRO", "Dinamo Zagreb", "Sava Zagreb", "#0057b8", "#ffffff", 82, 35000, 1945, "Modri", "el Maksimir", "El club grande de la capital."),
    ("CRO", "Hajduk Split", "Marjan Split", "#ffffff", "#0057b8", 80, 34000, 1911, "Bili", "el Poljud", "El club del Adriático, de una hinchada legendaria."),
    ("CRO", "Rijeka", "Kvarner FC", "#ffffff", "#0057b8", 76, 8000, 1946, "Riječki", "el Rujevica", "El club del puerto del Kvarner."),
    ("CRO", "Osijek", "Drava Osijek", "#0057b8", "#ffffff", 74, 13000, 1947, "Bijelo-plavi", "el Opus Arena", "El club de la Eslavonia."),
    ("CRO", "Lokomotiva", "Trešnjevka FC", "#d50032", "#ffffff", 67, 3000, 1914, "Loko", "el Kranjčevićeva", "Un club del barrio de Trešnjevka."),
    ("CRO", "Gorica", "Turopolje FC", "#d50032", "#ffffff", 66, 5000, 1930, "Goričani", "el Velika Gorica", "Un club de las afueras de Zagreb."),
    ("CRO", "Istra 1961", "Pula Arena", "#00843d", "#ffd100", 67, 8000, 1961, "Zeleno-žuti", "el Aldo Drosina", "El club de la península de Istria."),
    ("CRO", "Varaždin", "Varazdin Barok", "#ffffff", "#d50032", 68, 9000, 1931, "Barokni", "el Anđelko Herjavec", "El club de la ciudad barroca."),
    ("CRO", "Slaven Belupo", "Podravina FC", "#d50032", "#ffffff", 65, 4000, 1907, "Slaven", "el Ivo Čoh", "El club de Koprivnica."),
    ("CRO", "Vukovar 1991", "Vukovar Dunav", "#0057b8", "#ffffff", 62, 5000, 1991, "Vukovarci", "el Cibalia", "El club que nació de la reconstrucción de la ciudad del Danubio."),
    # ---- Dinamarca (12)
    ("DEN", "FC Copenhague", "Østerbro FC", "#ffffff", "#0057b8", 82, 38000, 1992, "Løverne", "el Parken", "El club más laureado del país."),
    ("DEN", "Midtjylland", "Vestegn FC", "#d50032", "#000000", 79, 28000, 1999, "Ulvene", "el MCH Arena", "El club de los datos y los lobos."),
    ("DEN", "Brøndby", "Hede FC", "#ffd100", "#0057b8", 78, 12000, 1964, "Drengene fra Vestegnen", "el Brøndby Stadion", "El club del extrarradio de Copenhague."),
    ("DEN", "AGF", "Marselis FC", "#ffffff", "#0057b8", 73, 19000, 1880, "Århus Fremad", "el Ceres Park", "El club de Aarhus."),
    ("DEN", "Nordsjælland", "Limfjord FC", "#d50032", "#ffd100", 72, 14000, 2003, "Ulvene fra Nord", "el Right to Dream Park", "El club de la academia ghanesa."),
    ("DEN", "Randers", "Kattegat FC", "#0057b8", "#ffffff", 72, 10000, 2003, "Cimbrerne", "el Cepheus Park", "El club del río Gudenå."),
    ("DEN", "Silkeborg", "Gudenå FC", "#d50032", "#ffffff", 68, 10000, 1917, "Silkeborgs", "el Jysk Park", "El club de los lagos."),
    ("DEN", "Viborg", "Søhøjland FC", "#00843d", "#ffffff", 68, 10000, 1896, "Viborgs", "el Energi Viborg Arena", "Un club de provincia muy antiguo."),
    ("DEN", "Sønderjyske", "Grænseland FC", "#0057b8", "#ffffff", 65, 10000, 2004, "Sønderjyske", "el Sydbank Park", "El club de la frontera alemana."),
    ("DEN", "Vejle", "Lillebælt FC", "#d50032", "#ffffff", 66, 10000, 1891, "Vejle", "el Vejle Stadion", "El club del fiordo."),
    ("DEN", "Fredericia", "Bygholm FC", "#d50032", "#ffffff", 64, 10000, 1900, "FF", "el Monjasa Park", "Un club de la ciudad fortaleza."),
    ("DEN", "Odense", "Fyn FC", "#d50032", "#ffffff", 71, 15000, 1887, "OB", "el Nature Energy Park", "El club de Fionia, cuna de cuentos."),
]
PAISES = sorted({f[0] for f in FILAS})

_UNLEET = {"0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "8": "b", "9": "g"}


def _limpio(n):
    def letra(c):
        u = ord(c)
        return (65 <= u <= 90) or (97 <= u <= 122) or (0xC0 <= u <= 0x17F)
    o = ""
    for i, c in enumerate(n):
        if c in _UNLEET and ((i > 0 and letra(n[i - 1])) or (i + 1 < len(n) and letra(n[i + 1]))):
            o += _UNLEET[c]
        else:
            o += c
    return o


def _leet(n):
    """El nombre real LIMPIO con un dígito en la primera vocal minúscula posible (`_limpio` debe devolverlo igual)."""
    mapa = {"o": "0", "i": "1", "e": "3", "a": "4", "s": "5", "b": "8", "g": "9"}
    for i, c in enumerate(n):
        if i > 0 and c in mapa and n[i - 1].isalpha():
            cand = n[:i] + mapa[c] + n[i + 1:]
            if _limpio(cand) == n:
                return cand
    return n


_FORM = ["4-4-2", "4-2-3-1", "4-3-3", "3-5-2", "4-4-2", "5-3-2", "4-3-3", "4-2-3-1"]
_EST = ["bloque", "equilibrado", "presion", "directo", "garra", "contra", "posesion", "vertical", "ofensivo"]

NUEVOS = [(f[0], _leet(f[1]), f[2], f[3], f[4], f[5], f[6], _FORM[i % 8], _EST[i % 9]) for i, f in enumerate(FILAS)]
CLUBES = {f[1]: f[2] for f in FILAS}
ESTILOS = {f[2]: [f[7], f[8]] for f in NUEVOS}
HISTORIA = {f[1]: (f[7], f[8], f[9], f[10]) for f in FILAS}
LIGAS_FICTICIAS = {p: v[1] for p, v in LIGAS.items()}
COPAS_FICTICIAS = {p: v[3] for p, v in LIGAS.items()}


def asegurar(real: dict) -> None:
    """Pone en el pack la liga y la copa REALES de cada país con sus clubes (idempotente: reconstruye la lista en el mismo orden)."""
    for pais, (liga_real, _lf, copa_real, _cf) in LIGAS.items():
        clubes = [[n, c1, c2, media, aforo] for p, n, _f, c1, c2, media, aforo, _fo, _e in NUEVOS if p == pais]
        real["PAISES_LIGAS"][pais] = {"liga": liga_real, "clubes": clubes}
        real["COPA_NOM"][pais] = copa_real


def estadios():
    """Arquitectura del estadio de cada club nuevo, según su aforo (clave = nombre real limpio)."""
    from estadios_reales_p2 import e
    sal = {}
    for f in NUEVOS:
        aforo = f[6]
        niv = 1 if aforo < 15000 else (2 if aforo < 40000 else 3)
        forma = "ingles" if aforo < 8000 else ("rect" if aforo < 40000 else "oval")
        techo = "sin" if aforo < 8000 else ("parcial" if aforo < 40000 else "anillo")
        sal[_limpio(f[1])] = e(forma, niv, techo, False, "torres", "hormigon", "")
    return sal


def comprobar() -> list:
    esperado = {"POR": 18, "BEL": 16, "CRO": 10, "DEN": 12}
    return ["%s: %d clubes y la liga real tiene %d" % (p, sum(1 for f in FILAS if f[0] == p), n)
            for p, n in esperado.items() if sum(1 for f in FILAS if f[0] == p) != n]


def aspecto():
    """Líneas de `aspecto_clubes/ligas_europa_real.txt`: nombre|forma|patrón|siglas|camiseta|k1|k2|pantalón|medias|esc1|esc2. El escudo (forma + patrón +
    colores) es único (prueba M-062) y usa formas y patrones que no usan las otras generaciones de clubes."""
    formas = ["rombo", "octogono", "corona", "laurel", "frances", "curvo", "arco3", "hexalgo"]
    patrones = ["estrella", "ondas", "rombos", "tablero", "sol", "escamas", "rayo"]
    sal = []
    usados = set()
    for i, f in enumerate(NUEVOS):
        n = _limpio(f[1])
        letras = "".join(c for c in n if c.isalpha() and c.isascii() and c.isupper())[:3]
        if len(letras) < 2:
            letras = "".join(c for c in n if c.isascii() and c.isalpha()).upper()[:3]
        c1, c2 = f[3], f[4]
        k = (i // 8 + i) % 7
        while (formas[i % 8], patrones[k], c1, c2) in usados:
            k = (k + 1) % 7
        usados.add((formas[i % 8], patrones[k], c1, c2))
        franjas = i % 3 == 0
        sal.append("|".join([n, formas[i % 8], patrones[k], letras, "franjas" if franjas else "liso", c1, c2, c2, c1, c1, c2]))
    return sal


if __name__ == "__main__":
    import os
    ruta = os.path.join(os.path.dirname(os.path.abspath(__file__)), "aspecto_clubes", "ligas_europa_real.txt")
    with open(ruta, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("# Generado por herramientas/ligas_europa_real.py (no editar a mano): aspecto base de los clubes reales de POR, BEL, CRO y DEN.\n")
        fh.write("\n".join(aspecto()) + "\n")
    print("escrito", ruta, len(NUEVOS), "clubes", comprobar())
