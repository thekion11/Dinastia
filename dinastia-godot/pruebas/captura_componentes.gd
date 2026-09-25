extends Node
## Verifica a ojo la Fase 2 de "el estadio por MODULOS" (16-9-2026): los 5
## componentes recien conectados -tipo de red, banderin de corner, banquillo,
## tunel y donde va el escudo- tienen que verse DISTINTOS de sus valores por
## defecto, no solo cambiar en el diccionario.
##
## NO puede correr con --headless: sin ventana no hay framebuffer.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_componentes.tscn

var _vista: VistaEstadio
var _frame := 0

func _ready() -> void:
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var mio := mundo.mi_club()
	mio.saldo = 999999999

	## Los 5 valores mas distintos de su default, para que la diferencia salte
	## a la vista sin tener que entrecerrar los ojos.
	var problema := mundo.estadio.reformar(mio, {
		"redTipo": "rombo",
		"corner": "led",
		"banquillo": "bunker",
		"tunel": "arco",
		"escudoDonde": "todo",
	}, mundo.obras)
	print("reformar los 5 componentes: '%s'" % problema)

	var p := mundo.perfil_estadio_de(mio)
	print("perfil: redTipo=%s corner=%s banquillo=%s tunel=%s escudoDonde=%s" % [
		p.get("redTipo"), p.get("corner"), p.get("banquillo"), p.get("tunel"), p.get("escudoDonde")])

	## Mismo bug que en `captura_bandejas.gd`, corregido el 22-9-2026: `mundo.
	## comercial` es Nil aqui (solo lo crea `tomar_el_mando()`), asi que esta
	## linea abortaba el resto de `_ready()` ANTES de llamar a `_vista.abrir()`
	## -visible solo en `.err.txt`, nunca en la consola-. Esta captura tampoco
	## mostraba el estadio real. `[]` usa el color de balon por defecto.
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(mio, 0.85, null, null, p, [])

func _process(_delta: float) -> void:
	_frame += 1
	## Vista general primero -para el escudo en grada/techo y el corner LED-.
	if _frame == 20:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/pantalla_componentes_general.png")
		print("captura guardada: pantalla_componentes_general.png (%dx%d)" % [img.get_width(), img.get_height()])
		## Cámara "Detrás del arco": de ahí se ve el túnel y la red de cerca.
		var rig: CameraRig = _vista.get("_rig")
		if rig != null:
			for i in rig.camera_names.size():
				if rig.camera_names[i] == "Detras del arco":
					rig.switch_to(i)
					break
	if _frame == 40:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/pantalla_componentes_arco.png")
		print("captura guardada: pantalla_componentes_arco.png (%dx%d)" % [img2.get_width(), img2.get_height()])
		print("FIN. 0 fallos")
		get_tree().quit()
