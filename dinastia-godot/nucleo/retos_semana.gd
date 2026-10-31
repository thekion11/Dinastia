class_name RetosSemana
extends RefCounted
## LOS RETOS DE LA SEMANA (semana 6 del plan, «tipo Manager Live», 27-10-2026). Cada semana con partido el club
## recibe tres retos para ESE partido (ganar, ganar por dos, portería a cero...), sacados del marcador y no de
## estadísticas que solo existen al dirigir: valen igual si el partido se dirige en directo o se simula. Cumplir
## uno da dinero a la caja (un porcentaje de la masa salarial semanal: pesa igual en un grande que en uno de
## Ascenso) y suma al recuento de la carrera; los
## tres de una semana, un extra. Se eligen con un hash de la semana y el club: no tocan el azar de la partida.

## [id, texto, premio en % de la masa salarial semanal del club]
const CATALOGO := [
	["ganar", "Gana el próximo partido", 4],
	["ganar_2", "Gana por dos goles o más", 8],
	["cero", "Deja la portería a cero", 6],
	["no_perder", "No pierdas el próximo partido", 2],
	["marcar_2", "Marca dos goles o más", 4],
	["marcar_3", "Marca tres goles o más", 9],
	["encajar_1", "No encajes más de un gol", 3],
]
const EXTRA_TRES := 2.0   ## los tres de una semana: el premio de la semana se dobla

var activos: Array = []        ## [{"id", "texto", "premio"}]
var cumplidos_total: int = 0
var semanas_perfectas: int = 0
var ultimo: Array = []         ## [{"texto", "ok"}] del último partido, para enseñarlo

## Los tres retos de la semana (si ya hay, no los cambia: valen hasta el próximo partido).
func generar(m: Mundo) -> void:
	if not activos.is_empty() or m.mi_club() == null:
		return
	var c := m.mi_club()
	var semanal := float(maxi(c.masa_salarial(), 1000))
	var h := absi(hash([m.anio, m.semana, c.id]))
	var duros := m.tiene_desafio("retos_duros")   ## DesafiosDificultad: solo los difíciles y menos premio
	var orden: Array = range(CATALOGO.size()) if not duros else [1, 2, 5]
	for i in orden.size():
		var j := (h / (i + 1) + i * 7) % orden.size()
		var tmp: int = orden[i]
		orden[i] = orden[j]
		orden[j] = tmp
	for k in 3:
		var r: Array = CATALOGO[orden[k]]
		var pct := float(r[2]) * (DesafiosDificultad.PREMIO_RETOS if duros else 1.0)
		activos.append({"id": String(r[0]), "texto": String(r[1]), "premio": maxi(int(round(semanal * pct / 100.0 / 1000.0)) * 1000, 1000)})
	if m.prensa != null:
		m.prensa.noticia.emit(Idiomas.t("Retos de la semana"), "\n".join(activos.map(func(a: Dictionary) -> String:
			return "🎯 %s (%d €)" % [Idiomas.t(String(a["texto"])), int(a["premio"])])))

static func cumple(id: String, gf: int, gc: int) -> bool:
	match id:
		"ganar":
			return gf > gc
		"ganar_2":
			return gf - gc >= 2
		"cero":
			return gc == 0
		"no_perder":
			return gf >= gc
		"marcar_2":
			return gf >= 2
		"marcar_3":
			return gf >= 3
		"encajar_1":
			return gc <= 1
	return false

## Tras tu partido: juzga los retos, paga los cumplidos a la caja del club y lo cuenta en la prensa.
## Devuelve cuántos se cumplieron.
func evaluar(m: Mundo, gf: int, gc: int) -> int:
	if activos.is_empty():
		return 0
	var c := m.mi_club()
	var ok := 0
	var premio := 0
	ultimo = []
	for r: Dictionary in activos:
		var si := cumple(String(r["id"]), gf, gc)
		ultimo.append({"texto": String(r["texto"]), "ok": si})
		if si:
			ok += 1
			premio += int(r["premio"])
	if ok == activos.size():
		semanas_perfectas += 1
		premio = int(float(premio) * EXTRA_TRES)
	cumplidos_total += ok
	if premio > 0 and c != null:
		c.mover_saldo(premio)
	if m.prensa != null:
		var lineas: Array = ultimo.map(func(u: Dictionary) -> String: return ("✅ " if bool(u["ok"]) else "❌ ") + Idiomas.t(String(u["texto"])))
		m.prensa.noticia.emit(Idiomas.t("Retos de la semana: %d de %d") % [ok, activos.size()],
			"\n".join(lineas) + ("\n" + Idiomas.t("Premio para la caja: %d €.") % premio if premio > 0 else ""))
	activos = []
	return ok

func a_dic() -> Dictionary:
	return {"activos": activos.duplicate(true), "cumplidos": cumplidos_total, "perfectas": semanas_perfectas, "ultimo": ultimo.duplicate(true)}

func desde_dic(d: Dictionary) -> void:
	activos = (d.get("activos", []) as Array).duplicate(true)
	cumplidos_total = int(d.get("cumplidos", 0))
	semanas_perfectas = int(d.get("perfectas", 0))
	ultimo = (d.get("ultimo", []) as Array).duplicate(true)
