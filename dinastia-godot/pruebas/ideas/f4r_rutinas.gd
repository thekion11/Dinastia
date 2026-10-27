extends BaseIdea
## f4r · RUTINAS Y VIDA DE LAS PERSONAS (fase 4, bloque 7): la afinidad 0-100 con la gente del
## club sube +2 solo con la primera charla de cada día, baja 1 por cada semana sin hablar, se
## reparte en tres tramos (frío / normal / cercano), sobrevive a guardar y cargar y solo
## cambia el texto del saludo de pasillo (nunca el partido).

func _probar() -> void:
	_titulo("f4r: afinidad con la gente del club")
	var a := AfinidadClub.new()
	_comprobar(a.valor("Ema Soto") == 50 and a.tramo("Ema Soto") == "normal", "empieza en 50, tramo normal")
	_comprobar(a.charlar("Ema Soto", 1, 3, 2) and a.valor("Ema Soto") == 52, "la primera charla del día suma +2")
	_comprobar(not a.charlar("Ema Soto", 1, 3, 2) and a.valor("Ema Soto") == 52, "la segunda del mismo día no suma")
	_comprobar(a.charlar("Ema Soto", 1, 3, 3) and a.valor("Ema Soto") == 54, "otro día de la misma semana, otra vez +2")
	_comprobar(a.charlar("Ema Soto", 2, 3, 2) and a.valor("Ema Soto") == 56, "el mismo día de la semana pero de otro año cuenta como otro día")
	_comprobar(a.valor("Leo Vega") == 50, "las demás personas no cambian")
	## Semanas.
	a.semana(2, 3)
	_comprobar(a.valor("Ema Soto") == 56, "la semana en que hablaste no baja")
	a.semana(2, 4)
	_comprobar(a.valor("Ema Soto") == 55, "una semana sin hablar baja 1")
	a.semana(2, 5)
	_comprobar(a.valor("Ema Soto") == 54 and a.valor("Leo Vega") == 50, "y otra más; quien nunca habló contigo sigue en 50")
	## Tramos y topes.
	a.valores["Ema Soto"] = 34
	_comprobar(a.tramo("Ema Soto") == "frio", "34 = frío")
	a.valores["Ema Soto"] = 35
	_comprobar(a.tramo("Ema Soto") == "normal", "35 = normal")
	a.valores["Ema Soto"] = 69
	_comprobar(a.tramo("Ema Soto") == "normal", "69 = normal")
	a.valores["Ema Soto"] = 70
	_comprobar(a.tramo("Ema Soto") == "cercano", "70 = cercano")
	a.valores["Ema Soto"] = 99
	a.charlar("Ema Soto", 3, 1, 0)
	a.charlar("Ema Soto", 3, 1, 1)
	_comprobar(a.valor("Ema Soto") == 100, "el tope es 100")
	var b := AfinidadClub.new()
	b.valores["Ana Paz"] = 0
	b.semana(1, 1)
	_comprobar(b.valor("Ana Paz") == 0, "y el suelo es 0")
	## Guardar y cargar.
	var c := AfinidadClub.new()
	c.desde_dic(a.a_dic())
	_comprobar(c.valor("Ema Soto") == 100 and not c.charlar("Ema Soto", 3, 1, 1), "a_dic / desde_dic conserva el valor y la charla de hoy")
	var vacia := AfinidadClub.new()
	vacia.desde_dic({})
	_comprobar(vacia.valores.is_empty() and vacia.valor("Cualquiera") == 50, "una partida vieja (sin afinidad) carga vacía")
	## En el mundo: cuelga de `Mundo`, baja cada semana y va en la partida.
	var m := _mundo(41)
	m.reloj.sincronizar(m.anio, m.semana)
	m.afinidad.charlar("Ema Soto", m.anio, m.semana, m.reloj.dia)
	_comprobar(m.afinidad.valor("Ema Soto") == 52, "el mundo tiene su afinidad")
	var inst := Partida.instantanea(m)
	_comprobar(inst.has("afinidad"), "va en la instantánea de la partida")
	var m2 := Partida.desde_instantanea(inst)
	_comprobar(m2 != null and m2.afinidad.valor("Ema Soto") == 52, "y vuelve al cargar la partida")
	var sem0 := m.semana
	var anio0 := m.anio
	m.afinidad._ultima_semana["Ema Soto"] = "%d|%d" % [anio0, sem0 - 1]
	m.avanzar_semana()
	_comprobar(m.afinidad.valor("Ema Soto") == 51, "al pasar la semana sin hablar, baja 1 (%d)" % m.afinidad.valor("Ema Soto"))
	## La frase de pasillo: por tu nombre, según el tramo, y la charla se anota.
	var g := {"nombre": "Ema Soto", "clave": "secretaria", "puesto": "Secretaria"}
	m.afinidad.valores["Ema Soto"] = 20
	PedidoPartida.dt_nombre_elegido = "Carlos Prueba"
	var dt := "Carlos"
	var fria := RecorridoCharla.pasillo(m, g)
	_comprobar(fria != "" and fria.contains(dt), "la persona te saluda por tu nombre (%s)" % fria)
	_comprobar(m.afinidad.valor("Ema Soto") == 22, "y la charla se anota (+2)")
	var frases_frias := RecorridoCharla._pasillo("frio")
	var frases_cercanas := RecorridoCharla._pasillo("cercano")
	var frases_normales := RecorridoCharla._pasillo("normal")
	_comprobar(frases_frias.size() == 3 and frases_cercanas.size() == 3 and frases_normales.size() == 3, "tres frases por tramo")
	var todas: Array = frases_frias + frases_cercanas + frases_normales
	var distintas := {}
	for f: String in todas:
		distintas[f] = true
	_comprobar(distintas.size() == 9, "las nueve son distintas")
	m.afinidad.valores["Leo Vega"] = 80
	var cerca := RecorridoCharla.pasillo(m, {"nombre": "Leo Vega", "clave": "jardinero", "puesto": "Jardinero"})
	_comprobar(cerca in _con_nombre(frases_cercanas, dt), "con afinidad alta sale una frase del tramo cercano")
	_comprobar(RecorridoCharla.pasillo(null, g) == "", "sin partida no hay frase")
	## No cambia el partido: la huella del mundo no depende de la afinidad.
	var h1 := _huella(_mundo(43))
	var m3 := _mundo(43)
	m3.afinidad.valores["Ema Soto"] = 3
	_comprobar(h1 == _huella(m3), "la afinidad no cambia la simulación")

func _con_nombre(frases: Array, dt: String) -> Array:
	var salida: Array = []
	for f: String in frases:
		salida.append(f % dt)
	return salida

func _huella(m: Mundo) -> String:
	m.avanzar_semana()
	var c := m.mi_club()
	return "%d|%d|%d" % [c.saldo, c.confianza, m.semana]
