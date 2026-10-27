class_name MuseoAmpliado
extends RefCounted
## EL MUSEO QUE CRECE (27-10-2026, orden del dueño: «el museo se va a tener que extender, por eso el ascensor»). Plan §2.2f-bis.
## La sala de la planta 2 guarda las seis primeras copas (`SalasClub.MAX_SALA`). Con el museo a nivel `NIVEL_PLANTA` o más (la obra
## «Museo del club», ya existente: coste, semanas y mantenimiento de siempre) el ascensor suma la planta 3, «Museo ampliado»: vitrinas
## con las copas del séptimo título en adelante, panel de hitos con año y título, camisetas por década y el balón de la primera copa.
## Mientras dura la obra que lleva el museo al nivel `NIVEL_PLANTA`, la planta 3 ya existe pero en obra (andamios y lona).
## Al entrar por primera vez tras terminar, las copas se iluminan una a una (`MuseoAmpliadoAnim`).
## Todo sale de `ctx` (`EdificioClub.contexto_de`): niveles, obras en marcha y los hitos [{anio, titulo}] del club.
const NIVEL_PLANTA := 5
const PLANTA := 3
const SALA := "Museo ampliado"
const POR_LADO := 5

static func lista() -> Array:
	return [PLANTA, SALA, [[SALA, -8.0, 8.0]]]

static func en_obra(ctx: Dictionary) -> bool:
	var niveles: Dictionary = ctx.get("inst", {})
	return int(niveles.get("museo", 0)) == NIVEL_PLANTA - 1 and (ctx.get("obras", {}) as Dictionary).has("museo")

static func terminada(ctx: Dictionary) -> bool:
	return int((ctx.get("inst", {}) as Dictionary).get("museo", 0)) >= NIVEL_PLANTA

## ¿Existe la planta 3 (terminada o en obra)?
static func existe(ctx: Dictionary) -> bool:
	return terminada(ctx) or en_obra(ctx)

## Los hitos del club por año, del más antiguo al más nuevo: [{anio, titulo}].
static func hitos(ctx: Dictionary) -> Array:
	var sal: Array = (ctx.get("hitos", []) as Array).duplicate()
	sal.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("anio", 0)) < int(b.get("anio", 0)))
	return sal

static func _mat_oro_vivo() -> StandardMaterial3D:
	var m: StandardMaterial3D = Texturas.metal(Color(0.95, 0.78, 0.3), 0.22)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.82, 0.35)
	m.emission_energy_multiplier = 0.0
	return m

## Una copa suelta (nodo propio, con su material para poder iluminarla): el trofeo real si está, o una copa de cilindros.
static func _copa(nodo: Node3D, p: Vector3, madera: Material) -> MeshInstance3D:
	TunelVestuario._caja(nodo, p + Vector3(0, 0.04, 0), Vector3(0.24, 0.08, 0.24), madera, false)
	var mi := MeshInstance3D.new()
	SalasClub._cargar_trofeo()
	if SalasClub._trofeo != null and SalasClub._trofeo_mat != null:
		mi.mesh = SalasClub._trofeo
		mi.material_override = (SalasClub._trofeo_mat as StandardMaterial3D).duplicate()
		var m: StandardMaterial3D = mi.material_override
		m.emission_enabled = true
		m.emission = Color(1.0, 0.82, 0.35)
		m.emission_energy_multiplier = 0.0
		mi.scale = Vector3.ONE * SalasClub.TROFEO_ESCALA
		mi.position = p + Vector3(0, 0.08, 0)
	else:
		mi.mesh = SalasClub._cilindro(0.14, 0.05, 0.3)
		mi.material_override = _mat_oro_vivo()
		mi.position = p + Vector3(0, 0.3, 0)
	nodo.add_child(mi)
	return mi

static func montar(nodo: Node3D, caja: Rect2, y0: float, c1: Color, c2: Color, ctx: Dictionary) -> void:
	if en_obra(ctx):
		_obra(nodo, caja, y0, ctx)
		return
	var lote := PiezasVestuario.Lote.new()
	var m := PiezasVestuario.materiales(c1, c2)
	var base := TunelVestuario._mat(Color(0.1, 0.1, 0.12), 0.4)
	var vidrio := SalasClub.vidrio_vitrina()
	var cx := caja.get_center().x
	var hs := hitos(ctx)
	var copas: Array = []
	lote.caja(m["placa"], SalasClub._en(Vector3(cx, y0 + 0.035, caja.get_center().y)), Vector3(1.6, 0.01, caja.size.y - 0.3))
	lote.caja(m["cojin"], SalasClub._en(Vector3(cx, y0 + 0.04, caja.get_center().y)), Vector3(1.4, 0.01, caja.size.y - 0.5))
	## Vitrinas de los dos lados con las copas del séptimo título en adelante.
	var por_lado := clampi(int((caja.size.y - 2.6) / 1.3), 2, POR_LADO)
	var z0 := caja.position.y + 1.4
	var z1 := caja.end.y - 1.2
	var n := mini(hs.size() - SalasClub.MAX_SALA, por_lado * 2)
	for k in maxi(n, 0):
		var lado := -1.0 if k % 2 == 0 else 1.0
		var pz := z0 + (z1 - z0) * (float(k / 2) + 0.5) / float(por_lado)
		var px := (caja.position.x + 0.45) if lado < 0.0 else (caja.end.x - 0.45)
		SalasClub.vitrina(lote, nodo, m, base, vidrio, Vector3(px, y0, pz))
		copas.append(_copa(nodo, Vector3(px, y0 + 1.0, pz), m["madera"]))
		var h: Dictionary = hs[SalasClub.MAX_SALA + k]
		TunelVestuario._rotulo(nodo, "%s · %d" % [Idiomas.t(String(h.get("titulo", ""))), int(h.get("anio", 0))],
			Vector3(px - lado * 0.38, y0 + 1.2, pz), -lado * PI / 2.0, 14, Color(0.12, 0.12, 0.14))
	## Camisetas por década en la pared del fondo (la del ascensor queda a un lado).
	var decadas: Array = []
	for h: Dictionary in hs:
		var d := int(h.get("anio", 0)) / 10 * 10
		if not decadas.has(d):
			decadas.append(d)
	for k in mini(maxi(decadas.size(), 2), 3):
		var px := caja.position.x + caja.size.x * (float(k) + 0.5) / 4.0
		var pz := caja.position.y - 0.13
		lote.caja(base, SalasClub._en(Vector3(px, y0 + 1.55, pz)), Vector3(0.95, 1.15, 0.05))
		lote.caja(m["toalla"], SalasClub._en(Vector3(px, y0 + 1.55, pz + 0.03)), Vector3(0.85, 1.05, 0.01))
		var alterna := k % 2 == 1
		PiezasVestuario.camiseta(lote, SalasClub._en(Vector3(px, y0 + 1.6, pz + 0.06)), m["cam2"] if alterna else m["cam1"], m["cam1"] if alterna else m["cam2"])
		if k < decadas.size():
			TunelVestuario._rotulo(nodo, "%ds" % int(decadas[k]), Vector3(px, y0 + 1.07, pz + 0.07), 0.0, 22, Color(0.12, 0.12, 0.14))
	## El panel de hitos y el balón de la primera copa, en el cuarto hueco de la pared del fondo.
	var px4 := caja.position.x + caja.size.x * 0.875
	var texto := Idiomas.t("HITOS DEL CLUB")
	for h: Dictionary in hs.slice(0, 12):
		texto += "\n%d · %s" % [int(h.get("anio", 0)), Idiomas.t(String(h.get("titulo", "")))]
	TunelVestuario._rotulo(nodo, texto, Vector3(px4, y0 + 1.75, caja.position.y - 0.1), 0.0, 17, Color(1.0, 0.86, 0.45))
	if not hs.is_empty():
		lote.malla(m["metal"], SalasClub._en(Vector3(px4, y0 + 0.4, caja.position.y + 0.7)), SalasClub._cilindro(0.1, 0.14, 0.8))
		lote.malla(TunelVestuario._mat(Color(0.45, 0.28, 0.14), 0.6), SalasClub._en(Vector3(px4, y0 + 0.92, caja.position.y + 0.7)), SalasClub._esfera(0.13))
		TunelVestuario._rotulo(nodo, Idiomas.t("Primer título") + " · %d" % int((hs[0] as Dictionary).get("anio", 0)),
			Vector3(px4, y0 + 0.5, caja.position.y + 0.86), 0.0, 14, Color(0.9, 0.9, 0.85))
	lote.caja(m["cam1"], SalasClub._en(Vector3(cx, y0 + 2.7, caja.position.y - 0.14)), Vector3(caja.size.x, 0.3, 0.02))
	lote.montar(nodo, "MuseoAmpliado")
	SalasClub._luces_museo(nodo, caja, y0, cx)
	var anim := MuseoAmpliadoAnim.new()
	anim.name = "AnimMuseoAmpliado"
	anim.copas = copas
	anim.sala = caja
	anim.y0 = y0
	anim.nivel = int((ctx.get("inst", {}) as Dictionary).get("museo", 0))
	anim.titulos = int(ctx.get("titulos", 0))
	nodo.add_child(anim)

## La planta en obra: andamios, lona y un cartel con las semanas que faltan.
static func _obra(nodo: Node3D, caja: Rect2, y0: float, ctx: Dictionary) -> void:
	var acero: StandardMaterial3D = Texturas.metal(Color(0.62, 0.64, 0.66), 0.5)
	var tablon := TunelVestuario._mat(Color(0.62, 0.46, 0.28), 0.8)
	var lona := StandardMaterial3D.new()
	lona.albedo_color = Color(0.2, 0.42, 0.66, 0.55)
	lona.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lona.cull_mode = BaseMaterial3D.CULL_DISABLED
	var cx := caja.get_center().x
	for fila in 3:
		var z := caja.position.y + 1.0 + float(fila) * (caja.size.y - 2.0) / 2.0
		for col in 5:
			var x := caja.position.x + 1.0 + float(col) * (caja.size.x - 2.0) / 4.0
			TunelVestuario._caja(nodo, Vector3(x, y0 + 1.5, z), Vector3(0.08, 3.0, 0.08), acero, false)
			if col < 4:
				TunelVestuario._caja(nodo, Vector3(x + (caja.size.x - 2.0) / 8.0, y0 + 1.1, z), Vector3((caja.size.x - 2.0) / 4.0, 0.06, 0.08), acero, false)
				TunelVestuario._caja(nodo, Vector3(x + (caja.size.x - 2.0) / 8.0, y0 + 2.1, z), Vector3((caja.size.x - 2.0) / 4.0, 0.06, 0.08), tablon, false)
	TunelVestuario._caja(nodo, Vector3(cx, y0 + 1.5, caja.position.y + 0.9), Vector3(caja.size.x - 1.0, 3.0, 0.03), lona, false)
	var semanas := int(((ctx.get("obras", {}) as Dictionary).get("museo", 1)))
	TunelVestuario._rotulo(nodo, Idiomas.t("EN OBRA · faltan %d semanas") % semanas, Vector3(cx, y0 + 2.4, caja.position.y + 0.85), 0.0, 36, Color(1.0, 0.85, 0.2))
	var o := OmniLight3D.new()
	o.position = Vector3(cx, y0 + 3.0, caja.get_center().y)
	o.omni_range = 9.0
	o.light_energy = 0.6
	nodo.add_child(o)
