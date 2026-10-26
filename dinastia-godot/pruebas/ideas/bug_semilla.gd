extends BaseIdea
## Caza de bugs: la misma semilla debe dar el mismo mundo (prueba 929/1006 de ideas_b4).

func _firma(m: Mundo) -> PackedStringArray:
	var t := PackedStringArray()
	for cl: Club in m.ligas[0].clubes:
		for j: Jugador in cl.plantilla:
			t.append("%s|%s|%d|%d" % [cl.nombre, j.nombre, j.ovr, j.edad])
	return t

func _comparar(etq: String, a: PackedStringArray, b: PackedStringArray) -> bool:
	var n := 0
	for i in mini(a.size(), b.size()):
		if a[i] != b[i]:
			if n < 5:
				_linea("%s difiere [%d]: %s  vs  %s" % [etq, i, a[i], b[i]])
			n += 1
	_linea("%s: %d/%d distintos (tamaños %d %d)" % [etq, n, a.size(), a.size(), b.size()])
	return n == 0 and a.size() == b.size()

func _libres(semilla: int) -> String:
	var m := Mundo.new()
	m.generar(["CHI"], semilla)
	m.generar_libres()
	return ",".join(m.libres.map(func(x: Jugador) -> String: return x.nombre))

func _probar() -> void:
	_titulo("BUG: determinismo de Mundo.generar")
	var era: bool = Datos.base_real
	for real: bool in [true, false]:
		Datos.usar_base_real(real)
		var a := Mundo.new()
		a.generar(["CHI"], 71)
		var a2 := Mundo.new()
		a2.generar(["CHI"], 71)
		_comprobar(_comparar("real=%s" % real, _firma(a), _firma(a2)), "misma semilla, mismo mundo (base real=%s)" % real)
		var b := Mundo.new()
		b.generar(["CHI"], 72)
		## Fase 4 (07-10): la plantilla de arranque se siembra con el NOMBRE del club, así que
		## dos semillas dan los mismos planteles a propósito. La semilla se nota en lo que
		## viene después: agentes libres, canteras, partidos.
		_comprobar(_comparar("otra semilla real=%s" % real, _firma(a), _firma(b)), "otra semilla, MISMOS planteles de arranque (fase 4, sembrados por nombre)")
		## `Azar` es global: los libres se sortean justo después de generar cada mundo.
		var la := _libres(71)
		var la2 := _libres(71)
		var lb := _libres(72)
		_comprobar(la == la2 and la != lb and la != "", "los libres sí dependen de la semilla: iguales con 71/71, distintos con 72 (real=%s)" % real)
	Datos.usar_base_real(era)
