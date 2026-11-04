extends BaseIdea
## (4-11, pedido del dueño) El aviso de interactuar («E: …») solo aparece MUY cerca del objeto: a pie ≤ 5 m, en coche ≤ 10 m (antes 14 y 30).

func _probar() -> void:
	_titulo("P6: ALCANCE DEL AVISO DE INTERACTUAR")
	var pie := ExploradorCiudad.alcance_base("pie")
	var coche := ExploradorCiudad.alcance_base("coche")
	_comprobar(pie <= 5.0 and pie > 1.0, "a pie el aviso sale a ≤ 5 m (%.1f)" % pie)
	_comprobar(coche <= 10.0 and coche > pie, "en coche a ≤ 10 m y más que a pie (%.1f)" % coche)
	## Un punto de objeto grande suma su propio alcance: la tienda deportiva (2,5 m) se avisa a ≤ pie + 2,5.
	_comprobar(pie + 2.5 <= 8.0, "con alcance propio sigue siendo corto (%.1f)" % (pie + 2.5))
