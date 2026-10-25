extends BaseIdea
## PRUEBA DIFERENCIAL DE `Prensa.resolver` (fase 0, 25-10-2026).
##
## Resuelve CADA evento del despacho -los de `_pool`, el del fondo que inyecta `Mundo` y las variantes sin
## jugador o con el tema ya cerrado- con "a" y con "b", con varias semillas fijas de `Azar` para pasar por las
## dos ramas de los sorteos, y anota todo lo que una decisión puede mover: lo publicado, la caja, la confianza,
## el ánimo, la moral y la ficha del jugador implicado, los efectos que quedan, las señales y hasta el siguiente
## número de `Azar` (si una rama consumiera un sorteo de más o de menos, el número cambiaría).
##
## Cómo se usa: `F0E_GUARDAR=1 herramientas/ideas.sh f0e_resolver` fija la referencia en
## `/tmp/aud/f0e_antes.json`; sin la variable, la prueba compara contra esa referencia (si existe) y deja la
## pasada actual en `/tmp/aud/f0e_ahora.json`. Las comprobaciones propias (todos los ids cubiertos, las dos
## ramas de cada sorteo vistas, cada decisión publica algo) valen aunque no haya referencia.

const REFERENCIA := "/tmp/aud/f0e_antes.json"
const ULTIMA := "/tmp/aud/f0e_ahora.json"
const SEMILLAS: Array[int] = [101, 202, 303, 404, 505, 606, 707, 808]

## [id, quién es el jugador del evento, preparación]. Quién: "fig" (mejor media), "joven" (el más joven),
## "capi" (el capitán), "otro" (uno cualquiera estable), "veterano" (el mayor: la cesión no se puede) o "".
const CASOS: Array = [
	["fondo_presiona", "joven", ""], ["fondo_presiona", "", ""],
	["retiro_joven", "otro", ""], ["virus_fifa", "", ""], ["filtracion_agente", "", ""],
	["hostil", "fig", ""], ["comercial", "fig", ""],
	["aumento", "fig", ""], ["aumento", "", ""],
	["benefico", "", ""], ["gira", "", ""], ["docu", "", ""],
	["agente", "fig", ""], ["agente", "", ""], ["tv", "", ""],
	["espia", "", ""], ["provoca", "", ""], ["aniversario", "", ""], ["huelgaBono", "", ""],
	["tunel", "", ""], ["viral", "otro", ""], ["viral", "", ""],
	["capitan", "capi", ""], ["capitan", "", ""], ["silencio", "", ""],
	["cambio_posicion", "otro", "dato"], ["cambio_posicion", "otro", ""], ["cambio_posicion", "", ""],
	["sponsor_rueda", "", ""], ["apuestas", "otro", ""], ["apuestas", "", ""],
	["huelga_impagos", "", "rojo"], ["derbi_amenaza", "", ""],
	["reclamo", "", "arbitro"], ["reclamo", "", "abogado"], ["reclamo", "", ""],
	["lobby_arbitral", "", "enojo"],
	["prestamoJuv", "joven", ""], ["prestamoJuv", "veterano", ""], ["prestamoJuv", "", ""],
	["sub20", "joven", ""], ["sub20", "", ""],
	["inexistente", "", ""], ["", "", "vacio"],
]

## Los que tiran `Azar.suerte` en una opción: [id/op] -> se tienen que ver las dos ramas con las semillas.
const CON_SORTEO: Array[String] = ["retiro_joven/a", "virus_fifa/a", "tunel/a", "tunel/b", "apuestas/b",
	"derbi_amenaza/b", "reclamo/a", "lobby_arbitral/a"]

## Los que sortean algo (`Azar`) en alguna rama: se repasan con las ocho semillas; el resto, con dos.
const SORTEAN: Array[String] = ["retiro_joven", "virus_fifa", "filtracion_agente", "hostil", "fondo_presiona",
	"tunel", "apuestas", "derbi_amenaza", "reclamo", "lobby_arbitral", "prestamoJuv"]
## Los que, sin jugador (se fue del plantel antes de firmar), no tienen nada que publicar.
const CALLAN_SIN_JUGADOR: Array[String] = ["fondo_presiona", "aumento", "agente", "prestamoJuv", "sub20"]

var _noticias: Array = []
var _resueltos: Array = []
var _movimientos: Array = []

func _probar() -> void:
	_titulo("F0E: Prensa.resolver, prueba diferencial de todos los eventos")
	## Un solo país: la prueba restaura el mundo cientos de veces y el resto del planeta no cuenta aquí.
	var base := Mundo.new()
	base.generar(["CHI"], 4242)
	base.tomar_el_mando(base.ligas[0].clubes[0].id)
	base.mi_club().mover_saldo(300000000)
	_preparar_plantel(base)
	var foto := Partida.instantanea(base)
	_cubre_la_baraja(base)

	var todo := {}
	var titulos := {}          ## "id/op" -> {titulo: true}, juntando todas las variantes y semillas
	var mudos: Array[String] = []        ## con su jugador y sin titular (no debería haber)
	var sin_cierre: Array[String] = []   ## sin jugador: debe callar, pero cerrar el tema y avisar
	var esperados := 0
	for caso: Array in CASOS:
		var id := String(caso[0])
		var semillas: Array[int] = SEMILLAS if id in SORTEAN else SEMILLAS.slice(0, 2)
		for op: String in ["a", "b"]:
			for s: int in semillas:
				esperados += 1
				var clave := "%s|%s|%s|%s|%d" % [caso[0], caso[1], caso[2], op, s]
				var r := _un_caso(foto, caso, op, s)
				todo[clave] = r
				var t := "%s/%s" % [id, op]
				if not titulos.has(t):
					titulos[t] = {}
				var titular := String((r["salida"] as Dictionary).get("titulo", ""))
				(titulos[t] as Dictionary)[titular] = true
				if id == "":
					## Nada pendiente: no hay nada que firmar ni que avisar.
					if not (r["salida"] as Dictionary).is_empty() or not (r["resueltos"] as Array).is_empty():
						sin_cierre.append(clave)
					continue
				if id == "inexistente":
					## Un id sin función en la tabla se cierra sin publicar, como el `match` sin rama.
					if titular != "" or not (r["pendiente"] as Dictionary).is_empty() or (r["resueltos"] as Array).size() != 1:
						sin_cierre.append(clave)
					continue
				if String(caso[1]) == "" and id in CALLAN_SIN_JUGADOR:
					if titular != "" or not (r["pendiente"] as Dictionary).is_empty() or (r["resueltos"] as Array).size() != 1:
						sin_cierre.append(clave)
				elif titular == "":
					mudos.append(clave)
	_comprobar(todo.size() == esperados, "se resolvieron %d casos" % todo.size())
	_comprobar(sin_cierre.is_empty(), "sin jugador, sin tema o con un id desconocido se cierra como debe (mal: %s)" % str(sin_cierre))
	_comprobar(mudos.is_empty(), "toda decisión con su jugador publica un titular (mudas: %s)" % str(mudos))
	var una_rama: Array[String] = []
	for t: String in CON_SORTEO:
		if (titulos[t] as Dictionary).size() < 2:
			una_rama.append(t)
	_comprobar(una_rama.is_empty(), "las semillas pasan por las dos ramas de cada sorteo (solo una: %s)" % str(una_rama))

	var texto := JSON.stringify(todo, " ", true)
	DirAccess.make_dir_recursive_absolute("/tmp/aud")
	_escribir(ULTIMA, texto)
	if OS.get_environment("F0E_GUARDAR") == "1":
		_escribir(REFERENCIA, texto)
		_linea("  referencia guardada en %s (%d bytes)" % [REFERENCIA, texto.length()])
		return
	if not FileAccess.file_exists(REFERENCIA):
		_linea("  (sin referencia en %s: solo comprobaciones propias)" % REFERENCIA)
		return
	var antes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(REFERENCIA))
	var ahora: Dictionary = JSON.parse_string(texto)
	var distintos: Array[String] = []
	for k: String in antes:
		if not ahora.has(k) or JSON.stringify(antes[k], "", true) != JSON.stringify(ahora[k], "", true):
			distintos.append(k)
	for k: String in ahora:
		if not antes.has(k):
			distintos.append(k)
	for k: String in distintos.slice(0, 5):
		_linea("  distinto %s\n    antes %s\n    ahora %s" % [k, JSON.stringify(antes.get(k, {}), "", true),
			JSON.stringify(ahora.get(k, {}), "", true)])
	_comprobar(distintos.is_empty(), "idéntico a la referencia en los %d casos (distintos: %d)" % [antes.size(), distintos.size()])

## El plantel necesita un menor de 21 y un capitán para que cesión, Sub-20 y capitán tengan a quién.
func _preparar_plantel(m: Mundo) -> void:
	var mio := m.mi_club()
	var orden := mio.plantilla.duplicate()
	orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.edad < b.edad)
	var joven: Jugador = orden[0]
	joven.edad = mini(joven.edad, 18)
	joven.pot = maxi(joven.pot, 82)
	var hay_capi := false
	for x: Jugador in mio.plantilla:
		hay_capi = hay_capi or x.capitan
	if not hay_capi:
		(orden[orden.size() - 1] as Jugador).capitan = true

## Todo id que la baraja real puede sacar tiene su caso aquí.
func _cubre_la_baraja(m: Mundo) -> void:
	var mio := m.mi_club()
	m.prensa.arbitro_polemico = "Pérez"
	if m.federacion != null:
		m.federacion.enojo_arbitral = 2
	var cubiertos := {}
	for caso: Array in CASOS:
		cubiertos[String(caso[0])] = true
	var faltan: Array[String] = []
	Azar.sembrar(77)
	for e: Dictionary in m.prensa._pool(m, mio):
		if not cubiertos.has(String(e["id"])):
			faltan.append(String(e["id"]))
	_comprobar(faltan.is_empty(), "todos los ids de la baraja tienen caso (faltan: %s)" % str(faltan))
	m.prensa.arbitro_polemico = ""

func _quien(mio: Club, tipo: String) -> Jugador:
	if mio.plantilla.is_empty() or tipo == "":
		return null
	var orden := mio.plantilla.duplicate()
	match tipo:
		"fig":
			orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr or a.ovr == b.ovr and a.id < b.id)
		"joven":
			orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.edad < b.edad or a.edad == b.edad and a.id < b.id)
		"veterano":
			orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.edad > b.edad or a.edad == b.edad and a.id < b.id)
		"capi":
			orden = orden.filter(func(x: Jugador) -> bool: return x.capitan)
		_:
			orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.id < b.id)
			return orden[mini(3, orden.size() - 1)]
	return orden[0] if not orden.is_empty() else null

func _un_caso(foto: Dictionary, caso: Array, op: String, semilla: int) -> Dictionary:
	var m := Partida.desde_instantanea(foto.duplicate(true))
	var mio := m.mi_club()
	var p := m.prensa
	var id := String(caso[0])
	var prep := String(caso[2])
	var j := _quien(mio, String(caso[1]))
	match prep:
		"rojo":
			mio.saldo = -absi(mio.saldo) - 1000000
		"arbitro":
			p.arbitro_polemico = "Pérez"
		"abogado":
			p.arbitro_polemico = "Pérez"
			p.abogado_en_directorio = true
		"enojo":
			if m.federacion != null:
				m.federacion.enojo_arbitral = 3
	if prep != "vacio":
		p.pendiente = {"id": id, "pid": j.id if j != null else "", "txt": "", "opcion_a": "", "opcion_b": ""}
		if prep == "dato":
			p.pendiente["dato"] = "DC"
	_noticias = []
	_resueltos = []
	_movimientos = []
	p.noticia.connect(func(t: String, c: String) -> void: _noticias.append([t, c]))
	p.evento_resuelto.connect(func(a: String, b: String, t: String, c: String) -> void: _resueltos.append([a, b, t, c]))
	p.movimiento.connect(func(c: String, n: int) -> void: _movimientos.append([c, n]))
	Azar.sembrar(semilla)
	var salida := p.resolver(op)
	return _huella(m, mio, j, salida)

func _huella(m: Mundo, mio: Club, j: Jugador, salida: Dictionary) -> Dictionary:
	var p := m.prensa
	var moral := 0
	var fisico := 0
	var forma := 0
	var susp := 0
	var sueldos := 0
	var sec := 0
	var transf := 0
	for x: Jugador in mio.plantilla:
		moral += x.moral
		fisico += x.fisico
		forma += x.forma
		susp += x.suspension
		sueldos += x.sueldo
		sec += x.pos_sec.size()
		transf += 1 if x.transferible else 0
	var h := {
		"salida": salida, "noticias": _noticias, "resueltos": _resueltos, "movimientos": _movimientos,
		"saldo": mio.saldo, "socios": mio.socios, "plantel": mio.plantilla.size(),
		"moral": moral, "fisico": fisico, "forma": forma, "suspension": susp, "sueldos": sueldos,
		"pos_sec": sec, "transferibles": transf,
		"confianza": m.directiva.confianza if m.directiva != null else -1,
		"animo": p.animo, "funa": p.funa, "rep_entrenador": p.rep_entrenador,
		"pendiente": p.pendiente, "efectos": p.efectos, "impuesto": [p.impuesto_pid, p.impuesto_hasta],
		"clausulas": p.clausulas, "oferta_forzada": p.oferta_forzada, "dato_rival": p.dato_del_rival,
		"presion": p.presion_prometida, "primas": p.primas_activas, "documental": p.semanas_documental,
		"arbitro": p.arbitro_polemico, "cesiones": p.cesiones,
		"federacion": [m.federacion.aliados, m.federacion.enojo_arbitral] if m.federacion != null else [],
		"staff": m.staff.niveles if m.staff != null else {},
		"reputacion": m.roles.reputacion.facetas if m.roles != null and m.roles.reputacion != null else {},
		"azar_despues": Azar.ent(0, 1000000000),
	}
	if j != null:
		h["figura"] = {"moral": j.moral, "sueldo": j.sueldo, "suspension": j.suspension, "fisico": j.fisico,
			"forma": j.forma, "pot": j.pot, "valor": j.valor, "pos_sec": j.pos_sec, "transferible": j.transferible,
			"en_plantel": mio.plantilla.has(j)}
	return h

func _escribir(ruta: String, texto: String) -> void:
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	if f != null:
		f.store_string(texto)
		f.close()
