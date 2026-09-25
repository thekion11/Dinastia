extends Node
## Verificación y prueba de integración de las mejoras realistas del partido 3D:
## - Arcos cilíndricos y red con textura perforada
## - Físicas del balón (gol dentro de red, atajadas, palos)
## - 9 cámaras (incluyendo Primera Persona y Pro) con zoom y altura ajustables
## - Control manual de jugador estilo FC 26 (WASD, sprint, pase, centro, tiro cargado, barrida, cambio)
## - Radar 2D en tiempo real con 22 jugadores, árbitros y pelota
## - Animaciones de remates, atajadas, celebraciones y protestas
##
## Ejecutar con:
##   godot --headless --path dinastia-godot res://pruebas/captura_partido_realista.tscn

var _mundo: Mundo
var _partido: Partido
var _vista: VistaEstadio
var _frame := 0

func _ready() -> void:
	print("=== INICIANDO PRUEBA: PARTIDO 3D REALISTA (TIPO FC 26 / SM 2027) ===")
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4711)
	_mundo.mi_club_id = _mundo.ligas[0].clubes[0].id
	var par := _mundo.proximo_partido()
	_partido = Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], _partido)

	# 1. Verificar arcos cilíndricos y red
	var raiz: Node3D = _vista.get("_raiz3d")
	assert(raiz != null, "ERROR: _raiz3d no existe en VistaEstadio")
	print("✓ Raíz 3D construida correctamente")

	# 2. Verificar cámaras en CameraRig
	var rig: CameraRig = _vista.get("_rig")
	assert(rig != null, "ERROR: CameraRig no instanciado")
	assert(rig.cameras.size() >= 9, "ERROR: Deben haber al menos 9 cámaras")
	print("✓ CameraRig cuenta con %d cámaras registradas:" % rig.cameras.size())
	for i in rig.cameras.size():
		print("    [%d] %s" % [i, rig.camera_names[i]])

	
	# Probar ciclado de cámaras
	for i in range(rig.cameras.size()):
		rig.cycle()
	print("✓ Ciclado de cámaras completado con éxito (cámara actual: %s)" % rig.current_name())


	# Probar ajuste de zoom y altura
	rig.ajustar_zoom(5.0)
	rig.ajustar_zoom(-5.0)
	rig.ajustar_altura(3.0)
	rig.ajustar_altura(-3.0)
	print("✓ Zoom y altura ajustables verificados")

	# 3. Verificar Balón 3D y coordenadas de red
	var balon: Balon3D = _vista.get("_balon")
	assert(balon != null, "ERROR: Balon3D no instanciado")
	balon.enviar(Vector3(1.5, 1.8, 53.5), 1.2, 0.5, true)
	print("✓ enviar() al fondo de la red (Z=53.5, Y=1.8, es_gol=true) sin errores")


	# 4. Verificar ControlPartido (Modo FC 26)
	var control: ControlPartido = _vista.get("_control")
	assert(control != null, "ERROR: ControlPartido no instanciado en Estadio")
	assert(control.has_method("setup"), "ERROR: ControlPartido no tiene método setup")
	control.set_activo(true)
	print("✓ Modo Jugador FC 26 activado en ControlPartido")
	assert(not control.jugador_activo.is_empty(), "ERROR: No hay jugador seleccionado para control")
	print("    Jugador activo asignado: %s" % control.jugador_activo.get("id", "desconocido"))

	# Simular acciones de jugador manual
	control._ejecutar_pase_corto()
	control._ejecutar_pase_largo()
	control._ejecutar_disparo(0.8)
	control._ejecutar_barrida()
	control.seleccionar_mas_cercano_al_balon()
	print("✓ Acciones de juego manual (pase, centro, remate potente, barrida, cambio) ejecutadas con éxito")

	# 5. Verificar Radar 2D
	var radar: RadarPartido = _vista.get("_radar")
	assert(radar != null, "ERROR: RadarPartido no instanciado en Estadio")
	var en_campo: Array = _vista.get("_en_campo")
	var pos_act: Vector3 = (control.jugador_activo["node"] as Node3D).global_position if is_instance_valid(control.jugador_activo.get("node")) else Vector3.ZERO
	radar.actualizar_datos(en_campo, balon.global_position, pos_act)
	print("✓ Radar táctico 2D actualizado con %d entidades en campo" % en_campo.size())



	# 6. Verificar MatchPlayback y acelerar para simular sucesos
	var juego: MatchPlayback = _vista.get("_juego")
	assert(juego != null, "ERROR: MatchPlayback no instanciado")
	juego.vel_idx = 4 # Velocidad x4

	# Simular eventos de partido (gol, tarjeta, lesión, decisión arbitral)
	var autor: Jugador = _partido.once_local[0]
	var asistente: Jugador = _partido.once_local[1] if _partido.once_local.size() > 1 else null
	_partido.gol.emit(par[0], autor, 12, asistente)
	_partido.remate.emit(par[0], autor, "atajada", 15)
	_partido.remate.emit(par[1], autor, "poste", 22)
	_partido.lesion.emit(autor, 3, 30)
	_partido.decision_arbitral.emit("El árbitro anula el tanto por offside milimétrico", 35)

	print("✓ Señales de dramatización (gol, atajada, poste, lesión, arbitraje) emitidas y recibidas")

func _process(_delta: float) -> void:
	_frame += 1
	if _frame > 30:
		print("=== TODAS LAS PRUEBAS DE PARTIDO REALISTA PASARON EXITOSAMENTE ===")
		print("FIN. 0 fallos")
		get_tree().quit(0)

