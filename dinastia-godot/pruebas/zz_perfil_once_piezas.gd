extends Node
## DÓNDE SE VA `Club.once()` (16-11, paso a C++): por piezas, sobre todos los clubes de un mundo entero. Herramienta, no prueba del banco.
##   godot --headless --path . res://pruebas/zz_perfil_once.tscn
func _ready() -> void:
	var m := Mundo.new()
	m.generar([], 777)
	var clubes: Array = m.clubes.values()
	var t := {"once() entero": 0.0, "disponibles": 0.0, "FORMS+orden": 0.0, "asignar (C++)": 0.0, "ajustar_once": 0.0, "manual": 0.0}
	var n := 0
	for v in 3:
		for c: Club in clubes:
			var a := Time.get_ticks_usec()
			c.once()
			var b := Time.get_ticks_usec()
			var libres := c.disponibles()
			var d := Time.get_ticks_usec()
			var forms: Dictionary = Datos.tabla("FORMS")
			var def: Dictionary = forms.get(c.tactica.formacion, forms.get("4-3-3", {}))
			var ranuras: Array = def.get("s", [])
			var orden: Array = OnceAuto.orden_de(ranuras)
			var e := Time.get_ticks_usec()
			var asig := OnceAuto.asignar(libres, ranuras, orden)
			var f := Time.get_ticks_usec()
			var elegidos: Array[Jugador] = []
			for i in ranuras.size():
				if asig.has(i):
					elegidos.append(asig[i])
			LeyesPais.ajustar_once(c, elegidos)
			var g := Time.get_ticks_usec()
			c._once_manual()
			var h := Time.get_ticks_usec()
			t["once() entero"] += b - a; t["disponibles"] += d - b; t["FORMS+orden"] += e - d; t["asignar (C++)"] += f - e; t["ajustar_once"] += g - f; t["manual"] += h - g
			n += 1
	for k: String in t:
		print("%-16s %6.1f µs por club" % [k, float(t[k]) / n])
	get_tree().quit()
