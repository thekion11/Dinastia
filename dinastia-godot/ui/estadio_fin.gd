extends "res://ui/estadio_p5.gd"
## Capa de `estadio.gd` (entre la 5 y la última): el final del partido del motor, con sus helpers de la capa de abajo.

## Cuando el motor termina el partido: el banner final, el acta a CSV y el cierre a los 5 s.
func _fin_del_partido_motor() -> void:
	if _motor.estado == "fin" and not _final_motor:
		_final_motor = true
		VotoMotor.mostrar(self, _motor)   ## (11-11) voto de diversión si se prueba a ciegas (A/B/C)
		## Las estadísticas del césped, a un CSV (M-162).
		if _stats != null:
			_stats.a_csv(partido, _motor)
		var mio_gana := (partido.goles_local > partido.goles_visita and _mi_lado == 0) or (partido.goles_visita > partido.goles_local and _mi_lado == 1)
		var pen := ""
		if not _motor.tanda.is_empty():
			var gl := _motor.goles_tanda(0)
			var gv := _motor.goles_tanda(1)
			pen = "  (%s %d-%d)" % [Idiomas.t("pen."), gl, gv]
			mio_gana = (gl > gv and _mi_lado == 0) or (gv > gl and _mi_lado == 1)
		_mostrar_banner_gol("🏁 %s  %s %d - %d %s%s" % [Idiomas.t("FINAL"), Nombres.visible(partido.local.nombre),
			partido.goles_local, partido.goles_visita, Nombres.visible(partido.visita.nombre), pen], mio_gana)
		get_tree().create_timer(5.0).timeout.connect(func() -> void:
			if is_instance_valid(self):
				cerrado.emit())
