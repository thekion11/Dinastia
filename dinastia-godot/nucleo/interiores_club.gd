class_name InterioresClub
extends RefCounted
## LAS SALAS DEL CLUB, A TU GUSTO (estadio interactivo 2.0, fase 5).
##
## Pedido: «todas las habitaciones personalizables, colores, poner decoración,
## las fotos sacadas poder ponerlas en las paredes, oficina con objetos
## propios». Cada sala del edificio del club (`EdificioClub.PLANTAS`) guarda:
##   pared, suelo  color en hex ("" = el de fábrica)
##   deco          lista de claves del CATALOGO, una por hueco (6 huecos)
##   fotos         rutas de `ModoFoto` (user://fotos/*.png), una por marco (4)
## Se guarda con la partida (`Partida`) y el edificio lo pinta al montarse.

const HUECOS := 6
const MARCOS := 4

## clave -> [nombre, icono, ¿solo en la oficina del DT?]
const CATALOGO := {
	"planta": ["Planta", "🪴", false],
	"sofa": ["Sofá", "🛋️", false],
	"trofeo": ["Trofeo", "🏆", false],
	"bandera": ["Bandera del club", "🚩", false],
	"tele": ["Televisión", "📺", false],
	"alfombra": ["Alfombra", "🟥", false],
	"lampara": ["Lámpara de pie", "💡", false],
	"estanteria": ["Estantería", "📚", false],
	"cafe": ["Máquina de café", "☕", false],
	"balon": ["Balón firmado", "⚽", false],
	"bufanda": ["Tu bufanda", "🧣", true],
	"pizarra": ["Tu pizarra táctica", "📋", true],
	"maqueta": ["Maqueta del estadio", "🏟️", true],
	"guitarra": ["Tu guitarra", "🎸", true],
}

## Colores a elegir para paredes y suelos.
const COLORES := ["", "f2f0ea", "dfe7ee", "e9dcc9", "c9d8c5", "2b2f36", "7a1f2b", "1f3f6b", "8a6a4a", "4d4d4d"]

## sala -> {pared, suelo, deco: [], fotos: []}
var salas: Dictionary = {}

func sala(nombre: String) -> Dictionary:
	if not salas.has(nombre):
		var deco: Array = []
		deco.resize(HUECOS)
		deco.fill("")
		var fotos: Array = []
		fotos.resize(MARCOS)
		fotos.fill("")
		salas[nombre] = {"pared": "", "suelo": "", "deco": deco, "fotos": fotos}
	return salas[nombre]

func pintar(nombre: String, que: String, color: String) -> void:
	sala(nombre)[que] = color

## Pone `clave` en el primer hueco libre. Devuelve false si no cabe.
func poner(nombre: String, clave: String) -> bool:
	if not CATALOGO.has(clave):
		return false
	if bool(CATALOGO[clave][2]) and nombre != "Oficina del DT":
		return false
	var deco: Array = sala(nombre)["deco"]
	var i := deco.find("")
	if i < 0:
		return false
	deco[i] = clave
	return true

func quitar_ultima(nombre: String) -> void:
	var deco: Array = sala(nombre)["deco"]
	for i in range(deco.size() - 1, -1, -1):
		if String(deco[i]) != "":
			deco[i] = ""
			return

## Cuelga una foto en el primer marco libre (o en el último si están todos).
func colgar(nombre: String, ruta: String) -> void:
	var fotos: Array = sala(nombre)["fotos"]
	var i := fotos.find("")
	fotos[i if i >= 0 else fotos.size() - 1] = ruta

func descolgar(nombre: String) -> void:
	var fotos: Array = sala(nombre)["fotos"]
	for i in range(fotos.size() - 1, -1, -1):
		if String(fotos[i]) != "":
			fotos[i] = ""
			return

func a_dic() -> Dictionary:
	return salas.duplicate(true)

func desde_dic(d: Dictionary) -> void:
	salas = d.duplicate(true)
