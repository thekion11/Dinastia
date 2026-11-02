#!/usr/bin/env python3
"""LIGA DE PAÍSES BAJOS (01-11-2026, orden del dueño «clubes»: recrear de forma legal los clubes de League-Soccer, ver
`dinastia-godot/terceros/league_soccer/DIRECCION_DATOS_REALES.md`). De sus 8 clubes, 6 ya existían; Ajax y PSV no tenían liga.

Lo REAL (nombres de clubes, plantillas, nombre de la liga y la copa) solo entra en el PACK (`pack_real.json`): `asegurar(real)`
lo añade si falta (idempotente) y `base_ficticia.py` hace el resto como con cualquier liga (nombre ficticio, guiños de
jugadores, aspecto). Fila de club: [nombre del pack, color 1, color 2, media, aforo]. Plantillas: «nombre|pos|edad|media|país»,
temporada 2025-26.
"""

PAIS = "NED"
LIGA_REAL = "Eredivisie"
LIGA_FICTICIA = "Liga Holandesa"
COPA_REAL = "KNVB Beker"
COPA_FICTICIA = "Copa de Holanda"

CLUBES_PACK = [
    ["Aj4x", "#d2122e", "#ffffff", 84, 55000],
    ["PSV", "#ed1c24", "#ffffff", 84, 35000],
    ["F3yenoord", "#e30613", "#ffffff", 83, 47500],
    ["AZ Alkm4ar", "#d50032", "#ffffff", 80, 19500],
    ["Tw3nte", "#e3001b", "#ffffff", 79, 30200],
    ["Utr3cht", "#d50032", "#ffffff", 77, 23700],
    ["Go Ah3ad Eagles", "#e30613", "#ffd100", 75, 10400],
    ["NEC", "#d50032", "#00843d", 75, 12500],
    ["H3erenveen", "#0057b8", "#ffffff", 74, 27200],
    ["Sp4rta Rotterdam", "#d50032", "#ffffff", 73, 11000],
    ["Gr0ningen", "#00843d", "#ffffff", 73, 22500],
    ["F0rtuna Sittard", "#ffd100", "#00843d", 72, 12500],
    ["PEC Zw0lle", "#0057b8", "#ffffff", 72, 14000],
    ["H3racles", "#000000", "#ffffff", 72, 12000],
    ["NAC Bred4", "#ffd100", "#000000", 71, 19000],
    ["V0lendam", "#f58220", "#ffffff", 70, 7000],
    ["Exc3lsior", "#d50032", "#000000", 70, 4500],
    ["T3lstar", "#ffffff", "#0057b8", 69, 5000],
]

# Nombre real limpio -> ficticio. Los 12 primeros son los que ya tenía la liga inventada de `paises_extra.json` (lote 1, 26-10):
# se conservan para no perder su historia ni sus traducciones. Evocan la ciudad, el barrio, el río o el apodo.
CLUBES = {
    "Ajax": "Amstel FC",
    "PSV": "Lichtstad FC",
    "Feyenoord": "Maas Rotterdam",
    "AZ Alkmaar": "Kaasstad FC",
    "Twente": "Grens Oost",
    "Utrecht": "Domstad Utrecht",
    "Heerenveen": "Friese Meren",
    "Groningen": "Noorderzon FC",
    "NEC": "Waal FC",
    "PEC Zwolle": "Isala FC",
    "NAC Breda": "Brabant Noord",
    "Fortuna Sittard": "Mijnstreek FC",
    "Go Ahead Eagles": "IJssel Adelaars",
    "Sparta Rotterdam": "Spangen FC",
    "Heracles": "Zwartwit Almelo",
    "Volendam": "Palingdorp FC",
    "Excelsior": "Kralingen FC",
    "Telstar": "IJmond FC",
}

REALES = {
    "Aj4x": [
        "Vítězslav Jaroš|POR|24|76|CZE", "Anton Gaaei|LD|23|75|DEN", "Josip Šutalo|DFC|25|78|CRO",
        "Youri Baas|DFC|22|77|NED", "Ko Itakura|DFC|28|78|JPN", "Owen Wijndal|LI|25|73|NED", "Lucas Rosa|LD|25|74|BRA",
        "Youri Regeer|MC|22|75|NED", "Kenneth Taylor|MC|23|79|NED", "Davy Klaassen|MCO|32|75|NED",
        "Oscar Gloukh|MCO|21|78|ISR", "Mika Godts|EI|20|77|BEL", "Raúl Moro|ED|22|74|ESP",
        "Wout Weghorst|DC|33|76|NED", "Kasper Dolberg|DC|27|77|DEN",
    ],
    "PSV": [
        "Matěj Kovář|POR|25|78|CZE", "Sergiño Dest|LD|24|79|USA", "Ryan Flamingo|DFC|22|77|NED",
        "Yarek Gasiorowski|DFC|20|76|ESP", "Mauro Júnior|LI|26|76|BRA", "Anass Salah-Eddine|LI|23|74|MAR",
        "Jerdy Schouten|MCD|28|79|NED", "Joey Veerman|MC|27|80|NED", "Guus Til|MCO|28|78|NED",
        "Paul Wanner|MCO|19|76|GER", "Ismael Saibari|MCO|24|79|MAR", "Ivan Perišić|EI|36|78|CRO",
        "Couhaib Driouech|ED|23|75|NED", "Ricardo Pepi|DC|22|76|USA",
    ],
    "F3yenoord": [
        "Timon Wellenreuther|POR|29|76|GER", "Givairo Read|LD|19|75|NED", "Tsuyoshi Watanabe|DFC|28|76|JPN",
        "Thomas Beelen|DFC|23|74|NED", "Gijs Smal|LI|28|74|NED", "Jordan Bos|LI|23|74|AUS",
        "Oussama Targhalline|MCD|23|74|MAR", "Hwang In-beom|MC|29|79|KOR", "Quinten Timber|MC|24|78|NED",
        "Sem Steijn|MCO|24|77|NED", "Anis Hadj Moussa|ED|23|77|ALG", "Gonçalo Borges|EI|24|74|POR",
        "Leo Sauer|EI|20|73|SVK", "Ayase Ueda|DC|27|76|JPN",
    ],
    "AZ Alkm4ar": [
        "Rome-Jayden Owusu-Oduro|POR|21|73|NED", "Seiya Maikuma|LD|28|73|JPN", "Wouter Goes|DFC|21|74|NED",
        "Alexandre Penetra|DFC|24|74|POR", "Mees de Wit|LI|27|72|NED", "Jordy Clasie|MCD|34|73|NED",
        "Peer Koopmeiners|MC|25|73|NED", "Kees Smit|MC|19|75|NED", "Sven Mijnans|MCO|25|76|NED",
        "Ibrahim Sadiq|EI|25|74|GHA", "Ernest Poku|ED|21|73|NED", "Troy Parrott|DC|23|76|IRL",
        "Mexx Meerdink|DC|22|72|NED",
    ],
}


def asegurar(real: dict) -> None:
    """Añade al pack la liga, la copa y las plantillas, si no están ya. Lo demás del país (selección, nivel, bolsas de
    nombres, torneos europeos) sigue en `paises_extra.json`."""
    real["PAISES_LIGAS"].setdefault(PAIS, {"liga": LIGA_REAL, "clubes": [list(f) for f in CLUBES_PACK]})
    real["COPA_NOM"].setdefault(PAIS, COPA_REAL)
    for club, filas in REALES.items():
        real["REALES"].setdefault(club, list(filas))

# Historia (fundado, apodo, estadio, guiño) para `historia_clubes.py`: el texto no nombra al club real.
HISTORIA = {
    "Ajax": (1900, "los Hijos de Dios", "la arena de la capital", "Su escuela de cantera y el fútbol total cambiaron el juego: cuatro copas de Europa."),
    "PSV": (1913, "los Granjeros", "el estadio de la ciudad de la luz", "Nació como club de los trabajadores de una fábrica de bombillas; campeón de Europa en 1988."),
    "Feyenoord": (1908, "el Club del Pueblo", "la Bañera", "El orgullo obrero del puerto: primer club del país en ganar la Copa de Europa, en 1970."),
    "AZ Alkmaar": (1967, "los Cabezas de Queso", "el estadio de la ciudad del queso", "Nació de la fusión de dos clubes de la ciudad del mercado de quesos."),
    "Twente": (1965, "los Tukkers", "el estadio del este", "El club de la región textil del este, campeón de liga en 2010."),
    "Utrecht": (1970, "los Domstedelingen", "el estadio de la catedral", "Juega a la sombra de la torre de la catedral más alta del país."),
    "Heerenveen": (1920, "los Superfrisones", "el estadio de los nenúfares", "El club de Frisia: en la camiseta llevan las hojas de nenúfar rojas de su bandera."),
    "Groningen": (1971, "el Orgullo del Norte", "el estadio verde del norte", "La ciudad universitaria del norte llena su estadio cada quincena."),
    "NEC": (1900, "los de Nimega", "el estadio del parque", "Rojo, verde y negro en la ciudad más antigua del país, a orillas del Waal."),
    "PEC Zwolle": (1910, "los Dedos Azules", "el estadio del río", "El apodo viene de los ciudadanos que, según la leyenda, contaron monedas hasta tener los dedos azules."),
    "NAC Breda": (1912, "los Ratas", "el estadio del castillo de Breda", "Amarillo y negro, con una de las hinchadas más ruidosas del sur."),
    "Fortuna Sittard": (1968, "los Fortunezen", "el estadio de la frontera", "El club de la punta sur, entre Bélgica y Alemania."),
    "Go Ahead Eagles": (1902, "las Águilas", "el Nido de las Águilas", "Uno de los clubes más antiguos del país, campeón de copa en 2025."),
    "Sparta Rotterdam": (1888, "los Castillos", "el Castillo", "El club profesional más antiguo del país juega en un estadio con forma de castillo."),
    "Heracles": (1903, "los Heraclieden", "el estadio de Almelo", "Blanco y negro desde hace más de un siglo en la ciudad textil de Almelo."),
    "Volendam": (1977, "los Paling", "el estadio del dique", "El club del pueblo pesquero de las anguilas, con la camiseta naranja."),
    "Excelsior": (1902, "los Kralingers", "el estadio del bosque", "El hermano pequeño del puerto, siempre entre la primera y la segunda."),
    "Telstar": (1963, "los Leones Blancos", "el estadio junto al mar del Norte", "El club de la costa del acero, de vuelta en primera en 2025."),
}

CLASICOS = [
    ["Ajax", "Feyenoord", "el Clásico neerlandés"],
    ["Ajax", "PSV", "el Duelo de los Grandes"],
    ["Feyenoord", "PSV", "el otro clásico"],
    ["Feyenoord", "Sparta Rotterdam", "el Derbi de Róterdam"],
    ["Feyenoord", "Excelsior", "el Derbi del puerto"],
    ["Twente", "Heracles", "el Derbi del este"],
    ["Groningen", "Heerenveen", "el Derbi del norte"],
]
