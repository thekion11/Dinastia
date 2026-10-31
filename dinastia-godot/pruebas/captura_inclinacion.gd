extends Node3D
## La inclinación del cuerpo al correr (31-10): recto, girando a tope (`MovimientoNatural.INCLINA_MAX`) y arrancando
## (`ADELANTE_MAX`). Arriba desde detrás, abajo de lado. herramientas/captura.sh res://pruebas/captura_inclinacion.tscn
var _n := 0
var _aps: Array = []
func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.25, 0.42, 0.28)
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
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.3, 9.5)
	cam.fov = 38
	add_child(cam)
	cam.look_at(Vector3(0, 0.0, 0))
	var c: Club = m.clubes.values()[0]
	var sp := PlayerSpawner.new()
	var kit := Puente3D.kit(c)
	sp._kit_x = kit["x"]
	var j: Jugador = c.plantel()[5]
	var datos := Puente3D.jugador(j)
	var look: Array = PlayerSpawner._look_de(datos)
	## [rotación del cuerpo (giro, cabeceo, balanceo)] por columna; fila 0 de espaldas a la cámara, fila 1 de lado.
	var poses := [Vector3.ZERO, Vector3(0, 0, MovimientoNatural.INCLINA_MAX), Vector3(MovimientoNatural.ADELANTE_MAX, 0, 0)]
	for fila in 2:
		for k in 3:
			var nodo := sp._crear_jugador(self, j.id, "DEL", "", Color(kit["c1"]), Color(kit["c2"]), String(kit["estilo"]), 10, look[0], look[1], look[2], Color(0, 0, 0, 0), datos)
			var n3 := nodo["nodo"] as Node3D
			n3.position = Vector3(-3.0 + k * 3.0, 0.6 - fila * 2.4, 0)
			var r: Vector3 = poses[k]
			n3.rotation = Vector3(r.x, PI if fila == 0 else PI * 0.5, r.z)
			_aps.append(nodo["anim"])
func _process(_d: float) -> void:
	_n += 1
	for ap: AnimationPlayer in _aps:
		if ap.current_animation != "correr":
			ap.play("correr")
		ap.seek(0.2, true)
		ap.pause()
	if _n == 30:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/inclinacion.png")
		get_tree().quit()
