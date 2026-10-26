extends Node
## s3 (26-10-2026): CAPTURAS CON LA CÁMARA REAL de lo que el plan §8 pedía ver en la ciudad.
##   MODO=pie   herramientas/captura.sh res://pruebas/captura_s3_ciudad.tscn
##     s3_peaton_1/_2: un vecino viene de frente por la acera, se aparta de lado y te pasa al lado.
##     s3_cede_coche:  plantado en el carril, el coche que viene se para a ~7 m de ti.
##   MODO=coche herramientas/captura.sh res://pruebas/captura_s3_ciudad.tscn
##     s3_choque_coche: conduces contra la trasera de un coche parado del tráfico: paras en su
##     parachoques (su forma real), sin atravesarlo.
## El tráfico se mueve a mano (1/30 s por paso) para que el momento de cada foto no dependa de lo
## lento que pinte la máquina. Salen en pruebas/capturas/ (JPG): muévelas a /tmp/capturas/s3/.
const PASO := 1.0 / 30.0
var _n := 0
var _p: Node
var _v: VistaCiudad
var _e: ExploradorCiudad
var _t: TraficoCiudad
var _modo := OS.get_environment("MODO") if OS.get_environment("MODO") != "" else "pie"
var _fase := 0
var _yo_v: Dictionary = {}
var _espera := 0
var _choque_s := 0.0

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto(nombre: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % nombre)
	print("FOTO ", nombre)

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 11.0)
		_v.call("_aplicar_hora")
		_v.explorar(_modo)
		_e = _v.get("_explorador")
		_t = _e.trafico
		_t.set_process(false)
		return
	if _n < 9:
		return
	if _modo == "pie":
		_pie()
	else:
		_coche()
	if _n > 400:
		print("FIN sin todas las fotos (fase %d)" % _fase)
		get_tree().quit(1)

## Coloca al personaje en `pos` mirando hacia `mira`.
func _plantar(pos: Vector3, mira: Vector3) -> void:
	_e.cuerpo.position = Vector3(pos.x, _e.altura_suelo(pos.x, pos.z), pos.z)
	var d := mira - pos
	var r := atan2(d.x, d.z)
	_e.set("rumbo", r)
	_e.cuerpo.rotation.y = r
	_e.set("vel", 0.0)
	_e.call("_colocar_camara", 1.0)

## El vecino visible más cercano a (1005, -500) que no esté parado.
func _vecino(cerca: Vector3, peaton: bool) -> Dictionary:
	var mejor := {}
	var dmin := INF
	for v: Dictionary in _t._vehiculos:
		var alto := float(v["alto"])
		if (alto > 0.05 and alto < 0.3) != peaton or (not peaton and alto >= 0.05) or v.get("oculto", false):
			continue
		if v.has("paradas"):
			continue
		var q: Vector3 = (v["nodo"] as Node3D).position
		var d := Vector2(q.x - cerca.x, q.z - cerca.z).length()
		if d < dmin:
			dmin = d
			mejor = v
	return mejor

## Un vecino con la acera libre (sin quioscos ni farolas) de 1 m detrás a 7 m delante, para
## que la foto le vea. De paso cuenta cuántos tramos de las rutas de peatones cercanas pasan por
## dentro de un obstáculo fijo (se anota en el informe).
func _vecino_libre(cerca: Vector3) -> Dictionary:
	var dentro := 0
	var total := 0
	for rid: int in _t._rutas_gente_cerca(cerca):
		var rr: TraficoCiudad.Ruta = _t._rutas[rid]
		var s := 0.0
		while s < rr.largo:
			var q: Vector3 = rr.en(s)[0]
			if Vector2(q.x - cerca.x, q.z - cerca.z).length() < 120.0:
				total += 1
				if not _e.libre_obst(q, 0.3):
					dentro += 1
			s += 1.0
	print("rutas de peatones a <120 m: %d de %d puntos (cada metro) dentro de un obstáculo" % [dentro, total])
	var lista: Array = []
	for v: Dictionary in _t._vehiculos:
		var alto := float(v["alto"])
		if alto > 0.05 and alto < 0.3 and not v.get("oculto", false):
			var q: Vector3 = (v["nodo"] as Node3D).position
			lista.append([Vector2(q.x - cerca.x, q.z - cerca.z).length(), v])
	lista.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for par: Array in lista:
		var v: Dictionary = par[1]
		var rr: TraficoCiudad.Ruta = _t._rutas[int(v["ruta"])]
		var ok := true
		for k in 17:
			if not _e.libre_obst(rr.en(float(v["s"]) - 1.0 + k * 0.5)[0], 0.9):
				ok = false
				break
		if ok:
			return v
	return lista[0][1]

## Distancia por delante (a lo largo de su ruta) del vecino hasta `p`.
func _delante(v: Dictionary, p: Vector3) -> float:
	var r: TraficoCiudad.Ruta = _t._rutas[int(v["ruta"])]
	var dir: Vector3 = r.en(float(v["s"]))[1]
	var q: Vector3 = (v["nodo"] as Node3D).position
	return Vector2(p.x - q.x, p.z - q.z).dot(Vector2(dir.x, dir.z).normalized())

func _pie() -> void:
	var yo := _e.cuerpo.position
	match _fase:
		0:
			_t.reciclar_peatones(Vector3(1005, 0, -500), Vector3.ZERO, 70.0, 22, 28, true)
			_yo_v = _vecino_libre(Vector3(1005, 0, -500))
			var r: TraficoCiudad.Ruta = _t._rutas[int(_yo_v["ruta"])]
			_yo_v["espera"] = 0.0
			_yo_v["vel"] = 1.3
			## Cinco metros por delante de él, en su misma acera, mirándole.
			var s := float(_yo_v["s"])
			_plantar(r.en(s + 5.0)[0], r.en(s)[0])
			_fase = 1
		1, 2:
			for i in 2:
				_t._process(PASO)
			_yo_v["espera"] = 0.0
			_e.call("_colocar_camara", 1.0)
			var f := _delante(_yo_v, yo)
			if _fase == 1 and f < 2.0:
				print("peatón a %.1f m, lado %.2f" % [f, float(_yo_v.get("lado", 0.0))])
				_foto("s3_peaton_1")
				_fase = 2
			elif _fase == 2 and f < 0.3:
				print("peatón a tu lado, lado %.2f" % float(_yo_v.get("lado", 0.0)))
				_foto("s3_peaton_2")
				_fase = 3
		3:
			## En mitad del carril, 16 m por delante de un coche que viene.
			_yo_v = _vecino(Vector3(1005, 0, -500), false)
			var r2: TraficoCiudad.Ruta = _t._rutas[int(_yo_v["ruta"])]
			var s2 := float(_yo_v["s"])
			_plantar(r2.en(s2 + 16.0)[0], r2.en(s2)[0])
			_fase = 4
			_espera = 0
		4:
			for i in 3:
				_t._process(PASO)
			_e.call("_colocar_camara", 1.0)
			_espera += 1
			if _espera == 60:
				print("coche parado a %.1f m de ti" % _delante(_yo_v, yo))
				_foto("s3_cede_coche")
				print("FIN. 0 fallos")
				get_tree().quit()

func _coche() -> void:
	match _fase:
		0:
			_yo_v = _vecino(Vector3(1005, 0, -500), false)
			_yo_v["espera"] = 1000.0
			var r: TraficoCiudad.Ruta = _t._rutas[int(_yo_v["ruta"])]
			var s := float(_yo_v["s"])
			_choque_s = s
			_plantar(r.en(s - 14.0)[0], r.en(s)[0])
			_fase = 1
			_espera = 0
		1:
			## Acelera hacia su trasera; el explorador hace la física y los choques.
			_t._process(PASO)
			_e.set("vel", maxf(float(_e.get("vel")), 7.0) if _espera < 40 else float(_e.get("vel")))
			_espera += 1
			if _espera == 70:
				print("tu coche a %.1f m (centro a centro) del coche parado, vel %.1f" % [
					Vector2(_e.cuerpo.position.x - (_yo_v["nodo"] as Node3D).position.x,
						_e.cuerpo.position.z - (_yo_v["nodo"] as Node3D).position.z).length(), float(_e.get("vel"))])
				_e.cam_coche = 0
				_e.call("_colocar_camara", 1.0)
				_foto("s3_choque_coche")
				print("FIN. 0 fallos")
				get_tree().quit()
