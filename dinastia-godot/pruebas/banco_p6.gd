extends "res://pruebas/banco_p5.gd"
## [Capa 6/27 de `banco.gd`] _probar_obras, _probar_pantalla_y_vallas, _probar_estadio, _probar_continental

func _probar_obras() -> void:
	_titulo("INSTALACIONES")
	var m := Mundo.new()
	m.generar(["CHI"], 2424)
	var c: Club = m.ligas[0].clubes[0]
	m.tomar_el_mando(c.id)
	var o := m.obras
	_linea("  %d obras en el catalogo" % Instalaciones.CATALOGO.size())
	_comprobar(Instalaciones.CATALOGO.size() == 19, "estan las 19 instalaciones del HTML")

	## Las obras NO son instantaneas: es lo que impide comprarlo todo el primer
	## dia y que el sistema desaparezca. En el HTML se cambio a proposito en la
	## v2.5 justo por eso.
	var caja := c.saldo
	var precio := o.coste("cal", c.rep)
	_comprobar(o.iniciar("cal", c) == "", "se puede empezar una obra")
	_comprobar(c.saldo == caja - precio, "la obra se paga por adelantado")
	_comprobar(o.nivel("cal") == 0, "la obra NO sube el nivel al momento")
	_comprobar(o.en_obra("cal"), "queda constancia de que hay obra en marcha")
	_comprobar(o.iniciar("cal", c) != "", "no se puede empezar dos veces la misma obra")
	var retrasos := 0
	for s in o.semanas_de("cal"):
		o.avanzar_semana(c)
		for t: String in o.ultimos_imprevistos:
			retrasos += 1 if t.contains("retrasa") else 0
	for s in retrasos:
		o.avanzar_semana(c)
	_comprobar(o.nivel("cal") == 1, "la obra termina en su plazo (%d semanas%s)" % [o.semanas_de("cal"), " + %d de retraso" % retrasos if retrasos > 0 else ""])
	_comprobar(not o.en_obra("cal"), "y deja de estar en marcha")

	## Y lo que de verdad importa: que se NOTE. Una obra que no mueve un numero
	## visible es un boton de gastar dinero.
	var f_sin := Finanzas.new(c, 0.0)
	var f_con := Finanzas.new(c, o.aporte_ocupacion())
	_linea("  calidad del estadio nivel 1: entran %d en vez de %d" % [
		f_con.asistencia(), f_sin.asistencia()])
	_comprobar(f_con.asistencia() > f_sin.asistencia(), "la calidad del estadio llena mas el estadio")

	## Las tribunas cambian el aforo, y hay que poder construirlas varias veces
	## sin que el aforo se multiplique cada vez que se carga la partida.
	var aforo0 := c.estadio_aforo
	o.niveles["trib"] = 2
	o.aplicar(c)
	var aforo2 := c.estadio_aforo
	_linea("  aforo: %s de fabrica, %s con dos tribunas" % [aforo0, aforo2])
	_comprobar(aforo2 > aforo0, "construir tribunas amplia el aforo")
	o.aplicar(c)
	o.aplicar(c)
	_comprobar(c.estadio_aforo == aforo2, "aplicarlo tres veces no multiplica el aforo")

	## Los ingresos que solo existen con ladrillo.
	o.niveles["com"] = 2
	o.niveles["museo"] = 1
	o.ultima_asistencia = 20000
	o.niveles["park"] = 3
	var ing := o.ingresos_del_mes(c)
	var total := 0
	for i: Dictionary in ing:
		total += int(i["monto"])
		_linea("  %s: %s al mes" % [String(i["concepto"]), _dinero(int(i["monto"]))])
	_comprobar(ing.size() == 3, "la tienda, el museo y los estacionamientos dan ingresos")
	_comprobar(total > 0, "y suman de verdad (%s)" % _dinero(total))
	## M-224: la estrella del plantel vende camisetas.
	var mejor_j: Jugador = c.plantilla[0]
	var ovr0 := mejor_j.ovr
	for j: Jugador in c.plantilla:
		j.ovr = mini(j.ovr, 74)
	var tienda_normal := int(o.ingresos_del_mes(c)[0]["monto"])
	mejor_j.ovr = 90
	var tienda_crack := int(o.ingresos_del_mes(c)[0]["monto"])
	mejor_j.ovr = ovr0
	_comprobar(tienda_crack > tienda_normal * 1.5, "con un crack de 90 la tienda vende más camisetas (%s → %s)" % [_dinero(tienda_normal), _dinero(tienda_crack)])
	## M-227: lo construido se mantiene (cuesta cada mes, más cuanto más hay).
	var mant := o.mantenimiento_del_mes(c.rep)
	o.niveles["trib"] = 4
	_comprobar(mant > 0 and o.mantenimiento_del_mes(c.rep) > mant, "el mantenimiento cuesta y crece con lo construido (%s → %s al mes)" % [_dinero(mant), _dinero(o.mantenimiento_del_mes(c.rep))])
	_comprobar(mant < total * 3, "y no se come lo que rinden las obras (%s vs %s)" % [_dinero(mant), _dinero(total)])
	## M-228: imprevistos — como mucho uno por obra, y repetibles al recargar.
	var imp := Instalaciones.new()
	imp.niveles = o.niveles.duplicate()
	var hubo := 0
	for clave: String in Instalaciones.CATALOGO:
		if imp.nivel(clave) >= imp.maximo(clave):
			continue
		imp.obras[clave] = 6
		for _s in 8:
			imp.avanzar_semana(c)
			hubo += imp.ultimos_imprevistos.size()
	_comprobar(hubo > 0 and hubo <= Instalaciones.CATALOGO.size(), "algunas obras tienen un imprevisto, nunca más de uno (%d)" % hubo)

	## Cada efecto tiene una puerta por la que entra al juego. Si alguna devuelve
	## siempre lo mismo, esa instalacion no hace nada.
	o.niveles["med"] = 2
	o.niveles["rehab"] = 1
	_comprobar(o.descuento_lesion() == 3, "el centro medico y la rehabilitacion acortan lesiones (%d)" % o.descuento_lesion())
	o.niveles["cocina"] = 2
	o.niveles["piscina"] = 2
	_comprobar(o.aguante() == 2, "comedor y piscina dan aguante (%d)" % o.aguante())
	o.niveles["ct"] = 3
	_comprobar(o.ritmo_de_progreso() > 1.0, "el centro de entrenamiento acelera el progreso (%.2f)" % o.ritmo_de_progreso())
	o.niveles["acad"] = 2
	o.niveles["resid"] = 2
	_comprobar(o.techo_cantera() == 3, "academia y residencia suben el techo de la cantera (%d)" % o.techo_cantera())
	o.niveles["huerto"] = 3
	_comprobar(o.abarata_operacion() < 1.0, "el huerto abarata la operacion")

	## El coste crece con el cuadrado del nivel: el quinto nivel tiene que ser
	## una decision de club, no un tramite.
	var c1 := o.coste("gim", c.rep)
	o.niveles["gim"] = 3
	var c4 := o.coste("gim", c.rep)
	_linea("  gimnasio: nivel 1 cuesta %s, nivel 4 cuesta %s" % [_dinero(c1), _dinero(c4)])
	_comprobar(c4 > c1 * 3, "el cuarto nivel cuesta mucho mas que el primero")

## LA PANTALLA GIGANTE Y LAS VALLAS LED (23-9-2026). Lo que se comprueba aquí
## es la LÓGICA, sin abrir ventana: la parte visual la verifica
## `pruebas/captura_pantalla_gigante.gd` con capturas reales.
##
## Hay dos bugs de verdad detrás de estas comprobaciones, los dos encontrados
## esta misma tanda mirando capturas:
##   - La pantalla estaba clavada en `alto - 1.0` con 9 m de marco FIJOS, así
##     que asomaba por encima del graderío y el techo (`alto + 0.4`) le pasaba
##     por delante partiéndola en dos. En un estadio de 1 nivel además se
##     hundía bajo el césped. Por eso se comprueba contra los TRES niveles.
##   - Los nombres largos de club se salían del lienzo. Por eso la pantalla usa
##     abreviaturas de tres letras, y se comprueba que "D. Limache" da "LIM"
##     (la versión vieja habría dado "D." o un recorte a media palabra).
func _probar_pantalla_y_vallas(m: Mundo) -> void:
	_titulo("PANTALLA GIGANTE Y VALLAS LED")
	var c: Club = m.ligas[0].clubes[0]
	var ab := PantallaEstadio.abreviatura(c)
	_comprobar(ab.length() == 3 and ab == ab.to_upper(),
		"la abreviatura del club son tres letras en mayúscula (%s -> %s)" % [c.nombre, ab])
	## El caso real que reventó la primera versión de la pantalla.
	var falso := Club.new("x", "D. Limache")
	_comprobar(PantallaEstadio.abreviatura(falso) == "LIM",
		"una inicial con punto no cuenta como palabra ('D. Limache' -> %s)" % \
			PantallaEstadio.abreviatura(falso))

	## La pantalla cuelga bajo el techo y sobre el césped en los tres niveles.
	var cruces := 0
	for niveles in [1, 2, 3]:
		var perfil := c.perfil_estadio()
		perfil["niveles"] = niveles
		var alto := StadiumBuilder.altura_de(perfil, niveles * 30000)
		var alto_marco: float = clampf(alto * 0.46, 4.2, 9.0)
		var y: float = alto - 0.8 - alto_marco / 2.0
		if y + alto_marco / 2.0 > alto + 0.4 or y - alto_marco / 2.0 < 0.5:
			cruces += 1
			_linea("  nivel %d: pantalla de %.1f..%.1f m contra techo en %.1f" % [
				niveles, y - alto_marco / 2.0, y + alto_marco / 2.0, alto + 0.4])
	_comprobar(cruces == 0, "la pantalla no se cruza con el techo en 1, 2 ni 3 niveles")

	## Las vallas: cada club con su propio juego, y con su nombre dentro.
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var la: Array = StadiumBuilder._anuncios_de(a.perfil_estadio(), a)
	var lb: Array = StadiumBuilder._anuncios_de(b.perfil_estadio(), b)
	_comprobar(la.size() >= 5 and lb.size() >= 5,
		"cada estadio tiene al menos 5 anuncios distintos (%d / %d)" % [la.size(), lb.size()])
	var textos_a: Array = []
	for x: Dictionary in la:
		textos_a.append(String(x["texto"]))
	var textos_b: Array = []
	for x: Dictionary in lb:
		textos_b.append(String(x["texto"]))
	_comprobar(textos_a != textos_b, "dos clubes distintos no anuncian lo mismo")
	_comprobar(textos_a.has(a.nombre.to_upper()) and textos_b.has(b.nombre.to_upper()),
		"las vallas de cada club llevan el nombre de su club")
	_linea("  %s: %s" % [a.nombre, ", ".join(textos_a)])
	## La tinta se decide contra el fondo: sobre un panel claro no puede salir
	## texto blanco. Es lo que hacía ilegible la mitad de las 38 marcas.
	var claro: Dictionary = StadiumBuilder._anuncio("PRUEBA", Color(0.95, 0.95, 0.9))
	var oscuro: Dictionary = StadiumBuilder._anuncio("PRUEBA", Color(0.05, 0.06, 0.1))
	_comprobar(Color(claro["tinta"]).get_luminance() < 0.3 \
		and Color(oscuro["tinta"]).get_luminance() > 0.7,
		"el texto de la valla contrasta con su propio fondo")

func _probar_estadio() -> void:
	_titulo("PERFIL DE ESTADIO (lo que ve el visor 3D)")
	var m := Mundo.new()
	m.generar(["CHI"], 2026)
	var c: Club = m.ligas[0].clubes[0]
	var p := c.perfil_estadio()
	_linea("  %s: %s de %d niveles, techo %s, %d butacas" % [
		c.nombre, p["forma"], int(p["niveles"]), p["techo"], int(p["aforo"])])
	## ESTABLE, no aleatorio: el rival tiene que jugar siempre en el mismo
	## recinto. Si se sorteara, cada visita seria a un estadio distinto y el
	## mundo dejaria de parecer un mundo.
	var otra := c.perfil_estadio()
	_comprobar(p["forma"] == otra["forma"] and p["techo"] == otra["techo"],
		"el mismo club da siempre el mismo estadio")
	var m2 := Mundo.new()
	m2.generar(["CHI"], 999)
	var c2: Club = null
	for k: Club in m2.clubes.values():
		if k.nombre == c.nombre:
			c2 = k
			break
	if c2 != null:
		_comprobar(c2.perfil_estadio()["forma"] == p["forma"],
			"el estadio no depende de la semilla de la partida")
	## Y el tamano manda sobre el gusto: un club chico no puede tener tres
	## bandejas por mucha reputacion que se le ponga.
	var formas := {}
	var mal := 0
	for k: Club in m.clubes.values():
		var q := k.perfil_estadio()
		formas[q["forma"]] = true
		if k.rep < 62 and int(q["niveles"]) > 1:
			mal += 1
		if int(q["aforo"]) <= 0:
			mal += 1
	_linea("  formas distintas en el mundo: %d" % formas.size())
	_comprobar(formas.size() >= 5, "no todos los clubes tienen el mismo estadio (%d formas)" % formas.size())
	_comprobar(mal == 0, "los niveles y el aforo son coherentes con el club (%d raros)" % mal)
	_probar_pantalla_y_vallas(m)

func _probar_continental() -> void:
	_titulo("COPAS CONTINENTALES")
	var m := Mundo.new()
	m.generar([], 5150)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	_linea("  torneos sorteados: %s" % [m.continentales.keys()])
	_comprobar(m.continentales.size() >= 2, "se sortean al menos dos torneos continentales")

	var vacios := 0
	for k: String in m.continentales:
		var t: Continental = m.continentales[k]
		_linea("  %-5s %-28s %2d inscritos, %2d vivos, %s" % [
			k, Continental.nombre_conti(k), t.participantes.size(), t.vivos.size(),
			t.nombre_de_ronda()])
		if t.participantes.is_empty():
			vacios += 1
	_comprobar(vacios == 0, "ningun torneo se sortea vacio (%d vacios)" % vacios)

	## Nadie puede estar en dos torneos de la misma confederacion a la vez.
	var en_dos := 0
	var visto := {}
	for k: String in m.continentales:
		var t: Continental = m.continentales[k]
		for c: Club in t.participantes:
			if visto.has(c.id) and Continental.confed_de(visto[c.id]) == Continental.confed_de(k):
				en_dos += 1
			visto[c.id] = k
	_comprobar(en_dos == 0, "ningun club juega dos copas de su misma confederacion (%d)" % en_dos)

	## Y lo que de verdad importa: que el torneo LLEGUE a tener campeon. Un
	## torneo que se queda sin nadie vivo antes de la final no reparte el premio
	## y ademas no se nota: no revienta nada, simplemente no pasa.
	var mio := m.mi_continental()
	_comprobar(mio != null, "tu club juega una copa continental")
	if mio != null:
		_linea("  la tuya: %s con %d inscritos" % [mio.nombre, mio.participantes.size()])
	var con_campeon := 0
	for k: String in m.continentales:
		var t: Continental = m.continentales[k]
		var vueltas := 0
		while t.en_curso() and vueltas < 20:
			t.jugar_ronda()
			vueltas += 1
		if t.campeon != null:
			con_campeon += 1
			_linea("  campeon de %s: %s" % [Continental.nombre_conti(k), t.campeon.nombre])
	_comprobar(con_campeon == m.continentales.size(),
		"todos los torneos llegan a tener campeon (%d de %d)" % [con_campeon, m.continentales.size()])

	## Y que ganar TU continental celebre el titulo -confianza, socios, moral al
	## tope- igual que la liga o la copa. El gancho vive en Mundo.avanzar_semana(),
	## no en jugar_ronda(): se prueba forzando una final a dos y comprobando que
	## SI mi club sale campeon, cae en la vitrina en la semana exacta.
	## Una sola final forzada puede perderla hasta el favorito absoluto -es una
	## eliminatoria de un partido, no una liga-, así que se insiste con semillas
	## distintas antes de rendirse. Sin insistir, esta prueba salía inconclusa
	## una de cada dos corridas y no decía nada real.
	var conti_verificado := false
	var ultimo_muro_antes := 0
	var ultimo_muro_despues := 0
	for intento_semilla in 6:
		var m3 := Mundo.new()
		m3.generar(["CHI"], 5150 + intento_semilla)
		m3.tomar_el_mando(m3.ligas[0].clubes[0].id)
		var t: Continental = m3.mi_continental()
		if t == null:
			continue
		var debil: Club = null
		for c: Club in m3.clubes.values():
			if c.id != m3.mi_club_id and (debil == null or c.rep < debil.rep):
				debil = c
		t.preparar([m3.mi_club(), debil] as Array[Club])
		var muro_antes := m3.logros.muro.size()
		var intentos := 0
		while t.en_curso() and intentos < 10:
			m3.avanzar_semana()
			intentos += 1
		if t.campeon == m3.mi_club():
			ultimo_muro_antes = muro_antes
			ultimo_muro_despues = m3.logros.muro.size()
			conti_verificado = true
			break
	if conti_verificado:
		_comprobar(ultimo_muro_despues > ultimo_muro_antes,
			"ganar un continental de clubes celebra el titulo (vitrina %d -> %d)" % [ultimo_muro_antes, ultimo_muro_despues])
	else:
		_linea("  (el club fuerte perdio la final forzada en las 6 semillas probadas; no se pudo verificar el gancho esta corrida)")
