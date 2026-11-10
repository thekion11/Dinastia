extends "res://pruebas/banco/varios_p11.gd"
## [Capa 12 de `varios.gd`, 10-11] _probar_selector_direccional, _probar_eventos_club, _probar_copas_mundo (rueda de prensa en cruz y eventos con diálogo)

## LA CRUZ DE RESPUESTAS (10-11): un botón por opción, delegar al centro, el analógico apunta por direcciones y elegir emite el índice.
func _probar_selector_direccional() -> void:
	_titulo("RUEDA DE PRENSA: SELECCIÓN DIRECCIONAL EN CRUZ")
	var s := SelectorDireccional.crear(["Uno", "Dos", "🙋 Que responda mi ayudante", "Cuatro", "Cinco"], Color.CORNFLOWER_BLUE)
	_comprobar(s.get_child_count() == 5, "un botón hijo por opción, en su orden (5)")
	_comprobar(s._centro == s.get_child(2) and s._brazos.size() == 4, "la de delegar va al centro y las demás a los 4 brazos")
	_comprobar(SelectorDireccional.direccion_de(Vector2(0, -1)) == 0 and SelectorDireccional.direccion_de(Vector2(0.9, 0.2)) == 1
		and SelectorDireccional.direccion_de(Vector2(0, 1)) == 2 and SelectorDireccional.direccion_de(Vector2(-1, 0.3)) == 3, "el analógico se lee en 4 direcciones")
	var dos := SelectorDireccional.crear(["A", "B"], Color.WHITE)
	_comprobar(dos._huecos() == [3, 1], "con dos respuestas: izquierda y derecha")
	var tres := SelectorDireccional.crear(["A", "B", "C"], Color.WHITE)
	_comprobar(tres._huecos() == [0, 3, 1], "con tres: arriba, izquierda y derecha")
	var got := [-1]
	s.elegido.connect(func(i: int) -> void: got[0] = i)
	s.elegir(3)   ## fuera del árbol: sin animación, inmediato
	_comprobar(got[0] == 3, "elegir emite el índice de la opción")
	s.elegir(1)
	_comprobar(got[0] == 3, "tras elegir se bloquea: no se contesta dos veces")
	for x: Node in [s, dos, tres]:
		x.free()

## EVENTOS DEL CLUB CON DIÁLOGO (10-11): solo en su fecha, una vez, y la respuesta mueve moral y confianza.
func _probar_eventos_club() -> void:
	_titulo("EVENTOS DEL CLUB CON DIÁLOGO (directiva, clásico, mitad de liga)")
	var m := Mundo.new()
	m.generar(["CHI"], 4242)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	m.semana = 1
	var ev := EventosClub.pendiente(m)
	_comprobar(not ev.is_empty() and String(ev["id"]) == "directiva", "semana 1: toca la reunión con la directiva")
	_comprobar((ev.get("opciones", []) as Array).size() == 4, "cuatro respuestas, una por brazo de la cruz")
	var conf0 := m.directiva.confianza
	var r := EventosClub.aplicar(m, ev, 1)
	_comprobar(m.directiva.confianza == conf0 + int(r["confianza"]) and int(r["confianza"]) > 0, "«a por más» sube la confianza (%d → %d)" % [conf0, m.directiva.confianza])
	_comprobar(EventosClub.pendiente(m).get("id", "") != "directiva", "ya vista: no vuelve a salir")
	_comprobar(m.prensa.eventos_vistos.has("directiva:%d" % m.anio), "queda anotada para el guardado")
	m.semana = 10
	var liga := m.liga_de(m.mi_club())
	liga.jornada_actual = 3   ## lejos de la mitad
	var otro := EventosClub.pendiente(m)
	_comprobar(otro.is_empty() or String(otro["id"]) == "clasico", "fuera de fecha no sale nada (salvo la semana de un clásico)")
	liga.jornada_actual = liga.jornadas() / 2
	m.prensa.eventos_vistos.append(EventosClub._clave(m, "clasico"))
	var mitad := EventosClub.pendiente(m)
	_comprobar(not mitad.is_empty() and String(mitad["id"]) == "mitad", "la jornada de la mitad: el balance con el ayudante")
	_comprobar(EventosClub.capitan(m.mi_club()) != null, "hay capitán para la escena del clásico")

## LAS COPAS Y SUPERCOPAS DE TODOS LOS PAÍSES (10-11, encargo del dueño): se juegan todas, quedan sus campeones y sobreviven a guardar y cargar.
## (Regla 34: un club de otro país, no el de siempre.)
func _probar_copas_mundo() -> void:
	_titulo("TORNEOS: LAS COPAS Y SUPERCOPAS DE TODOS LOS PAÍSES")
	var m := Mundo.new()
	m.generar(["ESP", "ARG", "ENG"], 314)
	var liga_esp: Liga = m.ligas.filter(func(l: Liga) -> bool: return l.pais == "ESP")[0]
	m.tomar_el_mando(liga_esp.clubes[5].id)
	var paises := {}
	for c: Club in m.clubes.values():
		paises[c.pais] = true
	_comprobar(m.copas_otras.size() >= paises.size() - 1, "se sortean las copas de los demás países (%d copas, %d países)" % [m.copas_otras.size(), paises.size()])
	var inglesas: Array = m.copas_otras.filter(func(cp: Copa) -> bool: return String(cp.get_meta("pais", "")) == "ENG")
	_comprobar(inglesas.size() == 2, "Inglaterra juega sus dos copas el mismo año (%d)" % inglesas.size())
	var mio := m.mi_club()
	_comprobar(not m.copas_otras.any(func(cp: Copa) -> bool: return cp.participantes.has(mio)), "tu club no está en las copas de los demás")
	var guard := 0
	while m.temporada_en_curso() and guard < 80:
		m.avanzar_semana()
		guard += 1
	CierreTorneos.cerrar_pendientes(m)
	_comprobar(m.copas_otras.all(func(cp: Copa) -> bool: return cp.campeon != null), "al terminar la liga todas las copas tienen campeón")
	var copas_en_palmares := m.palmares_mundo.filter(func(t: Dictionary) -> bool: return String(t["torneo"]) != "Supercopa").size()
	_comprobar(copas_en_palmares >= m.copas_otras.size(), "y quedan en el palmarés del mundo, con las ligas (%d)" % copas_en_palmares)
	Partida.borrar("_prueba_copas_mundo")
	_comprobar(Partida.guardar(m, "_prueba_copas_mundo"), "se guarda")
	var m2 := Partida.cargar("_prueba_copas_mundo")
	_comprobar(m2 != null and m2.copas_otras.size() == m.copas_otras.size() and m2.palmares_mundo.size() == m.palmares_mundo.size(), "y se carga con sus copas y su palmarés")
	m.nueva_temporada()
	var supers := m.palmares_mundo.filter(func(t: Dictionary) -> bool: return String(t["torneo"]) == "Supercopa" and int(t["anio"]) == m.anio).size()
	_comprobar(supers >= 1, "al empezar la temporada se juegan las supercopas de los demás países (%d)" % supers)
	_comprobar(m.copas_otras.all(func(cp: Copa) -> bool: return cp.campeon == null and cp.en_curso()), "y se sortean copas nuevas")
	Partida.borrar("_prueba_copas_mundo")
