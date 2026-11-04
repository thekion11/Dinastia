extends BaseIdea
## A4 memoria · el catálogo de sonidos sintetizados (~42 MB) no se hace entero en el menú: solo los básicos, y el resto al pedirse el primero de partido/ciudad/evento. Lo que suena es lo mismo.
## Corre en su propio proceso (en el banco otras pruebas ya lo generaron todo).
func _probar() -> void:
	_titulo("AUDITORÍA 4 · SONIDOS PEREZOSOS")
	for i in 20:
		await get_tree().process_frame
	await get_tree().create_timer(3.0).timeout
	var n0: int = Sonido._bancos.size()
	_comprobar(n0 <= Sonido.BASICOS.size() + 4, "tras 3 s solo están los básicos en memoria (%d bancos, básicos %d)" % [n0, Sonido.BASICOS.size()])
	_comprobar(not Sonido.get("_completo"), "y el catálogo entero aún no se pidió")
	var gol: Array = Sonido.banco("gol")
	_comprobar(not gol.is_empty(), "un sonido de partido se genera al momento al pedirlo (%d variantes)" % gol.size())
	_comprobar(bool(Sonido.get("_completo")), "y esa primera petición pone en marcha el catálogo entero")
	## Lo que suena es lo mismo: el banco a demanda es idéntico al de una síntesis nueva de la misma receta.
	var otra: Array = Sonido._sintetizar_banco("gol")
	var igual := otra.size() == gol.size() and not gol.is_empty() and (gol[0] as AudioStreamWAV).data == (otra[0] as AudioStreamWAV).data
	_comprobar(igual, "el banco «gol» es idéntico a una síntesis nueva (mismos bytes)")
	await get_tree().create_timer(40.0).timeout
	var n1: int = Sonido._bancos.size()
	_comprobar(n1 >= Sonido.NOMBRES.size() - 2, "en unos segundos el hilo termina el catálogo (%d de %d)" % [n1, Sonido.NOMBRES.size()])
