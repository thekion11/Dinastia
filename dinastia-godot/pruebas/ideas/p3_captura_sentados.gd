extends Node
## CAPTURA DE LA GENTE SENTADA (calidad visual P3, pasada 2, 27-10-2026), en Forward+:
##   herramientas/captura.sh res://pruebas/ideas/p3_captura_sentados.tscn        (después)
##   ANTES=1 herramientas/captura.sh res://pruebas/ideas/p3_captura_sentados.tscn (antes: sin gente)
## Sale en pruebas/capturas/p3_sentados_{antes,despues}.jpg: un banco de acera con la cámara real del paseo.

var _m: Mundo
var _vista: VistaCiudad
var _e: ExploradorCiudad
var _v: VidaCiudad

func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/p3_sentados_%s.png" % nombre)
	print("captura ", nombre)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _esperar(seg: float) -> void:
	await get_tree().create_timer(seg).timeout

func _ready() -> void:
	var antes := OS.get_environment("ANTES") == "1"
	_m = Mundo.new()
	_m.generar(["CHI", "ARG"], 4242)
	_m.tomar_el_mando(_m.ligas[0].clubes[0].id)
	_m.reloj.sincronizar(_m.anio, _m.semana)
	_m.reloj.dia = 2
	_m.reloj.minuto = 11 * 60
	var club := _m.mi_club()
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.animo = CiudadAnimo.de(_m, club)
	_vista.abrir(club, _m.obras, _m.ciudad, _m.perfil_estadio_de(club))
	_vista.explorar("pie", Vector3(0, 0, -440))
	_e = _vista._explorador
	await _frames(2)
	_v = VidaCiudad.enganchar(_e, _vista, _m)
	_v._sincronizar_luz()
	## Un banco de acera ocupado a esta hora, cerca del centro.
	var gs := _v.sentados
	var mejor := -1
	var mejor_d := 1.0e9
	for i in _e.cb.asientos.size():
		if not gs.ocupado(i):
			continue
		var p: Vector3 = _e.cb.asientos[i]["p"]
		var d := Vector2(p.x, p.z).length()
		if d < mejor_d:
			mejor_d = d
			mejor = i
	if mejor < 0:
		print("sin asientos")
		get_tree().quit()
		return
	var a: Dictionary = _e.cb.asientos[mejor]
	var p: Vector3 = a["p"]
	var giro := float(a["giro"])
	var frente := Vector3(sin(giro), 0, cos(giro))
	_e.cuerpo.position = _e.buscar_libre(p + frente * 3.2 + Vector3(0, -0.79, 0))
	_e.rumbo = giro + PI
	_e.cuerpo.rotation.y = _e.rumbo
	if antes:
		gs.set_process(false)
		gs._quitar_todos()
	else:
		gs.revisar()
	await _esperar(1.5)
	_e._colocar_camara(1.0)
	await _esperar(1.0)
	await _foto("antes" if antes else "despues")
	print("capturas hechas")
	get_tree().quit()
