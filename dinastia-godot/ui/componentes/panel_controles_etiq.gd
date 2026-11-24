extends "res://ui/componentes/panel_controles_p1.gd"
## [Capa de etiquetas de `panel_controles.gd`] Las filas del mando y los nombres de sus botones (`_etiquetas_mando` en `panel_controles_p2.gd`).

## Las filas del manual (o, fuera de él, cada acción en su forma corta).
func _filas_etiquetas() -> Array:
	var filas: Array = []
	if _pestana.begins_with("p"):
		filas = (ControlFC.MANUAL[int(_pestana.substr(1))] as Array)[2]
	else:
		## Fuera del manual: lo de cada acción en su forma corta.
		for a: String in Mando.MAPA:
			if a in ["jugar_arriba", "jugar_abajo", "jugar_izquierda", "jugar_derecha"] or a.begins_with("jugar_fili_"):
				continue
			filas.append([_nombres_disp(String(Mando.MAPA[a][0])).get_slice(" · ", 0).get_slice(" (", 0), [a], ""])
	return filas

## Los botones de cada fila: su nombre, en el mapa de letras o de teclas.
func _etiquetas_de_filas(et: Dictionary, filas: Array) -> void:
	for f: Array in filas:
		var fichas: Array = f[1]
		var nombre := Idiomas.t(String(f[0])).get_slice(" (", 0).get_slice(" / ", 0)
		var ultima: String = fichas[fichas.size() - 1] if not fichas.is_empty() else ""
		if dispositivo == "teclado":
			var ff := ultima.trim_prefix("mant:").trim_prefix("2x:")
			if Mando.MAPA.has(ff):
				for k: int in Mando.teclas_de(ff):
					if not et.has(str(k)):
						et[str(k)] = nombre
			continue
		for pz: String in ControlFC.piezas_de(ultima):
			if pz != "" and not et.has(pz):
				et[pz] = nombre

## Los botones que no salen en la sección, con su papel general.
func _etiquetas_generales(et: Dictionary) -> void:
	if dispositivo == "teclado":
		for a: String in ["jugar_arriba", "jugar_izquierda", "jugar_abajo", "jugar_derecha"]:
			for k: int in Mando.teclas_de(a):
				if not et.has(str(k)):
					et[str(k)] = Idiomas.t("Moverse")
		for k2: int in [KEY_KP_8, KEY_KP_4, KEY_KP_6, KEY_KP_2]:
			if not et.has(str(k2)):
				et[str(k2)] = Idiomas.t("Filigranas")
	else:
		if not et.has("LS"):
			et["LS"] = Idiomas.t("Moverse")
		if not et.has("RS"):
			et["RS"] = Idiomas.t("Filigranas")

## Lo que falta del mapa del mando, con su nombre corto.
func _etiquetas_mapa(et: Dictionary) -> void:
	if dispositivo != "teclado":
		for a: String in Mando.MAPA:
			for pz: String in ControlFC.piezas_de(a):
				if pz != "" and not et.has(pz):
					et[pz] = _nombres_disp(Idiomas.t(String(Mando.MAPA[a][0]))).get_slice(" · ", 0).get_slice(" (", 0)

## Los sticks hacen dos cosas: moverse / filigranas y, al hundirlos, otra.
func _etiquetas_sticks(et: Dictionary) -> void:
	if dispositivo != "teclado":
		if not _pestana.begins_with("p") or not et.has("LS") or String(et["LS"]).begins_with("Pedir"):
			et["LS"] = Idiomas.t("Moverse · hundir: pedir")
		if not _pestana.begins_with("p") or not et.has("RS") or String(et["RS"]).begins_with("Autopase"):
			et["RS"] = Idiomas.t("Filigranas · hundir: sombrero")
