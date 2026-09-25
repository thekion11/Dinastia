extends Node

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 4242)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var r := Roles.new(m)

	# --- dt ---
	r.arrancar("dt", "Tester")
	print("dt: rol=", r.rol, " alinear=", r.puede_alinear(), " manda=", r.manda(),
		" fichar=", r.puede_fichar(), " bloqueo='", r.mercado_bloqueado(), "'")

	# --- ayudante ---
	var m2 := Mundo.new()
	m2.generar(["CHI"], 4242)
	m2.tomar_el_mando(m2.ligas[0].clubes[0].id)
	var r2 := Roles.new(m2)
	r2.arrancar("ayudante", "Tester")
	print("ayudante: jefe=", r2.jefe_nombre(), " conf=", r2.jefe_confianza(),
		" mercado bloqueado=", r2.mercado_bloqueado() == "ayudante",
		" pizarron de solo lectura=", not r2.puede_alinear(),
		" staff=", r2.puede_contratar_staff(), " construir=", r2.puede_construir())
	# dos temporadas ganando: el jefe le deja el banco
	for i in 70:
		r2.tras_partido(2, 0)
	print("  tras 2 temporadas: rol=", r2.rol, " ascendido=", r2.ayudante_ascendido(),
		" confianza jefe=", r2.jefe_confianza(), " prestigio=", r2.prestigio)

	# --- interino ---
	var m3 := Mundo.new()
	m3.generar(["CHI"], 99)
	var r3 := Roles.new(m3)
	r3.arrancar("interino", "Tester")
	var l3 := m3.liga_de(m3.mi_club())
	var t3 := l3.tabla()
	var pos := 0
	for i in t3.size():
		if t3[i]["club"] == m3.mi_club(): pos = i + 1
	print("interino: club=", m3.mi_club().nombre, " puesto=", pos, "/", t3.size(),
		" fechas=", r3.fechas_interinato_restantes(),
		" mercado cerrado=", r3.mercado_bloqueado() == "interinato",
		" le_pueden_echar=", r3.le_pueden_echar(), " objetivo=", m3.directiva.objetivo)
	for i in 8:
		if l3.quedan_jornadas():
			m3.avanzar_semana()
		r3.tras_jornada()
	print("  tras jugar: interino=", "en curso" if r3.en_interinato() else "resuelto",
		" salvado=", r3.interino.get("salvado"), " prestigio=", r3.prestigio)

	# --- cantera ---
	var m4 := Mundo.new()
	m4.generar(["CHI"], 7)
	m4.tomar_el_mando(m4.ligas[0].clubes[0].id)
	var r4 := Roles.new(m4)
	r4.arrancar("cantera", "Tester")
	print("cantera: meta=", r4.cantera.get("meta"), " alinear=", r4.puede_alinear(),
		" dt=", r4.dt_nombre(), " objetivo=", m4.directiva.objetivo)
	var joven: Jugador = null
	for j in m4.mi_club().plantilla:
		if j.edad <= 21: joven = j
	if joven != null:
		print("  subir=", "'" + r4.subir_al_primer_equipo(joven) + "'", " total=", r4.cantera.get("total"))

	# --- dir / dueño / ascensos ---
	var r5 := Roles.new(m)
	r5.arrancar("dir", "Tester")
	print("dir: alinear=", r5.puede_alinear(), " fichar_perm=", r5.puede_contratar_dt(),
		" echan=", r5.le_pueden_echar(), " cambiar_dt='", r5.cambiar_dt(), "'")
	r5.prestigio = 82
	for i in 12: r5.sumar_trofeo("Liga")
	print("  puede_ascender=", r5.puede_ascender(), " -> '", r5.ascender(), "' rol=", r5.rol,
		" capital='", r5.inyectar_capital(), "' echan=", r5.le_pueden_echar())
	print("  escalon=", r5.siguiente_escalon())

	# --- ofertas y cambio de club ---
	r5.rol = Roles.DT
	r5.quedar_sin_banco()
	var of := r5.ofertas_trabajo()
	print("ofertas=", of.size(), " primera=", of[0].nombre if of.size() > 0 else "-")
	print("  aceptar='", r5.aceptar_trabajo(of[0].id), "' club=", m.mi_club().nombre,
		" sin_club=", r5.sin_club, " historial=", r5.historial.size())

	# --- menu, guardado ---
	print("modos con rol=", Roles.modos_con_rol().size(), " rol_de_modo(jeque)=", Roles.rol_de_modo("jeque"))
	var d := r2.a_dic()
	var r6 := Roles.new(m2)
	r6.desde_dic(d)
	print("guardado: rol=", r6.rol, " prestigio=", r6.prestigio, " trofeos=", r6.trofeos.size(),
		" ascendido=", r6.ayudante_ascendido())
	print("resumen=", r5.resumen())
	get_tree().quit()
