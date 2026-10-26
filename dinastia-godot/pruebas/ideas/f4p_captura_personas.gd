extends Node
## CAPTURAS DE LAS PERSONAS EN PERSONA (fase 4, 26-10-2026), en Forward+:
##   herramientas/captura.sh res://pruebas/ideas/f4p_captura_personas.tscn
## Salen en pruebas/capturas/f4p_*.jpg: el mensaje de la cita en el móvil, la Agenda
## con «Ir», la flecha en la calle, la patrocinadora en el centro comercial y la charla.

var _m: Mundo
var _vista: VistaCiudad
var _e: ExploradorCiudad
var _v: VidaCiudad
var _c: CitasCiudad

func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/f4p_%s.png" % nombre)
	print("captura ", nombre)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _esperar(seg: float) -> void:
	await get_tree().create_timer(seg).timeout

func _ready() -> void:
	_m = Mundo.new()
	_m.generar(["CHI", "ARG"], 4242)
	_m.tomar_el_mando(_m.ligas[0].clubes[0].id)
	_m.reloj.sincronizar(_m.anio, _m.semana)
	var club := _m.mi_club()
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.animo = CiudadAnimo.de(_m, club)
	var perfil := _m.perfil_estadio_de(club)
	_vista.abrir(club, _m.obras, _m.ciudad, perfil)
	var pend := _m.citas.pendientes()
	if pend.is_empty():
		print("sin citas")
		get_tree().quit()
		return
	var ct: Dictionary = pend[0]
	_vista.explorar("pie", Vector3(0, 0, -440))
	_e = _vista._explorador
	await _frames(2)
	_v = VidaCiudad.enganchar(_e, _vista, _m)
	_c = _v.citas_3d
	var p := _c.punto_de(ct)
	_e.cuerpo.position = _e.buscar_libre(p + Vector3(0, 0, 60.0))
	_e.rumbo = PI
	_e.cuerpo.rotation.y = PI
	_m.reloj.dia = int(ct["dia"])
	_m.reloj.minuto = int(ct["hora"]) * 60 + 10
	_v._sincronizar_luz()
	## 1) El móvil: el mensaje de la cita y la Agenda con «Ir».
	_v.abrir_telefono()
	await _frames(3)
	var tel: Telefono = null
	for t in _v._capa_tel.find_children("*", "Telefono", true, false):
		tel = t
	if tel != null:
		tel.abrir_app("mensajes")
		await _esperar(1.0)
		await _foto("1_mensaje")
		tel.abrir_app("agenda")
		await _esperar(1.0)
		await _foto("2_agenda")
		tel.al_cerrar.call()
		await _esperar(1.0)
	## 2) La flecha en la calle hacia la cita.
	_m.citas.objetivo = String(ct["id"])
	_e._physics_process(0.016)
	_c._process(0.6)
	_e._colocar_camara(1.0)
	await _esperar(1.0)
	await _foto("3_flecha")
	## 3) La persona en su sitio y la charla.
	_e.cuerpo.position = _e.buscar_libre(p + Vector3(0, 0, 8.0))
	_c._revisar_cuerpos()
	await _frames(2)
	var per: PrologoMentor = _c.cuerpos.get(String(ct["id"]))
	if per != null:
		_e.cuerpo.position = per.position + Vector3(0, 0, 1.4)
		_e.rumbo = PI
		_e.cuerpo.rotation.y = PI
		_e._colocar_camara(1.0)
		_c._buscar_cerca()
		await _esperar(1.2)
		await _foto("4_persona")
		_c.usar()
		await _esperar(1.0)
		await _foto("5_charla")
		_c._responder(0)
		await _esperar(1.2)
		await _foto("6_firmado")
	print("capturas hechas")
	get_tree().quit()
