extends Node
## Sonda: ¿qué es el bloque negro con una «P» que tapa la esquina de la cámara de TV? Imprime lo que hay a menos de 10 m de la cámara activa.
var _n := 0
var _vista: VistaEstadio

func _ready() -> void:
	Calidad.elegida = Calidad.ALTO
	AjustesCiudad.guardar("tutorial_visto", true)
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", false)
	cfg.set_value(CajonAjustes.SECCION, "intro", false)
	cfg.save(CajonAjustes.RUTA)
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	Partido.ctx_club_id = m.mi_club_id
	var par := m.proximo_partido()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))

func _process(_d: float) -> void:
	_n += 1
	if _n == 36:
		get_viewport().get_texture().get_image().save_png("/tmp/sonda_36_normal.png")
		var inst := get_tree().root.find_child("Instalaciones", true, false)
		print("INST ", inst)
		if inst != null:
			(inst as Node3D).visible = false
	if _n == 37:
		get_viewport().get_texture().get_image().save_png("/tmp/sonda_37_sin_instalaciones.png")
	if _n >= 20 and _n <= 60 and _n % 8 == 0 and _n != 40:
		get_viewport().get_texture().get_image().save_png("/tmp/sonda_f%d.png" % _n)
		print("RAYOF ", _n, " cam ", get_viewport().get_camera_3d().global_position)
	if _n != 40:
		return
	var cam := get_viewport().get_camera_3d()
	print("CAM ", cam.global_position, " mira ", -cam.global_transform.basis.z)
	var raiz := get_tree().root
	for l in raiz.find_children("*", "Label3D", true, false):
		var d := (l as Label3D).global_position.distance_to(cam.global_position)
		if d < 14.0:
			print("LABEL ", l.get_path(), " '", (l as Label3D).text, "' d=", snappedf(d, 0.1))
	for l in raiz.find_children("*", "Label3D", true, false):
		var t := (l as Label3D).text
		if t.begins_with("P") or t.begins_with("p"):
			print("LABELP ", l.get_path(), " '", t, "' pos=", (l as Label3D).global_position, " d=", snappedf((l as Label3D).global_position.distance_to(cam.global_position), 0.1))
	for nd in raiz.find_children("*", "Node3D", true, false):
		var nm := String(nd.name).to_lower()
		if nm.contains("camar") or nm.contains("tv") or nm.contains("grua") or nm.contains("cabina") or nm.contains("pantalla"):
			print("NODO ", nd.get_path(), " pos=", (nd as Node3D).global_position, " d=", snappedf((nd as Node3D).global_position.distance_to(cam.global_position), 0.1))
	for mi2 in raiz.find_children("*", "MeshInstance3D", true, false):
		var m2 := mi2 as MeshInstance3D
		if m2.mesh is TextMesh and (m2.mesh as TextMesh).text.to_upper().begins_with("P"):
			print("TEXTMESH ", m2.get_path(), " '", (m2.mesh as TextMesh).text, "' pos=", m2.global_position, " d=", snappedf(m2.global_position.distance_to(cam.global_position), 0.1))
	for c in raiz.find_children("*", "Control", true, false):
		var ctl := c as Control
		if ctl.is_visible_in_tree() and ctl.size.x > 20 and ctl.size.y > 20:
			var r := ctl.get_global_rect()
			if r.position.x < 300.0 and r.end.y > 420.0 and r.size.x < 900.0:
				print("CTRL ", ctl.get_path(), " ", ctl.get_class(), " rect=", r, " txt=", (ctl as Label).text if ctl is Label else "")
	get_viewport().get_texture().get_image().save_png("/tmp/sonda_bloque.png")
	var ori := cam.project_ray_origin(Vector2(80, 520))
	var dirr := cam.project_ray_normal(Vector2(80, 520))
	var golpes: Array = []
	for vi2 in raiz.find_children("*", "GeometryInstance3D", true, false):
		var g2 := vi2 as GeometryInstance3D
		if not g2.is_visible_in_tree() or g2 is MultiMeshInstance3D:
			continue
		var caja2: AABB = g2.global_transform * g2.get_aabb()
		var hit: Variant = caja2.grow(0.05).intersects_ray(ori, dirr)
		if hit != null:
			golpes.append([snappedf(ori.distance_to(hit), 0.1), str(g2.get_path()), caja2.size])
	golpes.sort()
	for gh in golpes.slice(0, 8):
		print("RAYO ", gh)
	var telones: Array = []
	for nd2 in raiz.find_children("Telon*", "Node3D", true, false):
		var n3 := nd2 as Node3D
		telones.append([snappedf(n3.global_position.distance_to(cam.global_position), 0.1), str(n3.get_path()), n3.global_position, ((n3 as MeshInstance3D).mesh.get_aabb().size if n3 is MeshInstance3D else Vector3.ZERO)])
	telones.sort()
	for t in telones.slice(0, 6):
		print("TELON ", t)
	var cerca: Array = []
	for vi in raiz.find_children("*", "GeometryInstance3D", true, false):
		var g := vi as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		var caja: AABB = g.global_transform * g.get_aabb()
		var c := caja.get_center()
		var dist := caja.grow(0.0).get_center().distance_to(cam.global_position)
		var dentro := caja.grow(8.0).has_point(cam.global_position)
		if dentro and not str(g.get_path()).contains("Personas") and not str(g.get_path()).contains("Hincha"):
			cerca.append([snappedf(dist, 0.1), str(g.get_path()), g.get_class(), caja.size])
	cerca.sort()
	for c in cerca.slice(0, 25):
		print("GEO ", c)
	print("FIN. 0 fallos")
	get_tree().quit()
