extends Node
## CAPTURAS DEL CLUB AMPLIADO (fase 5, 27-10-2026), en Forward+:
##   herramientas/captura.sh res://pruebas/ideas/f5c_captura_club.tscn
## Salen en pruebas/capturas/f5c_*.jpg: el vestuario con futbolistas junto a sus taquillas
## (martes 10:30), la charla con uno, y el museo con sus copas.

var _m: Mundo
var _vista: VistaCiudad
var _e: ExploradorCiudad
var _v: VidaCiudad

func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/f5c_%s.png" % nombre)
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
	_m.roles.trofeos.append({"anio": _m.anio - 1, "titulo": "Liga"})
	_m.roles.trofeos.append({"anio": _m.anio - 2, "titulo": "Copa"})
	var club := _m.mi_club()
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.animo = CiudadAnimo.de(_m, club)
	var perfil := _m.perfil_estadio_de(club)
	_vista.abrir(club, _m.obras, _m.ciudad, perfil)
	_vista.explorar("pie", Vector3(0, 0, -440))
	_e = _vista._explorador
	await _frames(2)
	_v = VidaCiudad.enganchar(_e, _vista, _m)
	_m.reloj.dia = 1
	_m.reloj.minuto = 10 * 60 + 30
	_v._sincronizar_luz()
	## 1) El vestuario con futbolistas.
	_e._entrar_al_estadio()
	await _frames(2)
	var vest: VestuarioVivo = _v.citas_3d.vestuario
	vest.revisar()
	await _esperar(1.5)
	var c := _centro_zona("Vestuario", 0)
	_e.cuerpo.position = c + Vector3(0, 0, 3.5)
	_e.rumbo = PI
	_e.cuerpo.rotation.y = PI
	_e._colocar_camara(1.0)
	await _esperar(1.0)
	await _foto("1_vestuario")
	if not vest.cuerpos.is_empty():
		var per: PrologoMentor = vest.cuerpos[0]["nodo"]
		_e.cuerpo.position = per.position + Vector3(1.2, 0, 0.6)
		_e.rumbo = -PI * 0.5
		_e.cuerpo.rotation.y = _e.rumbo
		_e._hablando_con = per
		_e._t_burbuja = 120.0
		_e._colocar_camara(1.0)
		vest._buscar_cerca()
		vest.usar()
		await _esperar(1.2)
		await _foto("2_charla")
		_e._hablando_con = null
		_e._t_burbuja = 0.0
	## 2) El museo con las copas.
	_e._ir_a_planta(2)
	var mu := _centro_zona("Museo del club", 2)
	_e.cuerpo.position = mu + Vector3(0, 0, 2.5)
	_e.rumbo = PI
	_e.cuerpo.rotation.y = PI
	await _esperar(1.2)
	_e._colocar_camara(1.0)
	await _esperar(0.8)
	await _foto("3_museo")
	print("capturas hechas")
	get_tree().quit()
