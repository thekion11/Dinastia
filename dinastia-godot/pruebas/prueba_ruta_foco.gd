extends Node
## EL FOCO DE «LA RUTA» (mando y teclado): en cada pantalla, desde el
## botón con foco, recorre con arriba/abajo/izquierda/derecha y cuenta los
## botones visibles a los que NO se llega.
## Falla si alguna pantalla empieza sin foco o deja botones sin alcanzar.
##   [MOVIL=1] xvfb-run -a godot --path . --resolution 1280x720 res://pruebas/prueba_ruta_foco.tscn   (de pie: 608x1080)
var _ui: CarreraJugadorUI
var _fallos := 0

func _alcanzables(desde: Control) -> Dictionary:
	var vistos := {desde: true}
	var cola: Array = [desde]
	while not cola.is_empty():
		var n: Control = cola.pop_back()
		for lado: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			var v := n.find_valid_focus_neighbor(lado)
			if v != null and not vistos.has(v):
				vistos[v] = true
				cola.append(v)
	return vistos

func _mirar(nombre: String, raiz: Node) -> void:
	for _i in 5:
		await get_tree().process_frame
	var foco := get_viewport().gui_get_focus_owner()
	var botones: Array = []
	for n: Node in raiz.find_children("*", "Button", true, false):
		var b := n as Button
		if b.is_visible_in_tree() and not b.disabled and b.focus_mode == Control.FOCUS_ALL:
			botones.append(b)
	if foco == null:
		_fallos += 1
		print("  FALLO FOCO %s: SIN FOCO INICIAL (%d botones)" % [nombre, botones.size()])
		return
	var al := _alcanzables(foco)
	var fuera: Array = []
	for b2: Button in botones:
		if not al.has(b2):
			fuera.append(b2.text.left(24))
	_fallos += fuera.size()
	print("%sFOCO %s: empieza en «%s»; %d botones, %d sin alcanzar %s" % ["  FALLO " if not fuera.is_empty() else "  ok    ", nombre, (foco as Button).text.left(24) if foco is Button else str(foco), botones.size(), fuera.size(), str(fuera.slice(0, 8))])

func _ready() -> void:
	RutaEstilo.sin_animar = true
	if OS.get_environment("MOVIL") == "1":
		EscalaMovil.forzar = true
		EscalaMovil.poner(get_tree(), EscalaMovil.ZOOM_MOVIL)
	CarreraJugadorUI.mundo = null
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)
	await _mirar("crear", _ui)
	_ui._buscar_club()
	await _mirar("ofertas", _ui)
	_ui._firmar(null)
	var c := _ui.carrera
	var m := CarreraJugadorUI.mundo
	c.ruta["puntos"] = 2
	c.ruta["ahorros"] = CarreraVida.precio(c, m, "fisio")
	for pest: String in ["hoy", "yo", "ruta"]:
		_ui._pestana = pest
		_ui._pintar_semana()
		await _mirar(pest, _ui)
	var toque := RutaToque.abrir(_ui)
	await _mirar("toque", toque)
	toque.free()
	var mo := RutaMomentos.abrir(_ui, _ui._partido_de_la_semana(c.club(m)))
	await _mirar("momentos", mo)
	mo.free()
	c.tras_partido(m, {"minutos": 90, "goles": 1, "asist": 0, "nota": 7.4, "titular": true})
	_ui._pestana = "hoy"
	_ui._pintar_semana()
	await _mirar("resumen", _ui._cuerpo.get_child(_ui._cuerpo.get_child_count() - 1))
	print("===== FIN. %d fallos =====" % _fallos)
	get_tree().quit()
