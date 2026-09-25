extends Node
## Barrido de pantallas (13-9-2026) para buscar texto recortado o mini-menus
## que se sientan apretados -queja del usuario: "aun se siente recortada las
## frases o mini menus"-. Recorre varias pestanas principales y saca una
## captura de cada una para inspeccionar a ojo.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##         res://pruebas/captura_sweep_texto.tscn

const ESPERA := 14
## Orden: nombre de pestana -> archivo de salida.
const PESTANAS := [
	["Club", "sweep_club.png"],
	["Gente", "sweep_gente.png"],
	["Historia", "sweep_historia.png"],
	["Operaciones", "sweep_operaciones.png"],
	["Ajustes", "sweep_ajustes.png"],
	["Entrenar", "sweep_entrenar.png"],
	["Mercado", "sweep_mercado.png"],
]

var _n := 0
var _pantalla: Node
var _tabs: TabContainer
var _paso := 0

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		_tabs = _pantalla.get("_pestanas")
	if _n > ESPERA and (_n - ESPERA) % 8 == 0 and _paso < PESTANAS.size():
		var par: Array = PESTANAS[_paso]
		_ir_a(String(par[0]))
	if _n > ESPERA and (_n - ESPERA) % 8 == 4 and _paso < PESTANAS.size():
		var par2: Array = PESTANAS[_paso]
		_guardar("res://pruebas/%s" % String(par2[1]))
		_paso += 1
	if _paso >= PESTANAS.size() and (_n - ESPERA) % 8 == 5:
		get_tree().quit()

func _ir_a(nombre: String) -> void:
	if _tabs == null:
		return
	for i in _tabs.get_tab_count():
		if _tabs.get_tab_title(i) == nombre or _tabs.get_child(i).name == nombre:
			_tabs.current_tab = i
			return
	print("AVISO: no encuentro la pestana '%s'" % nombre)

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s" % ruta)
