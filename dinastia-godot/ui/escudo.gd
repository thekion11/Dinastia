class_name Escudo
extends RefCounted
## El escudo de cada club, portado del HTML tal cual.
##
## EL HALLAZGO QUE HACE ESTO BARATO: Godot rasteriza SVG en tiempo de ejecución
## con `Image.load_svg_from_string()`. El generador del HTML no dibuja: construye
## una cadena SVG. Así que se porta como lo que es —un constructor de cadenas—
## en vez de reimplementar a mano ocho formas, diez patrones y sus degradados.
## Es la diferencia entre portar y reescribir, y aquí vale para toda la estética:
## escudos, caras de jugador, portadas.
##
## LO QUE NO SOPORTA EL RASTERIZADOR: el elemento `<text>`. Un SVG con texto
## carga sin error y sale sin las letras. Comprobado. Por eso las iniciales del
## club NO van dentro del SVG: se ponen encima con una etiqueta de Godot, que
## además queda más nítida y respeta el tema.
##
## El escudo de un club es SIEMPRE el mismo: forma, patrón y símbolo salen del
## hash de su id, igual que su estadio. Si se sortearan, el mismo club tendría
## un escudo distinto cada partida y dejaría de ser ese club.

## Los cuatro nuevos (22-9-2026) se diseñaron en Figma -boolean ops sobre
## primitivas (uniones/restas), no a mano- y se leyeron con `vectorPaths` del
## Plugin API, no se inventaron los números de memoria. Ampliar variedad real
## de escudos era parte del pedido del usuario: "mejorar el generador
## procedural" con las herramientas de diseño que dio acceso, no arte fijo por
## club -sigue siendo 100% determinista por hash, ver el comentario de la
## clase-.
const FORMAS := ["clasico", "circulo", "penta", "rombo", "hex", "escudo", "cruzado", "banderin",
	"ojiva", "octogono", "corona", "laurel",
	"frances", "curvo", "arco3", "hexalgo", "rombolgo", "banda_cinta", "estandarte", "doblepunta",
	"geometrico", "coronadoble", "ovalo", "redondeado", "trianguloesc", "cruzesc"]
const PATRONES := ["liso", "banda", "franjas", "mitad", "cuartos", "aro", "estrella", "ondas", "chevron", "sol",
	"cruz", "rombos", "escamas", "estrella6",
	"tablero", "corona2", "rayo", "anillos", "abanico", "interior", "puntas", "barras", "borde",
	"escalera", "pila", "estrella8", "manchas", "florlis", "trebol", "medialuna"]

## Las siluetas, en el sistema de coordenadas 64x70 del HTML.
const SILUETAS := {
	"clasico":  "M32 3h26a4 4 0 0 1 4 4v28c0 16-12 24-30 30C14 59 2 51 2 35V7a4 4 0 0 1 4-4Z",
	"escudo":   "M32 2 62 10v26c0 18-13 22-30 28C15 58 2 54 2 36V10Z",
	"circulo":  "M32 2a30 30 0 1 1 0 60 30 30 0 0 1 0-60Z",
	"penta":    "M32 2 62 24 50 60H14L2 24Z",
	"rombo":    "M32 1 63 32 32 63 1 32Z",
	"hex":      "M18 3h28l16 29-16 29H18L2 32Z",
	"cruzado":  "M32 2 60 12v22c0 18-14 24-28 28C18 58 4 52 4 34V12Z",
	"banderin": "M4 3h56v42L32 62 4 45Z",
	## Ojival: cuerpo + arco superior redondeado + punta, como un escudo gotico.
	"ojiva":    "M32 1 C47 1 60 9 60 18 L60 60 L43 60 L32 70 L21 60 L4 60 L4 18 C4 9 17 1 32 1 Z",
	## Octogono regular (createPolygon de 8 lados en Figma, sin retocar).
	"octogono": "M32 4 L54 13 L63 35 L54 57 L32 66 L10 57 L1 35 L10 13 Z",
	## Almenado: 3 dientes de castillo arriba, cuerpo recto, punta abajo.
	"corona":   "M16 19 L24 19 L24 3 L38 3 L38 19 L46 19 L46 3 L58 3 L58 19 L60 19 L60 59 L32 68 L4 59 L4 3 L16 3 Z",
	## Circulo con dos muescas en la base -resta booleana de dos elipses
	## pequenas-, como el cierre de una corona de laurel.
	"laurel":   "M32 5 C49 5 62 18 62 35 C62 46 56 56 47 61 C46 59 43 57 38 57 C36 57 32 61 32 65 C32 61 28 57 24 57 C21 57 18 59 17 61 C8 56 2 46 2 35 C2 18 15 5 32 5 Z",

	## Los 14 siguientes (22-9-2026, segunda tanda -"mas cantidad", inspirada en
	## heraldica real y en el editor de FC 26-): las 3 con curvas de verdad
	## (frances/curvo/arco3) salieron de Figma con booleanas otra vez; el resto
	## son poligonos de lados rectos -coordenadas calculadas a mano, sin
	## necesidad del viaje a Figma, mismo criterio que ya se aplico con las
	## formas de la primera tanda que resultaron ser simples-.
	"frances":     "M60 40 C60 55 47 68 32 68 C17 68 4 55 4 40 L4 3 L60 3 Z",
	"curvo":       "M60 54 C60 61 55 66 48 66 C45 66 42 65 40 63 C38 65 35 66 32 66 C29 66 26 65 24 63 C22 65 19 66 16 66 C9 66 4 61 4 54 L4 4 L60 4 Z",
	"arco3":       "M32 2 C37 2 42 5 44 10 C45 9 47 9 48 9 C55 9 60 14 60 21 L60 69 L4 69 L4 21 C4 14 9 9 16 9 C17 9 19 9 20 10 C22 5 27 2 32 2 Z",
	## Hexagono alargado vertical (rugby/urna).
	"hexalgo":     "M32 2 L58 20 L58 50 L32 68 L6 50 L6 20 Z",
	## Rombo alargado vertical.
	"rombolgo":    "M32 1 L50 35 L32 69 L14 35 Z",
	## Banderin/estandarte ancho con cola bifurcada -como una wimpel de club.
	"banda_cinta": "M6 3 L58 3 L58 50 L48 66 L32 50 L16 66 L6 50 Z",
	## Estandarte angosto, cola de golondrina.
	"estandarte":  "M16 2 L48 2 L48 55 L40 68 L32 58 L24 68 L16 55 Z",
	## Escudo ancho con esquinas superiores achaflanadas y base bifurcada.
	"doblepunta":  "M4 12 L12 4 L52 4 L60 12 L60 50 L46 66 L32 52 L18 66 L4 50 Z",
	## Escudo geometrico moderno, todas las esquinas achaflanadas (estilo logo de esports).
	"geometrico":  "M14 2 L50 2 L60 12 L60 42 L46 58 L32 68 L18 58 L4 42 L4 12 Z",
	## Igual que "corona" pero con 4 almenas en vez de 3.
	"coronadoble": "M14 19 L19 19 L19 3 L29 3 L29 19 L34 19 L34 3 L44 3 L44 19 L49 19 L49 3 L60 3 L60 19 L60 58 L32 68 L4 58 L4 3 L14 3 Z",
	## Ovalo clasico -mismo criterio de arco relativo que "circulo", solo que sin radio uniforme-.
	"ovalo":       "M32 2a28 33 0 1 1 0 66 28 33 0 0 1 0-66Z",
	## Rectangulo con esquinas redondeadas -placa/medalla-.
	"redondeado":  "M12 4 H52 A8 8 0 0 1 60 12 V58 A8 8 0 0 1 52 66 H12 A8 8 0 0 1 4 58 V12 A8 8 0 0 1 12 4 Z",
	## Triangulo ancho, apice arriba -estilo señal/cartel-.
	"trianguloesc": "M32 2 L60 66 L4 66 Z",
	## Cruz griega como silueta completa del escudo -estilo medalla militar-.
	"cruzesc":     "M21 2 L43 2 L43 24 L62 24 L62 46 L43 46 L43 68 L21 68 L21 46 L2 46 L2 24 L21 24 Z",
}

## ESCUDOS ESPECIALES (22-9-2026). 40 insignias originales -generadas con
## Canva, licencia propia, sin arte de terceros- a pedido del usuario, tras
## descartar usar directo las referencias de Pinterest (la mayoria son trabajo
## de disenadores/estudios individuales sin licencia visible para redistribuir
## en otro juego, y "estaba en Wikipedia" no equivale a libre -la mayoria de
## escudos reales ahi son "uso legitimo", prohibido fuera de la enciclopedia-).
## Esas referencias sirvieron de INSPIRACION de estilo, no de origen del arte.
##
## Se desbloquean por NIVEL DE PERFIL DE GESTOR (`Logros.perfil_nivel`), no por
## logros puntuales: `logros.gd` declara explicito que los logros "solo suman
## reconocimiento, nunca bloquean contenido" -regla heredada del HTML-, y no
## correspondia romperla para esto. El perfil de gestor es un sistema aparte
## sin esa restriccion, y ya es progresion de carrera en carrera.
##
## Los 10 temas (4 variantes cada uno) se repartieron entre los 7 niveles de
## `Logros.NIVELES_PERFIL` de forma creciente -mas variedad cuanto mas alto el
## nivel-. El reparto es arbitrario y facil de ajustar despues; lo que importa
## es que ya queda enganchado de punta a punta.
const ESPECIALES := {
	"soccer_1": 0, "soccer_2": 0, "soccer_3": 0, "soccer_4": 0,
	"wolf_1": 1, "wolf_2": 1, "wolf_3": 1, "wolf_4": 1,
	"eagle_1": 2, "eagle_2": 2, "eagle_3": 2, "eagle_4": 2,
	"bull_1": 3, "bull_2": 3, "bull_3": 3, "bull_4": 3,
	"lion_1": 3, "lion_2": 3, "lion_3": 3, "lion_4": 3,
	"shark_1": 4, "shark_2": 4, "shark_3": 4, "shark_4": 4,
	"dragon_1": 4, "dragon_2": 4, "dragon_3": 4, "dragon_4": 4,
	"panther_1": 5, "panther_2": 5, "panther_3": 5, "panther_4": 5,
	"falcon_1": 5, "falcon_2": 5, "falcon_3": 5, "falcon_4": 5,
	"ram_1": 6, "ram_2": 6, "ram_3": 6, "ram_4": 6,
}
const DIR_ESPECIALES := "res://assets/escudos_especiales/"

static var _cache_especial: Dictionary = {}

## Nivel de perfil de gestor actual (0..6). Perfil ilegible/nuevo = nivel 0,
## igual que ya hace `Logros.perfil_nivel()` con xp=0.
static func _nivel_perfil_actual() -> int:
	var perfil := Logros.perfil_leer()
	return int(Logros.perfil_nivel(int(perfil.get("xp", 0))).get("i", 0))

## Todos los especiales que el nivel actual ya desbloqueo, ordenados -para
## el picker de la pantalla de identidad (todavia sin construir hoy).
static func especiales_desbloqueados() -> Array:
	var nivel := _nivel_perfil_actual()
	var out: Array = []
	for id in ESPECIALES.keys():
		if int(ESPECIALES[id]) <= nivel:
			out.append(id)
	out.sort()
	return out

## Si `id` esta en el catalogo Y el nivel de perfil ya lo desbloqueo.
static func especial_desbloqueado(id: String) -> bool:
	return ESPECIALES.has(id) and int(ESPECIALES[id]) <= _nivel_perfil_actual()

## La textura ya cargada del especial `id`, o null si no existe o no esta
## desbloqueado -nunca revienta, `textura()` cae al procedural en ese caso-.
static func textura_especial(id: String) -> Texture2D:
	if not especial_desbloqueado(id):
		return null
	if _cache_especial.has(id):
		return _cache_especial[id]
	var ruta := DIR_ESPECIALES + id + ".png"
	if not ResourceLoader.exists(ruta):
		return null
	var tex: Texture2D = load(ruta)
	_cache_especial[id] = tex
	return tex

## Los escudos ya rasterizados, por clave. Rasterizar un SVG cuesta, y la tabla
## de posiciones pide dieciséis escudos en cada repintado: sin caché, cada
## avance de semana volvería a dibujarlos todos.
static var _cache: Dictionary = {}

static func silueta(forma: String) -> String:
	return String(SILUETAS.get(forma, SILUETAS["clasico"]))

## djb2 sobre el id, el mismo hash que usa el resto del proyecto para que un
## club dé siempre lo mismo.
static func _hash(s: String) -> int:
	var h := 7
	for i in s.length():
		h = ((h * 31) + s.unicode_at(i)) & 0x7FFFFFFF
	return h

## La forma del escudo. Sale del id del club para que cada uno tenga la suya,
## PERO se puede elegir a mano: `esc_forma` manda si esta puesto. Es lo que hace
## que la pantalla de identidad sirva para algo mas que cambiar dos colores.
static func forma_de(c: Club) -> String:
	if c.esc_forma != "" and FORMAS.has(c.esc_forma):
		return c.esc_forma
	return FORMAS[_hash(c.id) % FORMAS.size()]

static func patron_de(c: Club) -> String:
	if c.esc_patron != "" and PATRONES.has(c.esc_patron):
		return c.esc_patron
	return PATRONES[(_hash(c.id) >> 4) % PATRONES.size()]

## El símbolo del escudo -un emoji, "ESC_SIM" del HTML-, no una forma dibujada.
## Reemplaza a las iniciales cuando está puesto, nunca las dos cosas a la vez
## -mismo "sym ? ... : ini" de `escudo()` en el HTML-.
##
## A diferencia de la forma y el patrón -que SIEMPRE salen del hash, todo club
## tiene una de las ocho formas-, el símbolo por defecto solo le toca a uno de
## cada tres clubes (`(h>>8)%3===0` del HTML): los otros dos tercios se quedan
## con las iniciales, sin más. Elegirlo a mano en la pantalla de identidad lo
## fuerza siempre, le tocara o no ese tercio.
static func simbolo_de(c: Club) -> String:
	var lista: Array = Datos.tabla("ESC_SIM")
	if c.esc_simbolo != "" and lista != null and lista.has(c.esc_simbolo):
		return c.esc_simbolo
	if lista == null or lista.size() <= 1:
		return ""
	var h := _hash(c.id)
	if (h >> 8) % 3 != 0:
		return ""
	return String(lista[(h >> 10) % lista.size()])

## Las dos letras que van encima del escudo. Solo mayúsculas y dígitos, como en
## el HTML: "U. de Chile" da "UC", "Colo-Colo" da "CC".
static func iniciales(c: Club) -> String:
	var s := ""
	for i in c.nombre.length():
		var ch := c.nombre[i]
		if ch == ch.to_upper() and ch != ch.to_lower():
			s += ch
		elif ch.is_valid_int():
			s += ch
		if s.length() >= 2:
			break
	return s if not s.is_empty() else "FC"

## El patrón que va recortado dentro de la silueta. Son los diez del HTML, con
## sus mismas coordenadas y opacidades.
static func _patron_svg(p: String, c2: String) -> String:
	match p:
		"banda":
			return '<path d="M-6 44 L44 -6 L62 8 L12 58Z" fill="%s" opacity=".92"/>' % c2
		"franjas":
			var s := ""
			for i in 4:
				s += '<rect x="%s" y="-4" width="7.5" height="72" fill="%s" opacity=".9"/>' % [4 + i * 15, c2]
			return s
		"mitad":
			return '<rect x="32" y="-4" width="36" height="72" fill="%s" opacity=".92"/>' % c2
		"cuartos":
			return '<rect x="-4" y="-4" width="36" height="36" fill="%s" opacity=".9"/>' % c2 \
				+ '<rect x="32" y="32" width="36" height="36" fill="%s" opacity=".9"/>' % c2
		"aro":
			return '<circle cx="32" cy="32" r="20" fill="none" stroke="%s" stroke-width="8" opacity=".85"/>' % c2
		"estrella":
			return '<path d="M32 12 37 26h15l-12 9 4.5 15L32 41l-12.5 9L24 35l-12-9h15Z" fill="%s" opacity=".9"/>' % c2
		"ondas":
			var o := ""
			for i in 3:
				o += '<path d="M-4 %sq16 -8 32 0t32 0v7q-16 8-32 0t-32 0Z" fill="%s" opacity=".8"/>' % [18 + i * 15, c2]
			return o
		"chevron":
			return '<path d="M-4 46 32 18 68 46v12L32 30-4 58Z" fill="%s" opacity=".9"/>' % c2
		"sol":
			var r := ""
			for i in 8:
				var a1 := float(i) * PI / 4.0
				var a2 := (float(i) + 0.45) * PI / 4.0
				r += '<path d="M32 32 L%.2f %.2f L%.2f %.2f Z" fill="%s" opacity=".55"/>' % [
					32.0 + 30.0 * cos(a1), 32.0 + 30.0 * sin(a1),
					32.0 + 30.0 * cos(a2), 32.0 + 30.0 * sin(a2), c2]
			return r
		## Los cuatro de aqui abajo son del 22-9-2026 (mismo pedido que las 4
		## siluetas nuevas de arriba). "estrella6" salio de Figma (createStar de
		## 6 puntas, aplanada); "cruz" y "rombos" son geometria demasiado simple
		## como para justificar el viaje a Figma -misma logica que ya usan
		## "cuartos"/"franjas" de mas arriba, primitivas directas-.
		"cruz":
			return '<rect x="27" y="-4" width="10" height="78" fill="%s" opacity=".9"/>' % c2 \
				+ '<rect x="-4" y="30" width="72" height="10" fill="%s" opacity=".9"/>' % c2
		"rombos":
			var d := ""
			for centro in [Vector2(16, 18), Vector2(48, 18), Vector2(16, 50), Vector2(48, 50)]:
				d += '<path d="M%d %d L%d %d L%d %d L%d %d Z" fill="%s" opacity=".85"/>' % [
					centro.x, centro.y - 13, centro.x + 13, centro.y,
					centro.x, centro.y + 13, centro.x - 13, centro.y, c2]
			return d
		## Filas escalonadas de circulos -"piel de pez"-, tres filas de radio 9.
		## Coordenadas de la propia construccion en Figma (union de 11 elipses
		## que nunca llegaron a solaparse, asi que ahi salieron como 11 paths
		## sueltos): mas simple reproducir el mismo layout con un bucle que
		## transcribir once curvas Bezier casi identicas a mano.
		"escamas":
			var e := ""
			var filas := [[4.0, [4, 22, 40, 58]], [22.0, [13, 31, 49]], [40.0, [4, 22, 40, 58]]]
			for fila in filas:
				var y: float = fila[0]
				for x in fila[1]:
					e += '<circle cx="%d" cy="%.0f" r="9" fill="%s" opacity=".88"/>' % [x, y, c2]
			return e
		"estrella6":
			return '<path d="M32 7 L39 23 L56 21 L46 35 L56 49 L39 47 L32 63 L25 47 L8 49 L18 35 L8 21 L25 23 Z" fill="%s" opacity=".9"/>' % c2
		## Los 16 siguientes son la misma segunda tanda del 22-9-2026 que las 14
		## siluetas nuevas de arriba. Todos primitivas directas o formulas -ninguno
		## necesito Figma esta vez, ni siquiera "trebol"/"medialuna"/"florlis"
		## -que iban a salir de una union booleana hasta toparse con el limite de
		## llamadas del plan gratuito de Figma a mitad de la tanda-: como un
		## patron es un relleno recortado por el clip del escudo, no hace falta
		## que sea UN solo path fusionado -varios elementos sueltos (igual que ya
		## hacen "cuartos"/"franjas"/"escamas") se ven identico y son mas simples-.
		"tablero":
			var tb := ""
			for gi in 4:
				for gj in 4:
					if (gi + gj) % 2 == 0:
						tb += '<rect x="%d" y="%.1f" width="16" height="17.5" fill="%s" opacity=".9"/>' % [gi * 16, gj * 17.5, c2]
			return tb
		## Corona pequeña centrada, de 3 puntas -motivo, no la silueta entera-.
		"corona2":
			return '<path d="M18 45 L46 45 L46 32 L38 38 L32 20 L26 38 L18 32 Z" fill="%s" opacity=".9"/>' % c2
		"rayo":
			return '<path d="M36 2 L18 38 L30 38 L24 68 L48 30 L34 30 Z" fill="%s" opacity=".92"/>' % c2
		"anillos":
			var an := ""
			for r_i in [26, 18, 10]:
				an += '<circle cx="32" cy="34" r="%d" fill="none" stroke="%s" stroke-width="4" opacity=".85"/>' % [r_i, c2]
			return an
		## Abanico de rayos desde el borde inferior -mismo truco que "sol" pero
		## el origen esta en la base, no en el centro, asi que solo cubre 180°-.
		"abanico":
			var fa := ""
			for i in 6:
				var a1 := PI + float(i) * PI / 6.0
				var a2 := PI + (float(i) + 0.6) * PI / 6.0
				fa += '<path d="M32 70 L%.2f %.2f L%.2f %.2f Z" fill="%s" opacity=".55"/>' % [
					32.0 + 45.0 * cos(a1), 70.0 + 45.0 * sin(a1), 32.0 + 45.0 * cos(a2), 70.0 + 45.0 * sin(a2), c2]
			return fa
		## Escudito anidado adentro -mismo principio que un "inescutcheon" heraldico-.
		"interior":
			return '<path d="M32 15 L46 15 L46 32 C46 45 40 50 32 55 C24 50 18 45 18 32 L18 15 Z" fill="%s" opacity=".88"/>' % c2
		## Fila de dientes de sierra a lo largo de la base.
		"puntas":
			var pz := ""
			for i in 8:
				var x0 := i * 8.0
				pz += '<path d="M%.1f 62 L%.1f 70 L%.1f 62 Z" fill="%s" opacity=".85"/>' % [x0, x0 + 4, x0 + 8, c2]
			return pz
		## Dos barras horizontales gruesas -version horizontal de "franjas"-.
		"barras":
			return '<rect x="-4" y="14" width="72" height="12" fill="%s" opacity=".9"/>' % c2 \
				+ '<rect x="-4" y="44" width="72" height="12" fill="%s" opacity=".9"/>' % c2
		## Marco grueso pegado al borde -"bordure" heraldico-.
		"borde":
			return '<rect x="2" y="2" width="60" height="8" fill="%s" opacity=".85"/>' % c2 \
				+ '<rect x="2" y="60" width="60" height="8" fill="%s" opacity=".85"/>' % c2 \
				+ '<rect x="2" y="2" width="8" height="66" fill="%s" opacity=".85"/>' % c2 \
				+ '<rect x="54" y="2" width="8" height="66" fill="%s" opacity=".85"/>' % c2
		## Escalera diagonal de cuadrados superpuestos.
		"escalera":
			var sc := ""
			for i in 6:
				sc += '<rect x="%d" y="%d" width="12" height="12" fill="%s" opacity=".85"/>' % [i * 10 - 4, i * 10, c2]
			return sc
		## Pila heraldica: triangulo ancho que cae desde el borde superior.
		"pila":
			return '<path d="M6 -4 L58 -4 L32 55 Z" fill="%s" opacity=".9"/>' % c2
		## Estrella de 8 puntas -16 vertices alternando radio 30/13, centro
		## (32,34)-, calculada a mano con trigonometria, sin pasar por Figma.
		"estrella8":
			return '<path d="M32 4 L37 22 L53 13 L44 29 L62 34 L44 39 L53 55 L37 46 L32 64 L27 46 L11 55 L20 39 L2 34 L20 29 L11 13 L27 22 Z" fill="%s" opacity=".9"/>' % c2
		## Manchas irregulares -posiciones y radios fijos, no aleatorios, para
		## que el mismo club siempre salga igual-.
		"manchas":
			var ma := ""
			for bl in [[14, 14, 10], [46, 20, 7], [30, 45, 12], [10, 55, 6], [52, 52, 8]]:
				ma += '<circle cx="%d" cy="%d" r="%d" fill="%s" opacity=".8"/>' % [bl[0], bl[1], bl[2], c2]
			return ma
		## Flor de lis estilizada: ovalo central + dos circulos laterales + banda -sin
		## rotacion, para no depender de soporte de "transform" en el rasterizador SVG-.
		"florlis":
			return '<path d="M32 6 A7 20 0 1 1 32 46 A7 20 0 1 1 32 6 Z" fill="%s" opacity=".88"/>' % c2 \
				+ '<circle cx="18" cy="32" r="9" fill="%s" opacity=".8"/>' % c2 \
				+ '<circle cx="46" cy="32" r="9" fill="%s" opacity=".8"/>' % c2 \
				+ '<rect x="22" y="48" width="20" height="10" fill="%s" opacity=".85"/>' % c2
		## Trebol de 4 hojas: 4 circulos sueltos, no fusionados -un patron
		## recortado no necesita ser un solo path, ver nota de arriba-.
		"trebol":
			var tr := ""
			for pt in [Vector2(32, 24), Vector2(43, 35), Vector2(32, 46), Vector2(21, 35)]:
				tr += '<circle cx="%d" cy="%d" r="11" fill="%s" opacity=".82"/>' % [pt.x, pt.y, c2]
			return tr
		## Media luna: el truco clasico de dos arcos SVG (uno grande, uno mas
		## angosto y desplazado) en vez de una resta booleana.
		"medialuna":
			return '<path d="M32 4 A30 30 0 1 0 32 64 A22 26 0 1 1 32 4 Z" fill="%s" opacity=".9"/>' % c2
	return ""

## El SVG completo del escudo, sin texto.
static func svg_de(c: Club) -> String:
	var f := forma_de(c)
	var p := patron_de(c)
	var d := silueta(f)
	## El brillo diagonal es lo que hace que un escudo parezca metal y no una
	## pegatina plana. Son cuatro paradas de un degradado, y cambian mucho.
	return """<svg width="64" height="70" viewBox="0 0 64 70" xmlns="http://www.w3.org/2000/svg">
<defs>
<clipPath id="cl"><path d="%s"/></clipPath>
<linearGradient id="br" x1="0" y1="0" x2="0.3" y2="1">
<stop offset="0" stop-color="#ffffff" stop-opacity=".32"/>
<stop offset=".42" stop-color="#ffffff" stop-opacity=".04"/>
<stop offset=".58" stop-color="#000000" stop-opacity=".06"/>
<stop offset="1" stop-color="#000000" stop-opacity=".34"/></linearGradient>
</defs>
<path d="%s" fill="%s"/>
<g clip-path="url(#cl)">%s</g>
<path d="%s" fill="url(#br)"/>
<path d="%s" fill="none" stroke="#00000055" stroke-width="1.4"/>
</svg>""" % [d, d, c.color_escudo1(), _patron_svg(p, c.color_escudo2()), d, d]

## El escudo ya rasterizado, listo para meter en un TextureRect.
##
## Se rasteriza a 4x y se deja que el control lo encoja: a 1x los bordes curvos
## salen dentados, y a 4x se ven limpios en cualquier tamaño de la interfaz.
static func textura(c: Club, alto_px: int = 26) -> Texture2D:
	## Especial primero: si el club eligio uno Y sigue desbloqueado, manda por
	## encima del generador procedural. `textura_especial()` ya resuelve el
	## caso "ya no desbloqueado" devolviendo null, así que cae solo al
	## procedural de mas abajo sin ningun chequeo extra aqui.
	if c.esc_especial != "":
		var esp := textura_especial(c.esc_especial)
		if esp != null:
			return esp
	## LA CLAVE LLEVA LOS COLORES Y LA FORMA. Antes era solo el id y el tamaño,
	## asi que cambiar el escudo en la pantalla de identidad no repintaba nada:
	## la cache seguia devolviendo el escudo viejo hasta reiniciar el juego.
	var clave := "%s_%d_%s_%s_%s_%s" % [c.id, alto_px,
		c.color_escudo1(), c.color_escudo2(), forma_de(c), patron_de(c)]
	if _cache.has(clave):
		return _cache[clave]
	var img := Image.new()
	if img.load_svg_from_string(svg_de(c), float(alto_px) * 4.0 / 70.0) != OK:
		return null
	var t := ImageTexture.create_from_image(img)
	_cache[clave] = t
	return t

## Se vacía al empezar otra partida: los colores de un club pueden cambiar entre
## mundos y una caché con el id como clave los serviría del mundo anterior.
static func limpiar_cache() -> void:
	_cache.clear()
