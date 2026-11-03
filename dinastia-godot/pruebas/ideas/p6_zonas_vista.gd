extends BaseIdea
## R3 (3-11): las piezas grandes lejanas se ocultan y vuelven con histéresis; desde las alturas se ve todo; lo pequeño y lo marcado `sin_corte` no se toca.

func _caja(raiz: Node3D, x: float, tam: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(tam, 20, tam)
	mi.mesh = bm
	mi.position = Vector3(x, 10, 0)
	raiz.add_child(mi)
	return mi

func _probar() -> void:
	_titulo("P6: ZONAS DE VISTA (R3)")
	var raiz := Node3D.new()
	add_child(raiz)
	var cerca := _caja(raiz, 100.0, 80.0)
	var lejos := _caja(raiz, 900.0, 80.0)
	var pequena := _caja(raiz, 1500.0, 10.0)
	var estadio := Node3D.new()
	estadio.set_meta("sin_corte", true)
	raiz.add_child(estadio)
	var intocable := _caja(estadio, 1600.0, 80.0)
	var z := ZonasVista.new()
	raiz.add_child(z)
	z.reunir(raiz)
	_comprobar(z.total() == 2, "solo cuentan las piezas grandes que no son del estadio (%d)" % z.total())
	z.revisar(Vector3(0, 2, 0))
	_comprobar(cerca.visible and not lejos.visible, "la cercana se ve y la lejana (a 860 m de su borde) se oculta")
	_comprobar(pequena.visible and intocable.visible, "lo pequeño y el estadio no se tocan")
	z.revisar(Vector3(400, 2, 0))   ## el borde de la lejana queda a 460 m: vuelve (< 560)
	_comprobar(lejos.visible, "al acercarse (460 m) reaparece")
	z.revisar(Vector3(250, 2, 0))   ## a 610 m: entre las dos marcas, no vuelve a ocultarse
	_comprobar(lejos.visible, "entre las marcas (610 m) no parpadea")
	z.revisar(Vector3(150, 2, 0))   ## a 710 m (> 640): se oculta
	_comprobar(not lejos.visible, "otra vez lejos se oculta")
	z.revisar(Vector3(0, 300, 0))
	_comprobar(lejos.visible, "desde las alturas se ve todo")
	_comprobar(not ZonasVista.activa(), "apagada por defecto")
