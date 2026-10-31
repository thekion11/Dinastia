class_name SubsueloMando
extends RefCounted
## EL CENTRO DE MANDO Y LAS ACOMETIDAS DEL SUBSUELO (27-10-2026). `SubsueloCiudad` le deja montar:
##  · la sala de control con tres pantallas de verdad (`PanelMando` en un SubViewport: mapa sinóptico, curvas
##    de carga y alertas), servidores, mesa de mapas, baliza del evento, botón de reparar y palanca de corte;
##  · el cuadro general de la galería eléctrica, donde se REARMA el disyuntor del evento del apagón;
##  · la sala de acometidas: un armario por edificio REAL de la ciudad (los que registra `RedesCiudadVista`),
##    con su consumo, su luz y su agua en vivo, el rumbo y la distancia hasta él, y la opción de aislarlo.
## `s` es el `SubsueloCiudad` (sin tipo para no cruzar dependencias entre capas).

const HALL_X := 56.0
const HALL_Z := 14.0
const PASO_ARMARIO := 3.1

static func _caja(s: Node3D, pos: Vector3, tam: Vector3, mat: Material) -> void:
	s._caja(pos, tam, mat)

static func montar(s) -> void:
	_sala_control(s)
	_cuadro_general(s)
	_acometidas(s)

# ============================================================================ SALA DE CONTROL

static func _pantalla(s, modo: String, x: float) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1024, 576)
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	s.add_child(vp)
	var p := PanelMando.new()
	p.size = Vector2(1024, 576)
	p.modo = modo
	p.modelo = s.redes.modelo
	vp.add_child(p)
	s._paneles.append({"vp": vp, "panel": p})
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(5.6, 3.15)
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = vp.get_texture()
	mi.material_override = m
	mi.position = Vector3(x, 2.5, -9.62)
	s.add_child(mi)
	_caja(s, Vector3(x, 2.5, -9.72), Vector3(5.9, 3.45, 0.16), s._mat(Color(0.06, 0.07, 0.08), 0.4))

static func _sala_control(s) -> void:
	for k in 4:
		s._lampara(Vector3(64.0 + float(k) * 5.0, s.ALTO - 0.25, 0), k % 2 == 0)
	for c in [["mapa", 64.5], ["curvas", 71.0], ["alertas", 77.5]]:
		_pantalla(s, c[0], c[1])
	var rack: StandardMaterial3D = s._mat(Color(0.16, 0.17, 0.19), 0.5)
	for k in 6:
		var z := -8.0 + float(k) * 2.2
		_caja(s, Vector3(61.0, 1.1, z), Vector3(0.9, 2.2, 1.6), rack)
		for l in 3:
			_caja(s, Vector3(61.5, 0.6 + float(l) * 0.6, z), Vector3(0.04, 0.12, 1.2), s._mat(Color(0.1, 0.8, 0.3) if (k + l) % 3 else Color(0.9, 0.6, 0.1), 0.4, 1.5))
	## La mesa de mapas del centro, con la pantalla táctil encima.
	_caja(s, Vector3(71.0, 0.5, 0.0), Vector3(6.0, 1.0, 2.6), s._mat(Color(0.3, 0.26, 0.2), 0.7))
	_caja(s, Vector3(71.0, 1.02, 0.0), Vector3(5.6, 0.04, 2.2), s._mat(Color(0.2, 0.4, 0.5), 0.5, 0.6))
	for k in 3:
		_caja(s, Vector3(66.0, 0.45, -5.0 + float(k) * 3.4), Vector3(1.0, 0.9, 1.0), s._mat(Color(0.12, 0.12, 0.14), 0.6))
	## Baliza del evento: gira en rojo mientras hay un apagón por resolver.
	s._baliza = OmniLight3D.new()
	s._baliza.light_color = Color(1.0, 0.1, 0.05)
	s._baliza.omni_range = 18.0
	s._baliza.light_energy = 0.0
	s._baliza.position = Vector3(71.0, s.ALTO - 0.6, 0)
	s.add_child(s._baliza)
	s._baliza_mat = s._mat(Color(1.0, 0.1, 0.05), 0.4, 0.2)
	_caja(s, Vector3(71.0, s.ALTO - 0.3, 0), Vector3(0.5, 0.3, 0.5), s._baliza_mat)
	for c in [[64.0, Color(0.1, 0.75, 0.25), "sub_reparar", "RECONECTAR / REPARAR AVERÍAS", "Reconectar la red y reparar averías"],
			[78.0, Color(0.85, 0.12, 0.1), "sub_cortar", "PALANCA: CORTAR LA LUZ DEL SECTOR", "Palanca roja: cortar la luz del sector"]]:
		var x: float = c[0]
		_caja(s, Vector3(x, 0.55, 8.2), Vector3(3.0, 1.1, 1.0), s._mat(Color(0.3, 0.32, 0.34), 0.5))
		_caja(s, Vector3(x, 1.2, 8.0), Vector3(0.6, 0.2, 0.6), s._mat(c[1], 0.4, 1.8))
		s._rotulo(Vector3(x, 2.1, 8.2), String(c[3]), 0.008)
		s.puntos.append({"pos": Vector2(x, 6.8), "k": c[2], "n": c[4], "radio": 2.2})
	s._rotulo(Vector3(71.0, 4.3, -9.5), "CENTRO DE MANDO · REDES DE LA CIUDAD", 0.006, false, 0.0)

# ============================================================================ CUADRO GENERAL

static func _cuadro_general(s) -> void:
	_caja(s, Vector3(21.0, 1.4, -32.6), Vector3(3.4, 2.8, 0.8), s._mat(Color(0.3, 0.34, 0.3), 0.5))
	s._disyuntor_mat = s._mat(Color(0.1, 0.8, 0.2), 0.4, 1.6)
	_caja(s, Vector3(21.0, 1.9, -32.15), Vector3(0.5, 0.9, 0.12), s._disyuntor_mat)
	_caja(s, Vector3(19.9, 1.9, -32.15), Vector3(0.7, 0.9, 0.08), s._mat(Color(0.12, 0.12, 0.14), 0.5))
	_caja(s, Vector3(22.1, 1.9, -32.15), Vector3(0.7, 0.9, 0.08), s._mat(Color(0.12, 0.12, 0.14), 0.5))
	s._rotulo(Vector3(21.0, 3.15, -32.1), "CUADRO GENERAL · DISYUNTOR", 0.007, false, 0.0)
	s._chispas = s._mat(Color(1.0, 0.9, 0.4), 0.4, 0.0)
	_caja(s, Vector3(21.0, 2.7, -31.9), Vector3(0.25, 0.1, 0.1), s._chispas)
	s.puntos.append({"pos": Vector2(21.0, -30.4), "k": "sub_disyuntor", "n": "Cuadro general: disyuntor", "radio": 2.0})

# ============================================================================ ACOMETIDAS

static func _rumbo(d: Vector3) -> String:
	var dirs := ["N", "NE", "E", "SE", "S", "SO", "O", "NO"]
	var ang := fposmod(atan2(d.x, -d.z), TAU)         ## 0 = norte (−z), crece hacia el este
	return dirs[int(roundf(ang / (TAU / 8.0))) % 8]

static func _acometidas(s) -> void:
	s._rotulo(Vector3(76.0, 3.9, HALL_Z + 0.6), "SALA DE ACOMETIDAS · CONEXIONES A EDIFICIOS", 0.009, false, 0.0)
	for k in 4:
		s._lampara(Vector3(64.0 + float(k) * 10.0, s.ALTO - 0.25, HALL_Z + 12.0), k % 2 == 0)
	var cuerpo: StandardMaterial3D = s._mat(Color(0.28, 0.31, 0.33), 0.5)
	var i := 0
	var slot := 0
	while i < s.redes.modelo.edificios.size() and slot < 24:
		var norte := slot % 2 == 0
		var x := HALL_X + 3.0 + float(slot / 2) * PASO_ARMARIO
		slot += 1
		if norte and x > 67.0 and x < 76.0:          ## el hueco de la puerta
			continue
		var ed: Dictionary = s.redes.modelo.edificios[i]
		i += 1
		var z := (HALL_Z + 1.5) if norte else (HALL_Z + 22.5)
		var cara := 1.0 if norte else -1.0           ## hacia dónde mira el frente (+z en la fila norte)
		_caja(s, Vector3(x, 1.0, z), Vector3(2.5, 2.0, 0.8), cuerpo)
		var lz: StandardMaterial3D = s._mat(Color(0.1, 0.8, 0.2), 0.4, 1.6)
		var ag: StandardMaterial3D = s._mat(Color(0.2, 0.5, 0.95), 0.4, 1.6)
		_caja(s, Vector3(x - 0.8, 1.85, z + 0.42 * cara), Vector3(0.28, 0.18, 0.05), lz)
		_caja(s, Vector3(x + 0.8, 1.85, z + 0.42 * cara), Vector3(0.28, 0.18, 0.05), ag)
		s._tubo(Vector3(x, 2.0, z), Vector3(x, s.ALTO, z), 0.12, s._mat(Color(0.5, 0.52, 0.55), 0.5))
		var rot: Label3D = s._rotulo(Vector3(x, 1.2, z + 0.43 * cara), "", 0.0042, false, 0.0 if norte else PI)
		s._acometidas.append({"ed": ed, "luz": lz, "agua": ag, "rotulo": rot})
		s.puntos.append({"pos": Vector2(x, z + 1.4 * cara), "k": "sub_edif_%d" % int(ed["id"]), "n": "Acometida: %s" % String(ed["nombre"]), "radio": 1.5})

# ============================================================================ EN VIVO

static func actualizar(s) -> void:
	var m: RedesCiudad = s.redes.modelo
	for p: Dictionary in s._paneles:
		(p["panel"] as PanelMando).sector_entrada = s.sector_entrada
		(p["panel"] as PanelMando).queue_redraw()
		(p["vp"] as SubViewport).render_target_update_mode = SubViewport.UPDATE_ONCE
	for a: Dictionary in s._acometidas:
		var ed: Dictionary = a["ed"]
		var est := m.estado_edificio(ed)
		(a["luz"] as StandardMaterial3D).albedo_color = Color(0.1, 0.8, 0.2) if bool(est["luz"]) else Color(0.9, 0.1, 0.1)
		(a["luz"] as StandardMaterial3D).emission = (a["luz"] as StandardMaterial3D).albedo_color
		(a["agua"] as StandardMaterial3D).albedo_color = Color(0.2, 0.5, 0.95) if bool(est["agua"]) else Color(0.9, 0.1, 0.1)
		(a["agua"] as StandardMaterial3D).emission = (a["agua"] as StandardMaterial3D).albedo_color
		var d: Vector3 = (ed["pos"] as Vector3) - s._origen_calle
		d.y = 0.0
		(a["rotulo"] as Label3D).text = "%s\n%d kW%s\na %d m %s" % [String(ed["nombre"]).to_upper(), int(est["kw"]),
			" · GEN" if bool(ed["generador"]) else (" · AISLADO" if bool(est["aislado"]) else ""), roundi(d.length()), _rumbo(d)]
	var ev := m.evento
	var pulso := (Time.get_ticks_msec() / 500) % 2 == 0
	s._baliza.light_energy = (2.5 if pulso else 0.4) if ev.activo else 0.0
	s._baliza_mat.emission_energy_multiplier = (3.0 if pulso else 0.4) if ev.activo else 0.15
	s._disyuntor_mat.albedo_color = Color(0.9, 0.1, 0.1) if (ev.activo and not ev.rearmado) else Color(0.1, 0.8, 0.2)
	s._disyuntor_mat.emission = s._disyuntor_mat.albedo_color
	s._chispas.emission_enabled = ev.activo and not ev.rearmado
	s._chispas.emission = Color(1.0, 0.9, 0.4)
	s._chispas.emission_energy_multiplier = 4.0 if pulso else 0.5

# ============================================================================ INTERACCIONES

## Las órdenes del centro de mando. `e` es el explorador. Devuelve false si `k` no es de aquí.
static func usar(s, e, k: String) -> bool:
	var m: RedesCiudad = s.redes.modelo
	match k:
		"sub_reparar":
			var r := m.evento.reconectar(m)
			var n := m.reparar_todo()
			s.redes.refrescar()
			if e.vida != null:
				e.vida._sincronizar_luz()
				e.vida.avisos_redes()
			if r == "ok":
				s._decir(e, Idiomas.t("Cuadro de mando"), Idiomas.t("Red reconectada: vuelve la luz en los sectores del apagón. Nadie sabrá quién fue."))
			elif r == "falta_rearmar":
				s._decir(e, Idiomas.t("Cuadro de mando"), Idiomas.t("El disyuntor general sigue saltado: rearma primero el cuadro general de la galería eléctrica."))
			else:
				s._decir(e, Idiomas.t("Cuadro de mando"), Idiomas.t("La cuadrilla sale a arreglar: %d averías reparadas.") % n if n > 0 else Idiomas.t("Todo en orden: no hay averías."))
		"sub_disyuntor":
			var r2 := m.evento.rearmar()
			if r2 == "ok":
				s._decir(e, Idiomas.t("Cuadro general"), Idiomas.t("Levantas el disyuntor con las dos manos. Chispea, pero aguanta. Ahora reconecta la red desde la sala de control."))
			elif r2 == "ya":
				s._decir(e, Idiomas.t("Cuadro general"), Idiomas.t("El disyuntor ya está rearmado. Falta reconectar la red en la sala de control."))
			else:
				s._decir(e, Idiomas.t("Cuadro general"), Idiomas.t("El cuadro general está en orden. Mejor no tocar nada."))
		"sub_cortar":
			if m.esta_averiado("luz", s.sector_entrada):
				m.reparar("luz", s.sector_entrada)
				s._decir(e, Idiomas.t("Palanca roja"), Idiomas.t("Vuelves a subir la palanca: el sector recupera la luz."))
			else:
				m.averiar("luz", s.sector_entrada)
				s._decir(e, Idiomas.t("Palanca roja"), Idiomas.t("¡Clac! El sector de arriba se queda sin luz. Los vecinos no sabrán por qué."))
			m.recalcular()
			s.redes.refrescar()
			if e.vida != null:
				e.vida._sincronizar_luz()
		"sub_secreto":
			s._decir(e, Idiomas.t("Cuarto olvidado"), Idiomas.t("Una tele vieja con el escudo del club y una nota: «Los de arriba juegan; los de abajo hacemos que enciendan las luces». Nadie más lo sabe.") if not s._secreto_visto else Idiomas.t("Sigue ahí, con la tele encendida. Es vuestro secreto."))
			s._secreto_visto = true
		_:
			if not k.begins_with("sub_edif_"):
				return false
			var id := int(k.get_slice("_", 2))
			if id < 0 or id >= m.edificios.size():
				return false
			var ed: Dictionary = m.edificios[id]
			ed["aislado"] = not bool(ed["aislado"])
			m.anotar("%s %s" % [String(ed["nombre"]), "AISLADO de la red" if bool(ed["aislado"]) else "reconectado"])
			m.recalcular()
			s.redes.refrescar()
			s._decir(e, Idiomas.t("Acometida"), Idiomas.t("Cortas la acometida: el edificio queda aislado de las redes.") if bool(ed["aislado"]) else Idiomas.t("Restableces la acometida: el edificio vuelve a la red."))
	actualizar(s)
	return true
