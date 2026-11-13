extends Node
## Sonda (13-11): el libro de movimientos del club tras N semanas simuladas con la mejor marca firmada, sumado por concepto.
##   PAISES=ESP CLUBES=0 SEMANAS=14 godot --headless --path . res://pruebas/_sonda/sonda_libro.tscn
func _ready() -> void:
	var semanas := maxi(1, int(OS.get_environment("SEMANAS")))
	for pais: String in OS.get_environment("PAISES").split(","):
		for idx: String in OS.get_environment("CLUBES").split(","):
			var m := Mundo.new()
			var ps: Array[String] = []
			ps.assign([pais])
			m.generar(ps, 20261103)
			var c: Club = m.ligas[0].clubes[int(idx) % m.ligas[0].clubes.size()]
			m.tomar_el_mando(c.id)
			var mejor := 0
			for i in m.auspicio.ofertas.size():
				if int(m.auspicio.ofertas[i]["monto"]) > int(m.auspicio.ofertas[mejor]["monto"]):
					mejor = i
			m.auspicio.firmar(mejor)
			var caja: Array = [c.saldo]
			for s in semanas:
				for k in 4:
					var ev := EventosClub.pendiente(m)
					if ev.is_empty():
						break
					EventosClub.aplicar(m, ev, 0)
				m.avanzar_semana()
				caja.append(c.saldo)
			print("%s %s  plantel %d  caja por semana: %s" % [pais, c.nombre, c.plantilla.size(), " ".join(caja.map(func(x: int) -> String: return Eco.dinero(x).replace(" EUR", "")))])
			var suma := {}
			for f: Dictionary in m.libro_financiero:
				var k := String(f["concepto"]).substr(0, 34)
				suma[k] = int(suma.get(k, 0)) + int(f["monto"])
			var claves := suma.keys()
			claves.sort_custom(func(a: String, b: String) -> bool: return int(suma[a]) < int(suma[b]))
			for k: String in claves.slice(0, 8):
				print("      %-36s %s" % [k, Eco.dinero(int(suma[k]))])
	get_tree().quit()
