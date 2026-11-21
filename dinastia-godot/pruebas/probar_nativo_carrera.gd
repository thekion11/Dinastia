class_name ProbarNativoCarrera
extends RefCounted
## (19-11-2026) LA CURVA DE PROGRESO, LOS PRECIOS DE «LA RUTA» Y EL JUGADOR DEL MES EN C++ = GDScript (`nativo/src/carrera_nativo.cpp`).
## Cada función se calcula con la extensión y con su gemela GDScript (apagando `Nativo` un momento) y se comparan los BYTES del resultado.
## Devuelve {fallos, textos}.

static func _con(nat: Object) -> void:
	Nativo._obj = nat
	Nativo._mirado = true

static func _bytes(v: Variant) -> PackedByteArray:
	return var_to_bytes(v)

static func probar(nat: Object) -> Dictionary:
	var fallos: Array[String] = []
	var textos: Array[String] = []
	var j := Jugador.new()
	var casos := _probar_progreso(nat, fallos, j)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1911
	var hab_casos := _probar_habilidades(nat, fallos, rng)
	_probar_jugador_del_mes(nat, fallos, rng)
	textos.append("progreso: %d casos; La Ruta: %d comparaciones; jugador del mes: 40 ligas" % [casos, hab_casos])
	return {"fallos": fallos, "textos": textos}

## ProgresoJugador: toda la rejilla de edad, media y potencial, con y sin el rasgo «motor».
static func _probar_progreso(nat: Object, fallos: Array[String], j: Jugador) -> int:
	var casos := 0
	var malos := 0
	for edad in range(15, 41):
		for ovr in range(30, 100, 3):
			for pot in range(25, 100, 4):
				for rasgo: String in ["", "motor"]:
					j.edad = edad
					j.ovr = ovr
					j.pot = pot
					j.rasgo = rasgo
					casos += 1
					_con(null)
					var a_f := ProgresoJugador.freno(j)
					var a_p := ProgresoJugador.prob_semanal(j)
					var a_e := ProgresoJugador.por_edad(edad)
					_con(nat)
					if _bytes(a_f) != _bytes(ProgresoJugador.freno(j)) or _bytes(a_p) != _bytes(ProgresoJugador.prob_semanal(j)) or _bytes(a_e) != _bytes(float(nat.prog_por_edad(edad))):
						malos += 1
	if malos > 0:
		fallos.append("progreso: %d de %d casos distintos" % [malos, casos])
	return casos

## CarreraHabilidad y cuentas sueltas: precios, costes, reparto y cambio de puesto.
static func _probar_habilidades(nat: Object, fallos: Array[String], rng: RandomNumberGenerator) -> int:
	var puestos := ["POR", "DFC", "LD", "MC", "MCO", "ED", "DC", "MCD", "EI"]
	var hab_casos := 0
	var hab_malos := 0
	for pe: String in puestos:
		for nivel in [1, 2, 7, 15, 40, 99]:
			var c := CarreraJugador.new()
			c.ruta = {}
			c.ruta["nivel"] = nivel
			c.ruta["hab_nivel"] = nivel
			c.ruta["hab"] = 500
			var q := Jugador.new()
			q.id = "prueba-%s-%d" % [pe, nivel]
			q.pos_e = pe
			q.pos_sec.append("MC" if pe != "MC" else "DFC")
			var claves: Array = ["div", "par", "saq", "ref", "vel", "pos"] if pe == "POR" else ["rit", "tir", "pas", "reg", "def", "fis"]
			for k: String in claves:
				q.atributos[k] = rng.randi_range(22, 99)
			## Reparto inicial (con y sin extensión) y el detalle resultante.
			_con(null)
			c.ruta.erase("detalle")
			var d_gd: Dictionary = CarreraHabilidad.detalle(c, q).duplicate(true)
			var res_gd := {}
			for zona: String in claves:
				for par: Array in CarreraHabilidad.de_zona(zona):
					var h := String(par[0])
					res_gd[h] = [CarreraHabilidad.precio_zona(c, q, h), CarreraHabilidad.coste(c, q, h)]
			var cp_gd := {}
			for otro: String in puestos:
				cp_gd[otro] = CarreraHabilidad.coste_puesto(c, q, otro)
			var fn_gd := CarreraHabilidad._factor_nivel(c)
			var fp_gd := CarreraHabilidad._factor_puesto(q)
			_con(nat)
			c.ruta.erase("detalle")
			var d_c: Dictionary = CarreraHabilidad.detalle(c, q).duplicate(true)
			hab_casos += 1
			if _bytes(d_gd) != _bytes(d_c):
				hab_malos += 1
				fallos.append("reparto del detalle distinto en %s nivel %d" % [pe, nivel])
			for zona: String in claves:
				for par: Array in CarreraHabilidad.de_zona(zona):
					var h := String(par[0])
					hab_casos += 1
					if _bytes(res_gd[h]) != _bytes([CarreraHabilidad.precio_zona(c, q, h), CarreraHabilidad.coste(c, q, h)]):
						hab_malos += 1
						if hab_malos <= 5:
							fallos.append("precio o coste de «%s» distinto en %s nivel %d" % [h, pe, nivel])
			for otro: String in puestos:
				hab_casos += 1
				if cp_gd[otro] != CarreraHabilidad.coste_puesto(c, q, otro):
					hab_malos += 1
					fallos.append("coste de pasar de %s a %s distinto (nivel %d)" % [pe, otro, nivel])
			if _bytes(fn_gd) != _bytes(CarreraHabilidad._factor_nivel(c)) or _bytes(fp_gd) != _bytes(CarreraHabilidad._factor_puesto(q)):
				hab_malos += 1
				fallos.append("factores de nivel o de puesto distintos en %s nivel %d" % [pe, nivel])
	## Cuentas sueltas (promedio con redondeo en el .5, coste con zonas de 1 a 6 habilidades).
	for vs: Array in [[50, 51], [60, 61, 62, 63], [99, 98, 1], [0], [10, 11, 11, 12, 12, 13]]:
		var lista: Array = []
		var dd := {}
		for i in vs.size():
			lista.append(["h%d" % i, "x"])
			dd["h%d" % i] = vs[i]
		_con(null)
		var a := CarreraHabilidad._promedio(dd, lista)
		_con(nat)
		if a != CarreraHabilidad._promedio(dd, lista):
			fallos.append("promedio de %s distinto" % [vs])
	for suma in range(0, 400, 7):
		for n in range(1, 7):
			for z in [0.4, 1.0, 5.5, 6.0, 9.0, 12.0, 41.9, 126.0, 300.001]:
				var ref_k := float(posmod(suma, n))
				var ref := maxi(1, ceili(z * (ref_k + 1.0) / float(n) - 0.001) - ceili(z * ref_k / float(n) - 0.001))
				if ref != int(nat.hab_coste(suma, n, z)):
					fallos.append("hab_coste(%d, %d, %s) distinto" % [suma, n, z])
	_con(nat)
	return hab_casos

## PremioMensual: varias ligas al azar, con empates, para tocar la desigualdad aproximada.
static func _probar_jugador_del_mes(nat: Object, fallos: Array[String], rng: RandomNumberGenerator) -> void:
	var pm_malos := 0
	for semilla in range(40):
		rng.seed = 5000 + semilla
		var liga := Liga.new("L", "CHI", 1)
		for ci in range(rng.randi_range(1, 6)):
			var club := Club.new("c%d" % ci, "Club %d" % ci)
			for ji in range(rng.randi_range(0, 14)):
				var p := Jugador.new()
				p.id = "j%d-%d" % [ci, ji]
				p.ovr = rng.randi_range(40, 90)
				p.partidos = rng.randi_range(0, 12)
				var notas: Array[float] = []
				for _k in range(rng.randi_range(0, 9)):
					notas.append(float(rng.randi_range(40, 100)) / 10.0 if semilla % 3 != 0 else 6.5)   ## cada 3.ª liga: todas iguales (empates)
				p.notas = notas
				club.plantilla.append(p)
			liga.clubes.append(club)
		_con(null)
		var g: Jugador = PremioMensual._mejor_gd(liga)
		_con(nat)
		var cx: Variant = nat.premio_mejor(liga.clubes, PremioMensual.MINIMO_NOTAS)
		if (g == null) != (cx == null) or (g != null and g.id != (cx as Jugador).id):
			pm_malos += 1
	if pm_malos > 0:
		fallos.append("jugador del mes: %d de 40 ligas distintas" % pm_malos)
	_con(null)
	Nativo._mirado = false   ## que `Nativo.obj()` vuelva a mirar la extensión

