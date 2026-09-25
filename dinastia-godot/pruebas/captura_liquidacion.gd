extends Node
## Prueba del hallazgo de la auditoría de conectores (13-9-2026): `Banco.liquidado`
## se emitía de verdad tras 12 semanas en rojo pero nadie la escuchaba en
## `principal.gd` -el jugador seguía dirigiendo el club liquidado como si nada-.
## Fuerza la caja muy negativa y avanza el banco 13 semanas de golpe para
## comprobar que ahora sí aparece el aviso y la pantalla de ofertas.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_liquidacion.tscn

const ESPERA := 12

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		var mun = _pantalla.get("mundo")
		var c = mun.mi_club()
		c.saldo = -900000000
		print("liquidado_ya antes = %s   sin_club antes = %s" % [mun.banco.liquidado_ya, mun.roles.sin_club])
		for i in 13:
			mun.banco.semana(c)
		print("liquidado_ya despues = %s   semanas_en_rojo = %d   sin_club despues = %s" % [
			mun.banco.liquidado_ya, mun.banco.semanas_en_rojo, mun.roles.sin_club])
		_pantalla.call("_refrescar")
	if _n == ESPERA + 4:
		_guardar("res://pruebas/pantalla_liquidacion.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
