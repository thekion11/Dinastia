extends "res://pruebas/banco/guardado_p2_s.gd"
## [Capa 2/3 de `guardado.gd`] _probar_guardado_1


## [Capa 12/27 de `banco.gd`] _probar_guardado_1

## Tramo 1 de 2 de `_probar_guardado` (la norma de 450 líneas la troceó).
func _probar_guardado_1() -> Array:
	_titulo("GUARDAR Y CARGAR")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 777)
	m.tomar_el_mando(m.ligas[0].clubes[3].id)
	_gb_club_y_once(m)
	_gb_tienda(m)
	_gb_mentorias(m)
	_gb_bono(m)
	_gb_proyeccion(m)
	_g1_01_la_hinchada_cinco_segmento(m)
	_g1_02_las_directrices_al_entrena(m)
	_g1_03_los_roles_tacticos_el_sist(m)
	_g1_04_las_arengas_lo_que_hay_que(m)
	_g1_05_las_jugadas_ensayadas_y_lo(m)
	_g1_06_la_deuda_vbanco_es_el_unic(m)
	_g1_07_el_horario_del_partido_lo_(m)
	_g1_08_los_juegos_mentales_dos_ba(m)
	_g1_09_la_charla_del_entretiempo_(m)
	_g1_10_lo_que_lee_la_ficha_del_ju(m)
	## LOS ROLES PROMETIDOS: lo que se prueba es que NO es un desplegable tonto.
	## Si `acepta_rol()` dejara pasar cualquier cosa, prometer seria gratis y el
	## sistema entero sobraria.

	var v_rp := m.vestuario
	return [m, v_rp]

func _gb_club_y_once(m: Mundo) -> void:
	## Se toca el estado de los sistemas nuevos para que el guardado tenga algo
	## que conservar: uno recien creado se parece a cualquier otro recien creado.
	m.staff.subir("ayudante", m.mi_club())
	m.staff.subir("medico", m.mi_club())
	## Los cuatro interruptores tacticos: se guardaban... no, no se guardaban.
	## Se activaban, movian el partido, y volvian a false en cada carga sin
	## avisar. Se marcan dos si y dos no para que la prueba distinga entre
	## "vuelve el valor" y "vuelve el valor por defecto".
	m.mi_club().tactica.salida_corta = true
	m.mi_club().tactica.tiro_lejano = true
	m.mi_club().tactica.marca_al_hombre = false
	m.mi_club().tactica.fuera_de_juego = false
	## Un once a mano, para comprobar que sobrevive: los once primeros del plantel.
	var once_a_mano: Array[Jugador] = []
	for n in 11:
		once_a_mano.append(m.mi_club().plantilla[n])
	m.mi_club().fijar_once(once_a_mano)

func _gb_tienda(m: Mundo) -> void:
	## La tienda: se lanza una linea y se comprueba que rinde y que sobrevive.
	var sin_tienda := m.ingreso_tienda(m.mi_club())
	_comprobar(sin_tienda == 0, "sin lineas lanzadas la tienda no da nada (%d)" % sin_tienda)
	var err_t := m.alternar_tienda("buf", m.mi_club())
	_comprobar(err_t == "", "se lanza una linea de tienda (%s)" % err_t)
	_comprobar(m.ingreso_tienda(m.mi_club()) > 0, "y ya rinde todos los meses (%d)" % m.ingreso_tienda(m.mi_club()))

func _gb_mentorias(m: Mundo) -> void:
	## MENTORIAS: un veterano apadrina a un chico y el chico crece mas rapido.
	var maestro: Jugador = null
	var pupilo: Jugador = null
	for j in m.mi_club().plantilla:
		if maestro == null and m.entrenamiento.puede_ser_mentor(j):
			maestro = j
		elif pupilo == null and m.entrenamiento.puede_ser_pupilo(j):
			pupilo = j
	if maestro != null and pupilo != null:
		var moral_antes := pupilo.moral
		_comprobar(m.entrenamiento.crear_mentoria(maestro, pupilo) == "", "se crea una mentoria")
		_comprobar(pupilo.moral > moral_antes, "al pupilo le sube la moral al ser apadrinado (%d -> %d)" % [moral_antes, pupilo.moral])
		_comprobar(m.entrenamiento.mentorias.size() == 1, "queda registrada")
		_comprobar(not m.entrenamiento.puede_ser_pupilo(pupilo), "y ya no se le puede apadrinar dos veces")

func _gb_bono(m: Mundo) -> void:
	## EL BONO AL CUERPO TECNICO: una vez por temporada, y sube mas si vas bien.
	## Se parte de cero A PROPOSITO: este mundo ya trae staff contratado de
	## pruebas anteriores, y sin limpiarlo la primera comprobacion -"sin cuerpo
	## tecnico no hay bono"- pasaba de largo repartiendolo de verdad, dejando el
	## ano marcado y haciendo fallar a las tres siguientes.
	m.staff.niveles.clear()
	m.staff.anio_bono = 0
	var r_bono_sin := m.staff.repartir_bono(m.mi_club(), m.anio, 1, 16)
	_comprobar(r_bono_sin.has("error"), "sin cuerpo tecnico no hay bono que repartir")
	m.staff.subir("ayudante", m.mi_club())
	m.mi_club().mover_saldo(50000000)
	var moral_antes_b := m.mi_club().plantilla[0].moral
	var r_bono := m.staff.repartir_bono(m.mi_club(), m.anio, 1, 16)
	_comprobar(r_bono.has("ok"), "con cuerpo tecnico se reparte el bono")
	_comprobar(int(r_bono.get("moral", 0)) == 5, "yendo primero sube 5 de moral (%d)" % int(r_bono.get("moral", 0)))
	_comprobar(m.mi_club().plantilla[0].moral > moral_antes_b, "y la moral del plantel sube de verdad")
	_comprobar(m.staff.repartir_bono(m.mi_club(), m.anio, 1, 16).has("error"), "no se puede repartir dos veces el mismo ano")

func _gb_proyeccion(m: Mundo) -> void:
	## LA PROYECCION ANUAL: la contabilidad del ejercicio. No inventa cifras,
	## multiplica lo que ya cobra y paga `mes()`, asi que lo que se comprueba es
	## que cuadre consigo misma y que la masa salarial salga en un rango creible.
	var fin := Finanzas.new(m.mi_club(), 0.0, 0, 0.0)
	var proy := fin.proyeccion_anual(15, 0)
	var suma_ing := 0
	for k: String in proy["ingresos"]:
		suma_ing += int(proy["ingresos"][k])
	_comprobar(suma_ing == int(proy["total_ingresos"]), "los ingresos del ejercicio suman el total (%d)" % suma_ing)
	_comprobar(int(proy["resultado"]) == int(proy["total_ingresos"]) - int(proy["total_gastos"]),
		"el resultado es ingresos menos gastos")
	_linea("  ejercicio: entran %d, salen %d, resultado %d, masa salarial %d%%" % [
		int(proy["total_ingresos"]), int(proy["total_gastos"]), int(proy["resultado"]), int(proy["pct_salarial"])])
	_comprobar(int(proy["pct_salarial"]) > 5 and int(proy["pct_salarial"]) < 200,
		"la masa salarial sobre ingresos sale en un rango creible (%d%%)" % int(proy["pct_salarial"]))
