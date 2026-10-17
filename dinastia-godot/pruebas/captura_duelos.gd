extends Node
## LOS DUELOS VISTOS CON LA CÁMARA DE TRANSMISIÓN (16-10-2026). Partido con el
## motor real y la cámara del partido de siempre (no una de prueba): cuando
## salta un duelo (hombro, balón dividido o agarrón) saca la imagen tal cual
## la ve el jugador y, al lado, un recorte ampliado de la zona del choque.
## Salida: pruebas/capturas/duelos.png (→ JPG con captura.sh), una fila por duelo.
##   herramientas/captura.sh res://pruebas/captura_duelos.tscn
const FILAS := 4
var _vista: VistaEstadio
var _antes := {}
var _pend: Dictionary = {}
var _filas: Array = []
var _tipos := {}
var _n := 0

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", false)
	cfg.save(CajonAjustes.RUTA)
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	Partido.ctx_club_id = m.mi_club_id
	var par := m.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], partido)

func _process(_d: float) -> void:
	_n += 1
	var intro: Variant = _vista.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
	var cer: Variant = _vista.get("_ceremonia")
	if cer != null and is_instance_valid(cer) and cer.activa:
		cer.terminar()
	var motor: MotorJugable = _vista.get("_motor")
	if motor == null or _n < 30:
		return
	if _n > 9000:
		_guardar()
		return
	if not _pend.is_empty():
		## Unas décimas después del choque, con el gesto en marcha.
		if motor.t >= float(_pend["t"]) + 0.28 or motor.mitad != int(_pend["mitad"]):
			_foto(motor)
		return
	Engine.time_scale = 3.0
	for k: String in ["hombro", "dividido", "agarron"]:
		var v := int(motor.duelos.get(k, 0))
		if v > int(_antes.get(k, 0)) and int(_tipos.get(k, 0)) < 2:
			var dos: Array = []
			for p: Dictionary in motor.jugadores:
				if float(p.get("contacto_hasta", 0.0)) > motor.t + 0.8:
					dos.append(p)
			if dos.size() >= 2:
				Engine.time_scale = 1.0
				_pend = {"tipo": k, "a": dos[0], "b": dos[1], "t": motor.t, "mitad": motor.mitad}
		_antes[k] = v
		if not _pend.is_empty():
			break

func _foto(motor: MotorJugable) -> void:
	var cam := get_viewport().get_camera_3d()
	var img := get_viewport().get_texture().get_image()
	var a: Dictionary = _pend["a"]
	var b: Dictionary = _pend["b"]
	## Posición GLOBAL (los nodos cuelgan de la raíz del estadio).
	var medio := ((a["node"] as Node3D).global_position + (b["node"] as Node3D).global_position) * 0.5 + Vector3(0, 0.9, 0)
	var en_pantalla := cam != null and not cam.is_position_behind(medio)
	var w := img.get_width()
	var h := img.get_height()
	## `unproject_position` da coordenadas del viewport lógico (1280×720 con
	## stretch «canvas_items»); la imagen sale a la resolución de la ventana.
	var escala := float(w) / maxf(get_viewport().get_visible_rect().size.x, 1.0)
	var pt := cam.unproject_position(medio) * escala if en_pantalla else Vector2(w / 2.0, h / 2.0)
	var cw := w / 5
	var ch := h / 5
	var rx := clampi(int(pt.x) - cw / 2, 0, w - cw)
	var ry := clampi(int(pt.y) - ch / 2, 0, h - ch)
	var recorte := img.get_region(Rect2i(rx, ry, cw, ch))
	recorte.resize(640, 360, Image.INTERPOLATE_LANCZOS)
	## Marco del recorte en la imagen completa.
	for x in range(rx, rx + cw):
		for g in 3:
			img.set_pixel(x, mini(ry + g, h - 1), Color(1, 0.85, 0.1))
			img.set_pixel(x, mini(ry + ch - 1 - g, h - 1), Color(1, 0.85, 0.1))
	for y in range(ry, ry + ch):
		for g in 3:
			img.set_pixel(mini(rx + g, w - 1), y, Color(1, 0.85, 0.1))
			img.set_pixel(mini(rx + cw - 1 - g, w - 1), y, Color(1, 0.85, 0.1))
	img.resize(640, 360, Image.INTERPOLATE_LANCZOS)
	_filas.append([img, recorte])
	var k := String(_pend["tipo"])
	_tipos[k] = int(_tipos.get(k, 0)) + 1
	print("DUELO %d %s en (%.1f, %.1f) minuto %d: %s [%s] vs %s [%s]%s" % [_filas.size(), k, medio.x, medio.z, motor.minuto(),
		String(a.get("slot_code", "")), String(a.get("anim_actual", "")), String(b.get("slot_code", "")), String(b.get("anim_actual", "")),
		"" if en_pantalla else " (fuera de cámara)"])
	_pend = {}
	if _filas.size() >= FILAS:
		_guardar()

func _guardar() -> void:
	Engine.time_scale = 1.0
	if _filas.is_empty():
		print("SIN DUELOS")
		get_tree().quit(1)
		return
	var hoja := Image.create(1280, 360 * _filas.size(), false, (_filas[0][0] as Image).get_format())
	for i in _filas.size():
		for j in 2:
			var im: Image = _filas[i][j]
			im.convert(hoja.get_format())
			hoja.blit_rect(im, Rect2i(0, 0, 640, 360), Vector2i(j * 640, i * 360))
	hoja.save_png("res://pruebas/capturas/duelos.png")
	print("HOJA guardada: %d duelos" % _filas.size())
	get_tree().quit()
