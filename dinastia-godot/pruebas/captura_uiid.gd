extends Node
## CAPTURAS DEL PAQUETE uiid (25-10-2026): identidad del club, editor del mundo,
## diseñador del estadio y ciudad 2D, con la pantalla principal de verdad.
## Una sola arrancada saca todas las vistas (en Forward+ sin GPU cada arranque
## cuesta mucho): cada paso pinta una pestaña, la desplaza hasta lo que interesa
## y guarda `uiid_<etiqueta>_<ancho>.png`.
##
##   RESOLUCION=1280x720 IDIOMA=en herramientas/captura.sh res://pruebas/captura_uiid.tscn
##   (VISTAS=identidad,kits,estadio,editor,ciudad elige cuáles; por defecto, todas)

const ESPERA := 14
const PASO := 14

var _n := 0
var _pantalla: Node
var _vistas: Array = []
var _i := -1

func _ready() -> void:
	var v := OS.get_environment("VISTAS")
	_vistas = (v if v != "" else "identidad,escudo,kits,estadio,editor,ciudad").split(",")
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n < ESPERA:
		return
	if _n == ESPERA:
		var idioma := OS.get_environment("IDIOMA")
		if idioma != "":
			Idiomas.idioma = idioma
		var mio: Club = (_pantalla.get("mundo") as Mundo).mi_club()
		mio.saldo = 999999999
	var k := _n - ESPERA
	if k % PASO == 0:
		if _i >= 0:
			_guardar(String(_vistas[_i]))
		_i += 1
		if _i >= _vistas.size():
			get_tree().quit()
			return
		_pintar(String(_vistas[_i]))
	elif k % PASO == 3 and _i < _vistas.size():
		_desplazar(String(_vistas[_i]))

func _pestana(titulo: String) -> void:
	var tabs: TabContainer = _pantalla.get("_pestanas")
	for i in tabs.get_tab_count():
		if tabs.get_tab_title(i) == titulo:
			tabs.current_tab = i
			return

func _pintar(vista: String) -> void:
	var mundo: Mundo = _pantalla.get("mundo")
	var mio: Club = mundo.mi_club()
	match vista:
		"identidad", "escudo", "kits":
			## Por el chip de verdad: `_refrescar()` repinta la sección elegida.
			_pestana("Gente")
			_pantalla.set("_secc_gente", "identidad")
			_pantalla.call("_refrescar")
		"estadio":
			_pestana("Estadio")
			_pantalla.call("_pintar_estadio", mio)
		"editor":
			_pestana("Editor")
			_pantalla.set("_ed_club", mio.id)
			if not mio.plantilla.is_empty():
				_pantalla.set("_ed_jugador", (mio.plantilla[0] as Jugador).id)
			(_pantalla.get("_ui_editor") as Object).call("_pintar_editor")
		"ciudad":
			_pestana("Ciudad")
			_pantalla.call("_pintar_ciudad", mio)

## Lleva el desplazamiento hasta el primer texto que contenga la marca: lo de
## abajo de cada pantalla es justo lo que nadie revisa.
func _desplazar(vista: String) -> void:
	var marcas := {"kits": "LAS TRES CAMISETAS", "escudo": "3 · ESCUDO", "editor": "CLUBES", "estadio": "LA ESTRUCTURA",
		"ciudad": ""}
	var marca := String(marcas.get(vista, ""))
	if marca == "":
		return
	var lista: Control = _pantalla.get({"kits": "_lista_gente", "escudo": "_lista_gente", "editor": "_lista_editor",
		"estadio": "_lista_estadio"}.get(vista, "_lista_gente"))
	var objetivo := _buscar(lista, marca)
	var scroll := lista.get_parent() as ScrollContainer
	if objetivo != null and scroll != null:
		scroll.scroll_vertical = int(objetivo.position.y)

func _buscar(n: Node, texto: String) -> Control:
	for h in n.get_children():
		if (h is Label and Idiomas.t(texto) != "" and (h as Label).text.to_upper().contains(Idiomas.t(texto).to_upper())) \
				or (h is Label and (h as Label).text.contains(texto)):
			return h
	return null

func _guardar(vista: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var ruta := "res://pruebas/capturas/uiid_%s_%d.png" % [vista, img.get_width()]
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
