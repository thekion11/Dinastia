class_name EventoReflexion
extends EventoPantallaCompleta
## PANTALLA COMPLETA DE REFLEXIÓN (16-11, orden del dueño): el día de memoria de tu país (y, desde el 17-11, su día de la independencia, en tono festivo y sin silencio) (`DiasMemoria`). Sobria, sin música ni colores de fiesta:
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
	var fiesta := String(ev.get("tipo", "memoria")) == "independencia"   ## (17-11) el día de la independencia: mismo marco, tono de celebración
	_centro.custom_minimum_size = Vector2(ancho_base(760.0), 0)
	_centro.add_theme_constant_override("separation", 14)
	var vela := etiqueta("🎆" if fiesta else "🕯️", 64, VELA)
	var cab := Idiomas.t("DÍA DE LA INDEPENDENCIA") if fiesta else Idiomas.t("DÍA DE MEMORIA")
	var pais := etiqueta("%s · %s" % [cab, PersonajeDatos.nombre_pais(String(ev.get("pais", ""))).to_upper()], 14, Color(SelectorDireccional.BLANCO, 0.6))
	var titulo := etiqueta(Idiomas.t(String(ev.get("nombre", ""))), 34, SelectorDireccional.BLANCO)
	var cuando := "%d de %s" % [int(ev.get("dia", 1)), Principal.MESES_LARGOS[clampi(int(ev.get("mes", 1)) - 1, 0, 11)]]
	var fecha := etiqueta(Idiomas.t(cuando), 16, Color(VELA, 0.85))
	var raya := ColorRect.new()
	raya.color = Color(VELA, 0.45)
	raya.custom_minimum_size = Vector2(120, 2)
	raya.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	## Memoria: la frase de reflexión entre comillas. Independencia: lo que se celebra (la explicación) y debajo la frase, más suave.
	var frase := etiqueta(Idiomas.t(String(ev.get("texto", ""))) if fiesta else "«%s»" % Idiomas.t(String(ev.get("reflexion", ""))), 22, Color(SelectorDireccional.BLANCO, 0.92))
	frase.custom_minimum_size = Vector2(ancho_base(640.0), 0)
	frase.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var piezas: Array = [vela, pais, titulo, fecha, raya, frase]
	if fiesta:
		var sub := etiqueta(Idiomas.t(String(ev.get("reflexion", ""))), 16, Color(SelectorDireccional.BLANCO, 0.6))
		sub.custom_minimum_size = Vector2(ancho_base(600.0), 0)
		sub.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		piezas.append(sub)
	else:
		piezas.append(etiqueta(Idiomas.t("Un minuto de silencio"), 14, Color(SelectorDireccional.BLANCO, 0.6)))
		barra = ProgressBar.new()
		barra.show_percentage = false
		barra.max_value = 1.0
		barra.custom_minimum_size = Vector2(ancho_base(360.0) * 0.6, 6)
		barra.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		barra.add_theme_stylebox_override("background", Tema.caja(Color(1, 1, 1, 0.10), 3))
		barra.add_theme_stylebox_override("fill", Tema.caja(Color(VELA, 0.85), 3))
		piezas.append(barra)
	var seguir := boton(Idiomas.t("Continuar"), true)
	seguir.custom_minimum_size = Vector2(240, 58)
	seguir.pressed.connect(func() -> void: elegido.emit("0"))
	for n: Control in piezas:
		_centro.add_child(n)
	fijar_abajo(seguir)
	if barra == null:
		entrada_en_cascada(piezas, 0.2, 0.22)
	elif Animar.reducidas():
		barra.value = 1.0
	else:
		create_tween().tween_property(barra, "value", 1.0, SILENCIO)
		entrada_en_cascada(piezas, 0.2, 0.28)
