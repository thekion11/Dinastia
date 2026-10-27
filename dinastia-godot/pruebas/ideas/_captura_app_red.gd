extends Node3D
## Captura de la app «Red» del móvil junto a un paradero (orden del dueño 16):
##   herramientas/captura.sh res://pruebas/ideas/_captura_app_red.tscn --png
## Guarda `user://app_red.png` (SALIDA=ruta para otra); el JPG final va a docs/04_auditorias/capturas_ciudad_c2/app_red.jpg.
var _n := 0
var _m: Mundo

func _ready() -> void:
	var amb := WorldEnvironment.new()
	amb.environment = Environment.new()
	amb.environment.background_mode = Environment.BG_COLOR
	amb.environment.background_color = Color(0.55, 0.7, 0.85)
	amb.environment.ambient_light_color = Color(0.8, 0.8, 0.8)
	add_child(amb)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sol)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	suelo.mesh = pm
	add_child(suelo)
	var raiz := Node3D.new()
	raiz.position = Vector3(720, 0, 120)
	add_child(raiz)
	ParaderoRed.montar(raiz, 7.5, 4321)
	suelo.position = raiz.position
	var cam := Camera3D.new()
	add_child(cam)
	cam.look_at_from_position(raiz.position + Vector3(-3, 1.7, 9), raiz.position + Vector3(1.5, 1.6, 0))
	_m = Mundo.new()
	_m.generar(["CHI", "ARG"], 777)
	_m.tomar_el_mando(_m.ligas[0].clubes[0].id)
	if _m.reloj != null:
		_m.reloj._al_dia()
		_m.reloj.avanzar_minutos(1440 + 10 * 60 + 7)
	var capa := CanvasLayer.new()
	add_child(capa)
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(c)
	var pop := Telefono.abrir(c, _m)
	for n in pop.find_children("*", "PanelContainer", true, false):
		if n is Telefono:
			(n as Telefono).en_la_calle = true
			(n as Telefono).posicion_dt = raiz.position + Vector3(-3, 0, 9)
			(n as Telefono).abrir_app("red")

func _process(_d: float) -> void:
	_n += 1
	if _n == 40:
		var ruta := OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "user://app_red.png"
		get_viewport().get_texture().get_image().save_png(ruta)
		print("CAPTURA OK ", ruta)
		get_tree().quit()
