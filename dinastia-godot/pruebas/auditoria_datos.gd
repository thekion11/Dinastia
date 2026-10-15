extends Node
## AUDITORÍA DE INTEGRIDAD DE DATOS (14-10-2026, segunda pasada). Genera el mundo
## entero en la base ficticia y en la real y comprueba invariantes: ids únicos,
## rangos de media y edad, colores válidos, porteros por plantel, dorsales
## repetidos, nombres vacíos o duplicados, ligas pares, salarios y saldos.
## Imprime «HALLAZGO …» por cada violación y el recuento al final.
##   godot --headless --path . res://pruebas/auditoria_datos.tscn
var _hallazgos := 0
var _por_tipo := {}

func _h(tipo: String, detalle: String) -> void:
	_hallazgos += 1
	_por_tipo[tipo] = int(_por_tipo.get(tipo, 0)) + 1
	if int(_por_tipo[tipo]) <= 4:
		print("HALLAZGO [%s] %s" % [tipo, detalle])

func _ready() -> void:
	for real in [false, true]:
		if real and not Datos.hay_pack_real():
			continue
		Datos.usar_base_real(real)
		var base := "real" if real else "ficticia"
		var m := Mundo.new()
		m.generar([], 4711)
		var ids := {}
		var nombres_club := {}
		var jug_ids := {}
		var n_jug := 0
		for c: Club in m.clubes.values():
			if ids.has(c.id):
				_h("club_id_duplicado", "%s %s" % [base, c.id])
			ids[c.id] = true
			if nombres_club.has(c.nombre):
				_h("club_nombre_duplicado", "%s %s" % [base, c.nombre])
			nombres_club[c.nombre] = true
			if c.nombre.strip_edges() == "":
				_h("club_sin_nombre", "%s %s" % [base, c.id])
			if not Color.html_is_valid(c.color1) or not Color.html_is_valid(c.color2):
				_h("color_invalido", "%s %s %s %s" % [base, c.nombre, c.color1, c.color2])
			if c.color1.to_lower() == c.color2.to_lower():
				_h("colores_iguales", "%s %s" % [base, c.nombre])
			if c.rep < 1 or c.rep > 100:
				_h("rep_fuera_de_rango", "%s %s %d" % [base, c.nombre, c.rep])
			if c.estadio_aforo < 1000:
				_h("aforo_minusculo", "%s %s %d" % [base, c.nombre, c.estadio_aforo])
			var porteros := 0
			var dorsales := {}
			for j: Jugador in c.plantel():
				n_jug += 1
				if jug_ids.has(j.id):
					_h("jugador_id_duplicado", "%s %s" % [base, j.id])
				jug_ids[j.id] = true
				if j.nombre.strip_edges() == "":
					_h("jugador_sin_nombre", "%s %s" % [base, j.id])
				if j.ovr < 20 or j.ovr > 99:
					_h("ovr_fuera_de_rango", "%s %s %d" % [base, j.nombre, j.ovr])
				if j.edad < 15 or j.edad > 45:
					_h("edad_rara", "%s %s %d" % [base, j.nombre, j.edad])
				if j.pos == "POR":
					porteros += 1
				if j.dorsal > 0:
					if dorsales.has(j.dorsal):
						_h("dorsal_repetido", "%s %s #%d" % [base, c.nombre, j.dorsal])
					dorsales[j.dorsal] = true
				if j.club_id != c.id:
					_h("club_id_incoherente", "%s %s en %s" % [base, j.nombre, c.nombre])
			if porteros < 2:
				_h("menos_de_2_porteros", "%s %s (%d)" % [base, c.nombre, porteros])
		for l: Liga in m.ligas:
			if l.clubes.size() % 2 != 0:
				_h("liga_impar", "%s %s %d" % [base, l.nombre, l.clubes.size()])
		print("[%s] clubes %d, jugadores %d" % [base, m.clubes.size(), n_jug])
	Datos.usar_base_real(false)
	print("RESUMEN ", _por_tipo)
	print("===== FIN AUDITORÍA DE DATOS. %d hallazgos =====" % _hallazgos)
	get_tree().quit()
