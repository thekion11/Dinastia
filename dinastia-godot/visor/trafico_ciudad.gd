class_name TraficoCiudad
extends "res://visor/trafico_ciudad_p1.gd"
## [Capa 2/2 de `trafico_ciudad.gd`] _process, diagnostico

func _process(delta_real: float) -> void:
	## RENDIMIENTO (15-10-2026, medido con pruebas/sonda_explorador: 3,4 ms por
	## fotograma con ~310 coches y vecinos, y solo ~25 cerca). Los lejanos se
	## mueven menos a menudo con el tiempo acumulado (niveles abajo); la
	## posición del jugador se pide una vez, no dos por vehículo.
	_cuadro += 1
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var ojo := cam.global_position if cam != null else Vector3.INF
	var hay_jugador := jugador != null and is_instance_valid(jugador)
	var pj := jugador.global_position if hay_jugador else Vector3.ZERO
	var idx := -1
	for v in _vehiculos:
		idx += 1
		## Nivel de detalle: 0 = cerca (cada fotograma), 1 = se ve de lejos
		## (150-260 m: 1 de cada 3), 2 = fuera de la vista (más de 260 m, que es
		## donde dejan de dibujarse: 1 de cada 12). El nivel se recalcula cuando
		## le toca moverse, así los que se saltan no cuestan casi nada.
		if v.get("oculto", false):
			continue
		var nivel := int(v.get("lod", 0))
		if nivel > 0 and (idx + _cuadro) % (3 if nivel == 1 else 12) != 0:
			v["dt"] = float(v.get("dt", 0.0)) + delta_real
			continue
		var delta := delta_real + float(v.get("dt", 0.0))
		v["dt"] = 0.0
		if ojo != Vector3.INF:
			var nv: Node3D = v["nodo"]
			if is_instance_valid(nv):
				var q := nv.position
				var lejos := maxf(absf(q.x - ojo.x), absf(q.z - ojo.z))
				v["lod"] = 0 if lejos < 150.0 else (1 if lejos < 260.0 else 2)
		if float(v.get("espera", 0.0)) > 0.0:
			v["espera"] = float(v["espera"]) - delta
			if float(v["espera"]) <= 0.0 and v.has("pausa"):
				v.erase("pausa")
				_animar(v, "caminar")
			continue
		## NPCs CON VIDA (etapa 1): de vez en cuando un peatón se detiene a mirar
		## el móvil o a descansar y luego sigue su camino.
		if float(v["alto"]) > 0.05 and float(v["alto"]) < 0.3 and randf() < 0.0004 * delta * 60.0:
			v["espera"] = randf_range(3.0, 9.0)
			v["pausa"] = true
			_animar(v, "parado")
			continue
		var avance := float(v["vel"]) * delta
		var ruta := int(v["ruta"])
		var s0 := float(v["s"])
		var largo := (_rutas[ruta] as Ruta).largo
		## En rojo (o ámbar), se detiene en la línea.
		var frena := false
		if semaforos != null and _controles.has(ruta):
			for c: Dictionary in _controles[ruta]:
				var d := fposmod(float(c["s"]) - s0, largo)
				if d < avance + 0.5 and d < 12.0 and not semaforos.verde(int(c["eje"])):
					avance = maxf(0.0, d - 0.3)
					frena = true
					break
		if v.has("faros") and bool(v["frena"]) != frena:
			v["frena"] = frena
			var fm: MeshInstance3D = v["faros"]
			if is_instance_valid(fm):
				fm.set_instance_shader_parameter("freno", 1.0 if frena else 0.0)
		## Las paradas del autobús.
		if v.has("paradas"):
			for ps: float in v["paradas"]:
				var d2 := fposmod(ps - s0, largo)
				if d2 < avance:
					avance = d2 + 0.05
					v["espera"] = float(v.get("espera_parada", 8.0))
					break
		if v.has("cola"):
			for o: Dictionary in _en_cola[ruta]:
				if o == v:
					continue
				var d3 := fposmod(float(o["s"]) - s0, largo)
				if d3 < 9.0:
					avance = minf(avance, maxf(0.0, d3 - 8.0))
		## Un peatón no atraviesa al que va delante en su ruta: si le alcanza a menos
		## de 0,9 m, se queda detrás (adelantar queda para una próxima pasada).
		if _peatones_ruta.has(ruta) and float(v["alto"]) > 0.05 and float(v["alto"]) < 0.3:
			for o: Dictionary in _peatones_ruta[ruta]:
				if o == v:
					continue
				var d4 := fposmod(float(o["s"]) - s0, largo)
				if d4 < 0.9 + avance:
					avance = minf(avance, maxf(0.0, d4 - 0.9))
					## Si se alcanzan, a veces se paran a charlar (etapa 1: NPCs con vida).
					if float(o.get("espera", 0.0)) <= 0.0 and randf() < 0.004:
						_charlar(v, o)
						avance = 0.0
		## CEDER EL PASO AL JUGADOR (etapa 5): un peatón se detiene si estás
		## delante a menos de 1,6 m; un coche, a menos de 7 m. Solo se mira a los
		## que están a menos de 14 m (barato) y solo hacia dónde van.
		if hay_jugador and avance > 0.0:
			var nodo_v: Node3D = v["nodo"]
			if is_instance_valid(nodo_v):
				var rel := Vector3(pj.x - nodo_v.position.x, 0, pj.z - nodo_v.position.z)
				var dist := rel.length()
				if dist < 14.0:
					var dir_v: Vector3 = (_rutas[ruta] as Ruta).en(s0)[1]
					var peaton := float(v["alto"]) < 0.3
					var umbral := 1.6 if peaton else 7.0
					if dist < umbral and rel.normalized().dot(Vector3(dir_v.x, 0, dir_v.z).normalized()) > 0.5:
						avance = 0.0
		v["s"] = s0 + avance
		_colocar(v)

## Comprobación de orientación para las pruebas: hacia dónde mira de verdad el
## vehículo `i` y hacia dónde se está moviendo. Si el producto escalar de los
## dos no es ~1, va de lado o marcha atrás.
func diagnostico(i: int) -> Dictionary:
	if i < 0 or i >= _vehiculos.size():
		return {}
	var v: Dictionary = _vehiculos[i]
	var nodo: Node3D = v["nodo"]
	var r: Ruta = _rutas[int(v["ruta"])]
	var dir: Vector3 = r.en(float(v["s"]))[1]
	## El morro del modelo es su +Z local (medido el 26-9-2026: los coches de
	## Kenney son largos en Z y el capó cae en +Z; antes se suponía X y la flota
	## iba de lado aunque esta prueba diera 1).
	var morro: Vector3 = nodo.global_transform.basis.z.normalized()
	return {"alineacion": morro.dot(dir), "dir": dir, "morro": morro}
