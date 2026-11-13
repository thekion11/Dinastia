extends Node
## COSTE DE ARMAR EL ONCE DE LA IA (13-11-2026): `Club.once()` y sus partes (disponibles, once manual, tabla de formaciones, ajuste de la ley del país) en µs por club sobre un mundo entero. Herramienta, no prueba del banco.
##   godot --headless --path . res://pruebas/zz_tmp_once.tscn
func _ready() -> void:
	var m := Mundo.new()
	m.generar([], 777)
	var cl: Array = []
	for l: Liga in m.ligas:
		cl.append_array(l.clubes)
	var n := mini(cl.size(), 400)
	var t0 := Time.get_ticks_usec()
	for i in n: (cl[i] as Club).once()
	var t_once := Time.get_ticks_usec() - t0
	t0 = Time.get_ticks_usec()
	for i in n: (cl[i] as Club).disponibles()
	var t_disp := Time.get_ticks_usec() - t0
	t0 = Time.get_ticks_usec()
	for i in n: (cl[i] as Club)._once_manual()
	var t_man := Time.get_ticks_usec() - t0
	var ts := {}
	t0 = Time.get_ticks_usec()
	for i in n:
		var c: Club = cl[i]
		var forms: Dictionary = Datos.tabla("FORMS")
		forms.get(c.tactica.formacion, {})
	var t_forms := Time.get_ticks_usec() - t0
	t0 = Time.get_ticks_usec()
	for i in n:
		var c: Club = cl[i]
		LeyesPais.ajustar_once(c, c.once())
	var t_ley := Time.get_ticks_usec() - t0 - t_once
	print("ONCE por club: total %.0f µs · disponibles %.0f · once_manual %.0f · tabla FORMS %.0f · ajustar_once %.0f" % [float(t_once)/n, float(t_disp)/n, float(t_man)/n, float(t_forms)/n, float(t_ley)/n])
	get_tree().quit()
