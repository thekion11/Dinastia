class_name EstacionCentral
extends Node3D
## LA ESTACIÓN CENTRAL (27-10-2026): antes una caja con bóveda. Ahora es una estación de cabecera de verdad, con el kit
## `assets/kenney/tren` (Train Kit de Kenney, escala ×2,4): vestíbulo con fachada de cristal y bóveda, andén isla con
## marquesina, dos vías con topes y un túnel cubierto por el norte por donde SALEN y ENTRAN los trenes (la vía «sale de la
## ciudad» bajo tierra: el viaducto de las líneas de metro ya ocupa el aire). Cada vía tiene su tren (tres coches) que llega,
## espera con las puertas a la vista, retrocede hacia el túnel y deja la vía vacía un rato; los dos van desfasados
## media vuelta (un ciclo = CICLO s reales ≈ 10 min de juego con el reloj vivo). Los trenes cuelgan de este nodo con script:
## `Optimizar.agrupar` no los toca.

const RUTA := "res://assets/kenney/tren/"
const S := 2.4                               ## escala del kit (vía de 1 m → 2,4 m)
const CICLO := 70.0
const LLEGADA := 14.0
const ESPERA := 30.0
const SALIDA := 14.0
const VIA_X := 8.0
const LARGO_TUNEL := 26.0

var _trenes: Array = []                      ## [{nodo, fase, z0, z1}]
var _t := 0.0
var cuenta := {}

## `c` centro del bloque (y = suelo), `w` x `f` su tamaño; `mats` = materiales de la ciudad (claro, vidrio, piedra).
static func montar(b: CityBuilder, c: Vector3, w: float, f: float, mats: Dictionary) -> EstacionCentral:
	var s := EstacionCentral.new()
	s.name = "EstacionCentral"
	s.position = c
	b.add_child(s)
	s._construir(b, w, f, mats)
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

func _construir(b: CityBuilder, w: float, f: float, mats: Dictionary) -> void:
	var z_h0 := -f * 0.5 + 2.0
	var z_h1 := z_h0 + LARGO_TUNEL               ## la boca del túnel, hacia el andén
	var z_tope := f * 0.13                        ## los topes de las vías
	var gris := b._mat_simple(Color(0.62, 0.63, 0.64), 0.8)
	var oscuro := b._mat_simple(Color(0.08, 0.08, 0.09), 0.9)
	var acero := b._mat_simple(Color(0.3, 0.32, 0.34), 0.5)
	## Vías: tramos del kit de 9,6 m desde el fondo del túnel hasta los topes.
	var n_tramos := int(ceil((z_tope - z_h0) / (4.0 * S)))
	for sx: float in [-VIA_X, VIA_X]:
		for k in n_tramos:
			_pieza("railroad-straight", Vector3(sx, 0.25, z_h0 + float(k) * 4.0 * S))
		_caja(b, Vector3(sx, 0.9, z_tope + 0.6), Vector3(2.6, 1.2, 0.8), b._mat_simple(Color(0.7, 0.15, 0.1), 0.6))   ## tope
	## El túnel cubierto: paredes, techo y fondo oscuro (los trenes salen de él y vuelven a entrar).
	var largo := LARGO_TUNEL
	for sx: float in [-13.0, 13.0]:
		_caja(b, Vector3(sx, 4.5, z_h0 + largo * 0.5), Vector3(1.2, 9.0, largo), gris)
	_caja(b, Vector3(0, 9.4, z_h0 + largo * 0.5), Vector3(27.4, 1.2, largo), gris)
	_caja(b, Vector3(0, 4.5, z_h0 - 0.4), Vector3(26.0, 9.0, 0.8), oscuro)
	_caja(b, Vector3(0, 8.4, z_h1), Vector3(27.4, 1.6, 1.0), b._mat_simple(Color(0.5, 0.55, 0.6), 0.5))   ## dintel de la boca
	_rotulo(Vector3(0, 8.4, z_h1 + 0.6), "TÚNEL · VÍAS 1-2", 0.012)
	## Andén isla con marquesina.
	var z_a0 := z_h1 + 2.0
	var largo_a := z_tope - z_a0 + 4.0
	_caja(b, Vector3(0, 0.45, z_a0 + largo_a * 0.5), Vector3(12.0, 0.9, largo_a), b._mat_simple(Color(0.72, 0.72, 0.7), 0.9))
	_caja(b, Vector3(0, 0.92, z_a0 + largo_a * 0.5), Vector3(0.3, 0.05, largo_a), b._mat_simple(Color(0.95, 0.8, 0.1), 0.6))   ## línea amarilla
	_caja(b, Vector3(0, 7.4, z_a0 + largo_a * 0.5), Vector3(15.0, 0.5, largo_a), b._mat_simple(Color(0.35, 0.45, 0.5), 0.5))
	for k in 4:
		var z := z_a0 + 3.0 + float(k) * (largo_a - 6.0) / 3.0
		for sx: float in [-5.5, 5.5]:
			_caja(b, Vector3(sx, 3.9, z), Vector3(0.4, 7.0, 0.4), acero)
		_caja(b, Vector3(0, 0.9 + 0.5, z + 2.0), Vector3(3.0, 0.5, 0.8), b._mat_simple(Color(0.4, 0.28, 0.18), 0.8))   ## banco
	_rotulo(Vector3(0, 6.6, z_a0 + 4.0), "ANDÉN 1 ◄ ► ANDÉN 2", 0.008)
	## El vestíbulo: fachada de cristal, bóveda y el nombre.
	var z_v := f * 0.30
	_caja(b, Vector3(0, 6.5, z_v), Vector3(w * 0.85, 13.0, f * 0.3), mats["claro"])
	b._boveda(position + Vector3(0, 13.0, z_v), w * 0.85, f * 0.3, b._mat_simple(Color(0.5, 0.62, 0.7), 0.3), 0.3)
	_caja(b, Vector3(0, 5.0, z_v + f * 0.15 + 0.1), Vector3(w * 0.6, 7.0, 0.2), mats["vidrio"])
	_rotulo(Vector3(0, 11.0, z_v + f * 0.15 + 0.5), "ESTACIÓN CENTRAL", 0.035)
	## Los trenes: tres coches (cabina, vagón, cabina vuelta) por vía; la segunda desfasada media vuelta.
	var z_parada := z_tope - 3.0
	var z_dentro := z_h0 + 20.0
	var i := 0
	for sx: float in [-VIA_X, VIA_X]:
		var tren := Node3D.new()
		tren.position = Vector3(sx, 0.25 + 0.36 * S, z_dentro)
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
		_trenes.append({"nodo": tren, "fase": float(i) * CICLO * 0.5, "z0": z_dentro, "z1": z_parada})
		i += 1
	cuenta["trenes"] = _trenes.size()
	cuenta["tramos"] = n_tramos * 2

func _rotulo(pos: Vector3, texto: String, tam: float) -> void:
	var l := Label3D.new()
	l.text = texto
	l.font_size = 64
	l.pixel_size = tam
	l.outline_size = 10
	l.position = pos
	add_child(l)

## Dónde está el morro del tren `i` en el instante `t` del ciclo (y si está a la vista).
func posicion_tren(i: int, t: float) -> Dictionary:
	var tr: Dictionary = _trenes[i]
	var u := fposmod(t + float(tr["fase"]), CICLO)
	var z0: float = tr["z0"]
	var z1: float = tr["z1"]
	if u < LLEGADA:
		var k := u / LLEGADA
		return {"z": lerpf(z0, z1, 1.0 - (1.0 - k) * (1.0 - k)), "visible": true, "parado": false}
	if u < LLEGADA + ESPERA:
		return {"z": z1, "visible": true, "parado": true}
	if u < LLEGADA + ESPERA + SALIDA:
		var k2 := (u - LLEGADA - ESPERA) / SALIDA
		return {"z": lerpf(z1, z0, k2 * k2), "visible": true, "parado": false}
	return {"z": z0, "visible": false, "parado": false}

func _process(delta: float) -> void:
	_t += delta
	for i in _trenes.size():
		var p := posicion_tren(i, _t)
		var n: Node3D = _trenes[i]["nodo"]
		n.visible = bool(p["visible"])
		n.position.z = float(p["z"])
