extends Node
## CAPTURA DEL APAGÓN POR SECTOR CON LA CIUDAD ENTERA (27-10-2026, §2.2g, Forward+):
##   herramientas/captura.sh res://pruebas/ideas/p_captura_apagon.tscn
## De noche (23:00), vista aérea sobre el centro: primero con luz en todos los sectores y después con
## cuatro sectores cortados (los de alrededor del punto mirado, sin el hospital). Sale en
## pruebas/capturas/apagon_{encendido,cortado}.jpg. Solo mira; no cambia el juego.

var _m: Mundo
var _vista: VistaCiudad

func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/apagon_%s.png" % nombre)
	print("captura ", nombre)

func _esperar(seg: float) -> void:
	await get_tree().create_timer(seg).timeout

func _ready() -> void:
	_m = Mundo.new()
	_m.generar(["CHI", "ARG"], 4242)
	_m.tomar_el_mando(_m.ligas[0].clubes[0].id)
	var club := _m.mi_club()
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.animo = CiudadAnimo.de(_m, club)
	_vista.abrir(club, _m.obras, _m.ciudad, _m.perfil_estadio_de(club))
	await _esperar(2.0)
	_vista.set("_girando", false)
	_vista.set("_ciclo_activo", false)
	_vista.set("_hora", 23.0)
	_vista.call("_aplicar_hora")
	var centro := Vector3(float(OS.get_environment("X")) if OS.get_environment("X") != "" else 300.0, 8.0,
		float(OS.get_environment("Z")) if OS.get_environment("Z") != "" else 300.0)
	_vista.set("_objetivo", centro)
	_vista.set("_objetivo_deseado", centro)
	_vista.set("_dist", 260.0)
	_vista.set("_alto", 150.0)
	_vista.set("_ang", 0.6)
	_vista.call("_mover_camara")
	var cb: CityBuilder = _vista.get("_ciudad")
	var ex := cb.expansion
	if ex == null or ex.redes == null:
		print("sin redes")
		get_tree().quit()
		return
	cb.encender_luces(1.0)
	await _esperar(1.5)
	await _foto("encendido")
	## Corta los sectores alrededor del punto mirado (no el del hospital).
	var base := RedesCiudad.sector_en(centro.x, centro.z)
	var cortados := 0
	for dx in [0, 1]:
		for dz in [0, 1]:
			var s := base + Vector2i(dx, dz)
			if RedesCiudad.es_hospital(s):
				continue
			ex.redes.modelo.luz[s] = false
			cortados += 1
	cb.encender_luces(1.0)
	print("sectores cortados: ", cortados, " desde ", base)
	await _esperar(1.0)
	await _foto("cortado")
	print("capturas hechas")
	get_tree().quit()
