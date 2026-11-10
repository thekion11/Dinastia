class_name FechaSeleccion
extends RefCounted
## LOS PARTIDOS DE LA FECHA FIFA DE LA SELECCIÓN QUE DIRIGES (10-11, encargo del dueño, punto 2). Antes era un marcador al azar. Ahora, si
## tienes el cargo (`CargoSeleccion`), cada fecha FIFA tu selección juega un partido DE VERDAD (`Partido` entre `SeleccionEquipo`, con tu
## convocatoria): ELIMINATORIA si el rival es de tu confederación y AMISTOSO si no. El rival, de fuerza parecida (±8). Queda `pendiente`
## para que la interfaz lo ofrezca (jugarlo en directo o simularlo, `JornadaSeleccion.ofrecer_fecha`); si nadie lo juega (sin pantalla,
## o semanas simuladas), se simula solo en la semana siguiente. Azar aislado: no cambia nada del resto del juego.
const MARGEN_RIVAL := 8
const MAX_HISTORIAL := 30

## Prepara el partido de la fecha (si tienes el cargo). Devuelve el pendiente, o {}.
static func preparar(m: Mundo, sel: Selecciones, cargo: CargoSeleccion) -> Dictionary:
	if m == null or not cargo.activo():
		return {}
	var mia := cargo.seleccion
	var f := sel.fuerza(mia)
	var confed := CargoSeleccion.confed_de(mia)
	var rivales: Array[String] = []
	for n: String in CargoSeleccion.todas():
		if n != mia and absi(sel.fuerza(n) - f) <= MARGEN_RIVAL:
			rivales.append(n)
	if rivales.is_empty():
		return {}
	var sale := {}   ## la lambda no puede reasignar variables de fuera
	CopasMundo._aislado("fecha%s%d/%d" % [mia, m.anio, m.semana], func() -> void: sale["rival"] = rivales[Azar.ent(0, rivales.size() - 1)])
	var rival := String(sale.get("rival", rivales[0]))
	var tipo := "Eliminatoria" if CargoSeleccion.confed_de(rival) == confed else "Amistoso"
	cargo.fecha_pendiente = {"rival": rival, "tipo": tipo, "anio": m.anio, "semana": m.semana, "local": (m.semana / 3) % 2 == 0}
	return cargo.fecha_pendiente

## Los dos equipos del partido pendiente: [local, visita, mia].
static func equipos(m: Mundo, sel: Selecciones, cargo: CargoSeleccion) -> Array:
	var p := cargo.fecha_pendiente
	var mia := SeleccionEquipo.club_de(m, cargo.seleccion, sel.fuerza(cargo.seleccion), int(p["anio"]), cargo.convocados)
	var rival := SeleccionEquipo.club_de(m, String(p["rival"]), sel.fuerza(String(p["rival"])), int(p["anio"]))
	return [mia, rival, mia] if bool(p.get("local", true)) else [rival, mia, mia]

## Simula el pendiente (azar aislado) y lo cierra. Devuelve la línea del resultado.
static func simular(m: Mundo, sel: Selecciones, cargo: CargoSeleccion) -> String:
	if cargo.fecha_pendiente.is_empty():
		return ""
	var eq := equipos(m, sel, cargo)
	var p := Partido.new(eq[0], eq[1], false)
	CopasMundo._aislado("fecha_sim%s%d/%d" % [cargo.seleccion, int(cargo.fecha_pendiente["anio"]), int(cargo.fecha_pendiente["semana"])], func() -> void: p.simular())
	return cerrar(m, cargo, p)

## Apunta el resultado de un partido ya jugado (en directo o simulado) y deja la fecha sin pendiente.
static func cerrar(m: Mundo, cargo: CargoSeleccion, p: Partido) -> String:
	var tipo := String(cargo.fecha_pendiente.get("tipo", "Amistoso"))
	var linea := "%s: %s %d - %d %s" % [tipo, p.local.nombre, p.goles_local, p.goles_visita, p.visita.nombre]
	cargo.fechas.push_front({"linea": linea, "anio": m.anio if m != null else 0})
	while cargo.fechas.size() > MAX_HISTORIAL:
		cargo.fechas.pop_back()
	cargo.fecha_pendiente = {}
	if m != null and m.prensa != null:
		m.prensa.noticia.emit("🌍 " + linea, "La selección que diriges cierra la fecha internacional.")
	return linea

## Cada semana: si quedó un pendiente de una semana anterior (nadie lo jugó), se simula; si es fecha FIFA, se prepara el nuevo.
static func semana(m: Mundo, sel: Selecciones, cargo: CargoSeleccion, es_fecha_fifa: bool) -> void:
	if not cargo.fecha_pendiente.is_empty() and (int(cargo.fecha_pendiente["semana"]) != m.semana or int(cargo.fecha_pendiente["anio"]) != m.anio):
		simular(m, sel, cargo)
	if es_fecha_fifa:
		preparar(m, sel, cargo)
