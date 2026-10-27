extends BaseIdea
## S8 · MUSEO INTERACTIVO (27-10-2026): E ante una vitrina abre el visor de la copa con su ficha.

func _probar() -> void:
	_titulo("S8 · VITRINAS DEL MUSEO: LA COPA EN PRIMER PLANO Y SU FICHA")
	SalasClub.vitrinas.clear()
	SalasClub.vitrinas.append({"p": Vector3(10, 4, 20), "k": 0})
	SalasClub.vitrinas.append({"p": Vector3(14, 4, 20), "k": 1})
	_comprobar(MuseoVitrinas.cercana(Vector3(10.5, 4, 20.4))["k"] == 0, "junto a la primera vitrina se la reconoce")
	_comprobar(MuseoVitrinas.cercana(Vector3(12, 4, 20)).is_empty(), "entre dos vitrinas (a 2 m de ambas) no hay ninguna")
	_comprobar(MuseoVitrinas.cercana(Vector3(10.5, 12, 20.4)).is_empty(), "en otra planta no cuenta")
	## La ficha: la vitrina k enseña el título k.
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	m.roles.sumar_trofeo("Liga", {"final": "Campeón de liga con X", "goleadores": ["A (10)", "B (7)"]})
	m.roles.sumar_trofeo("Mundial de Clubes")
	var f0 := MuseoVitrinas.ficha(0, m)
	_comprobar(String(f0["titulo"]) == "Liga" and String(f0["final"]) != "" and (f0["goleadores"] as Array).size() == 2, "la primera vitrina enseña la liga con su final y goleadores")
	var f1 := MuseoVitrinas.ficha(1, m)
	_comprobar(String(f1["titulo"]) == "Mundial de Clubes" and String(f1["final"]) == "", "un título sin datos guardados sale sin final (Sin datos en el visor)")
	_comprobar(bool(MuseoVitrinas.ficha(5, m)["vacia"]), "una vitrina sin título está libre")
	## El visor.
	var capa := CanvasLayer.new()
	add_child(capa)
	var v := VisorTrofeo.abrir(capa, f0)
	_comprobar(v is PanelContainer and v.is_inside_tree(), "el visor es un panel (encaja en el menú del explorador)")
	var txt := ""
	for l in v.find_children("*", "Label", true, false):
		txt += (l as Label).text + "|"
	_comprobar(txt.contains("Liga") and txt.contains("A (10), B (7)") and txt.contains(str(m.anio)), "muestra competición, año y goleadores")
	var sv := v.find_children("*", "SubViewport", true, false)
	_comprobar(sv.size() == 1 and (sv[0] as SubViewport).own_world_3d, "la copa va en su propio mundo 3D")
	var piv: Node3D = v._pivote
	var r0 := piv.rotation.y
	v._process(0.5)
	_comprobar(not is_equal_approx(piv.rotation.y, r0), "la copa gira sola")
	var vacio := VisorTrofeo.abrir(capa, MuseoVitrinas.ficha(5, m))
	var t2 := ""
	for l in vacio.find_children("*", "Label", true, false):
		t2 += (l as Label).text + "|"
	_comprobar(t2.contains("Vitrina libre"), "la vitrina libre lo dice")
	## Ficha de liga real: la genera `Roles`.
	var club := m.mi_club()
	for j in club.plantilla.slice(0, 3):
		j.goles = 9
	var fl: Dictionary = m.roles._ficha_liga()
	_comprobar((fl["goleadores"] as Array).size() == 3 and String(fl["final"]).contains(club.nombre), "el título de liga guarda los tres máximos goleadores del plantel")
