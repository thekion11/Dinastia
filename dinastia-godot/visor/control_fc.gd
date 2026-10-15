class_name ControlFC
extends RefCounted
## LOS CONTROLES DE FC 26 (14-10-2026, el usuario pasó el manual completo:
## «así debe estar, y si tenemos más trucos agrega combinación»). Aquí viven:
##   - el MANUAL, con la misma estructura del que pasó (7 partes: movimiento y
##     regates, ataque, defensa, portero y tácticas, balón parado, saques de
##     banda y filigranas), para el motor y para la pantalla de controles;
##   - las FILIGRANAS, con sus estrellas;
##   - el RECONOCEDOR DE GESTOS del stick derecho;
##   - cómo se llama cada botón en PlayStation, en Xbox y en el teclado.
##
## Las combinaciones se escriben con «fichas»: el nombre de una acción del
## `Mando` («jugar_tiro»), con «mant:» si se mantiene o «2x:» si es doble toque,
## o un elemento del mando sin acción propia: LS, RS (los sticks), RS_toque (un
## toque rápido del stick derecho) y RS_giro (girarlo). Así la pantalla escribe
## SIEMPRE los botones que el jugador tenga puestos.
##
## Las direcciones del gesto son RELATIVAS al jugador (como dice el manual:
## «arriba» es hacia donde mira tu futbolista): F adelante, B atrás, L y R sus
## lados, y las diagonales. «N» es soltar el stick en medio de un gesto.

## id: [nombre, estrellas, fichas (modificadores), cómo, animación, efecto]
## Efectos: lateral, lateral_lento, giro (90°), giro_atras (180°), arranque,
## sombrero (el balón por encima), amago (engaña sin tocar el balón).
const FILIGRANAS := {
	"amago_tiro": ["Amago de tiro", 1, ["jugar_tiro", "jugar_pase"], "Tiro y, antes de soltar, Pase (rápido)", "amague_tiro", "amago"],
	"adelantar": ["Adelantar balón largo (knock-on)", 1, ["mant:jugar_sprint", "RS_toque"], "Corriendo, toque rápido del stick derecho hacia adelante", "cambio_ritmo", "arranque"],
	"pisada": ["Pisada de balón (ball roll)", 2, ["RS"], "Mantener el stick derecho a izquierda o derecha", "pisada_lateral", "lateral_lento"],
	"arrastre": ["Arrastre atrás (drag back)", 2, ["mant:jugar_cambiar", "mant:jugar_mod", "LS"], "Mantener LB + RB y el stick izquierdo hacia atrás", "arrastre", "giro_atras"],
	"finta_cuerpo": ["Finta de cuerpo (body feint)", 2, ["RS_toque"], "Toque del stick derecho a izquierda o derecha", "amague_cuerpo", "lateral"],
	"bicicleta": ["Bicicleta (stepover)", 2, ["RS_giro"], "Girar el stick derecho un cuarto de vuelta, de arriba hacia un lado", "bicicleta", "lateral"],
	"bicicleta_inversa": ["Bicicleta inversa", 2, ["RS_giro"], "Girar el stick derecho de un lado hacia arriba", "bicicleta_inversa", "lateral"],
	"sombrero_corto": ["Autopase elevado (sombrero flick)", 2, ["jugar_sombrero"], "Presionar el stick derecho hacia adentro", "lambreta", "sombrero"],
	"ruleta": ["Ruleta", 3, ["RS_giro"], "Girar el stick derecho tres cuartos de vuelta empezando desde atrás", "ruleta", "giro"],
	"tacon_tacon": ["Amago de caída (heel to heel)", 3, ["RS_toque"], "Toque del stick derecho adelante y luego atrás", "cambio_ritmo", "arranque"],
	"amago_salida": ["Amago y salida (feint and exit)", 3, ["RS_giro"], "Media luna del stick derecho por atrás, de un lado al otro", "recorte_exterior", "lateral"],
	"giro_berba": ["Giro de Berba / Cruyff (stop and turn)", 4, ["RS_toque"], "Toque del stick derecho adelante y luego a un lado", "giro_cruyff", "giro"],
	"giro_dragster": ["Giro de dragster (drag back spin)", 4, ["RS_toque"], "Toque del stick derecho atrás y luego a un lado", "giro_suela", "giro_atras"],
	"tacon_rodado": ["Giro de tacón a tacón (heel to ball roll)", 4, ["mant:jugar_cambiar", "RS_toque"], "Mantener LB + toque del stick derecho adelante y atrás", "giro_suela", "giro"],
	"croqueta": ["Cambio de carril (la croqueta)", 4, ["mant:jugar_cambiar", "RS"], "Mantener LB + mantener el stick derecho a un lado", "croqueta", "lateral"],
	"ruleta_tres": ["Ruleta de tres toques", 4, ["mant:jugar_regate", "RS_toque"], "Mantener LT + toque del stick derecho atrás y lateral (parado)", "ruleta_inversa", "giro"],
	"arrastre_tacon": ["Arrastre de tacón (heel lane change)", 4, ["mant:jugar_regate", "RS_toque"], "Mantener LT + toque atrás y luego lateral, corriendo", "recorte_interior", "lateral"],
	"sombrero": ["Toque de tacón avanzado (advanced rainbow)", 4, ["RS_toque"], "Toque del stick derecho atrás y luego arriba", "sombrero", "sombrero"],
	"elastica": ["Cola de vaca (elastic)", 5, ["RS_giro"], "Media luna del stick derecho por delante, de derecha a izquierda", "elastica", "lateral"],
	"elastica_inversa": ["Cola de vaca inversa (reverse elastic)", 5, ["RS_giro"], "Media luna del stick derecho por delante, de izquierda a derecha", "elastica_inversa", "lateral"],
	"mcgeady": ["Giro de elástico (McGeady spin)", 5, ["mant:jugar_sprint", "RS_toque"], "Corriendo, toque del stick derecho adelante y luego a un lado", "giro_cruyff", "giro"],
	"amago_rabona": ["Amago de rabona (rabona fake)", 5, ["mant:jugar_regate", "jugar_tiro", "jugar_pase"], "Mantener LT + amago de tiro (Tiro y Pase) corriendo en diagonal", "rabona_regate", "amago"],
	"sombrerito_flair": ["Amago de sombrerito (flair rainbow)", 5, ["RS_toque"], "Toque del stick derecho atrás, arriba y arriba", "sombrero", "sombrero"],
	"hocus_pocus": ["Sombrero de espaldas (hocus pocus)", 5, ["RS_giro"], "Stick derecho de atrás hacia un lado y un cuarto al lado contrario", "media_luna", "lateral"],
	"cano": ["Caño (extra de Dinastía)", 5, ["mant:jugar_cambiar", "mant:jugar_mod", "RS_toque"], "Mantener LB + RB y toque del stick derecho adelante", "cano", "arranque"],
}

## EL MANUAL, parte por parte: [título, icono, [[acción, fichas, nota], ...]].
const MANUAL := [
	["Movimiento y regates avanzados", "🏃", [
		["Movimiento básico", ["LS"], ""],
		["Esprintar (máxima velocidad)", ["mant:jugar_sprint"], ""],
		["Regate técnico (velocidad controlada)", ["mant:jugar_mod"], "con balón"],
		["Regate ágil (espacios cortos / freno)", ["mant:jugar_cambiar"], "con balón"],
		["Proteger el balón / bregar", ["mant:jugar_regate"], ""],
		["Cambios de dirección firmes (control total)", ["mant:jugar_mod", "mant:jugar_regate"], "con balón"],
		["Adelantar balón largo (knock-on)", ["mant:jugar_sprint", "RS_toque"], "corriendo, hacia adelante"],
		["Bloqueo de jugador (player lock)", ["jugar_pedir", "jugar_sombrero"], "los dos a la vez"],
		["Filigranas y amagos", ["RS"], "ver la parte 7"],
	]],
	["Ataque, pases y definición", "⚽", [
		["Tiro básico / cabeceo / volea (mantener = potencia)", ["jugar_tiro"], ""],
		["Tiro de calidad (finesse, con rosca al segundo palo)", ["jugar_mod", "jugar_tiro"], ""],
		["Vaselina (chip shot)", ["jugar_cambiar", "jugar_tiro"], ""],
		["Tiro potente (power shot, cámara lenta, apuntado manual)", ["jugar_cambiar", "jugar_mod", "jugar_tiro"], ""],
		["Pase raso corto", ["jugar_pase"], ""],
		["Pase al hueco (filtrado)", ["jugar_filtrado"], ""],
		["Pase largo / centro al área", ["jugar_centro"], ""],
		["Pase raso potente (rompe líneas)", ["jugar_mod", "jugar_pase"], ""],
		["Pase filtrado potente", ["jugar_mod", "jugar_filtrado"], ""],
		["Pase al hueco bombeado", ["jugar_cambiar", "jugar_filtrado"], ""],
		["Pared básica (pasa y corre; Pase otra vez para la devolución)", ["jugar_cambiar", "jugar_pase"], ""],
		["Centro bombeado", ["jugar_cambiar", "jugar_centro"], ""],
		["Centro tenso raso", ["jugar_mod", "jugar_centro"], ""],
		["Pase elegante (tacón, rabona, exterior)", ["mant:jugar_regate", "jugar_pase"], "o con Centro"],
	]],
	["Defensa y recuperación del balón", "🛡", [
		["Entrada normal / forcejeo / despeje", ["jugar_tiro"], ""],
		["Entrada agresiva (barrida)", ["jugar_centro"], ""],
		["Contener (aguanta de frente al rival)", ["mant:jugar_pase"], ""],
		["Cambiar al compañero más cercano al balón", ["jugar_cambiar"], ""],
		["Cambio manual de jugador (apuntando)", ["RS_toque"], "hacia el compañero"],
		["Bregar en defensa (jockey)", ["mant:jugar_regate"], ""],
		["Bregar en carrera", ["mant:jugar_regate", "mant:jugar_sprint"], ""],
		["Presión del segundo jugador", ["mant:jugar_mod"], ""],
		["Presión de dos compañeros", ["2x:jugar_mod"], "doble toque y mantener"],
		["Falta profesional (agarrón, amarilla segura)", ["jugar_mod", "jugar_pase"], "cerca del rival"],
	]],
	["Portero y tácticas", "🧤", [
		["Salida del portero (achicar)", ["mant:jugar_filtrado"], ""],
		["Portero al palo largo", ["2x:jugar_filtrado"], "doble toque"],
		["Mover al portero a mano", ["mant:jugar_sombrero", "LS"], ""],
		["Saque largo de manos / despeje de volea", ["jugar_centro"], "con el balón en las manos"],
		["Pase corto con la mano / raso con el pie", ["jugar_pase"], "con el balón en las manos"],
		["Táctica rápida: más ofensiva", ["jugar_tac_arriba"], ""],
		["Táctica rápida: más defensiva", ["jugar_tac_abajo"], ""],
		["Táctica rápida: presión de equipo (45 s)", ["jugar_tac_izquierda"], ""],
		["Táctica rápida: laterales al ataque", ["jugar_tac_derecha"], ""],
	]],
	["Balón parado y penaltis", "🎯", [
		["Dirección y altura del lanzamiento", ["LS"], "tiros libres y córners"],
		["Efecto (curva, topspin, raso)", ["RS"], ""],
		["Ejecutar tiro / centro (mantener = potencia)", ["jugar_tiro"], ""],
		["Elegir receptor dentro del área", ["jugar_cambiar"], "antes de centrar"],
		["Segundo lanzador (jugada ensayada)", ["jugar_mod"], ""],
		["Tercer lanzador", ["jugar_regate"], ""],
		["Penal: apuntar a las esquinas", ["LS"], ""],
		["Penal: patear con el círculo de serenidad en verde", ["jugar_tiro"], "cuando el círculo es más chico"],
		["Penal colocado con rosca", ["jugar_mod", "jugar_tiro"], ""],
		["Panenka (bombeado al centro)", ["jugar_cambiar", "jugar_tiro"], ""],
	]],
	["Saques de banda", "👐", [
		["Saque en corto al compañero elegido", ["jugar_pase"], ""],
		["Saque al espacio (al hueco)", ["jugar_filtrado"], ""],
		["Saque largo bombeado", ["jugar_centro"], ""],
		["Cambiar de receptor", ["jugar_cambiar"], ""],
		["Apuntar al compañero", ["RS"], ""],
	]],
]

## Las estrellas de filigranas del jugador (1 a 5) según su regate.
static func estrellas(reg: float) -> int:
	return clampi(int(reg * 5.0 + 0.5), 1, 5)

# ------------------------------------------------------------------ nombres

const NOMBRE_PS := {JOY_BUTTON_A: "✖", JOY_BUTTON_B: "◯", JOY_BUTTON_X: "▢", JOY_BUTTON_Y: "△",
	JOY_BUTTON_LEFT_SHOULDER: "L1", JOY_BUTTON_RIGHT_SHOULDER: "R1", JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3", JOY_BUTTON_START: "OPTIONS", JOY_BUTTON_BACK: "CREAR",
	JOY_BUTTON_DPAD_UP: "▲", JOY_BUTTON_DPAD_DOWN: "▼", JOY_BUTTON_DPAD_LEFT: "◀", JOY_BUTTON_DPAD_RIGHT: "▶"}
const NOMBRE_XBOX := {JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB", JOY_BUTTON_LEFT_STICK: "LS",
	JOY_BUTTON_RIGHT_STICK: "RS", JOY_BUTTON_START: "Menú", JOY_BUTTON_BACK: "Vista",
	JOY_BUTTON_DPAD_UP: "▲", JOY_BUTTON_DPAD_DOWN: "▼", JOY_BUTTON_DPAD_LEFT: "◀", JOY_BUTTON_DPAD_RIGHT: "▶"}
## El elemento del mando (para el dibujo) de cada botón.
const PIEZA_BOTON := {JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB", JOY_BUTTON_LEFT_STICK: "LS",
	JOY_BUTTON_RIGHT_STICK: "RS", JOY_BUTTON_START: "START", JOY_BUTTON_BACK: "BACK",
	JOY_BUTTON_DPAD_UP: "DPAD", JOY_BUTTON_DPAD_DOWN: "DPAD", JOY_BUTTON_DPAD_LEFT: "DPAD", JOY_BUTTON_DPAD_RIGHT: "DPAD"}

## EL COLOR DE CADA BOTÓN (14-10-2026, pedido: «asociarlo con los colores, un color
## por botón, asociado con el indicativo»). Los cuatro botones de la cara llevan
## los colores de su mando (Xbox: A verde, B rojo, X azul, Y amarillo; PlayStation:
## ✖ azul, ◯ rojo, ▢ rosa, △ verde) y al resto se les da uno propio, distinto. El
## mismo color sale en el aro del botón del mando 3D, en la línea y el icono de su
## etiqueta y en las fichas de cada fila de la tabla.
const COLOR_PIEZA := {
	"LS": Color("2fd4e8"), "RS": Color("ff8a3d"), "DPAD": Color("b78cff"),
	"LB": Color("30c9a0"), "RB": Color("f06ad8"), "LT": Color("8fa8ff"), "RT": Color("ffb86b"),
	"START": Color("e6e6e6"), "BACK": Color("b9bdc8"),
}
const COLOR_CARA_XBOX := {"A": Color("5cc85c"), "B": Color("e8504a"), "X": Color("3f8fe8"), "Y": Color("f2c230")}
const COLOR_CARA_PS := {"A": Color("6ea8ff"), "B": Color("ff6b6b"), "X": Color("f29ad8"), "Y": Color("5fe0b0")}

static func color_pieza(pieza: String, disp: String) -> Color:
	if COLOR_PIEZA.has(pieza):
		return COLOR_PIEZA[pieza]
	var t: Dictionary = COLOR_CARA_PS if disp == "ps" else COLOR_CARA_XBOX
	return t.get(pieza, Color(1, 1, 1))

## Los colores (sin repetir) de las piezas que toca una combinación.
static func colores_de(fichas: Array, disp: String) -> Array:
	var r: Array = []
	for f: String in fichas:
		for pz: String in piezas_de(f):
			var c := color_pieza(pz, disp)
			if pz != "" and not r.has(c):
				r.append(c)
	return r

## El mando que se usa: "ps" si el nombre del enchufado suena a Sony.
static func dispositivo_detectado() -> String:
	for id in Input.get_connected_joypads():
		var n := Input.get_joy_name(id).to_lower()
		if n.contains("sony") or n.contains("ps4") or n.contains("ps5") or n.contains("dualsense") or n.contains("dualshock") or n.contains("playstation"):
			return "ps"
		return "xbox"
	return "teclado"

## El botón del mando de una acción en un dispositivo ("" si no tiene).
static func boton_de(accion: String, disp: String) -> String:
	if not Mando.MAPA.has(accion):
		return ""
	var bs := Mando.botones_de(accion)
	if not bs.is_empty():
		var tabla := NOMBRE_PS if disp == "ps" else NOMBRE_XBOX
		return String(tabla.get(int(bs[0]), "?"))
	match int(Mando.MAPA[accion][3]):
		JOY_AXIS_TRIGGER_RIGHT: return "R2" if disp == "ps" else "RT"
		JOY_AXIS_TRIGGER_LEFT: return "L2" if disp == "ps" else "LT"
		JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y: return "Joystick der." if disp == "ps" else "Stick der."
		JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y: return "Joystick izq." if disp == "ps" else "Stick izq."
	return ""

## Las piezas del mando que toca una ficha (para iluminarlas en el dibujo).
static func piezas_de(ficha: String) -> Array:
	var f := ficha.trim_prefix("mant:").trim_prefix("2x:")
	match f:
		"LS": return ["LS"]
		"RS", "RS_toque", "RS_giro": return ["RS"]
	if not Mando.MAPA.has(f):
		return []
	var bs := Mando.botones_de(f)
	if not bs.is_empty():
		return [String(PIEZA_BOTON.get(int(bs[0]), ""))]
	match int(Mando.MAPA[f][3]):
		JOY_AXIS_TRIGGER_RIGHT: return ["RT"]
		JOY_AXIS_TRIGGER_LEFT: return ["LT"]
		JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y: return ["RS"]
		JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y: return ["LS"]
	return []

## Una ficha escrita para el dispositivo: «Mantener R1», «Doble toque △»…
static func texto_ficha(ficha: String, disp: String) -> String:
	var mant := ficha.begins_with("mant:")
	var doble := ficha.begins_with("2x:")
	var f := ficha.trim_prefix("mant:").trim_prefix("2x:")
	var nombre := ""
	match f:
		"LS": nombre = "WASD" if disp == "teclado" else ("Joystick izq." if disp == "ps" else "Stick izq.")
		"RS": nombre = "Numpad 8/4/6/2" if disp == "teclado" else ("Joystick der." if disp == "ps" else "Stick der.")
		"RS_toque": nombre = "toque Numpad" if disp == "teclado" else ("toque joystick der." if disp == "ps" else "toque stick der.")
		"RS_giro": nombre = "giro Numpad" if disp == "teclado" else ("giro joystick der." if disp == "ps" else "giro stick der.")
		_:
			if disp == "teclado":
				var ts := Mando.teclas_de(f)
				nombre = OS.get_keycode_string(ts[0] as Key) if not ts.is_empty() else "—"
			else:
				nombre = boton_de(f, disp)
	if mant:
		return Idiomas.t("Mantener %s") % nombre
	if doble:
		return Idiomas.t("Doble %s") % nombre
	return nombre

static func texto_fichas(fichas: Array, disp: String) -> String:
	var partes: Array[String] = []
	for f: String in fichas:
		partes.append(texto_ficha(f, disp))
	return " + ".join(partes)

# ------------------------------------------------------------------ gestos

## Estado del reconocedor (uno por motor).
var _seq: Array[String] = []
var _t_ultimo := 0.0
var _t_inicio := 0.0
var _en_centro := true
var _t_centro := 0.0
var _dir_actual := ""
var _mantenido := false

## Una de las ocho direcciones relativas para el vector del stick en el plano
## del jugador (`rel.x` a su derecha, `rel.y` adelante).
static func octante(rel: Vector2) -> String:
	var ang := rad_to_deg(atan2(rel.x, rel.y))
	var i := int(round(ang / 45.0))
	match i:
		0: return "F"
		1: return "FR"
		2: return "R"
		3: return "BR"
		-4, 4: return "B"
		-1: return "FL"
		-2: return "L"
		-3: return "BL"
	return "F"

## Se llama cada fotograma con el stick derecho en el plano del jugador.
## Devuelve una filigrana terminada ({"id", "lado"}) o {}.
func leer(rel: Vector2, t: float, lb: bool, lt: bool, rb: bool, sprint := false) -> Dictionary:
	var fuera := rel.length() > 0.7
	if fuera:
		var d := octante(rel)
		if _en_centro:
			if _seq.is_empty():
				_t_inicio = t
			elif t - _t_centro < 0.3:
				_seq.append("N")
			else:
				_seq.clear()
				_t_inicio = t
			_en_centro = false
		if d != _dir_actual:
			_seq.append(d)
			_dir_actual = d
			_t_ultimo = t
		## Mantener a un lado: la pisada (o la croqueta con LB).
		if not _mantenido and _seq.size() == 1 and (d == "L" or d == "R") and t - _t_ultimo > 0.35:
			_mantenido = true
			return {"id": "croqueta" if lb else "pisada", "lado": 1.0 if d == "R" else -1.0}
		return {}
	if not _en_centro:
		_en_centro = true
		_t_centro = t
		_dir_actual = ""
	## Fin del gesto: un rato en el centro.
	if _seq.is_empty() or t - _t_centro < 0.14:
		return {}
	var seq := _seq.duplicate()
	_seq.clear()
	if _mantenido:
		_mantenido = false
		return {}
	return reconocer(seq, lb, lt, rb, sprint)

## La filigrana que corresponde a una secuencia.
static func reconocer(seq: Array, lb: bool, lt: bool, rb: bool, sprint := false) -> Dictionary:
	var s := " ".join(seq)
	var lado_de := func(d: String) -> float: return 1.0 if d.ends_with("R") else -1.0
	var final_lado: bool = seq.size() == 3 and (String(seq[2]) == "R" or String(seq[2]) == "L")
	## Toques sueltos (con «N» entre medias).
	if s == "B N F N F":
		return {"id": "sombrerito_flair", "lado": 1.0}
	if s == "F N B":
		return {"id": "tacon_rodado" if lb else "tacon_tacon", "lado": 1.0}
	if s == "B N F":
		return {"id": "sombrero", "lado": 1.0}
	if s.begins_with("F N ") and final_lado:
		return {"id": "mcgeady" if sprint else "giro_berba", "lado": lado_de.call(seq[2])}
	if s.begins_with("B N ") and final_lado:
		if lt:
			return {"id": "arrastre_tacon" if sprint else "ruleta_tres", "lado": lado_de.call(seq[2])}
		return {"id": "giro_dragster", "lado": lado_de.call(seq[2])}
	if s == "F":
		if lb and rb:
			return {"id": "cano", "lado": 1.0}
		if sprint:
			return {"id": "adelantar", "lado": 1.0}
	## Giros continuos: cuánto recorre y en qué sentido.
	var giro := _recorrido(seq)
	var primero: String = seq[0]
	var ultimo: String = seq[seq.size() - 1]
	if absf(giro) >= 260.0 and primero.begins_with("B"):
		return {"id": "ruleta", "lado": signf(giro)}
	if absf(giro) >= 160.0:
		## Media luna por delante (elástica) o por detrás (amago y salida).
		var por_delante := seq.has("F")
		if por_delante and (primero == "R" or primero == "FR") and (ultimo == "L" or ultimo == "FL"):
			return {"id": "elastica", "lado": -1.0}
		if por_delante and (primero == "L" or primero == "FL") and (ultimo == "R" or ultimo == "FR"):
			return {"id": "elastica_inversa", "lado": 1.0}
		if seq.has("B"):
			return {"id": "amago_salida", "lado": lado_de.call(ultimo)}
	if absf(giro) >= 60.0:
		if primero == "F":
			return {"id": "bicicleta", "lado": lado_de.call(ultimo)}
		if ultimo == "F":
			return {"id": "bicicleta_inversa", "lado": -lado_de.call(primero)}
		## De atrás a un lado y luego vuelta al contrario.
		if primero.begins_with("B") and seq.size() >= 4:
			return {"id": "hocus_pocus", "lado": lado_de.call(ultimo)}
	if seq.size() == 1 and (primero == "L" or primero == "R"):
		return {"id": "finta_cuerpo", "lado": lado_de.call(primero)}
	return {}

## Grados recorridos por la secuencia (+ en sentido horario: hacia la derecha).
static func _recorrido(seq: Array) -> float:
	const ANG := {"F": 0.0, "FR": 45.0, "R": 90.0, "BR": 135.0, "B": 180.0, "BL": -135.0, "L": -90.0, "FL": -45.0}
	var total := 0.0
	var previo := ""
	for d: String in seq:
		if d == "N" or not ANG.has(d):
			previo = ""
			continue
		if previo != "":
			total += wrapf(float(ANG[d]) - float(ANG[previo]), -180.0, 180.0)
		previo = d
	return total
