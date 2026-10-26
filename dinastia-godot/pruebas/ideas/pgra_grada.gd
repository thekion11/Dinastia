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
	var est := {"forma": "cuenco", "niveles": 2, "techo": "anillo", "aforo": 40000, "focos": "torres", "clima": "niebla"}
	StadiumBuilder.build(raiz, est, 40000, 0.8, 4242, club)
	_escaleras(raiz)
	_haces(raiz)
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

## Los peldaños de acceso tal como los pone `_escaleras_de_acceso` (rehecho aquí con su
## cuenta, independiente de `DetalleGrada`): [bajo, dir, n] por escalera.
func _escaleras_esperadas(raiz: Node3D) -> Array:
	var out: Array = []
	var y0 := StadiumBuilder.ALTURA_PIE + StadiumBuilder.subida_bandeja() / 2.0
	for n: Node in raiz.find_children("Pasillos", "MultiMeshInstance3D", true, false):
		var deck := n.get_parent() as MeshInstance3D
		if not (deck.mesh is BoxMesh) or deck.get_parent() != raiz or absf(deck.position.y - y0) > 0.1:
			continue
		var tam := (deck.mesh as BoxMesh).size
		var lateral := tam.x < tam.z
		var esc := DetalleGrada.escalones_de(deck, tam, lateral, deck.rotation.z if lateral else deck.rotation.x)
		## La fila 0 (la de abajo): los primeros de la lista.
		var largo := tam.z if lateral else tam.x
		var cuantas := maxi(1, int(largo / StadiumBuilder.PASO_BUTACA))
		for c in cuantas:
			if not StadiumBuilder.es_pasillo(c, cuantas):
				continue
			var l := -largo * 0.5 + 0.8 + c * StadiumBuilder.PASO_BUTACA
			for e: Transform3D in esc:
				if absf((e.origin.z if lateral else e.origin.x) - l) < 0.01:
					var bajo := deck.transform * e.origin
					if bajo.y >= 0.5:
						var dir := Vector3(-signf(bajo.x), 0, 0) if lateral else Vector3(0, 0, -signf(bajo.z))
						out.append([bajo, dir, int(ceil((bajo.y - 0.05) / StadiumBuilder.PELDANO_ALTO))])
					break
	return out

func _cuenta(raiz: Node, nombre: String) -> int:
	var t := 0
	for n: Node in raiz.find_children("*" + nombre + "*", "MultiMeshInstance3D", true, false):
		t += (n as MultiMeshInstance3D).multimesh.instance_count
	return t

## Los peldaños de acceso de TODAS las tribunas: cada una cuelga su MultiMesh de la
## raíz y, con el nombre repetido, Godot les pone uno automático; se reconocen por
## su material (el de los peldaños) y su malla de caja.
func _peldanos_acceso(raiz: Node) -> int:
	var t := 0
	var muestra := raiz.find_child("EscalerasAcceso", false, false) as MultiMeshInstance3D
	if muestra == null:
		return 0
	for n: Node in raiz.get_children():
		var m := n as MultiMeshInstance3D
		if m != null and m.material_override == muestra.material_override and m.multimesh.mesh is BoxMesh \
				and not String(m.name).contains("Acceso") or m == muestra:
			t += m.multimesh.instance_count
	return t

func _escaleras(raiz: Node3D) -> void:
	var esperadas := _escaleras_esperadas(raiz)
	var peldanos := 0
	for e: Array in esperadas:
		peldanos += int(e[2])
	_comprobar(esperadas.size() >= 4 and peldanos > 20, "hay escaleras de acceso (%d, %d peldaños)" % [esperadas.size(), peldanos])
	_comprobar(_peldanos_acceso(raiz) == peldanos, "la cuenta rehecha coincide con los peldaños que levanta la grada (%d / %d)" % [_peldanos_acceso(raiz), peldanos])
	_comprobar(_cuenta(raiz, "CantosAcceso") == peldanos, "un canto por peldaño de acceso (%d)" % _cuenta(raiz, "CantosAcceso"))
	_comprobar(_cuenta(raiz, "ZancasAcceso") == esperadas.size() * 2, "dos zancas por escalera (%d)" % _cuenta(raiz, "ZancasAcceso"))
	_comprobar(_cuenta(raiz, "PasamanosAcceso") == esperadas.size() * 8, "pasamanos y tres postes a cada lado")
	## Cada canto en la arista de delante y arriba de su peldaño (la del cajón de
	## `_escaleras_de_acceso`: centro bajo + dir·(0,45 + k·0,3), arriba en alto − 0,1).
	var malos := 0
	var hundidas := 0
	for e: Array in esperadas:
		var bajo: Vector3 = e[0]
		var dir: Vector3 = e[1]
		var piezas := DetalleGrada.piezas_escalera(bajo, dir, int(e[2]), StadiumBuilder.PELDANO_ALTO, StadiumBuilder.PELDANO_FONDO, 1.25)
		for k in int(e[2]):
			var alto := bajo.y - float(k) * StadiumBuilder.PELDANO_ALTO
			var arista := bajo + dir * (0.45 + float(k) * StadiumBuilder.PELDANO_FONDO + StadiumBuilder.PELDANO_FONDO * 0.5)
			arista.y = alto - 0.1
			var canto: Transform3D = piezas[0][k]
			if (canto.origin + dir * 0.035 + Vector3(0, 0.02, 0)).distance_to(arista) > 0.02:
				malos += 1
		for z: Transform3D in piezas[1]:
			if z.origin.y < 0.0 or z.origin.y > bajo.y + 0.5:
				hundidas += 1
	_comprobar(malos == 0, "cada canto está en la arista de su peldaño (%d fuera de sitio)" % malos)
	_comprobar(hundidas == 0, "las zancas van entre el suelo y la grada")
	_comprobar(_cuenta(raiz, "CantosPasillo") == _cuenta(raiz, "Pasillos") and _cuenta(raiz, "Pasillos") > 100,
		"un canto por peldaño de pasillo (%d / %d)" % [_cuenta(raiz, "CantosPasillo"), _cuenta(raiz, "Pasillos")])

## M-014: un haz por torre, del bastidor al césped al que apunta, encendido solo de noche.
func _haces(raiz: Node3D) -> void:
	StadiumBuilder.encender_conos(1.0)
	var haces: Array = []
	for n: Node in raiz.get_children():
		if n.is_in_group("foco_cono"):
			haces.append(n)
	_comprobar(haces.size() == 4, "un haz por torre de focos (%d)" % haces.size())
	var bien := 0
	for h: Node in haces:
		var mi := h as MeshInstance3D
		var arriba := mi.transform * Vector3(0, 0.5, 0)
		var abajo := mi.transform * Vector3(0, -0.5, 0)
		## Nace en lo alto de la torre (fuera del campo) y muere en el césped, más adentro.
		if arriba.y > 20.0 and absf(abajo.y) < 0.2 and Vector2(abajo.x, abajo.z).length() < Vector2(arriba.x, arriba.z).length() * 0.5:
			bien += 1
	_comprobar(bien == haces.size(), "cada haz va del foco al césped al que apunta (%d bien)" % bien)
	var mat := StadiumBuilder.mat_haz()
	_comprobar(float(mat.get_shader_parameter("fuerza")) > 0.0, "de noche los haces se encienden")
	_comprobar(haces.all(func(h: Node) -> bool: return (h as Node3D).visible), "y se dibujan")
	_comprobar(haces.size() > 0 and float((haces[0] as GeometryInstance3D).get_instance_shader_parameter("aire")) > 1.0, "con niebla el aire los enseña más")
	StadiumBuilder.encender_conos(0.0)
	_comprobar(float(mat.get_shader_parameter("fuerza")) == 0.0 and haces.all(func(h: Node) -> bool: return not (h as Node3D).visible),
		"de día se apagan y no se dibujan")

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
	## Debajo de la losa (0,5 m de canto, centrada en 0), no encima ni fuera de ella.
	var tam := Vector3(14.0, 0.5, 80.0)
	var piezas := DetalleGrada.piezas_vigas(tam, Vector3(-1, 0, 0), true)
	var mal := 0
	for x: Transform3D in piezas:
		var e := x.basis.get_scale()
		if x.origin.y + e.y * 0.5 > tam.y * 0.5 + 0.01 or x.origin.y - e.y * 0.5 > -tam.y * 0.5 or absf(x.origin.x) + e.x * 0.5 > tam.x * 0.5 + 0.01 or absf(x.origin.z) + e.z * 0.5 > tam.z * 0.5 + 0.01:
			mal += 1
	_comprobar(mal == 0 and piezas.size() > 10, "las vigas cuelgan bajo la losa y no se salen de ella (%d piezas, %d mal)" % [piezas.size(), mal])
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
	## Las jardineras no cortan ningún paseo: ninguna se cruza con la boca de uno.
	var px := 90.0
	var pz := 110.0
	var paseos := EntornoEstadioJardin.paseos_de(px, pz, px + 25.0, pz + 25.0)
	var jard: Array[Transform3D] = EntornoEstadioJardin.piezas_borde(px, pz, paseos)["macetas"]
	var corta := 0
	for j: Transform3D in jard:
		for pa: Array in paseos:
			var c: Vector3 = pa[0]
			var t: Vector2 = pa[1]
			## Media caja de la jardinera en el mundo (sus columnas, en valor absoluto).
			var b := j.basis
			var mitad := (absf(b.x.x) + absf(b.y.x) + absf(b.z.x)) * 0.5
			var mitad_z := (absf(b.x.z) + absf(b.y.z) + absf(b.z.z)) * 0.5
			if absf(j.origin.x - c.x) < t.x * 0.5 + mitad + 0.5 and absf(j.origin.z - c.z) < t.y * 0.5 + mitad_z + 0.5:
				corta += 1
	_comprobar(jard.size() > 20 and corta == 0, "las jardineras (%d) no tapan ningún paseo (%d lo tapan)" % [jard.size(), corta])
	_comprobar(paseos.size() == 12, "tres paseos por lado (%d)" % paseos.size())
