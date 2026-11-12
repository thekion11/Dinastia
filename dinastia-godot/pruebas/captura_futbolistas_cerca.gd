extends Node3D
## PRIMEROS PLANOS DE FUTBOLISTAS (sesión 14, 12-11): el mismo camino de creación que el partido
## (`PlayerSpawner._crear_jugador`), 6 jugadores de 3 clubes de PAÍSES distintos (regla 34), para
## ver de cerca lo que la cámara real muestra en pequeño: costura cara-cuello, pelo, proporciones,
## botas y medias. Complementa a `captura_futbolistas.tscn` (la cámara de TV real).
##   PAISES=ENG,ARG,JPN SUFIJO=antes herramientas/captura.sh res://pruebas/captura_futbolistas_cerca.tscn
## Salida: pruebas/capturas/cerca_<plano>_<SUFIJO>.png (cabezas de frente, de perfil y de espaldas,
## cuerpo entero y pies).
var _n := 0
var _cam: Camera3D
var _jug: Array = []
const PLANOS := [
	["cabezas", Vector3(0, 1.62, 2.6), Vector3(0, 1.6, 0), 26.0],
	["perfil", Vector3(2.9, 1.62, 0.15), Vector3(0, 1.6, 0), 24.0],
	["nuca", Vector3(0.4, 1.75, -2.6), Vector3(0, 1.55, 0), 26.0],
	["cuerpo", Vector3(0, 1.05, 5.6), Vector3(0, 0.92, 0), 30.0],
	["pies", Vector3(0, 0.45, 2.4), Vector3(0, 0.18, 0), 30.0],
]

func _ready() -> void:
	var paises: Array[String] = []
	for t in (OS.get_environment("PAISES") if OS.get_environment("PAISES") != "" else "ENG,ARG,JPN").split(","):
		paises.append(t)
	var m := Mundo.new()
	m.generar(paises, 4711)
	_cam = Camera3D.new()
	add_child(_cam)
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.25, 0.42, 0.25)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.57, 0.6)
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	var we := WorldEnvironment.new()
	we.environment = e
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 35, 0)
	sol.shadow_enabled = true
	add_child(sol)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(20, 20)
	suelo.mesh = pm
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.2, 0.45, 0.18)
	suelo.material_override = ms
	add_child(suelo)
	var sp := PlayerSpawner.new()
	var i := 0
	for pais: String in paises:
		var liga: Liga = null
		for l: Liga in m.ligas:
			if l.pais == pais:
				liga = l
				break
		if liga == null:
			continue
		var c: Club = liga.clubes[(i * 3 + 1) % liga.clubes.size()]
		var kit := Puente3D.kit(c)
		sp._kit_x = kit["x"]
		var puestos := 0
		for j: Jugador in c.plantel():
			if j.pos == "POR":
				continue
			var datos := Puente3D.jugador(j)
			var look: Array = PlayerSpawner._look_de(datos)
			var nodo := sp._crear_jugador(self, j.id, j.pos, "", Color(kit["c1"]), Color(kit["c2"]), String(kit["estilo"]),
				7 + i, look[0], look[1], look[2], Color(0, 0, 0, 0), datos)
			if nodo.is_empty():
				continue
			var n3 := nodo["nodo"] as Node3D
			n3.position = Vector3(-1.75 + i * 0.7, 0, 0)
			_jug.append(nodo)
			print("futbolista ", i, " ", pais, " ", j.id, " pelo=", String(datos.get("look", {}).get("pelo", "")))
			i += 1
			puestos += 1
			if puestos == 2:
				break
	## Diagnóstico: LISTAR=1 imprime las mallas del primero; OCULTAR=a,b esconde las que contengan esos nombres.
	if OS.get_environment("LISTAR") != "" and not _jug.is_empty():
		for mi in (_jug[0]["nodo"] as Node).find_children("*", "GeometryInstance3D", true, false):
			print("malla ", mi.get_path(), " ", mi.get_class())
	for t in OS.get_environment("OCULTAR").split(",", false):
		for j: Dictionary in _jug:
			for mi in (j["nodo"] as Node).find_children("*" + t + "*", "GeometryInstance3D", true, false):
				(mi as GeometryInstance3D).visible = false
	_poner_plano(0)

func _poner_plano(k: int) -> void:
	var p: Array = PLANOS[k]
	_cam.position = p[1]
	_cam.fov = p[3]
	_cam.look_at(p[2])

func _process(_d: float) -> void:
	_n += 1
	var k := (_n - 12) / 6
	if _n >= 12 and (_n - 12) % 6 == 5:
		var suf := OS.get_environment("SUFIJO")
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/cerca_%s_%s.png" % [PLANOS[k][0], suf])
		if k + 1 >= PLANOS.size():
			get_tree().quit()
			return
		_poner_plano(k + 1)
