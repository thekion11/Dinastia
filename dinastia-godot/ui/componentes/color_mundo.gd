class_name ColorMundo
extends RefCounted
## UN COLOR POR MUNDO DE JUEGO (16-11, frente 1; pedido del dueño del 15-11 en `PLAN_GENERAL.md`, «Mundo suave, fase 2»):
## cada forma de jugar se reconoce por su color, como los modos de los juegos de fútbol de hoy.
##  · DIRIGIR (entrenador, ayudante, cantera, interino): verde pizarra.
##  · MANDAR (presidente o dueño del club): negro y oro.
##  · RETOS (una partida con un reto montado): naranja.
##  · LA RUTA (modo jugador) tiene su propia estética («noche de estadio», azul noche y magenta) en `RutaEstilo`: aquí no entra.
## Lo usan el menú central (pestañas del mosaico y filo de sus tarjetas), la barra de ayudas y, por `Tema.al_mundo`, la portada y la cabecera
## de los menús a pantalla completa; el foco de las tarjetas
## sigue con el color del CLUB (que es tu identidad).

const DIRIGIR := Color("4fae7b")   ## verde pizarra (acento claro para leerse sobre el fondo oscuro)
const MANDAR := Color("d4af37")    ## oro (sobre el negro del fondo)
const RETOS := Color("ef8a2b")     ## naranja

## «dirigir», «mandar» o «retos» según la partida.
static func mundo_de(m: Mundo) -> String:
	if m == null:
		return "dirigir"
	if not m.reto.is_empty():
		return "retos"
	if m.roles != null and String(m.roles.rol) in ["dir", "dueño"]:
		return "mandar"
	return "dirigir"

## Vuelca el mundo de la partida en `Tema` (variables), para que lo lean las pantallas que no reciben el mundo.
static func aplicar(m: Mundo) -> void:
	Tema.mundo = mundo_de(m)
	Tema.acento_mundo = acento(m)
	match Tema.mundo:
		"mandar": Tema.fondo_mundo = Color("0b0a08")
		"retos": Tema.fondo_mundo = Color("1a0f05")
		_: Tema.fondo_mundo = Tema.FONDO

static func acento(m: Mundo) -> Color:
	match mundo_de(m):
		"mandar": return MANDAR
		"retos": return RETOS
	return DIRIGIR

## El fondo de las tarjetas, teñido apenas del mundo (Mandar: casi negro; los demás, su tono muy oscuro).
static func fondo_tarjeta(m: Mundo) -> Color:
	var base := Color(0.03, 0.06, 0.045, 0.86)
	match mundo_de(m):
		"mandar": return Color(0.03, 0.03, 0.03, 0.9)
		"retos": return Color(0.07, 0.045, 0.02, 0.88)
	return base
