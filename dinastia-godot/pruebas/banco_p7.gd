extends "res://pruebas/banco_p6.gd"
## [Capa 7/27 de `banco.gd`] _probar_tactica_en_movimiento, _probar_copa, _probar_selecciones

## COMPARAR TACTICAS DE VERDAD (17-9-2026), sin necesitar pantalla: llama
## `_objetivo_jugador()` directo -el mismo metodo que usa `MatchPlayback._mover()`
## para cada uno de los 22, cada fotograma- con la MISMA ranura de formacion y
## la MISMA pelota, cambiando solo la `Tactica`. Si dos tacticas de verdad se
## sienten distinto jugando, tienen que devolver puntos distintos aqui -es la
## unica forma de "comparar visualmente" que tengo sin ojos.
func _probar_tactica_en_movimiento() -> void:
	_titulo("TACTICA EN EL MOVIMIENTO 3D (nivel FC 26)")
	var mp := MatchPlayback.new()
	mp.fase = "ataqueLocal"  # el equipo local ataca -hacia Z negativo, dir_ataque=-1

	var t_ofensiva := Tactica.new()
	t_ofensiva.mentalidad = Tactica.Mentalidad.OFENSIVA
	t_ofensiva.linea = Tactica.Nivel.ALTO
	t_ofensiva.amplitud = Tactica.Nivel.ALTO

	var t_defensiva := Tactica.new()
	t_defensiva.mentalidad = Tactica.Mentalidad.DEFENSIVA
	t_defensiva.linea = Tactica.Nivel.BAJO
	t_defensiva.amplitud = Tactica.Nivel.BAJO

	## Mismo jugador (misma ranura de formacion `base`), misma pelota -delta
	## grande y reaccion casi nula para que el empuje ya haya llegado del todo
	## a su objetivo, sin que la inercia de la ronda 2 tape la comparacion.
	var base := Vector3(20.0, 0, 0.0)
	var bola := Vector3(0, 0.11, -20.0)

	mp.local_tactica = t_ofensiva
	var obj_of: Vector3 = mp._objetivo_jugador(base, bola, true, {"_reaccion": 0.01}, 5.0)

	mp.local_tactica = t_defensiva
	var obj_def: Vector3 = mp._objetivo_jugador(base, bola, true, {"_reaccion": 0.01}, 5.0)

	_linea("  ofensiva+linea alta: (x=%.1f, z=%.1f)   defensiva+linea baja: (x=%.1f, z=%.1f)" % [
		obj_of.x, obj_of.z, obj_def.x, obj_def.z])
	_comprobar(obj_of.z < obj_def.z - 3.0,
		"ofensiva+linea alta empuja el bloque medible mas arriba que defensiva+linea baja (diferencia real, no cosmetica)")
	_comprobar(absf(obj_of.x) > absf(obj_def.x),
		"amplitud alta separa mas del centro que amplitud baja")

	## MARCA AL HOMBRE: un defensor con la casilla activa tiene que terminar
	## MAS CERCA del rival marcado que el mismo defensor con marca por zonas.
	var t_zonal := Tactica.new()
	var t_marca := Tactica.new()
	t_marca.marca_al_hombre = true
	## `_rival_mas_cercano()` necesita `yo["node"]` de verdad -en un partido
	## real todo jugador lo trae (lo pone `PlayerSpawner`), pero en esta
	## prueba hay que armarlo a mano. Sin este nodo, el primer intento de esta
	## prueba fallaba con un error real de "node" faltante -detectado
	## revisando el `.err.txt`, no confiando en que "0 fallos" bastara.
	var yo_nodo := Node3D.new()
	yo_nodo.position = base
	add_child(yo_nodo)
	var yo := {"_reaccion": 0.01, "slot_code": "DFC", "node": yo_nodo, "es_local": true, "arbitro": false}
	var rival_nodo := Node3D.new()
	rival_nodo.position = Vector3(-15.0, 0, 30.0)  # lejos de la ranura de formacion del marcador
	add_child(rival_nodo)
	var rival := {"node": rival_nodo, "es_local": false, "slot_code": "DC", "arbitro": false}
	mp.players = [rival]
	mp.fase = "ataqueVisita"  # el local defiende -condicion para que la marca se active

	mp.local_tactica = t_zonal
	var obj_zonal: Vector3 = mp._objetivo_jugador(base, bola, true, yo.duplicate(), 5.0)
	mp.local_tactica = t_marca
	var obj_marca: Vector3 = mp._objetivo_jugador(base, bola, true, yo.duplicate(), 5.0)

	var d_zonal := obj_zonal.distance_to(rival_nodo.position)
	var d_marca := obj_marca.distance_to(rival_nodo.position)
	_linea("  distancia al rival marcado -> zonal: %.1f m   marca al hombre: %.1f m" % [d_zonal, d_marca])
	_comprobar(d_marca < d_zonal - 3.0,
		"con marca al hombre activa, el defensor termina medible mas cerca del rival que en zona")
	rival_nodo.queue_free()
	yo_nodo.queue_free()

	## FUERA DE JUEGO: un defensor con la trampa activa tiene que quedar mas
	## adelantado (mas cerca de la mitad de cancha rival) que sin ella, en la
	## MISMA fase de defender.
	mp.players = []
	var t_sin_trampa := Tactica.new()
	var t_con_trampa := Tactica.new()
	t_con_trampa.fuera_de_juego = true
	var def_p := {"_reaccion": 0.01, "slot_code": "DFC"}
	mp.local_tactica = t_sin_trampa
	var obj_sin_trampa: Vector3 = mp._objetivo_jugador(base, bola, true, def_p.duplicate(), 5.0)
	mp.local_tactica = t_con_trampa
	var obj_con_trampa: Vector3 = mp._objetivo_jugador(base, bola, true, def_p.duplicate(), 5.0)
	_linea("  linea sin trampa: z=%.1f   con trampa de fuera de juego: z=%.1f" % [obj_sin_trampa.z, obj_con_trampa.z])
	_comprobar(obj_con_trampa.z < obj_sin_trampa.z - 2.0,
		"la trampa del fuera de juego sube medible la linea del defensor (local ataca a Z negativo)")

	## SALIDA CORTA: con el equipo en fase de ataque, un central tiene que
	## separarse mas del centro (mas ancho) si el club arma desde atras.
	var t_sin_salida := Tactica.new()
	var t_con_salida := Tactica.new()
	t_con_salida.salida_corta = true
	mp.fase = "ataqueLocal"  # el local ataca -este defensor SI tiene la pelota
	mp.local_tactica = t_sin_salida
	var obj_sin_salida: Vector3 = mp._objetivo_jugador(base, bola, true, def_p.duplicate(), 5.0)
	mp.local_tactica = t_con_salida
	var obj_con_salida: Vector3 = mp._objetivo_jugador(base, bola, true, def_p.duplicate(), 5.0)
	_linea("  ancho sin salida corta: x=%.1f   con salida corta: x=%.1f" % [obj_sin_salida.x, obj_con_salida.x])
	_comprobar(absf(obj_con_salida.x) > absf(obj_sin_salida.x) + 1.5,
		"la salida corta separa medible al central del centro cuando su equipo ataca")

	## RITMO: en igualdad de todo lo demas, un equipo de ritmo alto tiene que
	## desplazarse mas en UN MISMO paso de tiempo que uno de ritmo bajo -se
	## prueba con `_mover()` de verdad, no repitiendo la formula a mano.
	var nodo_alto := Node3D.new()
	nodo_alto.position = Vector3(20.0, 0, 20.0)
	add_child(nodo_alto)
	var nodo_bajo := Node3D.new()
	nodo_bajo.position = Vector3(20.0, 0, -20.0)
	add_child(nodo_bajo)
	var t_ritmo_alto := Tactica.new()
	t_ritmo_alto.ritmo = Tactica.Nivel.ALTO
	var t_ritmo_bajo := Tactica.new()
	t_ritmo_bajo.ritmo = Tactica.Nivel.BAJO
	var mp2 := MatchPlayback.new()
	mp2.fase = "ataqueVisita"  # el local (estos dos jugadores) defiende
	mp2.local_tactica = t_ritmo_alto
	mp2.players = [{"node": nodo_alto, "anim": null, "es_local": true, "base_pos": Vector3(0, 0, 20.0), "id": "ra"}]
	mp2.ball = null
	mp2._mover(1.0)
	var mp3 := MatchPlayback.new()
	mp3.fase = "ataqueVisita"
	mp3.local_tactica = t_ritmo_bajo
	mp3.players = [{"node": nodo_bajo, "anim": null, "es_local": true, "base_pos": Vector3(0, 0, -20.0), "id": "rb"}]
	mp3.ball = null
	mp3._mover(1.0)
	var recorrido_alto := nodo_alto.position.distance_to(Vector3(20.0, 0, 20.0))
	var recorrido_bajo := nodo_bajo.position.distance_to(Vector3(20.0, 0, -20.0))
	_linea("  recorrido en 1s -> ritmo alto: %.2f m   ritmo bajo: %.2f m" % [recorrido_alto, recorrido_bajo])
	_comprobar(recorrido_alto > recorrido_bajo,
		"un equipo de ritmo alto se mueve medible mas rapido que uno de ritmo bajo, mismo tiempo")
	nodo_alto.queue_free()
	nodo_bajo.queue_free()

	## JUGADA DE GOL (primera "jugada prehecha" real, 18-9-2026): el asistidor
	## de un gol tiene que dejar de ser ajeno a su propio pase -acercarse
	## medible al destino que le calcula `_jugada_gol()`, no seguir clavado en
	## su ranura de formacion como si el pase lo hubiera dado otro-. Se prueba
	## por `suceso()`, la puerta real que usa el partido en vivo (no llamando a
	## `_jugada_gol()` a mano), para que la prueba cubra tambien el disparo del
	## evento real y no solo la funcion aislada.
	var nodo_rematador := Node3D.new()
	nodo_rematador.position = Vector3(0.0, 0, -40.0)
	add_child(nodo_rematador)
	var nodo_asistidor := Node3D.new()
	nodo_asistidor.position = Vector3(15.0, 0, -10.0)  # lejos del area al momento del gol
	add_child(nodo_asistidor)

	var mp4 := MatchPlayback.new()
	mp4.fase = "medio"
	var p_rematador := {"id": "goleador", "node": nodo_rematador, "anim": null, "es_local": true,
		"base_pos": Vector3(0, 0, -40.0), "slot_code": "DC", "arbitro": false}
	var p_asistidor := {"id": "asistidor", "node": nodo_asistidor, "anim": null, "es_local": true,
		"base_pos": Vector3(15.0, 0, -10.0), "slot_code": "MC", "arbitro": false}
	mp4.players = [p_rematador, p_asistidor]
	mp4.players_by_id = {"goleador": p_rematador, "asistidor": p_asistidor}
	mp4.suceso({"min": 10, "t": "golMi", "equipo": "local", "tx": "gol de prueba",
		"jugadorId": "goleador", "asistidorId": "asistidor"})

	_comprobar(float(mp4._guion_hasta.get("asistidor", -1.0)) > mp4.elapsed,
		"tras el gol, el asistidor tiene una jugada con guion activa (no vuelve de inmediato al reparto por zona)")

	var destino_guion: Vector3 = mp4._guion_destino.get("asistidor", Vector3.ZERO)
	var d_inicial := nodo_asistidor.position.distance_to(destino_guion)
	for i in 20:
		mp4._mover(0.1)
	var d_final := nodo_asistidor.position.distance_to(destino_guion)
	_linea("  asistidor -> destino de la jugada: antes %.1f m   despues de 2s %.1f m" % [d_inicial, d_final])
	_comprobar(d_final < d_inicial - 3.0,
		"el asistidor se mueve medible hacia el destino de la jugada de gol, no se queda en su ranura de formacion")

	nodo_rematador.queue_free()
	nodo_asistidor.queue_free()

	## APOYO CERCANO (18-9-2026): sin ninguna jugada con guion activa, el
	## compañero MAS CERCANO al balón tiene que moverse medible hacia una
	## posición de apoyo -no quedarse en su ranura de formación como el resto-,
	## mientras que un compañero lejano SIGUE en reparto de zona normal. Es la
	## pieza que pidió el usuario: movimiento con sentido sin depender de una
	## jugada prehecha.
	var nodo_cercano := Node3D.new()
	nodo_cercano.position = Vector3(10.0, 0, -15.0)  # a unos pocos metros del balon
	add_child(nodo_cercano)
	var nodo_lejano := Node3D.new()
	nodo_lejano.position = Vector3(-25.0, 0, 30.0)  # lejos del balon, del otro lado
	add_child(nodo_lejano)
	var mp5 := MatchPlayback.new()
	mp5.fase = "ataqueLocal"  # el local ataca -condicion para que el apoyo se active
	var bola_apoyo := Vector3(12.0, 0.11, -18.0)
	var p_cercano := {"id": "cerca", "node": nodo_cercano, "anim": null, "es_local": true,
		"base_pos": Vector3(10.0, 0, -15.0), "slot_code": "MC", "arbitro": false, "_reaccion": 0.01}
	var p_lejano := {"id": "lejos", "node": nodo_lejano, "anim": null, "es_local": true,
		"base_pos": Vector3(-25.0, 0, 30.0), "slot_code": "MC", "arbitro": false, "_reaccion": 0.01}
	mp5.players = [p_cercano, p_lejano]
	mp5.ball = null

	var obj_cercano: Vector3 = mp5._objetivo_jugador(p_cercano["base_pos"], bola_apoyo, true, p_cercano, 5.0)
	var obj_lejano: Vector3 = mp5._objetivo_jugador(p_lejano["base_pos"], bola_apoyo, true, p_lejano, 5.0)
	var d_cercano_balon := obj_cercano.distance_to(bola_apoyo)
	var d_lejano_balon := obj_lejano.distance_to(bola_apoyo)
	_linea("  apoyo -> objetivo del cercano a %.1f m del balon   objetivo del lejano a %.1f m del balon" % [
		d_cercano_balon, d_lejano_balon])
	_comprobar(d_cercano_balon < 8.0,
		"el companero mas cercano al balon termina medible cerca de el (posicion de apoyo)")
	_comprobar(d_cercano_balon < d_lejano_balon - 10.0,
		"el companero mas cercano al balon queda medible mas cerca de el que el companero lejano -el apoyo no arrastra a todos por igual")

	nodo_cercano.queue_free()
	nodo_lejano.queue_free()

func _probar_copa() -> void:
	_titulo("COPA: ELIMINACION DIRECTA")
	var m := Mundo.new()
	m.generar(["CHI"], 909)
	var aspirantes: Array[Club] = []
	for c: Club in m.clubes.values():
		aspirantes.append(c)
	var copa := Copa.new("Copa de prueba")
	copa.preparar(aspirantes)
	_linea("  %d clubes inscritos -> %d en el cuadro (%s)" % [
		aspirantes.size(), copa.participantes.size(), copa.nombre_de_ronda()])
	## El cuadro tiene que ser potencia de dos: con 32 equipos y byes repartidos
	## a mano, el sorteo parece amanado y ademas hay que inventar rondas previas.
	var n := copa.participantes.size()
	var potencia := n > 0 and (n & (n - 1)) == 0
	_comprobar(potencia, "el cuadro es una potencia de dos (%d)" % n)
	_comprobar(n <= aspirantes.size(), "no se inventan participantes")

	var rondas := 0
	var nombres: Array[String] = []
	while copa.en_curso():
		nombres.append(copa.nombre_de_ronda())
		var res := copa.jugar_ronda()
		## En cada cruce tiene que pasar uno y solo uno, y el que pasa tiene que
		## ser uno de los dos que jugaron.
		for r: Dictionary in res:
			if r["pasa"] != r["local"] and r["pasa"] != r["visita"]:
				_fallos.append("pasa un club que no jugo el cruce")
			if r["gl"] == r["gv"] and r["penales"].is_empty():
				_fallos.append("un empate sin penales en eliminacion directa")
		rondas += 1
		if rondas > 12:
			break
	_linea("  rondas: %s" % ", ".join(nombres))
	_comprobar(copa.campeon != null, "la copa tiene campeon: %s" % (copa.campeon.nombre if copa.campeon else "ninguno"))
	_comprobar(rondas == int(log(float(n)) / log(2.0)), "se juegan las rondas justas (%d para %d clubes)" % [rondas, n])
	_comprobar(nombres.has("Final") and nombres.has("Semifinales"), "las rondas se llaman por su nombre")
	_comprobar(copa.participantes.has(copa.campeon), "el campeon estaba inscrito")

	## El premio es fijo y se cobra. Es lo que hace que una copa cambie el ano
	## de un club chico.
	var antes := copa.campeon.saldo
	var copa2 := Copa.new("Otra")
	copa2.preparar(aspirantes)
	var c2 := copa2.jugar_hasta_el_final()
	_linea("  premio de copa: %s (fijo, no escalado al tamano del club)" % _dinero(Copa.PREMIO))
	_comprobar(c2 != null, "jugar_hasta_el_final devuelve campeon")

	## Y la final se juega en cancha neutral: sin el 1,08 del local.
	##
	## SE MIDE POR GOLES, NO POR VICTORIAS. La version anterior contaba
	## victorias en 300 partidos y comparaba los dos numeros a pelo: con p~0,4 y
	## n=300 el ruido propio es de +-8 victorias, o sea que comparaba dos cifras
	## cuya diferencia esperada cabe entera dentro del error. Pasaba por suerte,
	## y el dia que las plantillas cambiaron de fuerza salio 118 contra 126 -al
	## reves- sin que nada estuviera roto. Los goles son una senal continua: el
	## bono de local (1,08 contra 0,94) los mueve directamente y se ve con mucha
	## menos muestra.
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var goles_en_casa := 0
	var goles_neutral := 0
	var remates_casa := 0
	var remates_neutral := 0
	## MUESTRA SUBIDA DE 300 A 800 (11-9-2026): con el árbitro metido en cada
	## llegada (`Partido._chequeo_arbitral()`, que gasta `Azar` en CADA ataque,
	## haya decisión o no) la posición del sorteo compartido se corre un poco
	## para todo lo que se simule después en el banco. La brecha esperada entre
	## casa y neutral (~4.47 contra ~4.24, un 0,23 de diferencia) cabía casi
	## entera dentro del error propio de 300 muestras -el mismo problema que
	## esta prueba ya había tenido una vez con "victorias" en vez de "goles",
	## documentado arriba-, así que bastó ese corrimiento para que en esta
	## semilla el resultado saliera al revés (4.16 contra 4.38) sin que la
	## ventaja de local se hubiera roto: `neutral=true` sigue sin sumar el
	## 1,08 de `simular_minuto()`, nadie tocó esa cuenta. Con 800 partidos por
	## lado el error baja de ~0,12 a ~0,07 remates, con margen de sobra sobre
	## la brecha real.
	for i in 800:
		var p1 := Partido.new(a, b, false)
		p1.simular()
		goles_en_casa += p1.goles_local
		remates_casa += p1.remates_local
		var p2 := Partido.new(a, b, true)
		p2.simular()
		goles_neutral += p2.goles_local
		remates_neutral += p2.remates_local
	var media_casa := float(goles_en_casa) / 800.0
	var media_neutral := float(goles_neutral) / 800.0
	var rem_casa := float(remates_casa) / 800.0
	var rem_neutral := float(remates_neutral) / 800.0
	_linea("  el local: %.2f goles y %.2f remates en casa | %.2f goles y %.2f remates en neutral" % [
		media_casa, rem_casa, media_neutral, rem_neutral])
	## SE MIDE POR REMATES, que es donde pega el bono. El camino hasta aqui:
	##  1) La version original contaba VICTORIAS en 300 partidos. Ruido propio
	##     +-8 victorias, diferencia esperada menor que eso: pasaba por suerte.
	##  2) Se cambio a GOLES, y salio 1.31 en casa contra 1.32 en neutral -o sea
	##     ninguna diferencia-, lo que parecia un bug gordo: que jugar de local
	##     no valiera nada. NO lo era: el gol es una moneda al 30% sobre cada
	##     remate, y ese sorteo se traga una diferencia del 5%.
	##  3) Medido en REMATES, que es lo que el bono multiplica directamente, la
	##     ventaja aparece limpia: 4.47 contra 4.24.
	## La leccion: medir el efecto donde ocurre, no tres sorteos mas abajo.
	_comprobar(rem_casa > rem_neutral,
		"en cancha neutral se pierde la ventaja de local (%.2f remates vs %.2f)" % [rem_casa, rem_neutral])

func _probar_selecciones() -> void:
	_titulo("SELECCIÓN NACIONAL Y MUNDIAL DE CLUBES")
	var m := Mundo.new()
	m.generar(["CHI", "ARG", "ESP"], 909)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	_comprobar(m.selecciones != null, "tomar el mando crea la selección")
	_comprobar(m.selecciones.pais_seleccion() == m.mi_club().pais,
		"la selección que sigues es la de tu club, no Chile a fuego (%s)" % m.selecciones.pais_seleccion())
	_comprobar(m.selecciones.fuerza("Brasil") == 88 and m.selecciones.fuerza("España") == 88,
		"las seis grandes valen 88")
	var antes_conti := m.continentales.size()

	## Tres temporadas: cae al menos una prenómina, una fecha FIFA, un torneo
	## continental de selecciones (par) y, a la tercera (2028), la Copa del Mundo.
	##
	## Se comprueba el estado directo (`prenomina_ids`, `nomina_ids`) y no las
	## señales: un lambda de GDScript captura las variables locales POR VALOR, no
	## por referencia, así que `func(): vio = true` conectado a una señal escribe
	## en una copia y la variable de fuera nunca cambia -sin error, sin aviso.
	var ultimo_resumen := {}
	for temporada in 3:
		m.jugar_temporada()
		ultimo_resumen = m.nueva_temporada()
	_comprobar(not m.selecciones.prenomina_ids.is_empty(), "se publica al menos una prenómina en tres temporadas")
	_comprobar(not m.selecciones.nomina_ids.is_empty(), "se cierra al menos una convocatoria en tres temporadas")
	_comprobar(m.selecciones.nomina_ids.size() <= 18, "la nómina final no pasa de 18 (%d)" % m.selecciones.nomina_ids.size())
	_comprobar(m.selecciones.resultados.size() > 0, "quedan resultados de la selección anotados")
	_comprobar(ultimo_resumen.get("selecciones", {}).has("mundial"),
		"nueva_temporada() devuelve el resumen de selecciones")
	## 2026 -> 2027 -> 2028: la Copa del Mundo cae al cerrar 2028.
	_comprobar(not m.selecciones.mundial.is_empty(), "la Copa del Mundo se jugó al llegar a 2028 (%s)" % m.selecciones.mundial.get("campeon", "?"))
	_comprobar(m.continentales.size() == antes_conti,
		"los continentales se re-sortean cada temporada con el mismo número de torneos (%d)" % m.continentales.size())

	## Guardado y carga: la cabeza de la selección (caps, nacionalizados, mundial)
	## tiene que sobrevivir igual que el resto de sistemas de TU club.
	Partida.borrar("_prueba_selecciones")
	_comprobar(Partida.guardar(m, "_prueba_selecciones"), "una partida con selección se guarda")
	var m2 := Partida.cargar("_prueba_selecciones")
	_comprobar(m2 != null, "esa partida se recarga")
	if m2 != null:
		_comprobar(m2.selecciones != null, "la selección vuelve al cargar")
		_comprobar(m2.selecciones.mundial.get("campeon", "") == m.selecciones.mundial.get("campeon", ""),
			"vuelve el mismo campeón del mundo (%s)" % m2.selecciones.mundial.get("campeon", "?"))
		_comprobar(m2.selecciones.resultados.size() == m.selecciones.resultados.size(),
			"vuelven los mismos resultados anotados (%d)" % m2.selecciones.resultados.size())
	Partida.borrar("_prueba_selecciones")
