extends Node
## CUÁNTO TARDA CREAR EL MUNDO ENTERO (M-349, 3-11-2026): `Mundo.generar([], 0)` (todas las ligas, ~384 clubes) y, aparte, `Reales.aplicar`
## sobre ese mundo. Herramienta, no prueba del banco. Imprime la huella (hash de nombres y medias) para comprobar que optimizar no cambia el resultado.
##   godot --headless --path . res://pruebas/zz_medir_generar.tscn
func _ready() -> void:
	for vez in 3:
		var m := Mundo.new()
		var t0 := Time.get_ticks_usec()
		m.generar([], 0)
		var t1 := Time.get_ticks_usec()
		var huella := 0
		for c: Club in m.clubes.values():
			huella = hash([huella, c.nombre, c.plantel().size()])
			for j: Jugador in c.plantel():
				huella = hash([huella, j.nombre, j.edad, j.ovr, j.pos_e])
		print("generar #%d: %.0f ms (%d clubes) huella %d" % [vez + 1, (t1 - t0) / 1000.0, m.clubes.size(), huella])
		var t2 := Time.get_ticks_usec()
		var n := Reales.aplicar(m)
		print("   Reales.aplicar sobre ese mundo: %.0f ms (%d reales)" % [(Time.get_ticks_usec() - t2) / 1000.0, n])
	_desglose()
	_micro()
	_micro_nombre()
	get_tree().quit()

## Desglose por fases de `generar` (copia de su bucle con relojes): crear club, poblar, preparar liga y Reales.aplicar.
func _desglose() -> void:
	var m := Mundo.new()
	m.semilla = Azar.sembrar(0)
	m.mercado = Mercado.new(m)
	m.roles = Roles.new(m)
	m.cesiones = Cesiones.new(m)
	m.eras = Eras.new(m)
	var t_club := 0.0
	var t_pob := 0.0
	var t_liga := 0.0
	for f: Dictionary in m._fuentes_de_liga([]):
		var liga := Liga.new(f["nombre"], f["pais"], int(f.get("division", 1)))
		for fila: Array in f["clubes"]:
			var a := Time.get_ticks_usec()
			var c := m._crear_club(fila, f["pais"])
			c.division = int(f.get("division", 1))
			m.clubes[c.id] = c
			liga.clubes.append(c)
			var b := Time.get_ticks_usec()
			m._poblar(c)
			t_club += (b - a) / 1000.0
			t_pob += (Time.get_ticks_usec() - b) / 1000.0
		var d := Time.get_ticks_usec()
		liga.preparar()
		t_liga += (Time.get_ticks_usec() - d) / 1000.0
		m.ligas.append(liga)
	print("   desglose: crear clubes %.0f ms · poblar plantillas %.0f ms · preparar ligas %.0f ms" % [t_club, t_pob, t_liga])

## Microcoste de cada paso de `crear_jugador` (N jugadores): lo que más pesa es lo que conviene bajar.
func _micro(n := 4000) -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 0)
	var c: Club = m.clubes.values()[0]
	var js: Array[Jugador] = []
	var pasos := {"Jugador.new+campos": 0.0, "Regiones.region_para": 0.0, "_nombre_al_azar": 0.0, "_rasgo_al_azar": 0.0, "Contratos.ajustar_anios": 0.0, "generar_atributos": 0.0, "tasar": 0.0, "sortear_habilidades": 0.0}
	var t := 0
	for i in n:
		t = Time.get_ticks_usec()
		var j := Jugador.new()
		j.id = "j%d" % i
		j.pos = "MED"
		j.pos_e = "MC"
		j.pais = c.pais
		pasos["Jugador.new+campos"] += Time.get_ticks_usec() - t
		t = Time.get_ticks_usec()
		j.region = Regiones.region_para(c.pais, j.id, c)
		pasos["Regiones.region_para"] += Time.get_ticks_usec() - t
		t = Time.get_ticks_usec()
		j.nombre = m._nombre_al_azar(c.pais, j.region)
		pasos["_nombre_al_azar"] += Time.get_ticks_usec() - t
		j.edad = 24
		j.ovr = 70
		j.pot = 72
		t = Time.get_ticks_usec()
		j.rasgo = m._rasgo_al_azar()
		pasos["_rasgo_al_azar"] += Time.get_ticks_usec() - t
		t = Time.get_ticks_usec()
		j.anios_contrato = Contratos.ajustar_anios(j, 2)
		pasos["Contratos.ajustar_anios"] += Time.get_ticks_usec() - t
		t = Time.get_ticks_usec()
		j.generar_atributos()
		pasos["generar_atributos"] += Time.get_ticks_usec() - t
		t = Time.get_ticks_usec()
		j.tasar()
		pasos["tasar"] += Time.get_ticks_usec() - t
		t = Time.get_ticks_usec()
		if m.entrenamiento != null:
			m.entrenamiento.sortear_habilidades(j)
		pasos["sortear_habilidades"] += Time.get_ticks_usec() - t
		js.append(j)
	for k: String in pasos:
		print("   %-26s %6.1f µs/jugador" % [k, float(pasos[k]) / n])

func _micro_nombre(n := 20000) -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 0)
	var pasos := {"3 Datos.tabla": 0.0, "Regiones.bolsas": 0.0, "_bolsa_extra": 0.0, "Azar.uno x2 + formato": 0.0, "Nombres.vetado": 0.0, "_sortear_nombre entero": 0.0, "sin_vetar entero": 0.0}
	var nom := "Juan Pérez"
	var tabla: Array = Datos.tabla("NOMBRES")
	for i in n:
		var t := Time.get_ticks_usec()
		var _a: Array = Datos.tabla("NOMBRES")
		var _b: Array = Datos.tabla("APELLIDOS")
		var _c: Variant = Datos.tabla("POOLS_EU")
		pasos["3 Datos.tabla"] += Time.get_ticks_usec() - t
		t = Time.get_ticks_usec()
		var _d := Regiones.bolsas("CHI", "")
		pasos["Regiones.bolsas"] += Time.get_ticks_usec() - t
		t = Time.get_ticks_usec()
		var _e := m._bolsa_extra("CHI")
		pasos["_bolsa_extra"] += Time.get_ticks_usec() - t
		t = Time.get_ticks_usec()
		var _s := "%s %s" % [Azar.uno(tabla), Azar.uno(tabla)]
		pasos["Azar.uno x2 + formato"] += Time.get_ticks_usec() - t
		t = Time.get_ticks_usec()
		var _v := Nombres.vetado(nom)
		pasos["Nombres.vetado"] += Time.get_ticks_usec() - t
		t = Time.get_ticks_usec()
		var _x := m._sortear_nombre("CHI", "")
		pasos["_sortear_nombre entero"] += Time.get_ticks_usec() - t
		t = Time.get_ticks_usec()
		var _y := Nombres.sin_vetar(func() -> String: return m._sortear_nombre("CHI", ""))
		pasos["sin_vetar entero"] += Time.get_ticks_usec() - t
	for k: String in pasos:
		print("   nombre: %-24s %6.2f µs" % [k, float(pasos[k]) / n])
