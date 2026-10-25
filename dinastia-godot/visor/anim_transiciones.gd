class_name AnimTransiciones
extends Node
## LAS PIERNAS QUE NO SE CRUZAN AL CAMBIAR DE PASO (pani, 25-10-2026). El motor
## cambia de clip de locomoción según la velocidad (parado, trotar, correr,
## conducir, trotar hacia atrás...) y cada clip nuevo empezaba en su fotograma
## 0: si el jugador iba con la pierna izquierda en el aire, durante la mezcla
## (0,2 s) las dos piernas se cruzaban -medido con
## `pruebas/ideas/pani_sonda_pies.gd`: saltos de pose de los muslos y las
## pantorrillas en cada cambio trotar ↔ correr-.
##
## Este nodo cuelga del AnimationPlayer del jugador. Apunta en qué punto del
## paso va el clip de locomoción (cada fotograma, en `_process`: `mixer_updated`
## no llega con `advance()`) y, cuando empieza otro de la misma familia
## (`current_animation_changed`, que llega dentro del propio `play()`), lo
## coloca en la MISMA fase del paso: el pie que estaba apoyado sigue apoyado.
## Las fases las mide `AnimPasos` al construir la librería.
##
## Además, el primer «parado» de cada jugador empieza en un punto distinto del
## ciclo (el mismo para el mismo id), para que los 22 no respiren a la vez.

var _ap: AnimationPlayer
var _clip := ""
var _fase := 0.0

static func poner(ap: AnimationPlayer, semilla: String = "") -> AnimTransiciones:
	if ap == null or ap.get_node_or_null("AnimTransiciones") != null:
		return null
	var t := AnimTransiciones.new()
	t.name = "AnimTransiciones"
	t._ap = ap
	ap.add_child(t)
	ap.current_animation_changed.connect(t._al_cambiar)
	if semilla != "" and ap.current_animation != "":
		var largo := ap.current_animation_length
		ap.seek(fposmod(float(absi(semilla.hash()) % 1000) / 1000.0, 1.0) * largo, true)
	return t

## Fase del paso (0 = apoya el pie izquierdo) de un clip en el instante `pos`.
static func fase_de(clip: String, pos: float, largo: float) -> float:
	return fposmod(pos / maxf(largo, 0.001) - float(AnimPasos.fases.get(clip, 0.0)), 1.0)

func _process(_d: float) -> void:
	apuntar()

func apuntar() -> void:
	var c := String(_ap.current_animation)
	if AnimPasos.fases.has(c):
		_clip = c
		_fase = fase_de(c, _ap.current_animation_position, _ap.current_animation_length)
	else:
		_clip = ""

func _al_cambiar(nuevo: String) -> void:
	if _clip == "" or not AnimPasos.fases.has(nuevo) or not _ap.has_animation(nuevo):
		_clip = ""
		return
	var largo := _ap.get_animation(nuevo).length
	_ap.seek(fposmod(_fase + float(AnimPasos.fases[nuevo]), 1.0) * largo, false)
	_clip = nuevo
