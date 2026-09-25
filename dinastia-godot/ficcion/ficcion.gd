class_name Ficcion
extends RefCounted
## Capa de indirección legal entre los datos de plantilla y lo que
## aparece en pantalla. Permite que el juego sea "inspirado en" sin
## ser "una copia de".
##
## Cada entrada mapea nombre_real → nombre_ficcion. Las variantes
## conservan la fonética o el origen geográfico del nombre real,
## pero son inventadas: no son marcas registradas ni nombres de
## personas reales con derechos sobre su imagen deportiva.
##
## REGLAS DE VARIANTE:
##   Clubes    → sufijo o prefijo geográfico leve   ("Colo-Colo" → "Cóndor FC")
##   Jugadores → cambio de vocal o sílaba final      ("Vidal" → "Vidal A.")
##   Ligas     → nombre descriptivo genérico          ("Primera División" → "Liga Premier")
##
## Un nombre que NO está en el diccionario pasa sin cambios: el sistema
## es aditivo, no rompe lo que ya funciona ni toca los IDs internos.
##
## IMPORTANTE: aplicar SOLO en la capa de presentación (ui/*.gd).
## El núcleo (nucleo/*.gd) compara IDs y nombres internamente; si se
## filtraran allí, las búsquedas en tablas romperían.

const _VARIANTES: Dictionary = {
	# ── CLUBES CHILE ────────────────────────────────────────────────────────
	"Colo-Colo":                 "Cóndor FC",
	"Universidad de Chile":      "Estadio Azul CF",
	"Universidad Católica":      "Cruzados SC",
	"Audax Italiano":            "Fénix Italiano",
	"Deportes Iquique":          "Tarapacá FC",
	"Cobreloa":                  "Cobre FC",
	"Everton":                   "Everton Viña",
	"Palestino":                 "Club Palestino",
	"Deportes Antofagasta":      "Atacama FC",
	"Huachipato":                "Acero CF",
	"Deportes La Serena":        "Elqui FC",
	"O'Higgins":                 "Rancagua United",
	"Curicó Unido":              "Curicó FC",
	"Deportes Temuco":           "Araucanía FC",
	"Deportes Puerto Montt":     "Los Lagos FC",
	"Santiago Wanderers":        "Wanderers SC",
	"San Luis de Quillota":      "Quillota FC",
	"Deportes Melipilla":        "Melipilla FC",
	"Ñublense":                  "Ñuble SC",
	"Cobresal":                  "Altiplano FC",
	# ── CLUBES ARGENTINA ────────────────────────────────────────────────────
	"Boca Juniors":              "La Boca United",
	"River Plate":               "Río Plate CF",
	"Racing Club":               "Racing Aviación",
	"Independiente":             "Rojo Independiente",
	"San Lorenzo":               "San Lorenzo CF",
	"Vélez Sársfield":           "Vélez FC",
	"Estudiantes":               "Estudiantes La Plata",
	"Talleres":                  "Talleres Córdoba",
	"Lanús":                     "Lanús FC",
	"Gimnasia":                  "Gimnasia La Plata",
	"Defensa y Justicia":        "Defensa FC",
	"Banfield":                  "Banfield SC",
	"Huracán":                   "Huracán de Buenos Aires",
	"Rosario Central":           "Central Rosario",
	"Newell's Old Boys":         "Newell's FC",
	"Colón":                     "Colón Santa Fe",
	"Godoy Cruz":                "Godoy Cruz Mendoza",
	# ── CLUBES BRASIL ────────────────────────────────────────────────────────
	"Flamengo":                  "Fla-Mengó SC",
	"Palmeiras":                 "Verdão FC",
	"Corinthians":               "Alvinegro SC",
	"Santos":                    "Baixada FC",
	"São Paulo":                 "Tricolor Paulista",
	"Fluminense":                "Flu-Tricolor",
	"Botafogo":                  "Estrela Solitária FC",
	"Vasco da Gama":             "Vasco CF",
	"Atlético Mineiro":          "Galo Atlético",
	"Cruzeiro":                  "Raposa SC",
	"Grêmio":                    "Tricolor Gaúcho",
	"Internacional":             "Colorado FC",
	# ── CLUBES URUGUAY ────────────────────────────────────────────────────────
	"Nacional":                  "Nacional Montevideo",
	"Peñarol":                   "Carbonero FC",
	# ── CLUBES COLOMBIA ───────────────────────────────────────────────────────
	"América de Cali":           "América CF",
	"Deportivo Cali":            "Cali Deportivo",
	"Millonarios":               "Millonarios FC",
	"Atlético Nacional":         "Nacional Medellín",
	# ── CLUBES PERÚ ───────────────────────────────────────────────────────────
	"Alianza Lima":              "Alianza SC",
	"Universitario":             "Universitario Lima",
	"Sporting Cristal":          "Cristal FC",
	# ── CLUBES ECUADOR ────────────────────────────────────────────────────────
	"Barcelona SC":              "Barcelona Guayaquil",
	"Liga de Quito":             "Liga Quito",
	"Emelec":                    "Eléctrico FC",
	# ── CLUBES VENEZUELA ──────────────────────────────────────────────────────
	"Caracas FC":                "Capital FC",
	"Deportivo Táchira":         "Táchira FC",
	# ── CLUBES BOLIVIA ────────────────────────────────────────────────────────
	"Bolívar":                   "Bolívar La Paz",
	"The Strongest":             "Los Tigres SC",
	# ── LIGAS Y COMPETICIONES ─────────────────────────────────────────────────
	"Primera División":          "Liga Premier",
	"Primera B":                 "Liga de Ascenso",
	"Segunda División":          "Liga Segunda",
	"Copa Chile":                "Copa Nacional",
	"Libertadores":              "Copa Libertad",
	"Sudamericana":              "Copa Sudamérica",
	"Recopa":                    "Recopa Continental",
	"Copa América":              "Copa de Naciones",
	"CONMEBOL":                  "CONFUT",
	# ── JUGADORES MÁS CONOCIDOS ───────────────────────────────────────────────
	# Regla: cambio de una letra o vocal, conservando ritmo fonético.
	# Solo se mapean los de mayor exposición mediática (~top 30 de la tabla).
	"Vidal":      "Vidal A.",
	"Pizarro":    "Pizarros",
	"Alexis":     "Alexis S.",
	"Medel":      "Medel G.",
	"Bravo":      "Bravo C.",
	"Valdivia":   "Valdibia",
	"De Paul":    "Di Paul",
	"Mac Allister": "Mac Allister A.",
	"Fernández":  "Fernández E.",
	"Messi":      "Méssi L.",
	"Di María":   "Di María Á.",
	"Cavani":     "Cavani E.",
	"Suárez":     "Suáres L.",
	"Neymar":     "Neymar S.",
	"Richarlison":"Richarlisson",
	"Vinicius":   "Vinícius J.",
	"Rodrygo":    "Rodrigo G.",
	"Cunha":      "Cuña M.",
	"Guerrero":   "Guerrero P.",
	"Cueva":      "Cuevas C.",
	"Lapadula":   "Lapadúla G.",
	"Caicedo":    "Caicedo M.",
	"Valencia":   "Valencia E.",
	"James":      "James R.",
	"Falcao":     "Falcón R.",
	"Cuadrado":   "Cuadrao J.",
	"Ospina":     "Espina D.",
	"Martínez":   "Martínez L.",
	"Dávila":     "Davilla M.",
	"Rodríguez":  "Rodríguez C.",
}

## Devuelve la variante ficticia del nombre si existe; en caso
## contrario devuelve el nombre sin modificar.
static func limpiar(nombre: String) -> String:
	return _VARIANTES.get(nombre, nombre)

## Versión para arrays: limpia una lista de nombres de una vez.
static func limpiar_lista(nombres: Array) -> Array:
	var salida: Array = []
	for n in nombres:
		salida.append(limpiar(String(n)))
	return salida

## Indica si un nombre tiene variante registrada. Útil para debug
## o para mostrar una marca visual "nombre ficticio" en el editor.
static func tiene_variante(nombre: String) -> bool:
	return _VARIANTES.has(nombre)
