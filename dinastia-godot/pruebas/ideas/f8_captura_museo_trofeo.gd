extends Node
## f8 · MUSEO DEL CLUB CON UN TROFEO EXTERNO (27-10-2026, tarea 8: «regalitos»). Construye solo la sala del
## museo (`SalasClub.museo`) y la fotografía con la cámara del paseo.
##   TROFEO=/ruta/gold_trophy.glb   (opcional) lo deja en `Engine.meta("proto_trofeo")` como una malla y su material;
##                                  una copia LOCAL de `SalasClub.copa` lo puede usar. Sin él, salen las copas de siempre.
##   SALIDA=museo_antes             nombre de la foto (carpeta pruebas/capturas/regalos)
## El modelo NO está en el repositorio: sin licencia clara no se sube. Sin pantalla no hace nada.
var _n := 0
var _raiz: Node3D
var _cam: Camera3D

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("f8: sin pantalla no se captura nada")
		print("===== FIN. 0 fallos =====")
		get_tree().quit()
		return
	var ruta := OS.get_environment("TROFEO")
	if ruta != "" and FileAccess.file_exists(ruta):
		var doc := GLTFDocument.new()
		var est := GLTFState.new()
		if doc.append_from_file(ruta, est) == OK:
			var esc := doc.generate_scene(est)
			for m in esc.find_children("*", "MeshInstance3D", true, false):
				var mi := m as MeshInstance3D
				if mi.name.ends_with("1"):   ## el trofeo del centro
					Engine.set_meta("proto_trofeo", {"malla": mi.mesh, "material": mi.mesh.surface_get_material(0)})
			print("f8: trofeo cargado de ", ruta)
	var ent := Environment.new()
	ent.background_mode = Environment.BG_COLOR
	ent.background_color = Color(0.16, 0.17, 0.2)
	ent.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ent.ambient_light_color = Color(0.85, 0.85, 0.9)
	ent.ambient_light_energy = 0.55
	var we := WorldEnvironment.new()
	we.environment = ent
	add_child(we)
	_raiz = Node3D.new()
	add_child(_raiz)
	var caja := Rect2(0.0, 0.0, 3.6, 6.0)
	SalasClub.museo(_raiz, caja, 0.0, Color("#c01020"), Color("#f2f2f2"), 3, 4)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(8.0, 10.0)
	suelo.mesh = pm
	suelo.position = Vector3(1.8, -0.01, 3.0)
	_raiz.add_child(suelo)
	_cam = Camera3D.new()
	_cam.fov = 62.0
	_raiz.add_child(_cam)
	_cam.position = Vector3(1.8, 1.45, 5.9)
	_cam.look_at(Vector3(1.8, 1.25, 1.2), Vector3.UP)

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		var nombre := OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "museo_antes"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://pruebas/capturas/regalos"))
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/regalos/%s.png" % nombre)
		print("FOTO ", nombre)
		get_tree().quit()
