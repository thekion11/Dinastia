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
