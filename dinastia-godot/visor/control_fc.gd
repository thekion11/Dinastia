class_name ControlFC
extends RefCounted
## LOS CONTROLES DE FC 26 (14-10-2026, el usuario pasó el manual completo:
## «así debe estar, y si tenemos más trucos agrega combinación»). Aquí viven
## el CATÁLOGO de combinaciones (para el motor y para la pantalla de controles)
## y el RECONOCEDOR DE GESTOS del stick derecho, que convierte los giros y los
## toques del stick en filigranas.
##
## Las direcciones del gesto son RELATIVAS al jugador (como dice el manual:
## «arriba» es hacia donde mira tu futbolista): F adelante, B atrás, L y R sus
## lados, y las diagonales FL, FR, BL, BR. «N» es soltar el stick en medio de
## un gesto (los toques rápidos: «flick adelante y luego a un lado»).

## id: [nombre, estrellas, cómo se hace (texto), animación, efecto]
## Efectos: lateral (sale hacia un lado), lateral_lento (pisada), giro (90°),
## giro_atras (180°), arranque (se lo adelanta y acelera), sombrero (el balón
## por encima del rival), amago (engaña sin tocar el balón).
const FILIGRANAS := {
	"amago_tiro": ["Amago de tiro", 1, "Tiro y, antes de soltar, Pase (o Centro)", "amague_tiro", "amago"],
	"finta_cuerpo": ["Finta de cuerpo", 2, "Toque del stick derecho a un lado", "amague_cuerpo", "lateral"],
	"pisada": ["Pisada de balón", 2, "Mantener el stick derecho a un lado", "pisada_lateral", "lateral_lento"],
	"bicicleta": ["Bicicleta", 2, "Stick derecho: de adelante a un lado (un cuarto de vuelta)", "bicicleta", "lateral"],
	"bicicleta_inversa": ["Bicicleta inversa", 2, "Stick derecho: de un lado hacia adelante", "bicicleta_inversa", "lateral"],
	"arrastre": ["Arrastre atrás", 2, "LB + RB y el stick izquierdo hacia atrás", "arrastre", "giro_atras"],
	"sombrero_corto": ["Autopase elevado (sombrero)", 2, "Pulsar el stick derecho (R3)", "lambreta", "sombrero"],
	"ruleta": ["Ruleta", 3, "Stick derecho: tres cuartos de vuelta empezando atrás", "ruleta", "giro"],
	"tacon_tacon": ["Tacón a tacón", 3, "Stick derecho: toque adelante y luego atrás", "cambio_ritmo", "arranque"],
	"amago_salida": ["Amago y salida", 3, "Stick derecho: media luna por detrás, de un lado al otro", "recorte_exterior", "lateral"],
	"giro_berba": ["Giro de Berba / Cruyff", 4, "Stick derecho: toque adelante y luego a un lado", "giro_cruyff", "giro"],
	"giro_dragster": ["Giro de dragster", 4, "Stick derecho: toque atrás y luego a un lado", "giro_suela", "giro_atras"],
	"croqueta": ["Cambio de carril (la croqueta)", 4, "LB + mantener el stick derecho a un lado", "croqueta", "lateral"],
	"tacon_rodado": ["Tacón con balón rodado", 4, "LB + stick derecho: toque adelante y atrás", "giro_suela", "giro"],
	"sombrero": ["Sombrerito (rainbow)", 4, "Stick derecho: toque atrás, luego adelante", "sombrero", "sombrero"],
	"ruleta_tres": ["Ruleta de tres toques", 4, "LT + stick derecho: toque atrás y a un lado", "ruleta_inversa", "giro"],
	"elastica": ["Cola de vaca (elástica)", 5, "Stick derecho: media luna por delante, de derecha a izquierda", "elastica", "lateral"],
	"elastica_inversa": ["Cola de vaca inversa", 5, "Stick derecho: media luna por delante, de izquierda a derecha", "elastica_inversa", "lateral"],
	"hocus_pocus": ["Sombrero de espaldas (hocus pocus)", 5, "Stick derecho: de atrás a un lado y un cuarto al lado contrario", "media_luna", "lateral"],
	"amago_rabona": ["Amago de rabona", 5, "LT + amago de tiro (Tiro y Pase) corriendo", "rabona_regate", "amago"],
	"cano": ["Caño", 5, "LB + RB + stick derecho adelante", "cano", "arranque"],
}

## Las combinaciones de botones (para la pantalla «Combinaciones»): [qué hace,
## [acciones del mando que se pulsan], cuándo]. Las acciones se escriben con
## las teclas o botones que el jugador tenga puestos (`Mando.corto_de`).
const COMBINACIONES := [
	["ATAQUE", [], ""],
	["Pase raso", ["jugar_pase"], "con balón"],
	["Pase raso tenso (rompe líneas)", ["jugar_mod", "jugar_pase"], "con balón"],
	["Pared (pasa y corre; vuelve a pulsar Pase para la devolución)", ["jugar_cambiar", "jugar_pase"], "con balón"],
	["Pase al hueco", ["jugar_filtrado"], "con balón"],
	["Pase al hueco tenso", ["jugar_mod", "jugar_filtrado"], "con balón"],
	["Pase al hueco bombeado", ["jugar_cambiar", "jugar_filtrado"], "con balón"],
	["Centro / pase largo", ["jugar_centro"], "con balón"],
	["Centro bombeado", ["jugar_cambiar", "jugar_centro"], "con balón"],
	["Centro tenso raso", ["jugar_mod", "jugar_centro"], "con balón"],
	["Tiro (mantener = más potencia)", ["jugar_tiro"], "con balón"],
	["Tiro con rosca (al segundo palo)", ["jugar_mod", "jugar_tiro"], "con balón"],
	["Vaselina", ["jugar_cambiar", "jugar_tiro"], "con balón"],
	["Tiro potente (apuntado manual)", ["jugar_cambiar", "jugar_mod", "jugar_tiro"], "con balón"],
	["Regate técnico (toques cortos)", ["jugar_mod"], "mantener, con balón"],
	["Regate ágil", ["jugar_cambiar"], "mantener, con balón"],
	["Proteger el balón", ["jugar_regate"], "mantener, con balón"],
	["Filigranas", ["jugar_fili_arriba"], "stick derecho (ver la lista)"],
	["DEFENSA", [], ""],
	["Contener (frente al rival, sin entrar)", ["jugar_pase"], "mantener, sin balón"],
	["Entrada / despeje", ["jugar_tiro"], "sin balón"],
	["Barrida", ["jugar_centro"], "sin balón"],
	["Bregar (jockey)", ["jugar_regate"], "mantener, sin balón"],
	["Bregar en carrera", ["jugar_regate", "jugar_sprint"], "mantener, sin balón"],
	["Presión del segundo jugador", ["jugar_mod"], "mantener, sin balón"],
	["Falta táctica (amarilla segura)", ["jugar_mod", "jugar_pase"], "sin balón, cerca del rival"],
	["Cambiar de jugador (al más cercano)", ["jugar_cambiar"], "sin balón"],
	["Cambio manual (apuntando con el stick derecho)", ["jugar_fili_arriba"], "toque del stick derecho, sin balón"],
	["Salida del portero", ["jugar_filtrado"], "mantener, sin balón"],
	["BALÓN PARADO Y PENALES", [], ""],
	["Dirección y altura del lanzamiento", ["jugar_arriba"], "stick izquierdo"],
	["Efecto (curva) del lanzamiento", ["jugar_fili_derecha"], "stick derecho"],
	["Lanzar (mantener = más fuerza)", ["jugar_tiro"], "córner, falta o penal"],
	["Penal colocado con rosca", ["jugar_mod", "jugar_tiro"], "penal"],
	["Panenka", ["jugar_cambiar", "jugar_tiro"], "penal"],
	["TÁCTICAS RÁPIDAS", [], ""],
	["Más ofensiva", ["jugar_tac_arriba"], "en juego"],
	["Más defensiva", ["jugar_tac_abajo"], "en juego"],
	["Presión de equipo (45 s)", ["jugar_tac_izquierda"], "en juego"],
	["Laterales al ataque", ["jugar_tac_derecha"], "en juego"],
]

## Las estrellas de filigranas del jugador (1 a 5) según su regate.
static func estrellas(reg: float) -> int:
	return clampi(int(reg * 5.0 + 0.5), 1, 5)

## Texto de una combinación con las teclas reales: «RB + B».
static func texto_combinacion(acciones: Array) -> String:
	var partes: Array[String] = []
	for a: String in acciones:
		if a.begins_with("jugar_fili_"):
			partes.append(Idiomas.t("stick derecho"))
		elif a == "jugar_arriba":
			partes.append(Idiomas.t("stick izquierdo"))
		else:
			partes.append(Mando.corto_de(a))
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
		3, -4, 4: return "BR" if i == 3 else "B"
		-1: return "FL"
		-2: return "L"
		-3: return "BL"
	return "F"

## Se llama cada fotograma con el stick derecho en el plano del jugador.
## Devuelve una filigrana terminada ({"id", "lado"}) o {}.
func leer(rel: Vector2, t: float, lb: bool, lt: bool, rb: bool) -> Dictionary:
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
			var r := {"id": "croqueta" if lb else "pisada", "lado": 1.0 if d == "R" else -1.0}
			return r
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
	return reconocer(seq, lb, lt, rb)

## La filigrana que corresponde a una secuencia (sin la «N» final).
static func reconocer(seq: Array, lb: bool, lt: bool, rb: bool) -> Dictionary:
	var s := " ".join(seq)
	var lado_de := func(d: String) -> float: return 1.0 if d.ends_with("R") else -1.0
	## Toques sueltos (con «N» entre medias).
	if s == "F N B":
		return {"id": "tacon_rodado" if lb else "tacon_tacon", "lado": 1.0}
	if s == "B N F":
		return {"id": "sombrero", "lado": 1.0}
	if s.begins_with("F N ") and (s.ends_with(" R") or s.ends_with(" L")) and seq.size() == 3:
		return {"id": "giro_berba", "lado": lado_de.call(seq[2])}
	if s.begins_with("B N ") and (s.ends_with(" R") or s.ends_with(" L")) and seq.size() == 3:
		return {"id": "ruleta_tres" if lt else "giro_dragster", "lado": lado_de.call(seq[2])}
	if s == "F" and lb and rb:
		return {"id": "cano", "lado": 1.0}
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
