extends Node

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 4242)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var f := Federacion.new()
	f.playoffs = true
	var l: Liga = m.ligas[0]
	var perdio := 0
	var n := 30
	for i in n:
		l.preparar()
		l.jugar_temporada()
		var t := l.tabla()
		var d := f.jugar_playoffs(t, 2026 + i, m.mi_club_id)
		if String(d["campeon"]) != String(d["lider"]):
			perdio += 1
	print("de %d finales, el lider de la tabla perdio el titulo %d veces (%.0f%%)" % [
		n, perdio, 100.0 * float(perdio) / float(n)])
	get_tree().quit()
