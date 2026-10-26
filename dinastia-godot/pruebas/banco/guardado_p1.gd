extends "res://pruebas/banco/base.gd"
## [Capa 1/3 de `guardado.gd`] _probar_repetibilidad, _probar_guardado_seguro, _comprobar_estado_cargado

func _probar_repetibilidad() -> void:
	_titulo("REPETIBILIDAD (lo que el HTML no puede hacer)")
	var a := Mundo.new()
	a.generar(["CHI"], 12345)
	var b := Mundo.new()
	b.generar(["CHI"], 12345)
	_comprobar(a.cuantos_jugadores() == b.cuantos_jugadores(), "misma semilla, mismo numero de jugadores")
	var ja := a.jugadores()
	var jb := b.jugadores()
	var iguales := true
	for i in mini(ja.size(), jb.size()):
		if ja[i].nombre != jb[i].nombre or ja[i].ovr != jb[i].ovr:
			iguales = false
			break
	_comprobar(iguales, "misma semilla, mismos jugadores uno a uno")
	## Desde la fase 4 las plantillas de ARRANQUE son fijas (sembradas con el
	## nombre del club): lo que cambia con la semilla es el mundo que corre,
	## empezando por los resultados de la primera jornada.
	var c := Mundo.new()
	c.generar(["CHI"], 999)
	var res_a := str(a.ligas[0].jugar_jornada()) + str(a.ligas[0].jugar_jornada())
	var res_c := str(c.ligas[0].jugar_jornada()) + str(c.ligas[0].jugar_jornada())
	_comprobar(res_a != res_c, "otra semilla, otro mundo (otros resultados)")

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
