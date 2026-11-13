extends Node
## Sonda (13-11): la caja del club del jugador tras N semanas SIMULADAS sin gestionar nada, en dos supuestos: sin firmar la marca de la
## camiseta y firmando la que más paga en la semana 1. Cifras con `Eco.dinero` (las del menú). Y la proyección anual por partidas.
##   PAISES=USA,NED,ESP CLUBES=0,6,12 SEMANAS=14 [PARTIDAS=1] godot --headless --path . res://pruebas/_sonda/sonda_caja.tscn
func _simular(pais: String, idx: int, semanas: int, firmar: bool) -> Dictionary:
	var m := Mundo.new()
	var ps: Array[String] = []
	ps.assign([pais])
	m.generar(ps, 20261103)
	var liga: Liga = m.ligas[0]
	var c: Club = liga.clubes[idx % liga.clubes.size()]
	m.tomar_el_mando(c.id)
	var antes := c.saldo
	var marca := 0
	if firmar and m.auspicio != null and not m.auspicio.ofertas.is_empty():
		var mejor := 0
		for i in m.auspicio.ofertas.size():
			if int(m.auspicio.ofertas[i]["monto"]) > int(m.auspicio.ofertas[mejor]["monto"]):
				mejor = i
		m.auspicio.firmar(mejor)
		marca = m.auspicio.semanal()
	var f: Finanzas = m._finanzas_de_la_semana(c)
	var proy: Dictionary = f.proyeccion_anual(int(liga.jornadas() / 2), m.ingreso_tienda(c))
	for s in semanas:
		for k in 4:
			var ev := EventosClub.pendiente(m)
			if ev.is_empty():
				break
			EventosClub.aplicar(m, ev, 0)
		m.avanzar_semana()
	return {"club": c, "antes": antes, "despues": c.saldo, "marca": marca, "proy": proy, "ofertas": 0 if m.auspicio == null else m.auspicio.ofertas.size()}

func _ready() -> void:
	var semanas := maxi(1, int(OS.get_environment("SEMANAS")))
	for pais: String in OS.get_environment("PAISES").split(","):
		for idx: String in OS.get_environment("CLUBES").split(","):
			var a := _simular(pais, int(idx), semanas, false)
			var b := _simular(pais, int(idx), semanas, true)
			var c: Club = a["club"]
			print("%s %-20s rep %2d | caja inicial %s | sin marca: %s | con la mejor marca (%s/sem): %s | ejercicio previsto %s" % [
				pais, c.nombre, c.rep, Eco.dinero(int(a["antes"])), Eco.dinero(int(a["despues"])), Eco.dinero(int(b["marca"])), Eco.dinero(int(b["despues"])),
				Eco.dinero(int((a["proy"] as Dictionary).get("resultado", 0)))])
			if OS.get_environment("PARTIDAS") == "1":
				var pr: Dictionary = a["proy"]
				for grupo: String in ["ingresos", "gastos"]:
					for k: String in (pr.get(grupo, {}) as Dictionary):
						print("      %-8s %-45s %s" % [grupo, k, Eco.dinero(int(pr[grupo][k]))])
	get_tree().quit()
