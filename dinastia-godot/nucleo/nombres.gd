class_name Nombres
extends RefCounted
## Deshace el leetspeak de los nombres del codigo fuente.
##
## Los clubes y jugadores reales estan escritos en las tablas con numeros en vez
## de letras ("C0lo-C0lo", "B0ca Juni0rs"). El juego los muestra limpios pasando
## por aqui. La regla no es un reemplazo ciego: un digito solo se convierte en
## letra si esta PEGADO a otra letra, para no destrozar "Racing 1904" ni los
## anos de fundacion.
##
## Cuidado con esto al portar cualquier cosa que compare nombres: los literales
## de las tablas siguen en leetspeak, asi que la comparacion hay que hacerla
## limpiando los dos lados, nunca uno solo. En el HTML esto ya rompio la carga de
## los 813 jugadores reales una vez.

const UNLEET := {
	"0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "8": "b", "9": "g",
}

static func limpiar(nombre: String) -> String:
	var salida := ""
	var n := nombre.length()
	for i in n:
		var c := nombre[i]
		if not UNLEET.has(c):
			salida += c
			continue
		var pegado := false
		if i > 0 and _es_letra(nombre[i - 1]):
			pegado = true
		if i + 1 < n and _es_letra(nombre[i + 1]):
			pegado = true
		salida += UNLEET[c] if pegado else c
	return salida

static func _es_letra(c: String) -> bool:
	if c.is_empty():
		return false
	var u := c.unicode_at(0)
	if (u >= 65 and u <= 90) or (u >= 97 and u <= 122):
		return true
	## Acentuadas y ene: el rango latino-1 y el latino extendido-A.
	return u >= 0xC0 and u <= 0x17F

## EL CAMINO DE VUELTA: letra → número.
##
## `limpiar()` deshace la censura para enseñar los nombres; esto la aplica, y se
## usa al IMPORTAR una base externa. Quien pega una plantilla real está metiendo
## nombres reales en el juego, y el juego no los guarda tal cual.
##
## Misma regla que `limpiar()`, al revés: solo se sustituye la letra que está
## pegada a otra letra. Así "Ari4s" sale de "Arias" pero una inicial suelta no se
## convierte en un número que no se lee.
const LEET := {
	"o": "0", "i": "1", "e": "3", "a": "4", "s": "5", "b": "8", "g": "9",
}

## Cada cuántas letras censurables se censura. Una de cada tres: censurarlas
## todas deja "C0l0-C0l0", que no se lee; una sola por nombre no disimula nada.
const CADA := 3

static func censurar(nombre: String) -> String:
	var salida := ""
	var n := nombre.length()
	var vistas := 0
	for i in n:
		var c := nombre[i]
		var min_c := c.to_lower()
		if not LEET.has(min_c):
			salida += c
			continue
		var pegado := false
		if i > 0 and _es_letra(nombre[i - 1]):
			pegado = true
		if i + 1 < n and _es_letra(nombre[i + 1]):
			pegado = true
		if not pegado:
			salida += c
			continue
		vistas += 1
		salida += LEET[min_c] if vistas % CADA == 0 else c
	return salida

## LA CUBIERTA DE LOS NOMBRES REALES (25-9-2026, pedido del usuario: "se
## necesita de nuevo esa cubierta en el nombre, ya que no está activa").
##
## Las tablas del pack real traen clubes, copas, árbitros y agentes ya
## cubiertos ("C0lo-C0lo", "Champi0ns Le4gue", "R. T0bar"), pero el juego los
## pasaba por `limpiar()` al crear el mundo y la cubierta nunca se veía. Los
## futbolistas reales (`REALES`) venían directamente en claro.
##
## Con el pack real activo, lo que sale de una tabla CONSERVA su cubierta, y lo
## que viene en claro se cubre con `censurar()`. Con la base ficticia no hay
## nada real que tapar y todo sigue limpio como antes. Se aplica al CREAR el
## nombre (club, liga, copa, árbitro, agente, jugador real): después el nombre
## guardado ya es el que se enseña en todas partes.
##
## Para comparar dos nombres se sigue usando `limpiar()` en los dos lados.
static func cubierta_activa() -> bool:
	return Datos.base_real

## Un nombre sacado de una tabla, listo para guardarlo y enseñarlo.
static func de_tabla(nombre: String) -> String:
	if not cubierta_activa():
		return limpiar(nombre)
	return nombre if limpiar(nombre) != nombre else censurar(nombre)

## Un nombre YA guardado (de un club o de un jugador), para ponerlo en un
## texto. Con la cubierta activa se deja tal cual -ya viene cubierto si es
## real, y los inventados nunca llevaron números-; sin ella, se limpia como
## siempre por si una partida vieja trajera restos de leetspeak.
static func visible(nombre: String) -> String:
	return nombre if cubierta_activa() else limpiar(nombre)

## NOMBRES VETADOS (25-9-2026). Un nombre generado al azar no puede ser el de
## un futbolista real: con las bolsas chilenas sale "Claudio Bravo" o "Vicente
## Pizarro" sin que nadie lo busque. La tabla `NOMBRES_VETADOS` trae la huella
## de cada jugador real conocido -md5 del nombre en minúsculas, 12 hex, la
## genera `herramientas/base_ficticia.py`-, así que la base publicada no lleva
## ni un nombre real legible y aun así puede evitarlos.
static var _vetados: Dictionary = {}
static var _vetados_listos := false

static func huella(nombre: String) -> String:
	return nombre.strip_edges().to_lower().md5_text().substr(0, 12)

static func vetado(nombre: String) -> bool:
	if not _vetados_listos:
		_vetados_listos = true
		if Datos.tiene("NOMBRES_VETADOS"):
			for h: Variant in Datos.tabla("NOMBRES_VETADOS"):
				_vetados[String(h)] = true
	return _vetados.has(huella(nombre))

## Llama a `sortear` hasta que devuelva un nombre no vetado. Ocho intentos
## sobran -la probabilidad de caer en uno real es del orden de 1 entre 70- y
## el tope evita un bucle infinito si una bolsa diminuta solo diera reales.
static func sin_vetar(sortear: Callable) -> String:
	var nombre: String = sortear.call()
	var intentos := 1
	while vetado(nombre) and intentos < 8:
		nombre = sortear.call()
		intentos += 1
	return nombre
