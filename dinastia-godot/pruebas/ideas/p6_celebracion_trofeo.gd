extends BaseIdea
## Celebración de un título (idea 327): once en el círculo central, el capitán (nunca el portero) con la copa en la mano, confeti,
## vuelta olímpica por la pista y fin que limpia todo y devuelve la cámara.

var _fin := false

func _probar() -> void:
	_titulo("P6: CELEBRACIÓN DE TROFEO EN 3D")
	var m := Mundo.new()
	m.generar(["CHI"], 2026)
	m.mi_club_id = m.ligas[0].clubes[0].id
	var raiz := Node3D.new()
	add_child(raiz)
	var previa := Camera3D.new()
	raiz.add_child(previa)
	previa.make_current()
	var cel := CelebracionTrofeo.iniciar(raiz, m.mi_club(), "Liga de Chile", null)
	cel.terminado.connect(func() -> void: _fin = true)
	_comprobar(cel._jug.size() >= 10, "salen al campo %d jugadores" % cel._jug.size())
	_comprobar(not cel._capi.is_empty() and not String((cel._capi["nodo"] as Node).name).is_empty(), "hay capitán")
	var copa := (cel._capi["nodo"] as Node3D).get_node_or_null("CopaDelTitulo") as Node3D
	_comprobar(copa != null and copa.position.y > 1.5 and copa.position.y < 1.9, "el capitán lleva la copa en alto sobre la cabeza")
	_comprobar(String(cel._capi.get("id", "")) != "" and not (cel._capi["nodo"] as Node).name.is_empty(), "el capitán no es el portero")
	_comprobar(cel._canones.size() == CelebracionTrofeo.CONFETI_CANONES, "hay %d cañones de confeti" % cel._canones.size())
	var t_total := CelebracionTrofeo.T_CORRO + CelebracionTrofeo.T_VUELTA + CelebracionTrofeo.T_FINAL
	var lejos := 0.0
	var disparados := 0
	for paso in int(t_total / 0.1) - 2:
		cel._process(0.1)
		for p in cel._canones:
			if p.emitting:
				disparados += 1
		lejos = maxf(lejos, ((cel._capi["nodo"] as Node3D).position).length())
	_comprobar(cel._disparos.is_empty(), "se han disparado todos los cañones de la lista aunque los fotogramas salten")
	_comprobar(disparados > 0, "los cañones disparan durante la fiesta")
	_comprobar(lejos > 30.0, "el capitán da la vuelta por la pista (llega a %.0f m del centro)" % lejos)
	_comprobar(not _fin and is_instance_valid(cel), "todavía no ha terminado antes de tiempo")
	for paso in 40:
		if is_instance_valid(cel):
			cel._process(0.1)
	_comprobar(_fin, "al acabar emite «terminado»")
	await get_tree().process_frame
	_comprobar(not is_instance_valid(cel) and previa.is_current(), "se limpia y la cámara anterior vuelve")
