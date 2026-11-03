class_name RoperoDT
extends RefCounted
## EL ROPERO DEL DT (M-188, 3-11-2026; decisión del dueño: inventario que se guarda). Lo que compra en la tienda deportiva de la plaza: camiseta, bufanda y gorra del club,
## chándal, botines y balones. Es un diccionario `{id: cantidad}` en `Roles.ropero` (se guarda con la partida). Cada prenda se compra una sola vez; los balones se pueden repetir.
## No toca el mundo simulado (clubes, ligas, motor): solo la cartera y el ánimo del DT. `PagoCiudad.comprar` lo llena (clave `inv` del artículo).
const CATALOGO := [
	{"id": "camiseta_club", "nombre": "Camiseta del club", "precio": 40, "animo": 6, "una": true},
	{"id": "bufanda_club", "nombre": "Bufanda del club", "precio": 15, "animo": 3, "una": true},
	{"id": "gorra_club", "nombre": "Gorra del club", "precio": 12, "animo": 2, "una": true},
	{"id": "chandal", "nombre": "Chándal de entrenamiento", "precio": 55, "animo": 4, "una": true},
	{"id": "botines", "nombre": "Botines de tacos", "precio": 70, "animo": 5, "una": true},
	{"id": "balon", "nombre": "Balón de entrenamiento", "precio": 25, "animo": 3, "una": false},
	{"id": "balon_playa", "nombre": "Balón de playa", "precio": 8, "animo": 1, "una": false},
]

static func articulo(id: String) -> Dictionary:
	for a: Dictionary in CATALOGO:
		if String(a["id"]) == id:
			return a
	return {}

static func tiene(ropero: Dictionary, id: String) -> bool:
	return int(ropero.get(id, 0)) > 0

## ¿Se puede comprar? («una» = prenda única).
static func puede(ropero: Dictionary, id: String) -> bool:
	var a := articulo(id)
	return not a.is_empty() and not (bool(a.get("una", true)) and tiene(ropero, id))

static func agregar(ropero: Dictionary, id: String) -> void:
	ropero[id] = int(ropero.get(id, 0)) + 1

## El surtido que ve la caja: cada artículo con su clave `inv` y la energía (ánimo) que da al comprarlo; las prendas que ya tiene salen marcadas.
static func surtido(ropero: Dictionary) -> Array:
	var s: Array = []
	for a: Dictionary in CATALOGO:
		var it := a.duplicate()
		it["inv"] = String(a["id"])
		it["hambre"] = 0
		it["energia"] = int(a.get("animo", 0))
		if not puede(ropero, String(a["id"])):
			it["nombre"] = Idiomas.t(String(a["nombre"])) + " ✔"
		s.append(it)
	return s

## «Tu ropero: camiseta del club, balón ×2…» (vacío si no hay nada).
static func resumen(ropero: Dictionary) -> String:
	var partes: PackedStringArray = []
	for a: Dictionary in CATALOGO:
		var n := int(ropero.get(String(a["id"]), 0))
		if n > 0:
			partes.append(Idiomas.t(String(a["nombre"])) + (" ×%d" % n if n > 1 else ""))
	return ", ".join(partes)
