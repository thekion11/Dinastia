class_name CartaGoleador
extends Control
## LA CARTA DEL GOLEADOR (14-10-2026, pedido: «cuando un jugador marca sale
## como una carta con la cara del modelo 3D, eso deberíamos tenerlo»). Como en
## la transmisión de FC 26 (visto en el vídeo, 5:21): abajo a la izquierda, el
## escudo, una banda del color del club que se despliega, el dorsal y el nombre
## completo, «TIROS n  GOLES n» y, asomando por la derecha, el propio jugador en
## 3D -el mismo modelo, con su cara y su camiseta- celebrando. El retrato es un
## `SubViewport` con mundo propio y una copia del nodo del jugador.

signal terminada

const ANCHO := 560.0
const ALTO := 78.0
const DURACION := 3.6

var _banda: Panel
var _textos: Control
var _retrato: TextureRect
var _vp: SubViewport

## `nodo`: el jugador en el campo (se copia). `color`: el del club.
static func mostrar(padre: Control, club: Club, dorsal: int, nombre: String, tiros: int, goles: int, nodo: Node3D) -> CartaGoleador:
	var c := CartaGoleador.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.z_index = 40
	padre.add_child(c)
	c.size = Vector2(ANCHO + 140, ALTO + 70)
	c.global_position = Vector2(48, padre.get_viewport_rect().size.y - ALTO - 150)
	c._montar(club, dorsal, nombre, tiros, goles, nodo)
	return c

func _montar(club: Club, dorsal: int, nombre: String, tiros: int, goles: int, nodo: Node3D) -> void:
	var col := Color(club.color1) if club != null else Color("1f3fbf")
	## Un color muy claro (camiseta blanca) no deja leer el texto blanco.
	if col.get_luminance() > 0.6:
		col = Color(club.color2) if club != null and Color(club.color2).get_luminance() < 0.6 else Color("1f3fbf")
	## Banda: degradado del color del club, con un filo claro arriba.
	_banda = Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = col.darkened(0.25)
	sb.border_color = col.lightened(0.45)
	sb.border_width_top = 3
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 8
	_banda.add_theme_stylebox_override("panel", sb)
	_banda.position = Vector2(30, 70)
	_banda.size = Vector2(0, ALTO)
	_banda.clip_contents = true
	add_child(_banda)
	var brillo := TextureRect.new()
	var gt := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(col.lightened(0.15), 0.0))
	g.set_color(1, Color(col.lightened(0.25), 0.55))
	gt.gradient = g
	gt.width = 64
	gt.height = 8
	brillo.texture = gt
	brillo.stretch_mode = TextureRect.STRETCH_SCALE
	brillo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banda.add_child(brillo)
	## Textos.
	_textos = Control.new()
	_textos.position = Vector2(56, 6)
	_textos.modulate.a = 0.0
	_banda.add_child(_textos)
	var t1 := Tema.etiqueta(22, Color.WHITE, ("%d  " % dorsal if dorsal > 0 else "") + Nombres.visible(nombre).to_upper())
	t1.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	t1.add_theme_constant_override("shadow_offset_y", 1)
	_textos.add_child(t1)
	var fila := HBoxContainer.new()
	fila.position = Vector2(0, 36)
	fila.add_theme_constant_override("separation", 6)
	_textos.add_child(fila)
	for par: Array in [[Idiomas.t("TIROS"), tiros], [Idiomas.t("GOLES"), goles]]:
		fila.add_child(Tema.etiqueta(17, Color(1, 1, 1, 0.82), String(par[0])))
		fila.add_child(Tema.etiqueta(17, Color("8fd3ff"), str(int(par[1])) + "   "))
	## Escudo a la izquierda, por encima de la banda.
	if club != null:
		var esc := TextureRect.new()
		esc.texture = Escudo.textura(club, 64)
		esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		esc.size = Vector2(62, 62)
		esc.position = Vector2(0, 70 + (ALTO - 62) * 0.5)
		add_child(esc)
	## El retrato 3D, asomando por la derecha.
	_retrato = TextureRect.new()
	_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_retrato.stretch_mode = TextureRect.STRETCH_SCALE
	_retrato.size = Vector2(150, 150)
	_retrato.position = Vector2(30 + ANCHO - 150, 70 + ALTO - 150)
	_retrato.modulate.a = 0.0
	add_child(_retrato)
	_montar_retrato(nodo)
	## Entrada: la banda se despliega, luego los textos y el jugador; salida
	## al revés.
	var tw := create_tween()
	tw.tween_property(_banda, "size:x", ANCHO, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_textos, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(_retrato, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(_retrato, "position:y", _retrato.position.y - 10.0, 0.25).from(_retrato.position.y + 20.0)
	tw.tween_interval(DURACION)
	tw.tween_property(_textos, "modulate:a", 0.0, 0.15)
	tw.parallel().tween_property(_retrato, "modulate:a", 0.0, 0.15)
	tw.tween_property(_banda, "size:x", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		terminada.emit()
		queue_free())

func _montar_retrato(nodo: Node3D) -> void:
	if not is_instance_valid(nodo):
		return
	_vp = SubViewport.new()
	_vp.size = Vector2i(300, 300)
	_vp.transparent_bg = true
	_vp.own_world_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var copia := nodo.duplicate() as Node3D
	if copia == null:
		return
	## Sin rótulos ni nada que no sea el cuerpo.
	for l in copia.find_children("*", "Label3D", true, false):
		l.queue_free()
	for s in copia.find_children("*", "Sprite3D", true, false):
		s.queue_free()
	copia.transform = Transform3D.IDENTITY
	_vp.add_child(copia)
	var amb := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.78, 0.85)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	amb.environment = env
	_vp.add_child(amb)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-35, 30, 0)
	sol.light_energy = 1.3
	_vp.add_child(sol)
	var contra := DirectionalLight3D.new()
	contra.rotation_degrees = Vector3(-20, 200, 0)
	contra.light_energy = 0.6
	_vp.add_child(contra)
	var cam := Camera3D.new()
	cam.fov = 26.0
	_vp.add_child(cam)
	var alto := 1.8
	var esq := copia.find_children("*", "Skeleton3D", true, false)
	if not esq.is_empty():
		var sk := esq[0] as Skeleton3D
		var h := sk.find_bone("head")
		if h < 0:
			h = sk.find_bone("Head")
		if h >= 0:
			alto = (sk.global_transform * sk.get_bone_global_rest(h)).origin.y + 0.1 if sk.is_inside_tree() else alto
	## De la cintura para arriba, como el recorte de la tele.
	cam.position = Vector3(0.22, alto - 0.3, 1.75)
	cam.look_at(Vector3(0, alto - 0.42, 0), Vector3.UP)
	## Un gesto de celebración, si lo tiene.
	var aps := copia.find_children("*", "AnimationPlayer", true, false)
	if not aps.is_empty():
		var ap := aps[0] as AnimationPlayer
		for g: String in ["puno_al_aire", "senalar_cielo", "celebrar", "aplaudir", "parado"]:
			if ap.has_animation(g):
				ap.play(g)
				break
	_retrato.texture = _vp.get_texture()
