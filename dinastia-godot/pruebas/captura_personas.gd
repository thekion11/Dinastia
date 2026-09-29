extends Control
## PERSONAS REALISTAS PERSONALIZABLES (25-9-2026).
##
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 \
##         res://pruebas/captura_personas.tscn
##
## Seis retratos con aspectos distintos (ropa, pelo, piel, complexión) y tres
## de cuerpo entero, en `pruebas/capturas/personas_retratos.png`. Comprueba que el
## modelo carga, que el material personalizado se aplica y que dos aspectos
## distintos dan materiales distintos.

var _n := 0
var _fallos := 0

func _comprobar(c: bool, que: String) -> void:
	print(("  ok    " if c else "  FALLO ") + que)
	if not c:
		_fallos += 1

func _ready() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color("121a14")
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	_comprobar(PersonaRealista.disponible(), "el modelo realista está en el proyecto")
	var g := GridContainer.new()
	g.columns = 6
	g.position = Vector2(20, 20)
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	add_child(g)
	var pedidos := [
		{}, {"ropa": "negro", "pelo": "canoso", "piel": "clara"},
		{"ropa": "burdeos", "pelo": "castaño", "piel": "morena"},
		{"ropa": "gris", "pelo": "rubio", "piel": "clara", "pantalon": "negro"},
		{"ropa": "camel", "pelo": "negro", "piel": "oscura"},
		{"ropa": "verde", "pelo": "pelirrojo", "piel": "media"},
	]
	for i in 4:
		var a := PersonaRealista.aspecto("prueba%d" % i, pedidos[i])
		g.add_child(PersonaRealista.retrato(a, Vector2i(200, 200), Color("1d2b22"), "cara"))
	for i in 2:
		var a := PersonaRealista.aspecto("cuerpo%d" % i, pedidos[i * 2 + 1])
		g.add_child(PersonaRealista.retrato(a, Vector2i(200, 330), Color("22313a"), "entero"))
	var p1 := PersonaRealista.crear(PersonaRealista.aspecto("x", {"ropa": "negro"}))
	var p2 := PersonaRealista.crear(PersonaRealista.aspecto("x", {"ropa": "burdeos"}))
	var m1: Material = (p1.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).material_override
	var m2: Material = (p2.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).material_override
	_comprobar(m1 is ShaderMaterial and m2 is ShaderMaterial and m1 != m2, "dos aspectos, dos materiales personalizados")
	p1.free()
	p2.free()

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/personas_retratos.png")
		print("captura_personas: %d fallos" % _fallos)
		get_tree().quit(1 if _fallos > 0 else 0)
