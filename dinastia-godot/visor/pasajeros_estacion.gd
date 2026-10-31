class_name PasajerosEstacion
extends RefCounted
## PASAJEROS DE LA ESTACIÓN CENTRAL (27-10-2026, pieza F-3b: «pasajeros que suben y bajan»). Cuatro por tren (8 en total, con
## `Mini3D.persona`/`PeatonQ`): dos se BAJAN por las puertas cuando el tren para y caminan por el andén hacia el vestíbulo;
## dos SUBEN: salen del vestíbulo a tiempo de llegar a la puerta cuando el tren acaba de parar y desaparecen dentro. Todo
## sale del instante `u` del ciclo del tren (función pura, sin estado ni azar): las posiciones se pueden comprobar sin dibujar.
const VEL := 1.4                  ## m/s
const CARRIL := 3.4               ## |x| del pasillo por el andén
const BORDE := 5.8                ## |x| donde se sube y se baja (borde del andén; el tren queda a 8)
const PUERTAS := [-3.0, -9.3, -15.7]   ## z de cada puerta respecto al morro del tren parado (centros de los tres coches)
const ALTO_ANDEN := 0.9
## Quién hace qué: [puerta, baja?, retraso en s desde que el tren para].
const PLAN := [[0, true, 2.5], [2, true, 5.0], [1, false, 7.0], [2, false, 11.0]]

## Camino de cada pasajero en coordenadas locales de la estación: de la puerta al vestíbulo o al revés.
static func camino(sx: float, z_puerta: float, z_fin: float, baja: bool) -> PackedVector3Array:
	var lado := signf(sx)
	var p := PackedVector3Array([Vector3(lado * BORDE, ALTO_ANDEN, z_puerta), Vector3(lado * CARRIL, ALTO_ANDEN, z_puerta),
		Vector3(lado * CARRIL, ALTO_ANDEN, z_fin)])
	if not baja:
		p.reverse()
	return p

static func largo(c: PackedVector3Array) -> float:
	var s := 0.0
	for i in c.size() - 1:
		s += c[i].distance_to(c[i + 1])
	return s

## Punto y rumbo a `d` metros del principio del camino.
static func en(c: PackedVector3Array, d: float) -> Dictionary:
	var resto := d
	for i in c.size() - 1:
		var l := c[i].distance_to(c[i + 1])
		if resto <= l or i == c.size() - 2:
			var f := clampf(resto / maxf(l, 0.001), 0.0, 1.0)
			var dir := (c[i + 1] - c[i]) / maxf(l, 0.001)
			return {"p": c[i].lerp(c[i + 1], f), "rumbo": atan2(dir.x, dir.z)}
		resto -= l
	return {"p": c[c.size() - 1], "rumbo": 0.0}

## Estado del pasajero `k` del plan para un tren que está a `u` segundos de su ciclo: {visible, p (local), rumbo}.
## `z_morro` es el z del morro del tren PARADO, `z_fin` el del vestíbulo.
static func estado(k: int, sx: float, z_morro: float, z_fin: float, u: float) -> Dictionary:
	var e: Array = PLAN[k]
	var c := camino(sx, z_morro + float(PUERTAS[int(e[0])]), z_fin, bool(e[1]))
	var dur := largo(c) / VEL
	var llega := EstacionCentral.LLEGADA + float(e[2])      ## el que baja sale entonces; el que sube LLEGA a la puerta entonces
	var inicio := llega if bool(e[1]) else llega - dur
	var t := fposmod(u - inicio, EstacionCentral.CICLO)
	if t >= dur:
		return {"visible": false, "p": c[0], "rumbo": 0.0}
	var r := en(c, t * VEL)
	return {"visible": true, "p": r["p"], "rumbo": r["rumbo"]}

## Crea los 8 pasajeros colgando de `est` (ocultos). Devuelve [{nodo, tren, k}].
static func crear(est: Node3D) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2710
	var gente: Array = []
	for i in 2:
		for k in PLAN.size():
			var d := Mini3D.persona(est, rng, Vector3.ZERO)
			if d.is_empty():
				continue
			var n: Node3D = d["nodo"]
			n.visible = false
			Mini3D.anim(d, "caminar")
			gente.append({"nodo": n, "tren": i, "k": k})
	return gente

## Pone a cada pasajero donde toca. `servicio`: con el tren fuera de servicio no hay nadie.
static func actualizar(est: Node3D, gente: Array, trenes: Array, t: float, servicio: bool) -> void:
	for g: Dictionary in gente:
		var tr: Dictionary = trenes[int(g["tren"])]
		var n: Node3D = g["nodo"]
		if not servicio:
			n.visible = false
			continue
		var u := fposmod(t + float(tr["fase"]), EstacionCentral.CICLO)
		var sx: float = (tr["nodo"] as Node3D).position.x
		var e := estado(int(g["k"]), sx, float(tr["z1"]), float(est.get("z_vestibulo")), u)
		n.visible = bool(e["visible"])
		if n.visible:
			n.position = e["p"]
			n.rotation.y = float(e["rumbo"])
