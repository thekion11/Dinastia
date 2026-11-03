extends Node
## GOLES POR PARTIDO DEL PARTIDO SIMULADO (3-11-2026): juega una temporada de varias ligas en varias semillas y da la media de goles por partido de liga, para calibrar el balance
## (rango real 2,4-2,9) y para bisecar qué commit lo movió. Sin pruebas ni escenas más allá de `Mundo`: sirve en commits viejos.
##   godot --headless --path . res://pruebas/zz_medir_goles.tscn      (SEMILLAS=6 PAISES=CHI,ARG,ESP)
func _ready() -> void:
	var paises := (OS.get_environment("PAISES") if OS.get_environment("PAISES") != "" else "CHI,ARG,ESP").split(",")
	var n := int(OS.get_environment("SEMILLAS")) if OS.get_environment("SEMILLAS") != "" else 6
	var lista: Array[String] = []
	for x in paises:
		lista.append(String(x))
	var gf_t := 0
	var pj_t := 0
	for s in n:
		var m := Mundo.new()
		m.generar(lista, 1000 + s * 77)
		m.tomar_el_mando(m.ligas[0].clubes[0].id)
		m.jugar_temporada()
		var gf := 0
		var pj := 0
		for l in m.ligas:
			for fila: Dictionary in l.tabla_puntos.values():
				gf += int(fila["gf"])
				pj += int(fila["pj"])
		gf_t += gf
		pj_t += pj
		print("   semilla %d: %.2f goles/partido (%d partidos)" % [1000 + s * 77, float(gf) / maxf(1.0, float(pj) / 2.0), pj / 2])
	print("GOLES/PARTIDO: %.3f (%d partidos)" % [float(gf_t) / maxf(1.0, float(pj_t) / 2.0), pj_t / 2])
	get_tree().quit()
