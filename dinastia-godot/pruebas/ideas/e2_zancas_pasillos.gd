extends BaseIdea
## ESTADIO (27-10-2026, decisión del líder): los pasillos de TODAS las bandejas llevan zancas (muretes laterales), no solo las escaleras de la baja.

func _probar() -> void:
	_titulo("E2 · ZANCAS EN LOS PASILLOS DE LAS BANDEJAS ALTAS")
	var club := Club.new("e2_club", "Club E2")
	club.color1 = "#1f4f9a"
	club.color2 = "#f2f2f2"
	var raiz := Node3D.new()
	add_child(raiz)
	StadiumBuilder.build(raiz, {"forma": "cuenco", "niveles": 3, "techo": "anillo", "aforo": 60000}, 60000, 0.8, 4242, club)
	var y0 := StadiumBuilder.ALTURA_PIE + StadiumBuilder.subida_bandeja() / 2.0
	var bajas := 0
	var altas := 0
	var mal := 0
	for n: Node in raiz.find_children("ZancasPasillo", "MultiMeshInstance3D", true, false):
		var deck := n.get_parent() as MeshInstance3D
		var cuenta := (n as MultiMeshInstance3D).multimesh.instance_count
		if cuenta == 0 or cuenta % 2 != 0:
			mal += 1
		if absf(deck.position.y - y0) < 0.1:
			bajas += 1
		elif deck.position.y > y0 + 0.5:
			altas += 1
	_comprobar(mal == 0, "cada pasillo lleva dos zancas (cuenta par y > 0)")
	_comprobar(bajas > 0, "las tribunas de la bandeja baja las llevan (%d)" % bajas)
	_comprobar(altas > 0, "y las de las bandejas altas también (%d)" % altas)
	## Una zanca sigue la pendiente: más larga que el fondo en planta y con su arista alta por encima de los peldaños.
	var tam := Vector3(30, 0.4, 14)
	var esc := DetalleGrada.escalones_de(MeshInstance3D.new(), tam, false, deg_to_rad(StadiumBuilder.RAKE_GRADOS))
	var z := DetalleGrada.zancas_pasillo(esc, tam, false)
	_comprobar(z.size() >= 2 and z.size() % 2 == 0, "una tribuna de prueba da %d zancas" % z.size())
