class_name SeleccionesTorneos
extends RefCounted
## QUIÉN JUEGA CADA TORNEO DE SELECCIONES (10-11, encargo del dueño, punto 2) y su montaje con `TorneoSelecciones` + `SeleccionEquipo`.
## El MUNDIAL lo juegan las 32 mejores del escalafón (`Selecciones.ranking`); cada torneo CONTINENTAL, las selecciones de su confederación
## (la Copa América invita a las de la CONCACAF, como en 2024). Último torneo jugado: `Selecciones.ultimo_torneo` (para la interfaz).
const POR_CONFED := {
	"lib": ["Argentina", "Brasil", "Uruguay", "Colombia", "Chile", "Perú", "Ecuador", "Paraguay", "Bolivia", "Venezuela", "México", "EE.UU.", "Costa Rica", "Canadá"],
	"ucl": ["España", "Inglaterra", "Italia", "Alemania", "Francia", "Portugal", "Holanda", "Bélgica", "Croacia", "Dinamarca"],
	"afr": ["Marruecos", "Senegal", "Nigeria", "Egipto", "Camerún", "Sudáfrica"],
	"asia": ["Japón", "Corea", "Irán", "Australia", "Arabia", "Catar"],
	"conc": ["México", "EE.UU.", "Costa Rica", "Canadá"],
	"oce": ["N. Zelanda", "Australia"],
}
const PLAZAS_MUNDIAL := 32

static func _equipos(sel: Selecciones, m: Mundo, nombres: Array, anio: int) -> Array[Club]:
	var out: Array[Club] = []
	for n: String in nombres:
		out.append(SeleccionEquipo.club_de(m, n, sel.fuerza(n), anio))
	return out

static func mundial(sel: Selecciones, m: Mundo, anio: int) -> TorneoSelecciones:
	var nombres: Array = []
	for f: Dictionary in sel.ranking(PLAZAS_MUNDIAL):
		nombres.append(String(f["nombre"]))
	return TorneoSelecciones.crear("Copa del Mundo", anio, _equipos(sel, m, nombres, anio))

static func continental(sel: Selecciones, m: Mundo, clave: String, nombre_torneo: String, anio: int) -> TorneoSelecciones:
	return TorneoSelecciones.crear(nombre_torneo, anio, _equipos(sel, m, POR_CONFED.get(clave, []), anio))

## El club de la selección `nombre` dentro del torneo (o null si no juega).
static func equipo_en(t: TorneoSelecciones, nombre: String) -> Club:
	for c: Club in t.equipos:
		if Nombres.limpiar(c.nombre) == Nombres.limpiar(nombre):
			return c
	return null
