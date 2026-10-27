class_name PresetsTactica
extends RefCounted
## PRESETS DE FORMACIÓN Y TÁCTICA CON NOMBRE (27-10-2026, fila 382): el DT guarda su pizarra entera («Contra el grande», «Ir a por el partido») y la
## recupera con un clic; también se borran. Es del DT, no del club (vive en `Roles`, se guarda con la partida y le sigue si cambia de equipo).
## Un preset lleva la formación, las perillas, los interruptores, los córners/libres y los planes por marcador; NO el once ni los roles por jugador
## (los jugadores son de cada club). Cargar uno con otra formación suelta el once elegido (las ranuras son otras), como al cambiar de dibujo.
const MAX := 12
const LARGO_NOMBRE := 24
const CAMPOS_INT := ["mentalidad", "presion", "ritmo", "linea", "amplitud", "verticalidad", "tras_perdida"]
const CAMPOS_BOOL := ["salida_corta", "marca_al_hombre", "fuera_de_juego", "tiro_lejano"]
const CAMPOS_TXT := ["formacion", "corner", "libre", "plan_perdiendo", "plan_ganando"]

var datos := {}   ## nombre → {campo: valor}

## Los nombres, por orden alfabético.
func nombres() -> Array:
	var l := datos.keys()
	l.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)
	return l

static func limpiar_nombre(n: String) -> String:
	return n.strip_edges().left(LARGO_NOMBRE)

## "" si se guardó (nuevo o encima de otro del mismo nombre); si no, el motivo (ya traducido).
func guardar(nombre: String, t: Tactica) -> String:
	var n := limpiar_nombre(nombre)
	if n == "":
		return Idiomas.t("Ponle un nombre al preset.")
	if not datos.has(n) and datos.size() >= MAX:
		return Idiomas.t("Ya tienes %d presets: borra alguno antes de guardar otro.") % MAX
	var d := {}
	for c: String in CAMPOS_INT:
		d[c] = int(t.get(c))
	for c: String in CAMPOS_BOOL:
		d[c] = bool(t.get(c))
	for c: String in CAMPOS_TXT:
		d[c] = String(t.get(c))
	datos[n] = d
	return ""

## Aplica el preset a la táctica de `club`. "" si se cargó; si no, el motivo. Una formación que ya no existe se ignora (el resto sí se aplica).
func cargar(nombre: String, club: Club) -> String:
	if not datos.has(nombre) or club == null or club.tactica == null:
		return Idiomas.t("Ese preset no existe.")
	var d: Dictionary = datos[nombre]
	var t := club.tactica
	var forma_antes := t.formacion
	for c: String in CAMPOS_INT:
		if d.has(c):
			t.set(c, clampi(int(d[c]), 0, 2))
	for c: String in CAMPOS_BOOL:
		if d.has(c):
			t.set(c, bool(d[c]))
	for c: String in CAMPOS_TXT:
		if d.has(c) and (c != "formacion" or Datos.tabla("FORMS").has(String(d[c]))):
			t.set(c, String(d[c]))
	if t.formacion != forma_antes:
		club.limpiar_once()
	return ""

func borrar(nombre: String) -> bool:
	return datos.erase(nombre)

func a_dict() -> Dictionary:
	return datos.duplicate(true)

func desde_dict(d: Dictionary) -> void:
	datos.clear()
	for k in d:
		if d[k] is Dictionary and datos.size() < MAX:
			datos[String(k)] = (d[k] as Dictionary).duplicate(true)
