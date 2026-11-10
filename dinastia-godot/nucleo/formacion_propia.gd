class_name FormacionPropia
extends RefCounted
## FORMACIONES PROPIAS (10-11-2026, pedido del dueño: «que el usuario pueda crear sus formaciones moviendo a los jugadores
## donde quiera, como en el PES 2020»). Como en el «Editar posición» del Plan de juego del PES: se parte de una formación BASE,
## se arrastra cada ficha por el campo y el PUESTO CAMBIA SOLO según la zona donde se suelta (un central que sube al medio pasa
## a mediocentro defensivo; un medio que se abre a la banda, a interior). El portero no se mueve. Al guardarla con un nombre
## queda en la pizarra junto a las de serie y la usan, sin cambiar nada más, el once, el partido 3D y los dos motores: se
## REGISTRA en la tabla `FORMS` (las mismas casillas [puesto, x %, y %]; y = 0 el arco rival, 100 el propio; x = 0 la banda
## izquierda). Se guardan en la táctica del club (`Tactica.propias`) y viajan en la partida.
## Como avisa la guía de PES: moverlas mucho de su base cambia carreras y pases (el motor coloca a cada uno según su casilla).

const PREFIJO := "★ "
const MAX_PROPIAS := 6
const MIN_DEFENSAS := 3
## Límites del campo para las fichas de campo (en %): ni dentro del área propia ni pegadas a las líneas.
const Y_MIN := 12.0
const Y_MAX := 86.0
const X_MIN := 6.0
const X_MAX := 94.0

## El puesto que corresponde a una casilla del tablero (zonas como las de las formaciones de serie: bandas por fuera de x 24/76,
## carrileros entre y 54 y 70, como los de 3-5-2 y 5-3-2).
static func puesto_de(x: float, y: float) -> String:
	var banda := x >= 76.0 or x <= 24.0
	var derecha := x >= 50.0
	if banda:
		if y >= 70.0:
			return "LD" if derecha else "LI"
		if y >= 54.0:
			return "CAD" if derecha else "CAI"
		if y >= 28.0:
			return "MD" if derecha else "MI"
		return "ED" if derecha else "EI"
	if y >= 70.0:
		return "DFC"
	if y >= 58.0:
		return "MCD"
	if y >= 40.0:
		return "MC"
	if y >= 28.0:
		return "MCO"
	return "DC"

static func linea_de(puesto: String) -> String:
	match puesto:
		"POR": return "POR"
		"LD", "LI", "DFC", "CAD", "CAI": return "DEF"
		"DC", "ED", "EI", "SD": return "DEL"
	return "MED"

## Una formación editable a partir de una de la tabla (copia profunda de sus casillas).
static func desde(nombre_base: String) -> Dictionary:
	var forms: Dictionary = Datos.tabla("FORMS")
	var f: Dictionary = forms.get(nombre_base, forms.get("4-3-3", {}))
	var s: Array = []
	for c: Array in f.get("s", []):
		s.append([String(c[0]), float(c[1]), float(c[2])])
	return contar({"s": s, "base": String(f.get("base", nombre_base))})

## Cuenta las líneas (DEF, MED, DEL) como las formaciones de serie. (Los puestos NO se recalculan aquí: como en el PES, solo
## cambia el de la ficha que se mueve; las casillas de serie conservan el suyo.)
static func contar(f: Dictionary) -> Dictionary:
	var n := {"DEF": 0, "MED": 0, "DEL": 0}
	for c: Array in f["s"]:
		if String(c[0]) != "POR":
			n[linea_de(String(c[0]))] = int(n[linea_de(String(c[0]))]) + 1
	for k: String in n:
		f[k] = n[k]
	return f

## Mueve la ficha `i` a (x, y) en %. Devuelve "" si se pudo o el motivo si no (el portero no se mueve; mínimo de defensas).
static func mover(f: Dictionary, i: int, x: float, y: float) -> String:
	var s: Array = f["s"]
	if i < 0 or i >= s.size():
		return "ficha"
	if String(s[i][0]) == "POR":
		return "portero"
	var antes: Array = (s[i] as Array).duplicate()
	s[i][1] = roundf(clampf(x, X_MIN, X_MAX))
	s[i][2] = roundf(clampf(y, Y_MIN, Y_MAX))
	s[i][0] = puesto_de(float(s[i][1]), float(s[i][2]))
	contar(f)
	if int(f["DEF"]) < MIN_DEFENSAS:
		s[i] = antes
		contar(f)
		return "defensas"
	return ""

## El nombre con el que se guarda (siempre con la estrella: no pisa nunca a una de serie).
static func nombre_valido(nombre: String) -> String:
	var n := nombre.strip_edges().replace(PREFIJO, "").left(24)
	return PREFIJO + (n if n != "" else "Mi formación")

## Guarda la formación en la táctica del club y la registra en la tabla. Devuelve el nombre final ("" si no cabe).
static func guardar(t: Tactica, nombre: String, f: Dictionary) -> String:
	var n := nombre_valido(nombre)
	if not t.propias.has(n) and t.propias.size() >= MAX_PROPIAS:
		return ""
	t.propias[n] = contar(f.duplicate(true))
	registrar(n, t.propias[n])
	return n

static func borrar(t: Tactica, nombre: String) -> void:
	t.propias.erase(nombre)
	var forms: Dictionary = Datos.tabla("FORMS")
	forms.erase(nombre)
	if t.formacion == nombre:
		t.formacion = "4-3-3"

static func registrar(nombre: String, f: Dictionary) -> void:
	var forms: Dictionary = Datos.tabla("FORMS")
	forms[nombre] = f

## Al cargar la partida (o crear el mundo): vuelve a registrar las formaciones propias de un club.
static func registrar_todas(t: Tactica) -> void:
	for n: String in t.propias:
		registrar(n, t.propias[n])

static func es_propia(nombre: String) -> bool:
	return nombre.begins_with(PREFIJO)
