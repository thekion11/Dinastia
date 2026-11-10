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
LIGA2 = {"ENG": ("Championsh1p", "Liga de Plata ING", 24), "ESP": ("Segunda D1visión", "Liga de Plata ESP", 22),
         "ITA": ("Ser1e B", "Liga de Plata ITA", 20), "GER": ("2. Bund3sliga", "Liga de Plata GER", 18),
         "FRA": ("L1gue 2", "Liga de Plata FRA", 18)}

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



# ---- Paso 3 (ESP, ITA, GER, FRA): se escribe el nombre real LIMPIO y `_leet` le pone el dígito (comprobado: `_limpio` lo devuelve igual).
# (país, nombre real, ficticio, color 1, color 2, media, aforo, fundado, apodo, estadio, guiño)
DATOS3 = [
    # ---- España, Segunda División 2025-26 (22)
    ("ESP", "Albacete", "Mancha Blanco", "#ffffff", "#000000", 62, 17000, 1940, "los Queso Mecánico", "el Carlos Belmonte", "El club de La Mancha que juega con el eslogan de su ciudad."),
    ("ESP", "Almería", "Indalo FC", "#d50032", "#ffffff", 66, 15000, 1989, "los Rojiblancos del Indalo", "el Power Horse", "Un club joven del sur que subió a Primera con un estadio de playa."),
    ("ESP", "Andorra", "Pirineo Andorra", "#0057b8", "#ffd100", 60, 3300, 1957, "los Tricolores", "la Nova Illa", "El club del Principado, en la liga española desde hace pocos años."),
    ("ESP", "Burgos", "Cid Burgales", "#ffffff", "#000000", 62, 12000, 1994, "los Blanquinegros", "el Plantío", "Un club castellano que volvió al fútbol profesional tras décadas de ausencia."),
    ("ESP", "Cádiz", "Bahia Amarilla", "#ffd100", "#0057b8", 66, 20700, 1910, "los Submarino Amarillo", "el Carranza", "El equipo más antiguo de la bahía, con una grada de carnaval."),
    ("ESP", "Castellón", "Orellut FC", "#000000", "#ffffff", 63, 15000, 1922, "los Orelluts", "el Nou Castàlia", "El club de la plana valenciana, con camiseta rayada en negro."),
    ("ESP", "Ceuta", "Africa Norte", "#ffffff", "#000000", 58, 6000, 1970, "los Caballas", "el Alfonso Murube", "El club de la ciudad al otro lado del Estrecho."),
    ("ESP", "Córdoba", "Califa Verde", "#00843d", "#ffffff", 63, 13500, 1954, "los Blanquiverdes", "el Arcángel", "Un club de ciudad califal que ya fue de Primera."),
    ("ESP", "Cultural Leonesa", "Leon Cultural", "#ffffff", "#d50032", 58, 13500, 1923, "los Culturales", "el Reino de León", "El club de la capital leonesa, con camiseta blanca."),
    ("ESP", "Deportivo", "Coruna Blanco", "#0057b8", "#ffffff", 66, 32600, 1906, "los Blanquiazules", "el Riazor", "Campeón de liga con un equipo de leyenda hace un par de décadas."),
    ("ESP", "Eibar", "Armero Eibar", "#d50032", "#0057b8", 62, 8000, 1940, "los Armeros", "el Ipurua", "El club más pequeño de las grandes ligas, con un campo de bolsillo."),
    ("ESP", "Granada", "Alhambra Nazari", "#d50032", "#ffffff", 66, 19300, 1931, "los Nazaríes", "los Cármenes", "Un club a los pies de la sierra con mucha vida entre divisiones."),
    ("ESP", "Las Palmas", "Canaria Amarilla", "#ffd100", "#0057b8", 67, 32400, 1949, "los Amarillos", "el Gran Canaria", "El club de la isla grande, con un juego de pase corto."),
    ("ESP", "Leganés", "Pepino Madrid", "#0057b8", "#ffffff", 63, 12450, 1928, "los Pepineros", "el Butarque", "Un club del sur de Madrid que llegó a Primera con un campo chico."),
    ("ESP", "Málaga", "Boqueron Azul", "#5ab4e5", "#ffffff", 66, 30000, 1948, "los Boquerones", "La Rosaleda", "Un club con un pasado europeo que busca volver arriba."),
    ("ESP", "Mirandés", "Miranda Rojillo", "#d50032", "#000000", 58, 5700, 1927, "los Rojillos", "el Anduva", "El club del norte que sorprendió en la copa."),
    ("ESP", "Racing Santander", "Cantabria Verde", "#00843d", "#ffffff", 65, 22200, 1913, "los Racinguistas", "el Sardinero", "Un club con una grada fiel frente al mar."),
    ("ESP", "Real Sociedad B", "Donosti Filial", "#0057b8", "#ffffff", 60, 2500, 1951, "los Sanse", "Zubieta", "El filial de la cantera más famosa del norte."),
    ("ESP", "Valladolid", "Pucela Violeta", "#5b2d8e", "#ffffff", 66, 26500, 1928, "los Pucelanos", "el José Zorrilla", "Un club castellano que sube y baja con la misma camiseta violeta."),
    ("ESP", "Sporting Gijón", "Gijon Rojiblanco", "#d50032", "#ffffff", 66, 30000, 1905, "los Rojiblancos", "el Molinón", "El club asturiano con una cantera orgullosa."),
    ("ESP", "Zaragoza", "Ebro Maño", "#ffffff", "#0057b8", 66, 33000, 1932, "los Maños", "La Romareda", "Un club grande de Aragón que ganó una copa de Europa."),
    ("ESP", "Huesca", "Oscense Azul", "#0057b8", "#d50032", 62, 5400, 1960, "los Azulgranas del Alto Aragón", "el Alcoraz", "Un club pequeño del Pirineo que llegó a Primera."),
    # ---- Italia, Serie B 2025-26 (20)
    ("ITA", "Avellino", "Irpinia Lupi", "#00843d", "#ffffff", 60, 10000, 1912, "i Lupi", "el Partenio", "Un club del interior campano con una grada de montaña."),
    ("ITA", "Bari", "Puglia Galletto", "#ffffff", "#d50032", 66, 58000, 1908, "i Galletti", "el San Nicola", "Un club del tacón de la bota con un estadio enorme."),
    ("ITA", "Carrarese", "Marmo Apuano", "#ffd100", "#0057b8", 58, 4000, 1908, "gli Apuani", "el Dei Marmi", "El club de la ciudad del mármol."),
    ("ITA", "Catanzaro", "Calabria Aquile", "#ffd100", "#d50032", 62, 14500, 1929, "le Aquile", "el Nicola Ceravolo", "Un club calabrés con una pasión de punta de bota."),
    ("ITA", "Cesena", "Romagna Cavallo", "#ffffff", "#000000", 62, 23000, 1940, "i Cavallucci Marini", "el Dino Manuzzi", "Un club de la Romaña que forma jóvenes."),
    ("ITA", "Empoli", "Arno Azzurro", "#0057b8", "#ffffff", 64, 16000, 1920, "gli Azzurri", "el Carlo Castellani", "Un club de pueblo que forma a media liga."),
    ("ITA", "Virtus Entella", "Chiavari FC", "#ffffff", "#5ab4e5", 56, 4000, 1914, "i Diavoli Neri", "el Comunale", "Un club ligur de ciudad pequeña."),
    ("ITA", "Frosinone", "Ciociaria FC", "#ffd100", "#0057b8", 63, 16000, 1928, "i Canarini", "el Benito Stirpe", "Un club del Lacio que subió con dinero fresco."),
    ("ITA", "Juve Stabia", "Vesuvio Vespe", "#ffd100", "#0057b8", 58, 7500, 1907, "le Vespe", "el Romeo Menti", "Un club de la bahía de Nápoles."),
    ("ITA", "Mantova", "Mincio FC", "#ffffff", "#d50032", 58, 14000, 1911, "i Virgiliani", "el Danilo Martelli", "Un club lombardo con apodo de poeta."),
    ("ITA", "Modena", "Gialloblu Emilia", "#ffd100", "#0057b8", 62, 21000, 1912, "i Canarini", "el Alberto Braglia", "Un club de la tierra de los motores."),
    ("ITA", "Monza", "Brianza FC", "#d50032", "#ffffff", 68, 18500, 1912, "i Brianzoli", "el U-Power", "Un club de las afueras de Milán que llegó a Primera."),
    ("ITA", "Padova", "Antenore FC", "#ffffff", "#d50032", 60, 11000, 1910, "i Biancoscudati", "el Euganeo", "Un club veneto con una grada histórica."),
    ("ITA", "Palermo", "Rosanero Isola", "#f4a7c1", "#000000", 68, 36000, 1900, "i Rosanero", "el Renzo Barbera", "El club rosa de Sicilia."),
    ("ITA", "Pescara", "Adriatico FC", "#5ab4e5", "#ffffff", 60, 20500, 1936, "i Delfini", "el Adriatico", "Un club de la costa abruzzesa."),
    ("ITA", "Reggiana", "Mapei Granata", "#8b1a3a", "#ffffff", 60, 21000, 1919, "i Granata", "el Mapei Stadium", "Un club emiliano que jugó el estadio más moderno."),
    ("ITA", "Sampdoria", "Ligure Blucerchi", "#0057b8", "#ffffff", 68, 36500, 1946, "i Blucerchiati", "el Luigi Ferraris", "Campeón de liga en los noventa, comparte estadio con su rival."),
    ("ITA", "Spezia", "Aquilotto Ligure", "#ffffff", "#000000", 62, 10000, 1906, "gli Aquilotti", "el Alberto Picco", "Un club del golfo ligur."),
    ("ITA", "Südtirol", "Alto Adige FC", "#ffffff", "#d50032", 56, 5500, 1974, "i Biancorossi", "el Druso", "El club de los Alpes, bilingüe."),
    ("ITA", "Venezia", "Laguna Alata", "#00843d", "#f58220", 66, 12000, 1907, "i Leoni Alati", "el Pier Luigi Penzo", "El club de la laguna, con un estadio en una isla."),
    # ---- Alemania, 2. Bundesliga 2025-26 (18)
    ("GER", "Arminia Bielefeld", "Teuto Azul", "#0057b8", "#ffffff", 62, 27000, 1905, "die Arminen", "la Alm", "Un club de Westfalia con una grada que baja del monte."),
    ("GER", "Braunschweig", "Leon Brunswick", "#ffd100", "#0057b8", 60, 23000, 1895, "die Löwen", "el Eintracht-Stadion", "Un club del norte con un león por emblema."),
    ("GER", "Darmstadt", "Lilien Hesse", "#0057b8", "#ffffff", 62, 17000, 1898, "die Lilien", "el Merck", "Un club de Hesse que subió con un presupuesto mínimo."),
    ("GER", "Dynamo Dresden", "Elba Dinamo", "#ffd100", "#000000", 62, 32000, 1953, "die Schwarz-Gelben", "el Rudolf-Harbig", "Un club del este con una grada enorme."),
    ("GER", "Düsseldorf", "Rhin Fortuna", "#d50032", "#ffffff", 64, 54000, 1895, "die Fortunen", "el Merkur Spiel-Arena", "Un club renano con título de liga."),
    ("GER", "Elversberg", "Saarland FC", "#ffffff", "#000000", 58, 10000, 1907, "die SpVgg", "el Ursapharm", "El club más pequeño de la liga."),
    ("GER", "Fürth", "Trebol Franconia", "#00843d", "#ffffff", 60, 16000, 1903, "das Kleeblatt", "el Sportpark Ronhof", "Un club franconio con un trébol por emblema."),
    ("GER", "Hannover", "Leine Rojo", "#d50032", "#00843d", 64, 49000, 1896, "die Roten", "el Heinz von Heiden", "Un club del norte con un estadio grande."),
    ("GER", "Hertha", "Spree Azul", "#0057b8", "#ffffff", 66, 74000, 1892, "die Alte Dame", "el Olímpico de Berlín", "La vieja dama de la capital."),
    ("GER", "Holstein Kiel", "Kiel Marino", "#0057b8", "#d50032", 58, 15000, 1900, "die Störche", "el Holstein-Stadion", "Un club del Báltico que llegó a Primera."),
    ("GER", "Kaiserslautern", "Palatino Rojo", "#d50032", "#ffffff", 64, 49000, 1900, "die Roten Teufel", "el Fritz-Walter", "Campeón de liga con un estadio en un monte."),
    ("GER", "Karlsruhe", "Wildpark FC", "#0057b8", "#ffffff", 60, 34000, 1894, "der KSC", "el Wildpark", "Un club de Baden de los más antiguos."),
    ("GER", "Magdeburg", "Elba Magdeburgo", "#0057b8", "#ffffff", 60, 30000, 1965, "der FCM", "la MDCC-Arena", "Campeón de Europa en los setenta."),
    ("GER", "Nürnberg", "Franken Club", "#d50032", "#000000", 64, 50000, 1900, "der Club", "el Max-Morlock", "Un club franconio con mucho palmarés."),
    ("GER", "Paderborn", "Pader Azul", "#0057b8", "#000000", 58, 15000, 1907, "die Ostwestfalen", "el Home Deluxe", "Un club que sube y baja con presupuesto pequeño."),
    ("GER", "Preußen Münster", "Munster Verde", "#00843d", "#000000", 58, 15000, 1906, "die Preußen", "el Preußenstadion", "Un club de Westfalia que volvió arriba."),
    ("GER", "Schalke", "Ruhr Minero", "#0057b8", "#ffffff", 68, 62000, 1904, "die Knappen", "el Veltins", "El club de los mineros, con una grada gigante."),
    ("GER", "Bochum", "Cuenca Azul", "#0057b8", "#ffffff", 62, 27000, 1848, "die Unabsteigbaren", "el Vonovia", "Un club de la cuenca del Ruhr que nunca baja."),
    # ---- Francia, Ligue 2 2025-26 (18)
    ("FRA", "Amiens", "Picardia FC", "#ffffff", "#000000", 56, 12000, 1901, "les Licornes", "la Licorne", "Un club del norte con una unicornio por emblema."),
    ("FRA", "Annecy", "Alpes Lago", "#d50032", "#ffffff", 52, 3700, 1927, "les Annéciens", "el Parc des Sports", "Un club alpino de un lago."),
    ("FRA", "Bastia", "Corsica Azul", "#0057b8", "#ffffff", 58, 16000, 1905, "les Turcs", "el Armand Cesari", "El club de la isla de Córcega."),
    ("FRA", "Boulogne", "Cote Opale", "#ffffff", "#d50032", 52, 12000, 1898, "les Boulonnais", "el Libert", "Un club de la costa del Canal."),
    ("FRA", "Clermont", "Auvernia Rojo", "#d50032", "#0057b8", 56, 11000, 1990, "les Clermontois", "el Gabriel Montpied", "Un club de montaña que sorprendió en Primera."),
    ("FRA", "Dunkerque", "Dunas Norte", "#0057b8", "#d50032", 52, 4900, 1909, "les Dunkerquois", "el Marcel-Tribut", "Un club portuario del extremo norte."),
    ("FRA", "Grenoble", "Isere FC", "#0057b8", "#ffffff", 52, 20000, 1892, "les Grenoblois", "el Stade des Alpes", "Un club alpino con un estadio de Juegos."),
    ("FRA", "Guingamp", "Armor Rojo", "#d50032", "#000000", 56, 18000, 1912, "les Rouge et Noir", "el Roudourou", "Un club bretón con un campo de pueblo."),
    ("FRA", "Laval", "Mayenne FC", "#f58220", "#000000", 50, 17000, 1902, "les Tango", "el Francis Le Basser", "Un club del oeste que volvió al profesionalismo."),
    ("FRA", "Le Mans", "Sarthe Motor", "#ffd100", "#d50032", 54, 25000, 1985, "les Manceaux", "el MMArena", "Un club de la ciudad de las 24 horas."),
    ("FRA", "Montpellier", "Mosson Sureno", "#0057b8", "#f58220", 62, 32900, 1919, "les Pailladins", "la Mosson", "Campeón de Francia con un presupuesto corto."),
    ("FRA", "Nancy", "Lorena Cardo", "#ffffff", "#d50032", 56, 20000, 1967, "les Lorrains", "el Marcel Picot", "Un club lorenés con un cardo por emblema."),
    ("FRA", "Pau", "Bearn Pau", "#ffd100", "#00843d", 52, 4000, 1920, "les Palois", "la Nouvelle Hippodrome", "Un club pirenaico."),
    ("FRA", "Red Star", "Saint Ouen FC", "#00843d", "#ffffff", 50, 10000, 1897, "les Audoniens", "el Bauer", "Uno de los clubes más antiguos de París."),
    ("FRA", "Reims", "Champagne Roja", "#d50032", "#ffffff", 62, 21600, 1931, "les Rémois", "el Auguste Delaune", "Una leyenda de las primeras copas de Europa."),
    ("FRA", "Rodez", "Aveyron FC", "#d50032", "#ffd100", 50, 5200, 1920, "les Ruthénois", "el Paul-Lignon", "El club más pequeño del profesionalismo."),
    ("FRA", "Saint-Étienne", "Loire Verde", "#00843d", "#ffffff", 66, 41000, 1933, "les Verts", "el Geoffroy-Guichard", "El club con más ligas de Francia en su época."),
    ("FRA", "Troyes", "Aube Azul", "#0057b8", "#ffffff", 56, 21000, 1986, "les Troyens", "el Stade de l'Aube", "Un club de Champagne que sube y baja."),
]

def _leet(n):
    """El nombre real LIMPIO con un dígito en la primera vocal minúscula posible (`_limpio` debe devolver el mismo nombre)."""
    mapa = {"o": "0", "i": "1", "e": "3", "a": "4", "s": "5", "b": "8", "g": "9"}
    for i, c in enumerate(n):
        if i > 0 and c in mapa and n[i - 1].isalpha():
            cand = n[:i] + mapa[c] + n[i + 1:]
            if _limpio(cand) == n:
                return cand
    return n   ## sin letra que cambiar (p. ej. «Fürth»): se queda en claro

_FORM = ["4-4-2", "4-2-3-1", "4-3-3", "3-5-2", "4-4-2", "5-3-2", "4-3-3", "4-2-3-1"]
_EST = ["bloque", "equilibrado", "presion", "directo", "garra", "contra", "posesion", "vertical", "ofensivo"]

for _i, _f in enumerate(DATOS3):
    NUEVOS.append((_f[0], _leet(_f[1]), _f[2], _f[3], _f[4], _f[5], _f[6], _FORM[_i % 8], _EST[_i % 9]))
    HISTORIA[_f[1]] = (_f[7], _f[8], _f[9], _f[10])

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
    usados = set()
    for i, f in enumerate(NUEVOS):
        n = _limpio(f[1])
        letras = "".join(c for c in n if c.isalpha() and c.isascii() and c.isupper())[:3] or n[:3].upper()
        if len(letras) < 2:
            letras = "".join(c for c in n if c.isascii() and c.isalpha()).upper()[:3]
        franjas = i % 3 == 0
        c1, c2 = f[3], f[4]
        ## El escudo de cada club es único (prueba M-062): forma por i % 8 y patrón desplazado según el grupo de ocho.
        k = (i // 8 + i) % 7
        while (formas[i % 8], patrones[k], f[3], f[4]) in usados:   # el escudo (forma+patrón+colores) no se repite
            k = (k + 1) % 7
        usados.add((formas[i % 8], patrones[k], f[3], f[4]))
        sal.append("|".join([n, formas[i % 8], patrones[k], letras, "franjas" if franjas else "liso",
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
