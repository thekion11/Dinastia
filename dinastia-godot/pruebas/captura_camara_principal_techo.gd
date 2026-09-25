extends Node
## La cámara "Principal (TV)" quedaba literalmente ENCIMA del techo en
## estadios de 1 nivel (14-9-2026): `alto*0.55+4.0` daba Y=7,575 m, y el techo
## de cada tribuna vuela a `alto+0.4` (grosor 0,5 -> cara inferior en
## `alto+0.15`, aquí 6,65 m). La cámara veía la cara de abajo del techo a
## menos de 1,5 m -un bloque gris liso que tapaba media pantalla, sin ningún
## error en consola, mismo síntoma ya documentado para "Tribuna alta" pero
## nunca corregido aquí-. Confirmado con un raycast manual contra la escena
## real (no a ojo): el primer impacto era el techo, no el césped.
##
## Arreglado con `minf(alto*0.55+4.0, alto-1.5)`. Esta prueba reconstruye el
## caso más grave (1 nivel) y comprueba con el MISMO raycast que el primer
## objeto que ve la cámara, mirando hacia abajo, es el césped.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##         res://pruebas/captura_camara_principal_techo.tscn

var _n := 0
var _mundo: Mundo
var _vista: VistaEstadio
var _meshes: Array = []
var _fallos := 0

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4713)
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)
	_vista = VistaEstadio.new()
	add_child(_vista)
	## Perfil REAL del club, forzando solo "niveles" a 1 -el caso mas grave-.
	## Un perfil a mano incompleto (sin "techo" y demas claves que espera
	## _actualizar_pie()) rompe la construccion a medio camino con un error
	## que no tiene nada que ver con lo que se prueba aqui.
	var perfil := _mundo.perfil_estadio_de(_mundo.mi_club())
	perfil["niveles"] = 1
	_vista.abrir(_mundo.mi_club(), 0.8, null, null, perfil)

func _listar(n: Node) -> void:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var mi3 := n as MeshInstance3D
		_meshes.append({"n": mi3, "aabb": mi3.global_transform * mi3.get_aabb()})
	for h in n.get_children():
		_listar(h)

func _t_entrada(a: AABB, origen: Vector3, dir: Vector3) -> float:
	var tmin := -INF
	var tmax := INF
	for eje in 3:
		var o: float = origen[eje]
		var d: float = dir[eje]
		var lo: float = a.position[eje]
		var hi: float = a.position[eje] + a.size[eje]
		if absf(d) < 0.000001:
			if o < lo or o > hi:
				return -1.0
			continue
		var t1 := (lo - o) / d
		var t2 := (hi - o) / d
		if t1 > t2:
			var tmp := t1; t1 = t2; t2 = tmp
		tmin = maxf(tmin, t1)
		tmax = minf(tmax, t2)
		if tmin > tmax:
			return -1.0
	return tmin if tmin >= 0.0 else tmax

## `py_frac`: fracción de la altura del viewport (0=arriba, 1=abajo). En
## modo headless el viewport NO mide 1280x720 -depende de la resolución base
## del proyecto-, así que usar píxeles fijos apuntaba a un ángulo distinto
## del frustum según el modo en que se corriera la prueba.
func _primer_impacto(cam: Camera3D, py_frac: float) -> MeshInstance3D:
	var tam := get_viewport().get_visible_rect().size
	var punto := Vector2(tam.x * 0.5, tam.y * py_frac)
	var origen := cam.project_ray_origin(punto)
	var dir := cam.project_ray_normal(punto)
	var mejor_t := INF
	var mejor_n: MeshInstance3D = null
	for e in _meshes:
		var t: float = _t_entrada(e["aabb"], origen, dir)
		if t >= 0.0 and t < mejor_t:
			mejor_t = t
			mejor_n = e["n"]
	return mejor_n

func _es_techo(m: MeshInstance3D) -> bool:
	if m == null or not (m.mesh is BoxMesh):
		return false
	var s: Vector3 = (m.mesh as BoxMesh).size
	# El techo es una losa ancha y delgada (0.5 de grosor en Y), muy distinta
	# de cualquier otra caja del estadio (vallas, zocalos, postes).
	return absf(s.y - 0.5) < 0.05 and (s.x > 8.0 or s.z > 8.0)

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		var rig: CameraRig = _vista.get("_rig")
		_listar(_vista)
		# "Principal (TV)": el tercio inferior del encuadre. Antes del arreglo
		# golpeaba el techo; ahora tiene que golpear el cesped.
		var cam: Camera3D = rig.cameras[rig.current_index]
		for py_frac in [0.70, 0.76, 0.90]:
			var m := _primer_impacto(cam, py_frac)
			var ok := m != null and m.mesh is PlaneMesh and (m.mesh as PlaneMesh).size == Vector2(80.0, 117.0)
			if ok:
				print("OK  Principal (TV) y=%.0f%%: ve el cesped" % (py_frac * 100))
			else:
				_fallos += 1
				print("MAL Principal (TV) y=%.0f%%: ve %s en vez del cesped" % [py_frac * 100, m.name if m else "nada"])
		# "Detras del arco": margen calculado de solo 0,375 m contra el mismo
		# techo -se comprueba que el TERCIO SUPERIOR del encuadre (donde
		# tocaría si lo rozara) no golpee el techo primero.
		for i in rig.camera_names.size():
			if String(rig.camera_names[i]).begins_with("Detr"):
				rig.switch_to(i)
				break
		var cam2: Camera3D = rig.cameras[rig.current_index]
		for py_frac in [0.05, 0.15, 0.25]:
			var m2 := _primer_impacto(cam2, py_frac)
			if _es_techo(m2):
				_fallos += 1
				print("MAL Detras del arco y=%.0f%%: ve el TECHO (%s)" % [py_frac * 100, m2.name])
			else:
				print("OK  Detras del arco y=%.0f%%: no ve el techo (ve %s)" % [
					py_frac * 100, m2.name if m2 else "nada/cielo"])
		print("FIN. %d fallo(s)" % _fallos)
		get_tree().quit(1 if _fallos > 0 else 0)
