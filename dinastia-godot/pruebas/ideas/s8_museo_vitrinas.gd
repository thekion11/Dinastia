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
	## La planta 3: las vitrinas del museo ampliado también se pueden mirar, y siguen el mismo orden de hitos.
	MuseoAmpliado.vitrinas.clear()
	MuseoAmpliado.vitrinas.append({"p": Vector3(30, 8, 40), "k": SalasClub.MAX_SALA})
	_comprobar(MuseoVitrinas.cercana(Vector3(30.2, 8, 40.1))["k"] == SalasClub.MAX_SALA, "las vitrinas de la planta 3 se reconocen")
	var m2 := Mundo.new()
	m2.generar(["CHI"], 4711)
	for i in 8:
		m2.anio = 2030 + (7 - i)   ## títulos conquistados en orden inverso: la lista de hitos los ordena por año
		m2.roles.sumar_trofeo("Título %d" % i)
	var h := MuseoVitrinas.hitos(m2)
	_comprobar(h.size() == 8 and int(h[0]["anio"]) < int(h[7]["anio"]), "los hitos salen por orden de año (%d..%d)" % [int(h[0]["anio"]), int(h[7]["anio"])])
	_comprobar(String(MuseoVitrinas.ficha(SalasClub.MAX_SALA, m2)["titulo"]) == String(h[SalasClub.MAX_SALA]["titulo"]), "la primera vitrina de la planta 3 enseña el hito 7")
	## La Copa también suma trofeo (decisión del dueño).
	var antes := m2.roles.trofeos.size()
	var copa := Copa.new("Copa Test")
	m2.copa = copa
	var mi: Club = m2.ligas[0].clubes[0]
	copa.campeon = mi
	copa.historial.append({"ronda": "Final", "resultados": [{"local": mi, "visita": m2.ligas[0].clubes[1], "gl": 2, "gv": 1, "penales": [], "pasa": mi, "ronda": "Final"}]})
	_comprobar(m2._final_de_copa(copa).contains("2-1"), "la final de la copa se escribe en una línea (%s)" % m2._final_de_copa(copa))
	_comprobar(antes == 8, "(sin la copa aún hay 8 títulos)")

