extends Node
## Un paseo a pie por la ciudad, con fotos a la altura de los ojos: avenida
## comercial, barrio de casas, parque, puente y cruce con placas.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_paseo.tscn
var _n := 0
var _p: Node
var _v: VistaCiudad
var _e: ExploradorCiudad
## [nombre, posición, rumbo]
const PARADAS := [
	["paseo_1_avenida", Vector3(990.0 + 15.0, 0, -500.0), PI],
	["paseo_2_casas", Vector3(120.0, 0, 1150.0), -PI * 0.5],
	["paseo_3_parque", Vector3(-605.0, 0, 432.0), PI],
	["paseo_4_puente", Vector3(-575.0, 0, -982.0), PI * 0.5],
	["paseo_5_cruce", Vector3(345.0, 0, -658.0), PI * 0.75],
	["paseo_6_calle", Vector3(-224.0, 0, -880.0), PI * 0.5],
]

func _ready() -> void:
	## Sin el tutorial de la ciudad tapando el tercio de abajo de cada foto.
	AjustesCiudad.guardar("tutorial_visto", true)
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_ciclo_activo", false)
		_v.set("_hora", float(OS.get_environment("HORA")) if OS.get_environment("HORA") != "" else 11.0)
		_v.call("_aplicar_hora")
		_v.explorar("pie")
		_e = _v.get("_explorador")
		_e.primera_persona = OS.get_environment("FP") != ""
	var k := (_n - 8) / 8
	if _n >= 8 and (_n - 8) % 8 == 0 and k < PARADAS.size():
		var par: Array = PARADAS[k]
		if k == 1 and OS.get_environment("CASA") != "":
			## Frente a la fachada de una casa del barrio (CASA=n elige cuál).
			var ct: Transform3D = _e.cb.expansion._casas_t[int(OS.get_environment("CASA")) % _e.cb.expansion._casas_t.size()]
			var ix := int(OS.get_environment("CASA")) % _e.cb.expansion._casas_t.size()
			var puerta: Transform3D = _e.cb.expansion._puertas_t[ix]
			var lado := signf(puerta.origin.z - ct.origin.z)
			par = ["casa", Vector3(ct.origin.x, 0, puerta.origin.z + lado * 9.0), 0.0 if lado < 0.0 else PI]
		_e.cuerpo.position = par[1]
		_e.cuerpo.position.y = _e.altura_suelo(par[1].x, par[1].z)
		_e.set("rumbo", float(par[2]))
		_e.cuerpo.rotation.y = float(par[2])
		_e.call("_colocar_camara", 1.0)
		## Como al llegar a un sitio nuevo: la gente se reparte alrededor.
		_e.trafico.reciclar_peatones(_e.cuerpo.position, Vector3.ZERO, 70.0, 22, 28, true)
		if OS.get_environment("DEBUG_MALLAS") != "" and k == 0:
			for g in _e.cb.find_children("*", "MultiMeshInstance3D", true, false):
				var mmq := (g as MultiMeshInstance3D).multimesh
				if mmq != null and mmq.mesh is ArrayMesh and mmq.mesh.get_aabb().size.y > 6.0:
					print("MM ", g.name, " ", mmq.mesh.resource_name, " n=", mmq.instance_count, " ovr=", (g as MultiMeshInstance3D).material_override)
			for g in _e.cb.find_children("*", "GeometryInstance3D", true, false):
				var gp: Vector3 = g.global_position
				if Vector2(gp.x - par[1].x, gp.z - par[1].z).length() < 40.0 and (g is MeshInstance3D) and (g as MeshInstance3D).mesh != null:
					var mm := (g as MeshInstance3D).mesh
					var ab := (g as MeshInstance3D).get_aabb().size * (g as Node3D).global_transform.basis.get_scale()
					if ab.y > 12.0:
						print("MALLA ", g.name, " ", mm.resource_name, " alto=", snappedf(ab.y, 0.1), " ovr=", (g as MeshInstance3D).material_override, " pos=", gp)
	if _n >= 8 and (_n - 8) % 8 == 6 and k < PARADAS.size():
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % PARADAS[k][0])
		print("FOTO ", PARADAS[k][0])
	if k >= PARADAS.size():
		get_tree().quit()
