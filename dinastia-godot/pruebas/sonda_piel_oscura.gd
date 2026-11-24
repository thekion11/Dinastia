extends Node
## SONDA (18-11): qué parámetros de piel llegan al shader de cada personaje según el tono de `PersonajeDT.PIELES`. Para ver por qué el más oscuro sale negro.
##   godot --headless --path . res://pruebas/sonda_piel_oscura.tscn
func _ready() -> void:
	for hex in ["7a4a2e", "3a2216"]:
		print(_linea_piel(hex))
	print("FIN")
	get_tree().quit()

## Crea un personaje con la piel `hex` y devuelve una línea por malla con sus parámetros de piel.
func _linea_piel(hex: String) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var asp := PersonajeDT.aleatorio(rng)
	asp["piel"] = hex
	asp["ropa"] = "traje"
	var nodo := Node3D.new()
	add_child(nodo)
	PersonajeDT.crear(nodo, asp, Color(0.8, 0.1, 0.1), Color.WHITE)
	var linea := "PIEL %s -> lineal %s" % [hex, str(snappedf(Color(hex).srgb_to_linear().get_luminance(), 0.001))]
	for mi: Node in nodo.find_children("*", "MeshInstance3D", true, false):
		linea += _describir_mallas(mi as MeshInstance3D)
	return linea

## Una línea por superficie con material de shader: sus parámetros de piel.
func _describir_mallas(m: MeshInstance3D) -> String:
	var texto := ""
	for k in (m.mesh.get_surface_count() if m.mesh != null else 0):
		var mat := m.get_active_material(k)
		if mat is ShaderMaterial:
			texto += _describir_material(m, k, mat as ShaderMaterial)
	return texto

func _describir_material(m: MeshInstance3D, k: int, sm: ShaderMaterial) -> String:
	var ps := ""
	for u in sm.shader.get_shader_uniform_list():
		var nm := String(u["name"])
		if nm in ["hay_cara", "hay_malla", "piel_obj", "piel_foto", "peso_cara", "cara_peso", "tinte_piel", "lum_media", "balance", "quitar_luz", "usa_reposo"]:
			ps += " %s=%s" % [nm, str(sm.get_shader_parameter(nm))]
	return "\n    %s/%s %s%s" % [m.name, k, sm.shader.resource_path.get_file(), ps]
