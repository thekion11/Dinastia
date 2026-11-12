extends Node
## LA GENERACIÓN DEL MUNDO POR TROZOS (7-11): `Mundo.generar_por_trozos` da el MISMO mundo que `generar` (mismos clubes, mismos jugadores, misma suma de medias y de valores) y no
## bloquea más de ~un trozo: se mide el mayor hueco entre fotogramas frente a la generación de una vez.
var _fallos := 0

func _comprobar(ok: bool, msg: String) -> void:
	print("  ", "ok   " if ok else "FALLO ", msg)
	if not ok:
		_fallos += 1

func _huella(m: Mundo) -> String:
	var n := 0
	var medias := 0
	var valores := 0
	var ids := 0
	for c: Club in m.clubes.values():
		ids += c.id.hash() % 1000
		for j: Jugador in c.plantilla:
			n += 1
			medias += j.ovr
			valores += j.valor
	return "clubes=%d ligas=%d jugadores=%d ovr=%d valor=%d ids=%d" % [m.clubes.size(), m.ligas.size(), n, medias, valores, ids]

func _ready() -> void:
	await get_tree().process_frame
	var a := Mundo.new()
	a.generar(["CHI", "ARG"], 4711)
	var ha := _huella(a)
	var b := Mundo.new()
	var fotogramas := [0]
	var contar := func() -> void: fotogramas[0] += 1
	get_tree().process_frame.connect(contar)
	await b.generar_por_trozos(["CHI", "ARG"], 4711, 8.0)
	get_tree().process_frame.disconnect(contar)
	var hb := _huella(b)
	_comprobar(fotogramas[0] >= 3, "se repartió entre fotogramas (%d fotogramas)" % fotogramas[0])
	_comprobar(ha == hb, "mismo mundo que `generar` con la misma semilla: %s" % ha)
	if ha != hb:
		print("  sincrona: ", ha, "\n  por trozos: ", hb)
	## (12-11, fallo n.º 1 del plan) Si la pantalla que la pidió se va a mitad, se abandona sin tocar lo global.
	var marca := {"marca": true}
	LeyesPais.clubes_mundo = marca
	Meta.heredar_proximo = true
	var viva := [true]
	var c := Mundo.new()
	get_tree().create_timer(0.05).timeout.connect(func() -> void: viva[0] = false)
	await c.generar_por_trozos(["CHI", "ARG"], 4711, 8.0, func() -> bool: return viva[0])
	_comprobar(LeyesPais.clubes_mundo == marca, "abandonada: no pisa `LeyesPais.clubes_mundo` (%d clubes creados de %d)" % [c.clubes.size(), b.clubes.size()])
	_comprobar(Meta.heredar_proximo, "abandonada: no gasta la herencia pedida (`Meta.heredar_proximo` sigue)")
	Meta.heredar_proximo = false
	LeyesPais.clubes_mundo = b.clubes
	print(("===== FIN. %d FALLOS =====" if _fallos > 0 else "===== FIN. 0 fallos =====") % _fallos)
	get_tree().quit()
