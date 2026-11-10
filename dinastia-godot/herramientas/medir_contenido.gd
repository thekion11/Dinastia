extends Node
## CIFRAS DE CONTENIDO DEL MUNDO GENERADO (10-11-2026, informes AUDITORIA_CONTENIDO y COMPARATIVA_PES2020): genera el mundo completo y MIDE (países, ligas, clubes, jugadores,
## selecciones, torneos, estadios, escudos, uniformes). Escribe el JSON en el argumento `--salida=ruta` (o lo imprime). Uso:
##   godot --headless --path dinastia-godot res://herramientas/medir_contenido.tscn -- --salida=/ruta/cifras.json
## No cambia ningún dato; solo lee. Con el pack real presente (pack_real.json) mide el mundo real, si no, el público.

func _ready() -> void:
	var salida := ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--salida="):
			salida = a.trim_prefix("--salida=")
	var m := Mundo.new()
	m.generar([] as Array[String], 7)
	var r := {}
	var paises := {}
	var ligas_por_div := {}
	var clubes_por_div := {}
	var clubes_por_pais := {}
	var ligas_info: Array = []
	for l: Liga in m.ligas:
		paises[l.pais] = true
		ligas_por_div[l.division()] = int(ligas_por_div.get(l.division(), 0)) + 1
		clubes_por_div[l.division()] = int(clubes_por_div.get(l.division(), 0)) + l.clubes.size()
		var cp: Dictionary = clubes_por_pais.get(l.pais, {})
		cp[l.division()] = int(cp.get(l.division(), 0)) + l.clubes.size()
		clubes_por_pais[l.pais] = cp
		ligas_info.append([l.pais, l.division(), l.clubes.size()])
	r["paises_con_liga"] = paises.size()
	r["paises"] = paises.keys()
	r["ligas"] = m.ligas.size()
	r["ligas_por_division"] = ligas_por_div
	r["clubes"] = m.clubes.size()
	r["clubes_por_division"] = clubes_por_div
	r["clubes_por_pais"] = clubes_por_pais
	r["ligas_detalle"] = ligas_info
	## Jugadores
	var jug := 0
	var libres := 0
	var por_pos := {}
	var nac := {}
	var ovr_suma := 0
	for c: Club in m.clubes.values():
		for j: Jugador in c.plantilla:
			jug += 1
			por_pos[j.pos] = int(por_pos.get(j.pos, 0)) + 1
			nac[j.pais] = true
			ovr_suma += j.ovr
	r["jugadores_en_clubes"] = jug
	r["jugadores_por_posicion"] = por_pos
	r["nacionalidades_de_jugadores"] = nac.size()
	r["ovr_medio"] = snappedf(float(ovr_suma) / maxf(1.0, float(jug)), 0.1)
	r["libres_en_mercado"] = m.mercado.libres.size() if "libres" in m.mercado else -1
	## Aspecto, estadio, historia (por club generado)
	var con_estadio_row := 0
	var con_historia := 0
	var con_asientos := 0
	var con_visita := 0
	var estadio_firmas := {}
	var aforo_suma := 0
	var aforo_max := 0
	var aforo_max_club := ""
	var asp: Dictionary = Datos.tabla("ASPECTO_CLUB") as Dictionary
	var est: Dictionary = Datos.tabla("ESTADIO_CLUB") as Dictionary
	var his: Dictionary = Datos.tabla("HISTORIA_CLUBES") as Dictionary
	var firmas_nombre := {}
	for c: Club in m.clubes.values():
		aforo_suma += c.estadio_aforo
		if c.estadio_aforo > aforo_max:
			aforo_max = c.estadio_aforo
			aforo_max_club = c.nombre
		var clave := c.nombre
		firmas_nombre[clave] = true
	for nombre: String in est:
		con_estadio_row += 1
		var f: Dictionary = est[nombre]
		estadio_firmas["%s|%s|%s|%s|%s" % [f.get("forma", ""), f.get("niveles", ""), f.get("techo", ""), f.get("focos", ""), f.get("fachada", "")]] = true
	var esc_fig := 0
	var kit_prop := 0
	var kit_firma := {}
	var esc_todo := {}
	for nombre: String in asp:
		var a: Dictionary = asp[nombre]
		if a.has("asientos"):
			con_asientos += 1
		if a.has("visita"):
			con_visita += 1
		if a.has("escudo") and a.has("esc"):
			var e: Array = a["escudo"]
			var ec: Array = a["esc"]
			esc_todo["%s|%s|%s|%s|%s" % [e[0], e[1], ec[0], ec[1], a.get("letras", "")]] = true
			if String(e[1]) != "liso" or String(a.get("letras", "")) != "":
				esc_fig += 1
		if a.has("kit"):
			var k: Dictionary = a["kit"]
			kit_prop += 1
			kit_firma["%s|%s|%s|%s|%s" % [a.get("camiseta", ""), k.get("c1", ""), k.get("c2", ""), k.get("pant", ""), k.get("med", "")]] = true
	r["escudos_con_patron_o_letras"] = esc_fig
	r["escudos_firmas_distintas_en_aspecto"] = esc_todo.size()
	r["uniformes_con_kit_propio"] = kit_prop
	r["uniformes_firmas_distintas_en_aspecto"] = kit_firma.size()
	for nombre: String in his:
		con_historia += 1
	r["filas_ASPECTO_CLUB"] = asp.size()
	r["filas_con_asientos"] = con_asientos
	r["filas_con_uniforme_visitante"] = con_visita
	r["filas_ESTADIO_CLUB"] = con_estadio_row
	r["perfiles_de_estadio_distintos"] = estadio_firmas.size()
	r["filas_HISTORIA_CLUBES"] = con_historia
	r["aforo_total"] = aforo_suma
	r["aforo_medio"] = int(float(aforo_suma) / maxf(1.0, float(m.clubes.size())))
	r["aforo_maximo"] = [aforo_max_club, aforo_max]
	## Selecciones y torneos
	var sel: Array = Datos.tabla("SELECCIONES") as Array
	r["selecciones"] = sel.size()
	var por_conf := {}
	var en_alguna := {}
	for k: String in SeleccionesTorneos.POR_CONFED:
		por_conf[k] = (SeleccionesTorneos.POR_CONFED[k] as Array).size()
		for s: String in SeleccionesTorneos.POR_CONFED[k]:
			en_alguna[s] = true
	r["selecciones_por_confederacion"] = por_conf
	var sin_torneo: Array = []
	for s: String in sel:
		if not en_alguna.has(s):
			sin_torneo.append(s)
	r["selecciones_sin_torneo_continental"] = sin_torneo
	r["selecciones_suspendidas"] = SeleccionesTorneos.SUSPENDIDAS
	r["plazas_mundial_48"] = SeleccionesTorneos.PLAZAS_MUNDIAL_48
	r["torneos_continentales_de_clubes"] = Continental.PRINCIPALES
	r["torneos_fifa"] = ["mundial", "interc"]
	r["copas_nacionales_nombres"] = (Datos.tabla("COPA_NOM") as Dictionary).size()
	r["paises_con_fase_final_de_liga"] = FaseFinalLiga.PAISES.keys()
	r["confederaciones_clubes"] = (Datos.tabla("CONFED") as Dictionary).keys()
	r["paises_con_reglas_de_ascenso"] = ReglasAscenso.tiene("CHI")
	var bib: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://datos/biblioteca_caras.json"))
	r["caras_en_biblioteca"] = (bib as Dictionary).size() if bib is Dictionary else -1
	r["caras_reales_pck_presente"] = FileAccess.file_exists("res://caras_reales.pck") or FileAccess.file_exists(OS.get_executable_path().get_base_dir().path_join("caras_reales.pck"))
	r["idiomas"] = Idiomas.IDIOMAS.size() if "IDIOMAS" in Idiomas else -1
	var txt := JSON.stringify(r, "  ")
	if salida != "":
		var f := FileAccess.open(salida, FileAccess.WRITE)
		f.store_string(txt)
		f.close()
		print("MEDIDO: ", salida)
	else:
		print(txt)
	get_tree().quit(0)
