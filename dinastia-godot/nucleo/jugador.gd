class_name Jugador
extends "res://nucleo/jugador_p1.gd"
## (Parte 2 de 2 de `jugador.gd`.)

## Reconversion permanente -reconvertir() del HTML-: cambia de puesto para
## siempre, recalcula la media EN el puesto nuevo (con una penalizacion de 1-3
## puntos si la aptitud no supera 0.9, igual que el original) y deja unas
## semanas de adaptacion. Vacio si el puesto no existe, ya es el suyo, o cruza
## la frontera portero/jugador de campo -esa reconversion no existe ni en el
## HTML-. Devuelve el antes/despues para el aviso de la interfaz.
func reconvertir(pe: String) -> Dictionary:
	var posd: Variant = Datos.tabla("POSD")
	if pe == pos_e or not (posd is Dictionary) or not (posd as Dictionary).has(pe):
		return {}
	var tabla: Dictionary = posd as Dictionary
	var d: Dictionary = tabla[pe]
	var n: Dictionary = tabla.get(pos_e, {})
	if (String(d.get("g", "")) == "POR") != (String(n.get("g", "")) == "POR"):
		return {}
	var antes := ovr
	if not pos_sec.has(pos_e):
		pos_sec.append(pos_e)
		if pos_sec.size() > 2:
			pos_sec.remove_at(0)
	var apt := aptitud_en(pe)
	pos_e = pe
	pos = String(d.get("g", pos))
	pos_sec.erase(pe)
	ovr = clampi(ovr_en_puesto(pe) - (0 if apt > 0.9 else Azar.ent(1, 3)), 20, 97)
	adapt = Azar.ent(3, 8)
	tasar()
	return {"antes": antes, "despues": ovr, "semanas": adapt}
