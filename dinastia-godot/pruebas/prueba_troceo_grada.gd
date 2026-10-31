extends Node
## EL TROCEO DE LA GRADA NO DEJA BUTACAS SIN DIBUJAR (28-10-2026, revisión de `OptimizarGrada`): construye un estadio con y sin trozos y comprueba que (1) salen
## las mismas instancias por tipo (butacas cerca/lejos, hinchada) y (2) la caja de cada trozo contiene todas sus instancias (si no, el culling de la cámara las
## descartaría estando a la vista). Necesita pantalla (los MultiMesh no guardan datos sin ella).
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/prueba_troceo_grada.tscn
var _fallos := 0

func _ok(c: bool, txt: String) -> void:
	print(("  ok    " if c else "  FALLO ") + txt)
	if not c:
		_fallos += 1

func _cuenta(r: Node) -> Dictionary:
	var d := {}
	for n in r.find_children("*", "MultiMeshInstance3D", true, false):
		var base := String(n.name).split("_")[0]
		if base in OptimizarGrada.NOMBRES:
			d[base] = int(d.get(base, 0)) + (n as MultiMeshInstance3D).multimesh.instance_count
	return d

func _build(club: Club) -> Node3D:
	var r := Node3D.new()
	add_child(r)
	var perfil := club.perfil_estadio()
	StadiumBuilder.build_pitch(r, perfil, club)
	StadiumBuilder.build(r, perfil, int(perfil.get("aforo", 20000)), 0.8, club._hash_id(), club)
	return r

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("sin pantalla no se mide nada")
		print("===== FIN. 0 fallos =====")
		get_tree().quit()
		return
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var club: Club = m.ligas[0].clubes[0]
	var entero := _build(club)
	var antes := _cuenta(entero)
	var trozos := _build(club)
	var hechos := OptimizarGrada.trocear(trozos)
	var despues := _cuenta(trozos)
	_ok(hechos > 0, "se parte algún MultiMesh grande (%d)" % hechos)
	_ok(antes == despues and not antes.is_empty(), "las mismas instancias por tipo antes y después %s" % str(despues))
	var fuera := 0
	var total := 0
	var vacios := 0
	for n in trozos.find_children("*_*", "MultiMeshInstance3D", true, false):
		var mmi := n as MultiMeshInstance3D
		if not (String(mmi.name).split("_")[0] in OptimizarGrada.NOMBRES):
			continue
		var mm := mmi.multimesh
		var caja := mmi.get_aabb().grow(0.05)
		if mm.instance_count == 0:
			vacios += 1
		for i in mm.instance_count:
			total += 1
			if not caja.has_point(mm.get_instance_transform(i).origin):
				fuera += 1
	_ok(total > 1000 and fuera == 0, "la caja de cada trozo contiene todas sus butacas e hinchas (%d de %d fuera)" % [fuera, total])
	_ok(vacios == 0, "ningún trozo vacío")
	print("===== FIN. %d fallos =====" % _fallos)
	get_tree().quit(0 if _fallos == 0 else 1)
