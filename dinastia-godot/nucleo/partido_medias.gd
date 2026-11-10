class_name PartidoMedias
extends RefCounted
## LAS CUATRO MEDIAS POR LÍNEA DE UN ONCE (10-11-2026, paso a C++), el bucle de `Partido.fuerza` (4 × `_media_linea`, ~85 µs por once). Con la extensión nativa (`medias_linea`, nativo/src/partido_nativo.cpp) se hace
## de una vez en C++ con las mismas cuentas (ley del ex, arenga, pie del lateral); sin ella, las 4 llamadas a `Partido._media_linea` de siempre (que es la referencia). `pruebas/nativo_partido.gd` las compara.

## [POR, DEF, MED, DEL] del once `once` del partido `p`.
static func de(p: Partido, once: Array[Jugador]) -> PackedFloat64Array:
	var nat := Nativo.obj()
	if nat != null and nat.has_method("medias_linea"):
		return nativo(p, once, nat)
	return gd(p, once)

static func gd(p: Partido, once: Array[Jugador]) -> PackedFloat64Array:
	return PackedFloat64Array([p._media_linea(once, "POR"), p._media_linea(once, "DEF"), p._media_linea(once, "MED"), p._media_linea(once, "DEL")])

static func nativo(p: Partido, once: Array[Jugador], nat: Object) -> PackedFloat64Array:
	var enfrente: Club = p.visita if once == p.once_local else p.local
	var arenga := Partido.ARENGA_BOOST
	if p._factor_arenga > 1.0:
		arenga = 1.0 + (Partido.ARENGA_BOOST - 1.0) * p._factor_arenga
	return nat.medias_linea(once, Datos.mapa_grupos(), Datos.mapa_lateral(), Datos.mapa_banda(), p.impulsos, p.minuto, arenga, Partido.LEY_DEL_EX, Partido.ex_de_mi_club, enfrente.id if enfrente != null else "")
