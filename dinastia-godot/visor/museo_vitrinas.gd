class_name MuseoVitrinas
extends RefCounted
## LAS VITRINAS DEL MUSEO SE PUEDEN MIRAR (27-10-2026, orden del dueño): con E ante una vitrina con copa se abre `VisorTrofeo`: la copa en primer
## plano, que se gira con el ratón o con A/D, y su ficha (competición, año, final y goleadores). La vitrina número k enseña el hito número k
## del club por orden de año (`hitos()`: los títulos de `Roles.trofeos` y los de las ramas), igual que las de la planta 3 (`MuseoAmpliado`). `SalasClub.museo()` apunta dónde está cada vitrina (`SalasClub.vitrinas`).

const RADIO := 1.5

## La vitrina a menos de `RADIO` m (en el plano) de `loc` (posición dentro del estadio) y a la altura del suelo de la sala: {p, k} o {}.
static func cercana(loc: Vector3) -> Dictionary:
	for v: Dictionary in SalasClub.vitrinas + MuseoAmpliado.vitrinas:
		var p: Vector3 = v["p"]
		if Vector2(p.x - loc.x, p.z - loc.z).length() < RADIO and absf(p.y - loc.y) < 1.5:
			return v
	return {}

## Los hitos del club por orden de año (la lista con la que se llenan las vitrinas de la planta 2 y de la 3): los títulos de `Roles.trofeos`
## con su ficha y los de las ramas de otros deportes. [{anio, titulo, final, goleadores}]
static func hitos(mundo: Object) -> Array:
	var sal: Array = []
	if mundo == null:
		return sal
	## Primero el palmarés real del club (el mismo orden que `EdificioClub.contexto_de`).
	if mundo.has_method("mi_club"):
		sal.append_array(HistoriaClub.hitos_palmares(mundo.call("mi_club")))
	var roles: Object = mundo.get("roles")
	if roles != null:
		for t: Dictionary in roles.get("trofeos"):
			sal.append(t.duplicate())
	var hinchada: Object = mundo.get("hinchada")
	if hinchada != null:
		for rr: Dictionary in hinchada.get("palmares_ramas"):
			if int(rr.get("puesto", 9)) == 1:
				sal.append({"anio": int(rr.get("anio", 0)), "titulo": String(rr.get("rama", ""))})
	for i in sal.size():
		(sal[i] as Dictionary)["_i"] = i
	sal.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("anio", 0)) < int(b.get("anio", 0)) or (int(a.get("anio", 0)) == int(b.get("anio", 0)) and int(a["_i"]) < int(b["_i"])))
	return sal

## La ficha del hito k (el mismo orden que las vitrinas): {titulo, anio, final, goleadores, vacia}. Sin título para esa vitrina, `vacia`.
static func ficha(k: int, mundo: Object) -> Dictionary:
	var lista := hitos(mundo)
	if k < 0 or k >= lista.size():
		return {"vacia": true, "titulo": Idiomas.t("Vitrina libre")}
	var t: Dictionary = lista[k]
	var club: Variant = mundo.call("mi_club") if mundo.has_method("mi_club") else null
	return {"vacia": false, "titulo": String(t.get("titulo", "")), "anio": int(t.get("anio", 0)),
		"final": String(t.get("final", "")), "goleadores": t.get("goleadores", []), "anios": t.get("anios", []), "cantidad": int(t.get("cantidad", 1)),
		"receta": TrofeosReales.para_titulo(String(t.get("titulo", "")), String(club.get("pais")) if club != null else "")}

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
