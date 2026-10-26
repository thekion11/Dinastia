extends BaseIdea
## FASE 1, etapa 0: LA INTRO DE MARCA (`ui/entrada/intro.gd`, clase `IntroMarca`). Se mueve su
## reloj a mano, a 60 fotogramas por segundo simulados: lo que se prueba es la partitura y el
## contrato, no la velocidad de esta máquina.

const PASO := 1.0 / 60.0

var _avisos := 0
var _datos: Variant = null
var _t_aviso := -1.0
var _vueltas := 0
var _actual: IntroMarca

func _probar() -> void:
	_titulo("FASE 1 · etapa 0: intro de marca (IntroMarca)")
	var azar_antes: int = Azar._rng.state
	_primera_vez()
	_ya_vista()
	_tope_real()
	_maqueta()
	_comprobar(Azar._rng.state == azar_antes, "ver la intro no consume ni un número de Azar (no cambia la partida)")

func _nueva(estado: Dictionary) -> IntroMarca:
	var a := IntroMarca.new()
	a.configurar(estado)
	add_child(a)
	_actual = a
	_avisos = 0
	_datos = null
	_t_aviso = -1.0
	_vueltas = 0
	a.terminado.connect(_al_terminar)
	a.volver.connect(func() -> void: _vueltas += 1)
	return a

func _al_terminar(d: Dictionary) -> void:
	_avisos += 1
	_datos = d
	_t_aviso = _actual.tiempo()

## Corre la intro hasta que termine (o 10 s simulados como mucho).
func _correr(a: IntroMarca) -> void:
	var n := 0
	while not a.acabada() and n < 600:
		a.avanzar(PASO)
		n += 1

static func _tecla() -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = KEY_SPACE
	e.pressed = true
	return e

static func _clic() -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	return e

static func _mando() -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = JOY_BUTTON_A
	e.pressed = true
	return e

static func _toque() -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.pressed = true
	return e

func _primera_vez() -> void:
	var a := _nueva({})
	_comprobar(a.has_signal("terminado") and a.has_signal("volver") and a.has_method("configurar"),
		"cumple el contrato de la entrada (terminado, volver, configurar)")
	_comprobar(a.size == get_viewport().get_visible_rect().size, "colgada de un Node suelto, ocupa la ventana entera (%s)" % str(a.size))
	## Como la monta el orquestador: dentro de un Control a pantalla completa.
	var marco := Control.new()
	marco.size = Vector2(1280, 720)
	add_child(marco)
	var x := IntroMarca.new()
	marco.add_child(x)
	## El reparto por anclas se aplica al cambiar el padre de tamaño (como al girar el móvil).
	marco.size = Vector2(1366, 768)
	_comprobar(x.anchor_left == 0.0 and x.anchor_top == 0.0 and x.anchor_right == 1.0 and x.anchor_bottom == 1.0
		and x.size == marco.size, "dentro de un Control va a pantalla completa por anclas (%s)" % str(x.size))
	marco.queue_free()
	_comprobar(a.mouse_filter == Control.MOUSE_FILTER_STOP, "tapa los clics de lo que haya debajo")
	_comprobar(load("res://ui/entrada/orquestador.gd") != null and OrquestadorEntrada.ETAPAS[0]["ruta"] == a.get_script().resource_path,
		"está donde la busca el orquestador (%s)" % a.get_script().resource_path)
	a.avanzar(0.6)
	for e: InputEvent in [_tecla(), _clic(), _mando(), _toque()]:
		a._input(e)
	a.avanzar(0.5)
	_comprobar(not a.acabada() and not a.se_puede_saltar(), "la primera vez NO se salta (tecla, clic, mando, toque)")
	_correr(a)
	_comprobar(_avisos == 1, "al acabar emite «terminado» (una vez: %d)" % _avisos)
	_comprobar(_datos is Dictionary and (_datos as Dictionary).is_empty(), "y lo emite con {} (la intro no elige nada)")
	_comprobar(_t_aviso > 4.0 and _t_aviso <= 5.0, "dura ≤ 5 s (%.2f s simulados a 60 fps)" % _t_aviso)
	for i in 120:
		a.avanzar(PASO)
	a._input(_tecla())
	_comprobar(_avisos == 1, "no lo vuelve a emitir aunque siga recibiendo fotogramas o teclas")
	_comprobar(_vueltas == 0, "nunca pide «volver» (es la primera etapa)")
	## Congelar para las capturas no la termina ni la mueve.
	var b := _nueva({})
	b.fijar_tiempo(2.55)
	b._process(PASO)
	_comprobar(not b.acabada() and is_equal_approx(b.tiempo(), 2.55), "fijar_tiempo congela la intro en un instante (capturas)")
	a.queue_free()
	b.queue_free()

func _ya_vista() -> void:
	var nombres := ["tecla", "clic", "botón del mando", "toque"]
	var eventos: Array[InputEvent] = [_tecla(), _clic(), _mando(), _toque()]
	for i in eventos.size():
		var a := _nueva({"intro_vista": true})
		a.avanzar(0.8)
		var t0 := a.tiempo()
		a._input(eventos[i])
		_correr(a)
		_comprobar(_avisos == 1 and a.acabada() and _t_aviso - t0 <= 0.35,
			"ya vista: un %s la salta con un fundido corto (%.2f s)" % [nombres[i], _t_aviso - t0])
		a.queue_free()
	## Una tecla que se repite (mantenida) no cuenta como pulsación.
	var b := _nueva({"intro_vista": true})
	var eco := _tecla()
	eco.echo = true
	b._input(eco)
	b.avanzar(0.5)
	_comprobar(not b.acabada(), "una tecla mantenida (eco) no la salta")
	b.queue_free()

## Si la máquina va a tirones, el delta recortado alargaría la intro: el tope en tiempo real
## la cierra igual (y antes funde, para que no sea un corte).
func _tope_real() -> void:
	var a := _nueva({})
	a.avanzar(1.0)
	a._inicio_ms -= 4800
	a._process(PASO)
	_comprobar(not a.acabada() and a._t_salto >= 0.0, "a punto del tope real empieza a fundir")
	a._inicio_ms -= 300
	a._process(PASO)
	_comprobar(a.acabada() and _avisos == 1, "a los 5 s reales termina sí o sí")
	a.queue_free()

## La marca cabe en un PC apaisado y en un móvil en vertical.
func _maqueta() -> void:
	for tam: Vector2 in [Vector2(1280, 720), Vector2(720, 1280), Vector2(2560, 1080)]:
		var a := _nueva({})
		a.size = tam
		a.fijar_tiempo(3.7)
		var cabe: bool = a._ancho_palabra <= tam.x * 0.87 and a._fs > 20.0
		var arriba: float = a._ce.y - a._we * (IntroMarca.ESCUDO_ALTO * 0.5 + 0.25)
		var abajo: float = a._c.y + a._cap * 0.5 + a._fs * 0.5 + a._fs_lema
		_comprobar(cabe and arriba > 0.0 and abajo < tam.y, "la marca cabe entera en %dx%d" % [int(tam.x), int(tam.y)])
		_comprobar(a._nombre != "" and a._lema != "", "con sus textos (traducidos con Idiomas.t)")
		a.queue_free()
