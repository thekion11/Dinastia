extends Node
## CAPTURAS de las pantallas de evento del avance por días (una por tipo de arte), con clubes de países distintos:
##   herramientas/captura.sh res://pruebas/captura_eventos_avance.tscn --compat      Salida: pruebas/capturas/evento_<tipo>.png

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://pruebas/capturas"))
	var m := Mundo.new()
	var ps: Array[String] = ["CHI", "ARG"]
	m.generar(ps, 21)
	m.tomar_el_mando(m.ligas[0].clubes[2].id)
	var j: Jugador = m.mi_club().plantilla[3]
	j.goles = 5
	j.asistencias = 3
	j.notas = [7.9, 8.0, 7.8] as Array[float]
	m.cantera.exigencia = {"tipo": "canterano", "agente": "Agencia Norte", "pid": j.id, "ids": [j.id], "perfil": "tiburon", "txt": "x", "opcion_a": "Fichar a su canterano", "opcion_b": "Que se olvide"}
	m.eventos_cantera.pendiente = {"tipo": "abandono", "id": "c1", "nombre": "Marco", "tema": "Marco (16 años) quiere dejar el fútbol para centrarse en los estudios.", "a": "Hablar con él y con su familia", "b": "Respetar su decisión"}
	var lista := [
		{"tipo": "guerra_agentes", "clase": "pantalla", "texto": "Agencia Norte controla a varios de tus jugadores y exige que fiches a un canterano de su agencia.", "causa": {"id": "guerra_agentes", "datos": {}}},
		{"tipo": "evento_cantera", "clase": "pantalla", "texto": "Marco (16 años) quiere dejar el fútbol para centrarse en los estudios.", "causa": {"id": "evento_cantera", "datos": {}}},
		{"tipo": "ultimatum", "clase": "pantalla", "causa": {"id": "ultimatum", "datos": {"confianza": 18}}},
		{"tipo": "jugador_del_mes", "clase": "pantalla", "es_mio": true, "nombre": Nombres.visible(j.nombre), "jugador_id": j.id, "club": m.mi_club().nombre, "causa": {"id": "jugador_del_mes", "datos": {}}},
		{"tipo": "golpe_caja", "clase": "aviso", "titulo": "Multa de la federación", "texto": "La federación te multa por incidentes en la grada.", "causa": {"id": "golpe_caja", "datos": {"importe": 500000, "semanas": 2}}},
		{"tipo": "sancion_dt", "clase": "aviso", "causa": {"id": "sancion_dt", "datos": {"fechas": 2}}},
		{"tipo": "fecha_pais", "subtipo": "independencia", "clase": "pantalla", "nombre": "Día de la independencia", "texto": "Se celebra la independencia del país.", "causa": {}},
		{"tipo": "mercado_cierra", "clase": "aviso", "icono": "🔒", "etiqueta": "Mercado", "texto": "Cierra el mercado de fichajes", "causa": {}},
		{"tipo": "fin", "clase": "pantalla", "etiqueta": "Temporada", "texto": "Fin de temporada", "causa": {}},
		{"tipo": "evento_cantera", "clase": "aviso", "texto": "Un chico de la academia quiere dejar el fútbol.", "causa": {"id": "evento_cantera", "datos": {}}}]
	for ev: Dictionary in lista:
		var t := EventoDiaPantalla.mostrar(self, ev, m)
		await get_tree().create_timer(2.2).timeout
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://pruebas/capturas/evento_%s.png" % String(ev["tipo"])))
		t.queue_free()
	get_tree().quit()
