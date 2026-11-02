extends Node3D
## Pies y césped (31-10, `SueloAnim`): los peores fotogramas de la auditoría biomecánica, de lado y con el suelo visible.
##   SUFIJO=despues herramientas/captura.sh res://pruebas/captura_pies_suelo.tscn   (SIN_SUELO_ANIM=1 → sin la corrección)
const CLIPS := [["tiro_canonazo", 0.33], ["volea", 0.27], ["trivela", 0.37], ["zancadilla", 0.33], ["achique", 0.4], ["trotar", 0.23]]
var _n := 0
var _aps: Array = []
func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.65, 0.75)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.55, 0.6)
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = e
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-45, 30, 0)
	sol.shadow_enabled = true
	add_child(sol)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(20, 6)
	suelo.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.5, 0.25, 0.75)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	suelo.material_override = mat
	add_child(suelo)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0.55, 9.0)
	cam.fov = 40
	add_child(cam)
	cam.look_at(Vector3(0, 0.55, 0))
	var c: Club = m.clubes.values()[0]
	var sp := PlayerSpawner.new()
	var kit := Puente3D.kit(c)
	sp._kit_x = kit["x"]
	var j: Jugador = c.plantel()[5]
	var datos := Puente3D.jugador(j)
	var look: Array = PlayerSpawner._look_de(datos)
	for k in CLIPS.size():
		var nodo := sp._crear_jugador(self, j.id, "DEL", "", Color(kit["c1"]), Color(kit["c2"]), String(kit["estilo"]), 10, look[0], look[1], look[2], Color(0, 0, 0, 0), datos)
		var n3 := nodo["nodo"] as Node3D
		n3.position = Vector3(-6.25 + k * 2.5, 0, 0)
		n3.rotation.y = PI * 0.5
		_aps.append([nodo["anim"], CLIPS[k][0], CLIPS[k][1]])
func _process(_d: float) -> void:
	_n += 1
	for c: Array in _aps:
		var ap: AnimationPlayer = c[0]
		if ap.current_animation != String(c[1]):
			ap.play(String(c[1]))
		ap.seek(float(c[2]), true)
		ap.pause()
	if _n == 30:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/pies_suelo_%s.png" % OS.get_environment("SUFIJO"))
		get_tree().quit()
