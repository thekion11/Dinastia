class_name FondoInversion
extends RefCounted
## EL FONDO DE INVERSIÓN (26-9-2026, modo del menú que estaba "en desarrollo":
## "comprar porcentajes de clubes por todo el mundo").
##
## Eres dueño de tu club sede como en el modo Dueño, y además manejas un fondo
## con su propia caja. Con ella compras participaciones de otros clubes (hasta
## un 49 %: el control es de sus socios), que:
##   - valen lo que vale el club, y el club vale según su reputación y su
##     estadio: si sube, tu participación sube;
##   - pagan DIVIDENDOS cada cuatro semanas según cómo les va en su liga;
##   - se venden cuando quieras, con una pequeña comisión.
## El objetivo del modo es que el fondo valga cada vez más.

signal noticia(titulo: String, cuerpo: String)

const MAX_PCT := 0.49
const COMISION := 0.03

var caja: int = 0
var cartera: Dictionary = {}     ## club_id -> porcentaje (0..0.49)
var invertido: Dictionary = {}   ## club_id -> lo que costó (para la rentabilidad)
var historia: Array[int] = []    ## valor total del fondo cada cuatro semanas
var dividendos_totales: int = 0

static func valor_club(c: Club) -> int:
	if c == null:
		return 0
	var base := Eco.ref_caja(float(c.rep)) * 0.6
	base *= 1.0 + clampf(float(c.estadio_aforo) / 60000.0, 0.0, 2.0) * 0.3
	return int(round(base / 1000.0) * 1000.0)

func valor_cartera(m: Mundo) -> int:
	var t := 0
	for cid: String in cartera:
		t += int(round(float(valor_club(m.clubes.get(cid))) * float(cartera[cid])))
	return t

func valor_total(m: Mundo) -> int:
	return caja + valor_cartera(m)

## Compra `pct` (0..1) de un club. Devuelve "" o el motivo.
func comprar(m: Mundo, c: Club, pct: float) -> String:
	if c == null:
		return "ese club no existe"
	if c.id == m.mi_club_id:
		return "tu club sede ya es tuyo entero"
	var tengo := float(cartera.get(c.id, 0.0))
	var p := minf(pct, MAX_PCT - tengo)
	if p <= 0.001:
		return "ya tienes el máximo (49 %)"
	var coste := int(round(float(valor_club(c)) * p * (1.0 + COMISION)))
	if coste > caja:
		return "el fondo no tiene caja: cuesta %s" % Cesiones.dinero(coste)
	caja -= coste
	cartera[c.id] = tengo + p
	invertido[c.id] = int(invertido.get(c.id, 0)) + coste
	noticia.emit("💼 El fondo compra", "%d %% de %s por %s." % [int(round(p * 100.0)), c.nombre, Cesiones.dinero(coste)])
	return ""

## Vende `pct` de lo que tienes de un club. Devuelve "" o el motivo.
func vender(m: Mundo, c: Club, pct: float) -> String:
	if c == null or not cartera.has(c.id):
		return "no tienes nada de ese club"
	var tengo := float(cartera[c.id])
	var p := minf(pct, tengo)
	var ingreso := int(round(float(valor_club(c)) * p * (1.0 - COMISION)))
	caja += ingreso
	var parte := p / tengo
	invertido[c.id] = int(round(float(invertido.get(c.id, 0)) * (1.0 - parte)))
	if tengo - p <= 0.001:
		cartera.erase(c.id)
		invertido.erase(c.id)
	else:
		cartera[c.id] = tengo - p
	noticia.emit("💼 El fondo vende", "%d %% de %s por %s." % [int(round(p * 100.0)), c.nombre, Cesiones.dinero(ingreso)])
	return ""

## Rentabilidad total desde lo invertido (en %).
func rentabilidad(m: Mundo) -> float:
	var inv := 0
	for cid: String in invertido:
		inv += int(invertido[cid])
	if inv <= 0:
		return 0.0
	return (float(valor_cartera(m) + dividendos_totales) / float(inv) - 1.0) * 100.0

## Cada semana: cada cuatro, los dividendos (según el puesto de cada club en
## su liga: los de arriba reparten, los de abajo no) y la foto del valor.
func semana(m: Mundo) -> int:
	if m == null or m.semana % 4 != 0:
		return 0
	var total := 0
	for cid: String in cartera:
		var c: Club = m.clubes.get(cid)
		if c == null:
			continue
		var factor := 0.5
		for l in m.ligas:
			if l.clubes.has(c):
				var t: Array = l.tabla()
				for i in t.size():
					if t[i]["club"] == c:
						factor = 1.0 - float(i) / float(maxi(t.size() - 1, 1))
				break
		total += int(round(float(valor_club(c)) * float(cartera[cid]) * 0.006 * factor))
	caja += total
	dividendos_totales += total
	historia.append(valor_total(m))
	if historia.size() > 60:
		historia.pop_front()
	if total > 0:
		noticia.emit("💼 Dividendos del fondo", "Tus participaciones repartieron %s." % Cesiones.dinero(total))
	return total

func a_dic() -> Dictionary:
	return {"caja": caja, "cartera": cartera.duplicate(), "invertido": invertido.duplicate(),
		"historia": historia.duplicate(), "div": dividendos_totales}

func desde_dic(d: Dictionary) -> void:
	caja = int(d.get("caja", 0))
	cartera = (d.get("cartera", {}) as Dictionary).duplicate()
	invertido = (d.get("invertido", {}) as Dictionary).duplicate()
	historia.clear()
	for v: Variant in d.get("historia", []):
		historia.append(int(v))
	dividendos_totales = int(d.get("div", 0))
