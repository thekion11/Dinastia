extends Node
## DÓNDE SE VA EL ONCE AUTOMÁTICO (10-11-2026, paso a C++): `Club.once()` por piezas, sobre todos los clubes del mundo. Herramienta, no prueba del banco.
##   godot --headless --path . res://pruebas/zz_perfil_once.tscn
func _ready() -> void:
	var m := Mundo.new()
	m.generar([], 777)
	var clubes: Array = m.clubes.values()
	var forms: Dictionary = Datos.tabla("FORMS")
	var t := {"once() entero": 0.0, "disponibles()": 0.0, "ranuras+orden": 0.0, "OnceAuto.asignar": 0.0, "  de ello _nativo (empaquetar+C++)": 0.0, "LeyesPais.ajustar_once": 0.0}
	var vueltas := 5
	for v in vueltas:
		for c: Club in clubes:
			var a := Time.get_ticks_usec()
			var once := c.once()
			var b := Time.get_ticks_usec()
			var libres := c.disponibles()
			var d := Time.get_ticks_usec()
			var forma := c.tactica.formacion
			var def: Dictionary = forms.get(forma, forms.get("4-3-3", {}))
			var ranuras: Array = def.get("s", [])
			var orden: Array = []
			for i in ranuras.size():
				orden.append(i)
			orden.sort_custom(func(x: int, y: int) -> bool: return PesosPuesto.es_portero(String(ranuras[x][0])) and not PesosPuesto.es_portero(String(ranuras[y][0])))
			var e := Time.get_ticks_usec()
			var asig := OnceAuto.asignar(libres, ranuras, orden)
			var f := Time.get_ticks_usec()
			var nat := Nativo.obj()
			var g := Time.get_ticks_usec()
			if nat != null:
				OnceAuto._nativo(nat, libres, ranuras, orden)
			var h := Time.get_ticks_usec()
			var elegidos: Array[Jugador] = []
			for i: int in asig:
				elegidos.append(asig[i])
			LeyesPais.ajustar_once(c, elegidos)
			var k := Time.get_ticks_usec()
			t["once() entero"] += b - a
			t["disponibles()"] += d - b
			t["ranuras+orden"] += e - d
			t["OnceAuto.asignar"] += f - e
			t["  de ello _nativo (empaquetar+C++)"] += h - g
			t["LeyesPais.ajustar_once"] += k - h
			once.size()
	var n := float(vueltas * clubes.size())
	for k: String in t:
		print("   %-38s %7.1f µs por once" % [k, float(t[k]) / n])
	get_tree().quit()
