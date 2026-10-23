extends "res://pruebas/banco_p9.gd"
## [Capa 10/27 de `banco.gd`] _probar_negociacion, _probar_consejeros, _probar_bilbao_solo_local, _motor_de_prueba, _probar_dificultad_cpu, _probar_ola_grada

func _probar_negociacion() -> void:
	_titulo("LA MESA DE NEGOCIACIÓN")
	var m := Mundo.new()
	m.generar(["CHI", "ARG", "ESP"], 7373)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio := m.mi_club()
	mio.mover_saldo(300000000)
	var mk := m.mercado

	## Buscar un objetivo claro: alguien de otro club, no del tuyo.
	var objetivo: Jugador = null
	for c: Club in m.clubes.values():
		if c.id != mio.id and not c.plantilla.is_empty():
			objetivo = c.plantilla[0]
			break
	_comprobar(objetivo != null, "hay un objetivo para negociar")
	if objetivo == null:
		return

	var motivo := mk.abrir_negociacion(objetivo)
	_comprobar(motivo == "", "se abre la mesa (%s)" % motivo)
	_comprobar(mk.negociacion != null, "queda una mesa abierta")
	var n := mk.negociacion
	_comprobar(n.pedido == mk.valor_pedido(objetivo), "el pedido inicial coincide con valor_pedido()")
	_comprobar(n.fijo == int(round(float(n.pedido) * 0.7 / 1000.0)) * 1000, "la oferta fija de salida es el 70% del pedido")

	## Ajustes: pct, sueldo, años, fijo se mueven en la direccion pedida.
	var pct_antes := n.pct
	n.ajustar("pct", 1)
	_comprobar(n.pct == pct_antes + 5, "ajustar pct sube de 5 en 5 (%d -> %d)" % [pct_antes, n.pct])
	n.ajustar("pct", -10)
	_comprobar(n.pct == 0, "pct no baja de 0 (%d)" % n.pct)
	var fijo_antes := n.fijo
	n.ajustar("fijo", 1)
	_comprobar(n.fijo > fijo_antes, "ajustar fijo al alza sube el fijo")
	var anios_antes := n.anios
	n.ajustar("anios", 1)
	_comprobar(n.anios == anios_antes + 1, "ajustar anios suma de a uno")

	## Con una oferta a proposito muy baja, el club pide mas -no cierra a la primera.
	n.fijo = 1000
	n.cuotas = 0; n.bonos = 0; n.pct = 0; n.opaco = 0
	var r1 := n.enviar_oferta()
	_comprobar(String(r1.get("tipo", "")) in ["club_pide_mas", "rival_traspaso", "rota"], "una oferta muy baja no cierra (%s)" % String(r1.get("tipo", "")))
	_comprobar(n.ronda >= 2 or n.estado != "abierta", "la ronda avanza o la mesa se corta")

	## Se abandona y se abre una mesa nueva, esta vez generosa de verdad, hasta
	## que cierre o se agote un limite de intentos -hay azar de por medio: rival
	## que se lleva el fichaje, o el jugador que pide mas rondas-.
	mk.cerrar_negociacion()
	_comprobar(mk.negociacion == null, "cerrar_negociacion vacía la mesa")

	var cerrado := false
	var intentos_apertura := 0
	while not cerrado and intentos_apertura < 12:
		intentos_apertura += 1
		## Otro objetivo cada vez, por si el anterior quedo con "no_negociar_hasta"
		## o se lo llevo un rival.
		var obj2: Jugador = null
		for c2: Club in m.clubes.values():
			if c2.id != mio.id and not c2.plantilla.is_empty():
				var candidato: Jugador = c2.plantilla[Azar.ent(0, c2.plantilla.size() - 1)]
				if candidato.club_id != mio.id and (candidato.no_negociar_hasta == 0 or m.semana >= candidato.no_negociar_hasta):
					obj2 = candidato
					break
		if obj2 == null:
			break
		if mk.abrir_negociacion(obj2) != "":
			continue
		var n2 := mk.negociacion
		## Oferta generosa: fijo por encima del pedido, ficha por encima de lo
		## que pediria, prima de cuatro semanas -respuestaDelJugador() la exige
		## para dar puntos extra-, y un contrato de tres temporadas.
		n2.fijo = int(float(n2.pedido) * 1.05)
		n2.sueldo = int(float(n2.sueldo) * 1.5)
		n2.firma = n2.sueldo * 5
		for intento_ronda in 8:
			var res := n2.enviar_oferta()
			var tipo := String(res.get("tipo", ""))
			if tipo == "cerrado":
				cerrado = true
				var jugador_fichado := obj2
				_comprobar(jugador_fichado.club_id == mio.id, "el fichado pasa a ser tuyo")
				_comprobar(mio.plantilla.has(jugador_fichado), "aparece en tu plantilla")
				_comprobar(m.vestuario.rol_plantel(jugador_fichado) == n2.rol, "el rol pactado queda escrito en Vestuario")
				_comprobar(jugador_fichado.anios_contrato == n2.anios, "los anios pactados quedan escritos")
				break
			elif tipo in ["rota", "rival_traspaso", "rival_firma", "jugador_rota", "cerrada"]:
				break
			## club_pide_mas o jugador_no: se sigue insistiendo con la misma oferta generosa.
	_comprobar(cerrado, "una oferta generosa termina cerrando un fichaje en un numero razonable de intentos")

	## Cuotas, bonos, porcentaje y clausula: se pactan de verdad a traves de
	## Cesiones.registrar_compromisos(), no con una copia propia de esa logica.
	var obj3: Jugador = null
	for c3: Club in m.clubes.values():
		if c3.id != mio.id and not c3.plantilla.is_empty():
			obj3 = c3.plantilla[0]
			break
	if obj3 != null and mk.abrir_negociacion(obj3) == "":
		var n3 := mk.negociacion
		n3.fijo = int(float(n3.pedido) * 1.1)
		n3.cuotas = 500000
		n3.bonos = 300000
		n3.pct = 20
		n3.clausula = true
		n3.sueldo = int(float(n3.sueldo) * 1.6)
		n3.firma = n3.sueldo * 5
		var cerrado3 := false
		for intento3 in 10:
			var res3 := n3.enviar_oferta()
			var tipo3 := String(res3.get("tipo", ""))
			if tipo3 == "cerrado":
				cerrado3 = true
				var hay_cuota := false
				for cu: Dictionary in m.cesiones.cuotas:
					if String(cu.get("jugador", "")) == obj3.nombre:
						hay_cuota = true
				_comprobar(hay_cuota, "las cuotas pactadas quedan registradas en Cesiones")
				_comprobar(m.cesiones.bonos.has(obj3.id), "el bono pactado queda registrado en Cesiones")
				_comprobar(m.cesiones.clausula_de(obj3) > 0, "la clausula pactada queda registrada en Cesiones")
				var pend := m.cesiones.porcentaje_pendiente(obj3.id)
				_comprobar(not pend.is_empty() and int(pend.get("pct", 0)) == 20, "el 20%% de venta futura queda pactado en Cesiones")
				## Cesiones.movimiento lleva escrito desde hace tiempo y nadie lo
				## escuchaba: se conecta ahora en tomar_el_mando(), directo al
				## libro de Mundo -sin pantalla de por medio-.
				_comprobar(not m.libro_financiero.is_empty(), "los pagos de la mesa quedan anotados en el libro financiero (%d)" % m.libro_financiero.size())
				break
			elif tipo3 in ["rota", "rival_traspaso", "rival_firma", "jugador_rota", "cerrada"]:
				break
		if not cerrado3:
			_linea("  (esta mesa en particular no cerro por azar -rival o jugador-, no se prueban cuotas/bonos/pct/clausula esta vez)")

func _probar_consejeros() -> void:
	_titulo("CONSEJEROS DEL DIRECTORIO")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 5151)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio := m.mi_club()
	var d := m.directiva

	## Sin caja, no se puede contratar.
	mio.saldo = 0
	var motivo := d.alternar_consejero("dep")
	_comprobar(motivo != "" and not d.tiene_consejero("dep"), "sin caja no se contrata un consejero (%s)" % motivo)

	mio.mover_saldo(5000000)
	_comprobar(d.alternar_consejero("dep") == "", "se contrata al consejero deportivo")
	_comprobar(d.tiene_consejero("dep"), "queda contratado")
	_comprobar(d.honorarios_semanales() == Directiva.HONORARIO_CONSEJERO_SEMANAL, "el honorario semanal cuenta un asiento (%d)" % d.honorarios_semanales())

	_comprobar(d.alternar_consejero("mkt") == "", "se contrata al consejero de marketing")
	_comprobar(d.consejeros.size() == 2, "hay dos consejeros a la vez")
	var lleno := d.alternar_consejero("leg")
	_comprobar(lleno != "" and not d.tiene_consejero("leg"), "no cabe un tercer consejero (%s)" % lleno)
	_comprobar(d.honorarios_semanales() == Directiva.HONORARIO_CONSEJERO_SEMANAL * 2, "el honorario cuenta los dos asientos")

	## dep: afina la niebla de ojeo en TODO el mundo, no solo en paises cubiertos.
	var rival: Jugador = null
	for c: Club in m.clubes.values():
		if c.id != mio.id and c.pais != mio.pais and not c.plantilla.is_empty():
			rival = c.plantilla[0]
			break
	if rival != null:
		var nivel_con := m.ojeadores.nivel_de(rival)
		d.alternar_consejero("dep")   ## lo cesa
		var nivel_sin := m.ojeadores.nivel_de(rival)
		_comprobar(nivel_con - nivel_sin > 0.35 and nivel_con - nivel_sin < 0.45, "el consejero deportivo suma 0.4 al nivel de ojeo en cualquier pais (%.2f vs %.2f)" % [nivel_con, nivel_sin])
		d.alternar_consejero("dep")   ## lo vuelve a contratar para lo que sigue

	## mkt: +10% en patrocinio.
	var sin_mkt := Finanzas.new(mio).patrocinio()
	var con_mkt := Finanzas.new(mio, 0.0, 0, 0.1).patrocinio()
	_comprobar(con_mkt > sin_mkt and con_mkt <= int(round(float(sin_mkt) * 1.1)) + 1, "el consejero de marketing sube el patrocinio un 10%% (%d vs %d)" % [sin_mkt, con_mkt])

	## Cesar libera el asiento y deja de cobrar honorario.
	_comprobar(d.alternar_consejero("mkt") == "", "se cesa al consejero de marketing")
	_comprobar(not d.tiene_consejero("mkt"), "el asiento queda libre")
	_comprobar(d.honorarios_semanales() == Directiva.HONORARIO_CONSEJERO_SEMANAL, "el honorario baja a un solo asiento")

	## EMBAJADOR DEL CLUB: reutiliza Cantera.leyendas, sembradas al generar.
	_comprobar(m.cantera != null and not m.cantera.leyendas.is_empty(), "hay leyendas sembradas para elegir embajador")
	var candidatas := Directiva.candidatas_embajador(m.cantera.leyendas, m.anio)
	_comprobar(not candidatas.is_empty(), "candidatas_embajador() devuelve al menos una terna (%d)" % candidatas.size())
	var candidatas2 := Directiva.candidatas_embajador(m.cantera.leyendas, m.anio)
	_comprobar(candidatas[0]["nombre"] == candidatas2[0]["nombre"], "las candidatas son deterministas para el mismo año")

	var elegido: Dictionary = candidatas[0]
	var costo_emb := 400000 + int(elegido.get("nivel", 80)) * 8000
	mio.saldo = 0
	_comprobar(d.contratar_embajador(elegido) != "", "sin caja no se puede fichar al embajador")
	mio.mover_saldo(costo_emb + 1000000)
	var saldo_antes := mio.saldo
	_comprobar(d.contratar_embajador(elegido) == "", "se ficha al embajador")
	_comprobar(not d.embajador.is_empty() and String(d.embajador["nombre"]) == String(elegido["nombre"]), "queda registrado con su nombre")
	_comprobar(mio.saldo == saldo_antes - costo_emb, "el fichaje cobra el costo exacto, nivel incluido (%d)" % costo_emb)

	var socios_antes := mio.socios
	m.avanzar_semana()
	_comprobar(mio.socios >= socios_antes + Directiva.SOCIOS_POR_SEMANA_EMBAJADOR, "el embajador suma socios cada semana (%d -> %d)" % [socios_antes, mio.socios])

	_comprobar(d.cesar_embajador() == "", "se cesa al embajador -hay caja para el finiquito-")
	_comprobar(d.embajador.is_empty(), "el puesto queda vacante")

	## El entrenador empleado tambien cobra -"G.rol!=='dt'&&G.dtEmp" del HTML-,
	## y solo cuando no diriges tu mismo. Se comprueba el asiento en el libro
	## financiero, no la caja total, porque un mes entero de partidos mueve la
	## caja por mil motivos a la vez.
	var m2 := Mundo.new()
	m2.generar(["CHI"], 8181)
	m2.tomar_el_mando(m2.ligas[0].clubes[1].id)
	m2.mi_club().mover_saldo(50000000)
	_comprobar(m2.roles.dt_empleado.is_empty(), "de entrenador (dt) todavia no hay a quien pagarle")
	m2.roles.rol = Roles.DIR
	m2.roles.call("_contratar_dt_empleado")
	for s in Finanzas.SEMANAS_DEL_MES:
		m2.avanzar_semana()
	var hay_sueldo_dt := false
	for mov: Dictionary in m2.libro_financiero:
		if String(mov.get("concepto", "")).begins_with("Sueldo del entrenador"):
			hay_sueldo_dt = true
			_comprobar(int(mov["monto"]) == -Roles.SUELDO_SEMANAL_DT_EMPLEADO * Finanzas.SEMANAS_DEL_MES,
				"el sueldo mensual del entrenador empleado es el correcto (%d)" % int(mov["monto"]))
	_comprobar(hay_sueldo_dt, "siendo director, el entrenador empleado cobra su sueldo al cierre de mes")

## "EL ATHLETIC CLUB DE BILBAO SOLO FICHA JUGADORES DE ESPAÑA" (22-9-2026,
## pedido directo del usuario). El club SÍ existe en el juego (`Ath. Bilbao`
## en `PAISES_LIGAS.ESP`, en leetspeak en la tabla -"B1lbao"-, por eso una
## búsqueda literal de "Bilbao" no lo encontraba la primera vez). La regla
## real (cantera vasca) no se puede portar literal -`Jugador` solo trackea
## `pais`, nunca ciudad/región-, así que se aproxima por "mismo país" (ESP).
## `Mercado._buscar_objetivo()` ahora salta cualquier candidato que no sea de
## España cuando el comprador es Bilbao (`Mercado.CLUBES_SOLO_MISMO_PAIS`).
##
## Mundo PROPIO, aislado -no reusa `m1`/`m2` de otra función, ni genera un
## tercer mundo dentro de una función ajena, la misma trampa que ya colgó el
## banco tres veces con la prueba de apellidos por país (ver esa sección de
## `LEEME.md`).
func _probar_bilbao_solo_local() -> void:
	_titulo("ATHLETIC BILBAO: SOLO FICHA DE ESPAÑA")
	var m := Mundo.new()
	m.generar(["ESP"], 4711)
	var bilbao: Club = null
	for c: Club in m.clubes.values():
		if Nombres.limpiar(c.nombre) == "Ath. Bilbao":
			bilbao = c
			break
	if bilbao == null:
		_comprobar(false, "Ath. Bilbao existe en PAISES_LIGAS.ESP")
		return
	var extranjeros_antes := 0
	for j in bilbao.plantilla:
		if j.pais != bilbao.pais:
			extranjeros_antes += 1
	## 100 semanas de mercado de la IA -bastante para que, sin la regla, le
	## hubiera entrado al menos un extranjero de los otros 15 clubes de la
	## liga (`mover(6)` sortea 6 compradores por semana entre TODOS los
	## clubes del mundo, Bilbao incluido con probabilidad real).
	for semana in 100:
		m.mercado.mover(6)
	var extranjeros_despues := 0
	for j in bilbao.plantilla:
		if j.pais != bilbao.pais:
			extranjeros_despues += 1
	_comprobar(extranjeros_despues <= extranjeros_antes,
		"100 semanas de mercado IA no le suman extranjeros a Bilbao (antes %d, después %d)" % [
			extranjeros_antes, extranjeros_despues])

## FÍSICA DEL MOTOR SIN PANTALLA (20-10-2026): 40 s de juego con el motor real,
## medidos como la sonda de física (cada 1/30 s, dos pasos de 1/60). Guarda lo
## arreglado el 19-10: nadie a más de 10,5 m/s, ningún giro de más de 720°/s,
## casi ningún tirón > 25 m/s² y el balón sin saltos en juego.
## Un motor real sin pantalla con dos equipos de la liga chilena, para las
## pruebas del partido (mini bancos). Devuelve [motor, raíz, balón].
func _motor_de_prueba(semilla := 7) -> Array:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var ball := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	var motor := MotorJugable.new()
	raiz.add_child(motor)
	motor.set_physics_process(false)
	motor.autopiloto = true
	motor.preparar(lista, ball, "", semilla)
	return [motor, raiz, ball]

## DIFICULTAD DE LA CPU (20-10-2026): solo toca al equipo de la CPU, y
## «profesional» deja el motor como siempre.
func _probar_dificultad_cpu() -> void:
	_titulo("DIFICULTAD DE LA CPU")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var raiz: Node3D = r[1]
	var cpu: Dictionary = {}
	var mio: Dictionary = {}
	for p: Dictionary in motor.jugadores:
		if not bool(p["por"]):
			if bool(p["es_local"]) and mio.is_empty():
				mio = p
			elif not bool(p["es_local"]) and cpu.is_empty():
				cpu = p
	var puro := float(cpu["attr_puro"]["pas"])
	_comprobar(motor.equipo_cpu() == -1 and is_equal_approx(float(cpu["attr"]["pas"]), puro), "sin nadie al mando no hay CPU que ajustar")
	motor.control_equipo = 0
	motor.fijar_dificultad("leyenda")
	_comprobar(motor.equipo_cpu() == 1, "manejando al local, la CPU es la visita")
	_comprobar(float(cpu["attr"]["pas"]) > puro, "en Leyenda la CPU pasa mejor (%.2f > %.2f)" % [float(cpu["attr"]["pas"]), puro])
	_comprobar(is_equal_approx(float(mio["attr"]["pas"]), float(mio["attr_puro"]["pas"])), "y tus jugadores no cambian")
	_comprobar(motor._tac(false, "presion") == 2, "y presiona más")
	motor.fijar_dificultad("principiante")
	_comprobar(float(cpu["attr"]["pas"]) < puro and motor._tac(false, "presion") == 0, "en Principiante, peor y presiona menos")
	motor.fijar_dificultad("profesional")
	_comprobar(is_equal_approx(float(cpu["attr"]["pas"]), puro) and motor._tac(false, "presion") == 1, "Profesional = el motor de siempre")
	## M-098: la cabeza sigue al balón (un modificador por jugador).
	_comprobar(MiradaBalon.poner(motor.jugadores, motor.balon) == motor.jugadores.size()
		and MiradaBalon.poner(motor.jugadores, motor.balon) == 0, "M-098: un LookAt en la cabeza de cada jugador, sin duplicar")
	## M-073: el capitán (y solo él) lleva el brazalete.
	var con_brazalete := [0, 0]
	var capitan_en_once := [false, false]
	for p: Dictionary in motor.jugadores:
		var eq := 0 if bool(p["es_local"]) else 1
		if bool((p.get("jugador", {}) as Dictionary).get("capitan", false)):
			capitan_en_once[eq] = true
		var lleva := false
		for mi in (p["node"] as Node).find_children("*", "MeshInstance3D", true, false):
			for k in (mi as MeshInstance3D).get_surface_override_material_count():
				var mt := (mi as MeshInstance3D).get_surface_override_material(k)
				if mt is ShaderMaterial and (mt as ShaderMaterial).get_shader_parameter("acc_brazalete") is Color \
						and ((mt as ShaderMaterial).get_shader_parameter("acc_brazalete") as Color).a > 0.5:
					lleva = true
		if lleva:
			con_brazalete[eq] += 1
	_comprobar(con_brazalete[0] == (1 if capitan_en_once[0] else 0) and con_brazalete[1] == (1 if capitan_en_once[1] else 0),
		"M-073: brazalete solo en el capitán (%s; capitán en el once %s)" % [str(con_brazalete), str(capitan_en_once)])
	_comprobar(capitan_en_once == [true, true], "M-073: cada equipo sale con un capitán (o el que hereda la cinta)")
	## M-127: gestión del tiempo al final (el que gana tarda, el que pierde corre).
	motor.control_equipo = -1
	motor.mitad = 2
	motor.t = motor.dur_mitad() * 0.85
	motor.goles = [1, 0]
	var loc_p: Dictionary = {}
	var vis_p: Dictionary = {}
	for p: Dictionary in motor.jugadores:
		if bool(p["es_local"]) and loc_p.is_empty():
			loc_p = p
		elif not bool(p["es_local"]) and vis_p.is_empty():
			vis_p = p
	_comprobar(motor.minuto() >= 75 and motor._ritmo_de_saque(loc_p) > 1.0 and motor._ritmo_de_saque(vis_p) < 1.0,
		"M-127: al %d' el que gana se toma su tiempo y el que pierde saca rápido" % motor.minuto())
	motor.control_equipo = 0
	_comprobar(is_equal_approx(motor._ritmo_de_saque(loc_p), 1.0), "M-127: el equipo del usuario no pierde tiempo solo")
	## M-119: en la tanda el portero se tira más al lado natural del pie del que patea.
	var cuenta := {-1: 0, 0: 0, 1: 0}
	motor.vel_balon = Vector3.ZERO
	for _i in 600:
		cuenta[motor._lado_portero_tanda(loc_p, vis_p)] += 1
	var nat := -1 if AnimExtra.es_zurdo(String(loc_p.get("id", ""))) else 1
	_comprobar(int(cuenta[nat]) > int(cuenta[-nat]) and int(cuenta[0]) > 0, "M-119: el portero lee el pie del lanzador (%s, natural %d)" % [str(cuenta), nat])
	raiz.queue_free()

## VALLAS LED EN MULTIMESH (20-10-2026): menos llamadas de dibujo y la misma
## animación (anuncios que cambian y el anillo del gol).
## M-036/044 (20-10): la ola y la onda escriben su reloj en el público y lo apagan.
func _probar_ola_grada() -> void:
	print("\n--- La ola y la onda de la grada ---")
	var raiz := Node3D.new()
	add_child(raiz)
	var mmi := MultiMeshInstance3D.new()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://visor/hinchada.gdshader")
	mmi.material_override = mat
	raiz.add_child(mmi)
	var otro := MultiMeshInstance3D.new()
	otro.material_override = mat
	raiz.add_child(otro)
	_comprobar(OlaGrada.materiales(raiz).size() == 1, "ola: el material compartido se cuenta una vez")
	var ola := OlaGrada.lanzar(raiz, "ola")
	_comprobar(ola != null and float(mat.get_shader_parameter("ola_edad")) == 0.0, "ola: arranca con el reloj en 0")
	ola._process(1.5)
	_comprobar(is_equal_approx(float(mat.get_shader_parameter("ola_edad")), 1.5), "ola: el reloj avanza en el material")
	ola._process(OlaGrada.DURA_OLA)
	_comprobar(float(mat.get_shader_parameter("ola_edad")) < 0.0, "ola: al terminar queda apagada (-1)")
	var onda := OlaGrada.lanzar(raiz, "onda", Vector3(0, 0, 62))
	_comprobar(onda != null and (mat.get_shader_parameter("onda_centro") as Vector3).z == 62.0, "onda: sale del fondo del gol")
	onda.free()
	_comprobar(float(mat.get_shader_parameter("onda_edad")) < 0.0, "onda: si se corta, también se apaga")
	var pro := OlaGrada.lanzar(raiz, "protesta")
	_comprobar(pro != null and float(mat.get_shader_parameter("protesta_edad")) == 0.0 and pro._dura == OlaGrada.DURA_PROTESTA, "protesta: de pie unos segundos")
	pro.free()
	OlaGrada.mirar(raiz, Vector3(3, 0, -7))
	_comprobar((mat.get_shader_parameter("balon_pos") as Vector3) == Vector3(3, 0, -7) and float(mat.get_shader_parameter("mira_balon")) == 1.0, "grada: sigue el balón con la cabeza")
	OlaGrada.piel_de_pais(raiz, "ARG")
	var s_arg := float(mat.get_shader_parameter("piel_sesgo"))
	OlaGrada.piel_de_pais(raiz, "BRA")
	_comprobar(s_arg > float(mat.get_shader_parameter("piel_sesgo")), "grada: la piel depende del país (ARG más clara que BRA)")
	_comprobar(OlaGrada.lanzar(Node3D.new(), "ola") == null, "ola: sin público no hace nada")
	raiz.free()
