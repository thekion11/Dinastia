extends Node
## MICROBENCHMARK de `AnimTransiciones.apuntar()` / `_process` (13-11, sesión 16, optimización de código): el caso habitual de un partido, un reproductor
## que corre un clip con fase (`AnimPasos.fases`). Mide el coste directo de una llamada (200 000) y la firma del resultado (fase y clip), que no debe cambiar.
##   godot --headless --path . res://pruebas/micro_transiciones.tscn
func _ready() -> void:
	AnimPasos.fases = {"correr": 0.25, "trotar": 0.6}
	var ap := AnimationPlayer.new()
	add_child(ap)
	var lib := AnimationLibrary.new()
	for nom in ["correr", "trotar", "parado"]:
		var a := Animation.new()
		a.length = 0.8
		a.loop_mode = Animation.LOOP_LINEAR
		lib.add_animation(nom, a)
	ap.add_animation_library("", lib)
	ap.play("correr")
	var t := AnimTransiciones.poner(ap)
	for i in 5:
		await get_tree().process_frame
	ap.seek(0.31, true)
	t.apuntar()
	print("MICRO_TRANS firma: clip=%s fase=%.5f" % [t._clip, t._fase])
	var n := 200000
	var t0 := Time.get_ticks_usec()
	for k in n:
		t.apuntar()
	var us := float(Time.get_ticks_usec() - t0) / float(n)
	print("MICRO_TRANS apuntar(): %.3f us por llamada → 50 reproductores = %.1f us por fotograma" % [us, us * 50.0])
	## Cambio de clip: la fase se conserva (`_al_cambiar`).
	ap.play("trotar")
	t._al_cambiar("trotar")
	print("MICRO_TRANS tras cambiar a trotar: clip=%s pos=%.5f" % [t._clip, ap.current_animation_position])
	get_tree().quit()
