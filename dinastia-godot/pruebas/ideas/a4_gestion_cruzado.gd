extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), repaso 5 CRUZADO desde mundo_3d sobre GESTIÓN: invariantes del mundo simulado, cada 4 semanas, durante 2,3 temporadas y 2 semillas (LARGO=1 añade 10 temporadas) con 2 países.
##   1. Cada jugador está en UN solo sitio (un plantel o los libres) y su `club_id` es el de su plantel.
##   2. Rangos: edad, valoración, forma, moral, físico, sueldo, años de contrato, goles; clubes: saldo, confianza, reputación, socios, aforo, entrada.
##   3. Tablas: la suma de goles a favor = en contra; pts = victoria×g + e; pj = g + e + p.
const SEMILLAS := [101, 5150]
const SEMANAS := 70
const SEMANAS_LARGO := 520   ## 10 temporadas, una semilla, solo Chile

func _probar() -> void:
	_titulo("A4 CRUZADO (gestión): invariantes del mundo simulado, 2 semillas × %d semanas × 2 países + casos extremos" % SEMANAS)
	for semilla in SEMILLAS:
		await _simular_mundo(semilla)
	await _extremos()
	if OS.get_environment("LARGO") == "1":
		await _simular_mundo(31, SEMANAS_LARGO, ["CHI"])

func _simular_mundo(semilla: int, semanas: int = SEMANAS, paises_sel: Array = ["CHI", "ARG"]) -> void:
	Partido.limpiar_contexto()
	var m := Mundo.new()
	var paises: Array[String] = []
	paises.assign(paises_sel)
	m.generar(paises, semilla)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var fallos: Dictionary = {}
	var muestras := 0
	var min_plantel := 999
	var max_plantel := 0
	for sem in semanas + 1:
		if sem % 4 == 0:
			muestras += 1
			var r := _revisar(m)
			for k in r:
				fallos[k] = int(fallos.get(k, 0)) + int(r[k])
			min_plantel = mini(min_plantel, int(r.get("_min", 999)))
			max_plantel = maxi(max_plantel, int(r.get("_max", 0)))
		if sem < semanas:
			m.avanzar_semana()
		if sem % 20 == 0:
			await get_tree().process_frame
	fallos.erase("_min")
	fallos.erase("_max")
	print("  semilla %d: %d muestras, planteles de %d a %d, fallos %s" % [semilla, muestras, min_plantel, max_plantel, str(fallos)])
	for k in fallos:
		_comprobar(false, "semilla %d: %s (%d veces)" % [semilla, k, int(fallos[k])])
	_comprobar(fallos.is_empty(), "semilla %d: todos los invariantes se cumplen en %d muestras" % [semilla, muestras])

func _revisar(m: Mundo) -> Dictionary:
	var f := {}
	var vistos := {}
	var minp := 999
	var maxp := 0
	for l in m.ligas:
		for c: Club in l.clubes:
			minp = mini(minp, c.plantilla.size())
			maxp = maxi(maxp, c.plantilla.size())
			if c.plantilla.size() < 11:
				_suma(f, "plantel de menos de 11 (%s)" % c.nombre)
			if not is_finite(float(c.saldo)) or c.confianza < 0 or c.confianza > 100 or c.rep < 1 or c.rep > 100 or c.socios < 0 or c.estadio_aforo <= 0 or c.precio_entrada <= 0.0:
				_suma(f, "club con valores fuera de rango")
			for j: Jugador in c.plantilla:
				if vistos.has(j.id):
					_suma(f, "jugador repetido en dos sitios")
				vistos[j.id] = true
				if j.club_id != c.id:
					_suma(f, "club_id del jugador distinto del de su plantel")
				_rangos(f, j)
	for j: Jugador in m.libres:
		if vistos.has(j.id):
			_suma(f, "jugador repetido (libre y en un plantel)")
		vistos[j.id] = true
		_rangos(f, j)
	for l in m.ligas:
		var gf := 0
		var gc := 0
		for id in l.tabla_puntos:
			var t: Dictionary = l.tabla_puntos[id]
			gf += int(t.get("gf", 0))
			gc += int(t.get("gc", 0))
			if int(t.get("pts", 0)) != l.puntos_victoria * int(t.get("g", 0)) + int(t.get("e", 0)) - int(t.get("sancion", 0)):
				_suma(f, "puntos distintos de victorias×%d + empates" % l.puntos_victoria)
			if int(t.get("pj", 0)) != int(t.get("g", 0)) + int(t.get("e", 0)) + int(t.get("p", 0)):
				_suma(f, "partidos jugados distintos de g+e+p")
		if gf != gc:
			_suma(f, "goles a favor (%d) distintos de en contra (%d) en %s" % [gf, gc, l.nombre])
	f["_min"] = minp
	f["_max"] = maxp
	return f

func _rangos(f: Dictionary, j: Jugador) -> void:
	if j.edad < 14 or j.edad > 48:
		_suma(f, "edad fuera de 14-48")
	if j.ovr < 1 or j.ovr > 100 or j.pot < 1 or j.pot > 100:
		_suma(f, "ovr/pot fuera de 1-100")
	if j.forma < 0 or j.forma > 100 or j.moral < 0 or j.moral > 100 or j.fisico < 0 or j.fisico > 100:
		_suma(f, "forma/moral/físico fuera de 0-100")
	if j.sueldo < 0 or j.anios_contrato < 0 or j.anios_contrato > 12 or j.goles < 0 or j.lesion < 0 or j.suspension < 0:
		_suma(f, "sueldo/contrato/goles/lesión negativos o contrato >12 años")

func _suma(f: Dictionary, k: String) -> void:
	f[k] = int(f.get(k, 0)) + 1

## ---- casos absurdos: plantel vacío, saldo en los extremos, todos con valoración 1, sin libres: avanzar semanas sin romper nada (un «SCRIPT ERROR» de la salida hace fallar la corrida)
func _extremos() -> void:
	var casos := ["plantel vacío", "saldo −2 000 millones", "saldo +2 000 millones", "todos ovr 1", "sin jugadores libres", "solo 3 jugadores"]
	for caso in casos:
		Partido.limpiar_contexto()
		var m := Mundo.new()
		var paises: Array[String] = ["CHI"]
		m.generar(paises, 777)
		m.tomar_el_mando(m.ligas[0].clubes[0].id)
		var c := m.mi_club()
		match caso:
			"plantel vacío":
				c.plantilla.clear()
			"saldo −2 000 millones":
				c.saldo = -2000000000
			"saldo +2 000 millones":
				c.saldo = 2000000000
			"todos ovr 1":
				for j: Jugador in c.plantilla:
					j.ovr = 1
					j.pot = 1
			"sin jugadores libres":
				m.libres.clear()
			"solo 3 jugadores":
				while c.plantilla.size() > 3:
					c.plantilla.pop_back()
		for i in 6:
			m.avanzar_semana()
		var f := _revisar(m)
		f.erase("_min")
		f.erase("_max")
		f.erase("plantel de menos de 11 (%s)" % c.nombre)
		var malos := []
		for k in f:
			if not String(k).begins_with("plantel de menos de 11"):
				malos.append(k)
		_comprobar(malos.is_empty(), "«%s»: 6 semanas después los invariantes siguen%s" % [caso, "" if malos.is_empty() else " — rotos: " + str(malos)])
		_comprobar(is_finite(float(c.saldo)), "«%s»: saldo finito (%d)" % [caso, c.saldo])
