extends "res://nucleo/trabajadores_p1.gd"
## [Capa intermedia de `trabajadores.gd`, entre `trabajadores_p1.gd` y `trabajadores.gd`] `resolver` (el asunto de los trabajadores) y sus ramas (20-11, orden 63: partido en funciones por rama).
## Va aparte porque `resolver` y sus ramas están por encima de `trabajadores_p1.gd` (si no, pasarían de 450 líneas).

## Firma el asunto. Devuelve {titulo, cuerpo}.
func resolver(op: String, c: Club, obras: Instalaciones, prensa: Prensa) -> Dictionary:
	if pendiente.is_empty() or c == null:
		return {}
	var p := pendiente
	pendiente = {}
	var si := op == "a"
	var clave := String(p["inst"])
	var eq: Array = equipos.get(clave, [])
	var idx := int(p["idx"])
	if idx >= eq.size():
		return {}
	var out := {"titulo": "", "cuerpo": ""}
	match String(p["id"]):
		"aumento":
			out = _trab_aumento(c, clave, eq, idx, prensa, si)
		"rival":
			out = _trab_rival(c, clave, eq, idx, prensa, si)
		"curso":
			out = _trab_curso(c, clave, eq, idx, prensa, si)
		"error":
			out = _trab_error(c, clave, eq, idx, prensa, si)
		"idea":
			out = _trab_idea(c, clave, eq, idx, prensa, si)
		"averia":
			out = _trab_averia(c, clave, eq, idx, prensa, si)
		"homenaje":
			out = _trab_homenaje(c, clave, eq, idx, prensa, si)
	if obras != null:
		obras.factor_personal[clave] = factor(clave)
	return out

## Rama «aumento» de `resolver` (trabajadores), sacada tal cual (orden 63).
func _trab_aumento(c: Club, clave: String, eq: Array, idx: int, prensa: Prensa, si: bool) -> Dictionary:
	var t: Dictionary = eq[idx]
	var nombre := String(t["nombre"])
	var rep := float(c.rep)
	var out := {"titulo": "", "cuerpo": ""}
	if si:
		_gastar(c, Eco.escalar(40000.0, rep), "Aumento para %s" % nombre)
		t["moral"] = mini(99, int(t["moral"]) + 25)
		t["sueldo_sube"] = int(t["semanas"])
		out = {"titulo": "Aumento concedido", "cuerpo": "%s sigue con más ganas que nunca." % nombre}
	else:
		t["moral"] = maxi(10, int(t["moral"]) - 20)
		if String(t["caracter"]) == "conflictivo":
			eq[idx] = _reemplazo(c, clave, idx, t)
			out = {"titulo": "%s se va" % nombre, "cuerpo": "Se despidió dando un portazo. Llega %s, con menos experiencia." % String(eq[idx]["nombre"])}
		else:
			out = {"titulo": "Sin aumento", "cuerpo": "%s lo acepta, pero se nota el malestar." % nombre}
	return out

## Rama «rival» de `resolver` (trabajadores), sacada tal cual (orden 63).
func _trab_rival(c: Club, clave: String, eq: Array, idx: int, prensa: Prensa, si: bool) -> Dictionary:
	var t: Dictionary = eq[idx]
	var nombre := String(t["nombre"])
	var rep := float(c.rep)
	var out := {"titulo": "", "cuerpo": ""}
	if si:
		_gastar(c, Eco.escalar(60000.0, rep), "Retener a %s" % nombre)
		t["moral"] = mini(99, int(t["moral"]) + 15)
		t["sueldo_sube"] = int(t["semanas"])
		out = {"titulo": "%s se queda" % nombre, "cuerpo": "El club igualó la oferta. Mensaje claro al resto del personal."}
	else:
		eq[idx] = _reemplazo(c, clave, idx, t)
		out = {"titulo": "%s se marcha" % nombre, "cuerpo": "Se va al rival. %s ocupa su puesto." % String(eq[idx]["nombre"])}
	return out

## Rama «curso» de `resolver` (trabajadores), sacada tal cual (orden 63).
func _trab_curso(c: Club, clave: String, eq: Array, idx: int, prensa: Prensa, si: bool) -> Dictionary:
	var t: Dictionary = eq[idx]
	var nombre := String(t["nombre"])
	var rep := float(c.rep)
	var out := {"titulo": "", "cuerpo": ""}
	if si:
		_gastar(c, Eco.escalar(25000.0, rep), "Formación de %s" % nombre)
		t["hab"] = mini(99, int(t["hab"]) + 8)
		t["moral"] = mini(99, int(t["moral"]) + 10)
		out = {"titulo": "Vuelve con ideas nuevas", "cuerpo": "%s aprendió mucho: la instalación lo nota." % nombre}
	else:
		t["moral"] = maxi(10, int(t["moral"]) - 8)
		out = {"titulo": "Curso aplazado", "cuerpo": "%s lo entiende, aunque le hacía ilusión." % nombre}
	return out

## Rama «error» de `resolver` (trabajadores), sacada tal cual (orden 63).
func _trab_error(c: Club, clave: String, eq: Array, idx: int, prensa: Prensa, si: bool) -> Dictionary:
	var t: Dictionary = eq[idx]
	var nombre := String(t["nombre"])
	var rep := float(c.rep)
	var out := {"titulo": "", "cuerpo": ""}
	if si:
		eq[idx] = _reemplazo(c, clave, idx, t)
		for o: Dictionary in eq:
			o["moral"] = maxi(10, int(o["moral"]) - 5)
		if prensa != null:
			prensa.mover_animo(1)
		out = {"titulo": "Despedido", "cuerpo": "%s deja el club. El resto del personal toma nota. Entra %s." % [nombre, String(eq[idx]["nombre"])]}
	else:
		t["moral"] = mini(99, int(t["moral"]) + 12)
		t["hab"] = mini(99, int(t["hab"]) + 2)
		if prensa != null:
			prensa.mover_animo(-1)
		out = {"titulo": "Segunda oportunidad", "cuerpo": "%s promete que no volverá a pasar. La prensa lo critica un poco." % nombre}
	return out

## Rama «idea» de `resolver` (trabajadores), sacada tal cual (orden 63).
func _trab_idea(c: Club, clave: String, eq: Array, idx: int, prensa: Prensa, si: bool) -> Dictionary:
	var t: Dictionary = eq[idx]
	var nombre := String(t["nombre"])
	var rep := float(c.rep)
	var out := {"titulo": "", "cuerpo": ""}
	if si:
		_gastar(c, Eco.escalar(50000.0, rep), "Idea de %s" % nombre)
		t["hab"] = mini(99, int(t["hab"]) + 4)
		t["moral"] = mini(99, int(t["moral"]) + 15)
		for j: Jugador in c.plantilla:
			j.forma = clampi(j.forma + 2, 10, 99)
		c.socios += 150
		out = {"titulo": "La idea funciona", "cuerpo": "La propuesta de %s ya está en marcha: el plantel y los socios lo notan." % nombre}
	else:
		t["moral"] = maxi(10, int(t["moral"]) - 6)
		out = {"titulo": "Idea en el cajón", "cuerpo": "%s guarda su propuesta para más adelante." % nombre}
	return out

## Rama «averia» de `resolver` (trabajadores), sacada tal cual (orden 63).
func _trab_averia(c: Club, clave: String, eq: Array, idx: int, prensa: Prensa, si: bool) -> Dictionary:
	var t: Dictionary = eq[idx]
	var nombre := String(t["nombre"])
	var rep := float(c.rep)
	var out := {"titulo": "", "cuerpo": ""}
	if si:
		_gastar(c, Eco.escalar(45000.0, rep), "Reparación en %s" % String(Instalaciones.CATALOGO[clave][0]))
		out = {"titulo": "Arreglado", "cuerpo": "Técnicos toda la semana: %s funciona como nuevo." % String(AVERIAS.get(clave, "todo"))}
	else:
		_gastar(c, Eco.escalar(8000.0, rep), "Parche en %s" % String(Instalaciones.CATALOGO[clave][0]))
		averias[clave] = 6
		out = {"titulo": "Parche provisional", "cuerpo": "Funciona a medias: la instalación rinde menos durante seis semanas."}
	return out

## Rama «homenaje» de `resolver` (trabajadores), sacada tal cual (orden 63).
func _trab_homenaje(c: Club, clave: String, eq: Array, idx: int, prensa: Prensa, si: bool) -> Dictionary:
	var t: Dictionary = eq[idx]
	var nombre := String(t["nombre"])
	var rep := float(c.rep)
	var out := {"titulo": "", "cuerpo": ""}
	if si:
		_gastar(c, Eco.escalar(15000.0, rep), "Homenaje a %s" % nombre)
		if prensa != null:
			prensa.mover_animo(2)
		t["moral"] = 99
		out = {"titulo": "Homenaje en el estadio", "cuerpo": "El estadio entero aplaudió a %s. Muchos no sabían quién era; ahora sí." % nombre}
	else:
		t["moral"] = mini(99, int(t["moral"]) + 15)
		for j: Jugador in c.plantilla:
			j.cambiar_moral(1, "Cuerpo técnico")
		out = {"titulo": "Homenaje en el vestuario", "cuerpo": "Tarta, camiseta firmada y abrazos para %s." % nombre}
	return out
