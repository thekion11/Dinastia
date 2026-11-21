extends Node
## A4 rendimiento (4-11-2026): luces y oclusores de la ciudad en MÍNIMA: cuántas hay, con sombra, y cuáles son duplicados.
##   CALIDAD=minimo xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/a4_rend_luces.tscn
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
		var luces := v.find_children("*", "Light3D", true, false)
		var por_tipo := {}; var con_sombra := 0; var visibles := 0; var dup := {}; var con_rango := 0
		for l in luces:
			var l_loc := l as Light3D
			por_tipo[l_loc.get_class()] = int(por_tipo.get(l_loc.get_class(), 0)) + 1
			if l_loc.shadow_enabled: con_sombra += 1
			if l_loc.visible: visibles += 1
			if l_loc.distance_fade_enabled: con_rango += 1
			var k := "%s|%d,%d,%d|%.2f" % [l_loc.get_class(), roundi(l_loc.global_position.x), roundi(l_loc.global_position.y), roundi(l_loc.global_position.z), l_loc.light_energy]
			dup[k] = int(dup.get(k, 0)) + 1
		var n_dup := 0
		for k in dup:
			if dup[k] > 1: n_dup += dup[k] - 1
		print("LUCES total=", luces.size(), " tipos=", por_tipo, " con_sombra=", con_sombra, " visibles=", visibles, " con_distance_fade=", con_rango, " duplicadas(misma pos y energía)=", n_dup)
		var lab := v.find_children("*", "Label3D", true, false)
		var gl := {}
		for x in lab:
			var l2 := x as Label3D
			var pad := String(l2.get_parent().name).left(14)
			var kk := "%s | rango_fin=%.0f | tam=%d | px=%.4f" % [pad, l2.visibility_range_end, l2.font_size, l2.pixel_size]
			gl[kk] = int(gl.get(kk, 0)) + 1
		var gk := gl.keys(); gk.sort_custom(func(a, b): return gl[a] > gl[b])
		print("LABELS total=", lab.size())
		for k in gk.slice(0, 20): print("  LABEL ", gl[k], " ", k)
		var oc := v.find_children("*", "OccluderInstance3D", true, false)
		var tipos := {}; var dup_o := {}; var vis_o := 0; var tam_media := 0.0
		for o in oc:
			var o_loc := o as OccluderInstance3D
			var oc3: Occluder3D = o_loc.occluder
			var c := oc3.get_class() if oc3 != null else "nulo"
			tipos[c] = int(tipos.get(c, 0)) + 1
			if o_loc.visible: vis_o += 1
			var sz := Vector3.ZERO
			if oc3 is BoxOccluder3D: sz = (oc3 as BoxOccluder3D).size
			tam_media += sz.length()
			var k2 := "%s|%d,%d,%d|%d,%d,%d" % [c, roundi(o_loc.global_position.x), roundi(o_loc.global_position.y), roundi(o_loc.global_position.z), roundi(sz.x), roundi(sz.y), roundi(sz.z)]
			dup_o[k2] = int(dup_o.get(k2, 0)) + 1
		var n_dup_o := 0
		for k2 in dup_o:
			if dup_o[k2] > 1: n_dup_o += dup_o[k2] - 1
		print("OCLUSORES total=", oc.size(), " tipos=", tipos, " visibles=", vis_o, " duplicados(misma pos y tamaño)=", n_dup_o, " tamaño_medio=", snappedf(tam_media / maxf(oc.size(), 1), 0.1))
		get_tree().quit()
