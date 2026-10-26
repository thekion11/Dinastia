extends BaseIdea
## LA GRADA Y EL EXTERIOR CREÍBLES (pgra, 26-10-2026): lo que se añadió contra las
## «cajas grises» existe, está donde debe y se comporta como el resto del estadio.
##   · escaleras: cada peldaño de acceso tiene su canto amarillo en su arista de
##     delante; cada escalera, dos zancas y su pasamanos; los pasillos, sus cantos;
##   · techo: cada tribuna con cubierta lleva sus vigas, que se esconden con la losa
##     ante una cámara que está detrás (la de TV) y vuelven a verse desde el campo;
##   · fachada: el vidrio ya no es negro liso (lleva despiece y tono);
##   · entorno: césped, paseos, jardineras y bolardos alrededor de la plaza.

func _probar() -> void:
	_titulo("PGRA · GRADA Y EXTERIOR CREÍBLES")
	var club := Club.new("pgra_club", "Club Grada")
	club.color1 = "#1f4f9a"
	club.color2 = "#f2f2f2"
	var raiz := Node3D.new()
	add_child(raiz)
	var est := {"forma": "cuenco", "niveles": 2, "techo": "anillo", "aforo": 40000}
	StadiumBuilder.build(raiz, est, 40000, 0.8, 4242, club)
	_escaleras(raiz)
	_techo(raiz)
	_fachada(raiz)
	EntornoEstadio.montar(raiz, est, 2)
	_entorno(raiz)
	## Sin techo: ni una viga.
	var raiz2 := Node3D.new()
	add_child(raiz2)
	StadiumBuilder.build(raiz2, {"forma": "rect", "niveles": 1, "techo": "sin", "aforo": 15000}, 15000, 0.8, 7, club)
	_comprobar(raiz2.find_children("VigasTecho", "", true, false).is_empty(), "un estadio sin techo no lleva vigas")
	_comprobar(not raiz2.find_children("CantosPasillo", "", true, false).is_empty(), "el estadio chico también lleva cantos en sus pasillos")

func _instancias(raiz: Node, nombre: String) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for n: Node in raiz.find_children("*", "MultiMeshInstance3D", true, false):
		if String(n.name).contains(nombre):
			var mmi := n as MultiMeshInstance3D
			for k in mmi.multimesh.instance_count:
				out.append(mmi.global_transform * mmi.multimesh.get_instance_transform(k))
	return out

func _escaleras(raiz: Node3D) -> void:
	var pel := _instancias(raiz, "EscalerasAcceso")
	var cantos := _instancias(raiz, "CantosAcceso")
	var zancas := _instancias(raiz, "ZancasAcceso")
	_comprobar(pel.size() > 20, "hay escaleras de acceso (%d peldaños)" % pel.size())
	_comprobar(cantos.size() == pel.size(), "un canto por peldaño de acceso (%d / %d)" % [cantos.size(), pel.size()])
	## Cada canto en la arista de arriba y delante de SU peldaño (a menos de 6 cm).
	var malos := 0
	for c: Transform3D in cantos:
		var mejor := INF
		for p: Transform3D in pel:
			var e := p.basis.get_scale()
			var lateral := e.x < e.z
			var dir := Vector3(-signf(p.origin.x), 0, 0) if lateral else Vector3(0, 0, -signf(p.origin.z))
			var arista := p.origin + dir * (minf(e.x, e.z) * 0.5) + Vector3(0, e.y * 0.5, 0)
			mejor = minf(mejor, (c.origin + dir * 0.035 + Vector3(0, 0.02, 0)).distance_to(arista))
		if mejor > 0.06:
			malos += 1
	_comprobar(malos == 0, "cada canto está en la arista de su peldaño (%d fuera de sitio)" % malos)
	## Dos zancas por escalera: las escaleras son los peldaños más altos de cada grupo.
	var altos := 0
	for p: Transform3D in pel:
		if p.origin.y + p.basis.get_scale().y * 0.5 > 1.2:
			altos += 1
	_comprobar(zancas.size() >= 2 and zancas.size() % 2 == 0, "zancas a los dos lados (%d)" % zancas.size())
	## Las zancas no se hunden en el suelo ni vuelan por encima de la grada.
	var fuera := 0
	for z: Transform3D in zancas:
		if z.origin.y < 0.0 or z.origin.y > 3.0:
			fuera += 1
	_comprobar(fuera == 0, "las zancas van entre el suelo y la grada")
	_comprobar(_instancias(raiz, "PasamanosAcceso").size() == zancas.size() * 4, "pasamanos y tres postes por zanca")
	var esc := _instancias(raiz, "Pasillos")
	var cp := _instancias(raiz, "CantosPasillo")
	var vivos := 0
	for e: Transform3D in esc:
		if e.basis.get_scale().x > 0.01:
			vivos += 1
	_comprobar(cp.size() == vivos and vivos > 100, "un canto por peldaño de pasillo (%d / %d)" % [cp.size(), vivos])

func _techo(raiz: Node3D) -> void:
	var vigas := raiz.find_children("VigasTecho", "MultiMeshInstance3D", true, false)
	_comprobar(vigas.size() == 4, "las cuatro tribunas con techo de anillo llevan vigas (%d)" % vigas.size())
	var en_grupo := 0
	for v: Node in vigas:
		if v.is_in_group("techo_estadio"):
			en_grupo += 1
	_comprobar(en_grupo == vigas.size(), "las vigas se esconden con el techo (grupo techo_estadio)")
	## Una cámara detrás de la tribuna +X (la de TV) esconde SU techo y sus vigas, no las de enfrente.
	var cam := Camera3D.new()
	raiz.add_child(cam)
	cam.global_position = Vector3(90.0, 30.0, 0.0)
	StadiumBuilder.ocultar_techo_ante(cam)
	var propias := 0
	var enfrente := 0
	for v: Node in vigas:
		var g := v as GeometryInstance3D
		if g.global_position.x > 20.0:
			propias += 1 if g.layers == StadiumBuilder.CAPA_TECHO_OCULTO else 0
		elif g.global_position.x < -20.0:
			enfrente += 1 if g.layers == 1 else 0
	_comprobar(propias == 1 and enfrente == 1, "ante la cámara de TV se esconden las vigas de su tribuna y se ven las de enfrente")
	cam.global_position = Vector3(0.0, 2.0, 0.0)
	StadiumBuilder.ocultar_techo_ante(cam)
	var visibles := 0
	for v: Node in vigas:
		visibles += 1 if (v as GeometryInstance3D).layers == 1 else 0
	_comprobar(visibles == vigas.size(), "desde el campo se ven todas")
	## Debajo de la losa, no encima.
	var bien := 0
	for v: Node in vigas:
		var mmi := v as MultiMeshInstance3D
		var t0 := mmi.multimesh.get_instance_transform(0)
		bien += 1 if t0.origin.y < 0.0 else 0
	_comprobar(bien == vigas.size(), "las vigas cuelgan bajo la losa")
	cam.queue_free()

func _fachada(raiz: Node3D) -> void:
	var f := raiz.get_node_or_null("Fachada")
	_comprobar(f != null, "hay fachada")
	if f == null:
		return
	var mi := f.get_node_or_null("FachadaEstructura") as MeshInstance3D
	var vidrio: StandardMaterial3D = null
	if mi != null:
		for s in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(s) as StandardMaterial3D
			if m != null and m.emission_texture != null:
				vidrio = m
	_comprobar(vidrio != null and vidrio.albedo_texture != null, "el vidrio de la fachada lleva despiece")
	if vidrio != null:
		var img := vidrio.albedo_texture.get_image()
		var c := img.get_pixel(48, 20) * vidrio.albedo_color
		_comprobar(c.get_luminance() > 0.15, "el vidrio ya no es un agujero negro (luminancia %.2f)" % c.get_luminance())

func _entorno(raiz: Node3D) -> void:
	var e := raiz.get_node_or_null("EntornoEstadio")
	_comprobar(e != null, "hay entorno")
	if e == null:
		return
	for nombre: String in ["Jardineras", "Setos", "Bolardos"]:
		var n := e.get_node_or_null(nombre) as MultiMeshInstance3D
		_comprobar(n != null and n.multimesh.instance_count > 8, "el entorno tiene %s" % nombre.to_lower())
	## Las jardineras no cortan ningún paseo: ninguna a menos de 4 m del eje de un paseo.
	var jard := _instancias(e, "Jardineras")
	var corta := 0
	for j: Transform3D in jard:
		if absf(j.origin.x) < 4.0 + 3.5 or absf(j.origin.z) < 4.0 + 3.5:
			corta += 1
	_comprobar(corta == 0, "las jardineras dejan libre la entrada central de cada lado")
