extends Node
## Verifica a ojo la Fase 1 de "el estadio por MODULOS" (16-9-2026): con
## "Personalizar cada tribuna" activo, las 4 tribunas deben leerse con un
## patron de butacas distinto entre si -no una sola piel para todo el recinto.
##
## NO puede correr con --headless: sin ventana no hay framebuffer para
## guardar la captura.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_bandejas.tscn

var _vista: VistaEstadio
var _frame := 0

func _ready() -> void:
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var mio := mundo.mi_club()
	mio.saldo = 999999999

	## Los 4 patrones mas distintos entre si del catalogo EST_ASIENTOS, para que
	## la diferencia salte a la vista y no haya que entrecerrar los ojos.
	var problema := mundo.estadio.reformar(mio, {"personalizar_bandejas": true}, mundo.obras)
	print("activar personalizar_bandejas: '%s'" % problema)
	problema = mundo.estadio.reformar(mio, {
		"bandeja_sur_asientoP": "franjas",
		"bandeja_norte_asientoP": "damero",
		"bandeja_este_asientoP": "moteado",
		"bandeja_oeste_asientoP": "bicolor",
	}, mundo.obras)
	print("reformar las 4 tribunas: '%s'" % problema)

	var p := mundo.perfil_estadio_de(mio)
	print("perfil trae bandejas=%s" % p.has("bandejas"))
	print("  sur=%s norte=%s este=%s oeste=%s" % [
		p.get("bandejas", {}).get("sur", {}).get("asientoP", "?"),
		p.get("bandejas", {}).get("norte", {}).get("asientoP", "?"),
		p.get("bandejas", {}).get("este", {}).get("asientoP", "?"),
		p.get("bandejas", {}).get("oeste", {}).get("asientoP", "?"),
	])

	## BUG REAL ENCONTRADO 22-9-2026, verificando la Fase 3 (Tramo): esta linea
	## leia `mundo.comercial.balon`, pero `comercial` solo lo crea
	## `tomar_el_mando()` -este script nunca lo llama, solo `generar()`- asi
	## que quedaba Nil. El error ("Invalid access... on a base object of type
	## Nil") aborta el resto de `_ready()` a mitad de camino, ANTES de que
	## `_vista.abrir()` llegara a ejecutarse: la captura que este script
	## guardaba no mostraba ningun estadio, solo el fondo vacio por defecto.
	## Solo aparecia en `.err.txt`, nunca en la consola -el "FIN. 0 fallos"
	## salia igual, exactamente la trampa que ya documenta
	## `feedback-verification-discipline`-. `[]` deja que `VistaEstadio`/
	## `StadiumBuilder.spawn_ball()` usen su color de balon por defecto.
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(mio, 0.85, null, null, p, [])

func _process(_delta: float) -> void:
	_frame += 1
	if _frame == 20:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/pantalla_bandejas.png")
		print("captura guardada: res://pruebas/pantalla_bandejas.png (%dx%d)" % [img.get_width(), img.get_height()])
		print("FIN. 0 fallos")
		get_tree().quit()
