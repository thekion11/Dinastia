class_name FichaJugadorInfo
extends RefCounted
## Los bloques DE SOLO LECTURA de la ficha de un jugador: informe ciego,
## estadísticas de la temporada, cabeza/vestuario, promesa y satisfacción,
## habilidades, historial médico, vida personal y crecimiento por temporada.
## Ocho funciones que `Principal._ver_ficha()` llamaba, sacadas tal cual -sin
## cambiar una coma de lo que pintan-, mismo patrón de clase estática que
## `TablaCompeticion` (25-9-2026): esto tampoco tiene estado propio.
##
## POR QUÉ SOLO ESTAS OCHO Y NO TODA LA FICHA (que sigue en `principal.gd`,
## anotado en `ROADMAP.md`): la ficha completa mide 850+ líneas repartidas en
## 14 funciones con QUINCE Y PICO botones distintos -pedir informe, comparar,
## ofrecer, negociar, pagar cláusula, desarrollo prioritario, reconvertir,
## fidelidad, vender, rescindir...-, cada uno tendría que convertirse en una
## señal como hizo `PanelMercado`. Intentarlo todo de una vez, la misma noche
## que se encontró y arregló un juego que no arrancaba por una migración a
## medias, es exactamente el riesgo que el usuario pidió reducir. Estas ocho
## SÍ son seguras de mover ahora porque se verificó una por una que ninguna
## tiene un botón ni cambia nada del mundo -solo leen `Jugador`/`Mundo` y
## pintan-, y solo dos (`_bio_de`/`_perfil_humano`) tenían más de un punto de
## llamada, los dos ya localizados y actualizados.
##
## `paleta`: los mismos colores YA resueltos que recibe `TablaCompeticion`
## -`_color_accesible()`/`_pal_*()`, con `escala` para el tamaño de letra de
## Ajustes-, para no repetir el hueco de coherencia visual del mercado.
##   {"suave", "texto", "acento", "verde", "rojo", "oro", "escala"}
##
## Sin `Ficcion.limpiar()`, igual que el resto de `principal.gd` fuera de
## `PanelMercado`: el renombrado legal es una decisión pendiente de confirmar,
## no un descuido de esta extracción.

## `fichaCiega()` del HTML: lo que ve el jugador cuando `Ojeadores.modo_ciego`
## está activo y no conoce a este rival -en vez de la grilla de atributos
## exacta, el informe de un ojeador con adjetivos y un margen de fiabilidad,
## sobre la media REAL del jugador-.
static func pintar_ciega(lista: VBoxContainer, j: Jugador, mundo: Mundo, paleta: Dictionary) -> void:
	var oj := mundo.ojeadores
	var fila := oj.escala_de(j.ovr)
	var puesto: Dictionary = (Datos.tabla("POSD") as Dictionary).get(j.pos_e, {})
	var t := _texto(11, paleta["suave"], paleta)
	t.text = "👁️ INFORME DEL OJEADOR"
	lista.add_child(t)
	var p := _texto(12, paleta["texto"], paleta)
	p.text = "%s, %d años, %s. Nuestro hombre lo califica como «%s»: %s." % [
		j.nombre, j.edad, String(puesto.get("n", "jugador")).to_lower(),
		String(fila[1]).to_lower(), String(fila[2]).to_lower()]
	p.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(p)
	if not j.atributos.is_empty():
		var claves: Array = j.atributos.keys()
		var fuerte := String(claves[0])
		var flojo := String(claves[0])
		for k: String in claves:
			if int(j.atributos[k]) > int(j.atributos[fuerte]):
				fuerte = k
			if int(j.atributos[k]) < int(j.atributos[flojo]):
				flojo = k
		_dato(lista, "Mejor cualidad", String(Principal.NOMBRES_ATRIBUTOS.get(fuerte, fuerte)), paleta["verde"], paleta)
		_dato(lista, "Punto débil", String(Principal.NOMBRES_ATRIBUTOS.get(flojo, flojo)), paleta["rojo"], paleta)
	_dato(lista, "Partidos esta temporada", "%d · %d goles · %d asistencias" % [j.partidos, j.goles, j.asistencias], paleta["texto"], paleta)
	_dato(lista, "Nota media", ("%.1f" % j.media_notas()) if j.notas.size() >= 3 else "sin datos", paleta["texto"], paleta)
	_dato(lista, "Carácter", Nombres.limpiar(String((Datos.tabla("RASGOS") as Dictionary).get(j.rasgo, ["sin rasgos marcados"])[0])) if j.rasgo != "" else "sin rasgos marcados", paleta["texto"], paleta)
	_dato(lista, "Fiabilidad del informe", oj.fiabilidad_de(j), paleta["suave"], paleta)

## Lo que ha hecho esta temporada.
static func pintar_estadisticas(lista: VBoxContainer, j: Jugador, paleta: Dictionary) -> void:
	if j.partidos <= 0:
		return
	lista.add_child(HSeparator.new())
	var t := _texto(11, paleta["suave"], paleta)
	t.text = "ESTA TEMPORADA"
	lista.add_child(t)
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 12)
	lista.add_child(g)
	## La nota media pide tres partidos: con uno solo, un 8 puntual diría que es
	## el mejor del plantel, y eso es ruido disfrazado de dato.
	var nota := "—"
	if j.notas.size() >= 3:
		var s := 0.0
		for x in j.notas:
			s += float(x)
		nota = "%.1f" % (s / float(j.notas.size()))
	for par in [["PJ", str(j.partidos)], ["Goles", str(j.goles)],
			["Asist.", str(j.asistencias)], ["Nota", nota]]:
		var col := VBoxContainer.new()
		g.add_child(col)
		var et := _texto(10, paleta["suave"], paleta)
		et.text = String(par[0])
		col.add_child(et)
		var va := _texto(16, paleta["texto"], paleta)
		va.text = String(par[1])
		col.add_child(va)
	if j.amarillas > 0:
		_dato(lista, "🟨 Amarillas", str(j.amarillas), paleta["oro"], paleta)

## La cabeza. `Vestuario` lleva ansiedad y confianza por jugador.
static func pintar_cabeza(lista: VBoxContainer, j: Jugador, mundo: Mundo, paleta: Dictionary) -> void:
	var v := mundo.vestuario
	if v == null:
		return
	lista.add_child(HSeparator.new())
	var t := _texto(11, paleta["suave"], paleta)
	t.text = "🧠 CABEZA"
	lista.add_child(t)
	var em: Dictionary = v.estado_mental(j)
	_dato(lista, "Estado mental", "%d/100 · %s" % [v.ansiedad(j), String(em["txt"])], Color(String(em["color"])), paleta)
	_dato(lista, "Confianza", "%d/100" % v.confianza(j), paleta["texto"], paleta)
	var clan: Dictionary = v.clan_de(j)
	if not clan.is_empty():
		_dato(lista, "Camarín", "pertenece a «%s»" % String(clan.get("nombre", "—")), paleta["suave"], paleta)

## El rol prometido y si lo estás cumpliendo.
static func pintar_promesa(lista: VBoxContainer, j: Jugador, mundo: Mundo, paleta: Dictionary) -> void:
	var v := mundo.vestuario
	if v == null:
		return
	var def := v.def_rol(v.rol_plantel(j))
	if def.is_empty():
		return
	lista.add_child(HSeparator.new())
	var t := _texto(11, paleta["suave"], paleta)
	t.text = "PROMESA Y SATISFACCIÓN"
	lista.add_child(t)
	_dato(lista, "Rol prometido", "%s (%d%%)" % [String(def[1]), int(float(def[3]) * 100.0)], paleta["texto"], paleta)
	var s: Dictionary = v.satisfaccion(j)
	var total := int(s["total"])
	_dato(lista, "Satisfacción", "%d/100" % total,
		paleta["verde"] if total >= 60 else (paleta["rojo"] if total < 40 else paleta["oro"]), paleta)
	for par in [["Minutos", "min"], ["Su rendimiento", "rend"], ["Comodidad táctica", "tact"], ["Instalaciones", "inst"]]:
		var val := int(s[String(par[1])])
		_dato(lista, "   %s" % String(par[0]), str(val),
			paleta["verde"] if val >= 60 else (paleta["rojo"] if val < 40 else paleta["suave"]), paleta)

## Las habilidades especiales que ya tiene.
static func pintar_habilidades(lista: VBoxContainer, j: Jugador, mundo: Mundo, paleta: Dictionary) -> void:
	var e := mundo.entrenamiento
	if e == null:
		return
	var habs := e.habilidades(j)
	if habs.is_empty():
		return
	var t := _texto(11, paleta["suave"], paleta)
	t.text = "HABILIDADES"
	lista.add_child(t)
	for k: String in habs:
		var l := _texto(11, paleta["oro"], paleta)
		l.text = "✦ %s" % e.nombre_habilidad(String(k))
		l.tooltip_text = e.descripcion_habilidad(String(k))
		lista.add_child(l)

## El historial de lesiones.
static func pintar_historial_medico(lista: VBoxContainer, j: Jugador, mundo: Mundo, paleta: Dictionary) -> void:
	var m := mundo.medico
	if m == null:
		return
	var h: Array = m.historial(j)
	if h.is_empty():
		return
	lista.add_child(HSeparator.new())
	var t := _texto(11, paleta["suave"], paleta)
	t.text = "HISTORIAL MÉDICO"
	lista.add_child(t)
	## De la más reciente hacia atrás, y como mucho seis.
	var desde := maxi(0, h.size() - 6)
	for i in range(h.size() - 1, desde - 1, -1):
		var x: Dictionary = h[i]
		_dato(lista, String(x.get("n", "lesión")),
			"%d sem  ·  %d" % [int(x.get("sem", 0)), int(x.get("anio", 0))], paleta["suave"], paleta)

## `perfilHumano()`/`bioDe()` del HTML. DOS PUNTOS DE LLAMADA en Principal:
## dentro de `pintar_vida_personal()` (de abajo) y directo en `_ver_ficha()`
## para la biografía de un jugador AJENO -"la biografía se enseña siempre,
## sea o no tuyo, a diferencia de `perfilHumano()`, que es cosa del vestuario
## propio"-. Los dos actualizados a llamar aquí.
const _ORIGEN_RESPALDO := ["surgido de la cantera", "llegado desde el fútbol amateur",
	"descubierto en un torneo de barrio", "formado a la antigua"]

static func perfil_humano(j: Jugador) -> Dictionary:
	var tabla: Variant = Datos.tabla("PERSONAL")
	if not (tabla is Array) or (tabla as Array).is_empty():
		return {}
	var arr: Array = tabla
	var clave := j.id + "ph"
	var h := 0
	for i in clave.length():
		h += clave.unicode_at(i)
	var p: Array = arr[h % arr.size()]
	if String(p[0]) == "":
		return {}
	return {"t": String(p[1]), "d": String(p[2])}

static func bio_de(j: Jugador, mundo: Mundo) -> String:
	var h := 0
	for i in j.id.length():
		h += j.id.unicode_at(i)
	var texto := "Debutó a los %d años, %s. " % [16 + h % 4, _ORIGEN_RESPALDO[h % 4]]
	var linaje := mundo.cantera.linaje_de(j) if mundo.cantera != null else {}
	if not linaje.is_empty():
		texto += "Hijo de la leyenda %s. " % String(linaje.get("padre", ""))
	if j.rasgo != "":
		var nombre_rasgo := String((Datos.tabla("RASGOS") as Dictionary).get(j.rasgo, ["?"])[0])
		texto += "En el camarín lo describen como «%s»." % Nombres.limpiar(nombre_rasgo).to_lower()
	return texto

## `perfilHumano()` del HTML: una novedad de vida personal estable por
## jugador y una línea de biografía. Solo se ve del propio -es cosa del
## vestuario, no de cualquiera-, a diferencia de `bio_de()`, que se ve siempre.
static func pintar_vida_personal(lista: VBoxContainer, j: Jugador, mundo: Mundo, paleta: Dictionary) -> void:
	lista.add_child(HSeparator.new())
	var t := _texto(11, paleta["suave"], paleta)
	t.text = "🧠 VIDA PERSONAL"
	lista.add_child(t)
	var perfil := perfil_humano(j)
	var p := _texto(12, paleta["texto"], paleta)
	p.text = ("%s. %s" % [String(perfil.get("t", "")), String(perfil.get("d", ""))]) if not perfil.is_empty() \
		else "Sin novedades fuera de la cancha: vida ordenada."
	p.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(p)
	var bio := _texto(11, paleta["suave"], paleta)
	bio.text = bio_de(j, mundo)
	bio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(bio)

## "CRECIMIENTO POR TEMPORADA" del HTML.
static func pintar_historial(lista: VBoxContainer, j: Jugador, paleta: Dictionary) -> void:
	if j.historial.is_empty():
		return
	lista.add_child(HSeparator.new())
	var t := _texto(11, paleta["suave"], paleta)
	t.text = "CRECIMIENTO POR TEMPORADA"
	lista.add_child(t)
	for i in range(j.historial.size() - 1, -1, -1):
		var h: Dictionary = j.historial[i]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		var izq := _texto(11, paleta["suave"], paleta)
		izq.text = "%s · %s" % [str(h["anio"]), String(h["club"])]
		izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		izq.clip_text = true
		fila.add_child(izq)
		var medio := _texto(11, paleta["texto"], paleta)
		medio.text = "%d PJ · %d goles" % [int(h["pj"]), int(h["goles"])]
		medio.custom_minimum_size = Vector2(110, 0)
		fila.add_child(medio)
		var color_ovr: Color = paleta["texto"]
		var texto_ovr := str(h["ovr"])
		if i > 0:
			var d: int = int(h["ovr"]) - int((j.historial[i - 1] as Dictionary)["ovr"])
			if d != 0:
				texto_ovr = "%s  %s%d" % [texto_ovr, "+" if d > 0 else "", d]
				color_ovr = paleta["verde"] if d > 0 else paleta["rojo"]
		var ovr_l := _texto(11, color_ovr, paleta)
		ovr_l.text = texto_ovr
		ovr_l.custom_minimum_size = Vector2(60, 0)
		fila.add_child(ovr_l)
		lista.add_child(fila)

# ── HELPERS DE UI, duplicados a propósito de `principal.gd` (ver la nota de
# `TablaCompeticion` sobre por qué duplicar en vez de compartir) ───────────
static func _texto(tam: int, color: Color, paleta: Dictionary) -> Label:
	var l := Label.new()
	var escala: float = float(paleta.get("escala", 1.0))
	l.add_theme_font_size_override("font_size", maxi(8, int(round(float(tam) * escala))))
	l.add_theme_color_override("font_color", color)
	return l

static func _dato(padre: Node, etiqueta: String, valor: String, color: Color, paleta: Dictionary) -> void:
	var h := HBoxContainer.new()
	var a := _texto(12, paleta["suave"], paleta)
	a.text = etiqueta
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a.clip_text = true
	a.tooltip_text = etiqueta
	h.add_child(a)
	var b := _texto(12, color, paleta)
	b.text = valor
	h.add_child(b)
	padre.add_child(h)
