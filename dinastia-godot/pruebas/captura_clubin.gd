extends Node
## Prueba de la app/web del club por dentro (`vClubIn`), la última pantalla
## parcial que quedaba en la auditoría de migración: antes eran un sí/no con
## renta fija; ahora crecen solas cada semana con nombre y dominio propios,
## como en el HTML (`procesoClubIn()`).

var _n := 0
var _pantalla: Node
var _probado := false

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == 20 and _probado:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/pantalla_clubin.png")
		get_tree().quit()
		return
	if _n != 12 or _probado:
		if _n > 200:
			get_tree().quit()
		return
	_probado = true
	var mundo: Mundo = _pantalla.get("mundo")
	var c: Club = mundo.mi_club()
	print("club=%s socios=%d rep=%d" % [c.nombre, c.socios, c.rep])

	## Se lanzan app y web con nombre propio.
	_pantalla.set("_secc_gente", "interno")
	_pantalla.call("_ir_a_pestana", "Gente")
	_pantalla.call("_lanzar_app", "Prueba Oficial", c)
	_pantalla.call("_lanzar_web", "PruebaDominio.cl", c)
	var cd: ClubDentro = mundo.club_dentro
	print("app lanzada=%s nombre=%s subs_inicial=%d" % [not cd.app.is_empty(), cd.app.get("nombre", ""), int(cd.app.get("subs", -1))])
	print("web lanzada=%s dominio=%s visitas_inicial=%d" % [not cd.web.is_empty(), cd.web.get("dominio", ""), int(cd.web.get("visitas", -1))])
	var subs_antes: int = int(cd.app["subs"])
	var visitas_antes: int = int(cd.web["visitas"])
	var saldo_antes := c.saldo

	## Una semana: deben crecer (con margen de ruido) y dejar caja.
	mundo.avanzar_semana()
	print("subs tras 1 semana=%d (antes %d)" % [int(cd.app["subs"]), subs_antes])
	print("visitas tras 1 semana=%d (antes %d)" % [int(cd.web["visitas"]), visitas_antes])
	print("saldo subio=%s (antes %d, ahora %d)" % [c.saldo > saldo_antes, saldo_antes, c.saldo])
	var hay_mov_app := false
	var hay_mov_web := false
	for m: Dictionary in mundo.libro_financiero:
		if String(m["concepto"]) == "Suscripciones de la app oficial":
			hay_mov_app = true
		if String(m["concepto"]) == "Publicidad en la web del club":
			hay_mov_web = true
	print("movimiento de app anotado=%s, de web anotado=%s" % [hay_mov_app, hay_mov_web])

	## forma solo debe llenarse con partidos de LIGA.
	print("forma tras la semana=%s" % [cd.forma])

	_pantalla.call("_refrescar")
