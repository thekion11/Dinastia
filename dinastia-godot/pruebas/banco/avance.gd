extends "res://pruebas/banco/base.gd"
## [Banco · grupo «avance»] (17-11-2026) El avance por días: el modelo de eventos del día, los disparadores, el núcleo que se detiene en cada parada, el sorteo del saque
## en el motor y la réplica de un partido (jugar de nuevo / momentos). Cada sección corre la misma lógica que su escena de `herramientas/especiales.sh` (así el banco
## entero la vigila): la escena y el banco comparten el cuerpo (`correr`). Las pruebas con pantalla (`probar_avance_ui`, menú del partido, resultado) siguen en `especiales.sh`.

func _correr(ruta: String, que: String) -> void:
	var t: Node = (load(ruta) as GDScript).new()
	var f: int = t.correr(self)
	_comprobar(f == 0, "%s (%d fallos)" % [que, f])
	t.free()

func _probar_avance_eventos_y_disparadores() -> void:
	_titulo("AVANCE POR DÍAS: EVENTOS DEL DÍA Y DISPARADORES")
	_correr("res://pruebas/probar_eventos_dia.gd", "el modelo de eventos del día (clases, zonas, paradas; 4 mundos)")
	_correr("res://pruebas/probar_disparadores_dia.gd", "los disparadores solo observan y salen una vez (3 mundos)")

func _probar_avance_nucleo_y_saque() -> void:
	_titulo("AVANCE POR DÍAS: NÚCLEO DE PARADAS, SAQUE INICIAL Y RÉPLICA")
	_correr("res://pruebas/probar_avance_dias.gd", "el avance se detiene en cada parada y recorre una temporada entera (4 mundos)")
	_correr("res://pruebas/probar_saque_inicial.gd", "el motor respeta el sorteo del saque inicial (3 mundos)")
	_correr("res://pruebas/probar_replica_partido.gd", "la réplica de un partido clona los clubes y arranca en el minuto y el marcador de la jugada (3 mundos)")

func _probar_menu_y_pausa_partido() -> void:
	_titulo("MENÚ DEL PARTIDO Y PAUSA: PESTAÑAS, SORTEO DEL SAQUE Y LAS SEIS OPCIONES DE LA PAUSA")
	var t: Node = (load("res://pruebas/probar_menu_y_pausa.gd") as GDScript).new()
	var f: int = t.correr(self)
	_comprobar(f == 0, "el menú (3 países) guarda el sorteo mostrado y la pausa llama a lo suyo, con confirmación al simular (%d fallos)" % f)
	t.free()

func _probar_resumen_descanso_y_final() -> void:
	_titulo("RESUMEN DEL DESCANSO Y DEL FINAL: CIFRAS REALES, PASES SOLO SI SE JUGÓ EN EL CÉSPED, GOLEADORES Y MARCADOR")
	var t: Node = (load("res://pruebas/probar_resumen_partido.gd") as GDScript).new()
	var f: int = t.correr(self)
	_comprobar(f == 0, "el resumen (3 países) usa las cifras del partido y se monta en el descanso y en el final (%d fallos)" % f)
	t.free()
