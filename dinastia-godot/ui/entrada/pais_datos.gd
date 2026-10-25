class_name PaisDatos
extends RefCounted
## LOS DATOS DE LA PANTALLA DE PAÍS (fase 1, etapa 3 del plan): el nombre completo de
## cada país, su nombre oficial, el continente con el que se agrupa en la lista y los
## CINCO MONUMENTOS que rotan de fondo cada 30 s.
##
## POR QUÉ UNA TABLA PROPIA Y NO `PAIS_SELECCION`: esa tabla es la de las selecciones y
## abrevia («EE.UU.», «Corea», «Arabia»), que en un marcador cabe y en el título de una
## pantalla entera se lee pobre. Aquí va el nombre de verdad.
##
## LOS MONUMENTOS son lugares reales y conocidos (edificios, puentes, montañas, ruinas),
## elegidos para reconocerse por la SILUETA: no hay red en el entorno (Wikimedia está
## bloqueada) y una foto sin licencia no puede entrar al repo, así que cada uno se dibuja
## en código (`PaisTrazo` y sus capas). Se evitaron a propósito los lugares de culto en
## activo como icono de fondo -un juego de fútbol no tiene por qué decorar con ellos-;
## las ruinas y obras históricas sí están. Cada fila es [nombre, tipo, variante]: el tipo
## elige la función que lo dibuja y la variante la forma concreta.

const NOMBRE := {
	"CHI": "Chile", "ARG": "Argentina", "BRA": "Brasil", "URU": "Uruguay", "PAR": "Paraguay",
	"BOL": "Bolivia", "PER": "Perú", "ECU": "Ecuador", "COL": "Colombia", "VEN": "Venezuela",
	"ESP": "España", "ENG": "Inglaterra", "ITA": "Italia", "GER": "Alemania", "FRA": "Francia",
	"JPN": "Japón", "KOR": "Corea del Sur", "KSA": "Arabia Saudita", "EGY": "Egipto",
	"MAR": "Marruecos", "RSA": "Sudáfrica", "AUS": "Australia", "MEX": "México", "USA": "Estados Unidos",
}

const OFICIAL := {
	"CHI": "República de Chile", "ARG": "República Argentina", "BRA": "República Federativa del Brasil",
	"URU": "República Oriental del Uruguay", "PAR": "República del Paraguay",
	"BOL": "Estado Plurinacional de Bolivia", "PER": "República del Perú", "ECU": "República del Ecuador",
	"COL": "República de Colombia", "VEN": "República Bolivariana de Venezuela", "ESP": "Reino de España",
	"ENG": "Inglaterra, Reino Unido", "ITA": "República Italiana", "GER": "República Federal de Alemania",
	"FRA": "República Francesa", "JPN": "Estado del Japón", "KOR": "República de Corea",
	"KSA": "Reino de Arabia Saudita", "EGY": "República Árabe de Egipto", "MAR": "Reino de Marruecos",
	"RSA": "República de Sudáfrica", "AUS": "Mancomunidad de Australia", "MEX": "Estados Unidos Mexicanos",
	"USA": "Estados Unidos de América",
}

## El orden de la lista: por continente, y dentro de cada uno como los ordena el juego.
const CONTINENTES := [
	["Sudamérica", ["CHI", "ARG", "BRA", "URU", "PAR", "BOL", "PER", "ECU", "COL", "VEN"]],
	["Europa", ["ESP", "ENG", "ITA", "GER", "FRA"]],
	["Norteamérica", ["MEX", "USA"]],
	["Asia", ["JPN", "KOR", "KSA"]],
	["África", ["EGY", "MAR", "RSA"]],
	["Oceanía", ["AUS"]],
]

const MONUMENTOS := {
	"CHI": [["Moáis de Rapa Nui", "moai", "fila"], ["Torres del Paine", "montana", "agujas"],
		["Volcán Osorno", "montana", "cono"], ["Gran Torre Santiago", "rascacielos", "aguja"],
		["Observatorios de Atacama", "cupula", "observatorio"]],
	"ARG": [["Obelisco de Buenos Aires", "obelisco", ""], ["Cataratas del Iguazú", "catarata", "ancha"],
		["Glaciar Perito Moreno", "montana", "glaciar"], ["Aconcagua", "montana", "nevado"],
		["Puente de la Mujer", "puente", "mastil"]],
	"BRA": [["Cristo Redentor", "estatua", "brazos"], ["Pan de Azúcar", "montana", "pan"],
		["Congreso Nacional", "rascacielos", "congreso"], ["Teatro Amazonas", "cupula", "teatro"],
		["Museo de Arte Contemporáneo de Niterói", "platillo", ""]],
	"URU": [["La Mano de Punta del Este", "mano", ""], ["Palacio Salvo", "rascacielos", "palacio"],
		["Faro de Colonia del Sacramento", "faro", ""], ["Puerta de la Ciudadela", "arco", "ciudadela"],
		["Palacio Legislativo", "cupula", "legislativo"]],
	"PAR": [["Panteón Nacional de los Héroes", "cupula", "panteon"], ["Represa de Itaipú", "presa", ""],
		["Ruinas de Trinidad", "ruinas", ""], ["Saltos del Monday", "catarata", "ancha"],
		["Palacio de López", "cupula", "torre"]],
	"BOL": [["Puerta del Sol de Tiwanaku", "arco", "tiwanaku"], ["Salar de Uyuni", "montana", "salar"],
		["Illimani", "montana", "nevado"], ["Teleférico de La Paz", "teleferico", ""],
		["Cerro Rico de Potosí", "montana", "cerro"]],
	"PER": [["Machu Picchu", "montana", "terrazas"], ["Huascarán", "montana", "nevado"],
		["Montaña de Siete Colores", "montana", "colores"], ["Fortaleza de Sacsayhuamán", "muralla", "zigzag"],
		["Ciudadela de Chan Chan", "muralla", "adobe"]],
	"ECU": [["Monumento a la Mitad del Mundo", "mitad_mundo", ""], ["Volcán Chimborazo", "montana", "nevado"],
		["Volcán Cotopaxi", "montana", "cono"], ["Arco de Darwin", "arco", "natural"],
		["Faro del cerro Santa Ana", "faro", ""]],
	"COL": [["Piedra del Peñol", "montana", "pan"], ["Castillo de San Felipe", "castillo", "fortaleza"],
		["Torre del Reloj de Cartagena", "torre_reloj", "puerta"], ["Valle de Cocora", "palmeras", ""],
		["Puente de Occidente", "puente", "colgante"]],
	"VEN": [["Salto Ángel", "catarata", "alta"], ["Monte Roraima", "montana", "mesa"],
		["Pico Bolívar", "montana", "nevado"], ["Puente sobre el Lago de Maracaibo", "puente", "atirantado"],
		["Torres de Parque Central", "rascacielos", "gemelas"]],
	"ESP": [["Sagrada Familia", "agujas", ""], ["Acueducto de Segovia", "acueducto", ""],
		["La Alhambra", "castillo", "fortaleza"], ["Puerta de Alcalá", "arco", "tres"],
		["Molinos de Consuegra", "molino", ""]],
	"ENG": [["Big Ben", "torre_reloj", ""], ["Tower Bridge", "puente", "basculante"],
		["London Eye", "noria", ""], ["Stonehenge", "piedras", ""], ["Castillo de Windsor", "castillo", "fortaleza"]],
	"ITA": [["Coliseo", "coliseo", ""], ["Torre de Pisa", "torre_inclinada", ""],
		["Puente de Rialto", "puente", "rialto"], ["Vesubio", "montana", "volcan"],
		["Panteón de Roma", "columnas", "panteon"]],
	"GER": [["Puerta de Brandeburgo", "columnas", "brandeburgo"], ["Castillo de Neuschwanstein", "castillo", "cuentos"],
		["Torre de Televisión de Berlín", "torre_tv", "bola"], ["Puerta de Holsten", "castillo", "holsten"],
		["Zugspitze", "montana", "nevado"]],
	"FRA": [["Torre Eiffel", "celosia", ""], ["Arco de Triunfo", "arco", "triunfo"],
		["Monte Saint-Michel", "montana", "isla"], ["Pirámide del Louvre", "piramide", "cristal"],
		["Mont Blanc", "montana", "nevado"]],
	"JPN": [["Monte Fuji", "montana", "cono"], ["Castillo de Himeji", "pagoda", "castillo"],
		["Torre de Tokio", "celosia", "tokio"], ["Tokyo Skytree", "torre_tv", "aguja"],
		["Puente Akashi Kaikyō", "puente", "colgante"]],
	"KOR": [["Torre N de Seúl", "torre_tv", "disco"], ["Puerta Gwanghwamun", "pagoda", "puerta"],
		["Lotte World Tower", "rascacielos", "aguja"], ["Monte Hallasan", "montana", "volcan"],
		["Fortaleza de Hwaseong", "muralla", "puerta"]],
	"KSA": [["Kingdom Centre", "rascacielos", "agujero"], ["Fortaleza de Masmak", "castillo", "adobe"],
		["Roca del Elefante de AlUla", "arco", "natural"], ["Tumbas de Hegra", "montana", "tumba"],
		["El Borde del Mundo", "montana", "acantilado"]],
	"EGY": [["Pirámides de Guiza", "piramide", "guiza"], ["Gran Esfinge de Guiza", "esfinge", ""],
		["Columnas de Karnak", "columnas", "karnak"], ["Torre de El Cairo", "torre_tv", "celosia"],
		["Obelisco de Luxor", "obelisco", ""]],
	"MAR": [["Kasbah de Aït Ben Haddou", "castillo", "adobe"], ["Puerta Bab Mansour", "arco", "ornada"],
		["Dunas de Merzouga", "dunas", ""], ["Montes Atlas", "montana", "nevado"],
		["Faro de Cabo Espartel", "faro", ""]],
	"RSA": [["Table Mountain", "montana", "mesa"], ["Faro de Cape Point", "faro", ""],
		["Puente Nelson Mandela", "puente", "atirantado"], ["Drakensberg", "montana", "agujas"],
		["Torre Hillbrow", "torre_tv", "disco"]],
	"AUS": [["Ópera de Sídney", "opera", ""], ["Harbour Bridge", "puente", "arco"],
		["Uluru", "montana", "roca"], ["Los Doce Apóstoles", "farallones", ""],
		["Torre de Sídney", "torre_tv", "disco"]],
	"MEX": [["Chichén Itzá", "piramide_escalonada", "templo"], ["Ángel de la Independencia", "estatua", "columna"],
		["Palacio de Bellas Artes", "cupula", "palacio"], ["Popocatépetl", "montana", "cono"],
		["Pirámide del Sol", "piramide_escalonada", "sol"]],
	"USA": [["Estatua de la Libertad", "estatua", "antorcha"], ["Puente Golden Gate", "puente", "colgante"],
		["Empire State Building", "rascacielos", "escalonado"], ["Monumento a Washington", "obelisco", ""],
		["Capitolio", "cupula", "capitolio"]],
}

## Todos los países que se pueden ver en el globo, en el orden de la lista.
static func todos() -> Array[String]:
	var salida: Array[String] = []
	for c: Array in CONTINENTES:
		for p: String in c[1]:
			salida.append(p)
	return salida

## El nombre completo, ya en el idioma del jugador («Corea del Sur», no «KOR»).
static func nombre(p: String) -> String:
	return Idiomas.t(String(NOMBRE.get(p, p)))

static func oficial(p: String) -> String:
	return Idiomas.t(String(OFICIAL.get(p, "")))

static func monumentos(p: String) -> Array:
	return MONUMENTOS.get(p, [])

static func continente_de(p: String) -> String:
	for c: Array in CONTINENTES:
		if (c[1] as Array).has(p):
			return String(c[0])
	return ""

## Las filas de clubes de la liga de un país, como las trae la tabla del HTML:
## [nombre, color1, color2, reputación, aforo]. Chile tiene dos divisiones; aquí va la
## primera, que es la que se enseña. Vacío si el país no tiene liga en el juego
## (Venezuela tiene pin en el globo, pero ninguna liga en `PAISES_LIGAS`).
static func filas_clubes(p: String) -> Array:
	if p == "CHI":
		var p1: Variant = Datos.tabla("DATA_P1")
		return p1 if p1 is Array else []
	var pl: Variant = Datos.tabla("PAISES_LIGAS")
	if pl is Dictionary and (pl as Dictionary).has(p):
		return (pl[p] as Dictionary).get("clubes", [])
	return []

static func tiene_liga(p: String) -> bool:
	return not filas_clubes(p).is_empty()

## El nombre de la primera división del país, tal como lo ve el resto del juego.
static func nombre_liga(p: String) -> String:
	if p == "CHI":
		return Idiomas.t("Primera División")
	var pl: Variant = Datos.tabla("PAISES_LIGAS")
	if pl is Dictionary and (pl as Dictionary).has(p):
		return Idiomas.t(Nombres.de_tabla(String((pl[p] as Dictionary).get("liga", p))))
	return ""

## El nivel de la liga de 1 a 5 estrellas, sacado de `TIER_PAIS` (el multiplicador de
## presupuestos del país: Inglaterra 2,4 · Bolivia 0,18). Escala logarítmica, porque
## entre la primera y la última hay un factor 13 y en lineal todas saldrían con una.
static func estrellas(p: String) -> int:
	var t: Variant = Datos.tabla("TIER_PAIS")
	if not (t is Dictionary) or not (t as Dictionary).has(p):
		return 0
	var f := float(t[p])
	return clampi(int(round(3.2 + log(f) / log(2.0) * 1.4)), 1, 5)
