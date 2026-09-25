extends Node
## Prueba de que `_a_la_decision_arbitral()` (la conexión nueva de
## `partido_vivo.gd` a la señal `decision_arbitral` de `Partido`) no revienta
## la pantalla en vivo, y que al menos se ve narrada si aparece.

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n != 12:
		return
	var mundo: Mundo = _pantalla.get("mundo")
	_pantalla.call("_dirigir")
	var vivo: PartidoVivo = null
	for h in _pantalla.get_children():
		if h is PartidoVivo:
			vivo = h
			break
	print("se abrio PartidoVivo = %s" % (vivo != null))
	if vivo != null:
		print("arbitro de este partido: %s (%s)" % [
			String(vivo.partido.arbitro.get("nombre", "")), String(vivo.partido.arbitro.get("perfil", ""))])
		vivo.call("_hasta_el_final")
		print("partido terminado sin reventar: %d-%d" % [vivo.partido.goles_local, vivo.partido.goles_visita])
		vivo.queue_free()
		mundo.avanzar_semana(vivo.partido)
	get_tree().quit()
