extends Node
## CUÁNTO TARDA ARMAR EL ONCE (M-469, 3-11-2026): `Club.once()` sobre cada club del mundo entero, varias vueltas. Imprime µs por once y una huella de los onces
## elegidos (ids en orden) para comprobar que optimizar no cambia a quién se elige.
##   godot --headless --path . res://pruebas/zz_medir_once.tscn
func _ready() -> void:
	var m := Mundo.new()
	m.generar([], 777)
	var clubes: Array = m.clubes.values()
	var huella := 0
	var huella2 := 0
	for c: Club in clubes:
		for j: Jugador in c.once():
			huella = hash([huella, j.id])
	for c: Club in clubes:
		for j: Jugador in c.once():
			huella2 = hash([huella2, j.id])
	print("huella1 %d huella2 %d" % [huella, huella2])
	var vueltas := 5
	var t0 := Time.get_ticks_usec()
	for v in vueltas:
		for c: Club in clubes:
			c.once()
	var dt := (Time.get_ticks_usec() - t0) / float(vueltas * clubes.size())
	print("once(): %.0f µs por club (%d clubes x %d vueltas) huella %d" % [dt, clubes.size(), vueltas, huella])
	_partes(clubes)
	get_tree().quit()

func _partes(clubes: Array) -> void:
	var t := {"disponibles": 0.0, "_once_manual": 0.0, "ajustar_once": 0.0, "filter+orden (ranuras)": 0.0}
	for c: Club in clubes:
		var a := Time.get_ticks_usec()
		var libres := c.disponibles()
		t["disponibles"] += Time.get_ticks_usec() - a
		a = Time.get_ticks_usec()
		c._once_manual()
		t["_once_manual"] += Time.get_ticks_usec() - a
		a = Time.get_ticks_usec()
		LeyesPais.ajustar_once(c, libres.slice(0, 11))
		t["ajustar_once"] += Time.get_ticks_usec() - a
		a = Time.get_ticks_usec()
		var forms: Dictionary = Datos.tabla("FORMS")
		var def: Dictionary = forms.get(c.tactica.formacion, forms.get("4-3-3", {}))
		var orden: Array = []
		for i in (def.get("s", []) as Array).size():
			orden.append(i)
		t["filter+orden (ranuras)"] += Time.get_ticks_usec() - a
	for k: String in t:
		print("   %-24s %6.1f µs por club" % [k, float(t[k]) / clubes.size()])
