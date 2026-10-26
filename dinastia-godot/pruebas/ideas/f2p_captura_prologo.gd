extends Node
## CAPTURAS DEL PRÓLOGO 3D (fase 2, 26-10-2026): las siete estaciones del guion
## tal como las ve el jugador, con la cámara del paseo en Forward+.
##   herramientas/captura.sh res://pruebas/ideas/f2p_captura_prologo.tscn
## Salen en pruebas/capturas/f2p_*.jpg. El personaje se mueve por código hasta
## cada sala (teletransporte + unos pasos andando para que la cámara se asiente).

var _p: PrologoDT
var _e: ExploradorCiudad
var _hechas := 0

func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/f2p_%s.png" % nombre)
	_hechas += 1
	print("captura ", nombre)

func _esperar(seg: float) -> void:
	await get_tree().create_timer(seg).timeout

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 4242)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	Principal.mundo_pregenerado = m
	Principal.modo_elegido = "dt"
	Principal.dt_nombre_elegido = "Míster"
	PrologoDT.rapido = false
	_p = (load("res://escenas/prologo.tscn") as PackedScene).instantiate()
	add_child(_p)
	## 1) El plano de presentación (a mitad del rótulo).
	for i in 600:
		await get_tree().process_frame
		if _p.hud != null and is_instance_valid(_p.hud._presentacion):
			break
	await _esperar(1.6)
	await _foto("1_presentacion")
	for i in 900:
		await get_tree().process_frame
		if _p._listo:
			break
	_e = _p.explorador
	await _esperar(1.0)
	## 2) La llegada: el mentor en la puerta, el cuadro de diálogo y la tarjeta de controles.
	_e._colocar_camara(1.0)
	await _foto("2_llegada")
	_cerrar_charla()
	await _frames(2)
	## 3) Llegar al mentor y la explicación de la puerta.
	_e.cuerpo.position = _p.mentor.position + Vector3(0, 0, 1.0)
	await _frames(3)
	_e.cuerpo.position = _p.destino
	await _frames(3)
	_e._colocar_camara(1.0)
	await _foto("3_puerta")
	_cerrar_charla()
	_e._entrar_al_estadio()
	await _frames(3)
	## 4) El vestuario con el mentor esperando.
	await _ir("vestuario")
	await _foto("4_vestuario")
	_cerrar_charla()
	await _ir("campo")
	await _foto("5_campo")
	_cerrar_charla()
	await _ir("enfermeria")
	_cerrar_charla()
	## 6) La directiva: la pregunta del presidente.
	await _ir("presidente")
	await _foto("6_directiva")
	_p._responder_directiva(0)
	await _frames(2)
	_cerrar_charla()
	## 7) La prensa: el plató de presentación.
	await _ir("prensa")
	await _esperar(1.2)
	await _foto("7_prensa")
	for i in 3:
		_p.prensa._responder("seguro", 2)
	for b: Button in _p.prensa._botones.get_children():
		b.pressed.emit()
	await _frames(3)
	## 8) La oficina con el PC encendible, y el menú central encendido.
	await _ir("oficina")
	await _foto("8_oficina")
	_e.cuerpo.position = _p.pc.punto
	await _frames(2)
	_p.pc.encender()
	await _esperar(1.0)
	await _foto("9_pc")
	_p.pc.apagar()
	await _frames(2)
	print("capturas hechas: ", _hechas)
	get_tree().quit()

func _cerrar_charla() -> void:
	for i in 12:
		if not _p.dialogo.visible:
			return
		_p._hablar()

## Al centro de la sala del paso (y su planta), mirando al mentor.
func _ir(clave: String) -> void:
	var paso: Dictionary = PrologoPasos.paso(clave)
	for i in 90:
		await get_tree().process_frame
		if _p.paso_i == PrologoPasos.indice(clave):
			break
	_e._ir_a_planta(int(paso["planta"]))
	_e.cuerpo.position = _p.destino + Vector3(0, 0, 1.6)
	_e.rumbo = PI
	_e.cuerpo.rotation.y = PI
	await _esperar(2.4)
	_e._colocar_camara(1.0)
	await _frames(2)
