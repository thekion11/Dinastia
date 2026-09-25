#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
BASE FICTICIA Y PACK REAL
=========================

Separa todo lo que tiene nombre de marca o de persona real de `tablas.json`:

  * `dinastia-godot/datos/tablas.json`     -> BASE FICTICIA (la que se publica)
  * `dinastia-godot/datos/pack_real.json`  -> PACK REAL (solo uso privado; se
    excluye de todas las exportaciones en `export_presets.cfg`)

Por que existe: el analisis externo del 25-9-2026 marco lo legal como el
bloqueo principal para vender el juego. Clubes reales, jugadores reales con
nombre y apellido, fotos de caras sacadas de Wikidata/Commons, equipaciones
reales, nombres de ligas y copas registrados (Premier League, Libertadores,
Champions...) y arbitros reales. Ningun manager comercial sin licencia sale
asi: sale con una base inventada y deja que la comunidad cargue la real por su
cuenta (PES, Football Manager con "real name fix", etc.). Eso es exactamente lo
que se monta aqui: `Datos.usar_base_real()` superpone el pack encima de la base
cuando el jugador lo elige y el pack existe.

Es IDEMPOTENTE: la fuente de verdad de lo real es el pack si ya existe (despues
de la primera pasada `tablas.json` ya es ficticio y no se puede volver a leer
lo real de ahi). Correrlo dos veces deja los dos archivos igual.

    python3 herramientas/base_ficticia.py            # regenera los dos
    python3 herramientas/base_ficticia.py --comprobar # solo valida, no escribe

Reglas de los nombres ficticios (comprobadas al final, el script falla si no):
  * unicos entre si y distintos de cualquier nombre real de la tabla;
  * maximo 16 caracteres (lo que ya aguantaba la interfaz con "Indep. Petrolero");
  * sin digitos pegados a letras (`Nombres.limpiar()` los convertiria en letras);
  * evocan la ciudad, el barrio, el rio o el color del club original, pero no
    usan su nombre registrado ni su apodo comercial.
"""
import hashlib
import json
import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATOS = os.path.join(RAIZ, "dinastia-godot", "datos")
TABLAS = os.path.join(DATOS, "tablas.json")
PACK = os.path.join(DATOS, "pack_real.json")

# Tablas que el pack reemplaza enteras cuando se activa la base real.
TABLAS_DEL_PACK = [
    "DATA_P1", "DATA_P2", "PAISES_LIGAS", "CONFED", "COPA_NOM",
    "ARBITROS", "REALES", "EQUIP_REAL", "PROVEEDORES",
]

# ---------------------------------------------------------------------------
#  CLUBES: nombre real (ya sin leetspeak) -> nombre ficticio
# ---------------------------------------------------------------------------
CLUBES = {
    # -- Chile, Primera --------------------------------------------------
    "Colo-Colo": "Lautaro FC",
    "U. de Chile": "U. Andina",
    "U. Católica": "Precordillera",
    "Coquimbo Unido": "Puerto Coquimbo",
    "Cobresal": "Cobre Atacama",
    "Palestino": "Levantino SC",
    "Unión Española": "Hispania SC",
    "Audax Italiano": "Itálica FC",
    "Huachipato": "Acero Talcahuano",
    "Ñublense": "Chillán Rojo",
    "O'Higgins": "Rancagua Celeste",
    "Everton": "Viña Marina",
    "D. Iquique": "Iquique Celeste",
    "U. La Calera": "Cemento Calera",
    "La Serena": "Elqui FC",
    "D. Limache": "Marga Marga FC",
    # -- Chile, Primera B ------------------------------------------------
    "Cobreloa": "Calama Naranja",
    "S. Wanderers": "Porteño FC",
    "U. de Concepción": "U. Penquista",
    "Rangers": "Talca Rojinegra",
    "Magallanes": "Academia SC",
    "Curicó Unido": "Mataquito FC",
    "Antofagasta": "Norte Grande",
    "D. Concepción": "Concepción Lila",
    "Stgo. Morning": "Stgo. Aurora",
    "San Luis": "Quillota Canaria",
    "D. Temuco": "Cautín FC",
    "D. Copiapó": "Atacama León",
    "San Marcos": "Arica Morro",
    "Recoleta": "Patronato SC",
    "Santa Cruz": "Colchagua FC",
    "Pto. Montt": "Reloncaví FC",
    # -- Argentina -------------------------------------------------------
    "Boca Juniors": "Riachuelo AC",
    "River Plate": "Núñez Athletic",
    "Racing Club": "Avellaneda Cel.",
    "San Lorenzo": "Boedo AC",
    "Independiente": "Avellaneda Rojo",
    "Estudiantes": "Diagonal FC",
    "Vélez": "Villa Luro FC",
    "Huracan": "Parque Patricios",
    "Rosario Central": "Arroyito FC",
    "Newell's": "Parque Rosario",
    "Lanús": "Granate Sur",
    "Talleres": "Jardín Córdoba",
    "Banfield": "Lomas Verdes",
    "Godoy Cruz": "Mendoza Andes",
    "Colón": "Costanera SF",
    "Unión SF": "Litoral SF",
    # -- Brasil ----------------------------------------------------------
    "Flamengo": "Gávea RJ",
    "Palmeiras": "Pompeia SC",
    "Sao Paulo": "Morumbi FC",
    "Gremio": "Azenha FC",
    "Corinthians": "São Jorge SP",
    "Santos": "Baixada FC",
    "Fluminense": "Laranjeiras FC",
    "Botafogo": "Estrela Rio",
    "Cruzeiro": "Barro Preto FC",
    "Atl. Mineiro": "Belo Horizonte",
    "Internacional": "Guaíba FC",
    "Vasco": "Almirante RJ",
    "Bahia": "Itapuã FC",
    "Fortaleza": "Pici FC",
    "Athletico PR": "Araucária PR",
    "Goiás": "Serrinha FC",
    # -- Uruguay ---------------------------------------------------------
    "Peñarol": "Ferroviario UY",
    "Nacional": "Tricolor MVD",
    "Defensor": "Punta Carretas",
    "Danubio": "Maroñas FC",
    "Wanderers": "Prado FC",
    "Liverpool M.": "Belvedere FC",
    "River (U)": "Capurro FC",
    "Cerro (U)": "Villa del Cerro",
    "Boston River": "Sayago FC",
    "Racing (U)": "Aguada FC",
    "Progreso": "La Teja FC",
    "Fénix": "Violeta MVD",
    "Plaza Colonia": "Sacramento FC",
    "Montevideo C.": "Malvín FC",
    "Juventud": "Las Piedras FC",
    "Rentistas": "Cerrito FC",
    # -- Paraguay --------------------------------------------------------
    "Olimpia": "Franja FC",
    "Cerro Porteño": "Barrio Obrero",
    "Libertad": "Tuyucuá FC",
    "Guarani": "Dos Bocas FC",
    "Nacional (P)": "Tricolor ASU",
    "Sol de América": "Villa Elisa FC",
    "Luqueño": "Luque FC",
    "Doce de Octubre": "Itauguá FC",
    "Tacuari": "Tacumbú FC",
    "Gral. Caballero": "Alto Paraná FC",
    "Ameliano": "Tembetary FC",
    "Trinidense": "Santísima FC",
    "2 de Mayo": "Pedro Juan FC",
    "Rubio Ñu": "Ñu Guasu FC",
    "Fernando Mora": "Ypacaraí FC",
    "Resistencia": "Mburicaó FC",
    # -- Colombia --------------------------------------------------------
    "Atl. Nacional": "Antioquia Verde",
    "Millonarios": "Bogotá Azul",
    "America de Cali": "Cali Escarlata",
    "Junior": "Curramba FC",
    "Santa Fe": "Cardenal Bogotá",
    "Dep. Cali": "Azucarero FC",
    "Tolima": "Pijao FC",
    "DIM Medellin": "Medellín Rojo",
    "Once Caldas": "Manizales FC",
    "Bucaramanga": "Santander FC",
    "Pereira": "Matecaña FC",
    "La Equidad": "Bogotá Verde",
    "Envigado": "Aburrá FC",
    "Alianza FC": "Cesar FC",
    "Fortaleza C.": "Sabana FC",
    "Boyacá Chicó": "Tunja FC",
    # -- Peru ------------------------------------------------------------
    "Universitario": "Lima Crema",
    "Alianza Lima": "La Victoria FC",
    "Sporting Cristal": "Rímac FC",
    "Melgar": "Misti FC",
    "Cienciano": "Imperial CUS",
    "Sport Boys": "Callao Rosado",
    "Municipal": "Cercado FC",
    "Cusco FC": "Qosqo FC",
    "C. Vallejo": "Moche FC",
    "Atl. Grau": "Tallán FC",
    "Garcilaso": "Wiracocha FC",
    "AD Tarma": "Andino Tarma",
    "UTC Cajamarca": "Cajamarca FC",
    "Binacional": "Titicaca FC",
    "Ayacucho": "Huamanga FC",
    "Chankas": "Andahuaylas FC",
    # -- Ecuador ---------------------------------------------------------
    "LDU Quito": "Ponceano FC",
    "Barcelona SC": "Torero GYE",
    "Emelec": "Eléctrico FC",
    "I. del Valle": "Sangolquí FC",
    "Aucas": "Chillogallo FC",
    "El Nacional": "Criollos UIO",
    "Delfin": "Manabí FC",
    "U. Católica (E)": "Chimbacalle FC",
    "Orense": "Oro Machala",
    "Técnico U.": "Tungurahua FC",
    "Mushuc Runa": "Runa Andina",
    "Macara": "Ambato Celeste",
    "Guayaquil C.": "Salado FC",
    "Cumbaya": "Tumbaco FC",
    "Imbabura": "Ibarra FC",
    "9 de Octubre": "Malecón GYE",
    # -- Espana ----------------------------------------------------------
    "Real Madrid": "Castellana CF",
    "Barcelona": "Comtal FC",
    "Atlético Madrid": "Neptuno AC",
    "Sevilla": "Nervión FC",
    "Valencia": "Turia CF",
    "Villarreal": "Madrigal CF",
    "Ath. Bilbao": "Abando AC",
    "Real Sociedad": "Anoeta CF",
    "Betis": "Heliópolis CF",
    "Celta Vigo": "Olívico CF",
    "Getafe": "Alhóndiga CF",
    "Osasuna": "Iruña CF",
    "Girona": "Onyar CF",
    "Mallorca": "Balear CF",
    "Espanyol": "Sarrià CE",
    "Rayo Vallecano": "Vallecas Franja",
    # -- Inglaterra ------------------------------------------------------
    "Manchester Utd": "Trafford Reds",
    "City de Manch.": "Eastlands FC",
    "Liverpool": "Mersey Reds",
    "Arsenal": "Islington FC",
    "Chelsea": "Kensington FC",
    "Tottenham": "Lilywhite FC",
    "Newcastle": "Tyneside FC",
    "Aston Villa": "Holte FC",
    "West Ham": "Upton FC",
    "Everton FC": "Mersey Blues",
    "Brighton": "Sussex FC",
    "Wolves": "Black Country",
    "Cristal Palace": "Selhurst FC",
    "Fulham": "Putney FC",
    "Brentford": "Griffin FC",
    "Nottingham F.": "Trent Reds",
    # -- Italia ----------------------------------------------------------
    "Juventus": "Piemonte FC",
    "Milan": "Navigli FC",
    "Inter": "Duomo FC",
    "Napoli": "Partenope FC",
    "Roma": "Capitolina",
    "Lazio": "Tevere FC",
    "Atalanta": "Orobica FC",
    "Fiorentina": "Arno FC",
    "Torino": "Superga FC",
    "Bologna": "Felsinea FC",
    "Udinese": "Friuli FC",
    "Sampdoria": "Ligure Blu",
    "Genoa": "Zena FC",
    "Sassuolo": "Secchia FC",
    "Monza": "Brianza FC",
    "Lecce": "Salento FC",
    # -- Alemania --------------------------------------------------------
    "Bayern Múnich": "Isar FC",
    "Dortmund": "Borsigplatz FC",
    "Leipzig": "Pleiße FC",
    "Leverkusen": "Wupper FC",
    "Frankfurt": "Main FC",
    "Wolfsburgo": "Aller FC",
    "Gladbach": "Niederrhein",
    "Friburgo": "Breisgau FC",
    "Stuttgart": "Neckar FC",
    "Hoffenheim": "Kraichgau FC",
    "Unión Berlín": "Köpenick FC",
    "Mainz": "Rheinhessen",
    "Colonia": "Domstadt FC",
    "Bremen": "Weser FC",
    "Bochum": "Ruhrpott FC",
    "Augsburgo": "Lech FC",
    # -- Francia ---------------------------------------------------------
    "Paris SG": "Lutèce FC",
    "Marsella": "Massilia FC",
    "Lyon": "Lugdunum FC",
    "Monaco": "Rocher FC",
    "Lille": "Flandres FC",
    "Niza": "Nikaïa FC",
    "Rennes": "Vilaine FC",
    "Lens": "Artois FC",
    "Nantes": "Loire FC",
    "Estrasburgo": "Alsace FC",
    "Toulouse": "Garonne FC",
    "Montpellier": "Hérault FC",
    "Brest": "Finistère FC",
    "Reims": "Champagne FC",
    "Lorient": "Morbihan FC",
    "Auxerre": "Yonne FC",
    # -- Bolivia ---------------------------------------------------------
    "Bolivar": "Celeste La Paz",
    "The Strongest": "Achumani FC",
    "Always Ready": "Altiplano FC",
    "Blooming": "Piraí FC",
    "Oriente P.": "Chiquitano FC",
    "Wilstermann": "Aviador FC",
    "San José": "Oruro FC",
    "Guabira": "Montero FC",
    "Tomayapo": "Tarija FC",
    "Nac. Potosí": "Cerro Rico FC",
    "Aurora": "Tunari FC",
    "Indep. Petrolero": "Chuquisaca FC",
    "R. Santa Cruz": "Guapay FC",
    "Palmaflor": "Quillacollo FC",
    "Vaca Diez": "Cobija FC",
    "Univ. de Vinto": "Valle Alto FC",
    # -- Japon -----------------------------------------------------------
    "Kawasaki F.": "Tamagawa FC",
    "Yokohama FM": "Yokohama Bay",
    "Kashima A.": "Ibaraki FC",
    "Urawa Reds": "Saitama Red",
    "Vissel Kobe": "Rokko FC",
    "Gamba Osaka": "Suita FC",
    "FC Tokio": "Musashi FC",
    "Sanfrecce H.": "Setouchi FC",
    "Cerezo Osaka": "Naniwa FC",
    "Nagoya G.": "Owari FC",
    "Konsadole S.": "Ishikari FC",
    "Avispa F.": "Hakata FC",
    "Shimonoseki": "Kanmon FC",
    "Kyoto S.": "Kamo FC",
    "Albirex N.": "Shinano FC",
    "Shonan B.": "Sagami FC",
    # -- Corea -----------------------------------------------------------
    "Ulsan HD": "Taehwa FC",
    "Jeonbuk M.": "Honam FC",
    "Pohang S.": "Hyeongsan FC",
    "FC Seoul": "Hangang FC",
    "Incheon Utd": "Wolmi FC",
    "Daejeon H.": "Gapcheon FC",
    "Gangwon FC": "Seorak FC",
    "Suon FC": "Paldal FC",
    "Gwangju FC": "Mudeung FC",
    "Jeju United": "Halla FC",
    "Daegu FC": "Palgong FC",
    "Gimcheon": "Jikji FC",
    "Seongnam": "Namhan FC",
    "Busan IPark": "Haeundae FC",
    "Ansan G.": "Sihwa FC",
    "Ch. Citizen": "Chungnam FC",
    # -- Arabia Saudi ----------------------------------------------------
    "Al-Hilal": "Al-Qamar",
    "Al-Nassr": "Al-Fawz",
    "Al-ittihad": "Al-Jeddawi",
    "Al-ahli SA": "Al-Balad",
    "Al-Shabab": "Al-Fityan",
    "Al-Ettifaq": "Al-Khobar",
    "Al-Taawoun": "Al-Qassim",
    "Al-Faiha": "Al-Majmaah",
    "Al-Raed": "Buraidah FC",
    "Al-Fateh": "Al-Ahsa",
    "Dammac": "Asir FC",
    "Al-Khaleej": "Saihat FC",
    "Al-Wehda": "Umm Al-Qura",
    "Al-Okgdood": "Najran FC",
    "Al-Riyadh": "Al-Diriyah",
    "Al-Hazem": "Al-Rass",
    # -- Egipto ----------------------------------------------------------
    "Al Ahly": "Al-Nil SC",
    "Zamalek": "Mit Oqba SC",
    "Pyramids": "Sphinx FC",
    "Ismaiiy": "Timsah FC",
    "Al Masry": "Port Said FC",
    "Ceramica C.": "Ramadan City",
    "Fut. Rise": "New Cairo SC",
    "National Bank": "Treasury SC",
    "ENPPi": "Petrol Cairo",
    "Pharco": "Borg Arab SC",
    "Smouha": "Montaza SC",
    "El Gouna": "Hurghada SC",
    "Baladiyat": "Delta SC",
    "Talaea": "Vanguard SC",
    "Al Mokawloon": "Builders SC",
    "ZED FC": "Zayed SC",
    # -- Marruecos -------------------------------------------------------
    "W. Casablanca": "Anfa FC",
    "Raja C.": "Derb FC",
    "AS FAR": "Chellah FC",
    "RS Berkane": "Moulouya FC",
    "Maghreb Fès": "Médina Fès",
    "MC Oujda": "Oujda FC",
    "FUS Rabat": "Oudayas FC",
    "Hassania A.": "Souss FC",
    "Olympic Safi": "Atlantique Safi",
    "Chabab MA": "Atlas FC",
    "Jeunesse S.": "Berrechid FC",
    "SCC Mohammédia": "Fedala FC",
    "Ittihad Tanger": "Détroit FC",
    "Renaissance Z.": "Doukkala FC",
    "Unión Touarga": "Mechouar FC",
    "COD Meknès": "Volubilis FC",
    # -- Sudafrica -------------------------------------------------------
    "Mamelodi S.": "Tshwane FC",
    "Orlando Pirates": "Jozi Corsairs",
    "Kaizer Chiefs": "Naturena FC",
    "Stelleribosch": "Winelands FC",
    "Sekhukhune": "Groblersdal FC",
    "Cape Town City": "Table Bay FC",
    "Supersport Utd": "Atteridgeville",
    "Richards Bay": "Zululand FC",
    "Golden Arrows": "Lamontville FC",
    "Polokwane": "Pietersburg FC",
    "Chippa Utd": "Gqeberha FC",
    "AmaZalu": "Umgeni FC",
    "Ts. Galaxie": "Venda FC",
    "Maritzburg": "Msunduzi FC",
    "Casric Stars": "Mpumalanga FC",
    "Magesi FC": "Mankweng FC",
    # -- Australia -------------------------------------------------------
    "Melbourne City": "Yarra FC",
    "Sidney FC": "Harbour FC",
    "Melbourne V.": "Port Phillip",
    "C. Coast M.": "Gosford FC",
    "W. Sidney W.": "Parramatta FC",
    "Adelaide Utd": "Torrens FC",
    "Brisbane R.": "Moreton FC",
    "Wellington P.": "Strait FC",
    "Macarthur FC": "Campbelltown FC",
    "Newcastle J.": "Hunter FC",
    "Perth Glory": "Swan FC",
    "W. United": "Wyndham FC",
    "Auckland FC": "Waitematā FC",
    "Canberra Utd": "Molonglo FC",
    "Geelong FC": "Corio FC",
    "Darwin City": "Top End FC",
    # -- Mexico ----------------------------------------------------------
    "America": "Coapa FC",
    "Tigres UANL": "San Nicolás FC",
    "Monterrey": "Cerro Silla FC",
    "Guadalajara": "Occidente FC",
    "Cruz Azul": "La Noria FC",
    "Pachuca": "Hidalgo FC",
    "Toluca": "Nevado FC",
    "Santos Laguna": "Comarca FC",
    "Pumas UNAM": "Pedregal FC",
    "Leon": "Bajío FC",
    "Atlas": "Colomos FC",
    "Necaxa": "Hidrocálido FC",
    "Puebla": "Angelópolis",
    "Tijuana": "Frontera FC",
    "Queretaro": "Bernal FC",
    "Mazatlán": "Sinaloa FC",
    # -- Estados Unidos --------------------------------------------------
    "Inter Miami": "Biscayne FC",
    "LAFC": "Figueroa FC",
    "Seattle S.": "Puget FC",
    "Columbus Crew": "Scioto FC",
    "Philadelphia U.": "Keystone FC",
    "Atlanta Utd": "Peachtree FC",
    "LA Galaxy": "Carson FC",
    "NY City FC": "Hudson FC",
    "N. England R.": "Bay State FC",
    "Austin FC": "Hill Country",
    "Portland T.": "Willamette FC",
    "Orlando City": "Citrus FC",
    "FC Cincinnati": "Riverfront FC",
    "Nashville SC": "Cumberland FC",
    "St. Louis City": "Gateway FC",
    "Charlotte FC": "Piedmont FC",
}

# Nombre de cada liga en PAISES_LIGAS. Chile no esta: sus dos divisiones se
# llaman "Primera Division"/"Primera B" en el codigo, y son genericas.
LIGAS = {
    "BRA": "Liga Brasileña",
    "ESP": "Liga Española",
    "ENG": "Liga Inglesa",
    "ITA": "Liga Italiana",
    "GER": "Liga Alemana",
    "FRA": "Liga Francesa",
    "JPN": "Liga Japonesa",
    "KOR": "Liga Coreana",
    "MAR": "Liga Marroquí",
    "AUS": "Liga Australiana",
    "MEX": "Liga Mexicana",
    "USA": "Liga Norteamericana",
}

# Torneos continentales (clave interna intacta: "lib", "ucl"... la usa el codigo).
CONFED = {
    "lib": "Copa Cóndor",
    "sud": "Copa Cruz del Sur",
    "ucl": "Copa de las Estrellas",
    "uel": "Copa del Viejo Continente",
    "asia": "Copa Asiática de Clubes",
    "afr": "Copa África de Clubes",
    "oce": "Liga de Oceanía",
    "conc": "Copa Norte y Centro",
}

# Copas nacionales que llevan nombre registrado o de patrocinador.
COPAS = {
    "ESP": "Copa de España",
    "ENG": "Copa de Inglaterra",
    "JPN": "Copa de Japón",
    "KSA": "Copa de Arabia",
    "MAR": "Copa de Marruecos",
    "RSA": "Copa de Sudáfrica",
    "MEX": "Copa de México",
    "USA": "Copa de EE.UU.",
}

# Arbitros: los doce de la tabla original coincidian con arbitros chilenos en
# activo. Se conserva el perfil (segunda columna), que es lo que usa el motor.
ARBITROS = [
    "R. Aldunate", "P. Villagrán", "C. Irarrázaval", "J. Echenique",
    "N. Barahona", "F. Cienfuegos", "M. Lastarria", "A. Undurraga",
    "B. Montalva", "E. Larraín", "H. Quiroga", "D. Pradenas",
]

# Proveedores de equipacion: tres de las parodias quedaban a una letra de una
# marca registrada (Adidas, Puma, Nike). La clave interna no cambia.
PROVEEDORES = {
    "korrida": "Korrida",
    "adistar": "Astra Sport",
    "numbra": "Nimbo",
    "pumba": "Salto",
    "volk": "Volkspor",
}

# Bolsas de nombres por pais (`POOLS_EU`). Siete venian copiadas de la
# convocatoria de su seleccion -EE.UU. era "Christian/Weston/Tyler" con
# "Pulisic/McKennie/Adams", Marruecos "Achraf" con "Hakimi"- y el generador
# fabricaba "Mohamed Salah" o "Christian Pulisic" en la base ficticia. Se
# sustituyen por nombres y apellidos comunes de cada pais. Las que ya eran
# genericas (Japon, Corea, Inglaterra, Alemania, Italia) no se tocan.
POOLS = {
    "KSA": (None, ["Al-Harbi", "Al-Otaibi", "Al-Ghamdi", "Al-Zahrani", "Al-Qahtani", "Al-Shammari",
                   "Al-Mutairi", "Al-Anazi", "Al-Subaie", "Al-Juhani", "Al-Rashidi", "Al-Omari",
                   "Al-Khaldi", "Al-Balawi"]),
    "EGY": (None, ["Hassan", "Ibrahim", "Mahmoud", "Abdelrahman", "Farouk", "Mansour", "Soliman",
                   "Nasser", "Fawzy", "Gamal", "Hamdy", "Saber", "Adel", "Ashraf"]),
    "MAR": (["Youssef", "Mehdi", "Hamza", "Othmane", "Soufiane", "Bilal", "Ilias", "Anass",
             "Zakaria", "Amine", "Yassine", "Walid", "Reda", "Ayoub"],
            ["Benali", "El Idrissi", "Bennani", "Alaoui", "Tazi", "Berrada", "Chraibi", "El Amrani",
             "Benjelloun", "Lahlou", "Fassi", "Ouazzani", "Kettani", "Sebti"]),
    "RSA": (None, ["Nkosi", "Dlamini", "Ndlovu", "Mokoena", "Ngcobo", "Mahlangu", "Khumalo",
                   "Mabaso", "Sithole", "Zulu", "Mthembu", "Molefe", "Nel", "Van Wyk"]),
    "AUS": (None, ["Smith", "Jones", "Williams", "Brown", "Wilson", "Taylor", "Nguyen", "Kelly",
                   "Martin", "Anderson", "Thompson", "White", "Walsh", "O'Brien"]),
    "MEX": (["Santiago", "Emiliano", "Fernando", "Ricardo", "Uriel", "Alexis", "Diego", "Erick",
             "Rodolfo", "Luis", "Jorge", "Israel", "Julián", "César"],
            ["Hernández", "García", "Martínez", "López", "González", "Pérez", "Sánchez", "Ramírez",
             "Flores", "Cruz", "Morales", "Ortiz", "Castillo", "Mendoza"]),
    "USA": (["Michael", "Ryan", "Tyler", "Brandon", "Jacob", "Ethan", "Dylan", "Austin", "Josh",
             "Matt", "Chris", "Kevin", "Andrew", "Nathan"],
            ["Johnson", "Miller", "Davis", "Anderson", "Thomas", "Jackson", "Harris", "Clark",
             "Lewis", "Walker", "Young", "Allen", "King", "Scott"]),
}
# Retoques sueltos dentro de bolsas que por lo demas son genericas.
POOLS_CAMBIOS = {
    ("FRA", 0): {"Kylian": "Clément"},
    ("ESP", 1): {"Aduriz": "Olabarria", "Zubizarreta": "Elorza", "Muguruza": "Ibarguren"},
}

# ---------------------------------------------------------------------------

UNLEET = {"0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "8": "b", "9": "g"}


def _es_letra(c):
    u = ord(c)
    return (65 <= u <= 90) or (97 <= u <= 122) or (0xC0 <= u <= 0x17F)


def limpiar(n):
    """Mismo algoritmo que `nucleo/nombres.gd::limpiar()`."""
    o = ""
    for i, c in enumerate(n):
        if c in UNLEET and ((i > 0 and _es_letra(n[i - 1])) or (i + 1 < len(n) and _es_letra(n[i + 1]))):
            o += UNLEET[c]
        else:
            o += c
    return o


def huella(nombre):
    """Mismo calculo que `Nombres.vetado()`: md5 del nombre en minusculas."""
    return hashlib.md5(nombre.strip().lower().encode("utf-8")).hexdigest()[:12]


def leer(ruta):
    with open(ruta, encoding="utf-8") as f:
        return json.load(f)


def escribir(ruta, datos):
    with open(ruta, "w", encoding="utf-8", newline="") as f:
        f.write(json.dumps(datos, ensure_ascii=False, separators=(",", ":")))


def main():
    solo_comprobar = "--comprobar" in sys.argv
    base = leer(TABLAS)
    if os.path.exists(PACK):
        real = leer(PACK)["tablas"]
    else:
        real = {k: base[k] for k in TABLAS_DEL_PACK}

    errores = []

    # 1. Lista de clubes reales, limpia, en el orden de las tablas.
    reales = []
    for fila in real["DATA_P1"] + real["DATA_P2"]:
        reales.append(limpiar(fila[0]))
    for pais, d in real["PAISES_LIGAS"].items():
        for fila in d["clubes"]:
            reales.append(limpiar(fila[0]))
    faltan = [n for n in reales if n not in CLUBES]
    sobran = [n for n in CLUBES if n not in reales]
    if faltan:
        errores.append("clubes sin nombre ficticio: %s" % faltan)
    if sobran:
        errores.append("nombres ficticios de clubes que ya no existen: %s" % sobran)

    ficticios = list(CLUBES.values())
    repes = sorted({n for n in ficticios if ficticios.count(n) > 1})
    if repes:
        errores.append("nombres ficticios repetidos: %s" % repes)
    reales_bajos = {n.lower() for n in reales}
    choques = [n for n in ficticios if n.lower() in reales_bajos]
    if choques:
        errores.append("nombres ficticios iguales a uno real: %s" % choques)
    largos = [n for n in ficticios if len(n) > 16]
    if largos:
        errores.append("nombres de mas de 16 caracteres: %s" % largos)
    pegados = [n for n in ficticios if limpiar(n) != n]
    if pegados:
        errores.append("nombres que Nombres.limpiar() alteraria: %s" % pegados)

    if errores:
        for e in errores:
            print("ERROR:", e)
        sys.exit(1)

    # 2. Construir la base ficticia a partir de lo real.
    def renombrar(filas):
        salida = []
        for fila in filas:
            nueva = list(fila)
            nueva[0] = CLUBES[limpiar(fila[0])]
            salida.append(nueva)
        return salida

    fic = {}
    fic["DATA_P1"] = renombrar(real["DATA_P1"])
    fic["DATA_P2"] = renombrar(real["DATA_P2"])
    fic["PAISES_LIGAS"] = {}
    for pais, d in real["PAISES_LIGAS"].items():
        nd = dict(d)
        nd["clubes"] = renombrar(d["clubes"])
        if pais in LIGAS:
            nd["liga"] = LIGAS[pais]
        fic["PAISES_LIGAS"][pais] = nd
    fic["CONFED"] = {}
    for clave, d in real["CONFED"].items():
        nd = dict(d)
        nd["n"] = CONFED[clave]
        fic["CONFED"][clave] = nd
    fic["COPA_NOM"] = dict(real["COPA_NOM"])
    fic["COPA_NOM"].update(COPAS)
    if len(ARBITROS) != len(real["ARBITROS"]):
        print("ERROR: hay %d arbitros reales y %d ficticios" % (len(real["ARBITROS"]), len(ARBITROS)))
        sys.exit(1)
    fic["ARBITROS"] = [[ARBITROS[i], fila[1]] for i, fila in enumerate(real["ARBITROS"])]
    fic["PROVEEDORES"] = []
    for fila in real["PROVEEDORES"]:
        nueva = list(fila)
        if fila[0] in PROVEEDORES:
            nueva[1] = PROVEEDORES[fila[0]]
        fic["PROVEEDORES"].append(nueva)
    # Sin jugadores reales ni fotos de equipaciones reales.
    fic["REALES"] = {}
    fic["EQUIP_REAL"] = {}

    # Bolsas de nombres (viven solo en la base: no son datos reales).
    pools = base["POOLS_EU"]
    for pais, (nombres, apellidos) in POOLS.items():
        if nombres is not None:
            pools[pais][0] = nombres
        if apellidos is not None:
            pools[pais][1] = apellidos
    for (pais, i), cambios in POOLS_CAMBIOS.items():
        pools[pais][i] = [cambios.get(n, n) for n in pools[pais][i]]

    # NOMBRES VETADOS: la huella (md5 del nombre en minusculas, 12 hex) de cada
    # jugador real del pack. El generador vuelve a sortear si le sale una
    # combinacion real -"Claudio Bravo" sale solo con NOMBRES/APELLIDOS
    # chilenos-, y con huellas la base no lleva ni un nombre legible.
    vetados = set()
    for club, filas in real["REALES"].items():
        for fila in filas:
            vetados.add(huella(fila.split("|")[0]))
    base["NOMBRES_VETADOS"] = sorted(vetados)

    print("clubes renombrados: %d" % len(reales))
    print("ligas renombradas: %d, torneos continentales: %d, copas: %d, arbitros: %d"
          % (len(LIGAS), len(CONFED), len(COPAS), len(ARBITROS)))
    print("jugadores reales que pasan al pack: %d"
          % sum(len(v) for v in real["REALES"].values()))

    if solo_comprobar:
        print("--comprobar: nada escrito")
        return

    pack = {
        "formato": 1,
        "nombre": "Base real",
        "descripcion": "Clubes, ligas, copas, jugadores y equipaciones reales. "
                       "Solo para uso privado: no se incluye en las versiones publicadas.",
        "tablas": {k: real[k] for k in TABLAS_DEL_PACK},
    }
    escribir(PACK, pack)
    for k in TABLAS_DEL_PACK:
        base[k] = fic[k]
    escribir(TABLAS, base)
    print("escrito:", os.path.relpath(TABLAS, RAIZ), "y", os.path.relpath(PACK, RAIZ))


if __name__ == "__main__":
    main()
