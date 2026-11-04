extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), orden del dueño: la grada del estadio propio SIGUE CRECIENDO con el aforo por encima de ~30 000, SOLO en calidad ALTA.
##   · MEDIO: igual que siempre (las butacas visibles se quedan en el mismo número de 34 000 a 76 500).
##   · ALTO: más butacas y más niveles a 34 000, 55 250 y 76 500 (crece con el aforo); se miden nodos e instancias antes/después.
func _contar(raiz: Node3D) -> Dictionary:
	var vis := 0
	var inst := 0
	for g in raiz.find_children("*", "MultiMeshInstance3D", true, false):
		var mm := (g as MultiMeshInstance3D).multimesh
		inst += mm.instance_count
		if String(g.name).begins_with("Butacas"):
			for q in mm.instance_count:
				if mm.get_instance_color(q).a > 0.5 and mm.get_instance_transform(q).basis.get_scale().y > 0.01:
					vis += 1
	return {"butacas": vis, "instancias": inst, "nodos": raiz.find_children("*", "Node", true, false).size()}

func _probar() -> void:
	_titulo("A4 MUNDO_3D: la grada crece con el aforo por encima de 30 000 solo en calidad ALTA")
	if DisplayServer.get_name() == "headless":
		_comprobar(false, "esta prueba necesita pantalla (xvfb + OpenGL)")
		return
	Partido.limpiar_contexto()
	var m := Mundo.new()
	var paises: Array[String] = ["CHI"]
	m.generar(paises, 321)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var club := m.mi_club()
	club.saldo = 2000000000
	var res := {}
	var antes := Calidad.elegida
	for calidad in [Calidad.MEDIO, Calidad.ALTO]:
		Calidad.elegida = calidad
		for aforo in [20000, 34000, 55250, 76500]:
			club.estadio_aforo = aforo
			var perfil: Dictionary = m.perfil_estadio_de(club)
			Azar.sembrar(4242)
			var v := VistaEstadio.new()
			add_child(v)
			await v.abrir(club, 0.5, null, null, perfil)
			for k in 8:
				await get_tree().process_frame
			var r := _contar(v.get("_raiz3d"))
			res["%d/%d" % [calidad, aforo]] = r
			print("  (info) calidad %d, aforo %d: niveles %d, %s" % [calidad, aforo, StadiumBuilder.niveles_de(perfil, aforo), str(r)])
			v.free()
	Calidad.elegida = antes
	var med34: int = res["%d/34000" % Calidad.MEDIO]["butacas"]
	var med76: int = res["%d/76500" % Calidad.MEDIO]["butacas"]
	var alt20: int = res["%d/20000" % Calidad.ALTO]["butacas"]
	var alt34: int = res["%d/34000" % Calidad.ALTO]["butacas"]
	var alt55: int = res["%d/55250" % Calidad.ALTO]["butacas"]
	var alt76: int = res["%d/76500" % Calidad.ALTO]["butacas"]
	_comprobar(med34 == med76, "MEDIO: sin cambios, 34 000 y 76 500 dan las mismas butacas (%d y %d)" % [med34, med76])
	_comprobar(res["%d/20000" % Calidad.MEDIO]["butacas"] == res["%d/20000" % Calidad.MEDIO]["butacas"] and int(res["%d/34000" % Calidad.MEDIO]["instancias"]) == int(res["%d/76500" % Calidad.MEDIO]["instancias"]), "MEDIO: las instancias tampoco cambian por encima de 30 000")
	_comprobar(alt34 > alt20 and alt55 > alt34 and alt76 > alt55, "ALTO: la grada crece con el aforo (%d → %d → %d → %d butacas)" % [alt20, alt34, alt55, alt76])
	_comprobar(int(res["%d/76500" % Calidad.ALTO]["nodos"]) < 20000, "ALTO: el árbol sigue siendo razonable a 76 500 (%d nodos)" % int(res["%d/76500" % Calidad.ALTO]["nodos"]))
