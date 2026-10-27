class_name MuseoVitrinas
extends RefCounted
## LAS VITRINAS DEL MUSEO SE PUEDEN MIRAR (27-10-2026, orden del dueño): con E ante una vitrina con copa se abre `VisorTrofeo`: la copa en primer
## plano, que se gira con el ratón o con A/D, y su ficha (competición, año, final y goleadores). La vitrina número k enseña el título número k
## del club (`Roles.trofeos`, por orden de conquista). `SalasClub.museo()` apunta dónde está cada vitrina (`SalasClub.vitrinas`).

const RADIO := 1.5

## La vitrina a menos de `RADIO` m (en el plano) de `loc` (posición dentro del estadio) y a la altura del suelo de la sala: {p, k} o {}.
static func cercana(loc: Vector3) -> Dictionary:
	for v: Dictionary in SalasClub.vitrinas:
		var p: Vector3 = v["p"]
		if Vector2(p.x - loc.x, p.z - loc.z).length() < RADIO and absf(p.y - loc.y) < 1.5:
			return v
	return {}

## La ficha del título k: {titulo, anio, final, goleadores, vacia}. Sin título para esa vitrina, `vacia`.
static func ficha(k: int, mundo: Object) -> Dictionary:
	var lista: Array = []
	if mundo != null and mundo.get("roles") != null:
		lista = (mundo.get("roles") as Object).get("trofeos")
	if k < 0 or k >= lista.size():
		return {"vacia": true, "titulo": Idiomas.t("Vitrina libre")}
	var t: Dictionary = lista[k]
	return {"vacia": false, "titulo": String(t.get("titulo", "")), "anio": int(t.get("anio", 0)),
		"final": String(t.get("final", "")), "goleadores": t.get("goleadores", [])}

## E ante una vitrina: abre el visor. true si se abrió.
static func usar(e: Object, loc: Vector3) -> bool:
	var v := cercana(loc)
	if v.is_empty():
		return false
	var abierto: Variant = e.get("_menu_asc")
	if abierto != null and is_instance_valid(abierto):
		return true
	var vida: Object = e.get("vida")
	var visor := VisorTrofeo.abrir(e.get("_capa"), ficha(int(v["k"]), vida.get("mundo") if vida != null else null))
	e.set("_menu_asc", visor)
	return true
