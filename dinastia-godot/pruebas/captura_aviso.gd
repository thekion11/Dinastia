extends Node
## Los avisos deslizantes, ahora con TIPOS: cada uno con su etiqueta, su color
## y su sonido. Se disparan cuatro de golpe para probar la cola -al cerrar una
## temporada pueden caer varios y sin cola el último pisaría al primero-.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_aviso.tscn

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
		var mio = mun.mi_club()
		var otro: Club = null
		for c in mun.ligas[0].clubes:
			if c != mio:
				otro = c
				break
		## Cuatro tipos distintos, por los cuatro caminos reales.
		mun.logros.logro_desbloqueado.emit("primer_titulo", "🏆",
			"Primer título", "Levantaste tu primer trofeo como entrenador.")
		mun.cesiones.clausula_pagada.emit(mio.plantilla[0], mio, otro, 12500000)
		mun.mercado.oferta_recibida.emit(mio.plantilla[1], otro, 8400000)
		mun.logros.titulo_celebrado.emit("Copa de Chile")
	if _n == ESPERA + 12:
		_guardar("res://pruebas/pantalla_aviso1.png")
	if _n == ESPERA + 250:
		_guardar("res://pruebas/pantalla_aviso2.png")
	if _n == ESPERA + 490:
		_guardar("res://pruebas/pantalla_aviso3.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
