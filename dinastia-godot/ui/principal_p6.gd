extends "res://ui/principal_p5.gd"
## [Capa 6/17 de `principal.gd`] _pintar_porque_moral (y los puentes a `PantallaFinanzas`: finanzas y camarín)

## Puente (fase 6, paso 6): la pestaña Finanzas la pinta `PantallaFinanzas`.
func _pintar_finanzas(c: Club) -> void: _ui_finanzas._pintar_finanzas(c)

## POR QUÉ SUBE O BAJA LA MORAL (17-10-2026, lo pedía el informe y lo hace FM):
## los motivos de las últimas semanas sumados por el plantel, lo que pesa en la
## satisfacción de media y los tres más tocados con su motivo.
func _pintar_porque_moral(c: Club) -> void:
	var v := mundo.vestuario
	var pl := c.plantilla
	if pl.is_empty():
		return
	var t := _texto(11, COL_SUAVE)
	t.text = Idiomas.t("📈 POR QUÉ SUBE O BAJA LA MORAL")
	_lista_camarin.add_child(t)
	## Las cuatro últimas semanas con algún cambio.
	var semanas := {}
	for j in pl:
		for e: Dictionary in j.historial_moral:
			semanas[int(e["s"])] = true
	var orden: Array = semanas.keys()
	orden.sort()
	var desde: int = orden[maxi(orden.size() - 4, 0)] if not orden.is_empty() else 0
	var por_motivo := {}
	for j in pl:
		for e: Dictionary in j.historial_moral:
			if int(e["s"]) >= desde:
				por_motivo[String(e["m"])] = float(por_motivo.get(String(e["m"]), 0.0)) + float(e["d"])
	var motivos: Array = por_motivo.keys()
	motivos.sort_custom(func(a: String, b: String) -> bool: return absf(float(por_motivo[a])) > absf(float(por_motivo[b])))
	if motivos.is_empty():
		var nada := _texto(12, COL_SUAVE)
		nada.text = Idiomas.t("Todavía no hay cambios de moral que explicar (empieza a jugar semanas).")
		_lista_camarin.add_child(nada)
	else:
		var sub := _texto(10, COL_SUAVE)
		sub.text = Idiomas.t("Últimas semanas, media por jugador:")
		_lista_camarin.add_child(sub)
		for mo: String in motivos.slice(0, 6):
			var media := float(por_motivo[mo]) / float(pl.size())
			if absf(media) < 0.05:
				continue
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 8)
			_lista_camarin.add_child(fila)
			var n := _texto(12, COL_TEXTO)
			n.text = Idiomas.t(mo)
			n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila.add_child(n)
			var dv := _texto(12, COL_VERDE if media > 0 else COL_ROJO)
			dv.text = "%+.1f" % media
			fila.add_child(dv)
	## Lo que pesa en la satisfacción, de media: hacia ahí va la moral cada semana.
	if v != null and v.has_method("satisfaccion_de"):
		var suma := {"min": 0.0, "rend": 0.0, "tact": 0.0, "inst": 0.0}
		for j in pl:
			var sat: Dictionary = v.satisfaccion_de(j)
			for k: String in suma:
				suma[k] = float(suma[k]) + float(sat[k])
		var sub2 := _texto(10, COL_SUAVE)
		sub2.text = Idiomas.t("Hacia dónde tira la satisfacción (la moral se acerca a ella cada semana):")
		_lista_camarin.add_child(sub2)
		var peor := "min"
		for k: String in suma:
			if float(suma[k]) < float(suma[peor]):
				peor = k
		var nombres := {"min": "Minutos de juego", "rend": "Rendimiento", "tact": "Comodidad en su puesto", "inst": "Instalaciones"}
		for k: String in ["min", "rend", "tact", "inst"]:
			var val := float(suma[k]) / float(pl.size())
			var fila2 := HBoxContainer.new()
			fila2.add_theme_constant_override("separation", 8)
			_lista_camarin.add_child(fila2)
			var et := _texto(12, COL_ROJO if k == peor else COL_TEXTO)
			et.text = Idiomas.t(nombres[k])
			et.custom_minimum_size = Vector2(190, 0)
			fila2.add_child(et)
			var barra := ProgressBar.new()
			barra.max_value = 100
			barra.value = val
			barra.show_percentage = false
			barra.custom_minimum_size = Vector2(160, 10)
			barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			fila2.add_child(barra)
			var num := _texto(12, COL_SUAVE)
			num.text = str(roundi(val))
			fila2.add_child(num)
		var consejo := {"min": "Reparte minutos: los que no juegan son los que más tiran la moral abajo.",
			"rend": "El equipo no rinde: la moral sube sola cuando llegan buenas notas.",
			"tact": "Hay jugadores fuera de su puesto: revisa la alineación o reconviértelos.",
			"inst": "Mejorar ciudad deportiva, médicos, gimnasio y cocina sube la moral de todos."}
		var tip := _texto(12, COL_ORO)
		tip.text = "💡 " + Idiomas.t(consejo[peor])
		tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_camarin.add_child(tip)
	## Los tres más tocados y su motivo.
	var bajos: Array = pl.duplicate()
	bajos.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.moral < b.moral)
	var sub3 := _texto(10, COL_SUAVE)
	sub3.text = Idiomas.t("Los más tocados:")
	_lista_camarin.add_child(sub3)
	for j: Jugador in bajos.slice(0, 3):
		var mot := ""
		for k in range(j.historial_moral.size() - 1, -1, -1):
			if int(j.historial_moral[k]["d"]) < 0:
				mot = Idiomas.t(String(j.historial_moral[k]["m"]))
				break
		if mot == "" and v != null and v.has_method("satisfaccion_de"):
			mot = Idiomas.t(Vestuario.motivo_satisfaccion(v.satisfaccion_de(j), true))
		var fj := _texto(12, COL_ROJO if j.moral < 40 else COL_TEXTO)
		fj.text = "%s  ·  %s %d  ·  %s" % [j.nombre, Idiomas.t("moral"), j.moral, mot]
		_lista_camarin.add_child(fj)
	_lista_camarin.add_child(HSeparator.new())

## Puente (fase 6, paso 6): la pestaña Camarín la pinta `PantallaFinanzas`.
func _pintar_camarin(c: Club) -> void: _ui_finanzas._pintar_camarin(c)
