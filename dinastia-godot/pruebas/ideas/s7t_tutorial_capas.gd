extends BaseIdea
## s7t · EL TUTORIAL POR CAPAS (semana 7 del plan, 27-10-2026). Las tres primeras misiones del primer día son la
## capa básica; pasadas, «Saltar» pasa a «Lo demás, por mi cuenta», el tutorial cuenta como hecho y las misiones
## que faltan siguen en el panel de objetivos (🧭) como opcionales. La lectura de cada guion cabe en unos minutos.

func _probar() -> void:
	_titulo("S7T: el tutorial por capas")
	var m := _mundo(5150)
	var ctx := Tutorial.contexto(m)
	for modo: String in ["dt", "dir", "ayudante", "interino", "cantera", "jeque"]:
		var g := Tutorial.guion(modo, ctx)
		var pasos: Array = g["pasos"]
		var letras := String(g.get("prologo", "")).length()
		var misiones := 0
		for p: Dictionary in pasos:
			letras += String(p.get("texto", "")).length()
			misiones += 1 if p.has("mision") else 0
		var minutos := letras / Tutorial.LETRAS_SEG / 60.0
		_comprobar(minutos < 2.0 and misiones >= Tutorial.CAPA_BASICA, "%s: %.1f min de lectura y %d misiones (la capa básica son %d)" % [modo, minutos, misiones, Tutorial.CAPA_BASICA])
	## La capa: con un guion de prueba, «por mi cuenta» aparece tras la tercera misión vista.
	var t := Tutorial.new()
	var g2 := Tutorial.guion("dt", ctx)
	t.set("_pasos", g2["pasos"])
	var primera_libre := -1
	for i in (g2["pasos"] as Array).size():
		t.set("_i", i)
		if t._capa_basica_hecha():
			primera_libre = i
			break
	var antes := 0
	for k in maxi(primera_libre, 0):
		antes += 1 if (g2["pasos"][k] as Dictionary).has("mision") else 0
	_comprobar(primera_libre > 0 and antes == Tutorial.CAPA_BASICA, "«Lo demás, por mi cuenta» sale tras %d misiones (paso %d)" % [antes, primera_libre])
	t.free()
	## Las que faltan quedan en el panel de objetivos como misiones del mentor.
	var en_panel := PanelObjetivos.lista(m, "dt").filter(func(o: Dictionary) -> bool: return bool(o.get("mentor", false)))
	_comprobar(en_panel.size() >= Tutorial.CAPA_BASICA, "las misiones siguen en el panel de objetivos (%d)" % en_panel.size())
