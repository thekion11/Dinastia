class_name ProbarNativoPuras
extends RefCounted
## (20-11-2026, orden 63 del dueño) LAS FUNCIONES PURAS DEL NÚCLEO EN C++ = SU GEMELA GDSCRIPT. Cada fila de CASOS es una función
## de `nucleo/` con su gemela `<nombre>_gd` y su método de la extensión (`nuc_…`): se llaman con las MISMAS entradas (los bordes de
## cada argumento, los valores donde cambia una rama y entradas al azar con semilla fija) y se comparan los BYTES del resultado
## (`var_to_bytes`: tipo y bits). Una fila nueva por cada función que se porte. Devuelve {fallos, textos}.
## Cada argumento: ["i", mín, máx] entero, ["f", mín, máx, [valores extra]] flotante, ["b"] booleano.
const AZAR := 400   ## entradas al azar por función (además de las de borde)

const CASOS: Array = [
	["res://nucleo/banco.gd", "cuota_francesa", "nuc_cuota_francesa", [["i", 0, 50000000], ["f", 0.001, 0.3, [0.0, -0.5]], ["i", -2, 500]]],
	["res://nucleo/calendario_p1.gd", "pascua", "nuc_pascua", [["i", 1583, 2600]]],
	["res://nucleo/calles_ciudad.gd", "es_avenida_columna", "nuc_es_avenida_columna", [["i", -20, 20]]],
	["res://nucleo/calles_ciudad.gd", "es_avenida_fila", "nuc_es_avenida_fila", [["i", -20, 20]]],
	["res://nucleo/cantera_p3.gd", "agente_aprieta", "nuc_agente_aprieta", [["i", -2, 6], ["i", -5, 5]]],
	["res://nucleo/cantera_progreso.gd", "por_edad", "nuc_por_edad", [["i", -5, 45]]],
	["res://nucleo/cargo_seleccion.gd", "_alcanza", "nuc_alcanza", [["i", -20, 130]]],
	["res://nucleo/carrera_premios.gd", "_puntos_mundial", "nuc_puntos_mundial", [["f", 0.0, 10.0, []], ["i", 0, 60], ["i", 0, 60], ["i", 0, 20]]],
	["res://nucleo/carrera_ruta.gd", "xp_para", "nuc_xp_para", [["i", -5, 200]]],
	["res://nucleo/cartera_dt.gd", "clave_dia", "nuc_clave_dia", [["i", 1990, 2100], ["i", 0, 60], ["i", 0, 7]]],
	["res://nucleo/charlas.gd", "_abs", "nuc_abs_semana", [["i", 1990, 2100], ["i", 0, 60]]],
	["res://nucleo/eventos_cantera.gd", "_abs", "nuc_abs_semana", [["i", 1990, 2100], ["i", 0, 60]]],
	["res://nucleo/licencia.gd", "_abs", "nuc_abs_semana", [["i", 1990, 2100], ["i", 0, 60]]],
	["res://nucleo/vida_dt.gd", "_abs", "nuc_abs_semana", [["i", 1990, 2100], ["i", 0, 60]]],
	["res://nucleo/clima.gd", "mes_de", "nuc_mes_de", [["i", -5, 70]]],
	["res://nucleo/continental.gd", "_orden_de_semillas", "nuc_orden_de_semillas", [["i", -2, 70]]],
	["res://nucleo/entrada_campeonato.gd", "_socios_de", "nuc_socios_de", [["i", 0, 120000], ["i", 0, 110]]],
	["res://nucleo/fase_final_liga.gd", "_rr", "nuc_rr", [["i", -5, 60]]],
	["res://nucleo/formacion_propia.gd", "puesto_de", "nuc_puesto_de", [["f", 0.0, 100.0, [24.0, 76.0, 50.0, 23.999, 76.001, 49.999]], ["f", 0.0, 100.0, [70.0, 54.0, 28.0, 58.0, 40.0, 69.999, 27.999]]]],
	["res://nucleo/idiomas.gd", "_es_letra", "nuc_es_letra", [["i", 0, 800]]],
	["res://nucleo/jugador.gd", "techo_tope", "nuc_techo_tope", [["i", 0, 130], ["i", 0, 120]]],
	["res://nucleo/objetivos_cierre.gd", "delta_de", "nuc_delta_de", [["i", -5, 40], ["b"]]],
	["res://nucleo/ocasiones_dt.gd", "hueco", "nuc_hueco", [["i", 0, 95], ["i", 0, 130], ["i", -2, 12]]],
	["res://nucleo/ocasiones_dt.gd", "prob_tiro_3d", "nuc_prob_tiro_3d", [["f", 0.0, 60.0, []], ["f", -35.0, 35.0, [0.0]], ["b"], ["f", 0.0, 1.4, [0.54, 0.99, 0.0]]]],
	["res://nucleo/previa.gd", "_cuota", "nuc_cuota", [["f", -0.1, 1.2, [0.0, 0.01, 1.0]]]],
	["res://nucleo/redes_ciudad.gd", "curva", "nuc_curva_hora", [["i", -30, 60]]],
	["res://nucleo/viajes.gd", "delegacion", "nuc_delegacion", [["i", -20, 130]]],
	["res://nucleo/motor_libre_p1.gd", "_dir", "nuc_dir_equipo", [["i", -2, 3]]],
	["res://nucleo/olimpicos.gd", "toca", "nuc_toca_olimpicos", [["i", 1900, 2100]]],
	## 2.ª tanda (las constantes de la clase se resuelven en el script: «const:NOMBRE» = su valor, para probar justo los umbrales)
	["res://nucleo/calendario_p1.gd", "icono", "nuc_icono_calendario", [["s", ["fiesta", "memoria", "trabajo", "festividad", "otro", ""]]]],
	["res://nucleo/crisis_caja.gd", "concepto", "nuc_concepto_crisis", [["s", ["multa", "patrocinio", "obra", "x", ""]]]],
	["res://nucleo/dialogos_ciudad.gd", "grupo", "nuc_grupo_dialogo", [["s", ["euforia", "bien", "mal", "crisis", "normal", "x", ""]]]],
	["res://nucleo/formacion_propia.gd", "linea_de", "nuc_linea_de", [["s", ["POR", "LD", "LI", "DFC", "CAD", "CAI", "DC", "ED", "EI", "SD", "MC", "MCD", "MCO", "MD", "MI", "x", ""]]]],
	["res://nucleo/incidentes_ciudad.gd", "aviso", "nuc_aviso_incidente", [["s", ["incendio", "accidente", "robo", "x", ""]]]],
	["res://nucleo/incidentes_ciudad.gd", "resuelto", "nuc_resuelto_incidente", [["s", ["incendio", "accidente", "robo", "x", ""]]]],
	["res://nucleo/musica_libre.gd", "situacion_libre", "nuc_situacion_libre", [["s", ["partido", "final", "celebracion", "grada", "parón", "paron", "oficina", "x", ""]]]],
	["res://nucleo/tipo_titulo.gd", "nombre_escena", "nuc_nombre_escena", [["s", ["escenario", "palco", "fuegos", "sobrio", "foto", "manteo", "champan", "desfile", "pasillo", "otra", ""]]]],
	["res://nucleo/ocasiones_dt.gd", "nivel", "nuc_nivel_ocasion", [["i", 0, 95], ["i", 0, 130], ["i", 0, 12], ["i", -2, 12]]],
	["res://nucleo/viajes.gd", "medio", "nuc_medio_viaje", [["f", 0.0, 12000.0, ["const:KM_BUS_MAX", "const:KM_AVION_MAX", 0.0]]]],
	["res://nucleo/viajes.gd", "noches", "nuc_noches_viaje", [["f", 0.0, 12000.0, ["const:KM_BUS_NOCHE", 2500.0, 9000.0, 0.0]]]],
	["res://nucleo/calendario_p1.gd", "toca_continental_selecciones", "nuc_toca_continental", [["s", ["ucl", "lib", "oce", "conc", "afr", "asia", "x", ""]], ["i", 1990, 2100]]],
	["res://nucleo/retos_semana.gd", "cumple", "nuc_cumple_reto", [["s", ["ganar", "ganar_2", "cero", "no_perder", "marcar_2", "marcar_3", "encajar_1", "x", ""]], ["i", 0, 8], ["i", 0, 8]]],
	["res://nucleo/partida.gd", "_seq_de", "nuc_seq_de", [["s", ["c1", "c12", "j7", "cx", "", "c", "j-3", "c+4", "c 5", "x9", "j007"]], ["s", ["c", "j", ""]], ["i", -3, 5]]],
	["res://nucleo/selecciones_p1.gd", "_hash_txt", "nuc_hash_txt", [["r", 12]]],
	["res://nucleo/nombres.gd", "_es_letra", "nuc_es_letra_nombre", [["s", ["a", "Z", "ñ", "Ā", "ſ", "À", "é", "1", " ", "", "🎉", "İ", "ab"]], ]],
	["res://nucleo/idiomas_inverso.gd", "_prefijo", "nuc_prefijo_comun", [["r", 8], ["r", 8]]],
	## 3.ª tanda (Array, Dictionary, Vector2/3; «g» = generador propio, «diff:A:B» = A − B de las constantes)
	["res://nucleo/acciones_juego.gd", "xg", "nuc_xg", [["v2", -60.0, 60.0, []]]],
	["res://nucleo/fase_final_liga.gd", "_unir", "nuc_unir_arrays", [["g", "listas"], ["g", "listas"]]],
	["res://nucleo/fase_final_liga.gd", "_vuelta", "nuc_vuelta_pares", [["g", "rondas"]]],
	["res://nucleo/idiomas.gd", "_escapar_re", "nuc_escapar_re", [["r", 12]]],
	["res://nucleo/logros_largo.gd", "_maximo_de", "nuc_maximo_de", [["g", "registro"]]],
	["res://nucleo/ocasiones_dt.gd", "es_clara", "nuc_es_clara", [["f", 0.0, 40.0, ["const:DIST_MINIMO", "const:DIST_APURADA", "const:DIST_CLARA"]], ["f", -30.0, 30.0, ["const:LATERAL_MINIMO", "const:LATERAL_CLARA", 0.0]], ["f", 0.0, 1.0, ["const:ESPACIO_MINIMO", "const:ESPACIO_APURADA", "const:ESPACIO_CLARA"]], ["g", "nivel"]]],
	["res://nucleo/ocasiones_dt.gd", "recomendar", "nuc_recomendar", [["g", "lect"], ["f", 0.0, 1.2, [0.0]], ["f", 0.0, 1.2, [0.0]]]],
	["res://nucleo/politica.gd", "relacion", "nuc_relacion_politica", [["g", "politica"]]],
	["res://nucleo/recorridos_mapa.gd", "antes", "nuc_antes_recorrido", [["s", ["122", "150", "C02", "C09c", "150c", "200", "C10", "", "a", "Z"]], ["s", ["122", "150", "C02", "C09c", "150c", "200", "C10", "", "a", "Z"]]]],
	["res://nucleo/recorridos_red.gd", "sector_de", "nuc_sector_de", [["v3", -2500.0, 2500.0, ["const:PERIFERIA", "const:RIO_X", "diff:RIO_X:RIO_MEDIO", "const:NUC_Z0", "const:NUC_X1", "const:NUC_Z1", 700.0]]]],
	["res://nucleo/recorridos_red.gd", "sector_del_codigo", "nuc_sector_del_codigo", [["s", ["PA1234", "PA6999", "PA0123", "PA7000", "PA123", "PAx234", "PA12345", "", "P", "PA", "PA5000"]]]],
	["res://nucleo/redes_ciudad.gd", "tiempo_de", "nuc_tiempo_de", [["s", ["lluvia", "tormenta", "viento", "calor", "despejado", "nieve", ""]], ["i", -30, 60]]],
	["res://nucleo/seleccion_equipo.gd", "_total", "nuc_total_grupos", [["g", "por_grupo"]]],
	["res://nucleo/torneo_selecciones.gd", "_cruces", "nuc_cruces", [["g", "lista_cruces"], ["g", "f_pos"]]],
	["res://nucleo/vestuario_p3.gd", "motivo_satisfaccion", "nuc_motivo_satisfaccion", [["g", "sat"], ["b"]]],
	## 4.ª tanda (textos, diccionarios, Color y objetos Jugador; ninguna modifica sus argumentos)
	["res://nucleo/cesiones_p2.gd", "nueva_oferta", "nuc_nueva_oferta", [["i", 0, 200000000]]],
	["res://nucleo/idiomas.gd", "_tiene_letras", "nuc_tiene_letras", [["r", 8]]],
	["res://nucleo/idiomas_inverso.gd", "normal", "nuc_normal_titulo", [["g", "mayus_mixto"]]],
	["res://nucleo/mercado_dt.gd", "_sin_fecha", "nuc_sin_fecha", [["g", "dict_fecha"]]],
	["res://nucleo/movil.gd", "remitente_de", "nuc_remitente_de", [["g", "texto_msg"], ["g", "texto_msg"]]],
	["res://nucleo/recorridos_red.gd", "normalizar", "nuc_normalizar_codigo", [["g", "codigo"]]],
	["res://nucleo/partido_despedida.gd", "por_linea", "nuc_por_linea", [["g", "jugadores"]]],
	["res://nucleo/ropero_dt.gd", "aplicar", "nuc_ropero_aplicar", [["g", "aspecto"], ["s", ["camiseta_club", "chandal", "bufanda_club", "gorra_club", "otro", ""]], ["g", "color"], ["g", "color"]]],
	["res://nucleo/ciudad_p1.gd", "paletas_luces", "nuc_paletas_luces", []],
]

## Los valores de un argumento: bordes y puntos de cambio primero, el resto al azar.
static func _valores(espec: Array, rng: RandomNumberGenerator, scr: Script) -> Array:
	var v: Array = []
	match String(espec[0]):
		"b":
			return [false, true]
		"s":
			return (espec[1] as Array).duplicate()
		"g":
			return _generar(String(espec[1]), rng)
		"v2", "v3":
			var lo := float(espec[1])
			var hi := float(espec[2])
			var tres: bool = String(espec[0]) == "v3"
			var extras: Array = []
			for extra: Variant in espec[3]:
				extras.append(_constante(scr, extra))
			for e: float in extras + [0.0]:
				for sg: float in [1.0, -1.0]:
					v.append(Vector3(e * sg, 0.0, 0.0) if tres else Vector2(e * sg, 0.0))
					v.append(Vector3(0.0, 0.0, e * sg) if tres else Vector2(0.0, e * sg))
					v.append(Vector3(e * sg, 0.0, e * sg) if tres else Vector2(e * sg, e * sg))
			for _k in AZAR:
				v.append(Vector3(rng.randf_range(lo, hi), 0.0, rng.randf_range(lo, hi)) if tres else Vector2(rng.randf_range(lo, hi), rng.randf_range(lo, hi)))
		"r":
			var alfabeto := "abcXYZ áéíóúñÑüÜ0123_-🎉ßİıÀ"
			v.append("")
			for _k in AZAR:
				var t := ""
				for _c in rng.randi_range(0, int(espec[1])):
					t += alfabeto[rng.randi() % alfabeto.length()]
				v.append(t)
		"i":
			var lo := int(espec[1])
			var hi := int(espec[2])
			v.append_array([lo, hi, lo - 1, hi + 1, 0, 1, -1])
			for _k in AZAR:
				v.append(rng.randi_range(lo, hi))
		"f":
			var lo := float(espec[1])
			var hi := float(espec[2])
			v.append_array([lo, hi, (lo + hi) * 0.5])
			for extra: Variant in espec[3]:
				v.append(_constante(scr, extra))
			for _k in AZAR:
				v.append(rng.randf_range(lo, hi))
				v.append(float(rng.randi_range(int(lo), int(hi))))   ## valores enteros: donde suelen estar los umbrales
	return v

## Un valor extra de un argumento flotante: número, «const:NOMBRE» (constante del script) o «diff:A:B» (A − B).
static func _constante(scr: Script, extra: Variant) -> float:
	if not (extra is String):
		return float(extra)
	var mapa: Dictionary = scr.get_script_constant_map()
	var partes := String(extra).split(":")
	if partes[0] == "diff":
		return float(mapa[partes[1]]) - float(mapa[partes[2]])
	return float(mapa[partes[1]])

## Entradas propias de las funciones que reciben listas o diccionarios (con semilla fija).
static func _generar(nombre: String, rng: RandomNumberGenerator) -> Array:
	var v: Array = []
	for _k in AZAR:
		match nombre:
			"listas":
				var l: Array = []
				for _i in rng.randi_range(0, 4):
					var m: Array = []
					for _j in rng.randi_range(0, 3):
						m.append(rng.randi_range(0, 9))
					l.append(m)
				v.append(l)
			"rondas":
				var r: Array = []
				for _i in rng.randi_range(0, 4):
					var j: Array = []
					for _j in rng.randi_range(0, 4):
						j.append([rng.randi_range(0, 20), "c%d" % rng.randi_range(0, 20)])
					r.append(j)
				v.append(r)
			"registro":
				var d: Dictionary = {}
				for c: String in ["a", "b", "c", "d", "e"]:
					match rng.randi() % 5:
						0: d[c] = rng.randi_range(0, 50)
						1: d[c] = rng.randf_range(0.0, 50.9)
						2: d[c] = {"n": rng.randi_range(0, 60)}
						3: d[c] = {"x": 1}
						_: pass
				v.append(d)
			"lect":
				var d: Dictionary = {}
				for c: String in ["tiro", "pase", "conducir"]:
					if rng.randi() % 4 != 0:
						d[c] = {"prob": rng.randf_range(0.0, 1.0)}
				v.append(d)
			"politica":
				var d: Dictionary = {}
				for c: String in ["apoyo_club", "recelo_club", "desde"]:
					if rng.randi() % 6 != 0:
						d[c] = rng.randi_range(-2, 8)
				v.append(d)
			"por_grupo":
				var d: Dictionary = {}
				for _i in rng.randi_range(0, 5):
					var a: Array = []
					a.resize(rng.randi_range(0, 6))
					d["g%d" % _i] = a
				v.append(d)
			"lista_cruces":
				var a: Array = []
				for _i in rng.randi_range(1, 12):
					a.append(null if rng.randi() % 9 == 0 else (rng.randi_range(0, 99) if rng.randi() % 2 == 0 else "e%d" % rng.randi_range(0, 99)))
				v.append(a)
			"f_pos":
				v.append(rng.randi_range(0, 30))
			"nivel":
				v.append(rng.randi_range(-1, 3))
			"mayus_mixto":
				var t := ""
				for _i in rng.randi_range(0, 9):
					t += "ABCDEFGHIJKLMNÑOPQRSTUVWXYZÁÉÍÓÚÜß abc12-".substr(rng.randi() % 39, 1)
				v.append(t if rng.randi() % 3 != 0 else t.to_upper())
			"dict_fecha":
				var d: Dictionary = {"x": rng.randi_range(0, 9)}
				if rng.randi() % 2 == 0:
					d["anio"] = 2026 + rng.randi_range(0, 5)
				if rng.randi() % 2 == 0:
					d["semana"] = rng.randi_range(1, 52)
				d["y"] = "t%d" % rng.randi_range(0, 9)
				v.append(d)
			"texto_msg":
				var palabras: Array = ["directiva", "Confianza", "JUNTA", "casa", "familia", "Oferta", "contrato", "lesión", "LESION", "médico", "gol", "xyz", "", "pareja", "mascota", "agente"]
				var t := ""
				for _i in rng.randi_range(0, 4):
					t += String(palabras[rng.randi() % palabras.size()]) + (" " if rng.randi() % 2 == 0 else "")
				v.append(t)
			"codigo":
				var opciones: Array = ["pa1234", " PA 12-34 ", "1234", "pa12", "PA12345", "-", "", "ab 123", "PA999", "pa-5000", "123", "PAxx12", "12 3"]
				v.append(opciones[rng.randi() % opciones.size()])
			"jugadores":
				var a: Array = []
				for _i in rng.randi_range(0, 8):
					var j := Jugador.new()
					j.pos = ["POR", "DEF", "MED", "DEL", "XX"][rng.randi() % 5]
					a.append(j)
				v.append(a)
			"aspecto":
				var d: Dictionary = {"pelo": "corto"}
				for c: String in ["ropa", "corbata", "gorra", "bufanda", "c_ropa"]:
					if rng.randi() % 2 == 0:
						d[c] = rng.randi_range(0, 3)
				v.append(d)
			"color":
				v.append(Color(rng.randf(), rng.randf(), rng.randf(), 1.0 if rng.randi() % 2 == 0 else rng.randf()))
			"sat":
				var d: Dictionary = {}
				for c: String in ["min", "rend", "tact", "inst"]:
					d[c] = rng.randi_range(0, 100)
				v.append(d)
	return v

static func probar(nat: Object) -> Dictionary:
	var fallos: Array[String] = []
	var textos: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 20112026
	var total := 0
	for caso: Array in CASOS:
		var nombre := String(caso[1])
		var nuc := String(caso[2])
		if not nat.has_method(nuc):
			fallos.append("%s.%s: la extensión no trae `%s`" % [caso[0], nombre, nuc])
			continue
		if Nativo.de(nuc) == null:   ## sin esto la comparación sería GDScript contra GDScript y pasaría en vacío
			fallos.append("%s.%s: `Nativo.de(\"%s\")` no devuelve la extensión (el envoltorio usaría GDScript)" % [caso[0], nombre, nuc])
			continue
		var scr: Script = load(String(caso[0]))
		var tiene: Dictionary = {}
		for m: Dictionary in scr.get_script_method_list():
			tiene[String(m["name"])] = true
		if not tiene.has(nombre + "_gd") or not tiene.has(nombre):
			fallos.append("%s: falta `%s` o su gemela `%s_gd`" % [caso[0], nombre, nombre])
			continue
		var conjuntos: Array = []
		for espec: Array in caso[3]:
			conjuntos.append(_valores(espec, rng, scr))
		## Cada argumento con su propia lista; se combinan por posición (las listas de borde primero) y con barajado del resto.
		var n := 0
		for conj: Array in conjuntos:
			n = maxi(n, conj.size())
		var malos := 0
		if conjuntos.is_empty():   ## sin argumentos: una sola comparación
			total += 1
			if var_to_bytes(scr.callv(nombre, [])) != var_to_bytes(scr.callv(nombre + "_gd", [])):
				fallos.append("%s.%s(): C++ distinto de GDScript" % [String(caso[0]).get_file(), nombre])
		for k in n * 2:
			var args: Array = []
			for conj: Array in conjuntos:
				args.append(conj[k % conj.size()] if k < n else conj[rng.randi() % conj.size()])
			var a: Variant = scr.callv(nombre, args)         ## con la extensión (Nativo.de la devuelve)
			var b: Variant = scr.callv(nombre + "_gd", args)   ## la gemela GDScript
			total += 1
			if var_to_bytes(a) != var_to_bytes(b):
				malos += 1
				if malos <= 3:
					fallos.append("%s.%s%s: C++ %s, GDScript %s" % [String(caso[0]).get_file(), nombre, str(args), str(a), str(b)])
		if malos > 3:
			fallos.append("%s.%s: … y %d entradas más distintas" % [String(caso[0]).get_file(), nombre, malos - 3])
	textos.append("funciones puras del núcleo: %d funciones, %d comparaciones C++ = GDScript" % [CASOS.size(), total])
	return {"fallos": fallos, "textos": textos}
