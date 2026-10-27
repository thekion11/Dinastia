class_name AfinidadClub
extends RefCounted
## LA AFINIDAD CON LA GENTE DEL CLUB (fase 4, bloque 7, 26-10-2026). Plan §2.2d, fila 7:
## *«el personal del club saluda por nombre y recuerda la última charla; afinidad 0-100 que
## sube por charla diaria y baja por semanas sin hablar»*.
##
## Solo datos y reglas, sin nodos ni `Azar`: la afinidad solo cambia TEXTOS (la frase de pasillo
## del diálogo del personal, `RecorridoCharla.pasillo`). No toca el partido ni la economía.
## La clave es el nombre con que `PersonalEstadio` presenta a cada persona.

const INICIAL := 50
const MAXIMO := 100
## Lo que sube la primera charla de cada día y lo que baja una semana sin hablar.
const SUBE_POR_CHARLA := 2
const BAJA_POR_SEMANA := 1
## Por debajo de FRIO la persona es «fría»; desde CERCANO, «cercana»; entre medias, «normal».
const FRIO := 35
const CERCANO := 70

## nombre → afinidad. Solo están quienes ya hablaron contigo: el resto vale `INICIAL`.
var valores: Dictionary = {}
## nombre → "anio|semana|dia" de su última charla (para sumar solo una vez al día).
var _ultimo_dia: Dictionary = {}
## nombre → "anio|semana" de la última semana en que hablaste con la persona.
var _ultima_semana: Dictionary = {}

func valor(nombre: String) -> int:
	return int(valores.get(nombre, INICIAL))

## Registra una charla. Devuelve true si sumó (la primera del día para esa persona).
func charlar(nombre: String, anio: int, semana: int, dia: int) -> bool:
	if nombre == "":
		return false
	_ultima_semana[nombre] = "%d|%d" % [anio, semana]
	var hoy := "%d|%d|%d" % [anio, semana, dia]
	if String(_ultimo_dia.get(nombre, "")) == hoy:
		return false
	_ultimo_dia[nombre] = hoy
	valores[nombre] = mini(MAXIMO, valor(nombre) + SUBE_POR_CHARLA)
	return true

## Al cerrar una semana (`Mundo._semana_modulos_del_club`, antes de `semana += 1`): baja un
## punto a quien conoces y no habló contigo en esa semana.
func semana(anio: int, sem: int) -> void:
	var esta := "%d|%d" % [anio, sem]
	for nombre: String in valores.keys():
		if String(_ultima_semana.get(nombre, "")) != esta:
			valores[nombre] = maxi(0, int(valores[nombre]) - BAJA_POR_SEMANA)

## "frio" (< 35), "normal" o "cercano" (≥ 70).
func tramo(nombre: String) -> String:
	var v := valor(nombre)
	if v < FRIO:
		return "frio"
	return "cercano" if v >= CERCANO else "normal"

func a_dic() -> Dictionary:
	return {"valores": valores.duplicate(), "ultimo_dia": _ultimo_dia.duplicate(), "ultima_semana": _ultima_semana.duplicate()}

func desde_dic(d: Dictionary) -> void:
	valores.clear()
	_ultimo_dia.clear()
	_ultima_semana.clear()
	var v: Dictionary = d.get("valores", {})
	for k: Variant in v:
		valores[String(k)] = clampi(int(v[k]), 0, MAXIMO)
	var u: Dictionary = d.get("ultimo_dia", {})
	for k: Variant in u:
		_ultimo_dia[String(k)] = String(u[k])
	var s: Dictionary = d.get("ultima_semana", {})
	for k: Variant in s:
		_ultima_semana[String(k)] = String(s[k])
