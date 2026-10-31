class_name EstacionCentral
extends Node3D
## LA ESTACIÓN CENTRAL (27-10-2026): antes una caja con bóveda. Ahora es una estación de cabecera de verdad, con el kit
## `assets/kenney/tren` (Train Kit de Kenney, escala ×2,4): vestíbulo con fachada de cristal y bóveda, andén isla con
## marquesina, dos vías con topes y un túnel cubierto por el norte por donde SALEN y ENTRAN los trenes (la vía «sale de la
## ciudad» bajo tierra: el viaducto de las líneas de metro ya ocupa el aire). Cada vía tiene su tren (tres coches) que llega,
## espera con las puertas a la vista, retrocede hacia el túnel y deja la vía vacía un rato; los dos van desfasados
## media vuelta. El ciclo va por el RELOJ DEL JUEGO (`reloj`, que pone `VidaCiudad`): CICLO s ÷ 6 = ~11,7 min de juego por vuelta
## (con el reloj vivo 1 min de juego = 6 s reales); sin reloj (pruebas) corre en segundos reales. De 01:00 a 05:00 no hay servicio.
## Los trenes cuelgan de este nodo con script: `Optimizar.agrupar` no los toca.

const RUTA := "res://assets/kenney/tren/"
const S := 2.4                               ## escala del kit (vía de 1 m → 2,4 m)
const CICLO := 240.0                          ## 96 s llegando desde el horizonte, 30 s parado, 96 s saliendo y un respiro
const LLEGADA := 96.0
const ESPERA := 30.0
const SALIDA := 96.0
const VIA_X := 8.0
const Y_TREN := 0.25 + 0.36 * S              ## altura del tren sobre la vía en el andén
const LARGO_TUNEL := 26.0

## El reloj de la partida (lo pone `VidaCiudad.enganchar`); null = tiempo real.
static var reloj: Reloj = null

var _trenes: Array = []
var _reloj_rotulo: Label3D
var _min_vista := -1
var _seg_min := 0.0                      ## [{nodo, fase, z0, z1}]
var _t := 0.0
var cuenta := {}
var perfil_via := PackedFloat32Array()   ## altura del terreno a lo largo de la vía exterior (`ViaEstacion.perfil`)
var z_tunel_anden := 0.0                 ## z donde empieza el túnel del andén (el tren va por el subsuelo antes)
var largo_del_tren := 0.0
var z_vestibulo := 0.0                   ## z (local) donde los pasajeros entran al vestíbulo
var _gente: Array = []                   ## los pasajeros (`PasajerosEstacion`), creados al primer tren con servicio

## `c` centro del bloque (y = suelo), `w` x `f` su tamaño; `mats` = materiales de la ciudad (claro, vidrio, piedra).
static func montar(b: CityBuilder, c: Vector3, w: float, f: float, mats: Dictionary, ex: CiudadExpansion = null) -> EstacionCentral:
	var s := EstacionCentral.new()
	s.name = "EstacionCentral"
	s.position = c
	b.add_child(s)
	s._construir(b, w, f, mats, ex)
	return s

func _caja(b: CityBuilder, pos: Vector3, tam: Vector3, mat: Material) -> void:
	var mi := b._caja_en(pos, tam, mat)
	b.remove_child(mi)
	mi.position = pos
	add_child(mi)

func _pieza(nombre: String, pos: Vector3, giro: float = 0.0) -> Node3D:
	var e := load(RUTA + nombre + ".glb") as PackedScene
	if e == null:
		return null
	var n: Node3D = e.instantiate()
	n.scale = Vector3.ONE * S
	n.position = pos
	n.rotation.y = giro
	add_child(n)
	return n

func _construir(b: CityBuilder, w: float, f: float, mats: Dictionary, ex: CiudadExpansion) -> void:
	var z_h0 := -f * 0.5 + 2.0
	var z_h1 := z_h0 + LARGO_TUNEL               ## la boca del túnel, hacia el andén
	var z_tope := f * 0.13                        ## los topes de las vías
	var gris := b._mat_simple(Color(0.62, 0.63, 0.64), 0.8)
	var beton := StandardMaterial3D.new()          ## hormigón con manchas (el ruido del subsuelo), triplanar
	beton.albedo_texture = SubsueloDetalle._ruido(31, 0.04, FastNoiseLite.TYPE_SIMPLEX_SMOOTH)
	beton.albedo_color = Color(0.62, 0.62, 0.6)
	beton.uv1_triplanar = true
	beton.uv1_scale = Vector3(0.12, 0.12, 0.12)
	beton.roughness = 0.9
	var oscuro := b._mat_simple(Color(0.08, 0.08, 0.09), 0.9)
	var acero := b._mat_simple(Color(0.3, 0.32, 0.34), 0.5)
	## Vías: tramos del kit de 9,6 m desde el fondo del túnel hasta los topes.
	var n_tramos := int(ceil((z_tope - z_h0) / (4.0 * S)))
	for sx: float in [-VIA_X, VIA_X]:
		for k in n_tramos:
			_pieza("railroad-straight", Vector3(sx, 0.25, z_h0 + float(k) * 4.0 * S))
		_caja(b, Vector3(sx, 0.9, z_tope + 0.6), Vector3(2.6, 1.2, 0.8), b._mat_simple(Color(0.7, 0.15, 0.1), 0.6))   ## tope
	## El túnel cubierto: un cilindro de hormigón medio enterrado con la BOCA oscura al frente (el disco oscuro tapa el
	## cuerpo del tren que aún está dentro: sale de la sombra y vuelve a entrar en ella).
	var largo := LARGO_TUNEL
	var cuerpo := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 13.5
	cm.bottom_radius = 13.5
	cm.height = largo
	cm.radial_segments = 28
	cuerpo.mesh = cm
	cuerpo.material_override = beton
	cuerpo.rotation.x = PI * 0.5
	cuerpo.position = Vector3(0, 0, z_h0 + largo * 0.5)
	add_child(cuerpo)
	var boca := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 12.0
	dm.bottom_radius = 12.0
	dm.height = 0.1
	dm.radial_segments = 28
	boca.mesh = dm
	var sombra := StandardMaterial3D.new()
	sombra.albedo_color = Color(0.015, 0.015, 0.02)
	sombra.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	boca.material_override = sombra
	boca.rotation.x = PI * 0.5
	boca.position = Vector3(0, 0, z_h1 + 0.06)
	add_child(boca)
	_rotulo(Vector3(0, 12.9, z_h1 + 0.3), "TÚNEL · VÍAS 1-2", 0.008)
	## Andén isla con marquesina.
	var z_a0 := z_h1 + 2.0
	var largo_a := z_tope - z_a0 + 4.0
	_caja(b, Vector3(0, 0.45, z_a0 + largo_a * 0.5), Vector3(12.0, 0.9, largo_a), beton)
	_caja(b, Vector3(0, 0.92, z_a0 + largo_a * 0.5), Vector3(0.3, 0.05, largo_a), b._mat_simple(Color(0.95, 0.8, 0.1), 0.6))   ## línea amarilla
	_caja(b, Vector3(0, 7.4, z_a0 + largo_a * 0.5), Vector3(15.0, 0.5, largo_a), b._mat_simple(Color(0.35, 0.45, 0.5), 0.5))
	for k in 4:
		var z := z_a0 + 3.0 + float(k) * (largo_a - 6.0) / 3.0
		for sx: float in [-5.5, 5.5]:
			_caja(b, Vector3(sx, 3.9, z), Vector3(0.4, 7.0, 0.4), acero)
		_caja(b, Vector3(0, 1.125, z + 2.0), Vector3(0.8, 0.45, 3.0), b._mat_simple(Color(0.4, 0.28, 0.18), 0.8))   ## banco (asiento a 0,45 m del andén)
		for dz: float in [-0.8, 0.8]:
			b.asientos.append({"p": position + Vector3(0, 1.35, z + 2.0 + dz), "giro": PI * 0.5})   ## los pasajeros (`GenteSentada`)
	_rotulo(Vector3(0, 6.6, z_a0 + 4.0), "ANDÉN 1 ◄ ► ANDÉN 2", 0.008)
	## El vestíbulo: fachada de cristal, bóveda y el nombre.
	var z_v := f * 0.30
	_caja(b, Vector3(0, 6.5, z_v), Vector3(w * 0.85, 13.0, f * 0.3), mats["claro"])
	b._boveda(position + Vector3(0, 13.0, z_v), w * 0.85, f * 0.3, b._mat_simple(Color(0.5, 0.62, 0.7), 0.3), 0.3)
	var z_front := z_v + f * 0.15
	if ex != null:
		FachadaModular.montar(ex, position.x, position.z + z_front, position.y, w * 0.85, 3, true, true)   ## puertas de cristal y marquesina
	else:
		_caja(b, Vector3(0, 5.0, z_front + 0.1), Vector3(w * 0.6, 7.0, 0.2), mats["vidrio"])
	_rotulo(Vector3(0, 15.0, z_front + 0.8), "ESTACIÓN CENTRAL", 0.035)
	ExpendedoraCiudad.montar(b, position + Vector3(12.5, 0.3, z_front + 4.0), 0.0)   ## una máquina expendedora junto a las puertas (cobra de la cartera; en +2 quedaba dentro de la fachada)
	if ex != null:
		CajeroCiudad.montar(ex, position + Vector3(15.0, 0.3, z_front + 4.0), 0.0)   ## y un cajero al lado (§2.5; a la izquierda lo tapaba la parada de taxis)
	var disco := b._cil_en(position + Vector3(0, 12.0, z_front + 1.6), 1.6, 0.4, b._mat_simple(Color(0.95, 0.95, 0.9), 0.4))
	disco.rotation.x = PI * 0.5
	_reloj_rotulo = Label3D.new()
	_reloj_rotulo.text = "--:--"
	_reloj_rotulo.font_size = 48
	_reloj_rotulo.pixel_size = 0.03
	_reloj_rotulo.modulate = Color(0.05, 0.05, 0.08)
	_reloj_rotulo.position = Vector3(0, 12.0, z_front + 1.85)
	add_child(_reloj_rotulo)
	## Parada de taxis y autobuses delante (a la izquierda) y marquesina a la derecha.
	var taxi := load("res://assets/ciudad/kenney_cars/taxi.glb") as PackedScene
	if taxi != null:
		for k in 3:
			var t: Node3D = taxi.instantiate()
			t.scale = Vector3.ONE * 2.6
			t.position = Vector3(-w * 0.33 + float(k) * 6.0, 0.0, z_front + 4.2)
			t.rotation.y = PI * 0.5
			add_child(t)
	_caja(b, Vector3(w * 0.33, 3.6, z_front + 3.4), Vector3(12.0, 0.3, 3.4), b._mat_simple(Color(0.2, 0.55, 0.45), 0.5))
	for sx: float in [-5.5, 5.5]:
		_caja(b, Vector3(w * 0.33 + sx, 1.8, z_front + 3.4), Vector3(0.25, 3.6, 0.25), acero)
	_caja(b, Vector3(w * 0.33, 0.55, z_front + 3.9), Vector3(5.0, 0.5, 0.8), b._mat_simple(Color(0.4, 0.28, 0.18), 0.8))
	_rotulo(Vector3(w * 0.33, 4.4, z_front + 3.4), "TAXIS · AUTOBUSES", 0.012)
	## Los trenes: tres coches (cabina, vagón, cabina vuelta) por vía; la segunda desfasada media vuelta.
	var z_parada := z_tope - 3.0
	z_vestibulo = z_tope + 2.0
	var z_dentro := ViaEstacion.Z_BOCA_B - 10.0     ## dentro del túnel del horizonte (la vía exterior: `ViaEstacion`)
	perfil_via = ViaEstacion.montar(self, b, beton)
	z_tunel_anden = z_h0
	var i := 0
	for sx: float in [-VIA_X, VIA_X]:
		var tren := Node3D.new()
		tren.position = Vector3(sx, Y_TREN, z_dentro)
		add_child(tren)
		var largo_tren := 0.0
		for coche in [["train-electric-city-a", 2.4, 0.0], ["train-electric-city-b", 2.7, 0.0], ["train-electric-city-a", 2.4, PI]]:
			var e := load(RUTA + String(coche[0]) + ".glb") as PackedScene
			if e == null:
				continue
			var n: Node3D = e.instantiate()
			n.scale = Vector3.ONE * S
			n.rotation.y = float(coche[2])
			n.position = Vector3(0, 0, -largo_tren - float(coche[1]) * S * 0.5)
			tren.add_child(n)
			largo_tren += float(coche[1]) * S + 0.3
		largo_del_tren = largo_tren - 0.3
		_trenes.append({"nodo": tren, "fase": float(i) * CICLO * 0.5, "z0": z_dentro, "z1": z_parada})
		i += 1
	cuenta["trenes"] = _trenes.size()
	cuenta["tramos"] = n_tramos * 2

func _rotulo(pos: Vector3, texto: String, tam: float) -> void:
	var l := Label3D.new()
	l.text = Idiomas.t(texto)   ## M-333
	l.font_size = 64
	l.pixel_size = tam
	l.outline_size = 10
	l.position = pos
	add_child(l)

## Dónde está el morro del tren `i` en el instante `t` del ciclo (y si está a la vista), con su velocidad `v` y su
## aceleración `a` a lo largo de la vía. Perfil cúbico (27-10-2026, pieza F-3): llega frenando con aceleración que se
## anula justo al parar (sin tirón de parada) y sale arrancando suave, en vez del cuadrático de antes.
func posicion_tren(i: int, t: float) -> Dictionary:
	var tr: Dictionary = _trenes[i]
	var u := fposmod(t + float(tr["fase"]), CICLO)
	var z0: float = tr["z0"]
	var z1: float = tr["z1"]
	var dz := z1 - z0
	if u < LLEGADA:
		var k := u / LLEGADA
		var r := 1.0 - k
		return {"z": z0 + dz * (1.0 - r * r * r), "visible": true, "parado": false,
			"v": dz * 3.0 * r * r / LLEGADA, "a": -dz * 6.0 * r / (LLEGADA * LLEGADA)}
	if u < LLEGADA + ESPERA:
		return {"z": z1, "visible": true, "parado": true, "v": 0.0, "a": 0.0}
	if u < LLEGADA + ESPERA + SALIDA:
		var k2 := (u - LLEGADA - ESPERA) / SALIDA
		return {"z": z1 - dz * k2 * k2 * k2, "visible": true, "parado": false,
			"v": -dz * 3.0 * k2 * k2 / SALIDA, "a": -dz * 6.0 * k2 / (SALIDA * SALIDA)}
	return {"z": z0, "visible": false, "parado": false, "v": 0.0, "a": 0.0}

## El instante del ciclo (en «segundos de juego»: 1 min de juego = 6 s) y si hay servicio (de 01:00 a 05:00, no).
## (28-10) Lo deja en `_tp_t` / `_tp_servicio` en vez de devolver un Dictionary nuevo por cuadro.
var _tp_t := 0.0
var _tp_servicio := true
func _tiempo() -> void:
	if reloj == null:
		_tp_t = _t
		_tp_servicio = true
		return
	var h := reloj.hora()
	_tp_t = float(reloj.dia * 1440 + reloj.minuto) * 6.0 + minf(_seg_min, 5.99)
	_tp_servicio = h >= 5 or h < 1

func _process(delta: float) -> void:
	_t += delta
	_seg_min += delta
	if reloj != null and reloj.minuto != _min_vista:
		_min_vista = reloj.minuto
		_seg_min = 0.0
		_reloj_rotulo.text = "%02d:%02d" % [reloj.hora(), reloj.minuto % 60]
	_tiempo()
	for i in _trenes.size():
		var p := posicion_tren(i, _tp_t)
		var n: Node3D = _trenes[i]["nodo"]
		n.visible = bool(p["visible"]) and _tp_servicio and ViaEstacion.visible_en(float(p["z"]), largo_del_tren, z_tunel_anden)
		n.position.z = float(p["z"])
		n.position.y = Y_TREN + ViaEstacion.altura(perfil_via, float(p["z"]))   ## sigue el terraplén de la vía exterior
		## La caja se inclina con la frenada y la arrancada (cabeceo) y se mece un poco al rodar (balanceo).
		var vel := absf(float(p["v"]))
		n.rotation.x = clampf(-float(p["a"]) * 0.01, -0.02, 0.02)
		n.rotation.z = sin(_t * 6.0 + float(i) * 2.0) * 0.0025 * clampf(vel / 6.0, 0.0, 1.0)
	if _gente.is_empty() and _tp_servicio and not _trenes.is_empty():
		_gente = PasajerosEstacion.crear(self)
	PasajerosEstacion.actualizar(self, _gente, _trenes, _tp_t, _tp_servicio)

