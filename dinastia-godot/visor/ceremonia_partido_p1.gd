extends Node
## (Parte 1 de 2 de `ceremonia_partido.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `ceremonia_partido.gd`, conserva la clase.)

## LA CEREMONIA ANTES DEL SAQUE (13-10-2026, comparación con el vídeo de FC 26:
## «presentación de ~3 minutos: túnel, niños de la mano, balón gigante,
## alineaciones»). Una versión propia, corta (~25 s) y que se salta con
## cualquier tecla o clic:
##   1. Vuelo sobre el estadio con el rótulo del partido.
##   2. Los 22 salen del túnel en dos filas, cada uno de la mano de un niño
##      con la camiseta del club, y la mascota los recibe.
##   3. Formación en el medio campo, de cara a la tribuna principal, con una
##      lona gigante con el escudo en el círculo central que ondea.
##   4. Las alineaciones: la carta de cada equipo (escudo, dibujo y nombres en
##      su sitio) mientras la cámara recorre su fila; suena el himno.
##   5. EL SORTEO DE CAMPO (17-10-2026, M-160): árbitro y capitanes en el
##      círculo central, la moneda que gira en el aire, quién elige campo y el
##      apretón de manos (≈4 s, se salta igual que el resto).
##   6. Corte al saque.
## Se reutiliza todo lo que había: los 22 del partido (`_en_campo`), la
## mascota del club (`MascotaQ`), los cuerpos de los peatones para los niños,
## los escudos (`Escudo`) y las formaciones (`Datos.FORMS`). Todo ficticio.

signal terminada

const T_VUELO := 4.5
const T_SALIDA := 10.0
const T_FILA := 5.0
const T_SORTEO := 4.2
const T_FIN := T_VUELO + T_SALIDA + T_FILA * 2.0 + T_SORTEO

var activa := false
var _ui: Control
var _raiz: Node3D
var _jugadores: Array = []        ## los dicts del partido (sin árbitros)
var _local: Club
var _visita: Club
var _nombre_estadio := ""
var _cam: Camera3D
var _previa: Camera3D
var _t := 0.0
var _ninos: Array = []           ## [{nodo, anim, de}] (de = el jugador al que acompaña)
var _guardado: Array = []        ## [nodo, transform] para devolver a todos a su sitio
var _destinos := {}              ## nodo -> [camino de puntos]
var _mascota: Node3D
var _lona: MeshInstance3D
var _rotulo: Control
var _carta: Control
var _fase := -1
var _dx := 49.0
var _dz := 68.0
var _x_boca := 0.0
var _rng := RandomNumberGenerator.new()
## La estética de quien la usa (16-10-2026: la Carrera de Jugador la pinta con
## su negro, lima y fucsia): {fondo, acento, borde}. Vacío = la del entrenador.
var _estilo := {}
## El sorteo: el árbitro principal (de `en_campo`), los dos capitanes y la moneda.
var _arbitro: Dictionary = {}
var _capitanes: Array = []
var _moneda: MeshInstance3D
var _saludo_hecho := false
var _gana_local := true

static func iniciar(ui: Control, raiz: Node3D, en_campo: Array, local: Club, visita: Club, estadio: String,
		dx: float, dz: float, x_boca: float, estilo: Dictionary = {}) -> CeremoniaPartido:
	var n := CeremoniaPartido.new()
	n._estilo = estilo
	ui.add_child(n)
	n._ui = ui
	n._raiz = raiz
	n._local = local
	n._visita = visita
	n._nombre_estadio = estadio
	n._dx = dx
	n._dz = dz
	n._x_boca = x_boca
	for p: Dictionary in en_campo:
		if not bool(p.get("arbitro", false)) and is_instance_valid(p.get("node")):
			n._jugadores.append(p)
		elif String(p.get("id", "")) == "arbitro" and is_instance_valid(p.get("node")):
			n._arbitro = p
	n._montar()
	return n

func _anim_de(ap: Variant, nombre: String) -> void:
	if ap is AnimationPlayer and is_instance_valid(ap) and (ap as AnimationPlayer).has_animation(nombre):
		if (ap as AnimationPlayer).current_animation != nombre:
			(ap as AnimationPlayer).play(nombre, 0.25)
			(ap as AnimationPlayer).speed_scale = 1.0

## Un niño con la camiseta del club (más bajo, de la mano del jugador).
func _nino(club: Club, pos: Vector3) -> Dictionary:
	var mujer := _rng.randf() < 0.45
	var d := FutbolistaQ.crear(_rng.randf_range(1.18, 1.36), "female" if mujer else "male")
	if d.is_empty():
		return {}
	var nodo: Node3D = d["nodo"]
	_raiz.add_child(nodo)
	nodo.position = pos
	nodo.rotation.y = PI
	FutbolistaQ.terminar(d, true)
	var c1 := Color(club.color1)
	var c2 := Color(club.color2)
	var piel := Color(String(PeatonQ.PIELES[_rng.randi() % PeatonQ.PIELES.size()]))
	var pelo: Color = PeatonQ.PELOS[_rng.randi() % 4]
	var kit := {"dis": "liso", "cols": [c1.to_html(false), c1.to_html(false), c2.to_html(false), "ffffff", "111111"],
		"trim": 1, "cuello": 1, "manga_corta": true,
		"pant": {"dis": "liso", "c1": c2.to_html(false), "c2": c2.to_html(false)},
		"med": {"dis": "lisas", "c1": c1.to_html(false), "c2": c1.to_html(false)},
		"bot": {"mod": "clasico", "c1": "1c1c1e", "c2": "1c1c1e", "c3": "eeeeee"}, "acc": {}, "civil": true}
	VestidorQ.vestir_equipacion(d, c1, c2, "liso", piel, pelo, c2, c1, true, kit, 0)
	PersonajeDT.adelgazar(d, false)
	var cortes: Array = PeatonQ.CORTES_M if mujer else PeatonQ.CORTES_H
	PeloQ.poner(d, String(cortes[_rng.randi() % cortes.size()]), pelo, false)
	_anim_de(d.get("anim"), "caminar")
	return {"nodo": nodo, "anim": d.get("anim")}

# ---------------------------------------------------------------- la salida

## Las dos filas salen de la boca del túnel (fondo +Z) y caminan hasta su sitio
## en el medio campo: el local en la mitad +Z, la visita en la -Z, todos de cara
## a la tribuna principal (+X). Delante de cada uno, su niño.
func _preparar_salida() -> void:
	var filas := [[], []]
	for p: Dictionary in _jugadores:
		filas[0 if bool(p["es_local"]) else 1].append(p)
	for eq in 2:
		var fila: Array = filas[eq]
		var club: Club = _local if eq == 0 else _visita
		var lado := 1.0 if eq == 0 else -1.0
		for i in fila.size():
			var p: Dictionary = fila[i]
			var nd: Node3D = p["node"]
			## Sitio final: una fila a lo largo de la banda, a 1,1 m entre ellos.
			var final := Vector3(11.0, 0, lado * (1.6 + float(i) * 1.15))
			## Salida escalonada desde la boca del túnel, en dos hileras.
			## Ya fuera del túnel, en la línea de fondo, en dos hileras (la
			## salida del túnel se ve en el plano: corto a la cancha).
			var inicio := Vector3(_x_boca + lado * 0.9, 0, 40.0 + float(i) * 1.4 + (0.0 if eq == 0 else 0.7))
			nd.position = inicio
			nd.rotation.y = PI
			_destinos[nd] = [Vector3(11.0, 0, final.z + 6.0 * lado), final]
			_anim_de(p.get("anim"), "caminar")
			var nino := _nino(club, inicio + Vector3(0.55, 0, -0.35))
			if not nino.is_empty():
				nino["de"] = nd
				_ninos.append(nino)

func _poner_mascota() -> void:
	var animal := EstadioExtras.animal_de(_local)
	_mascota = MascotaQ.crear(_raiz, _local, animal, Vector3(12.0, 0, 0.0), 90.0)

## La lona del círculo central: un disco con el escudo del local, que ondea.
func _poner_lona() -> void:
	_lona = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(17.0, 17.0)
	pm.subdivide_width = 24
	pm.subdivide_depth = 24
	_lona.mesh = pm
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D escudo : source_color, filter_linear_mipmap;
uniform vec4 fondo : source_color = vec4(0.1, 0.12, 0.3, 1.0);
uniform vec4 borde : source_color = vec4(1.0);
void vertex() {
	float r = length(VERTEX.xz);
	VERTEX.y += 0.12 * sin(r * 0.9 - TIME * 2.6) * smoothstep(0.0, 8.0, r) + 0.25 * (1.0 - smoothstep(0.0, 8.5, r)) + 0.12;
}
void fragment() {
	vec2 c = UV - 0.5;
	float r = length(c) * 2.0;
	if (r > 1.0) discard;
	vec3 col = fondo.rgb;
	if (r > 0.9) col = borde.rgb;
	vec2 uv = c * 1.9 + 0.5;
	if (uv.x > 0.0 && uv.x < 1.0 && uv.y > 0.0 && uv.y < 1.0) {
		vec4 e = texture(escudo, uv);
		col = mix(col, e.rgb, e.a);
	}
	ALBEDO = col;
	ROUGHNESS = 0.8;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("escudo", Escudo.textura(_local, 256))
	mat.set_shader_parameter("fondo", Color(_local.color1).darkened(0.25))
	mat.set_shader_parameter("borde", Color(_local.color2))
	_lona.material_override = mat
	_lona.position = Vector3(0, 0, 0)
	_lona.visible = false
	_raiz.add_child(_lona)

func _escudo(c: Club, tam: int) -> TextureRect:
	var r := TextureRect.new()
	r.texture = Escudo.textura(c, tam * 2)
	r.custom_minimum_size = Vector2(tam, tam)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return r

# ---------------------------------------------------------------- la interfaz

func _rotulo_partido() -> Control:
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(_estilo.get("fondo", Color(0.03, 0.05, 0.12, 0.88)), Tema.RADIO_GRANDE, _estilo.get("borde", Color(1, 1, 1, 0.18))))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 22)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_child(h)
	h.add_child(_escudo(_local, 72))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	var t := Tema.etiqueta(30, Tema.TEXTO, "%s  vs  %s" % [Nombres.visible(_local.nombre), Nombres.visible(_visita.nombre)])
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var s := Tema.etiqueta(15, _estilo.get("acento", Tema.ORO), Idiomas.t("En vivo desde") + " " + _nombre_estadio)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	var salta := Tema.etiqueta(11, Tema.SUAVE, Idiomas.t("Cualquier tecla para saltar"))
	salta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(salta)
	h.add_child(_escudo(_visita, 72))
	_ui.add_child(caja)
	caja.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	caja.grow_horizontal = Control.GROW_DIRECTION_BOTH
	caja.grow_vertical = Control.GROW_DIRECTION_BEGIN
	caja.offset_bottom = -54
	Animar.aparecer(caja, 0.3, 0.4)
	return caja

func _montar() -> void:
	activa = true
	_rng.seed = hash(_local.id + _visita.id)
	## La cámara del mundo del partido (puede vivir en un SubViewport, como en
	## la Carrera de Jugador: la del `ui` sería otra).
	_previa = _raiz.get_viewport().get_camera_3d()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 900.0
	_raiz.add_child(_cam)
	_cam.current = true
	for p: Dictionary in _jugadores:
		var nd: Node3D = p["node"]
		_guardado.append([nd, nd.transform])
	if not _arbitro.is_empty():
		_guardado.append([_arbitro["node"], (_arbitro["node"] as Node3D).transform])
	_preparar_salida()
	_poner_mascota()
	_poner_lona()
	_rotulo = _rotulo_partido()
	Sonido.toca("salida_tunel", Sonido.Bus.AMBIENTE)

func _quitar_rotulo() -> void:
	if is_instance_valid(_rotulo):
		var tw := _rotulo.create_tween()
		tw.tween_property(_rotulo, "modulate:a", 0.0, 0.3)
		tw.tween_callback(_rotulo.queue_free)

## Corte al saque: todos a su sitio, fuera niños, lona y carta.
func terminar() -> void:
	if not activa:
		return
	activa = false
	for g: Array in _guardado:
		var nd: Node3D = g[0]
		if is_instance_valid(nd):
			nd.transform = g[1]
	for p: Dictionary in _jugadores:
		_anim_de(p.get("anim"), "parado")
	for k: Dictionary in _ninos:
		if is_instance_valid(k.get("nodo")):
			(k["nodo"] as Node3D).queue_free()
	_ninos.clear()
	if is_instance_valid(_mascota):
		_mascota.queue_free()
	if is_instance_valid(_lona):
		_lona.queue_free()
	if is_instance_valid(_moneda):
		_moneda.queue_free()
	if not _arbitro.is_empty():
		_anim_de(_arbitro.get("anim"), "parado")
	_quitar_rotulo()
	if is_instance_valid(_carta):
		_carta.queue_free()
	if is_instance_valid(_previa):
		_previa.current = true
	if is_instance_valid(_cam):
		_cam.queue_free()
	terminada.emit()
	queue_free()

func _apellido(n: String) -> String:
	var v := Nombres.visible(n)
	var partes := v.split(" ")
	return partes[partes.size() - 1] if partes.size() > 1 else v

## LA CARTA DE ALINEACIÓN: escudo, nombre, dibujo y un campo pequeño con cada
## titular en su sitio, como en una transmisión.
func _carta_alineacion(c: Club, es_local: bool) -> Control:
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(_estilo.get("fondo", Color(0.04, 0.06, 0.16, 0.9)), Tema.RADIO_GRANDE, Color(c.color1).lightened(0.2)))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	caja.add_child(h)
	var izq := VBoxContainer.new()
	izq.alignment = BoxContainer.ALIGNMENT_CENTER
	izq.custom_minimum_size = Vector2(170, 0)
	h.add_child(izq)
	izq.add_child(_escudo(c, 110))
	var nom := Tema.etiqueta(18, Tema.TEXTO, Nombres.visible(c.nombre).to_upper())
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	izq.add_child(nom)
	var dib := Tema.etiqueta(14, _estilo.get("acento", Tema.ORO), c.tactica.formacion)
	dib.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	izq.add_child(dib)
	## El campo con los once.
	var campo := Panel.new()
	campo.custom_minimum_size = Vector2(300, 380)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.1, 0.32, 0.18, 0.9)
	st.border_color = Color(1, 1, 1, 0.35)
	st.set_border_width_all(2)
	st.set_corner_radius_all(6)
	campo.add_theme_stylebox_override("panel", st)
	h.add_child(campo)
	var linea := ColorRect.new()
	linea.color = Color(1, 1, 1, 0.3)
	linea.position = Vector2(0, 189)
	linea.size = Vector2(300, 2)
	campo.add_child(linea)
	var slots: Array = Puente3D.formacion(c.tactica.formacion).get("s", [])
	var once: Array = []
	for p: Dictionary in _jugadores:
		if bool(p["es_local"]) == es_local:
			once.append(p)
	for i in mini(once.size(), slots.size()):
		var jd: Dictionary = once[i].get("jugador", {})
		var sx := float(slots[i][1]) / 100.0
		var sy := float(slots[i][2]) / 100.0
		var punto := ColorRect.new()
		punto.color = Color(c.color1) if Color(c.color1).get_luminance() > 0.18 else Color(c.color2)
		punto.size = Vector2(14, 14)
		punto.position = Vector2(sx * 300.0 - 7.0, sy * 380.0 - 14.0)
		campo.add_child(punto)
		var et := Tema.etiqueta(11, Tema.TEXTO, "%s %s" % [str(jd.get("dorsal", "")), _apellido(String(jd.get("nombre", "")))])
		et.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		et.add_theme_constant_override("shadow_offset_y", 1)
		et.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		et.size = Vector2(120, 16)
		et.position = Vector2(sx * 300.0 - 60.0, sy * 380.0 + 1.0)
		campo.add_child(et)
	_ui.add_child(caja)
	caja.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT if es_local else Control.PRESET_CENTER_RIGHT)
	caja.grow_vertical = Control.GROW_DIRECTION_BOTH
	if es_local:
		caja.offset_left = 40
	else:
		caja.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		caja.offset_right = -40
	Animar.aparecer(caja, 0.3, 0.3)
	return caja

# ---------------------------------------------------------------- el sorteo

## El capitán de cada equipo (el del brazalete; si no hay, el de más media).
func _capitan(es_local: bool) -> Dictionary:
	var club: Club = _local if es_local else _visita
	var mejor: Dictionary = {}
	var mejor_ovr := -1
	for p: Dictionary in _jugadores:
		if bool(p["es_local"]) != es_local:
			continue
		var id := String(p.get("id", ""))
		for j: Jugador in club.plantilla:
			if j.id == id and j.capitan:
				return p
		var ovr := int((p.get("jugador", {}) as Dictionary).get("ovr", 0))
		if ovr > mejor_ovr:
			mejor_ovr = ovr
			mejor = p
	return mejor
