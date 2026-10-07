class_name PresentacionFichaje
extends Control
## LA PRESENTACIÓN DE UN FICHAJE (26-9-2026, plan maestro C7). Pedido: *"presentación
## de jugadores"*. Hasta hoy un fichaje era una línea en el registro. Ahora
## sale su cara junto a TU camiseta con su dorsal, de dónde viene, y eliges cómo
## presentarlo:
##   - EN EL ESTADIO, con la hinchada: cuesta dinero, sube el ánimo y trae
##     seguidores (más cuanto mejor es el jugador);
##   - en la SALA DE PRENSA: gratis y discreto.
## Es una decisión de verdad: presentar a lo grande a un suplente se lee como
## propaganda, y la hinchada responde menos.

signal cerrado

var _j: Jugador
var _mundo: Mundo
var _de: Club

static func coste_estadio(c: Club) -> int:
	## Montar el escenario, la seguridad y la pantalla: poco al lado de un
	## traspaso (con 60.000 de base un club grande pagaba casi 3 millones).
	return Eco.escalar(15000.0, float(c.rep))

static func mostrar(padre: Control, mundo: Mundo, j: Jugador, de: Club) -> PresentacionFichaje:
	var n := PresentacionFichaje.new()
	n._j = j
	n._de = de
	n._mundo = mundo
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(n)
	n._montar(de)
	return n

func _montar(de: Club) -> void:
	var mio := _mundo.mi_club()
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.78)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Tema.PANEL, Tema.RADIO_GRANDE, Tema.ORO))
	caja.custom_minimum_size = Vector2(620, 0)
	centro.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Tema.ESPACIO)
	caja.add_child(v)
	v.add_child(Tema.rotulo("✍️ Nuevo fichaje · %s" % Nombres.visible(mio.nombre)))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(h)
	var cara := TextureRect.new()
	cara.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cara.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cara.texture = Cara.textura(_j, mio.color1, mio.color2, 160)
	cara.custom_minimum_size = Vector2(160, 160)
	h.add_child(cara)
	var camiseta := TextureRect.new()
	camiseta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	camiseta.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var img := Image.new()
	if img.load_svg_from_string(Jersey.svg_de(mio.color_kit1(), mio.color_kit2(), Jersey.kit_de(mio, mio.kit_estilo), maxi(_j.dorsal, 1)), 2.4) == OK:
		camiseta.texture = ImageTexture.create_from_image(img)
	camiseta.custom_minimum_size = Vector2(150, 160)
	## Sobre fondo claro: una camiseta negra sobre el panel oscuro no se veía.
	var fondo_cam := PanelContainer.new()
	fondo_cam.add_theme_stylebox_override("panel", Tema.caja(Color(0.86, 0.88, 0.9), Tema.RADIO, Color(1, 1, 1, 0.4)))
	fondo_cam.add_child(camiseta)
	h.add_child(fondo_cam)
	var nombre := Tema.etiqueta(Tema.TAM_TITULO + 4, Tema.TEXTO, _j.nombre)
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nombre)
	var ficha := Tema.etiqueta(Tema.TAM_CUERPO, Tema.ORO, "%s · %d años · media %d · dorsal %d%s" % [
		_j.pos_e, _j.edad, _j.ovr, _j.dorsal, ("  ·  llega desde %s" % Nombres.visible(de.nombre)) if de != null else "  ·  llega libre"])
	ficha.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(ficha)
	var coste := coste_estadio(mio)
	var b1 := Button.new()
	b1.text = "🏟️ Presentarlo en el estadio, con la hinchada  ·  %s" % Cesiones.dinero(coste)
	b1.disabled = coste > mio.saldo
	b1.custom_minimum_size = Vector2(0, 40)
	b1.pressed.connect(_presentar.bind(true))
	v.add_child(b1)
	var b2 := Button.new()
	b2.text = "🎙️ Presentación sencilla en la sala de prensa"
	b2.custom_minimum_size = Vector2(0, 40)
	b2.pressed.connect(_presentar.bind(false))
	v.add_child(b2)
	Animar.aparecer(caja, 0.0, 0.35)
	Sonido.toca("fichaje" if Sonido.NOMBRES.has("fichaje") else "cambio", Sonido.Bus.INTERFAZ)

## Aplica la presentación. Pública para el banco de pruebas.
static func aplicar(mundo: Mundo, j: Jugador, en_estadio: bool) -> Dictionary:
	var mio := mundo.mi_club()
	var media_plantel := mio.media()
	var estrella := float(j.ovr) >= media_plantel + 3.0
	var animo := 0
	var seguidores := 0
	var texto := ""
	if en_estadio:
		var coste := coste_estadio(mio)
		mio.mover_saldo(-coste)
		mundo._anotar_movimiento("Presentación de %s en el estadio" % j.nombre, -coste)
		animo = 4 if estrella else 1
		seguidores = int(float(j.ovr) * (40.0 if estrella else 12.0))
		texto = "Miles de hinchas en la grada para ver a %s con la camiseta y dar toques al balón." % j.nombre if estrella \
			else "La grada, a medio llenar: presentar así a un jugador de rotación se leyó como propaganda."
	else:
		animo = 1 if estrella else 0
		seguidores = int(float(j.ovr) * 4.0)
		texto = "Foto con la camiseta, cuatro preguntas y a entrenar. Sin ruido."
	if mundo.prensa != null:
		mundo.prensa.mover_animo(animo)
		mundo.prensa.seguidores += seguidores
		mundo.prensa.noticia.emit("✍️ Presentación de %s" % j.nombre, "%s (+%d seguidores)" % [texto, seguidores])
	j.moral = clampi(j.moral + (6 if en_estadio else 3), 10, 99)
	return {"animo": animo, "seguidores": seguidores, "texto": texto}

func _presentar(en_estadio: bool) -> void:
	var estrella := float(_j.ovr) >= _mundo.mi_club().media() + 3.0
	aplicar(_mundo, _j, en_estadio)
	## En el estadio se VE (mapa de metas 13): la cinemática con tu estadio y el
	## jugador en el círculo central; la tarjeta se cierra al acabar.
	if en_estadio and get_parent() is Control and DisplayServer.get_name() != "headless":
		visible = false
		var cin := CinematicaFichaje.mostrar(get_parent(), _mundo, _j, _de, estrella)
		cin.terminada.connect(func() -> void:
			cerrado.emit()
			queue_free())
		return
	cerrado.emit()
	queue_free()
