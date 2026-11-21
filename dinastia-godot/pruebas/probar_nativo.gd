extends "res://pruebas/probar_nativo_p2.gd"
## La extensión en C++ (`Nativo`) da los MISMOS bytes que las versiones GDScript a las que
## sustituye, con datos reales: la rampa de las texturas de ruido y el alisado de la ropa de los dos
## cuerpos (30-10-2026). En Linux y Windows la extensión tiene que estar; si falta, es un FALLO.


func _ready() -> void:
	_probar.call_deferred()

func _probar() -> void:
	var nat := Nativo.obj()
	## (5-11) La expectativa es PROPIA del sistema: con binario (Linux, Windows x86_64, Android arm64) tiene que cargar; sin él (Web, macOS, iOS) tiene que
	## estar ausente y el respaldo GDScript es el que manda (lo comprueba pruebas/so/int_nativo_por_sistema).
	var esperada := BaseSO.se_espera_nativo() and OS.get_environment("DINASTIA_SIN_NATIVO") != "1"
	_comprobar((nat != null) == esperada, "la extensión nativa %s (se espera %s en %s)" % ["está cargada" if nat != null else "no está", "sí" if esperada else "no", BaseSO.sistema()])
	if nat == null:
		_fin()
		return
	_probar_rampa_y_ruido(nat)
	_probar_relieve_y_hierba(nat)
	_probar_once_y_multimallas(nat)
	_probar_choques_y_movimiento(nat)
	_probar_partido_simulado_y_clima(nat)
	_probar_locomocion_balon_y_equipo(nat)
	_probar_casos_limite_y_estado(nat)
	_fin()
