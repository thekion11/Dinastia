extends Node
## CAPTURAS DE LA PANTALLA DE PAÍS (f1g, fase 1 etapa 3), en Forward+:
##   herramientas/captura.sh res://pruebas/f1g_captura_pais.tscn
## Saca, en una sola ejecución (son lentas sin GPU):
##   pais_FRA.png   → Francia, modo normal, con sus clubes y la Torre Eiffel de fondo;
##   pais_JPN.png   → Japón en modo «crear club» (sin clubes), con el Monte Fuji;
##   pais_galeria.png → los 120 monumentos en rejilla, para revisar las siluetas de un vistazo.
## Variables: PAISES="FRA,JPN" (el segundo va en modo crear) y MON=<índice del monumento>.

var _n := 0
var _paso := 0
var _pantalla: PantallaPais
var _paises: PackedStringArray = ["FRA", "JPN"]

func _ready() -> void:
	if OS.get_environment("PAISES") != "":
		_paises = OS.get_environment("PAISES").split(",")
	_montar(_paises[0], false)

func _montar(p: String, crear: bool) -> void:
	if _pantalla != null:
		_pantalla.get_parent().queue_free()
	_pantalla = PantallaPais.new()
	_pantalla.configurar({"modo": "creador" if crear else "dt", "pais": p})
	## Como en el orquestador: dentro de un Control del tamaño de la ventana.
	var caja := Control.new()
	add_child(caja)
	caja.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caja.add_child(_pantalla)
	_pantalla.sin_animaciones()
	var mon := int(OS.get_environment("MON")) if OS.get_environment("MON") != "" else 0
	for i in mon:
		_pantalla.fondo().avanzar()
	_pantalla.globo().ir_a(p, true)

func _galeria() -> void:
	_pantalla.get_parent().queue_free()
	_pantalla = null
	var fondo := ColorRect.new()
	fondo.color = Color("caa56a")
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var tam := get_viewport().get_visible_rect().size
	var i := 0
	var cel := Vector2(tam.x / 12.0, tam.y / 10.0)
	for p: String in PaisDatos.todos():
		for f: Array in PaisDatos.monumentos(p):
			var mo := PaisMonumento.new()
			mo.position = Vector2(i % 12, i / 12) * cel + Vector2(4, 4)
			mo.size = cel - Vector2(8, 8)
			mo.poner(String(f[1]), String(f[2]))
			fondo.add_child(mo)
			i += 1

func _process(_d: float) -> void:
	_n += 1
	if _n < 40:
		return
	_n = 0
	var nombres := ["pais_%s" % _paises[0], "pais_%s" % (_paises[1] if _paises.size() > 1 else "b"), "pais_galeria"]
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % nombres[_paso])
	print("captura ", nombres[_paso])
	_paso += 1
	match _paso:
		1:
			if _paises.size() > 1:
				_montar(_paises[1], true)
			else:
				_galeria()
				_paso = 2
		2:
			_galeria()
		_:
			get_tree().quit()
