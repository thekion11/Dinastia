class_name CarreraComienzo
extends RefCounted
## EL COMIENZO DE «LA RUTA» (13-11-2026): los tres clubes que te ofrecen tu
## primer contrato y la firma por el que elijas.

## Tres clubes de tres países distintos (el segundo nivel si lo hay): uno de una
## liga humilde, uno de una media y uno de una de las fuertes; y dentro de cada
## liga, uno humilde, uno de media tabla y uno de los fuertes. Tres comienzos
## distintos: minutos fáciles contra escaparate.
static func pruebas(m: Mundo, semilla: int) -> Array[Club]:
	var por_pais := {}
	for l: Liga in m.ligas:
		if l.div <= 2 and (not por_pais.has(l.pais) or l.div > (por_pais[l.pais] as Liga).div):
			por_pais[l.pais] = l
	var fuerza := {}
	for pp: String in por_pais:
		var suma := 0.0
		for cl: Club in (por_pais[pp] as Liga).clubes:
			suma += float(cl.rep)
		fuerza[pp] = suma / float(maxi(1, (por_pais[pp] as Liga).clubes.size()))
	var orden: Array = por_pais.keys()
	orden.sort_custom(func(a: String, b: String) -> bool:
		return float(fuerza[a]) < float(fuerza[b]) or (is_equal_approx(float(fuerza[a]), float(fuerza[b])) and a < b))
	var g := RandomNumberGenerator.new()
	g.seed = semilla
	var out: Array[Club] = []
	var tramos := mini(3, orden.size())
	for k in tramos:
		var desde := int(float(orden.size()) * float(k) / float(tramos))
		var hasta := maxi(desde, int(float(orden.size()) * float(k + 1) / float(tramos)) - 1)
		var liga: Liga = por_pais[orden[g.randi_range(desde, hasta)]]
		var clubes: Array = liga.clubes.duplicate()
		clubes.sort_custom(func(a: Club, b: Club) -> bool: return a.rep < b.rep or (a.rep == b.rep and a.id < b.id))
		if clubes.is_empty():
			continue
		var c0 := int(float(clubes.size() - 1) * float(k) * 0.4)
		var c1 := maxi(c0, int(float(clubes.size() - 1) * minf(1.0, float(k) * 0.4 + 0.2)))
		out.append(clubes[g.randi_range(c0, c1)])
	return out

## Empieza en el club elegido (en vez del que pone `CarreraJugador.crear`).
static func mudar(c: CarreraJugador, m: Mundo, destino: Club) -> void:
	var j := c.jugador(m)
	var origen := c.club(m)
	if j == null or destino == null or origen == destino:
		return
	if origen != null:
		origen.soltar(j)
	destino.fichar(j)
	j.pais = destino.pais
	j.dorsal = CarreraJugador._dorsal_libre(destino)
	j.tasar()
	c.capitan = false   ## (13-11) el brazalete es de un club: en el nuevo hay que ganárselo otra vez
	(CarreraRuta.asegurar(c)["rival"] as Dictionary).clear()
