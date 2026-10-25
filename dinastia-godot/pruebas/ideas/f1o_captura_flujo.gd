extends Control
## CAPTURAS DE LA ENTRADA (fase 1, 25-10-2026): el menú con «Nuevo juego» y cada etapa del
## `OrquestadorEntrada` tal como la ve el jugador, más un fotograma a mitad de fundido.
##   CAPTURA_SIN_CERROJO=1 flock /tmp/godot.lock herramientas/captura.sh res://pruebas/ideas/f1o_captura_flujo.tscn
## Las imágenes salen en pruebas/capturas/f1o_*.png (el script de captura las pasa a JPG).

const RESPUESTAS := {
	"idioma": {"idioma": "es"},
	"modo": {"modo": "creador"},
	"pais": {"pais": "ARG"},
	"config": {"nombre_club": "Club Captura"},
	"entrada": {"entrada": "reemplazar"},
	"personaje": {"personaje": {"nombre": "Míster"}},
}

func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/f1o_%s.png" % nombre)
	print("captura ", nombre)

func _esperar(seg: float) -> void:
	await get_tree().create_timer(seg).timeout

func _ready() -> void:
	OrquestadorEntrada.ruta_prefs = "user://f1o_captura_entrada.cfg"
	OrquestadorMundo.ruta_preferencias = "user://f1o_captura_prefs.cfg"
	## 1) El menú de siempre, antes (sin el botón) y después (con «Nuevo juego» arriba).
	for con_boton: bool in [false, true]:
		Inicio.flujo_nuevo = con_boton
		var inicio: Control = (load("res://escenas/inicio.tscn") as PackedScene).instantiate()
		add_child(inicio)
		await _esperar(2.0)
		await _foto("inicio_despues" if con_boton else "inicio_antes")
		inicio.queue_free()
		await get_tree().process_frame
	## 2) El flujo, con sus fundidos de verdad.
	var o := OrquestadorEntrada.new()
	o.cambiar_escena = false
	o.forzar_intro = true
	add_child(o)
	var fundido_hecho := false
	for _i in 10:
		await _esperar(0.6)
		while o.get("_en_transicion"):
			await get_tree().process_frame
		await _esperar(1.2)
		var k := o.etapa_actual()
		var p := o.pantalla_actual()
		if p == null or k == "":
			break
		await _foto("etapa_%d_%s" % [o.indice_de(k), k])
		if k == "personaje":
			break
		p.emit_signal("terminado", (RESPUESTAS.get(k, {}) as Dictionary).duplicate(true))
		if not fundido_hecho and k == "modo":
			## A mitad del fundido a negro (0,25 s): el velo tapa la pantalla que se va.
			fundido_hecho = true
			await _esperar(0.12)
			await _foto("fundido")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(OrquestadorEntrada.ruta_prefs))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(OrquestadorMundo.ruta_preferencias))
	get_tree().quit()
