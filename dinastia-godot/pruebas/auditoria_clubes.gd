extends Node
## AUDITORÍA POR CLUB (14-10-2026, pedido: «compara qué se respeta con cada club de
## todo el juego: estadio, escudo, patrocinadores, camiseta y jugadores»).
## Recorre TODOS los clubes de la base ficticia y de la base real y mide, por club:
##   · estadio: ¿arquitectura del real? ¿colores propios de butacas? ¿forma/techo?
##   · escudo: forma y patrón propios, ¿colores del escudo = colores del club?
##   · camiseta: ¿foto real de equipación? ¿diseño propio del club? ¿colores = club?
##   · patrocinadores: zonas vendidas, marcas, ¿vienen de un dato del club real?
##   · jugadores: plantel, ¿con plantilla real fija?, ¿con retrato real?
## Salida: AUDITORIA_CLUBES.md (resumen) y AUDITORIA_CLUBES.csv (una fila por club).
##   godot --headless --path . res://pruebas/auditoria_clubes.tscn

func _ready() -> void:
	var md := "# AUDITORÍA POR CLUB (14-10-2026)\n\nGenerada por `pruebas/auditoria_clubes.gd`. Cada fila del CSV es un club.\n\n"
	var csv := "base,club,pais,rep,estadio_real,estadio_forma,estadio_colores_propios,escudo_forma,escudo_patron,escudo_colores_club,camiseta_foto_real,camiseta_diseno,sponsor_zonas,sponsor_marcas,sponsor_dato_real,plantel,plantilla_real_fija,jugadores_con_retrato\n"
	for real in [false, true]:
		if real and not Datos.hay_pack_real():
			md += "## Base real\n\nNo hay pack real en este entorno (`datos/pack_real.json` ausente).\n\n"
			continue
		Datos.usar_base_real(real)
		var base := "real" if real else "ficticia"
		var m := Mundo.new()
		m.generar([], 4711)
		var n := 0
		var c_est_real := 0
		var c_est_col := 0
		var c_esc_ok := 0
		var c_esc_real := 0
		var c_kit_foto := 0
		var c_kit_dis := 0
		var c_sp := 0
		var c_sp_real := 0
		var c_plantel_real := 0
		var jug_total := 0
		var jug_retrato := 0
		var sin_est: Array[String] = []
		for c: Club in m.clubes.values():
			n += 1
			var p := c.perfil_estadio()
			var est_real: bool = bool(p.get("real", false))
			var est_col: bool = est_real and Datos.tabla("ESTADIO_CLUB").has(c.nombre) and (Datos.tabla("ESTADIO_CLUB")[c.nombre] as Dictionary).has("asientos")
			if est_real:
				c_est_real += 1
			else:
				sin_est.append(c.nombre)
			if est_col:
				c_est_col += 1
			var esc_ok: bool = c.color_escudo1() == c.color1 or c.color_escudo2() == c.color1 or c.color_escudo1() == c.color2
			if esc_ok:
				c_esc_ok += 1
			if not Escudo._rasgo_real(c).is_empty():
				c_esc_real += 1
			var foto: bool = Jersey.fichero_real(c) != ""
			if foto:
				c_kit_foto += 1
			var kx := DisenosKit.kit_de_club(c)
			var dis := String(kx.get("dis", ""))
			if dis != "" and dis != "liso":
				c_kit_dis += 1
			var sp: Dictionary = kx.get("sp", {})
			var marcas: Array[String] = []
			for z: String in sp:
				marcas.append(String(sp[z].get("marca", "")))
			if not sp.is_empty():
				c_sp += 1
			## Los patrocinadores de los AI salen de un reparto por azar determinista
			## (SponsorKit.de_club), no de un dato del club real: se cuenta como NO.
			var sp_dato := false
			var fijos := 0
			for j: Jugador in c.plantel():
				jug_total += 1
				if j.real:
					fijos += 1
				if Cara.ruta_foto(j) != "":
					jug_retrato += 1
			var plantel_real: bool = fijos >= 11
			if plantel_real:
				c_plantel_real += 1
			csv += "%s,\"%s\",%s,%d,%s,%s,%s,%s,%s,%s,%s,%s,%d,\"%s\",%s,%d,%s,%d\n" % [base, c.nombre, c.pais, c.rep, est_real, p.get("forma", ""), est_col,
				Escudo.forma_de(c), Escudo.patron_de(c), esc_ok, foto, dis, sp.size(), "|".join(marcas), sp_dato, c.plantel().size(), plantel_real, jug_retrato]
		md += "## Base %s — %d clubes\n\n| Aspecto | Clubes | Porcentaje |\n|---|---|---|\n" % [base, n]
		var filas := [
			["Estadio con la arquitectura del real", c_est_real], ["Estadio con colores propios de butacas", c_est_col],
			["Escudo con los colores del club", c_esc_ok], ["Escudo con rasgos del escudo real", c_esc_real], ["Camiseta con foto real de la equipación", c_kit_foto],
			["Camiseta con diseño propio (no liso)", c_kit_dis], ["Con patrocinador en la camiseta", c_sp],
			["Patrocinador tomado de un dato del club real", c_sp_real], ["Plantilla fija (≥11 jugadores reales)", c_plantel_real]]
		for f: Array in filas:
			md += "| %s | %d | %.0f %% |\n" % [f[0], f[1], 100.0 * float(f[1]) / maxf(n, 1)]
		md += "\nJugadores: %d; con retrato real: %d (%.0f %%).\n\n" % [jug_total, jug_retrato, 100.0 * float(jug_retrato) / maxf(jug_total, 1)]
		md += "Clubes SIN estadio del real (primeros 30): %s\n\n" % ", ".join(sin_est.slice(0, 30))
	Datos.usar_base_real(false)
	FileAccess.open("res://AUDITORIA_CLUBES.md", FileAccess.WRITE).store_string(md)
	FileAccess.open("res://AUDITORIA_CLUBES.csv", FileAccess.WRITE).store_string(csv)
	print(md)
	print("FIN. 0 fallos")
	get_tree().quit()
