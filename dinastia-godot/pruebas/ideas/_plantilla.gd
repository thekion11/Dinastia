extends BaseIdea
## Plantilla: copia _plantilla.gd/.tscn a <tu_nombre>.gd/.tscn (cambia la ruta del script en el .tscn).

func _probar() -> void:
	_titulo("IDEAS DEL DUEÑO (plantilla)")
	var m := _mundo(2500)
	_comprobar(m.mi_club() != null, "hay un club al mando")
