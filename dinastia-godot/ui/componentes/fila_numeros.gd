class_name FilaNumeros
extends HBoxContainer
## TUS NÚMEROS EN EL PARTIDO DE LA RUTA, CON ICONOS DIBUJADOS (17-11, orden 36: iconos dibujados por defecto). Antes era una línea de
## texto con emojis («⚽ 0   🅰 0   🎯 0/0   ✔ 0/0 pases   ⭐ 6.0»), que cada teléfono pinta distinto. Ahora, cinco pares icono + cifra
## con los iconos del juego (`IconosUI`: pelota, «A» de asistencia, diana, visto y estrella); con los dibujados apagados (Ajustes →
## Pantalla) vuelven los emojis. Lo usa `PartidoJugable._montar_hud`.

const EMOJIS := ["⚽", "🅰", "🎯", "✔", "⭐"]

var _cifras: Array[Label] = []

static func crear(tam_letra: int) -> FilaNumeros:
	var f := FilaNumeros.new()
	f.add_theme_constant_override("separation", int(tam_letra * 0.45))
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for e: String in EMOJIS:
		var ic := IconosUI.control(e, int(tam_letra * 1.25))
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		f.add_child(ic)
		var l := Label.new()
		l.add_theme_font_size_override("font_size", tam_letra)
		l.add_theme_color_override("font_color", Color.WHITE)
		l.text = "0"
		f.add_child(l)
		f._cifras.append(l)
	return f

## Las cinco cifras: goles, asistencias, a puerta / tiros, pases buenos / pases y la nota.
func poner(goles: int, asist: int, a_puerta: int, tiros: int, pases_ok: int, pases: int, nota: float) -> void:
	var t := ["%d" % goles, "%d" % asist, "%d/%d" % [a_puerta, tiros], "%d/%d" % [pases_ok, pases], "%.1f" % nota]
	for i in _cifras.size():
		if _cifras[i].text != t[i]:
			_cifras[i].text = t[i]
