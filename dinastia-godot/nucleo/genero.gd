class_name Genero
extends Translation
## ENTRENADORA (26-9-2026). Pedido del usuario: *"también poder ser mujer"*.
##
## El creador de personaje ya tiene cuerpo de mujer; faltaba que el juego te
## trate como tal. Los textos se escriben en cientos de sitios, así que en vez
## de tocarlos uno a uno esto se engancha al traductor de Godot: TODO texto de
## la interfaz (etiquetas, botones, avisos) pasa por `tr()` antes de
## dibujarse, y aquí, si tu personaje es mujer, se adaptan las formas que se
## refieren a TI: "el entrenador" -> "la entrenadora", "director deportivo"
## -> "directora deportiva", "Bienvenido" -> "Bienvenida"...
## Lo que habla de OTRO entrenador ("el entrenador rival") no se toca.
## Con un personaje hombre no hace nada (devuelve vacío = texto original).

static var mujer := false
static var _instalado: Genero = null
static var _reglas: Array = []

## Se registra una vez, para el idioma actual.
static func instalar() -> void:
	if _instalado != null:
		return
	_instalado = Genero.new()
	_instalado.locale = TranslationServer.get_locale()
	TranslationServer.add_translation(_instalado)

## Cambia el género; la interfaz se vuelve a traducir sola al refrescar.
static func fijar(es_mujer: bool) -> void:
	instalar()
	if es_mujer == mujer:
		return
	mujer = es_mujer
	if _instalado != null:
		_instalado.locale = TranslationServer.get_locale()

static func _preparar() -> void:
	if not _reglas.is_empty():
		return
	## [patrón, reemplazo]. Orden: de lo más largo a lo más corto.
	var pares := [
		["\\b([Ee])l (entrenador|técnico) principal\\b", "$1l_ entrenadora principal"],
		["\\b([Ee])l entrenador interino\\b", "$1l_ entrenadora interina"],
		["\\bentrenador principal\\b", "entrenadora principal"],
		["\\bEntrenador principal\\b", "Entrenadora principal"],
		["\\bentrenador interino\\b", "entrenadora interina"],
		["\\bEntrenador interino\\b", "Entrenadora interina"],
		["\\b([Ee])l entrenador\\b(?! (rival|del rival|contrario))", "$1l_ entrenadora"],
		["\\b([Dd])el entrenador\\b(?! (rival|del rival|contrario))", "$1e la entrenadora"],
		["\\b([Aa])l entrenador\\b(?! (rival|del rival|contrario))", "$1 la entrenadora"],
		["\\b([Ee])l (DT|míster|mister)\\b(?! (rival|del rival|contrario))", "$1l_ $2"],
		["\\b([Dd])el (DT|míster)\\b(?! (rival|del rival|contrario))", "$1e la $2"],
		["\\bdirector deportivo\\b", "directora deportiva"],
		["\\bDirector deportivo\\b", "Directora deportiva"],
		["\\bDIRECTOR DEPORTIVO\\b", "DIRECTORA DEPORTIVA"],
		["\\bdueño del club\\b", "dueña del club"],
		["\\bDueño del club\\b", "Dueña del club"],
		["\\b([Ee])res el dueño\\b", "$1res la dueña"],
		["\\bpresidente del club\\b", "presidenta del club"],
		["\\bPresidente del club\\b", "Presidenta del club"],
		["\\b([Bb])ienvenido\\b", "$1ienvenida"],
		["\\bestás despedido\\b", "estás despedida"],
		["\\bEstás despedido\\b", "Estás despedida"],
		["\\bhas sido despedido\\b", "has sido despedida"],
		["\\bestás contratado\\b", "estás contratada"],
		["\\bhas sido contratado\\b", "has sido contratada"],
		["\\bnuevo entrenador\\b", "nueva entrenadora"],
		["\\bNuevo entrenador\\b", "Nueva entrenadora"],
		["\\bENTRENADOR\\b", "ENTRENADORA"],
		["\\bEres el\\b", "Eres la"],
		["\\beres el\\b", "eres la"],
		## Concordancia de lo que quedó delante de una forma ya cambiada.
		["\\b([Nn])uevo entrenadora\\b", "$1ueva entrenadora"],
		["\\b([Nn])uevo (directora|dueña|presidenta)\\b", "$1ueva $2"],
		["\\bun entrenadora\\b", "una entrenadora"],
	]
	for p: Array in pares:
		var re := RegEx.new()
		if re.compile(String(p[0])) == OK:
			_reglas.append([re, String(p[1])])

## Adapta un texto (sin depender del traductor: también sirve para textos
## que no pasan por la interfaz, como los de las pruebas).
static func adaptar(texto: String) -> String:
	if not mujer or texto.length() < 4:
		return texto
	_preparar()
	var s := texto
	for r: Array in _reglas:
		s = (r[0] as RegEx).sub(s, String(r[1]), true)
	## "El_" / "el_" es la marca para no depender de mayúsculas en el grupo:
	## "El entrenador" -> "La entrenadora", "el entrenador" -> "la entrenadora".
	return s.replace("El_ ", "La ").replace("el_ ", "la ")

func _get_message(src_message: StringName, _context: StringName) -> StringName:
	if not mujer:
		return &""
	var s := String(src_message)
	var r := adaptar(s)
	return StringName(r) if r != s else &""
