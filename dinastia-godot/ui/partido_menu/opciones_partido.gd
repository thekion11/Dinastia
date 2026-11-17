class_name OpcionesPartido
extends RefCounted
## LOS AJUSTES DEL PARTIDO, EN LA PANTALLA DEL MENÚ DEL PARTIDO (17-11-2026, orden del dueño): todo lo que antes se tocaba dentro del partido (el cajón de
## ajustes de la transmisión) vive ahora SOLO aquí. Cada control escribe la MISMA preferencia que ya leía el estadio al empezar (`CajonAjustes.RUTA/SECCION`),
## así que no cambia cómo se juega, solo dónde se elige. Dentro del partido quedan las ACCIONES (cámara, zoom, táctica, estadísticas, simular el resto).

const GENERALES := [["motor_real", "⚽ Motor real: el resultado se juega en el césped", true], ["indicador_pase", "🎯 Indicador de pase (a quién va el balón)", true]]
const PANTALLA := [["pantalla_esquina", "📺 Pantalla del estadio en la esquina", true], ["radar", "🗺 Radar táctico", true], ["rotulos", "📺 Rótulos de las jugadas", true],
	["vineta", "🎞 Viñeta de transmisión", true], ["pie", "ℹ Ficha del estadio abajo", false], ["intro", "🎬 Presentación antes del partido", true],
	["ceremonia", "🧒 Ceremonia completa (niños, mascota, alineaciones)", true], ["repeticiones", "🔁 Repetición de los goles", true]]
const RITMOS := [["rapido", "⏩ Partido corto"], ["normal", "⏯ Normal"], ["largo", "🐢 Largo (FC)"]]
const CAMARAS := [["cerca", "🎥 Pro: cerca"], ["normal", "Normal"], ["lejos", "Lejos"]]

static func leer(k: String, por_defecto: Variant) -> Variant:
	var cfg := ConfigFile.new()
	if cfg.load(CajonAjustes.RUTA) != OK:
		return por_defecto
	return cfg.get_value(CajonAjustes.SECCION, k, por_defecto)

static func guardar(k: String, v: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, k, v)
	cfg.save(CajonAjustes.RUTA)

static func _titulo(padre: Control, texto: String) -> void:
	var l := Tema.etiqueta(Tema.TAM_ROTULO, Tema.ORO, Idiomas.t(texto).to_upper())
	padre.add_child(l)

static func _interruptor(padre: Control, clave: String, texto: String, defecto: bool, extra := Callable()) -> void:
	var c := CheckButton.new()
	c.text = Idiomas.t(texto)
	c.button_pressed = bool(leer(clave, defecto))
	c.toggled.connect(func(si: bool) -> void:
		guardar(clave, si)
		if extra.is_valid():
			extra.call(si))
	padre.add_child(c)

## Una fila de botones de los que solo uno está activo; guarda su clave en `pref`.
static func _segmentos(padre: Control, pref: String, opciones: Array, actual: String, extra := Callable()) -> void:
	var fila := HFlowContainer.new()
	var grupo := ButtonGroup.new()
	for par: Array in opciones:
		var b := Button.new()
		b.text = Idiomas.t(String(par[1]))
		b.toggle_mode = true
		b.button_group = grupo
		b.button_pressed = String(par[0]) == actual
		var clave := String(par[0])
		b.pressed.connect(func() -> void:
			guardar(pref, clave)
			if extra.is_valid():
				extra.call(clave))
		fila.add_child(b)
	padre.add_child(fila)

static func _deslizador(padre: Control, texto: String, valor: float, al_cambiar: Callable) -> void:
	var f := HBoxContainer.new()
	var l := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, Idiomas.t(texto))
	l.custom_minimum_size = Vector2(260, 0)
	f.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = valor
	s.custom_minimum_size = Vector2(260, 24)
	s.value_changed.connect(al_cambiar)
	f.add_child(s)
	padre.add_child(f)

## Todos los ajustes del partido (menos la cámara, que tiene su pestaña).
static func construir(padre: VBoxContainer) -> void:
	_titulo(padre, "Partido")
	for g: Array in GENERALES:
		_interruptor(padre, String(g[0]), String(g[1]), bool(g[2]))
	_segmentos(padre, "ritmo_partido", RITMOS, String(leer("ritmo_partido", "normal")))
	padre.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, Idiomas.t("Dificultad de la CPU")))
	var dif: Array = []
	for k: String in MotorJugable.ORDEN_DIFICULTAD:
		dif.append([k, String(MotorJugable.DIFICULTADES[k]["nombre"])])
	_segmentos(padre, "dificultad_cpu8", dif, VistaEstadio.dificultad_cpu_guardada())
	padre.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, Idiomas.t("Estilo de juego")))
	var pre: Array = []
	for k: String in MotorJugable.ORDEN_PRESETS:
		pre.append([k, String(MotorJugable.PRESETS[k]["nombre"])])
	_segmentos(padre, "preset_juego", pre, VistaEstadio.preset_guardado())
	_titulo(padre, "En pantalla")
	_interruptor(padre, "nombres", "🏷 Nombres de los jugadores", PlayerSpawner.mostrar_nombres, func(si: bool) -> void: PlayerSpawner.mostrar_nombres = si)
	for g: Array in PANTALLA:
		_interruptor(padre, String(g[0]), String(g[1]), bool(g[2]))
	_interruptor(padre, "calidad_auto", "⚡ Calidad automática", Calidad.adaptativa, func(si: bool) -> void: Calidad.adaptativa = si)
	_titulo(padre, "Sonido")
	_deslizador(padre, "Grada y ambiente", float(Sonido.volumen.get(Sonido.Bus.AMBIENTE, 0.5)), func(v: float) -> void: Sonido.volumen[Sonido.Bus.AMBIENTE] = v)
	_deslizador(padre, "Efectos (balón, silbato)", float(Sonido.volumen.get(Sonido.Bus.EFECTOS, 0.8)), func(v: float) -> void: Sonido.volumen[Sonido.Bus.EFECTOS] = v)
	_deslizador(padre, "Música", Musica.volumen, func(v: float) -> void:
		Musica.volumen = v
		Musica.aplicar_volumen())

## La pestaña Cámara: la distancia de la cámara «Pro».
static func construir_camara(padre: VBoxContainer) -> void:
	_titulo(padre, "Cámara")
	padre.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, Idiomas.t("Distancia de la cámara Pro (la de jugar). Dentro del partido se cambia de cámara y se acerca o aleja con los botones del cajón.")))
	_segmentos(padre, "pro_camara", CAMARAS, VistaEstadio.pro_camara_guardada())
