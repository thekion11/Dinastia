extends Node
## El azar del juego, con semilla.
##
## El HTML usa `Math.random()` a pelo, sin semilla. Eso significa que dos
## partidas con la misma configuracion nunca dan lo mismo y que el banco de
## pruebas no puede comparar una ejecucion con la anterior: solo puede mirar si
## algo revienta. Aqui se arregla desde el principio, porque despues cuesta.
##
## Con semilla se gana:
##  - Un banco de pruebas que compara de verdad (misma semilla, mismo resultado).
##  - Poder reproducir el fallo que reporte el usuario: basta su numero de semilla.
##  - Partidas compartibles ("juega mi mundo") sin guardar un fichero entero.
##
## Consecuencia de esto: la migracion NO se puede verificar comparando huellas
## contra el HTML, porque el HTML no es reproducible ni consigo mismo. Se
## verifica por distribucion (medias, curvas, sumas) y por invariantes, que es
## lo que hace `pruebas/banco.gd`.

var _rng := RandomNumberGenerator.new()
var semilla: int = 0

func _ready() -> void:
	sembrar(0)

## Semilla 0 = una al azar, y se guarda para poder repetirla luego.
func sembrar(s: int) -> int:
	if s == 0:
		_rng.randomize()
		## La semilla se guarda en positivo: `seed` es un entero sin signo de 64
		## bits y al leerlo con signo salia en pantalla como -3988284697144550724,
		## que nadie va a copiar bien para repetir una partida.
		semilla = absi(int(_rng.seed))
		_rng.seed = semilla
	else:
		semilla = s
		_rng.seed = s
	## OJO: NO tocar `_rng.state` aqui. `seed` y `state` son cosas distintas, y
	## fijar el estado a mano deja el generador en un punto fijo que ya no
	## depende de la semilla: dos semillas distintas daban el MISMO mundo. Lo
	## caza la prueba "otra semilla, otro mundo" del banco.
	return semilla

## Entero en [a,b], ambos incluidos. Equivale al R(a,b) del HTML.
func ent(a: int, b: int) -> int:
	if b < a:
		return a
	return _rng.randi_range(a, b)

## Real en [0,1). Equivale al RF() del HTML.
func f() -> float:
	return _rng.randf()

## Un elemento cualquiera del array. Equivale al pick() del HTML.
func uno(a: Array) -> Variant:
	if a.is_empty():
		return null
	return a[_rng.randi_range(0, a.size() - 1)]

## Cierto con probabilidad p.
func suerte(p: float) -> bool:
	return _rng.randf() < p

## Normal recortada: para repartir atributos sin que salgan planos.
func campana(centro: float, desvio: float, minimo: float, maximo: float) -> float:
	return clampf(_rng.randfn(centro, desvio), minimo, maximo)

## Baraja en el sitio. La de Godot usa su propio generador global, que no
## respeta la semilla de aqui: por eso se implementa a mano.
func barajar(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var k := _rng.randi_range(0, i)
		var t: Variant = a[i]
		a[i] = a[k]
		a[k] = t
