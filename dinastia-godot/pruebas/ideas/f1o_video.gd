extends Control
## VÍDEO DE LA ENTRADA (fase 1, 25-10-2026): el mismo recorrido que `f1o_captura_flujo.gd`, pero
## pensado para el Movie Maker de Godot: ~3-6 s por pantalla, algo de interacción simulada
## (flechas para mover la selección, el globo girando entre países) y los fundidos de verdad.
##   xvfb-run -a godot --path . --rendering-method forward_plus --resolution 1280x720 \
##     --write-movie /tmp/x/entrada.avi --fixed-fps 30 res://pruebas/ideas/f1o_video.tscn
## El .avi va SIEMPRE fuera del repo.

const RESPUESTAS := {
	"idioma": {"idioma": "es"},
	"modo": {"modo": "creador"},
	"pais": {"pais": "ARG"},
	"config": {"nombre_club": "Club Dinastía"},
	"entrada": {"entrada": "reemplazar"},
	"personaje": {"personaje": {"nombre": "Míster"}},
}
const TIEMPOS := {"intro": 6.0, "idioma": 4.0, "modo": 4.0, "pais": 7.0, "config": 5.0,
	"entrada": 4.0, "personaje": 5.0}

func _esperar(seg: float) -> void:
	await get_tree().create_timer(seg).timeout

func _tecla(accion: String) -> void:
	var e := InputEventAction.new()
	e.action = accion
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame
	var s := InputEventAction.new()
	s.action = accion
	s.pressed = false
	Input.parse_input_event(s)

## Mueve la selección un par de veces y vuelve, como quien mira las opciones.
func _ojear(tiempo: float) -> void:
	await _esperar(tiempo * 0.3)
	for a: String in ["ui_right", "ui_down", "ui_left", "ui_up"]:
		await _tecla(a)
		await _esperar(tiempo * 0.15)
	await _esperar(tiempo * 0.1)

func _ready() -> void:
	OrquestadorEntrada.ruta_prefs = "user://f1o_video_entrada.cfg"
	OrquestadorMundo.ruta_preferencias = "user://f1o_video_prefs.cfg"
	## 1) El menú de inicio con «Nuevo juego».
	var inicio: Control = (load("res://escenas/inicio.tscn") as PackedScene).instantiate()
	add_child(inicio)
	await _esperar(4.0)
	## Fundido a negro simulando el clic en «Nuevo juego».
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.z_index = 100
	add_child(velo)
	var tw := create_tween()
	tw.tween_property(velo, "color:a", 1.0, 0.4)
	await tw.finished
	inicio.queue_free()
	## 2) El flujo con sus fundidos.
	var o := OrquestadorEntrada.new()
	o.cambiar_escena = false
	o.forzar_intro = true
	add_child(o)
	move_child(velo, -1)
	var tw2 := create_tween()
	tw2.tween_property(velo, "color:a", 0.0, 0.4)
	for _i in 12:
		await _esperar(0.3)
		while o.get("_en_transicion"):
			await get_tree().process_frame
		var k := o.etapa_actual()
		var p := o.pantalla_actual()
		if p == null or k == "":
			break
		var t: float = TIEMPOS.get(k, 4.0)
		print("etapa ", k)
		if k == "pais" and p.has_method("globo"):
			await _esperar(1.0)
			for pais: String in ["BRA", "ESP", "ARG"]:
				p.call("_elegir", pais)
				await _esperar(2.0)
		elif k == "intro":
			await _esperar(t)
		else:
			await _ojear(t)
		if k == "personaje":
			break
		if not is_instance_valid(p) or o.etapa_actual() != k:
			continue ## la intro avanza sola
		p.emit_signal("terminado", (RESPUESTAS.get(k, {}) as Dictionary).duplicate(true))
	var tw3 := create_tween()
	tw3.tween_property(velo, "color:a", 1.0, 0.6)
	await tw3.finished
	DirAccess.remove_absolute(ProjectSettings.globalize_path(OrquestadorEntrada.ruta_prefs))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(OrquestadorMundo.ruta_preferencias))
	get_tree().quit()
