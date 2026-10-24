class_name Ciudad
extends "res://nucleo/ciudad_p1.gd"
## [Capa 2/2 de `ciudad.gd`] _resolver_sancion, semana, mes, a_dic, desde_dic

func _resolver_sancion() -> void:
	if sancion.is_empty():
		return
	sancion["semanas"] = int(sancion["semanas"]) - 1
	if int(sancion["semanas"]) > 0:
		return
	sancion = {}
	noticia.emit("Sanción cumplida", "El estadio vuelve a abrir con normalidad.")

# ---------------------------------------------------------------------------
#  EL PULSO
# ---------------------------------------------------------------------------

func semana(c: Club, animo: int) -> void:
	if c == null:
		return
	var ing := renta_negocios(c, animo)
	if ing > 0:
		c.mover_saldo(ing)
		movimiento.emit("Negocios del club (hotel, tienda, escuela…)", ing)
	var ahorro := ahorro_energetico(c)
	if ahorro > 0:
		c.mover_saldo(ahorro)
		movimiento.emit("Ahorro energético y beneficio tributario", ahorro)
	## El césped se recupera solo, despacio: tres puntos por semana. Un concierto
	## quita hasta 32, así que dos seguidos dejan el campo inservible durante un
	## mes largo, que es exactamente el freno que tiene que tener.
	cesped = clampi(cesped + 3, 0, 100)
	## Y la relación vecinal deriva con el ambiente del club.
	if Azar.suerte(0.4):
		vecinos = clampi(vecinos + (1 if animo > 70 else -1), 0, 100)
	_resolver_permiso()
	_resolver_sancion()

func mes() -> void:
	_gestion_hecha = false

func a_dic() -> Dictionary:
	return {
		"terrenos": terrenos.duplicate(), "negocios": negocios.duplicate(),
		"vecinos": vecinos, "cesped": cesped, "conciertos": conciertos,
		"paneles": paneles, "cert": certificado,
		"seg_p": seg_privada, "seg_c": seg_camaras,
		"permiso": permiso.duplicate(), "permiso_ok": permiso_ok,
		"sancion": sancion.duplicate(), "gestion": _gestion_hecha,
		"luces": luces,
	}

func desde_dic(d: Dictionary) -> void:
	terrenos = (d.get("terrenos", []) as Array).duplicate()
	negocios = (d.get("negocios", {}) as Dictionary).duplicate()
	vecinos = int(d.get("vecinos", 55))
	cesped = int(d.get("cesped", 100))
	conciertos = int(d.get("conciertos", 0))
	paneles = int(d.get("paneles", 0))
	certificado = bool(d.get("cert", false))
	seg_privada = int(d.get("seg_p", 0))
	seg_camaras = int(d.get("seg_c", 0))
	permiso = (d.get("permiso", {}) as Dictionary).duplicate()
	permiso_ok = bool(d.get("permiso_ok", false))
	sancion = (d.get("sancion", {}) as Dictionary).duplicate()
	_gestion_hecha = bool(d.get("gestion", false))
	luces = String(d.get("luces", LUCES_POR_DEFECTO))
