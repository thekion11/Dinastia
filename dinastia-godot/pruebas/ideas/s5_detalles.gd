extends BaseIdea
## S5 «LOOK GTA» (27-10-2026): objetos pequeños por manzana, paleta por barrio y desgaste de fachadas.

func _probar() -> void:
	_titulo("S5 · DETALLES DE FACHADA, PALETA POR BARRIO Y DESGASTE")
	var b := CityBuilder.new()
	add_child(b)
	var ex := CiudadExpansion.new(b)
	ex.armar_red()
	for k in 24:
		ex._bloque_modular(Vector3(float(k) * 40.0, 0.24, 0.0), 0.0, 100 + k, 20.0, 14.0)
	var n := int(ex.cuenta.get("detalles_fachada", 0))
	_comprobar(n >= 20, "los bloques modulares llevan aires, cables, carteles y grafitis (%d)" % n)
	_comprobar(int(ex.cuenta.get("bloques_modulares", 0)) == 24, "se levantaron los bloques modulares (%d)" % int(ex.cuenta.get("bloques_modulares", 0)))
	_comprobar(int(ex.cuenta.get("arriates", 0)) >= 8, "los bloques llevan arriates con matas y flores a pie de fachada (%d)" % int(ex.cuenta.get("arriates", 0)))
	## Las tres familias de color cubren los diez pares y no se pisan.
	var vistos := {}
	for fam: Array in CiudadExpansion.FAMILIAS_BARRIO:
		for i: int in fam:
			vistos[i] = int(vistos.get(i, 0)) + 1
	_comprobar(vistos.size() == CiudadExpansion.COLORES_PISOS.size() and vistos.values().all(func(v: int) -> bool: return v == 1), "las familias de barrio reparten los %d pares de colores sin repetir" % vistos.size())
	var sh := load("res://visor/bloque_modular.gdshader") as Shader
	_comprobar(sh != null and sh.code.contains("churrete") and sh.code.contains("mundo"), "el shader de la pared lleva desgaste (suciedad, churretes, moteado)")
	## Determinista: el mismo bloque da los mismos detalles.
	var a := DetalleFachada.montar(ex, Vector3(0, 0, 0), Basis.IDENTITY, 4.8, 3, 4, 3.0, 1, 123)
	var c := DetalleFachada.montar(ex, Vector3(0, 0, 0), Basis.IDENTITY, 4.8, 3, 4, 3.0, 1, 123)
	_comprobar(a == c, "la semilla fija los detalles (%d = %d)" % [a, c])
	## Tejados por tipo: entre 24 bloques salen al menos tres de los cuatro, y los altos no llevan teja.
	var tipos := 0
	for t in 4:
		if int(ex.cuenta.get("tejado_%d" % t, 0)) > 0:
			tipos += 1
	_comprobar(tipos >= 3, "hay %d tipos de tejado distintos (plano, dos aguas, depósito, jardín)" % tipos)
	var alto_ok := true
	for sem in 200:
		if TejadoTipo.tipo_de(sem, 6) == TejadoTipo.DOS_AGUAS:
			alto_ok = false
	_comprobar(alto_ok, "un bloque de 6 pisos nunca lleva tejado a dos aguas")
	_comprobar(TejadoTipo.tipo_de(77, 3) == TejadoTipo.tipo_de(77, 3), "el tipo es estable por semilla")
	## Cables entre postes: las calles de barrio llevan líneas con tres hilos combados.
	var ex2 := CiudadExpansion.new(b)
	ex2.armar_red()
	ex2._kenney_calles()
	var hilos := int(ex2.cuenta.get("cables_postes", 0))
	_comprobar(hilos > 30 and hilos % 24 == 0, "las calles de barrio llevan líneas de postes con cable (%d tramos, 24 por vano)" % hilos)
