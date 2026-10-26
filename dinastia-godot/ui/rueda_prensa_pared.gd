class_name ParedPrensa
extends RefCounted
## LA PARED DE PATROCINADORES DE LA RUEDA DE PRENSA, según el contexto
## (26-10, pedido del dueño). Sale de `RuedaPrensaEscena3D` (capa 1) para no
## pasar de 450 líneas.
##
## Es un «step and repeat» en damero, pintado en un `SubViewport` -única forma
## de tener escudos y logos nítidos en 3D- sobre un panel de 5,4×1,7 m detrás
## del atril. Lo que se repite depende de `contexto["tipo"]`:
##   - "general" (presentación, rueda sin competición): escudo y nombre del club;
##   - "competicion": escudo del club y logo de la competición
##     (`LogoCompeticion`) de `contexto["competicion"]`;
##   - "previa": los escudos de los dos clubes (`contexto["rival"]`).
## El fondo es el color real del club (aclarado si es muy oscuro) con un halo
## detrás del DT. Las iniciales de los escudos van en un `Label` encima: el SVG
## del escudo no dibuja texto y sin ellas salían aros vacíos.

const FILAS := 4
const COLS := 8
const CELDA := Vector2(190, 120)

static func montar(escena: Node3D, club: Club, acento: Color, contexto: Dictionary = {}) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(2000, 700)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	escena.add_child(vp)
	var col1 := Color.from_string(club.color1, acento) if club != null else acento
	var col2 := Color.from_string(club.color2, Color.WHITE) if club != null else Color.WHITE
	var fondo := ColorRect.new()
	fondo.color = col1 if col1.get_luminance() >= 0.22 else col1.lerp(col2, 0.3)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp.add_child(fondo)
	var halo := TextureRect.new()
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.55)
	gt.fill_to = Vector2(0.5, 1.25)
	var gr := Gradient.new()
	gr.set_color(0, Color(col1.lightened(0.35), 0.55))
	gr.set_color(1, Color(col1, 0.0))
	gt.gradient = gr
	halo.texture = gt
	halo.set_anchors_preset(Control.PRESET_FULL_RECT)
	halo.stretch_mode = TextureRect.STRETCH_SCALE
	vp.add_child(halo)
	var grid := GridContainer.new()
	grid.columns = COLS
	grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 40)
	grid.offset_left = 40.0; grid.offset_top = 40.0
	vp.add_child(grid)
	var tipo := String(contexto.get("tipo", "general"))
	var comp := String(contexto.get("competicion", ""))
	var rival: Club = contexto.get("rival") as Club
	for i in FILAS * COLS:
		var par := (i + int(i / COLS)) % 2 == 0
		if par:
			grid.add_child(_escudo(club))
		elif tipo == "competicion" and comp != "":
			grid.add_child(_logo(comp))
		elif tipo == "previa" and rival != null:
			grid.add_child(_escudo(rival))
		else:
			grid.add_child(_nombre(club, col2))
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 1.2
	var tex := vp.get_texture()
	mat.albedo_texture = tex
	mat.emission_texture = tex
	var quad := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(5.4, 1.7)
	quad.mesh = q
	quad.material_override = mat
	quad.position = Vector3(0, 1.55, -1.6)
	escena.add_child(quad)

static func _escudo(c: Club) -> Control:
	var celda := TextureRect.new()
	celda.custom_minimum_size = CELDA
	celda.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	celda.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if c == null:
		return celda
	celda.texture = Escudo.textura(c, 110)
	var ini := Label.new()
	ini.text = Escudo.iniciales(c)
	ini.set_anchors_preset(Control.PRESET_FULL_RECT)
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ini.add_theme_font_size_override("font_size", 40)
	ini.add_theme_color_override("font_color", Color.from_string(c.color_escudo2(), Color.WHITE))
	celda.add_child(ini)
	return celda

static func _logo(comp: String) -> Control:
	var caja := CenterContainer.new()
	caja.custom_minimum_size = CELDA
	caja.add_child(LogoCompeticion.control(comp, 112))
	return caja

static func _nombre(c: Club, col: Color) -> Control:
	var nom := Label.new()
	nom.custom_minimum_size = CELDA
	nom.text = c.nombre.to_upper() if c != null else ""
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nom.add_theme_font_size_override("font_size", 30)
	nom.add_theme_color_override("font_color", Color(col, 0.95))
	return nom
