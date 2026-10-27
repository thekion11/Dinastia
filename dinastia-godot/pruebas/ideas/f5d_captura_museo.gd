extends Node
## CAPTURAS DEL MUSEO QUE CRECE (27-10-2026), en Forward+:
##   herramientas/captura.sh res://pruebas/ideas/f5d_captura_museo.tscn
## Salen en pruebas/capturas/f5d_*.jpg: la sala de la planta 2 con 9 títulos (seis vitrinas llenas), la planta 3 en obra (museo a nivel 4 con
## la obra en marcha), la planta 3 terminada al entrar (las copas se iluminan una a una) y ya encendida.

var _m: Mundo
var _vista: VistaCiudad
var _e: ExploradorCiudad
var _v: VidaCiudad

func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/f5d_%s.png" % nombre)
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
	var titulos := 9
	for k in titulos:
		_m.roles.trofeos.append({"anio": _m.anio - 3 - k * 2, "titulo": ["Liga", "Copa", "Supercopa"][k % 3]})
	var nivel := int(OS.get_environment("NIVEL")) if OS.get_environment("NIVEL") != "" else 5
	_m.obras.niveles["museo"] = nivel
	if nivel < 5:
		_m.obras.obras["museo"] = 2
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
	_e._entrar_al_estadio()
	await _frames(2)
	await _esperar(1.0)
	## La sala de la planta 2.
	_e._ir_a_planta(2)
	_poner("Museo del club", 2, 2.5)
	await _esperar(1.5)
	await _foto("planta2_%d" % nivel)
	## La planta 3 (en obra o terminada): primero un paso de la entrada, luego de pie en la sala.
	_e._ir_a_planta(3)
	_poner("Museo ampliado", 3, 2.5)
	await _esperar(0.9)
	await _foto("planta3_%d_entrada" % nivel)
	await _esperar(3.5)
	await _foto("planta3_%d_dentro" % nivel)
	_poner("Museo ampliado", 3, -1.0)
	_e.rumbo = 0.0
	_e.cuerpo.rotation.y = 0.0
	_e._colocar_camara(1.0)
	await _esperar(1.0)
	await _foto("planta3_%d_fondo" % nivel)
	print("capturas hechas")
	get_tree().quit()

func _poner(zona: String, planta: int, dz: float) -> void:
	var mu := _centro_zona(zona, planta)
	_e.cuerpo.position = mu + Vector3(0, 0, dz)
	_e.rumbo = PI
	_e.cuerpo.rotation.y = PI
	_e._colocar_camara(1.0)
