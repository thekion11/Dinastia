extends Node
## Sonda de coherencia económica (13-10-2026): la caja de tu club semana a
## semana durante una temporada sin que nadie toque nada, con los movimientos
## más grandes. Uso: godot --headless --path . res://pruebas/sonda_caja.tscn
func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI", "ARG", "ESP"], 11)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	print("inicio: caja ", c.saldo / 1000000, " M · sueldos/sem ", c.masa_salarial() / 1000, " mil · plantel ", c.plantilla.size())
	var antes := c.saldo
	var sem := 0
	while m.temporada_en_curso() and sem < 80:
		m.avanzar_semana()
		sem += 1
		var d := c.saldo - antes
		if absi(d) > 3000000 or sem % 8 == 0:
			if d < -1000000:
				print("   faltas once ", LeyesPais.infracciones_once(c, c.once()), " pais ", c.pais)
			print("sem %2d: caja %6.1f M  (cambio %+.1f M) sueldos/sem %d mil plantel %d" % [sem, c.saldo / 1e6, d / 1e6, c.masa_salarial() / 1000, c.plantilla.size()])
		antes = c.saldo
	get_tree().quit()
