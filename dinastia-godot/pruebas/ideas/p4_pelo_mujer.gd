extends BaseIdea
## P4 · PELO (27-10-2026): el corte rapado de una mujer usa la malla `Hair_BuzzedFemale` del pack (antes sin usar); el de un hombre sigue con `Hair_Buzzed`.

func _probar() -> void:
	_titulo("P4 · CORTE RAPADO FEMENINO CON SU PROPIA MALLA")
	var raiz := Node3D.new()
	add_child(raiz)
	var m := FutbolistaQ.crear(1.8, "male")
	raiz.add_child(m["nodo"])
	FutbolistaQ.terminar(m, false)
	var f := FutbolistaQ.crear(1.65, "female")
	raiz.add_child(f["nodo"])
	FutbolistaQ.terminar(f, false)
	var pm := PeloQ.poner(m, "corto", Color("#3a2a1c"), false)
	var pf := PeloQ.poner(f, "corto", Color("#3a2a1c"), false)
	_comprobar(pm != null and pm.find_child("Hair_Buzzed", true, false) != null and pm.find_child("Hair_BuzzedFemale", true, false) == null, "en un hombre sigue la malla de siempre")
	_comprobar(pf != null and pf.find_child("Hair_BuzzedFemale", true, false) != null and pf.find_child("Hair_Buzzed", true, false) == null, "en una mujer va la malla femenina")
	var pl := PeloQ.poner(f, "largo", Color("#3a2a1c"), false)
	_comprobar(pl != null and pl.find_child("Hair_Long", true, false) != null, "el pelo largo no cambia")
