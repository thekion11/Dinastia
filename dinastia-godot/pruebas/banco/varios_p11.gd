extends "res://pruebas/banco/varios_p11_p1.gd"
## (Parte 2 de 2 de `varios_p11.gd`.)

## LA CARA POR PAÍS (10-11, encargo «uniformes y caras», parte 2): los jugadores de nombre fijo sin foto toman la cara típica de su país (proporciones medidas en las caras
## reales), en vez de un azar de ocho tonos y barba 0-7. Se prueba con jugadores de varios países y clubes.
func _probar_cara_por_pais() -> void:
	_titulo("CARA POR PAÍS PARA LOS JUGADORES SIN FOTO")
	_comprobar(not CaraPrior.tabla().is_empty() and CaraPrior.tabla().has("*") and CaraPrior.tabla().has("JPN"), "la tabla por país está y trae JPN y la media mundial")
	var m := Mundo.new()
	m.generar(["JPN", "COL", "GER", "ESP", "KOR", "ARG"], 71)
	var por_pais := {}
	for c: Club in m.clubes.values():
		for j: Jugador in c.plantilla:
			if not j.real:
				continue
			var lk := Cara.look_de(j)
			var otra := Cara.look_de(j)
			if str(lk) != str(otra):
				_comprobar(false, "la cara de %s es siempre la misma" % j.nombre)
			var d: Dictionary = por_pais.get(j.pais, {"n": 0, "sin_barba": 0, "piel": 0.0, "rubios": 0})
			d["n"] += 1
			d["sin_barba"] += 1 if int(lk["barba"]) == 0 else 0
			d["piel"] += float(CaraPrior.tono_de_foto(String(lk["piel"])) if not Cara.PIELES.has(String(lk["piel"])) else Cara.PIELES.find(String(lk["piel"])))   ## con la base real cargada, los que tienen foto traen su piel MEDIDA (un hex libre, más oscuro que la paleta): se calibra por luminancia
			d["rubios"] += 1 if String(lk["peloC"]) == CaraPrior.PELO_HEX["rubio"] else 0
			por_pais[j.pais] = d
	var ok_pais := por_pais.has("JPN") and por_pais.has("COL") and por_pais.has("GER")
	_comprobar(ok_pais, "hay jugadores de nombre fijo de varios países (%s)" % str(por_pais.keys()))
	if not ok_pais:
		return
	var jp: Dictionary = por_pais["JPN"]
	var co: Dictionary = por_pais["COL"]
	var al: Dictionary = por_pais["GER"]
	## Las diferencias entre países salen de lo MEDIDO en las caras reales: Colombia (media 3,2 en la paleta) frente a Alemania (1,8) es un contraste claro; Brasil frente a Inglaterra, no (2,5 y 2,3: ambas plantillas son mixtas), por eso no se usa.
	_comprobar(float(co["piel"]) / maxf(float(co["n"]), 1.0) > float(al["piel"]) / maxf(float(al["n"]), 1.0) + 0.5, "la piel de Colombia sale más oscura que la de Alemania (%.1f frente a %.1f)" % [float(co["piel"]) / float(co["n"]), float(al["piel"]) / float(al["n"])])
	_comprobar(int(jp["rubios"]) * 20 <= int(jp["n"]), "casi ningún japonés sale rubio (%d de %d)" % [int(jp["rubios"]), int(jp["n"])])
	var sin := 0
	var tot := 0
	for d: Dictionary in por_pais.values():
		sin += int(d["sin_barba"])
		tot += int(d["n"])
	_comprobar(float(sin) / float(maxi(tot, 1)) > 0.4, "como en las fotos, la mayoría no lleva barba (%d de %d sin barba; antes 1 de cada 8)" % [sin, tot])
