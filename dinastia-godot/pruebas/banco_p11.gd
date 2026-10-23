extends "res://pruebas/banco_p10.gd"
## (Parte 11 de 25 de `banco.gd`.)

func _probar_vallas_led() -> void:
	_titulo("VALLAS LED EN MULTIMESH")
	var raiz := Node3D.new()
	add_child(raiz)
	var led := VallasLed.new()
	raiz.add_child(led)
	led.sembrar([{"texto": "UNO", "fondo": Color(0.9, 0.1, 0.1), "tinta": Color.WHITE},
		{"texto": "DOS", "fondo": Color(0.1, 0.1, 0.9), "tinta": Color.WHITE}])
	for i in 4:
		var caja := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.25, 1.1, 5.75) if i < 2 else Vector3(5.75, 1.1, 0.25)
		caja.mesh = bm
		caja.position = Vector3(i * 6.0, 0.55, 0)
		led.add_child(caja)
		var l := Label3D.new()
		led.add_child(l)
		led.registrar(caja, l, i)
	led._process(0.016)
	var mmis := led.find_children("Paneles*", "MultiMeshInstance3D", false, false)
	_comprobar(mmis.size() == 2, "laterales y fondos en dos MultiMesh (%d)" % mmis.size())
	var p0: Dictionary = led._paneles[0]
	_comprobar(p0.has("mm") and p0.get("caja") == null, "las cajas sueltas se quitan")
	var antes: Color = p0.get("color", Color.BLACK)
	led._process(VallasLed.SEG + 0.1)
	_comprobar(Color(p0.get("color", Color.BLACK)) != antes, "al cambiar el anuncio cambia el color del panel")
	led.evento(["GOL"], Color(1, 0.8, 0), Color(0, 0.4, 0))
	led._process(0.4)
	var c: Color = p0.get("color", Color.BLACK)
	var club := [Color(1, 0.8, 0).srgb_to_linear(), Color(0, 0.4, 0).srgb_to_linear()]
	_comprobar(c.a > 0.3 and (Color(c.r, c.g, c.b).is_equal_approx(Color(club[0].r, club[0].g, club[0].b))
		or Color(c.r, c.g, c.b).is_equal_approx(Color(club[1].r, club[1].g, club[1].b))), "en el gol el panel brilla con los colores del club (%s)" % str(c))
	raiz.queue_free()

## FALTAS POR PUNTOS (20-10-2026, vídeo del dueño): jugadas preparadas.
func _probar_faltas_puntos() -> void:
	_titulo("FALTAS POR PUNTOS")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var raiz: Node3D = r[1]
	var loc: Array = []
	var vis: Array = []
	for p: Dictionary in motor.jugadores:
		if bool(p["por"]):
			continue
		(loc if bool(p["es_local"]) else vis).append(p)
	var atacante: Dictionary = loc[0]
	var defensa: Dictionary = vis[0]
	var arco := motor._arco_rival(atacante)
	var d := signf(arco.z)
	## Todos los demás lejos, a la espalda del atacante (no tapan el arco).
	for i in range(1, loc.size()):
		(loc[i]["node"] as Node3D).position = Vector3(-30 + i * 3, 0, -d * 45.0)
	for i in range(1, vis.size()):
		(vis[i]["node"] as Node3D).position = Vector3(-30 + i * 3, 0, -d * 48.0)
	## 1) Mano a mano: el 9 corre hacia el arco a 20 m; el último defensa llega
	## por detrás, lanzado, en plancha → roja directa.
	(atacante["node"] as Node3D).position = Vector3(0, 0, arco.z - d * 20.0)
	atacante["vel"] = Vector3(0, 0, d * 7.0)
	(defensa["node"] as Node3D).position = Vector3(0, 0, arco.z - d * 21.5)
	defensa["vel"] = Vector3(0, 0, d * 7.5)
	var pf := motor.puntos_falta(defensa, atacante, "deslizante")
	_comprobar((pf["factores"] as Array).has("por_detras") and (pf["factores"] as Array).has("gran_velocidad")
		and (pf["factores"] as Array).has("profesional"), "por detrás + a gran velocidad + último hombre (%s)" % str(pf["factores"]))
	_comprobar(float(pf["puntos"]) >= MotorJugable.UMBRAL_ROJA, "suma de roja directa (%.1f)" % float(pf["puntos"]))
	## 2) De frente, sin velocidad y con compañeros cubriendo: carga de hombro.
	(atacante["node"] as Node3D).position = Vector3(10, 0, 0)
	atacante["vel"] = Vector3(0, 0, d * 2.0)
	(defensa["node"] as Node3D).position = Vector3(10, 0, d * 1.0)
	defensa["vel"] = Vector3(0, 0, -d * 1.0)
	(vis[1]["node"] as Node3D).position = Vector3(10, 0, d * 12.0)
	var pf2 := motor.puntos_falta(defensa, atacante, "hombro")
	_comprobar(float(pf2["puntos"]) < MotorJugable.UMBRAL_AMARILLA, "carga de hombro de frente: solo falta (%.1f, %s)" % [float(pf2["puntos"]), str(pf2["factores"])])
	## 3) La falta de verdad: con tarjetas reales, la roja directa expulsa.
	motor.tarjetas_reales = true
	(atacante["node"] as Node3D).position = Vector3(0, 0, arco.z - d * 20.0)
	atacante["vel"] = Vector3(0, 0, d * 7.0)
	(defensa["node"] as Node3D).position = Vector3(0, 0, arco.z - d * 21.5)
	defensa["vel"] = Vector3(0, 0, d * 7.5)
	(vis[1]["node"] as Node3D).position = Vector3(-30, 0, -d * 48.0)
	var antes := motor.jugadores.size()
	var an0 := float(motor.anadido[motor.mitad - 1]) if motor.mitad >= 1 and motor.anadido.size() >= motor.mitad else -1.0
	motor._falta(defensa, atacante, 0.25, "", "deslizante")
	var an1 := float(motor.anadido[motor.mitad - 1]) if an0 >= 0.0 else -1.0
	_comprobar(an0 >= 0.0 and an1 > an0, "M-139: la entrada dura suma añadido (%.2f → %.2f)" % [an0, an1])
	_comprobar(String(motor.ultima_falta.get("sancion", "")) == "roja", "se pita roja directa (%s)" % str(motor.ultima_falta))
	_comprobar(String(defensa.get("anim_actual", "")) in ["discutir_arbitro", "protestar"], "M-105: el amonestado protesta al árbitro (%s)" % String(defensa.get("anim_actual", "")))
	_comprobar(motor.jugadores.size() == antes - 1 or bool(defensa.get("expulsado", false)), "y el infractor se va del campo")
	## M-107: el juez de línea va a la altura del penúltimo defensor.
	var def_mas: Array = []
	for p: Dictionary in motor.jugadores:
		if signf(motor._arco_propio(p).z) > 0.0:
			def_mas.append(p)
	for i in def_mas.size():
		(def_mas[i]["node"] as Node3D).position = Vector3(float(i) * 2.0 - 10.0, 0, 5.0)
	(def_mas[0]["node"] as Node3D).position = Vector3(0, 0, 51.0)
	(def_mas[1]["node"] as Node3D).position = Vector3(5, 0, 33.0)
	_comprobar(is_equal_approx(motor.linea_fuera_de_juego(1.0), 33.0), "M-107: la línea del fuera de juego es la del penúltimo (%.1f)" % motor.linea_fuera_de_juego(1.0))
	raiz.queue_free()

func _probar_fisica_motor() -> void:
	_titulo("FÍSICA DEL MOTOR (SIN PANTALLA)")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var raiz: Node3D = r[1]
	var ball: Node3D = r[2]
	var prev := {}
	var vprev := {}
	var rprev := {}
	var bprev := Vector3.INF
	var c := {"vel": 0, "giro": 0, "tiron": 0, "tele": 0, "muestras": 0}
	var dt := 1.0 / 30.0
	for _f in 1200:
		motor.paso(dt * 0.5)
		motor.paso(dt * 0.5)
		for p: Dictionary in motor.jugadores:
			var nd: Node3D = p["node"]
			var id := nd.get_instance_id()
			var pa := nd.position
			c["muestras"] += 1
			if prev.has(id):
				var vel: Vector3 = (pa - prev[id]) / dt
				vel.y = 0.0
				if vel.length() > 10.5:
					c["vel"] += 1
				if vprev.has(id) and (vel - (vprev[id] as Vector3)).length() / dt > 25.0 and vel.length() < 10.5:
					c["tiron"] += 1
				vprev[id] = vel
			if rprev.has(id) and absf(wrapf(nd.rotation.y - float(rprev[id]), -PI, PI)) / dt > deg_to_rad(720.0):
				c["giro"] += 1
			prev[id] = pa
			rprev[id] = nd.rotation.y
		var pb := ball.position
		if bprev != Vector3.INF and pb.distance_to(bprev) > 1.2 and motor.estado == "juego":
			c["tele"] += 1

		bprev = pb
	print("   · física: %s" % str(c))
	## Coste de CPU del motor (20-10-2026, para valorar C++): ms por paso.
	var t0 := Time.get_ticks_usec()
	for _k in 600:
		motor.paso(dt * 0.5)
	var us := float(Time.get_ticks_usec() - t0) / 600.0
	print("   · motor: %.3f ms por paso de 1/60 s (%.1f %% de un fotograma de 60 fps)" % [us / 1000.0, us / 1000.0 / 16.67 * 100.0])
	_comprobar(motor.minuto() >= 3, "el partido avanzó (minuto %d)" % motor.minuto())
	_comprobar(int(c["vel"]) == 0, "nadie corre a más de 10,5 m/s (%d)" % c["vel"])
	_comprobar(int(c["giro"]) == 0, "ningún giro de más de 720°/s (%d)" % c["giro"])
	_comprobar(float(c["tiron"]) / float(c["muestras"]) < 0.005, "tirones > 25 m/s² por debajo del 0,5 %% (%d de %d)" % [c["tiron"], c["muestras"]])
	_comprobar(int(c["tele"]) <= 3, "el balón no salta en pleno juego (%d)" % c["tele"])
	raiz.queue_free()

## GUARDADO SEGURO (20-10-2026): un guardado roto o a medias no pierde la
## partida; se recupera del temporal o de la copia anterior.
func _probar_guardado_seguro() -> void:
	_titulo("GUARDADO SEGURO")
	var m := Mundo.new()
	m.generar(["CHI"], 909)
	m.tomar_el_mando(m.ligas[0].clubes[2].id)
	## 20-10: al empezar, tu club ya tiene sus bonificaciones (antes valían 1,0
	## hasta la primera semana y solo al recargar salían bien).
	var rec := Partida.desde_instantanea(Partida.instantanea(m))
	_comprobar(absf(m.mi_club().bonus_ataque - rec.mi_club().bonus_ataque) < 0.0001
		and absf(m.mi_club().bonus_defensa - rec.mi_club().bonus_defensa) < 0.0001,
		"bonificaciones del club iguales en vivo y al recargar (%.3f/%.3f vs %.3f/%.3f)" % [
		m.mi_club().bonus_ataque, m.mi_club().bonus_defensa, rec.mi_club().bonus_ataque, rec.mi_club().bonus_defensa])
	var n := "__prueba_seguro__"
	var ruta := Partida.ruta_de(n)
	Partida.borrar(n)
	_comprobar(Partida.guardar(m, n), "se guarda")
	_comprobar(FileAccess.file_exists(ruta) and not FileAccess.file_exists(ruta + Partida.TEMPORAL), "queda el principal y no el temporal")
	var semana1 := m.semana
	m.semana += 3
	_comprobar(Partida.guardar(m, n), "se guarda otra vez")
	_comprobar(FileAccess.file_exists(ruta + Partida.RESPALDO), "la versión anterior queda como copia")
	## Principal corrompido (basura): carga la copia y avisa.
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	f.store_string("basura que no es una partida")
	f.close()
	var m2 := Partida.cargar(n)
	_comprobar(m2 != null and m2.semana == semana1 and Partida.cargada_de_respaldo, "principal roto: se recupera la copia anterior")
	## Principal truncado a 2 bytes: no revienta.
	f = FileAccess.open(ruta, FileAccess.WRITE)
	f.store_8(1)
	f.store_8(2)
	f.close()
	_comprobar(Partida.cargar(n) != null, "principal truncado: tampoco se pierde")
	## Sin principal: la ranura sigue en el menú.
	DirAccess.remove_absolute(ruta)
	var esta := false
	for d: Dictionary in Partida.listar():
		esta = esta or String(d.get("fichero", "")) == n
	_comprobar(esta, "sin principal, la ranura sigue en la lista de partidas")
	## Un temporal completo (corte entre escribir y mover) se aprovecha.
	_comprobar(Partida.guardar(m, n), "se guarda de nuevo")
	DirAccess.rename_absolute(ruta, ruta + Partida.TEMPORAL)
	var m3 := Partida.cargar(n)
	_comprobar(m3 != null and m3.semana == semana1 + 3, "un temporal entero se recupera (semana %d)" % (m3.semana if m3 != null else -1))
	## M-412 (20-10): GUARDADOS ESTROPEADOS AL AZAR. Se toma un guardado bueno y
	## se rompe de 40 maneras (bytes cambiados, cortado, cabecera con un tamaño
	## absurdo), sin copia de respaldo: cargar nunca revienta; o sale la partida
	## o sale null (y el banco caza cualquier «SCRIPT ERROR» por el camino).
	Partida.borrar(n)
	_comprobar(Partida.guardar(m, n), "guardado bueno para estropear")
	var bueno := FileAccess.get_file_as_bytes(ruta)
	var az := RandomNumberGenerator.new()
	az.seed = 412
	var nulos := 0
	var cargados := 0
	for i in 40:
		var malo := bueno.duplicate()
		match i % 4:
			0:
				for _k in az.randi_range(1, 30):
					var pos := az.randi_range(0, malo.size() - 1)
					malo[pos] = az.randi_range(0, 255)
			1:
				malo.resize(az.randi_range(0, malo.size() - 1))
			2:
				for k in 4:
					malo[k] = az.randi_range(0, 255)
			3:
				var desde := az.randi_range(4, malo.size() - 2)
				for k in range(desde, mini(desde + 64, malo.size())):
					malo[k] = 0
		DirAccess.remove_absolute(ruta + Partida.RESPALDO)
		var fm := FileAccess.open(ruta, FileAccess.WRITE)
		fm.store_buffer(malo)
		fm.close()
		var mm := Partida.cargar(n)
		if mm == null:
			nulos += 1
		else:
			cargados += 1
	Partida.cargada_de_respaldo = false
	_comprobar(nulos + cargados == 40, "40 guardados estropeados: ninguno revienta (%d no cargan, %d sí)" % [nulos, cargados])
	Partida.borrar(n)
	_comprobar(not FileAccess.file_exists(ruta) and not FileAccess.file_exists(ruta + Partida.TEMPORAL)
		and not FileAccess.file_exists(ruta + Partida.RESPALDO), "borrar quita principal, temporal y copia")

## Lo que no se ve al mirar una partida recien cargada: la division de cada liga
## y el cuadro de la copa. Sin guardarlos, todas las ligas volvian a ser primera
## -con el club que acababa de descender cobrando otra vez de primera- y el
## torneo de copa desaparecia sin que nada se quejara.
func _comprobar_estado_cargado(m: Mundo, m2: Mundo) -> void:
	var divs_ok := true
	for i in m2.ligas.size():
		if m2.ligas[i].div != m.ligas[i].div:
			divs_ok = false
	_comprobar(divs_ok, "vuelve la division de cada liga")
	if m.copa == null:
		return
	_comprobar(m2.copa != null, "vuelve la copa")
	if m2.copa == null:
		return
	_comprobar(m2.copa.vivos.size() == m.copa.vivos.size() and m2.copa.ronda == m.copa.ronda,
		"vuelve el cuadro de la copa (%d vivos, ronda %d)" % [m2.copa.vivos.size(), m2.copa.ronda])
	var mismos := true
	for i in mini(m2.copa.vivos.size(), m.copa.vivos.size()):
		if m2.copa.vivos[i].id != m.copa.vivos[i].id:
			mismos = false
	_comprobar(mismos, "los clubes vivos son los mismos y en el mismo orden")

	## Y los cuatro sistemas que solo existen para TU club. Sin guardarlos,
	## cargar te devolvia con la confianza a 55, sin cuerpo tecnico, sin parte
	## medico, sin logros y sin torneos continentales, y sin una sola queja.
	if m.directiva != null:
		_comprobar(m2.directiva != null, "vuelve la directiva")
		if m2.directiva != null:
			_comprobar(m2.directiva.confianza == m.directiva.confianza \
				and m2.directiva.objetivo == m.directiva.objetivo \
				and m2.directiva.meta_puesto == m.directiva.meta_puesto,
				"vuelve la confianza y el objetivo (%d, %s)" % [m2.directiva.confianza, m2.directiva.objetivo])
	_comprobar(m2.staff.nivel("ayudante") == m.staff.nivel("ayudante") \
		and m2.staff.nivel("medico") == m.staff.nivel("medico"),
		"vuelven los niveles del cuerpo tecnico")
	## Y aplicados: los niveles solos no mueven nada, el motor lee los dos
	## bonificadores del club. Un staff cargado de disco que no los escribe no
	## hace absolutamente nada.
	_comprobar(is_equal_approx(m2.mi_club().bonus_ataque, m.mi_club().bonus_ataque),
		"el staff cargado vuelve a mover el bonificador del motor (%.3f)" % m2.mi_club().bonus_ataque)
	_comprobar(m2.prensa != null and m2.medico != null and m2.logros != null,
		"vuelven prensa, parte medico y logros")
	if m.prensa != null and m2.prensa != null:
		_comprobar(m2.prensa.animo == m.prensa.animo and m2.prensa.funa == m.prensa.funa,
			"vuelve el humor de la hinchada (animo %d)" % m2.prensa.animo)
	_comprobar(m2.continentales.size() == m.continentales.size(),
		"vuelven los %d torneos continentales" % m2.continentales.size())
	if not m.continentales.is_empty():
		var k: String = m.continentales.keys()[0]
		var t1: Continental = m.continentales[k]
		var t2: Continental = m2.continentales[k]
		_comprobar(t2.vivos.size() == t1.vivos.size() and t2.ronda == t1.ronda,
			"vuelve el cuadro de %s (%d vivos, ronda %d)" % [k, t2.vivos.size(), t2.ronda])
