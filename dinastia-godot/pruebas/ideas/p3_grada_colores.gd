extends BaseIdea
## LA GRADA CON LOS COLORES DEL CLUB EN CUALQUIER ESTADIO (27-10-2026). Las rayas, bufandas y gorras de los
## hinchas (`hinchada.gdshader`, `bufanda1/2`) solo se pintaban con el club en el partido y en la visita al
## estadio; en la ciudad y en la cinemática de fichaje salían con el verde por defecto (captura P3 del
## banquillo de un club negro y blanco). Ahora lo hace `StadiumBuilder.build` al recibir el club.

func _probar() -> void:
	_titulo("P3 · LA GRADA VISTE LOS COLORES DEL CLUB DE CASA")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var club: Club = m.ligas[0].clubes[0]
	club.color1 = "#000000"
	club.color2 = "#ffffff"
	var raiz := Node3D.new()
	add_child(raiz)
	var perfil := m.perfil_estadio_de(club)
	StadiumBuilder.build(raiz, perfil, int(perfil.get("aforo", 20000)), 0.35, club._hash_id(), club)
	var mats := OlaGrada.materiales(raiz)
	_comprobar(mats.size() > 0, "hay hinchas con el sombreador de la grada (%d materiales)" % mats.size())
	var mal := 0
	for mt: ShaderMaterial in mats:
		var b1: Color = mt.get_shader_parameter("bufanda1")
		var b2: Color = mt.get_shader_parameter("bufanda2")
		if not b1.is_equal_approx(Color("#000000")) or not b2.is_equal_approx(Color("#ffffff")):
			mal += 1
	_comprobar(mal == 0, "rayas, bufandas y gorras en negro y blanco, los del club (%d de %d con otro color)" % [mal, mats.size()])
	var sesgo := float(OlaGrada.PIEL_SESGO.get(club.pais, 1.5))
	var piel_ok := mats.all(func(mt: ShaderMaterial) -> bool: return is_equal_approx(float(mt.get_shader_parameter("piel_sesgo")), sesgo))
	_comprobar(piel_ok, "y las pieles del país del club (%s, sesgo %.1f)" % [club.pais, sesgo])
	raiz.free()
