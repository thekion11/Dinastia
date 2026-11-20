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
]

## Los valores de un argumento: bordes y puntos de cambio primero, el resto al azar.
static func _valores(espec: Array, rng: RandomNumberGenerator) -> Array:
	var v: Array = []
	match String(espec[0]):
		"b":
			return [false, true]
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
			v.append_array(espec[3])
			for _k in AZAR:
				v.append(rng.randf_range(lo, hi))
				v.append(float(rng.randi_range(int(lo), int(hi))))   ## valores enteros: donde suelen estar los umbrales
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
		var scr: Script = load(String(caso[0]))
		var tiene: Dictionary = {}
		for m: Dictionary in scr.get_script_method_list():
			tiene[String(m["name"])] = true
		if not tiene.has(nombre + "_gd") or not tiene.has(nombre):
			fallos.append("%s: falta `%s` o su gemela `%s_gd`" % [caso[0], nombre, nombre])
			continue
		var conjuntos: Array = []
		for espec: Array in caso[3]:
			conjuntos.append(_valores(espec, rng))
		## Cada argumento con su propia lista; se combinan por posición (las listas de borde primero) y con barajado del resto.
		var n := 0
		for conj: Array in conjuntos:
			n = maxi(n, conj.size())
		var malos := 0
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
