extends Node
## A4 rendimiento (4-11-2026): de qué están hechos los ~51.000 nodos de la ciudad en calidad MÍNIMA (la del móvil).
##   CALIDAD=minimo xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/a4_rend_nodos.tscn
var _p: Node
var _n := 0

func _ready() -> void:
	Calidad.elegida = Calidad.MINIMO if OS.get_environment("CALIDAD") != "medio" else Calidad.MEDIO
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	Engine.max_fps = 0
	if _n == 5:
		_p.call("_ver_ciudad_propia")
	if _n == 60:
		var v: Node = null
		for h in _p.get_children():
			if h is VistaCiudad: v = h
		var clases := {}; var invis := 0; var total := 0; var sin_malla := 0
		var por_hijo := {}
		var colis := 0; var luces := 0; var timers := 0; var labels := 0; var vacios := 0
		var pila: Array = [v]
		while not pila.is_empty():
			var x: Node = pila.pop_back()
			total += 1
			var c := x.get_class()
			clases[c] = int(clases.get(c, 0)) + 1
			if x is Node3D and not (x as Node3D).visible: invis += 1
			if x is CollisionShape3D: colis += 1
			if x is Light3D: luces += 1
			if x is Label3D: labels += 1
			if x.get_class() == "Node3D" and x.get_child_count() == 0: vacios += 1
			for ch in x.get_children(): pila.append(ch)
		for ch in v.get_children():
			var cnt := 1 + ch.find_children("*", "", true, false).size()
			por_hijo[ch.name] = cnt
		var hist := {}; var mm_un := 0; var mm_total_inst := 0; var vis_rango := 0
		var lab_txt := {}; var vac_pad := {}
		for x in v.find_children("*", "MultiMeshInstance3D", true, false):
			var mmi := x as MultiMeshInstance3D
			var k := mmi.multimesh.instance_count if mmi.multimesh != null else -1
			var b := "1" if k == 1 else ("2-3" if k <= 3 else ("4-10" if k <= 10 else ("11-100" if k <= 100 else ">100")))
			hist[b] = int(hist.get(b, 0)) + 1
			if k > 0: mm_total_inst += k
		for x in v.find_children("*", "Label3D", true, false):
			var l := x as Label3D
			var pn := String(l.get_parent().name).left(18)
			lab_txt[pn] = int(lab_txt.get(pn, 0)) + 1
		for x in v.find_children("*", "Node3D", true, false):
			if x.get_class() == "Node3D" and x.get_child_count() == 0:
				var pn := String(x.get_parent().name).left(18)
				vac_pad[pn] = int(vac_pad.get(pn, 0)) + 1
		print("MM_HIST ", hist, " instancias_totales=", mm_total_inst)
		var lk := lab_txt.keys(); lk.sort_custom(func(a, b): return lab_txt[a] > lab_txt[b])
		for k in lk.slice(0, 8): print("LABEL_PADRE ", lab_txt[k], " ", k)
		var vk := vac_pad.keys(); vk.sort_custom(func(a, b): return vac_pad[a] > vac_pad[b])
		for k in vk.slice(0, 8): print("VACIO_PADRE ", vac_pad[k], " ", k)
		for x in v.find_children("*", "Node3D", true, false):
			if String(x.name).begins_with("@Node3D@748") or x.name == &"@Node3D@748":
				var sc = x.get_script()
				print("PADRE748 ruta=", x.get_path(), " script=", sc.resource_path if sc != null else "-", " hijos=", x.get_child_count())
				var nombres := {}
				for ch in x.get_children().slice(0, 4000):
					var key: String = ch.get_class() + ":" + String(ch.name).left(10).rstrip("0123456789@") + (":label=" + (ch as Label3D).text.left(14) if ch is Label3D else "")
					nombres[key] = int(nombres.get(key, 0)) + 1
				var nk := nombres.keys(); nk.sort_custom(func(a, b): return nombres[a] > nombres[b])
				for k in nk.slice(0, 8): print("  HIJO748 ", nombres[k], " ", k)
				break
		print("TOTAL ", total, " invisibles=", invis, " colisiones=", colis, " luces=", luces, " Label3D=", labels, " Node3D_vacios=", vacios)
		var ks := clases.keys(); ks.sort_custom(func(a, b): return clases[a] > clases[b])
		for k in ks.slice(0, 12): print("CLASE ", clases[k], " ", k)
		var kh := por_hijo.keys(); kh.sort_custom(func(a, b): return por_hijo[a] > por_hijo[b])
		for k in kh.slice(0, 15): print("HIJO ", por_hijo[k], " ", k)
		get_tree().quit()
