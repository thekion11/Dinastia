extends BaseIdea
## EL ASPECTO DE LOS CLUBES REALES (orden 15, 27-10-2026): los 384 clubes del pack real y los 384 de la base ficticia traen escudo, uniforme y
## butacas de su club; todo se puede dibujar; los clubes de una misma liga no se confunden y el diseño propio del jugador sigue mandando.

func _ready() -> void:
	await get_tree().process_frame
	_probar_aspecto()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

var colores := {}

func _clubes() -> Array:
	var r: Array = []
	colores.clear()
	var filas: Array = (Datos.tabla("DATA_P1") + Datos.tabla("DATA_P2")).duplicate()
	for pais: String in Datos.tabla("PAISES_LIGAS"):
		filas.append_array(Datos.tabla("PAISES_LIGAS")[pais]["clubes"])
	for fila: Array in filas:
		r.append(String(fila[0]))
		colores[String(fila[0])] = [fila[1], fila[2]]
	return r

func _probar_aspecto() -> void:
	for real: bool in [true, false]:
		Datos.usar_base_real(real)
		if real != Datos.base_real:
			print("(sin pack real en este equipo: se salta la base real)")
			continue
		_titulo("ASPECTO DE CLUB · BASE %s" % ("REAL" if real else "FICTICIA"))
		var tabla: Dictionary = Datos.tabla("ASPECTO_CLUB")
		var nombres := _clubes()
		_comprobar(tabla.size() == 384, "384 filas de aspecto (%d)" % tabla.size())
		var propios := nombres.filter(func(n: String) -> bool: return tabla.has(n) or tabla.has(Nombres.limpiar(n)))
		_comprobar(propios.size() == 384, "los 384 clubes de las 22 ligas originales tienen su fila (%d)" % propios.size())
		nombres = propios
		var mal := 0
		var sin_siglas := 0
		var repetidos := {}
		for n: String in nombres:
			var c := Club.new()
			c.id = "x_" + n
			c.nombre = n
			c.color1 = String(colores[n][0])
			c.color2 = String(colores[n][1])
			var f: Dictionary = AspectoClub.fila(c)
			if not (f.has("escudo") and f.has("camiseta")):
				mal += 1
			if real and AspectoClub.siglas(c) == "":
				sin_siglas += 1
			if not real and AspectoClub.siglas(c) != "":
				sin_siglas += 1
			if Escudo.textura(c, 48) == null or Jersey.textura(c, 0, 64) == null:
				mal += 1
				print("  (no se dibuja: %s)" % n)
			var kit := DisenosKit.kit_de_club(c)
			if String(kit["dis"]) != String(f["camiseta"]):
				mal += 1
				print("  (diseño distinto: %s %s %s)" % [n, kit["dis"], f["camiseta"]])
			repetidos[c.color1 + c.color2 + str(f["escudo"]) + str(f.get("esc", [])) + String(f["camiseta"]) + str(f.get("kit", {}))] = true
		_comprobar(mal == 0, "todos tienen escudo, camiseta y butacas y se dibujan (%d con fallo)" % mal)
		_comprobar(sin_siglas == 0, "siglas: las del club real en el pack y ninguna en la base ficticia (%d mal)" % sin_siglas)
		_comprobar(repetidos.size() >= 300, "el aspecto no se repite de un club a otro (%d distintos de 384)" % repetidos.size())
		## Las figuras y letras de los escudos más conocidos (escudos v2).
		var con_motivo := 0
		var distintos := {}
		for n: String in nombres:
			var cc := Club.new()
			cc.id = "z_" + n
			cc.nombre = n
			cc.color1 = "#336699"
			cc.color2 = "#ffffff"
			if AspectoClub.emblema(cc) != "" or AspectoClub.letras(cc) != "":
				con_motivo += 1
				var capa := EscudoEmblemas.capa_de(cc, cc.color_escudo1())
				if capa == "" or not capa.contains("<"):
					con_motivo -= 1000
				distintos[Escudo.svg_de(cc)] = true
		_comprobar(con_motivo >= 60, "al menos 60 escudos con figura o letras propias (%d)" % con_motivo)
		_comprobar(distintos.size() == con_motivo, "cada escudo con motivo sale distinto (%d de %d)" % [distintos.size(), con_motivo])
		## El uniforme propio del jugador manda sobre el del club real.
		var yo := Club.new()
		yo.id = "yo"
		yo.nombre = nombres[0]
		yo.color1 = "#336699"
		yo.color2 = "#ffffff"
		yo.kit_color1 = "#123456"
		_comprobar(yo.color_kit1() == "#123456", "el color de camiseta que elige el jugador manda")
		yo.esc_color1 = "#654321"
		_comprobar(yo.color_escudo1() == "#654321", "el color de escudo que elige el jugador manda")
	var prueba := Club.new()
	prueba.id = "p"
	prueba.nombre = "Arsenal"
	EscudoEmblemas.activo = false
	_comprobar(EscudoEmblemas.capa_de(prueba, "#d50032") == "", "apagadas las figuras no se dibuja nada")
	EscudoEmblemas.activo = true
	_comprobar(EscudoEmblemas.letras_svg("CABJ", 32.0, 33.0, 38.0, 24.0, "#ffffff", "#000000").contains("<path"), "las letras salen en trazos vectoriales")
	_comprobar(EscudoEmblemas.letras_svg("¿?", 32.0, 33.0, 38.0, 24.0, "#fff", "#000").count("<path") == 0, "una letra que no existe no rompe el dibujo")
	Datos.usar_base_real(false)
