class_name CitasRamas
extends RefCounted
## LAS RAMAS DE OTROS DEPORTES EN PERSONA (§2.5 del guion, 30-10-2026). Lo que le faltaba a la
## fase 5 (`Citas`, tipo «rama» y «celebracion»):
##  · la coordinadora de la rama no solo pide presupuesto: también VISIBILIDAD, un partido de la
##    rama en el estadio (más socios y algo de fuerza esa temporada, a cambio de desgastar el césped);
##  · cada título de una rama (puesto 1 en `Hinchada.palmares_ramas`) trae su celebración: la
##    coordinadora te espera en el museo el lunes siguiente, como el presidente con los trofeos.
## Sin `Azar`: todo sale de lo que ya pasó en la temporada.

const VISIBILIDAD_SOCIOS := 150
const VISIBILIDAD_CESPED := 6
const CELEBRACION_SOCIOS := 100

## Los títulos (puesto 1) de las ramas que lleva el club.
static func titulos(m: Mundo) -> Array:
	var t: Array = []
	if m.hinchada != null:
		for d: Dictionary in m.hinchada.palmares_ramas:
			if int(d.get("puesto", 0)) == 1:
				t.append(d)
	return t

## En `Citas.semana`: un título nuevo de una rama = una cita de celebración en el museo. Devuelve
## cuántas citas lleva la semana.
static func celebraciones(ci: Citas, m: Mundo, c: Club, prox: int, nuevas: int) -> int:
	var t := titulos(m)
	if ci._ramas_vistas >= 0 and t.size() > ci._ramas_vistas and nuevas < Citas.MAX_SEMANA:
		var d: Dictionary = t[0]   ## lo más nuevo primero
		var clave := String(d.get("clave", ""))
		if not ci._hay_clave("celebracion", prox, "rama|" + clave):
			ci._nueva(m, prox, "celebracion", Citas.nombre_ficticio("rama|" + clave + c.id),
				Idiomas.t("Coordinadora de %s") % Idiomas.t(String(d.get("rama", ""))),
				Idiomas.t("te espera en el museo con la copa de la rama"), "rama|" + clave)
			nuevas += 1
	ci._ramas_vistas = t.size()
	return nuevas

## «Darles visibilidad»: la rama juega un partido en el estadio.
static func visibilidad(m: Mundo, c: Club, ct: Dictionary) -> Dictionary:
	var clave := String(ct["clave"])
	if m.hinchada == null:
		return {}
	m.hinchada.visib_rama[clave] = m.anio
	c.socios += VISIBILIDAD_SOCIOS
	if m.ciudad != null:
		m.ciudad.cesped = clampi(m.ciudad.cesped - VISIBILIDAD_CESPED, 0, 100)
	return {"titulo": Idiomas.t("La rama, en el estadio"), "texto": Idiomas.t("Juegan un partido en tu césped: +%d socios y un poco más de fuerza esta temporada (el césped, −%d).") % [VISIBILIDAD_SOCIOS, VISIBILIDAD_CESPED]}

## La celebración de un título de la rama en el museo.
static func celebrar(m: Mundo, c: Club, ct: Dictionary, opcion: int) -> Dictionary:
	c.socios += CELEBRACION_SOCIOS
	if m.prensa != null:
		m.prensa.animo = clampi(m.prensa.animo + 2, 0, 100)
	if opcion == 0 and m.redes != null:
		m.redes.publicar(m, "victoria", [Redes.hashtag_club(c), "#Campeonas" if String(ct["clave"]) == "rama|femenino" else "#Campeones"])
		return {"titulo": Idiomas.t("¡La rama, campeona!"), "texto": Idiomas.t("La copa de la rama ya está en el museo y la foto en Tribuna (+%d socios, +2 de ánimo).") % CELEBRACION_SOCIOS}
	return {"titulo": Idiomas.t("¡La rama, campeona!"), "texto": Idiomas.t("La copa de la rama ya está en el museo (+%d socios, +2 de ánimo).") % CELEBRACION_SOCIOS}
