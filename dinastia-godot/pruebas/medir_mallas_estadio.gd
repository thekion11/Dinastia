extends Node
## (10-11) Cuenta las mallas que dibuja el estadio de un club (por nombre del nodo padre) para buscar qué multiplica las llamadas.
##   CLUBES="R3al Madrid,Int3r" CALIDAD=-3 godot --headless res://pruebas/medir_mallas_estadio.tscn
func _ready() -> void:
	Datos.usar_base_real(true)
	Calidad.elegida = int(OS.get_environment("CALIDAD")) if OS.get_environment("CALIDAD") != "" else Calidad.MEDIO
	var m := Mundo.new()
	m.generar(["ESP", "ITA"], 2026)
	for nombre: String in OS.get_environment("CLUBES").split(","):
		var club: Club = null
		for c: Club in m.clubes.values():
			if c.nombre == nombre:
				club = c
		if club == null:
			print("no está ", nombre)
			continue
		var root := Node3D.new()
		add_child(root)
		await StadiumBuilder.build(root, club.perfil_estadio(), 60000, 0.8, 7, club)
		var cuenta := {}
		var total := [0]
		_contar(root, cuenta, total)
		var filas := cuenta.keys()
		filas.sort_custom(func(a, b) -> bool: return cuenta[a] > cuenta[b])
		print("== ", nombre, " calidad ", Calidad.elegida, " · mallas+superficies: ", total[0])
		for k in filas.slice(0, 18):
			print("   ", cuenta[k], "  ", k)
		root.free()
	get_tree().quit()

func _contar(n: Node, cuenta: Dictionary, total: Array) -> void:
	var sup := 0
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null and (n as MeshInstance3D).visible:
		sup = (n as MeshInstance3D).mesh.get_surface_count()
	elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).visible:
		sup = 1
	if sup > 0:
		var clave := String(n.get_parent().name) + "/" + String(n.name).rstrip("0123456789@")
		cuenta[clave] = int(cuenta.get(clave, 0)) + sup
		total[0] += sup
	for h in n.get_children():
		_contar(h, cuenta, total)
