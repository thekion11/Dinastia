class_name RotuloEstadisticas
extends PanelContainer
## EL RÓTULO DE ESTADÍSTICAS DE LA TELE (16-10-2026): en los momentos muertos
## (la primera pelota parada pasado el 17', el descanso, la primera pasado el
## 65') entra por abajo una franja con 3-5 cifras enfrentadas y se va sola. No
## para el partido. Lo decide `cuando()` (estático, para las pruebas).

const DURA := 7.0

## Qué rótulo toca ahora ("" = ninguno). `hechos` guarda los ya mostrados.
static func cuando(minuto: int, estado: String, mitad: int, hechos: Dictionary) -> String:
	## En la prórroga y la tanda no (el descanso de la prórroga no es «el descanso»).
	if mitad > 2 or estado == "tanda":
		return ""
	if estado == "descanso" and not hechos.has("descanso"):
		return "descanso"
	if estado != "saque":
		return ""
	if mitad == 1 and minuto >= 17 and minuto < 44 and not hechos.has("primero"):
		return "primero"
	if mitad == 2 and minuto >= 65 and minuto < 88 and not hechos.has("segundo"):
		return "segundo"
	return ""

const CLAVES := {
	"primero": ["Posesión", "Tiros", "Tiros a puerta", "Córners"],
	"descanso": ["Posesión", "Tiros", "Tiros a puerta", "Goles esperados (xG)", "Precisión de pase"],
	"segundo": ["Posesión", "Tiros", "Goles esperados (xG)", "Faltas"],
}
const TITULOS := {"primero": "ESTADÍSTICAS", "descanso": "DESCANSO · ESTADÍSTICAS", "segundo": "ESTADÍSTICAS"}

static func mostrar(padre: Control, cual: String, p: Partido, m: MotorJugable, d: EstadisticasVivo) -> RotuloEstadisticas:
	var r := RotuloEstadisticas.new()
	r._montar(cual, p, m, d)
	padre.add_child(r)
	r._animar()
	return r

func _montar(cual: String, p: Partido, m: MotorJugable, d: EstadisticasVivo) -> void:
	name = "RotuloEstadisticas"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 40
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.04, 0.07, 0.05, 0.9)
	st.border_color = Tema.ORO
	st.border_width_top = 3
	st.set_corner_radius_all(6)
	st.content_margin_left = 16
	st.content_margin_right = 16
	st.content_margin_top = 8
	st.content_margin_bottom = 10
	add_theme_stylebox_override("panel", st)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	custom_minimum_size = Vector2(560, 0)
	var cols := PanelEstadisticas.colores_equipos(p.local if p else null, p.visita if p else null)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	add_child(v)
	var cab := HBoxContainer.new()
	v.add_child(cab)
	var t := Tema.etiqueta(13, Tema.ORO, Idiomas.t(String(TITULOS.get(cual, "ESTADÍSTICAS"))))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(t)
	if p != null:
		cab.add_child(Tema.etiqueta(13, Tema.TEXTO, "%s %d - %d %s" % [Nombres.visible(p.local.nombre), p.goles_local,
			p.goles_visita, Nombres.visible(p.visita.nombre)]))
	for f: Array in d.para_rotulo(p, m, CLAVES.get(cual, CLAVES["primero"])):
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		v.add_child(fila)
		var a := Tema.etiqueta(15, Tema.TEXTO, String(f[1]))
		a.custom_minimum_size = Vector2(56, 0)
		fila.add_child(a)
		var bl := PanelEstadisticas.BarraDoble.new()
		bl.l = float(f[3])
		bl.v = float(f[4])
		bl.col_l = cols[0]
		bl.col_v = cols[1]
		bl.custom_minimum_size = Vector2(150, 5)
		bl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var n := Tema.etiqueta(13, Tema.SUAVE, Idiomas.t(String(f[0])))
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(n)
		fila.add_child(bl)
		var b := Tema.etiqueta(15, Tema.TEXTO, String(f[2]))
		b.custom_minimum_size = Vector2(56, 0)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		fila.add_child(b)

func _animar() -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	## Centrado abajo, por encima de la barra de potencia; entra desde abajo.
	var ancho := maxf(size.x, custom_minimum_size.x)
	offset_left = -ancho * 0.5
	offset_right = ancho * 0.5
	var arriba := -size.y - 118.0
	offset_top = 40.0
	offset_bottom = offset_top + size.y
	modulate.a = 0.0
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.set_parallel(true)
	tw.tween_property(self, "offset_top", arriba, 0.45)
	tw.tween_property(self, "offset_bottom", arriba + size.y, 0.45)
	tw.tween_property(self, "modulate:a", 1.0, 0.3)
	tw.set_parallel(false)
	tw.tween_interval(DURA)
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(queue_free)
