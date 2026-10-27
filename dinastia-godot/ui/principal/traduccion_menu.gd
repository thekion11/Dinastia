class_name TraduccionMenu
extends RefCounted
## (fase 6, paso 7 del plan §7.1: sale de `Principal`, ui/principal_p9.gd, el 27-10-2026). `p` es la pantalla principal;
## sus miembros se usan como `p.x` y `Principal` conserva puentes de una línea con los nombres de siempre.

var p: Principal
## Estado propio de esta pantalla (fase 6, paso 7: antes eran variables de `Principal`).
## Si alguna vez se tradujo a otro idioma en esta sesión. Mientras siga en
## falso y el idioma sea castellano, `_traducir_pantalla` no recorre nada -es
## la mayoría de las partidas, que nunca tocan el selector de idioma-.
var _traduccion_activa := false

func _init(principal: Principal) -> void:
	p = principal

## LA MÚSICA. Seis piezas sintetizadas, como todo el audio del juego: ni un solo
## fichero, ni una licencia de terceros que arrastrar en el paquete.
##
## Va aparte del mezclador de efectos a propósito. La música se apaga entera
## mucho más a menudo que los efectos —hay gente que juega a esto con un podcast
## de fondo—, y tenerla en el mismo grupo obligaba a bajar el silbato para no oír
## el arpegio.
## RECORRE LA PANTALLA Y TRADUCE. Ver la explicación larga en `nucleo/idiomas.gd`.
##
## Solo toca `Label`, `Button` y `OptionButton`, que es donde vive el esqueleto
## de la interfaz. NO toca `RichTextLabel` -ahí va la narración, que sigue en
## castellano- ni `LineEdit` -ahí escribe el usuario-.
##
## Guarda en metadatos del propio nodo el texto castellano original (`_i18n_src`)
## y lo último que ESTA función escribió (`_i18n_out`): si el texto actual
## coincide con lo último que ella misma puso, nadie lo tocó desde entonces y
## usa el castellano guardado como fuente; si NO coincide, es que un repintado
## puso texto castellano fresco (nombre de jugador, cifra...) y lo adopta como
## la nueva fuente. SIN esto, un nodo que se construye UNA sola vez y nunca se
## repinta -"Guardar"/"Cargar"/"Otro mundo" de la fila de acciones, tooltips-
## se quedaba pegado en el último idioma elegido para siempre, sin volver al
## castellano al cambiar de vuelta: bug real, sospechado el 10-9-2026 en una
## captura ("Save"/"Load"/"New world" seguían en inglés tras forzar `idioma="es"`)
## y confirmado y corregido aquí el 12-9-2026.
## Un texto sin castellano guardado: si es la traducción de una clave (se pintó ya
## traducido en otro idioma), su clave; si no, tal cual (s3, cambio de idioma).
func _origen_de(texto: String) -> String:
	var o := Idiomas.origen(texto)
	return o if o != "" else texto
func _traducir_pantalla(n: Node) -> void:
	if n == p:
		if Idiomas.idioma == "es" and not _traduccion_activa:
			return
		if Idiomas.idioma != "es":
			_traduccion_activa = true
	if n is Label:
		var l := n as Label
		var actual := l.text
		var fue_mio: bool = l.has_meta("_i18n_out") and String(l.get_meta("_i18n_out")) == actual
		var base: String = String(l.get_meta("_i18n_src")) if fue_mio else _origen_de(actual)
		var nuevo := base if Idiomas.idioma == "es" else Idiomas.t(base)
		l.set_meta("_i18n_src", base)
		l.set_meta("_i18n_out", nuevo)
		l.text = nuevo
	elif n is OptionButton:
		## El desplegable, por dentro: cada entrada por separado. El texto del
		## botón lo pinta Godot con la entrada elegida, así que no hay que tocarlo.
		var ob := n as OptionButton
		var outs: Array = ob.get_meta("_i18n_out") if ob.has_meta("_i18n_out") else []
		var srcs: Array = ob.get_meta("_i18n_src") if ob.has_meta("_i18n_src") else []
		var nuevos_src: Array = []
		var nuevos_out: Array = []
		for i in ob.item_count:
			var actual_i := ob.get_item_text(i)
			var fue_mio_i: bool = i < outs.size() and String(outs[i]) == actual_i
			var base_i: String = String(srcs[i]) if (fue_mio_i and i < srcs.size()) else actual_i
			var nuevo_i := base_i if Idiomas.idioma == "es" else Idiomas.t(base_i)
			ob.set_item_text(i, nuevo_i)
			nuevos_src.append(base_i)
			nuevos_out.append(nuevo_i)
		ob.set_meta("_i18n_src", nuevos_src)
		ob.set_meta("_i18n_out", nuevos_out)
	elif n is Button:
		var b := n as Button
		var actual2 := b.text
		var fue_mio2: bool = b.has_meta("_i18n_out") and String(b.get_meta("_i18n_out")) == actual2
		var base2: String = String(b.get_meta("_i18n_src")) if fue_mio2 else _origen_de(actual2)
		var nuevo2 := base2 if Idiomas.idioma == "es" else Idiomas.t(base2)
		b.set_meta("_i18n_src", base2)
		b.set_meta("_i18n_out", nuevo2)
		## Si el boton repartia ancho por el largo de su rotulo -la fila de
		## acciones-, el reparto se rehace con el rotulo NUEVO: "Temporada
		## siguiente" y "Next season" no piden lo mismo.
		if nuevo2 != actual2 and b.size_flags_stretch_ratio != 1.0:
			b.size_flags_stretch_ratio = clampf(float(nuevo2.length()) / 12.0, 0.95, 1.9)
		b.text = nuevo2
	elif n is LineEdit:
		## El texto de ayuda del campo ("🔎 Buscar..."), no lo que escribe el jugador.
		var le := n as LineEdit
		var actual_ph := le.placeholder_text
		if actual_ph != "":
			var fue_mio_ph: bool = le.has_meta("_i18n_ph_out") and String(le.get_meta("_i18n_ph_out")) == actual_ph
			var base_ph: String = String(le.get_meta("_i18n_ph_src")) if fue_mio_ph else actual_ph
			var nuevo_ph := base_ph if Idiomas.idioma == "es" else Idiomas.t(base_ph)
			le.set_meta("_i18n_ph_src", base_ph)
			le.set_meta("_i18n_ph_out", nuevo_ph)
			le.placeholder_text = nuevo_ph
	if n.has_method("get_tooltip_text") and n is Control:
		var ctrl := n as Control
		var actual_tip := ctrl.tooltip_text
		if actual_tip != "":
			var fue_mio_tip: bool = ctrl.has_meta("_i18n_tip_out") and String(ctrl.get_meta("_i18n_tip_out")) == actual_tip
			var base_tip: String = String(ctrl.get_meta("_i18n_tip_src")) if fue_mio_tip else _origen_de(actual_tip)
			var nuevo_tip := base_tip if Idiomas.idioma == "es" else Idiomas.t(base_tip)
			ctrl.set_meta("_i18n_tip_src", base_tip)
			ctrl.set_meta("_i18n_tip_out", nuevo_tip)
			ctrl.tooltip_text = nuevo_tip
	for h in n.get_children():
		_traducir_pantalla(h)
