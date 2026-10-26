class_name VitrinaTrofeos
extends SubViewportContainer
## LA VITRINA EN 3D DEL LEGADO (26-10, pedido del dueño): los últimos trofeos
## ganados, en fila sobre una balda iluminada, con la forma de su tipo
## (`Trofeo3D`) y su nombre visible debajo. Solo se pinta una vez
## (`UPDATE_ONCE` tras unos fotogramas): es decorado, no hace falta más.

const MAX := 6

## `trofeos`: [{titulo, anio}, ...] (los de `Roles.trofeos`). null si no hay
## ninguno que mostrar (los «Reto: …» no son trofeos de una competición).
static func crear(trofeos: Array) -> VitrinaTrofeos:
	var lista: Array = []
	for t: Dictionary in trofeos:
		if not String(t.get("titulo", "")).begins_with("Reto"):
			lista.append(t)
	if lista.is_empty():
		return null
	lista = lista.slice(maxi(0, lista.size() - MAX))
	var v := VitrinaTrofeos.new()
	v.stretch = true
	v.custom_minimum_size = Vector2(0, 190)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v._montar(lista)
	return v

func _montar(lista: Array) -> void:
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	add_child(vp)
	var w := Node3D.new()
	vp.add_child(w)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.65, 0.7)
	env.ambient_light_energy = 0.7
	we.environment = env
	w.add_child(we)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-30, 25, 0)
	luz.light_energy = 1.5
	w.add_child(luz)
	var paso := 0.62
	var ancho := paso * float(lista.size())
	var balda := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(ancho + 0.3, 0.04, 0.5)
	balda.mesh = bm
	var mb := StandardMaterial3D.new()
	mb.albedo_color = Color(0.2, 0.14, 0.1)
	mb.roughness = 0.5
	balda.material_override = mb
	balda.position = Vector3(0, -0.02, 0)
	w.add_child(balda)
	for i in lista.size():
		var t: Dictionary = lista[i]
		var nombre := String(t.get("titulo", ""))
		var x := -ancho / 2.0 + paso * (float(i) + 0.5)
		var tro := Trofeo3D.de_competicion(nombre, 0.42)
		tro.position = Vector3(x, 0, 0)
		w.add_child(tro)
		var et := Label3D.new()
		et.text = "%s\n%s" % [CompeticionInfo.nombre_visible(nombre), str(t.get("anio", ""))]
		et.font_size = 32
		et.pixel_size = 0.0016
		et.width = 340
		et.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		et.outline_size = 8
		et.position = Vector3(x, -0.09, 0.27)
		et.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		w.add_child(et)
	var cam := Camera3D.new()
	cam.fov = 34.0
	w.add_child(cam)
	## Que la fila llene el ancho (la vitrina es apaisada, ~3:1): con fov
	## vertical de 34° el medio ángulo horizontal ronda los 42°.
	var dist := maxf(1.0, (ancho * 0.5 + 0.2) / tan(deg_to_rad(40.0)))
	cam.look_at_from_position(Vector3(0, 0.32, dist), Vector3(0, 0.14, 0), Vector3.UP)
