class_name EventoReflexion
extends EventoPantallaCompleta
## PANTALLA COMPLETA DE REFLEXIÓN (16-11, orden del dueño): el día de memoria de tu país (`DiasMemoria`). Sobria, sin música ni colores de fiesta:
## una vela, «DÍA DE MEMORIA · PAÍS», el nombre del día y su fecha, una frase para pensar y un minuto de silencio (la barra se llena sola en
## `SILENCIO` s; con «Animaciones reducidas» aparece llena). El botón de seguir está siempre a mano: nadie queda atrapado. Emite `elegido("0")`.
const SILENCIO := 12.0   ## s que tarda la barra del minuto de silencio (simbólico: el evento es breve)
const VELA := Color("f2c46d")
var barra: ProgressBar

static func mostrar(pr: Principal, ev: Dictionary) -> EventoReflexion:
	var e := EventoReflexion.new()
	e.paleta_noche = true
	e.acento = Color(VELA, 0.55)
	e._montar_base(pr)
	e._rellenar(ev)
	return e

func _rellenar(ev: Dictionary) -> void:
	_centro.custom_minimum_size = Vector2(ancho_base(760.0), 0)
	_centro.add_theme_constant_override("separation", 14)
	var vela := etiqueta("🕯️", 64, VELA)
	var pais := etiqueta("%s · %s" % [Idiomas.t("DÍA DE MEMORIA"), PersonajeDatos.nombre_pais(String(ev.get("pais", ""))).to_upper()], 14, Color(SelectorDireccional.BLANCO, 0.6))
	var titulo := etiqueta(Idiomas.t(String(ev.get("nombre", ""))), 34, SelectorDireccional.BLANCO)
	var cuando := "%d de %s" % [int(ev.get("dia", 1)), Principal.MESES_LARGOS[clampi(int(ev.get("mes", 1)) - 1, 0, 11)]]
	var fecha := etiqueta(Idiomas.t(cuando), 16, Color(VELA, 0.85))
	var raya := ColorRect.new()
	raya.color = Color(VELA, 0.45)
	raya.custom_minimum_size = Vector2(120, 2)
	raya.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var frase := etiqueta("«%s»" % Idiomas.t(String(ev.get("reflexion", ""))), 22, Color(SelectorDireccional.BLANCO, 0.92))
	frase.custom_minimum_size = Vector2(ancho_base(640.0), 0)
	frase.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var silencio := etiqueta(Idiomas.t("Un minuto de silencio"), 14, Color(SelectorDireccional.BLANCO, 0.6))
	barra = ProgressBar.new()
	barra.show_percentage = false
	barra.max_value = 1.0
	barra.custom_minimum_size = Vector2(ancho_base(360.0) * 0.6, 6)
	barra.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var fondo := Tema.caja(Color(1, 1, 1, 0.10), 3)
	var relleno := Tema.caja(Color(VELA, 0.85), 3)
	barra.add_theme_stylebox_override("background", fondo)
	barra.add_theme_stylebox_override("fill", relleno)
	var seguir := boton(Idiomas.t("Continuar"), true)
	seguir.custom_minimum_size = Vector2(240, 58)
	seguir.pressed.connect(func() -> void: elegido.emit("0"))
	for n: Control in [vela, pais, titulo, fecha, raya, frase, silencio, barra]:
		_centro.add_child(n)
	fijar_abajo(seguir)
	if Animar.reducidas():
		barra.value = 1.0
	else:
		create_tween().tween_property(barra, "value", 1.0, SILENCIO)
		entrada_en_cascada([vela, pais, titulo, fecha, raya, frase, silencio, barra], 0.2, 0.28)
