extends BaseIdea
## SESIÓN 6 (26-10-2026), plan §10: los treinta logros a largo plazo (`LogrosLargo`).
## Cada uno, uno por uno: a un paso de la meta NO cae y en la meta SÍ. Además: los
## heredados no se anuncian, la carrera cuenta también los partidos simulados, el
## guardado los conserva (y una partida vieja se reconstruye) y la lista se pinta.

var _m: Mundo
var _lg: Logros

func _probar() -> void:
	_titulo("S6: LOS 30 LOGROS A LARGO PLAZO")
	_m = _mundo(6060, 0)
	_lg = _m.logros
	_catalogo()
	_heredados()
	## Base hecha: a partir de aquí cada logro se prueba por separado.
	_lg.revisar_largos()
	var malos: Array[String] = []
	for f: Array in LogrosLargo.CATALOGO:
		var clave := String(f[0])
		var meta := int(f[4])
		_lg.largos.erase(clave)
		_poner(clave, meta - 1)
		var antes := _lg.revisar_largos().has(clave)
		_poner(clave, meta)
		var ahora := _lg.revisar_largos().has(clave)
		if antes or not ahora:
			malos.append("%s (a %d: %s, en %d: %s)" % [clave, meta - 1, antes, meta, ahora])
		_poner(clave, 0)
	_comprobar(malos.is_empty(), "los 30 caen justo en su meta y no antes %s" % (", ".join(malos) if not malos.is_empty() else ""))
	_carrera_y_guardado()
	_pantalla()

func _catalogo() -> void:
	var claves := {}
	var ok := true
	for f: Array in LogrosLargo.CATALOGO:
		ok = ok and f.size() == 5 and int(f[4]) > 0 and not claves.has(f[0])
		claves[f[0]] = true
	_comprobar(LogrosLargo.CATALOGO.size() == 30 and ok, "30 logros, claves únicas y meta positiva")
	Idiomas.idioma = "en"
	var sin := []
	for f: Array in LogrosLargo.CATALOGO:
		if Idiomas.t(String(f[2])) == String(f[2]) or Idiomas.t(String(f[3])) == String(f[3]):
			sin.append(f[0])
	Idiomas.idioma = "es"
	_comprobar(sin.is_empty(), "títulos y descripciones traducidos %s" % str(sin))

## Un club que ya cumple al llegar: se apunta como heredado y sin aviso.
func _heredados() -> void:
	var c := _m.mi_club()
	c.rep = 95
	c.socios = 60000
	var avisos: Array = []
	var cb := func(clave: String, _i: String, _t: String, _d: String) -> void: avisos.append(clave)
	_lg.logro_desbloqueado.connect(cb)
	var nuevos := _lg.revisar_largos()
	_lg.logro_desbloqueado.disconnect(cb)
	_comprobar(_lg.largos.has("rep_90") and bool(_lg.largos["rep_90"].get("heredado", false)) and _lg.largos.has("socios_50k"),
		"reputación 95 y 60.000 socios al llegar: apuntados como heredados")
	_comprobar(not nuevos.has("rep_90") and not avisos.has("rep_90"), "y no se anuncian como mérito tuyo")
	var hecho := false
	for f: Dictionary in _lg.catalogo_largo():
		if String(f["clave"]) == "rep_90":
			hecho = bool(f["heredado"])
	_comprobar(hecho, "la lista los marca como heredados")
	c.rep = 60
	c.socios = 1000

func _poner(clave: String, n: int) -> void:
	var c := _m.mi_club()
	match clave.split("_")[0]:
		"anios": _m.anio = _lg.anio_inicio + n
		"pj": _lg.carrera["pj"] = n
		"pg": _lg.carrera["pg"] = n
		"racha": _lg.rachas["ganando_max"] = n
		"invicto": _lg.rachas["invicto_max"] = n
		"titulos":
			_m.directiva.trofeos.clear()
			for i in n:
				_m.directiva.trofeos.append("Copa %d" % i)
		"cantera":
			_lg.canteranos_debutados.clear()
			for i in n:
				_lg.canteranos_debutados["c%d" % i] = true
		"goleador": _lg.rec["goles"] = {"Fulano": n}
		"fiel": _lg.rec["pj"] = {"j1": {"nombre": "Fulano", "n": n}}
		"publico": _lg.rec["mas_publico"] = {"n": n}
		"aforo": c.estadio_aforo = n
		"socios": c.socios = n
		"rep": c.rep = n
		"caja": c.saldo = int(ceil(float(n) * 1000000.0 / Eco.ECO))
		"once":
			for j: Jugador in c.plantilla:
				j.ovr = n
		"dt", "fairplay":
			_lg.premios.clear()
			for i in n:
				_lg.premios.append({"dt_es_mio": true, "fairplay_es_mio": true})
		"ideal": _lg.premios = [{"ideal_mios": n}]

func _carrera_y_guardado() -> void:
	_lg.carrera = {"pj": 0, "pg": 0}
	_lg.tras_partido_simulado(true, false)
	_lg.tras_partido_simulado(false, true)
	_comprobar(int(_lg.carrera["pj"]) == 2 and int(_lg.carrera["pg"]) == 1, "los partidos simulados también cuentan (2 PJ, 1 PG)")
	_lg.largos["pj_100"] = {"anio": 2031, "semana": 4}
	var d := _lg.a_dic()
	var otro := Logros.new(_m)
	otro.desde_dic(JSON.parse_string(JSON.stringify(d)))
	_comprobar(otro.largos.has("pj_100") and int(otro.carrera["pj"]) == 2 and otro._largos_base, "el guardado conserva los largos, la carrera y la base")
	## Una partida de antes de esta tanda: sin «carrera», se rehace con el cara a cara.
	d.erase("carrera")
	d.erase("largos")
	d.erase("largos_base")
	d["h2h"] = {"x": {"pj": 7, "pg": 4, "pe": 1, "pp": 2, "gf": 9, "gc": 5}, "y": {"pj": 3, "pg": 1, "pe": 1, "pp": 1, "gf": 3, "gc": 3}}
	var viejo := Logros.new(_m)
	viejo.desde_dic(JSON.parse_string(JSON.stringify(d)))
	_comprobar(int(viejo.carrera["pj"]) == 10 and int(viejo.carrera["pg"]) == 5 and viejo._largos_base and viejo.largos.is_empty(),
		"una partida vieja rehace la carrera (10 PJ, 5 PG) y no marca heredados")

func _pantalla() -> void:
	var lista := VBoxContainer.new()
	add_child(lista)
	var texto := func(tam: int, col: Color) -> Label:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", tam)
		l.add_theme_color_override("font_color", col)
		return l
	_lg.largos.clear()
	_lg.carrera = {"pj": 312, "pg": 150}
	ListaLogrosLargo.pintar(lista, _lg, texto)
	var barras := lista.find_children("*", "ProgressBar", true, false).size()
	var textos := ""
	for l in lista.find_children("*", "Label", true, false):
		textos += (l as Label).text + "\n"
	_comprobar(textos.contains("A LARGO PLAZO") and textos.contains("312 / 500") and barras >= 25, "la lista se pinta con su progreso (312 / 500) y %d barras" % barras)
	_comprobar(ListaLogrosLargo.cifra({"clave": "caja_500m", "valor": 37, "meta": 500}) == "37 / 500 M"
		and ListaLogrosLargo.cifra({"clave": "socios_50k", "valor": 48213, "meta": 50000}) == "48.213 / 50.000", "cifras con miles y millones")
	lista.queue_free()
