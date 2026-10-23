class_name Selecciones
extends "res://nucleo/selecciones_p2.gd"
## [Capa 3/3 de `selecciones.gd`] _mejores_del_plantel, _vitrina_mundialista, copa_del_mundo, toca_copa_del_mundo, cierre_de_temporada, a_dic … (+3)

func _mejores_del_plantel(m: Mundo, cuantos: int) -> Array[Jugador]:
	var mio := m.mi_club()
	if mio == null:
		return []
	var lista := mio.plantilla.duplicate()
	lista.sort_custom(_mejor_media)
	if lista.size() > cuantos:
		lista.resize(cuantos)
	return lista

## Lo que se lleva de vuelta el que jugó un Mundial: escaparate, desgaste y,
## uno de cada cuatro, una lesión. El orden importa: primero sube, después se
## rompe, y el físico se descuenta siempre. Así el que vuelve lesionado vuelve
## además revalorizado, que es exactamente la frustración que se busca.
func _vitrina_mundialista(j: Jugador, anio: int) -> void:
	var m := _mundo()
	if Azar.suerte(PROB_VITRINA):
		var d := Azar.ent(1, 3)
		j.ajustar_media(d)
		_caps[j.id] = caps_de(j) + Azar.ent(3, 7)
		noticia.emit("🌍 Vitrina mundialista: " + j.nombre,
			"Jugó el Mundial y volvió con %d punto(s) de media más. Su valor de mercado se disparó: espera ofertas." % d)
	if Azar.suerte(PROB_LESION_MUNDIAL):
		var sem := 0
		if m != null and m.medico != null:
			sem = m.medico.lesionar(j, Medico.MEDIA, "en el Mundial", anio, 0)
		else:
			sem = Azar.ent(1, 4)
			j.lesionar(sem)
		if sem > 0:
			noticia.emit("Vuelve tocado del Mundial",
				"🩹 %s llega lesionado de la Copa (%d sem)." % [j.nombre, sem])
			vuelve_tocado.emit(j, sem, false)
	j.fisico = clampi(j.fisico - Azar.ent(10, 25), 10, 100)

## La Copa del Mundo, cada cuatro años: 32 selecciones a eliminación directa.
##
## POR QUÉ ESTA ELIMINATORIA NO PASA POR `Copa`: `Copa` hace jugar `Partido`
## entre `Club`, y aquí los participantes son nombres de países que no tienen
## plantilla, ni estadio, ni saldo. No hay nada que hacer jugar. El duelo es una
## comparación de fuerzas con ±9 de ruido, tal cual el HTML, y ocupa seis líneas:
## montar clubes falsos para poder reutilizar la copa sería mucho peor negocio.
##
## Lo que sí es real es lo que le pasa a TU plantel. Van tus seis mejores —los
## convoca su propio país, no el tuyo, por eso da igual que sean elegibles— y
## vuelven con más media y más caros, o rotos.
func copa_del_mundo(anio: int) -> Dictionary:
	var m := _mundo()
	if m == null:
		return {}
	var vivos: Array = []
	for n: String in _tabla_selecciones():
		vivos.append(_txt(n))
	if vivos.size() < 2:
		return {}
	Azar.barajar(vivos)
	if vivos.size() > PLAZAS_COPA_DEL_MUNDO:
		vivos.resize(PLAZAS_COPA_DEL_MUNDO)
	while vivos.size() > 1:
		var siguiente: Array = []
		for i in range(0, vivos.size(), 2):
			var a := String(vivos[i])
			if i + 1 >= vivos.size():
				siguiente.append(a)      ## impar: el último pasa sin jugar
				continue
			var b := String(vivos[i + 1])
			var fa := fuerza(a) + Azar.ent(-RUIDO_DUELO, RUIDO_DUELO)
			var fb := fuerza(b) + Azar.ent(-RUIDO_DUELO, RUIDO_DUELO)
			siguiente.append(a if fa >= fb else b)
		vivos = siguiente
	var campeon := String(vivos[0])
	mundial = {"anio": anio, "campeon": campeon}

	var mios := _mejores_del_plantel(m, 6)
	var nombres: Array[String] = []
	for j in mios:
		nombres.append("%s (%s)" % [j.nombre, j.pais])
	noticia.emit("🏆 MUNDIAL %d: campeón %s" % [anio, campeon],
		"Se jugó la Copa del Mundo. %s levantó el trofeo. " % campeon
		+ ("De tu plantel fueron convocados: %s." % ", ".join(nombres) if not nombres.is_empty() else "Ningún jugador tuyo fue convocado."))
	for j in mios:
		_vitrina_mundialista(j, anio)
	copa_del_mundo_jugada.emit(anio, campeon)
	return {"anio": anio, "campeon": campeon, "convocados": mios}

func toca_copa_del_mundo(anio: int) -> bool:
	return (anio - ANIO_BASE) % CICLO_MUNDIAL == RESTO_MUNDIAL

# ---------------------------------------------------------------------------
#  CIERRE DE TEMPORADA
# ---------------------------------------------------------------------------

## Todo lo que la selección hace al acabar el año, en el orden del HTML.
##
## OJO: hay que llamarlo ANTES de volver a sortear los torneos continentales. El
## Mundial de Clubes lo juegan los campeones de ESTA temporada, y si el sorteo
## nuevo ya pasó, `Mundo.continentales` tiene ocho torneos sin campeón y el
## Mundial de Clubes se queda sin participantes en silencio.
func cierre_de_temporada(anio: int) -> Dictionary:
	var resumen := {}
	residencias()
	resumen["torneo"] = torneo_continental(anio)
	resumen["clubes"] = mundial_de_clubes(anio)
	resumen["mundial"] = copa_del_mundo(anio) if toca_copa_del_mundo(anio) else {}
	return resumen

# ---------------------------------------------------------------------------
#  GUARDAR
# ---------------------------------------------------------------------------

## Los diccionarios por jugador se guardan enteros porque son pequeños de verdad:
## solo tienen fila los que han sido internacionales o llevan residencia. En un
## mundo de miles de jugadores la inmensa mayoría no aparece nunca, que es la
## misma razón por la que `Medico` guarda solo las fichas con algo dentro.
func a_dic() -> Dictionary:
	return {
		"pre": prenomina_ids,
		"nomina": nomina_ids,
		"resultados": resultados,
		"caps": _caps,
		"racha": _racha,
		"nacionalizados": _nacionalizados,
		"residencia": _residencia,
		"descanso": _descanso.keys(),
		"mundial": mundial,
		"mundial_clubes": mundial_clubes,
		"continentales": campeones_continentales,
	}

## El JSON devuelve arrays sin tipo y estos campos son `Array[String]`: asignar
## el crudo revienta al guardar la partida siguiente.
static func _ids(crudo: Variant) -> Array[String]:
	var salida: Array[String] = []
	if crudo is Array:
		for x in crudo:
			salida.append(String(x))
	return salida

func desde_dic(d: Dictionary) -> void:
	prenomina_ids = _ids(d.get("pre", []))
	nomina_ids = _ids(d.get("nomina", []))
	resultados = _ids(d.get("resultados", []))
	_caps = d.get("caps", {}).duplicate()
	_racha = d.get("racha", {}).duplicate()
	_nacionalizados = d.get("nacionalizados", {}).duplicate()
	_residencia = d.get("residencia", {}).duplicate()
	_descanso.clear()
	for id in d.get("descanso", []):
		_descanso[String(id)] = true
	mundial = d.get("mundial", {}).duplicate()
	mundial_clubes = d.get("mundial_clubes", {}).duplicate()
	campeones_continentales.clear()
	for f in d.get("continentales", []):
		campeones_continentales.append((f as Dictionary).duplicate())

func _to_string() -> String:
	return "Selección de %s (fuerza %d)" % [nombre_seleccion(), fuerza(nombre_seleccion())]
