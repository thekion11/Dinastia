extends Node3D
## LOS AVATARES ELEGIBLES DEL JUGADOR (19-11): los «Modelo base» del creador de personaje (atleta hombre y mujer, los civiles
## modulares de `FutbolistaQ.MODULARES_H/M` y el avatar regalo), creados por el MISMO camino que el juego (`PersonajeDT.crear`)
## y con la luz de tres puntos del estudio del creador (`EstudioPersonaje`). Planos: cuerpo entero y caras.
##   SALIDA=/carpeta SUFIJO=antes herramientas/captura.sh res://pruebas/captura_avatares_elegibles.tscn
## Salida: <SALIDA>/elegibles_<plano>_<SUFIJO>.jpg (sin SALIDA, pruebas/capturas/).
const SEP := 0.85
var _n := 0
var _cam: Camera3D
var _claves: Array[String] = []
## [nombre, primer avatar del grupo (-1 = todos)]
const PLANOS := [["cuerpo", -1], ["caras1", 0], ["caras2", 4], ["caras3", 8]]

func _ready() -> void:
	_claves.assign(["", "@female"])
	for k: String in FutbolistaQ.todos_ajenos():
		_claves.append(k)
	if AvatarRegalo.disponible():
		_claves.append(AvatarRegalo.CLAVE)
	_cam = Camera3D.new()
	add_child(_cam)
	for l: Array in [[Vector3(-32, 28, 0), 1.0, Color(1.0, 0.95, 0.88), true], [Vector3(-12, -45, 0), 0.32, Color(0.8, 0.88, 1.0), false],
			[Vector3(-25, 165, 0), 0.75, Color(1.0, 0.97, 0.92), false]]:
		var luz := DirectionalLight3D.new()
		luz.rotation_degrees = l[0]
		luz.light_energy = float(l[1])
		luz.light_color = l[2]
		luz.shadow_enabled = bool(l[3])
		add_child(luz)
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.16, 0.17, 0.19)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.57, 0.62)
	e.ambient_light_energy = 0.42
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 0.95
	e.tonemap_white = 6.0
	var we := WorldEnvironment.new()
	we.environment = e
	add_child(we)
	var pieles := PersonajeDT.PIELES
	for i in _claves.size():
		var k := _claves[i]
		var nodo := Node3D.new()
		add_child(nodo)
		nodo.position = Vector3((i - (_claves.size() - 1) * 0.5) * SEP, 0, 0)
		var asp := {"cuerpo": "female" if k == "@female" else "male", "modelo": "" if k.begins_with("@") else k,
			"piel": pieles[(i * 5 + 2) % pieles.size()]}
		var fila = FutbolistaQ.todos_ajenos().get(k)
		if fila is Array:
			asp["cuerpo"] = fila[2]
		var d := PersonajeDT.crear(nodo, asp)
		print("elegible ", i, " '", k, "' ", "vacío" if d.is_empty() else "ok")
	_poner(0)

func _poner(k: int) -> void:
	var desde: int = PLANOS[k][1]
	if desde < 0:
		_cam.fov = 36
		_cam.position = Vector3(0, 1.0, _claves.size() * SEP * 0.5 / tan(deg_to_rad(18.0 * 16.0 / 9.0)) + 1.6)
		_cam.look_at(Vector3(0, 0.9, 0))
		return
	## Cuatro caras: centro del grupo, a 4,6 m (las cabezas a ~1,6 m).
	var x := (desde + 1.5 - (_claves.size() - 1) * 0.5) * SEP
	_cam.fov = 22
	_cam.position = Vector3(x, 1.6, 4.6)
	_cam.look_at(Vector3(x, 1.5, 0))

func _process(_d: float) -> void:
	_n += 1
	if _n % 20 != 0:
		return
	var k := _n / 20 - 1
	var sal := OS.get_environment("SALIDA")
	var nombre := "elegibles_%s_%s.jpg" % [PLANOS[k][0], OS.get_environment("SUFIJO")]
	get_viewport().get_texture().get_image().save_jpg(sal.path_join(nombre) if sal != "" else "res://pruebas/capturas/" + nombre, 0.9)
	if k + 1 >= PLANOS.size():
		get_tree().quit()
		return
	_poner(k + 1)
