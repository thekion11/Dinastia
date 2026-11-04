extends BaseIdea
## MEGA AUDITORÍA 4, ÁREA GESTIÓN (4-11-2026, líder): el mundo de gestión llevado al límite.
##   1. OCHO TEMPORADAS seguidas (2 países); al cerrar cada una: guardar y cargar da el mismo mundo, y la integridad se mantiene
##      (un club por jugador, club_id coherente, libres fuera de planteles, contratos ≥ 1 año, sueldos > 0, edades 15-45, medias
##      1-99, cajas sin NaN, planteles 16-40, cada liga con sus clubes y la división del club igual a la de su liga).
##   2. CASOS ABSURDOS sin cuelgues: caja −250 M seis semanas; plantel vacío una semana; todos los jugadores sancionados y
##      lesionados; un club con 60 jugadores; el año 2099.

const PREFIJO := "zz_a4_gestion_"
var _malos: Array[String] = []

func _probar() -> void:
	_titulo("A4 GESTIÓN AL LÍMITE: 8 temporadas con guardado, integridad y casos absurdos")
	Partido.limpiar_contexto()
	var m := Mundo.new()
	var paises: Array[String] = ["CHI", "ARG"]
	m.generar(paises, 20261104)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var tamanos := {}
	for l: Liga in m.ligas:
		tamanos[l.nombre] = l.clubes.size()
	var n_temp := int(OS.get_environment("A4_TEMPORADAS")) if OS.get_environment("A4_TEMPORADAS") != "" else 8
	for t in n_temp:
		m.jugar_temporada()
		m.nueva_temporada()
		_integridad(m, "temporada %d" % (t + 1), tamanos)
		if t % 2 == 1 or OS.get_environment("A4_TEMPORADAS") != "":
			m = _ida_y_vuelta(m, t + 1)
	_comprobar(_malos.is_empty(), "%d temporadas: integridad del mundo y guardado exacto (cada dos, o cada una con A4_TEMPORADAS)%s" % [n_temp, "" if _malos.is_empty() else " — " + str(_malos.slice(0, 8))])
	_absurdos(m)
	for f in DirAccess.get_files_at(Partida.ruta_de(PREFIJO + "x").get_base_dir()):
		if f.begins_with(PREFIJO):
			DirAccess.remove_absolute(Partida.ruta_de(PREFIJO + "x").get_base_dir().path_join(f))

func _malo(t: String) -> void:
	if _malos.size() < 20:
		_malos.append(t)

func _foto(m: Mundo) -> String:
	var d := Partida.instantanea(m)
	d.erase("guardado")
	return JSON.stringify(_redondear(JSON.parse_string(JSON.stringify(d))), "\t", true)

## Los decimales se comparan a 9 cifras: el JSON guarda ~15 cifras y la última puede bailar al ir y volver (0.41695652173913 / …131).
func _redondear(v: Variant) -> Variant:
	if v is float:
		return snappedf(v, 1e-9)
	if v is Dictionary:
		for k in v:
			v[k] = _redondear(v[k])
	elif v is Array:
		for i in (v as Array).size():
			v[i] = _redondear(v[i])
	return v

func _ida_y_vuelta(m: Mundo, t: int) -> Mundo:
	var antes := _foto(m)
	var nombre := PREFIJO + str(t)
	if not Partida.guardar(m, nombre):
		_malo("temporada %d: no se guarda" % t)
		return m
	var c := Partida.cargar(nombre)
	if c == null:
		_malo("temporada %d: no se carga" % t)
		return m
	var despues := _foto(c)
	if despues != antes:
		_malo("temporada %d: la partida cargada NO es idéntica — %s" % [t, _diferencia(antes, despues)])
	return c

func _integridad(m: Mundo, cuando: String, tamanos: Dictionary) -> void:
	var visto := {}
	for l: Liga in m.ligas:
		if l.clubes.size() != int(tamanos.get(l.nombre, l.clubes.size())):
			_malo("%s: %s pasa a %d clubes" % [cuando, l.nombre, l.clubes.size()])
		for c: Club in l.clubes:
			if c.division != l.division():
				_malo("%s: %s en %s con división %d" % [cuando, c.nombre, l.nombre, c.division])
	for c: Club in m.clubes.values():
		if is_nan(float(c.saldo)) or is_inf(float(c.saldo)):
			_malo("%s: caja no numérica en %s" % [cuando, c.nombre])
		if c.plantilla.size() < 16 or c.plantilla.size() > 40:
			_malo("%s: %s con %d jugadores" % [cuando, c.nombre, c.plantilla.size()])
		for j: Jugador in c.plantilla:
			if visto.has(j.id):
				_malo("%s: %s en dos clubes" % [cuando, j.nombre])
			visto[j.id] = true
			if j.club_id != c.id:
				_malo("%s: %s con club_id «%s» en %s" % [cuando, j.nombre, j.club_id, c.nombre])
			if j.anios_contrato < 1 or j.sueldo <= 0:
				_malo("%s: %s con %d años de contrato y sueldo %d" % [cuando, j.nombre, j.anios_contrato, j.sueldo])
			if j.edad < 15 or j.edad > 45 or j.ovr < 1 or j.ovr > 99:
				_malo("%s: %s edad %d media %d" % [cuando, j.nombre, j.edad, j.ovr])
	for j: Jugador in m.libres:
		if visto.has(j.id) or j.club_id != "":
			_malo("%s: el libre %s sigue en un plantel o con club" % [cuando, j.nombre])

func _absurdos(m: Mundo) -> void:
	var c := m.mi_club()
	## Caja hundida: seis semanas a −250 M.
	c.mover_saldo(-250_000_000 - c.saldo)
	for i in 6:
		m.avanzar_semana()
	_comprobar(m.mi_club() != null, "caja a −250 M durante 6 semanas: el mundo sigue (club %s)" % (m.mi_club().nombre if m.mi_club() else "—"))
	## Todos sancionados y lesionados: se juega igual.
	var otro: Club = m.ligas[0].clubes[3]
	for j: Jugador in otro.plantilla:
		j.lesion = 3
		j.suspension = 1
	var once := otro.once()
	_comprobar(once.size() >= 7, "un club con todos lesionados y sancionados aún saca %d al campo" % once.size())
	m.avanzar_semana()
	_comprobar(true, "  y la semana se juega sin colgarse")
	## Plantel enorme.
	var grande: Club = m.ligas[1].clubes[2]
	var donante: Club = m.ligas[1].clubes[5]
	var movidos := 0
	while grande.plantilla.size() < 60 and donante.plantilla.size() > 0:
		var j: Jugador = donante.plantilla[0]
		donante.soltar(j)
		grande.fichar(j)
		movidos += 1
	m.avanzar_semana()
	_comprobar(grande.plantilla.size() >= 40, "un club con %d jugadores y otro vacío (%d): la semana se juega" % [grande.plantilla.size(), donante.plantilla.size()])
	## A4-GES-005: un rival se lleva al jugador en mitad de tu negociación → pasa de verdad a su plantel.
	var vend: Club = m.ligas[0].clubes[6]
	var rico: Club = m.ligas[0].clubes[7]
	rico.mover_saldo(2_000_000_000)
	c.mover_saldo(500_000_000 - c.saldo)   ## tras la caja hundida: si no, todo sale «sin caja»
	var tipos := {}
	var llevado: Jugador = null
	for intento in 300:
		if vend.plantilla.is_empty():
			break
		var obj: Jugador = vend.plantilla[intento % vend.plantilla.size()]
		var n := Negociacion.new(m, obj)
		n.rival_id = rico.id
		n.fijo = 0
		var r := n.enviar_oferta()
		tipos[String(r.get("tipo", ""))] = int(tipos.get(String(r.get("tipo", "")), 0)) + 1
		if String(r.get("tipo", "")) in ["rival_traspaso", "rival_firma"]:
			llevado = obj
			break
	_comprobar(llevado != null and rico.plantilla.has(llevado) and not vend.plantilla.has(llevado) and llevado.club_id == rico.id,
		"un rival que se lo lleva en plena negociación lo pasa a SU plantel (y sale del viejo) %s" % str(tipos))
	## Año extremo.
	m.anio = 2099
	m.avanzar_semana()
	_comprobar(m.anio >= 2099, "el año 2099 no rompe el calendario (año %d)" % m.anio)

func _diferencia(a: String, b: String) -> String:
	var la := a.split("\n")
	var lb := b.split("\n")
	for i in mini(la.size(), lb.size()):
		if la[i] != lb[i]:
			var camino: Array[String] = []
			var nivel := la[i].length() - la[i].strip_edges(true, false).length()
			for k in range(i - 1, -1, -1):
				var s := la[k].length() - la[k].strip_edges(true, false).length()
				if s < nivel and la[k].contains("\":"):
					camino.push_front(la[k].strip_edges().get_slice("\"", 1))
					nivel = s
			return "%s · «%s» ≠ «%s»" % ["/".join(camino), la[i].strip_edges().left(70), lb[i].strip_edges().left(70)]
	return "tamaños %d / %d líneas" % [la.size(), lb.size()]
