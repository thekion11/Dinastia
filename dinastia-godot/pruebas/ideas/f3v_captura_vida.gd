extends Node
## CAPTURAS DE LA VIDA EN 3D (fase 3, 26-10-2026), en Forward+:
##   herramientas/captura.sh res://pruebas/ideas/f3v_captura_vida.tscn
## Salen en pruebas/capturas/f3v_*.jpg: el amanecer en la ciudad con la hora en el
## HUD, la casa por dentro, la familia, la cama, el comedor del plantel y el móvil
## con la agenda.

var _m: Mundo
var _vista: VistaCiudad
var _e: ExploradorCiudad
var _v: VidaCiudad
var _est: Dictionary = {}

func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/f3v_%s.png" % nombre)
	print("captura ", nombre)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _esperar(seg: float) -> void:
	await get_tree().create_timer(seg).timeout

func _centro_zona(zona: String, planta: int) -> Vector3:
	var mejor := Rect2()
	for z: Dictionary in _est["zonas"]:
		if String(z["nombre"]) == zona and int(z.get("planta", 0)) == planta:
			var r: Rect2 = z["r"]
			if r.get_area() > mejor.get_area():
				mejor = r
	var c := mejor.get_center()
	return CityBuilder.ESTADIO_EN + Vector3(c.x, RecorridoClub.y_de(planta), c.y)

func _ready() -> void:
	_m = Mundo.new()
	_m.generar(["CHI", "ARG"], 4242)
	_m.tomar_el_mando(_m.ligas[0].clubes[0].id)
	_m.reloj.sincronizar(_m.anio, _m.semana)
	_m.vida.perfil = {"pareja": "Carolina", "hijos": [{"nombre": "Martina", "edad": 6}, {"nombre": "Agustín", "edad": 14}], "mascota": "Toby"}
	var club := _m.mi_club()
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.animo = CiudadAnimo.de(_m, club)
	var perfil := _m.perfil_estadio_de(club)
	_vista.abrir(club, _m.obras, _m.ciudad, perfil)
	_est = TunelVestuario.datos(perfil, StadiumBuilder.niveles_de(perfil, int(perfil.get("aforo", 20000))))
	## 1) Amanecer de lunes en la calle, frente a la Casa Grande, con la hora en el HUD.
	var casa := Vector3.ZERO
	for pc: Dictionary in _vista._ciudad.puntos_clic:
		if String(pc["k"]) == "casa_grande":
			casa = pc["pos"]
	_vista.explorar("pie", casa + Vector3(0, 0, 40.0))
	_e = _vista._explorador
	await _frames(2)
	_v = VidaCiudad.enganchar(_e, _vista, _m)
	_m.reloj.dia = 0
	_m.reloj.minuto = 7 * 60 + 10
	_v._sincronizar_luz()
	_e.rumbo = PI
	_e.cuerpo.rotation.y = PI
	_e._physics_process(0.016)
	_e._colocar_camara(1.0)
	await _esperar(1.5)
	await _foto("1_amanecer")
	## 2) La casa por dentro.
	_v.entrar_casa()
	await _esperar(1.2)
	_e._physics_process(0.016)
	await _foto("2_casa")
	## 3) La familia: junto a la pareja, con el aviso de la E.
	if not _v.casa.cuerpos.is_empty():
		var c: Dictionary = _v.casa.cuerpos[0]
		_e.cuerpo.position = _e._INT_ORIGEN + (c["pos"] as Vector3) + Vector3(0, 0, 1.2)
		_e.rumbo = PI
		_e.cuerpo.rotation.y = PI
		_e._hablando_con = c["nodo"]
		_e._t_burbuja = 120.0
		_e._colocar_camara(1.0)
		_v.avisar_interior()
		_v.usar_interior()
		await _esperar(1.0)
		await _foto("3_familia")
		_e._hablando_con = null
		_e._t_burbuja = 0.0
	## 4) La cama: dormir hasta las 08:00.
	_e.cuerpo.position = _e._INT_ORIGEN + (CasaDT.POS_USO["cama"] as Vector3)
	_e.rumbo = -PI * 0.5
	_e.cuerpo.rotation.y = _e.rumbo
	_e._colocar_camara(1.0)
	_v.avisar_interior()
	await _esperar(0.8)
	await _foto("4_cama")
	_v.usar_interior()
	await _esperar(1.0)
	await _foto("5_dormido")
	_e._salir_del_edificio()
	await _frames(2)
	## 6) El comedor del plantel (planta 2 del club).
	_e._entrar_al_estadio()
	_e._ir_a_planta(2)
	_e.cuerpo.position = _centro_zona("Comedor del plantel", 2) + Vector3(0, 0, 1.5)
	_e.rumbo = PI
	_e.cuerpo.rotation.y = PI
	await _esperar(1.2)
	_e._colocar_camara(1.0)
	_v.usar_en_estadio("Comedor del plantel")
	await _esperar(0.8)
	await _foto("6_comedor")
	## 7) El móvil con la agenda.
	_v.abrir_telefono()
	await _frames(3)
	for t in _v._capa_tel.find_children("*", "Telefono", true, false):
		(t as Telefono).abrir_app("agenda")
	await _esperar(1.2)
	await _foto("7_agenda")
	print("capturas hechas")
	get_tree().quit()
