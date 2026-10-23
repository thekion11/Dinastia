extends "res://ui/componentes/interior_instalacion_p5.gd"
## [Capa 6/7 de `interior_instalacion.gd`] _piscina, _vivienda, _bar, _panaderia

## Piscina de recuperación (22 × 14 m, 5,5 m de alto; 16-10-2026: «a la altura
## del gimnasio»). El vaso de 14 × 7 m con fondo de gresite, calles pintadas,
## corcheras de flotadores, rebosadero con su rejilla, poyetes de salida y
## banderines de espalda. En el agua: dos corriendo por la calle (aquajogging),
## uno flotando boca arriba con su churro, otro con ejercicios de brazos y otro
## agarrado al borde con el fisio agachado al lado. A la derecha el jacuzzi con
## burbujas, las bañeras de hielo y la sauna acristalada; a la izquierda las
## duchas, el toallero y la fuente; delante las tumbonas, la silla del
## socorrista, el material (churros, tablas, pull-buoys) y la nevera. En las
## paredes, azulejo con la franja del club, el reloj, la pantalla de la sesión
## y el salvavidas. Casi todo en lotes (`_prim`, `_poner`).
func _piscina() -> void:
	_sala(Vector3(22, 5.5, 14), Color(0.86, 0.89, 0.9), Color(0.82, 0.9, 0.93), "losa", Color(0.32, 0.58, 0.72))
	var dep := [_c1, _c2]
	var bata := [Color(0.95, 0.95, 0.97), Color(0.14, 0.18, 0.32), true]
	var acero := Color(0.7, 0.72, 0.75)
	var cromo := Color(0.86, 0.87, 0.89)
	var blanco := Color(0.95, 0.95, 0.96)
	var gresite := Color(0.28, 0.6, 0.8)
	var madera := Color(0.74, 0.52, 0.32)
	## --- El vaso: fondo de gresite con su cuadrícula y las calles pintadas.
	var c := Vector3(-1.5, 0, -1.8)
	var largo := 14.0
	var ancho := 7.0
	var hx := largo * 0.5
	var hz := ancho * 0.5
	_prim("caja", c + Vector3(0, 0.003, 0), Vector3(largo, 0.006, ancho), gresite)
	for i in 15:
		_prim("caja", c + Vector3(-hx + float(i), 0.007, 0), Vector3(0.025, 0.002, ancho), gresite.lightened(0.22))
	for j in 8:
		_prim("caja", c + Vector3(0, 0.007, -hz + float(j)), Vector3(largo, 0.002, 0.025), gresite.lightened(0.22))
	var calles: Array[float] = []
	for i in 4:
		var zl := c.z - hz + 0.875 + float(i) * 1.75
		calles.append(zl)
		_prim("caja", Vector3(c.x, 0.01, zl), Vector3(largo - 2.0, 0.003, 0.25), Color(0.08, 0.16, 0.35))
		for s: float in [-1.0, 1.0]:
			_prim("caja", Vector3(c.x + s * (hx - 1.0), 0.01, zl), Vector3(0.25, 0.003, 1.0), Color(0.08, 0.16, 0.35))
	var agua := Mini3D.caja(_raiz, c + Vector3(0, 0.03, 0), Vector3(largo, 0.04, ancho), Mini3D.mat(Color(0.3, 0.68, 0.86, 0.5), 0.03, 0.12))
	agua.name = "Agua"
	## Rebosadero (rejilla oscura con sus lamas) y el borde blanco alrededor.
	var rejilla := Color(0.32, 0.38, 0.42)
	for s: float in [-1.0, 1.0]:
		_prim("caja", c + Vector3(0, 0.05, s * (hz + 0.09)), Vector3(largo + 0.36, 0.1, 0.18), rejilla)
		_prim("caja", c + Vector3(s * (hx + 0.09), 0.05, 0), Vector3(0.18, 0.1, ancho), rejilla)
		_prim("caja", c + Vector3(0, 0.06, s * (hz + 0.43)), Vector3(largo + 1.36, 0.12, 0.5), blanco)
		_prim("caja", c + Vector3(s * (hx + 0.43), 0.06, 0), Vector3(0.5, 0.12, ancho + 0.36), blanco)
		for i in int((largo + 0.36) / 0.12):
			_prim("caja", c + Vector3(-hx - 0.12 + float(i) * 0.12, 0.102, s * (hz + 0.09)), Vector3(0.03, 0.004, 0.15), Color(0.85, 0.88, 0.9))
		for j in int(ancho / 0.12):
			_prim("caja", c + Vector3(s * (hx + 0.09), 0.102, -hz + 0.06 + float(j) * 0.12), Vector3(0.15, 0.004, 0.03), Color(0.85, 0.88, 0.9))
	## Profundidad pintada en el borde.
	for k in 3:
		var x := c.x - hx + 2.0 + float(k) * 5.0
		var l := _texto(String(["1,20 m", "1,60 m", "2,00 m"][k]), Vector3(x, 0.125, c.z + hz + 0.43), 26, Color(0.1, 0.2, 0.45), 0.0, false)
		l.rotation.x = -PI * 0.5
	## Corcheras: flotadores rojos en los 5 m de cada extremo, azules y blancos
	## en medio.
	for i in 3:
		var zb := c.z - hz + 1.75 * float(i + 1)
		var n := int((largo - 0.2) / 0.14)
		for k in n:
			var x := c.x - hx + 0.1 + float(k) * 0.14
			var cerca := absf(x - c.x) > hx - 5.0
			var col := Color(0.85, 0.15, 0.12) if cerca else (Color(0.15, 0.35, 0.8) if k % 2 == 0 else blanco)
			_prim("cil", Vector3(x, 0.055, zb), Vector3(0.1, 0.12, 0.1), col, "goma", Vector3(0, 0, PI * 0.5))
	## Banderines de espalda a 5 m de cada pared.
	for s: float in [-1.0, 1.0]:
		var x := c.x + s * (hx - 5.0)
		for t: float in [-1.0, 1.0]:
			_prim("cil", Vector3(x, 0.95, c.z + t * (hz + 0.55)), Vector3(0.05, 1.9, 0.05), acero, "metal")
		_prim("caja", Vector3(x, 1.82, c.z), Vector3(0.015, 0.015, ancho + 1.1), Color(0.2, 0.2, 0.22))
		for k in int(ancho / 0.35):
			_prim("caja", Vector3(x, 1.73, c.z - hz + 0.2 + float(k) * 0.35), Vector3(0.004, 0.16, 0.13), [Color(0.85, 0.15, 0.12), blanco, Color(0.15, 0.35, 0.8)][k % 3])
	## Poyetes de salida (lado izquierdo), con su número.
	for i in 4:
		var p := Vector3(c.x - hx - 0.45, 0, calles[i])
		_prim("caja", p + Vector3(0, 0.3, 0), Vector3(0.45, 0.6, 0.5), Color(0.2, 0.22, 0.26))
		_prim("caja", p + Vector3(0.04, 0.64, 0), Vector3(0.6, 0.05, 0.55), blanco, "goma", Vector3(0, 0, -0.12))
		_prim("caja", p + Vector3(-0.2, 0.75, 0), Vector3(0.04, 0.04, 0.45), cromo, "metal")
		_texto(str(i + 1), p + Vector3(-0.232, 0.32, 0), 40, blanco, -PI * 0.5, false)
	## Escalerillas en el extremo derecho, a los dos lados.
	for s: float in [-1.0, 1.0]:
		var z := c.z + s * (hz + 0.12)
		for dx: float in [-0.25, 0.25]:
			var x := c.x + hx - 1.3 + dx
			_prim("cil", Vector3(x, 0.5, z + s * 0.1), Vector3(0.045, 1.0, 0.045), cromo, "metal")
			_prim("cil", Vector3(x, 1.0, z - s * 0.12), Vector3(0.045, 0.45, 0.045), cromo, "metal", Vector3(PI * 0.5, 0, 0))
			_prim("cil", Vector3(x, 0.5, z - s * 0.34), Vector3(0.045, 1.0, 0.045), cromo, "metal")
	## --- Paredes: franja del club, rótulos, reloj, pantalla y salvavidas.
	_prim("caja", Vector3(0, 3.0, -6.99), Vector3(22, 0.22, 0.02), _c1)
	for s: float in [-1.0, 1.0]:
		_prim("caja", Vector3(s * 10.99, 3.0, 0), Vector3(0.02, 0.22, 14), _c1)
	_cartel("🏊 " + _sala_nombre().to_upper(), Vector3(-1.5, 4.2, -6.95), 44)
	_cartel("AGUA · CALMA · RECUPERACIÓN", Vector3(-10.96, 3.6, 0.6), 30, _c1.lightened(0.25), PI * 0.5)
	_reloj(Transform3D(Basis.IDENTITY, Vector3(-6.0, 2.35, -6.97)), 0.5, 10.75)
	_prim("cil", Vector3(-6.0, 2.35, -6.985), Vector3(1.12, 0.03, 1.12), Color(0.2, 0.2, 0.22), "metal", Vector3(PI * 0.5, 0, 0))
	_pantalla(Vector3(4.2, 2.3, -6.95), Vector2(2.4, 1.3), Color(0.06, 0.18, 0.28))
	_texto("SESIÓN DE RECUPERACIÓN\nAgua  30 °C   ·   Jacuzzi  37 °C\nHielo  10 °C   ·   Sauna  80 °C\nAquajogging 20'  ·  Estiramientos 15'", Vector3(4.2, 2.3, -6.89), 17, Color(0.6, 1.0, 0.8), 0.0, false)
	var aro := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.24
	tm.outer_radius = 0.38
	tm.rings = 20
	tm.ring_segments = 10
	aro.mesh = tm
	aro.material_override = Mini3D.mat(Color(0.95, 0.4, 0.1), 0.6)
	aro.position = Vector3(-9.6, 1.75, -6.9)
	aro.rotation.x = PI * 0.5
	_raiz.add_child(aro)
	for k in 4:
		var a := float(k) * PI * 0.5 + PI * 0.25
		_prim("caja", Vector3(-9.6 + cos(a) * 0.31, 1.75 + sin(a) * 0.31, -6.84), Vector3(0.16, 0.08, 0.05), blanco, "mate", Vector3(0, 0, a + PI * 0.5))
	_prim("caja", Vector3(-8.5, 1.55, -6.95), Vector3(0.45, 0.4, 0.1), blanco)
	_prim("caja", Vector3(-8.5, 1.55, -6.895), Vector3(0.18, 0.05, 0.01), Color(0.8, 0.12, 0.12))
	_prim("caja", Vector3(-8.5, 1.55, -6.895), Vector3(0.05, 0.18, 0.01), Color(0.8, 0.12, 0.12))
	_ventana(-1.0, -4.4, 3.0, false)
	_ventana(1.0, -4.4, 3.0, false)
	## --- La gente en el agua (el suelo tapa lo que queda bajo la superficie).
	for i: int in [0, 2]:
		var a := Vector3(c.x - hx + 1.3, -0.95, calles[i])
		var b := Vector3(c.x + hx - 1.3, -0.95, calles[i])
		_caminante([a, b], dep)
		if not _caminantes.is_empty():
			var cm: Dictionary = _caminantes[-1]
			cm["puntos"] = [a, b]
			cm["i"] = 1 if i == 0 else 0
			cm["vel"] = 0.55
			(cm["d"]["nodo"] as Node3D).position = a.lerp(b, 0.3 if i == 0 else 0.65)
	_tumbado(Vector3(c.x + 1.2, -0.13, calles[1]), PI * 0.5, dep)
	_prim("cil", Vector3(c.x + 2.05, 0.05, calles[1]), Vector3(0.1, 1.5, 0.1), Color(1.0, 0.55, 0.1), "goma", Vector3(PI * 0.5, 0, 0))
	_trabajador(Vector3(c.x - 1.2, -0.95, calles[3] - 0.2), 0.0, false, ["brazos_al_frente", "charla", "brazos_al_frente", "pedir_calma"], dep)
	_trabajador(Vector3(c.x - 4.6, -0.95, c.z + hz - 0.35), 0.0, false, ["parado", "charla", "cansado"], dep)
	_trabajador(Vector3(c.x - 4.6, 0.12, c.z + hz + 0.55), PI, false, ["agachado"], bata)
	if not _fijos.is_empty():
		_fijos[-1]["base"] = "agachado"
		Mini3D.anim(_fijos[-1]["d"], "agachado", "")
	_prim("caja", Vector3(c.x - 3.9, 0.07, c.z + hz - 0.6), Vector3(0.45, 0.04, 0.3), Color(0.98, 0.8, 0.15), "goma")
	## En el borde: el preparador y el socorrista en su silla alta.
	_trabajador(Vector3(c.x + 2.6, 0, c.z + hz + 1.1), PI, false, ["senalar_adelante", "aplaudir", "charla", "brazos_jarra"], [_c1.darkened(0.5), Color(0.12, 0.12, 0.15), true])
	var silla := Vector3(c.x + 5.6, 0, c.z + hz + 1.15)
	for dx: float in [-0.28, 0.28]:
		for dz: float in [-0.22, 0.22]:
			_prim("cil", silla + Vector3(dx, 0.75, dz), Vector3(0.05, 1.5, 0.05), blanco, "metal")
		for y: float in [0.35, 0.75, 1.1]:
			_prim("caja", silla + Vector3(dx, y, 0.22), Vector3(0.04, 0.04, 0.04), blanco)
	for y: float in [0.35, 0.75, 1.1]:
		_prim("caja", silla + Vector3(0, y, 0.24), Vector3(0.6, 0.035, 0.08), blanco)
	_prim("caja", silla + Vector3(0, 1.5, 0), Vector3(0.66, 0.06, 0.56), Color(0.85, 0.15, 0.12))
	_prim("caja", silla + Vector3(0, 1.85, 0.27), Vector3(0.66, 0.5, 0.05), Color(0.85, 0.15, 0.12))
	_prim("caja", silla + Vector3(0, 0.95, -0.3), Vector3(0.5, 0.04, 0.2), blanco)
	_trabajador(silla + Vector3(0, 0, 0.04), PI, true, [], [Color(0.85, 0.12, 0.12), Color(0.95, 0.85, 0.2)], 1.53)
	## --- Jacuzzi: vaso redondo elevado, agua con burbujas y dos dentro.
	var jc := Vector3(8.7, 0, -4.4)
	_prim("cil", jc + Vector3(0, 0.275, 0), Vector3(3.0, 0.55, 3.0), Color(0.9, 0.93, 0.95))
	_prim("cil", jc + Vector3(0, 0.552, 0), Vector3(2.66, 0.004, 2.66), gresite)
	_prim("cil", jc + Vector3(0, 0.3, 1.6), Vector3(0.9, 0.04, 0.5), Color(0.8, 0.84, 0.86))
	for k in 3:
		_prim("caja", jc + Vector3(-0.9 + float(k) * 0.9, 0.555, 1.38), Vector3(0.05, 0.02, 0.05), Color(0.6, 0.9, 1.0), "luz")
	var agua_j := Mini3D.cilindro(_raiz, jc + Vector3(0, 0.565, 0), 1.33, 0.02, Mini3D.mat(Color(0.45, 0.8, 0.92, 0.55), 0.03, 0.25))
	agua_j.name = "AguaJacuzzi"
	for k in 26:
		var a := _rng.randf() * TAU
		var r := sqrt(_rng.randf()) * 1.2
		_prim("esf", jc + Vector3(cos(a) * r, 0.58, sin(a) * r), Vector3.ONE * _rng.randf_range(0.04, 0.1), Color(0.95, 0.98, 1.0), "luz")
	for a: float in [PI * 0.75, -PI * 0.2]:
		var dir := Vector3(sin(a), 0, cos(a))
		_trabajador(jc + dir * 0.95, atan2(-dir.x, -dir.z), true, [], dep, 0.2)
	_cartel("HIDROMASAJE 37 °C", Vector3(8.7, 2.3, -6.95), 26, Color(0.9, 0.97, 1.0))
	## --- Bañeras de hielo (crioterapia), una ocupada, y el fisio con el crono.
	for k in 2:
		var p := Vector3(7.9 + float(k) * 1.5, 0, -1.0)
		_prim("caja", p + Vector3(0, 0.35, 0), Vector3(0.95, 0.7, 1.8), acero, "metal")
		_prim("caja", p + Vector3(0, 0.705, 0), Vector3(0.83, 0.01, 1.68), Color(0.72, 0.9, 0.97), "luz")
		for q in 9:
			_prim("caja", p + Vector3(_rng.randf_range(-0.33, 0.33), 0.72, _rng.randf_range(-0.7, 0.7)), Vector3.ONE * 0.07, Color(0.88, 0.96, 1.0), "luz", Vector3(0, _rng.randf() * TAU, 0))
		_prim("caja", p + Vector3(0, 0.74, -0.86), Vector3(0.95, 0.08, 0.08), acero.darkened(0.2), "metal")
	_trabajador(Vector3(7.9, 0, -1.45), 0.0, true, [], dep, 0.25)
	_trabajador(Vector3(8.65, 0, 0.55), PI * 0.85, false, ["charla", "senalar_adelante", "brazos_jarra"], bata)
	_texto("CRIOTERAPIA 10 °C", Vector3(10.96, 2.2, -1.0), 24, Color(0.75, 0.92, 1.0), -PI * 0.5)
	## --- Sauna acristalada, contra la pared derecha.
	var x0 := 8.8
	for z: float in [2.0, 5.0]:
		_prim("caja", Vector3(9.9, 1.15, z), Vector3(2.2, 2.3, 0.08), madera)
		for k in 15:
			_prim("caja", Vector3(9.9, 0.1 + float(k) * 0.15, z + (0.045 if z > 3.0 else -0.045)), Vector3(2.2, 0.01, 0.01), madera.darkened(0.25))
	_prim("caja", Vector3(9.9, 2.33, 2.0), Vector3(2.2, 0.08, 0.12), madera.darkened(0.15))
	_prim("caja", Vector3(9.9, 2.33, 5.0), Vector3(2.2, 0.08, 0.12), madera.darkened(0.15))
	_prim("caja", Vector3(x0, 2.33, 3.5), Vector3(0.12, 0.08, 3.0), madera.darkened(0.15))
	for z: float in [2.0, 2.85, 5.0]:
		_prim("caja", Vector3(x0, 1.15, z), Vector3(0.1, 2.3, 0.1), madera.darkened(0.2))
	Mini3D.caja(_raiz, Vector3(x0, 1.15, 3.92), Vector3(0.02, 2.2, 2.1), Mini3D.mat(Color(0.75, 0.6, 0.4, 0.3), 0.05))
	Mini3D.caja(_raiz, Vector3(x0, 1.05, 2.43), Vector3(0.03, 2.0, 0.8), Mini3D.mat(Color(0.75, 0.6, 0.4, 0.35), 0.05))
	_prim("caja", Vector3(x0 - 0.04, 1.05, 2.75), Vector3(0.04, 0.3, 0.03), cromo, "metal")
	for g: Array in [[10.6, 0.9, 0.5], [10.05, 0.45, 0.55]]:
		_prim("caja", Vector3(float(g[0]), float(g[1]) * 0.5, 3.5), Vector3(float(g[2]), float(g[1]), 2.9), madera)
		for k in 4:
			_prim("caja", Vector3(float(g[0]), float(g[1]) + 0.005, 2.2 + float(k) * 0.85), Vector3(float(g[2]), 0.01, 0.02), madera.darkened(0.3))
	_prim("caja", Vector3(9.3, 0.35, 4.55), Vector3(0.5, 0.7, 0.5), Color(0.2, 0.2, 0.22), "metal")
	for k in 9:
		_prim("esf", Vector3(9.3 + _rng.randf_range(-0.16, 0.16), 0.75, 4.55 + _rng.randf_range(-0.16, 0.16)), Vector3.ONE * 0.11, Color(0.4, 0.38, 0.36))
	_prim("cil", Vector3(9.75, 0.13, 4.6), Vector3(0.25, 0.26, 0.25), madera.darkened(0.35))
	_prim("caja", Vector3(10.94, 1.9, 3.5), Vector3(0.04, 0.12, 0.4), Color(1.0, 0.75, 0.4), "luz")
	_trabajador(Vector3(10.55, 0, 3.9), -PI * 0.5, true, [], dep, 0.9)
	_trabajador(Vector3(10.0, 0, 2.7), -PI * 0.5, true, [], dep, 0.45)
	_texto("SAUNA  80 °C", Vector3(x0 - 0.06, 2.45, 3.5), 26, Color(1.0, 0.85, 0.6), -PI * 0.5)
	## --- Duchas en la pared izquierda (mamparas, platos y una abierta).
	for k in 3:
		var z := -0.6 + float(k) * 1.2
		_prim("caja", Vector3(-10.5, 0.004, z), Vector3(0.95, 0.008, 1.1), Color(0.55, 0.6, 0.64))
		_prim("cil", Vector3(-10.5, 0.01, z), Vector3(0.1, 0.005, 0.1), Color(0.2, 0.2, 0.22), "metal")
		_prim("cil", Vector3(-10.93, 1.15, z), Vector3(0.05, 2.3, 0.05), cromo, "metal")
		_prim("caja", Vector3(-10.75, 2.25, z), Vector3(0.36, 0.035, 0.035), cromo, "metal")
		_prim("cono", Vector3(-10.56, 2.18, z), Vector3(0.18, 0.1, 0.18), cromo, "metal")
		_prim("cil", Vector3(-10.92, 1.05, z + 0.12), Vector3(0.07, 0.06, 0.07), cromo, "metal", Vector3(0, 0, PI * 0.5))
	for k in 4:
		Mini3D.caja(_raiz, Vector3(-10.5, 1.0, -1.2 + float(k) * 1.2), Vector3(0.95, 2.0, 0.02), Mini3D.mat(Color(0.85, 0.93, 1.0, 0.25), 0.05))
	var chorro := Mini3D.cilindro(_raiz, Vector3(-10.56, 1.15, 0.6), 0.09, 2.0, Mini3D.mat(Color(0.8, 0.92, 1.0, 0.3), 0.05, 0.3), 0.04)
	chorro.name = "Chorro"
	_trabajador(Vector3(-10.45, 0, 0.6), -PI * 0.5, false, ["parado", "cansado", "parado"], dep)
	_toallero(Vector3(-10.62, 0, 4.6))
	_fuente_agua(Vector3(-10.72, 0, 6.0), acero, cromo)
	## --- Delante: tumbonas con sus toallas, mesitas y bebidas.
	for k in 4:
		var x := -8.6 + float(k) * 1.6
		_asiento("loungeChairRelax", Vector3(x, 0, 5.1), PI, [0.0] if k % 2 == 1 else [], dep, null, {"carpet": Color(0.95, 0.95, 0.95), "wood": Color(0.7, 0.72, 0.75)})
		if k % 2 == 0:
			_prim("caja", Vector3(x, 0.42, 5.4), Vector3(0.5, 0.03, 0.9), _c1 if k == 0 else blanco)
		if k < 3:
			_prim("cil", Vector3(x + 0.8, 0.22, 5.6), Vector3(0.36, 0.44, 0.36), blanco)
			_poner("comida/glass", Vector3(x + 0.8, 0.44, 5.6), 0.0)
	## Material: churros, tablas, pull-buoys, la nevera y una planta.
	_prim("caja", Vector3(4.6, 0.04, 6.4), Vector3(1.3, 0.08, 0.4), acero, "metal")
	for k in 9:
		_prim("cil", Vector3(4.05 + float(k) * 0.135, 0.8, 6.4), Vector3(0.09, 1.5, 0.09), [Color(1.0, 0.55, 0.1), Color(0.2, 0.6, 0.95), Color(0.95, 0.2, 0.5), Color(0.3, 0.85, 0.4)][k % 4], "goma")
	for k in 10:
		_prim("caja", Vector3(5.9, 0.02 + float(k) * 0.035, 6.35), Vector3(0.45, 0.03, 0.3), [Color(0.2, 0.45, 0.9), Color(0.98, 0.8, 0.15)][k % 2], "goma", Vector3(0, float(k % 3) * 0.06, 0))
	_prim("cil", Vector3(6.75, 0.22, 6.3), Vector3(0.5, 0.44, 0.5), Color(0.3, 0.32, 0.35))
	for k in 6:
		_prim("caja", Vector3(6.75 + _rng.randf_range(-0.12, 0.12), 0.48, 6.3 + _rng.randf_range(-0.12, 0.12)), Vector3(0.1, 0.08, 0.18), [_c1, Color(0.2, 0.45, 0.9)][k % 2], "goma", Vector3(0, _rng.randf() * TAU, 0))
	_poner("kitchenFridgeSmall", Vector3(10.65, 0, 6.2), -PI * 0.5)
	_planta(Vector3(7.8, 0, 6.5))
	_planta(Vector3(-10.4, 0, -6.4))
	## Uno que vuelve de nadar por el borde de delante.
	var ida := Vector3(-7.6, 0, 3.55)
	var vuelta := Vector3(6.4, 0, 3.55)
	_caminante([ida, vuelta], dep)
	if not _caminantes.is_empty():
		_caminantes[-1]["puntos"] = [ida, vuelta]
		(_caminantes[-1]["d"]["nodo"] as Node3D).position = ida.lerp(vuelta, 0.35)

## Vivienda (12 × 9 m, techo de 3 m): salón con sofá, tele y alfombra; cocina
## al fondo; mesa de comer; y la familia que vive allí.
func _vivienda() -> void:
	_tonos_sala = _MADERA_CLARA
	_sala(Vector3(12, 3.0, 9), Color(0.7, 0.5, 0.34), Color(0.93, 0.89, 0.82), "parquet")
	var tela: Color = _TELAS[_rng.randi() % _TELAS.size()]
	## Salón.
	_poner("quaternius/alfombra", Vector3(-3.2, 0, -2.3), PI * 0.5)
	_poner("cabinetTelevision", Vector3(-3.2, 0, -4.25))
	_poner("televisionModern", Vector3(-3.2, _alto("cabinetTelevision"), -4.3))
	_poner("speakerSmall", Vector3(-4.4, 0, -4.35))
	_poner("speakerSmall", Vector3(-2.0, 0, -4.35))
	_poner("tableCoffee", Vector3(-3.2, 0, -2.4))
	_poner("books", Vector3(-3.0, _alto("tableCoffee"), -2.4), 0.3)
	_poner("plantSmall2", Vector3(-3.5, _alto("tableCoffee"), -2.35))
	_asiento("loungeSofa", Vector3(-3.2, 0, -0.85), PI, [-0.45], _calle(), null, {"carpet": tela})
	_poner("pillowBlue", Vector3(-2.5, 0.46, -0.75), PI)
	_asiento("loungeChair", Vector3(-5.1, 0, -2.4), PI * 0.5, [], [], null, {"carpet": tela.darkened(0.2)})
	_poner("lampRoundFloor", Vector3(-5.5, 0, -3.9))
	for z: float in [0.1, 0.92]:
		_poner("bookcaseOpen", Vector3(-5.74, 0, z), PI * 0.5)
		for k in 3:
			_poner("books", Vector3(-5.74, 0.42 + float(k) * 0.5, z + _rng.randf_range(-0.15, 0.15)), PI * 0.5)
	_planta(Vector3(-5.4, 0, 2.2))
	_ventana(-1.0, -2.4)
	_cuadro(Vector3(-3.2, 2.05, -4.47), Vector2(1.2, 0.6), Color.from_hsv(_rng.randf(), 0.35, 0.75))
	## Cocina al fondo a la derecha.
	var zc := -4.5 + 0.45
	var fin := _cocina(0.62, zc, ["kitchenCabinetDrawer", "kitchenSink", "kitchenCabinet", "kitchenStove", "kitchenCabinet"])
	_poner("kitchenFridgeLarge", Vector3(fin + 0.53, 0, -4.5 + 0.42))
	var encimera := _alto("kitchenCabinet")
	_poner("kitchenCoffeeMachine", Vector3(1.05, encimera, zc - 0.1))
	_poner("toaster", Vector3(2.9, encimera, zc - 0.1))
	_poner("comida/pot", Vector3(3.5, _alto("kitchenStove"), zc))
	_poner("comida/cutting-board", Vector3(4.4, encimera, zc + 0.05), PI * 0.5)
	_trabajador(Vector3(3.3, 0, -3.05), PI, false, ["charla", "brazos_jarra"], [Color(0.9, 0.85, 0.7), Color(0.3, 0.3, 0.35), true])
	## Comedor.
	_mesa_con_sillas(Vector3(3.3, 0, -0.6), 0.0, "table", 2.2, 2, "chairCushion", 0.4, _calle(), "comida/plate", ["comida/glass"])
	_poner("comida/cake", Vector3(3.3, _alto("table", 2.2), -0.6))
	_ventana(1.0, 0.6)
	## Entrada.
	_poner("coatRackStanding", Vector3(2.5, 0, 4.15))
	_planta(Vector3(5.5, 0, 4.0))
	_poner("trashcan", Vector3(5.6, 0, -2.9), 0.0, 1.4)
	_caminante([Vector3(-4.4, 0, 1.6), Vector3(4.4, 0, 1.6), Vector3(4.4, 0, 2.9), Vector3(-4.4, 0, 2.9)])
	_cartel("🏠 " + _sala_nombre().to_upper(), Vector3(-0.4, 2.62, -4.45), 26)

## Bar (14 × 10 m): barra con taburetes, botellero, mesas, tragaperras y tele
## con el fútbol; el camarero y los clientes.
func _bar() -> void:
	_tonos_sala = _MADERA_OSCURA
	_sala(Vector3(14, 3.4, 10), Color(0.46, 0.32, 0.22), Color(0.82, 0.62, 0.45), "parquet", Color(0.36, 0.22, 0.14))
	## La barra (piezas de barra de cocina a ×2,5: 1,05 m de alto).
	var zb := -2.4
	var esc_barra := 2.5
	var ancho := _medida("kitchenBar", esc_barra).x
	var xs: Array = []
	for k in 6:
		xs.append(-5.6 + float(k) * ancho)
		_poner("kitchenBar", Vector3(float(xs[k]), 0, zb), 0.0, esc_barra)
	_poner("kitchenBarEnd", Vector3(-5.6 - ancho * 0.5 - _medida("kitchenBarEnd", esc_barra).x * 0.5, 0, zb), 0.0, esc_barra)
	_poner("kitchenBarEnd", Vector3(float(xs[5]) + ancho * 0.5 + _medida("kitchenBarEnd", esc_barra).x * 0.5, 0, zb), PI, esc_barra)
	var tope := _alto("kitchenBar", esc_barra)
	## Grifos de cerveza, vasos y servilleteros sobre la barra.
	var metal := Mini3D.mat(Color(0.85, 0.85, 0.88), 0.2)
	metal.metallic = 0.9
	for k in 3:
		Mini3D.cilindro(_raiz, Vector3(-3.0 + float(k) * 0.25, tope + 0.2, zb - 0.1), 0.025, 0.4, metal)
	for x: float in xs:
		if _rng.randf() < 0.6:
			_poner(["comida/glass", "comida/mug", "comida/glass-wine", "comida/cup-coffee"][_rng.randi() % 4], Vector3(x + _rng.randf_range(-0.3, 0.3), tope, zb + 0.1), _rng.randf() * TAU)
	## Taburetes y clientes sentados de cara a la barra.
	var cliente := [false, true, true, false, true, false]
	for k in 6:
		_asiento("stoolBar", Vector3(float(xs[k]), 0, zb + 0.75), PI, [0.0] if cliente[k] else [], _calle())
	## Detrás: muebles bajos, botellero con botellas y la cafetera.
	var fin := _cocina(-6.6, -5.0 + 0.45, ["kitchenCabinet", "kitchenCabinetDrawer", "kitchenSink", "kitchenCabinet", "kitchenFridgeBuiltIn", "kitchenCabinetDrawer"], 0.0, false)
	_poner("kitchenCoffeeMachine", Vector3(-1.9, _alto("kitchenCabinet"), -4.6), 0.0, 2.4)
	var madera := Mini3D.mat(Color(0.33, 0.21, 0.13), 0.6)
	for y: float in [1.45, 1.9, 2.35]:
		Mini3D.caja(_raiz, Vector3((-6.6 + fin) * 0.5, y, -4.86), Vector3(fin + 6.6, 0.05, 0.28), madera)
		var x := -6.45
		while x < fin - 0.15:
			_poner(["comida/wine-red", "comida/wine-white", "comida/soda-bottle"][_rng.randi() % 3], Vector3(x, y + 0.025, -4.86), _rng.randf() * TAU)
			x += _rng.randf_range(0.16, 0.26)
	Mini3D.caja(_raiz, Vector3((-6.6 + fin) * 0.5, 1.92, -4.995), Vector3(fin + 6.6, 1.2, 0.01), Mini3D.mat(Color(0.75, 0.8, 0.85), 0.05))
	_trabajador(Vector3(-3.6, 0, -3.35), 0.0, false, ["charla", "brazos_jarra", "saludo_mano"], [Color(0.95, 0.95, 0.95), Color(0.15, 0.15, 0.18), true])
	_trabajador(Vector3(1.0, 0, -1.6), -PI * 0.7, false, ["charla", "aplaudir", "brazos_jarra"], _calle())
	## La pizarra del menú y el rótulo.
	Mini3D.caja(_raiz, Vector3(2.9, 1.9, -4.97), Vector3(1.6, 1.1, 0.04), Mini3D.mat(Color(0.12, 0.14, 0.13), 0.9))
	_cartel("MENÚ DEL DÍA\nTortilla · Croquetas\nCaña · Café", Vector3(2.9, 1.9, -4.93), 18, Color(0.95, 0.95, 0.88))
	_cartel("🍺 " + _sala_nombre().to_upper(), Vector3(-3.0, 2.95, -4.9), 30, Color(1.0, 0.85, 0.5))
	## Mesas de bar con dos sillas y algo de beber.
	var mesa_esc := Vector3(1.25, 2.2, 1.9)
	for p: Vector3 in [Vector3(-5.0, 0, 0.8), Vector3(-2.0, 0, 0.8), Vector3(1.6, 0, 0.9), Vector3(4.6, 0, 0.8), Vector3(-5.0, 0, 3.4), Vector3(4.6, 0, 3.4)]:
		_poner("table", p, PI * 0.5, mesa_esc)
		var alto_m := _alto("table", mesa_esc)
		for s: float in [-1.0, 1.0]:
			_asiento("chair", p + Vector3(s * 0.78, 0, 0), -s * PI * 0.5, [0.0] if _rng.randf() < 0.55 else [], _calle())
			_poner(["comida/glass-wine", "comida/mug", "comida/cocktail", "comida/glass"][_rng.randi() % 4], p + Vector3(s * 0.22, alto_m, _rng.randf_range(-0.15, 0.15)), _rng.randf() * TAU)
		if _rng.randf() < 0.5:
			_poner("comida/plate", p + Vector3(0, alto_m, 0.1))
			_poner(["comida/fries", "comida/sandwich", "comida/burger"][_rng.randi() % 3], p + Vector3(0, alto_m + 0.02, 0.1), _rng.randf() * TAU)
	## El rincón de las máquinas y la tele del partido.
	_poner("mini_arcade/gambling-machine", Vector3(6.4, 0, -3.6), -PI * 0.5)
	_poner("mini_arcade/arcade-machine", Vector3(6.45, 0, -2.4), -PI * 0.5)
	_pantalla(Vector3(6.96, 2.15, 0.6), Vector2(1.6, 0.9), Color(0.25, 0.6, 0.3), -PI * 0.5)
	_planta(Vector3(-6.5, 0, 4.4))
	_planta(Vector3(6.5, 0, 4.4))
	_ventana(-1.0, -0.6, 1.6, false)
	_caminante([Vector3(-6.4, 0, 2.1), Vector3(5.8, 0, 2.1), Vector3(5.8, 0, -0.7), Vector3(-6.4, 0, -0.7)], [Color(0.95, 0.95, 0.95), Color(0.15, 0.15, 0.18), true])

## Panadería (10 × 8 m): vitrina con bollería, estantes de pan, el horno, los
## panaderos, la cola y una mesita para el café.
func _panaderia() -> void:
	_tonos_sala = _MADERA_CLARA
	_sala(Vector3(10, 3.2, 8), Color(0.88, 0.8, 0.68), Color(0.98, 0.93, 0.82), "losa", Color(0.72, 0.5, 0.32))
	## El mostrador con la vitrina de cristal encima.
	var fin := _cocina(-3.6, -1.1, ["kitchenCabinet", "kitchenCabinetDrawer", "kitchenCabinet", "kitchenCabinetDrawer", "kitchenCabinet", "kitchenCabinet"], PI, false)
	var tope := _alto("kitchenCabinet")
	var largo := fin + 3.6
	var xc := (fin - 3.6) * 0.5
	Mini3D.caja(_raiz, Vector3(xc - 0.43, tope + 0.25, -1.1), Vector3(largo - 0.86, 0.5, 0.7), Mini3D.mat(Color(0.85, 0.93, 1.0, 0.22), 0.05))
	Mini3D.caja(_raiz, Vector3(xc - 0.43, tope + 0.505, -1.1), Vector3(largo - 0.86, 0.02, 0.72), Mini3D.mat(Color(0.95, 0.95, 0.93), 0.4))
	var dulces := ["croissant", "muffin", "donut-sprinkles", "cupcake", "croissant", "donut-sprinkles"]
	var x := -3.45
	while x < fin - 1.0:
		_poner("comida/plate-dinner" if _rng.randf() < 0.3 else "comida/plate", Vector3(x + 0.14, tope + 0.01, -1.1), 0.0)
		_poner("comida/" + String(dulces[_rng.randi() % dulces.size()]), Vector3(x + 0.14, tope + 0.04, -1.1), _rng.randf() * TAU)
		x += 0.34
	_poner("mini_arcade/cash-register", Vector3(fin - 0.43, tope, -1.15), PI, 0.55)
	## Estantes de pan contra la pared y el horno.
	var madera := Mini3D.mat(Color(0.6, 0.42, 0.26), 0.7)
	for y: float in [0.9, 1.35, 1.8]:
		Mini3D.caja(_raiz, Vector3(-2.2, y, -3.78), Vector3(5.4, 0.05, 0.42), madera)
		var xp := -4.75
		while xp < 0.3:
			var pan: String = ["loaf", "loaf-round", "loaf-baguette", "loaf"][_rng.randi() % 4]
			_poner("comida/" + pan, Vector3(xp + 0.2, y + 0.025, -3.78), _rng.randf_range(-0.2, 0.2) + (PI * 0.5 if pan == "loaf-baguette" else 0.0))
			xp += 0.42
	for s: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(-2.2 + s * 2.72, 1.0, -3.78), Vector3(0.05, 2.0, 0.42), madera)
	var horno := Mini3D.mat(Color(0.25, 0.25, 0.27), 0.35)
	horno.metallic = 0.6
	Mini3D.caja(_raiz, Vector3(3.2, 0.95, -3.45), Vector3(1.8, 1.9, 1.0), horno)
	for y: float in [0.65, 1.35]:
		Mini3D.caja(_raiz, Vector3(3.2, y, -2.94), Vector3(1.4, 0.45, 0.02), Mini3D.mat(Color(1.0, 0.55, 0.2), 0.3, 1.6))
	_trabajador(Vector3(-2.0, 0, -2.2), 0.0, false, ["charla", "brazos_jarra"], [Color.WHITE, Color(0.3, 0.3, 0.3), true])
	_trabajador(Vector3(0.9, 0, -2.2), 0.0, false, ["saludo_mano", "charla"], [Color.WHITE, Color(0.3, 0.3, 0.3), true])
	## La cola de clientes.
	for k in 3:
		_trabajador(Vector3(-2.6 + float(k) * 1.3, 0, 0.05 + float(k % 2) * 0.25), PI, false, ["charla"], _calle())
	## Mesita del café junto a la ventana.
	_poner("table", Vector3(3.6, 0, 1.6), 0.0, Vector3(1.2, 2.2, 1.5))
	_asiento("chair", Vector3(3.6, 0, 2.27), PI, [0.0], _calle())
	_asiento("chair", Vector3(3.6, 0, 0.93), 0.0, [])
	_poner("comida/cup-coffee", Vector3(3.55, _alto("table", 2.2), 1.85), 0.5)
	_poner("comida/croissant", Vector3(3.7, _alto("table", 2.2), 1.5), 1.2)
	_ventana(1.0, 1.6, 1.4)
	## Mesa de cestas con barras y hogazas.
	_poner("table", Vector3(-4.2, 0, 1.2), PI * 0.5, Vector3(1.6, 2.0, 1.6))
	var cesta := Mini3D.mat(Color(0.62, 0.45, 0.25), 0.9)
	for k in 2:
		var c := Vector3(-4.2, _alto("table", 2.0), 0.85 + float(k) * 0.7)
		Mini3D.caja(_raiz, c + Vector3(0, 0.06, 0), Vector3(0.5, 0.12, 0.55), cesta)
		for q in 3:
			_poner("comida/loaf-baguette" if k == 0 else "comida/loaf-round", c + Vector3(-0.15 + float(q) * 0.15, 0.08, 0), PI * 0.5 + _rng.randf_range(-0.2, 0.2))
	_planta(Vector3(-4.5, 0, 3.4))
	_cartel("🥖 " + _sala_nombre().to_upper(), Vector3(-2.2, 2.65, -3.95), 30)
