class_name SalaVAR
extends Control
## LA SALA VAR POR DENTRO (26-9-2026). Pedido: *"ver el VAR por dentro"*.
##
## Cuando el árbitro pide revisar, la transmisión se va a la sala de vídeo:
## una sala oscura con una pared de monitores, dos puestos con sus operadores
## (auriculares, polo oscuro) y el rótulo VAR. Los monitores NO son dibujos:
## cada uno es una cámara de verdad sobre el MISMO mundo 3D del partido (detrás
## del arco, lateral a ras de campo, cenital y la de la jugada), así que se ve
## lo que está pasando en el campo desde cuatro ángulos.
## Dura unos segundos, muestra la decisión y se cierra sola. El partido se
## pausa mientras tanto (lo reanuda quien la abrió, con `terminada`).

signal terminada

const DURACION := 6.5

var _vp: SubViewport
var _cam: Camera3D
var _t := 0.0
var _rotulo: Label
var _reloj: Label
var _decision: PanelContainer
var _motivo := ""
## Si la revisión acaba anulando lo decidido en el campo (el gol).
var anula := false
var _minuto := 0
var _mundo_partido: World3D
var _foco := Vector3.ZERO
var _monitores: Array = []
## LA LÍNEA DEL FUERA DE JUEGO EN EL MONITOR (17-10-2026, M-118): con
## {"linea": z del penúltimo defensor, "atacante": z del goleador, "margen": m}
## (lo que mide el motor en el pase, `MotorJugable.lineas_gol`), la cámara 2 se
## pone en alto de lado mirando a esa zona y se dibujan encima las dos líneas
## de lado a lado del campo, como en la tele: roja la del defensor, azul la del
## atacante, y el margen en metros.
var lineas: Dictionary = {}

static func abrir(padre: Control, mundo_partido: World3D, foco: Vector3, minuto: int, motivo: String, anular := false, lineas_off := {}) -> SalaVAR:
	var s := SalaVAR.new()
	s.anula = anular
	s.lineas = lineas_off
	s._mundo_partido = mundo_partido
	s._foco = foco
	s._minuto = minuto
	s._motivo = motivo
	s.set_anchors_preset(Control.PRESET_FULL_RECT)
	s.mouse_filter = Control.MOUSE_FILTER_STOP
	## Encima de todo el HUD del partido (rótulos de repetición incluidos).
	s.z_index = 100
	padre.add_child(s)
	s._montar()
	return s

func _montar() -> void:
	var cont := SubViewportContainer.new()
	cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	cont.stretch = true
	add_child(cont)
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.size = Vector2i(1600, 900)
	_vp.msaa_3d = Viewport.MSAA_2X
	cont.add_child(_vp)
	_sala()
	## Rótulos de transmisión.
	var barra := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.05, 0.1, 0.88)
	sb.border_color = Color("3fa9f5")
	sb.border_width_bottom = 3
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	barra.add_theme_stylebox_override("panel", sb)
	barra.set_anchors_preset(Control.PRESET_TOP_WIDE)
	add_child(barra)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	barra.add_child(fila)
	_rotulo = Label.new()
	_rotulo.text = Idiomas.t("🖥️  REVISIÓN VAR  ·  %d'  ·  %s") % [_minuto, Idiomas.t(_motivo)]
	_rotulo.add_theme_font_size_override("font_size", 26)
	_rotulo.add_theme_color_override("font_color", Color("e8f4ff"))
	_rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(_rotulo)
	_reloj = Label.new()
	_reloj.add_theme_font_size_override("font_size", 26)
	_reloj.add_theme_color_override("font_color", Color("3fa9f5"))
	fila.add_child(_reloj)
	_decision = PanelContainer.new()
	var sd := StyleBoxFlat.new()
	sd.bg_color = Color(0.45, 0.06, 0.06, 0.95) if anula else Color(0.05, 0.35, 0.15, 0.95)
	sd.set_corner_radius_all(10)
	sd.content_margin_left = 40
	sd.content_margin_right = 40
	sd.content_margin_top = 18
	sd.content_margin_bottom = 18
	_decision.add_theme_stylebox_override("panel", sd)
	_decision.set_anchors_preset(Control.PRESET_CENTER)
	_decision.visible = false
	add_child(_decision)
	var ld := Label.new()
	ld.text = Idiomas.t("✖  DECISIÓN: GOL ANULADO") if anula else Idiomas.t("✔  DECISIÓN: SE MANTIENE LO DECIDIDO EN EL CAMPO")
	ld.add_theme_font_size_override("font_size", 30)
	ld.add_theme_color_override("font_color", Color.WHITE)
	_decision.add_child(ld)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

## La sala: suelo, paredes, luz fría, la pared de monitores, dos puestos con
## operadores y el rótulo.
func _sala() -> void:
	var raiz := Node3D.new()
	_vp.add_child(raiz)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.02, 0.03, 0.05)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.25, 0.32, 0.45)
	e.ambient_light_energy = 0.6
	e.glow_enabled = true
	e.glow_intensity = 0.7
	env.environment = e
	raiz.add_child(env)
	_caja(raiz, Vector3(0, -0.05, 0), Vector3(12, 0.1, 9), Color(0.07, 0.08, 0.1), 0.0)       ## suelo
	_caja(raiz, Vector3(0, 1.6, -3.2), Vector3(12, 3.4, 0.1), Color(0.09, 0.11, 0.15), 0.0)   ## pared de monitores
	_caja(raiz, Vector3(-5.0, 1.6, 0), Vector3(0.1, 3.4, 9), Color(0.08, 0.09, 0.12), 0.0)
	_caja(raiz, Vector3(5.0, 1.6, 0), Vector3(0.1, 3.4, 9), Color(0.08, 0.09, 0.12), 0.0)
	## Tiras de luz en el techo y el zócalo azul.
	for x: float in [-3.0, 0.0, 3.0]:
		_caja(raiz, Vector3(x, 3.25, 0), Vector3(1.6, 0.04, 0.12), Color(0.8, 0.9, 1.0), 2.5)
	_caja(raiz, Vector3(0, 0.05, -3.12), Vector3(12, 0.06, 0.04), Color("3fa9f5"), 3.0)
	var luz := OmniLight3D.new()
	luz.position = Vector3(0, 2.8, 0.5)
	luz.light_color = Color(0.75, 0.85, 1.0)
	luz.light_energy = 1.4
	luz.omni_range = 9.0
	raiz.add_child(luz)
	## Rótulo VAR.
	var var_rot := Label3D.new()
	var_rot.text = Idiomas.t("VAR")
	var_rot.font_size = 160
	var_rot.pixel_size = 0.004
	var_rot.modulate = Color("3fa9f5")
	var_rot.outline_size = 0
	var_rot.position = Vector3(0, 2.95, -3.12)
	raiz.add_child(var_rot)
	## Los monitores: cuatro cámaras sobre el partido real.
	var angulos := [
		[Vector3(_foco.x * 0.3, 8.0, _foco.z + signf(_foco.z + 0.01) * 16.0), _foco, 40.0],  ## detrás de la jugada
		[Vector3(36.0, 2.0, _foco.z), _foco, 30.0],                                          ## lateral a ras de campo (fuera de juego)
		[Vector3(_foco.x, 45.0, _foco.z + 0.1), _foco, 45.0],                                 ## cenital
		[Vector3(-30.0, 14.0, _foco.z * 0.6), _foco, 28.0],                                   ## tele contraria
	]
	var hay_lineas := lineas.has("linea") and lineas.has("atacante")
	if hay_lineas:
		## Alto y de lado, en diagonal sobre la zona de las dos líneas.
		var zl := (float(lineas["linea"]) + float(lineas["atacante"])) * 0.5
		var hacia := signf(_foco.z + 0.01)
		angulos[1] = [Vector3(44.0, 17.0, zl - hacia * 12.0), Vector3(0.0, 0.0, zl + hacia * 2.0), 38.0]
	var pos_mon := [Vector3(-1.1, 1.75, -3.1), Vector3(1.1, 1.75, -3.1), Vector3(-3.3, 1.75, -3.1), Vector3(3.3, 1.75, -3.1)]
	var tam_mon := [Vector2(2.0, 1.12), Vector2(2.0, 1.12), Vector2(1.6, 0.9), Vector2(1.6, 0.9)]
	for i in 4:
		var tex: Texture2D = null
		if _mundo_partido != null:
			var sv := SubViewport.new()
			sv.world_3d = _mundo_partido
			sv.size = Vector2i(480, 270)
			sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			add_child(sv)
			var c := Camera3D.new()
			c.fov = float(angulos[i][2])
			c.far = 400.0
			sv.add_child(c)
			c.position = angulos[i][0]
			c.look_at(angulos[i][1], Vector3.UP if i != 2 else Vector3(0, 0, -1))
			c.current = true
			tex = sv.get_texture()
			_monitores.append(c)
		_monitor(raiz, pos_mon[i], tam_mon[i], tex, i)
		if i == 1 and hay_lineas and _monitores.size() > 1:
			_dibujar_lineas(raiz, _monitores[1], Vector2(480, 270), pos_mon[i], tam_mon[i])
	## Dos puestos con su operador (auriculares y polo oscuro).
	for lado: float in [-1.0, 1.0]:
		var mesa_x := 1.6 * lado
		_caja(raiz, Vector3(mesa_x, 0.75, -0.9), Vector3(2.2, 0.06, 0.9), Color(0.13, 0.14, 0.17), 0.0)
		_caja(raiz, Vector3(mesa_x, 0.37, -0.9), Vector3(2.1, 0.74, 0.08), Color(0.1, 0.1, 0.12), 0.0)
		## Pantallas de mesa encendidas.
		_caja(raiz, Vector3(mesa_x - 0.45, 1.05, -1.15), Vector3(0.7, 0.42, 0.03), Color(0.25, 0.55, 0.9), 1.4)
		_caja(raiz, Vector3(mesa_x + 0.45, 1.05, -1.15), Vector3(0.7, 0.42, 0.03), Color(0.2, 0.7, 0.45), 1.2)
		_operador(raiz, Vector3(mesa_x, 0.0, -0.1), lado)
	_cam = Camera3D.new()
	_cam.fov = 52
	_cam.position = Vector3(2.8, 2.1, 3.6)
	raiz.add_child(_cam)
	_cam.look_at(Vector3(0, 1.5, -2.5), Vector3.UP)
	_cam.current = true

func _caja(raiz: Node3D, pos: Vector3, tam: Vector3, col: Color, emision: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.7
	if emision > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emision
	mi.material_override = m
	mi.position = pos
	raiz.add_child(mi)
	return mi

func _monitor(raiz: Node3D, pos: Vector3, tam: Vector2, tex: Texture2D, i: int) -> void:
	_caja(raiz, pos + Vector3(0, 0, -0.03), Vector3(tam.x + 0.08, tam.y + 0.08, 0.05), Color(0.02, 0.02, 0.03), 0.0)
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = tam
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if tex != null:
		m.albedo_texture = tex
	else:
		m.albedo_color = Color(0.1, 0.3, 0.2)
	mi.material_override = m
	mi.position = pos
	raiz.add_child(mi)
	var et := Label3D.new()
	et.text = [Idiomas.t("CÁMARA 1 · JUGADA"), Idiomas.t("CÁMARA 2 · LÍNEA"), Idiomas.t("CÁMARA 3 · CENITAL"), Idiomas.t("CÁMARA 4 · CONTRA")][i]
	et.font_size = 28
	et.pixel_size = 0.0035
	et.modulate = Color(0.85, 0.92, 1.0)
	et.position = pos + Vector3(-tam.x * 0.5 + 0.35, tam.y * 0.5 - 0.07, 0.01)
	raiz.add_child(et)

## Las dos líneas, proyectadas con la cámara del monitor y dibujadas sobre su
## pantalla (finas cintas que brillan), recortadas al borde del monitor.
func _dibujar_lineas(raiz: Node3D, cam: Camera3D, px: Vector2, centro: Vector3, tam: Vector2) -> void:
	var pares := [[float(lineas["linea"]), Color(1.0, 0.18, 0.2)], [float(lineas["atacante"]), Color(0.25, 0.6, 1.0)]]
	for par: Array in pares:
		var z: float = par[0]
		var a3 := Vector3(-34.0, 0.03, z)
		var b3 := Vector3(34.0, 0.03, z)
		if cam.is_position_behind(a3) or cam.is_position_behind(b3):
			continue
		var a := _a_monitor(cam.unproject_position(a3), px, tam)
		var b := _a_monitor(cam.unproject_position(b3), px, tam)
		var rec := _recortar(a, b, tam * 0.5)
		if rec.is_empty():
			continue
		_cinta(raiz, centro, rec[0], rec[1], par[1])
	## El margen medido, abajo del monitor.
	var m := float(lineas.get("margen", 0.0))
	var et := Label3D.new()
	var cm := absf(m) * 100.0
	et.text = (Idiomas.t("ADELANTADO %d cm") if m > 0.0 else Idiomas.t("HABILITADO %d cm")) % int(round(cm))
	et.font_size = 34
	et.pixel_size = 0.0035
	et.outline_size = 6
	et.modulate = Color(1.0, 0.35, 0.35) if m > 0.0 else Color(0.5, 0.85, 1.0)
	## Arriba a la derecha (abajo lo tapa la cabeza del operador).
	et.position = centro + Vector3(tam.x * 0.5 - 0.42, tam.y * 0.5 - 0.08, 0.012)
	raiz.add_child(et)

## Píxel de la cámara del monitor -> punto (x, y) sobre la pantalla del monitor.
func _a_monitor(p: Vector2, px: Vector2, tam: Vector2) -> Vector2:
	return Vector2((p.x / px.x - 0.5) * tam.x, (0.5 - p.y / px.y) * tam.y)

## Liang-Barsky: el tramo a-b dentro del rectángulo ±medio.
func _recortar(a: Vector2, b: Vector2, medio: Vector2) -> Array:
	var t0 := 0.0
	var t1 := 1.0
	var d := b - a
	var p := [-d.x, d.x, -d.y, d.y]
	var q := [a.x + medio.x, medio.x - a.x, a.y + medio.y, medio.y - a.y]
	for k in 4:
		if absf(float(p[k])) < 0.000001:
			if float(q[k]) < 0.0:
				return []
			continue
		var r := float(q[k]) / float(p[k])
		if float(p[k]) < 0.0:
			t0 = maxf(t0, r)
		else:
			t1 = minf(t1, r)
		if t0 > t1:
			return []
	return [a + d * t0, a + d * t1]

func _cinta(raiz: Node3D, centro: Vector3, a: Vector2, b: Vector2, col: Color) -> void:
	var largo := a.distance_to(b)
	if largo < 0.01:
		return
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(largo, 0.012, 0.002)
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	mi.material_override = m
	var medio := (a + b) * 0.5
	mi.position = centro + Vector3(medio.x, medio.y, 0.008)
	mi.rotation.z = atan2(b.y - a.y, b.x - a.x)
	raiz.add_child(mi)

## UN OPERADOR DEL VAR (17-10-2026): antes era el futbolista del partido con
## la equipación pintada de oscuro (calvo, de culturista y con ropa de juego).
## Ahora se arma como la gente de la ciudad (`PeatonQ`): complexión normal
## (`adelgazar`), polo de árbitro con el cuello celeste del VAR y pantalón de
## vestir (ropa de calle del `VestidorQ`), pelo (`PeloQ`), cara de la
## biblioteca modular y ojos de verdad; sentado en una silla de oficina.
func _operador(raiz: Node3D, pos: Vector3, lado: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7741 + (1 if lado > 0.0 else 0)
	var d := FutbolistaQ.crear(rng.randf_range(1.72, 1.84), "male")
	if d.is_empty():
		return
	var nodo: Node3D = d["nodo"]
	nodo.position = pos
	nodo.rotation_degrees.y = 180.0
	raiz.add_child(nodo)
	FutbolistaQ.terminar(d, false)
	PersonajeDT.adelgazar(d, false)
	var piel := Color("b98a66") if lado < 0 else Color("7a5238")
	var pelo_col: Color = PeatonQ.PELOS[rng.randi() % 3]
	var polo := Color("1b1f27")
	var ribete := Color("3fa9f5")
	var pant := Color("22252c")
	var kit := {
		"dis": "liso",
		"cols": [polo.to_html(false), polo.to_html(false), ribete.to_html(false), "ffffff", "111111"],
		"trim": 1, "cuello": 2, "manga_corta": true,
		"pant": {"dis": "liso", "c1": pant.to_html(false), "c2": pant.to_html(false)},
		"med": {"dis": "lisas", "c1": "15161a", "c2": "15161a"},
		"bot": {"mod": "clasico", "c1": "111214", "c2": "111214", "c3": "222222"},
		"acc": {}, "civil": true,
	}
	VestidorQ.vestir_equipacion(d, polo, ribete, "liso", piel, pelo_col, pant, pant, true, kit, 0)
	PeloQ.poner(d, ["corto", "fade", "flequillo"][rng.randi() % 3] if lado < 0 else "rapado", pelo_col, rng.randf() < 0.5)
	if BibliotecaCaras.hay():
		var bib := BibliotecaCaras.para("var_%d" % rng.seed, piel, pelo_col)
		if not bib.is_empty():
			bib["pelo"] = ""
			VestidorQ.poner_cara(d, {"look": {}, "foto": "", "biblio": bib}, piel)
	PersonajeDT._ojos_vivos(d, piel, Color(String(PersonajeDT.OJOS[rng.randi() % PersonajeDT.OJOS.size()])), false)
	var ap: AnimationPlayer = d["anim"]
	if ap.has_animation("sentado"):
		ap.play("sentado")
	## Sentado de verdad: la cadera sobre el asiento (como en los bancos del
	## metro, `MetroCiudad.altura_cadera`), no flotando a la altura de pie.
	const ASIENTO := 0.48
	var cadera := MetroCiudad.altura_cadera(nodo)
	if cadera > 0.0:
		nodo.position.y = pos.y + ASIENTO + 0.08 - cadera * 0.99
	## La silla de oficina: asiento, respaldo (detrás: el operador mira a −Z),
	## pie y base.
	var gris := Color(0.12, 0.12, 0.14)
	_caja(raiz, pos + Vector3(0, ASIENTO - 0.03, 0.02), Vector3(0.5, 0.07, 0.48), gris, 0.0)
	_caja(raiz, pos + Vector3(0, ASIENTO + 0.36, 0.27), Vector3(0.46, 0.62, 0.06), gris, 0.0)
	_caja(raiz, pos + Vector3(0, ASIENTO * 0.5 - 0.02, 0.02), Vector3(0.06, ASIENTO - 0.06, 0.06), Color(0.3, 0.3, 0.32), 0.0)
	_caja(raiz, pos + Vector3(0, 0.03, 0.02), Vector3(0.56, 0.04, 0.56), Color(0.2, 0.2, 0.22), 0.0)
	## Auriculares: una diadema y dos cascos, en su cabeza (hueso Head de la
	## pose de reposo: la postura sentada no mueve la cadera, ver arriba).
	var alto_cabeza := 1.62
	var esqs := nodo.find_children("*", "Skeleton3D", true, false)
	if not esqs.is_empty():
		var sk: Skeleton3D = esqs[0]
		var hb := sk.find_bone("Head")
		if hb >= 0:
			alto_cabeza = (sk.global_transform * sk.get_bone_global_rest(hb)).origin.y - nodo.global_position.y + 0.1
	var cab := Node3D.new()
	cab.position = Vector3(pos.x, nodo.position.y + alto_cabeza, pos.z + 0.02)
	raiz.add_child(cab)
	for s: float in [-1.0, 1.0]:
		var casco := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.045
		cm.bottom_radius = 0.045
		cm.height = 0.03
		casco.mesh = cm
		casco.rotation_degrees.z = 90.0
		casco.position = Vector3(0.085 * s, 0.0, 0.0)
		var mm := StandardMaterial3D.new()
		mm.albedo_color = Color(0.08, 0.08, 0.09)
		casco.material_override = mm
		cab.add_child(casco)
	var diadema := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.085
	tm.outer_radius = 0.1
	diadema.mesh = tm
	diadema.rotation_degrees.z = 90.0
	diadema.rotation_degrees.y = 90.0
	diadema.position = Vector3(0, 0.02, 0)
	cab.add_child(diadema)

func _process(delta: float) -> void:
	## Paso acotado: el primer fotograma (cargando a los operadores) puede
	## durar segundos, y la revisión se "terminaba" antes de verse.
	delta = minf(delta, 0.1)
	_t += delta
	_reloj.text = "⏱ %02d" % int(_t)
	## La cámara se acerca despacio a la pared de monitores.
	if _cam != null:
		_cam.position = _cam.position.lerp(Vector3(0.6, 1.9, 1.4), 0.25 * delta)
		_cam.look_at(Vector3(0, 1.6, -3.0), Vector3.UP)
	if _t > DURACION - 1.6 and not _decision.visible:
		_decision.visible = true
		_decision.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_decision.reset_size()
		_decision.position = (size - _decision.get_combined_minimum_size()) * 0.5
		_decision.pivot_offset = _decision.get_combined_minimum_size() * 0.5
		_decision.scale = Vector2(0.6, 0.6)
		create_tween().tween_property(_decision, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	if _t > DURACION:
		set_process(false)
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.35)
		tw.tween_callback(func() -> void:
			terminada.emit()
			queue_free())
