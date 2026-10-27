extends Node3D
## Cabeza de perfil de un peatón. OCULTA=<nombre de un hijo del esqueleto> lo esconde (para averiguar qué malla sale del mentón).
##   → /tmp/cabeza_<OCULTA|todo>.png
var _n := 0

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	Mini3D.caja(self, Vector3(0, -0.1, 0), Vector3(40, 0.2, 40), Mini3D.mat(Color(0.5, 0.5, 0.48)))
	var d := PeatonVida.nuevo(self, int(OS.get_environment("SEMILLA")) if OS.get_environment("SEMILLA") != "" else 75)
	var n := d["nodo"] as Node3D
	n.rotation.y = 0.0
	Mini3D.anim(d, "parado", "")
	var esq := FutbolistaQ.esqueleto_de(n)
	var oc := OS.get_environment("OCULTA")
	if oc == "glafas":
		for c in esq.get_children():
			if c is BoneAttachment3D and (c as BoneAttachment3D).bone_name == "Head" and not String(c.name).begins_with("Cara") and c.name != "Pelo":
				c.visible = false
	elif oc != "":
		var h := esq.get_node_or_null(oc)
		if h != null:
			h.visible = false
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, 60, 0)
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.74, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.66, 0.7)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 25.0
	cam.position = Vector3(2.2, 1.65, 0.0)
	cam.look_at(Vector3(0, 1.55, 0), Vector3.UP)
	cam.make_current()

func _process(_d: float) -> void:
	_n += 1
	if _n == 25:
		var tag := OS.get_environment("OCULTA") if OS.get_environment("OCULTA") != "" else "todo"
		get_viewport().get_texture().get_image().save_png("/tmp/cabeza_%s.png" % tag)
		get_tree().quit()
