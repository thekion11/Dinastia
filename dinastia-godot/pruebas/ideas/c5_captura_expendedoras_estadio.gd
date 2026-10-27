extends Node
## LAS MÁQUINAS EXPENDEDORAS del estadio (semana 6): la del exterior junto a la puerta del club y la del pasillo de la sala de prensa.
##   herramientas/captura.sh res://pruebas/ideas/c5_captura_expendedoras_estadio.tscn   → pruebas/capturas/c5_*.jpg

var _m: Mundo
var _vista: VistaCiudad
var _e: ExploradorCiudad
var _v: VidaCiudad

func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/c5_%s.png" % nombre)
	print("captura ", nombre)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _esperar(seg: float) -> void:
	await get_tree().create_timer(seg).timeout

func _centro_zona(zona: String, planta: int) -> Vector3:
	var mejor := Rect2()
	for z: Dictionary in _e._est.get("zonas", []):
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
	var club := _m.mi_club()
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.animo = CiudadAnimo.de(_m, club)
	EdificioClub.fijar_ctx(_m, club)
	var perfil := _m.perfil_estadio_de(club)
	_vista.abrir(club, _m.obras, _m.ciudad, perfil)
	_vista.explorar("pie", Vector3(0, 0, -440))
	_e = _vista._explorador
	await _frames(2)
	_v = VidaCiudad.enganchar(_e, _vista, _m)
	_m.reloj.dia = 1
	_m.reloj.minuto = 10 * 60 + 30
	_v._sincronizar_luz()
	_v.poner_extras()
	## 1) El exterior: delante de la máquina junto a la puerta del club.
	var pu: Vector3 = CityBuilder.ESTADIO_EN + (_e._est["puerta"] as Vector3)
	_e.cuerpo.position = Vector3(pu.x - 6.0, 0.2, pu.z + 6.0)
	_e.rumbo = PI
	_e.cuerpo.rotation.y = PI
	_e._colocar_camara(1.0)
	await _esperar(1.2)
	await _foto("1_exterior")
	## 2) La sala de prensa: de cara a la máquina del fondo.
	_e._entrar_al_estadio()
	await _frames(2)
	_e._ir_a_planta(2)
	var c := _centro_zona("Sala de prensa", 2)
	_e.cuerpo.position = c + Vector3(2.2, 0, 0)
	_e.rumbo = PI * 0.5
	_e.cuerpo.rotation.y = _e.rumbo
	await _esperar(1.2)
	_e._colocar_camara(1.0)
	await _esperar(0.8)
	await _foto("2_prensa")
	print("capturas hechas")
	get_tree().quit()
