class_name CarreraHabilidad
extends RefCounted
## LOS PUNTOS DE HABILIDAD DE «LA RUTA» (13-11-2026, reglas del dueño). Cada
## nivel da puntos de habilidad; cada ZONA es el promedio de sus habilidades
## concretas, y subir UN punto de una habilidad cuesta:
##  - más cuanto más alta está ya esa habilidad,
##  - más cuanto menos pesa en tu puesto (lo que es clave para tu puesto es lo natural),
##  - más cuanto más nivel tiene tu personaje.
## Y se puede ENTRENAR OTRO PUESTO (cuesta puntos, más si es de otra línea): la
## media sale de las habilidades Y del puesto, así que con las mismas habilidades
## puedes valer mucho más en otro sitio (`Jugador.media_en_puesto`).

const PUNTOS_POR_NIVEL := 6
const SUBE_NIVEL := 0.05          ## cada nivel encarece un 5 %
const PUESTO_MISMA_LINEA := 12
const PUESTO_OTRA_LINEA := 24

## (13-11 noche, ampliación del dueño) Cada ZONA (los seis atributos de siempre) es el
## PROMEDIO de sus habilidades concretas, que es donde se reparten los puntos.
## zona -> [[id, nombre], …]. Los porteros no tienen detalle: su zona es su habilidad.
const DETALLE := {
	"rit": [["aceleracion", "Aceleración"], ["punta", "Velocidad punta"]],
	"tir": [["desmarque", "Desmarque"], ["definicion", "Definición"], ["potencia", "Potencia de tiro"], ["lejano", "Tiro lejano"], ["volea", "Voleas"], ["penal", "Penaltis"]],
	"pas": [["vision", "Visión"], ["centro", "Centros"], ["libre", "Tiros libres"], ["corto", "Pase corto"], ["largo", "Pase largo"], ["efecto", "Efecto"]],
	"reg": [["agilidad", "Agilidad"], ["equilibrio", "Equilibrio"], ["reaccion", "Reacción"], ["control", "Control del balón"], ["conduccion", "Conducción"], ["temple", "Temple"]],
	"def": [["intercepcion", "Intercepción"], ["aereo", "Juego aéreo"], ["marcaje", "Marcaje"], ["entrada", "Entrada"], ["barrida", "Barrida"]],
	"fis": [["salto", "Salto"], ["resistencia", "Resistencia"], ["fuerza", "Fuerza"], ["garra", "Agresividad"]],
}

## Los puntos que tienes. Los de los niveles ya subidos se dan al mirar (también en carreras de antes).
static func puntos(c: CarreraJugador) -> int:
	var r := CarreraRuta.asegurar(c)
	var nivel := int(r["nivel"])
	var dado := int(r.get("hab_nivel", 1)) if typeof(r.get("hab_nivel")) in [TYPE_INT, TYPE_FLOAT] else 1
	var tengo := int(r.get("hab", 0)) if typeof(r.get("hab")) in [TYPE_INT, TYPE_FLOAT] else 0
	if nivel > dado:
		tengo += (nivel - dado) * PUNTOS_POR_NIVEL
	r["hab"] = tengo
	r["hab_nivel"] = maxi(nivel, dado)
	return tengo

## Las habilidades de una zona: [[id, nombre], …] (una sola, la propia zona, si no tiene detalle).
static func de_zona(zona: String) -> Array:
	return DETALLE.get(zona, [[zona, zona.capitalize()]])

## La zona a la que pertenece una habilidad.
static func zona_de(hab: String) -> String:
	var nat := Nativo.de("nuc_zona_habilidad")
	if nat != null:
		return nat.nuc_zona_habilidad(hab)
	return zona_de_gd(hab)

## Gemela GDScript de `nuc_zona_habilidad` (extensión C++, orden 63): respaldo sin binario y comparación en `pruebas/probar_nativo_puras.gd`.
static func zona_de_gd(hab: String) -> String:
	for zona: String in DETALLE:
		for par: Array in DETALLE[zona]:
			if String(par[0]) == hab:
				return zona
	return hab

## El detalle del jugador (habilidad -> valor), creado la primera vez alrededor de cada zona y
## puesto al día si la zona cambió por otro lado (el entreno sube la zona entera).
static func detalle(c: CarreraJugador, j: Jugador) -> Dictionary:
	var r := CarreraRuta.asegurar(c)
	if not r.get("detalle") is Dictionary:
		r["detalle"] = {}
	var d: Dictionary = r["detalle"]
	for zona: String in j.atributos:
		var lista := de_zona(zona)
		var meta := int(j.atributos[zona])
		if not d.has(String(lista[0][0])):
			## Reparto fijo por jugador: cada habilidad se aparta hasta 6 puntos de la zona, y el promedio queda en la zona.
			var nat := Nativo.obj()
			if nat != null and nat.has_method("hab_reparto"):   ## (19-11) el reparto, en C++ (`nativo/src/carrera_nativo.cpp`); gemela: la rama `else`
				var ids := PackedStringArray()
				for par0: Array in lista:
					ids.append(String(par0[0]))
				var rep_c: PackedInt32Array = nat.hab_reparto(j.id, ids, meta)
				for i in lista.size():
					d[ids[i]] = rep_c[i]
			else:
				var desvios: Array = []
				var suma := 0
				for par: Array in lista:
					var dv := (absi(hash(j.id + String(par[0]))) % 13) - 6 if lista.size() > 1 else 0
					desvios.append(dv)
					suma += dv
				for i in lista.size():
					d[String(lista[i][0])] = clampi(meta + int(desvios[i]) - int(round(float(suma) / float(lista.size()))), 1, 99)
		var falta := meta - _promedio(d, lista)
		if falta != 0:
			for par2: Array in lista:
				d[String(par2[0])] = clampi(int(d[String(par2[0])]) + falta, 1, 99)
	return d

static func _promedio(d: Dictionary, lista: Array) -> int:
	var nat := Nativo.obj()
	if nat != null and nat.has_method("hab_promedio"):   ## (19-11) la cuenta, en C++ (`nativo/src/carrera_nativo.cpp`); gemela: `_promedio_gd`
		var vs := PackedInt32Array()
		for par: Array in lista:
			vs.append(int(d.get(String(par[0]), 0)))
		return nat.hab_promedio(vs)
	return _promedio_gd(d, lista)

static func _promedio_gd(d: Dictionary, lista: Array) -> int:
	var suma := 0
	for par: Array in lista:
		suma += int(d.get(String(par[0]), 0))
	return int(round(float(suma) / float(maxi(1, lista.size()))))

static func valor(c: CarreraJugador, j: Jugador, hab: String) -> int:
	return int(detalle(c, j).get(hab, 0))

## Cuánto pesa la ZONA en el puesto del jugador (0 a 1; 0 si no cuenta).
static func peso(j: Jugador, zona: String) -> float:
	var e := PesosPuesto.de(j.pos_e)
	if e.is_empty():
		return 0.0
	var ks: PackedStringArray = e[0]
	var ws: PackedFloat64Array = e[1]
	var i := ks.find(zona)
	return ws[i] if i >= 0 else 0.0

## "clave" (la zona pesa mucho en tu puesto), "util" o "ajena".
static func clase(j: Jugador, zona: String) -> String:
	var w := peso(j, zona)
	return "clave" if w >= 0.2 else ("util" if w >= 0.1 else "ajena")

static func _factor_nivel(c: CarreraJugador) -> float:
	var nat := Nativo.obj()
	if nat != null and nat.has_method("hab_factor_nivel"):   ## (19-11) en C++; gemela: `_factor_nivel_gd`
		return nat.hab_factor_nivel(CarreraRuta.nivel(c))
	return _factor_nivel_gd(c)

static func _factor_nivel_gd(c: CarreraJugador) -> float:
	return 1.0 + float(CarreraRuta.nivel(c) - 1) * SUBE_NIVEL

## (16-11, informe R-08) EL PRECIO ES DE LA ZONA, no de la habilidad: +1 de zona cuesta lo mismo tenga la zona 2
## habilidades (velocidad), 6 (tiro) o 1 (las del portero), y se reparte entre sus habilidades. Antes, +1 de
## velocidad costaba 2 puntos, +1 de tiro 6 y +1 de una zona de portero 1 (seis veces más barato que un delantero).
## Y cada puesto paga según lo que le rinde su mejor zona (`PESO_REF`, el tiro del delantero centro): así un punto de
## habilidad sube la MEDIA más o menos lo mismo en cualquier puesto (portero y delantero, a menos del 20 %).
const PUNTOS_ZONA := 6.0
const PESO_REF := 0.39

static func _factor_puesto(j: Jugador) -> float:
	var nat := Nativo.obj()
	if nat != null and nat.has_method("hab_factor_puesto"):   ## (19-11) en C++; gemela: `_factor_puesto_gd`
		var e0 := PesosPuesto.de(j.pos_e)
		return nat.hab_factor_puesto(e0[1] if not e0.is_empty() else PackedFloat64Array())
	return _factor_puesto_gd(j)

static func _factor_puesto_gd(j: Jugador) -> float:
	var e := PesosPuesto.de(j.pos_e)
	var maximo := 0.0
	for w: float in (e[1] if not e.is_empty() else PackedFloat64Array()):
		maximo = maxf(maximo, w)
	return clampf(maximo / PESO_REF, 0.5, 1.5) if maximo > 0.0 else 1.0

## Lo que cuesta +1 de la zona de esa habilidad, hoy (puede tener decimales: se reparte entre sus habilidades).
static func precio_zona(c: CarreraJugador, j: Jugador, hab: String) -> float:
	var nat := Nativo.obj()
	if nat != null and nat.has_method("hab_precio_zona"):   ## (19-11) la cuenta, en C++; gemela: `_precio_zona_gd`
		var cl := clase(j, zona_de(hab))
		return nat.hab_precio_zona(valor(c, j, hab), 0 if cl == "clave" else (1 if cl == "util" else 2), _factor_nivel(c), _factor_puesto(j))
	return _precio_zona_gd(c, j, hab)

static func _precio_zona_gd(c: CarreraJugador, j: Jugador, hab: String) -> float:
	var v := valor(c, j, hab)
	var base := 1.0 if v < 60 else (2.0 if v < 70 else (3.0 if v < 80 else (5.0 if v < 90 else 7.0)))
	var por_puesto: float = {"clave": 1.0, "util": 1.5, "ajena": 2.0}[clase(j, zona_de(hab))]
	return base * por_puesto * _factor_nivel(c) * _factor_puesto(j) * PUNTOS_ZONA

## Lo que cuesta subir UN punto esa habilidad, hoy: su parte del precio de la zona. Las `n` compras que hacen +1 de
## zona suman el precio de la zona redondeado una sola vez (la k-ésima paga ceil(z·(k+1)/n) − ceil(z·k/n)).
static func coste(c: CarreraJugador, j: Jugador, hab: String) -> int:
	var lista := de_zona(zona_de(hab))
	var d := detalle(c, j)
	var suma := 0
	for par: Array in lista:
		suma += int(d.get(String(par[0]), 0))
	var nat := Nativo.obj()
	if nat != null and nat.has_method("hab_coste"):   ## (19-11) la cuenta, en C++; gemela: lo de abajo
		return nat.hab_coste(suma, lista.size(), precio_zona(c, j, hab))
	var n := float(lista.size())
	var k := float(posmod(suma, lista.size()))
	var z := precio_zona(c, j, hab)
	return maxi(1, ceili(z * (k + 1.0) / n - 0.001) - ceili(z * k / n - 0.001))

static func puede_subir(c: CarreraJugador, m: Mundo, hab: String) -> bool:
	var j := c.jugador(m)
	return j != null and detalle(c, j).has(hab) and valor(c, j, hab) < 99 and puntos(c) >= coste(c, j, hab)

## Sube un punto la habilidad; la zona pasa a ser el promedio nuevo y la media se recalcula.
static func subir(c: CarreraJugador, m: Mundo, hab: String) -> bool:
	if not puede_subir(c, m, hab):
		return false
	var r := CarreraRuta.asegurar(c)
	var j := c.jugador(m)
	var d := detalle(c, j)
	r["hab"] = puntos(c) - coste(c, j, hab)
	d[hab] = int(d[hab]) + 1
	var zona := zona_de(hab)
	j.atributos[zona] = _promedio(d, de_zona(zona))
	if not r.get("pulidos") is Dictionary:
		r["pulidos"] = {}
	(r["pulidos"] as Dictionary)[hab] = int((r["pulidos"] as Dictionary).get(hab, 0)) + 1
	var antes := j.ovr
	j.ovr = maxi(j.ovr, j.media_en(j.pos_e))
	if j.ovr != antes:
		j.tasar()
	return true

# ---------------------------------------------------------------- el puesto

static func _linea(pe: String) -> String:
	return String((PesosPuesto._tabla().get(pe, {}) as Dictionary).get("g", ""))

## Los puestos a los que puede pasar (no se cruza la frontera portero / jugador de campo), el suyo incluido.
static func puestos(j: Jugador) -> Array:
	var sal: Array = []
	for pe: String in PesosPuesto._tabla():
		if (_linea(pe) == "POR") == (_linea(j.pos_e) == "POR"):
			sal.append(pe)
	return sal

## La media que tendría en ese puesto con las habilidades de hoy.
static func media_en(j: Jugador, pe: String) -> int:
	return j.ovr if pe == j.pos_e else j.media_en_puesto(pe)

static func coste_puesto(c: CarreraJugador, j: Jugador, pe: String) -> int:
	var nat := Nativo.obj()
	if nat != null and nat.has_method("hab_coste_puesto"):   ## (19-11) la cuenta, en C++; gemela: `_coste_puesto_gd`
		return nat.hab_coste_puesto(_linea(pe) == _linea(j.pos_e), j.pos_sec.has(pe), _factor_nivel(c))
	return _coste_puesto_gd(c, j, pe)

static func _coste_puesto_gd(c: CarreraJugador, j: Jugador, pe: String) -> int:
	var base := PUESTO_MISMA_LINEA if _linea(pe) == _linea(j.pos_e) else PUESTO_OTRA_LINEA
	if j.pos_sec.has(pe):
		base = int(base / 2.0)   ## un puesto que ya conoces cuesta la mitad
	return maxi(1, ceili(float(base) * _factor_nivel(c) - 0.001))

static func puede_cambiar(c: CarreraJugador, m: Mundo, pe: String) -> bool:
	var j := c.jugador(m)
	return j != null and pe != j.pos_e and puestos(j).has(pe) and puntos(c) >= coste_puesto(c, j, pe)

## Cambia de puesto para siempre (hasta que entrenes otro). Devuelve {antes, despues, semanas} o {}.
static func cambiar(c: CarreraJugador, m: Mundo, pe: String) -> Dictionary:
	if not puede_cambiar(c, m, pe):
		return {}
	var j := c.jugador(m)
	var precio := coste_puesto(c, j, pe)
	var res := j.reconvertir(pe)
	if res.is_empty():
		return {}
	CarreraRuta.asegurar(c)["hab"] = puntos(c) - precio
	return res
