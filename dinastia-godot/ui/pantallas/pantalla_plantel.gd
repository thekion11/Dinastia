class_name PantallaPlantel
extends "res://ui/pantallas/pantalla_plantel_p3.gd"
## [Capa 4/4 de `pantalla_plantel.gd`] _abrir_negociacion, _cancelar_negociacion, _pintar_copa

func _abrir_negociacion(j: Jugador) -> void:
	var motivo := p.mundo.mercado.abrir_negociacion(j)
	if motivo != "":
		p._escribir("[color=#e05555]No se pudo abrir la mesa: %s.[/color]" % motivo)
		return
	p._negociacion_ultimo = {}
	p._ir_a_pestana("Mercado")
	p._refrescar()

func _cancelar_negociacion() -> void:
	p.mundo.mercado.cerrar_negociacion()
	p._negociacion_ultimo = {}
	p._refrescar()

## El estado de la copa: en qué ronda va, quién sigue vivo y cómo cayó cada
## eliminatoria. Se pinta al revés que la liga -de la ronda más reciente hacia
## atrás- porque lo que interesa es lo que acaba de pasar.
func _pintar_copa(mio: Club) -> void:
	p._limpiar(p._lista_copa)
	if p.mundo.copa == null:
		var vacio := p._texto(12, Principal.COL_SUAVE)
		vacio.text = Idiomas.t("La copa se sortea al empezar la temporada.")
		p._lista_copa.add_child(vacio)
		return
	var c := p.mundo.copa
	var cab := p._texto(14, Principal.COL_ORO)
	if c.campeon != null:
		cab.text = Idiomas.t("%s — campeón: %s") % [c.nombre, c.campeon.nombre]
	elif c.en_curso():
		cab.text = Idiomas.t("%s — %s  (%d equipos vivos)") % [c.nombre, c.nombre_de_ronda(), c.vivos.size()]
	else:
		cab.text = c.nombre
	p._lista_copa.add_child(cab)

	if c.en_curso():
		var cruce := c.emparejamiento_de(mio)
		var estado := p._texto(12, Principal.COL_VERDE if not cruce.is_empty() else Principal.COL_ROJO)
		if not cruce.is_empty():
			estado.text = Idiomas.t("Te toca: %s  vs  %s") % [cruce[0].nombre, cruce[1].nombre]
		else:
			estado.text = Idiomas.t("%s ya está eliminado.") % mio.nombre
		p._lista_copa.add_child(estado)

	for i in range(c.historial.size() - 1, -1, -1):
		var ronda: Dictionary = c.historial[i]
		p._lista_copa.add_child(HSeparator.new())
		var t := p._texto(11, Principal.COL_SUAVE)
		t.text = String(ronda["ronda"]).to_upper()
		p._lista_copa.add_child(t)
		var g := GridContainer.new()
		g.columns = 3
		g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_theme_constant_override("h_separation", 10)
		p._lista_copa.add_child(g)
		for r: Dictionary in ronda["resultados"]:
			var mio_juega: bool = r["local"] == mio or r["visita"] == mio
			var col := p.COL_ACENTO if mio_juega else Principal.COL_TEXTO
			p._celda(g, String(r["local"].nombre), col if r["pasa"] == r["local"] else Principal.COL_SUAVE)
			var marcador := "%d-%d" % [r["gl"], r["gv"]]
			if not r["penales"].is_empty():
				marcador += "  (%d-%d pen.)" % [r["penales"][0], r["penales"][1]]
			p._celda(g, marcador, col, true)
			p._celda(g, String(r["visita"].nombre), col if r["pasa"] == r["visita"] else Principal.COL_SUAVE)
