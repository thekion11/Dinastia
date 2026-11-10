extends Node
## Sesión 6 (10-11): la ficha de Competición con los formatos nuevos de los torneos continentales.
##   RESOLUCION=1280x900 herramientas/captura.sh res://pruebas/captura_conti_formatos.tscn
## Tres clubes de tres países y tres formatos (Champions con fase de liga, Libertadores con 8 grupos, Mundial de Clubes de 32);
## de cada uno, dos momentos: la primera fase a medias y el cuadro con ida y vuelta.
## Las fotos se guardan en pruebas/capturas/conti_<clave>_<momento>.png (JPG tras `captura.sh`).
const CASOS := [
	{"pais": "ITA", "paises": ["ESP", "ENG", "ITA", "GER", "FRA", "POR", "NED", "BEL", "CRO", "DEN"], "semilla": 301, "clave": "ucl"},
	{"pais": "BRA", "paises": ["CHI", "ARG", "BRA", "COL", "URU", "PER", "ECU", "PAR", "BOL"], "semilla": 302, "clave": "lib"},
	{"pais": "JPN", "paises": ["JPN", "KOR", "KSA", "AUS"], "semilla": 303, "clave": "asia"},
]
var _caso := 0
var _paso := 0
var _n := 0
var _mundo: Mundo
var _ficha: Competicion
var _torneo: Continental

func _ready() -> void:
	_siguiente_caso()

func _siguiente_caso() -> void:
	if _caso >= CASOS.size():
		get_tree().quit()
		return
	var c: Dictionary = CASOS[_caso]
	_mundo = Mundo.new()
	var paises: Array[String] = []
	for p in c["paises"]:
		paises.append(String(p))
	_mundo.generar(paises, int(c["semilla"]))
	var mio: Club = null
	for k: Club in _mundo.clubes.values():
		if k.pais == String(c["pais"]) and k.division == 1 and (mio == null or k.rep > mio.rep):
			mio = k
	_mundo.tomar_el_mando(mio.id)
	_torneo = _mundo.continentales.get(String(c["clave"]))
	_paso = 0
	_n = 0

func _foto(momento: String) -> void:
	var nombre := "conti_%s_%s" % [CASOS[_caso]["clave"], momento]
	if DisplayServer.get_name() != "headless":   ## sin pantalla (`especiales.sh`) solo se comprueba que la ficha se construye sin errores
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % nombre)
	print("FOTO ", nombre, "  (", _torneo.nombre_de_ronda(), ")")

func _abrir_ficha() -> void:
	if _ficha != null:
		_ficha.queue_free()
	_ficha = Competicion.new()
	_ficha.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_ficha)
	_ficha.abrir(_mundo, _mundo.liga_de(_mundo.mi_club()))
	var sel: OptionButton = _ficha.get("_selector")
	for i in sel.item_count:
		if _ficha.get("_entradas")[i] == _torneo:
			sel.select(i)
			_ficha._elegir(i)

func _process(_d: float) -> void:
	_n += 1
	if _caso >= CASOS.size() or _torneo == null:
		return
	if _n == 3:
		var primera := 4 if _torneo.clave != "lib" else 3
		for i in primera:
			_torneo.jugar_ronda()
		_abrir_ficha()
	elif _n == 25:
		_foto("1_primera_fase")
		## Hasta una ida y vuelta de la primera ronda con eliminatoria.
		var vueltas := 0
		while _torneo.en_curso() and vueltas < 40 and not _torneo.historial.any(func(h: Dictionary) -> bool: return (h["resultados"] as Array).any(func(r: Dictionary) -> bool: return r.has("agregado"))):
			_torneo.jugar_ronda()
			vueltas += 1
		_abrir_ficha()
	elif _n == 50:
		_foto("2_cuadro")
		_ficha.queue_free()
		_ficha = null
		_caso += 1
		_siguiente_caso()
