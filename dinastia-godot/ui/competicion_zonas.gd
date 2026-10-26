class_name CompeticionZonas
extends RefCounted
## LAS ZONAS DE UNA TABLA DE LIGA (25-10-2026): quién sube, quién baja, quién
## juega la promoción y quién iría al torneo continental SI LA LIGA ACABARA HOY.
##
## Antes la ficha de competición pintaba de verde "del 2.º al 4.º" y de rojo
## "los tres últimos" a ojo: en Chile bajan DOS (`Liga.plazas_descenso`), en
## Segunda nadie baja y suben los dos primeros, y la Libertadores no se reparte
## por un corte fijo. Una tabla que pinta zonas que el juego no aplica miente
## justo en lo primero que se mira, así que aquí se calculan con LAS MISMAS
## reglas que usa el cierre de temporada (`Mundo` al mover clubes de liga) y el
## sorteo continental (`Continental.plazas()`), sin copiar ninguna cifra.
##
## Es pura lectura: no toca el mundo. Devuelve club_id -> {"zona", "texto"}.

const CAMPEON := "campeon"
const CONTINENTAL := "continental"
const ASCENSO := "ascenso"
const PROMOCION := "promocion"
const DESCENSO := "descenso"

## Colores de las zonas. Se eligen para no chocar con el verde del club propio
## (que va de FONDO de fila, no de color) y para seguir leyéndose con la paleta
## de daltonismo: azul y naranja son el par seguro de Okabe-Ito.
const COLORES := {
	CAMPEON: Color("c9a227"),
	CONTINENTAL: Color("3b8fd9"),
	ASCENSO: Color("4caf6d"),
	PROMOCION: Color("e69f00"),
	DESCENSO: Color("e05555"),
}

## Orden de la leyenda: de arriba abajo, como se lee la tabla.
const ORDEN := [CAMPEON, CONTINENTAL, ASCENSO, PROMOCION, DESCENSO]

static func nombre_zona(zona: String) -> String:
	match zona:
		CAMPEON: return Idiomas.t("Campeón")
		CONTINENTAL: return Idiomas.t("Torneo continental")
		ASCENSO: return Idiomas.t("Ascenso")
		PROMOCION: return Idiomas.t("Promoción")
		DESCENSO: return Idiomas.t("Descenso")
	return ""

## Las zonas de `liga` con su tabla actual. `tabla` se pasa para no ordenarla
## dos veces (la pantalla ya la tiene); vacía = se pide aquí.
static func de_liga(mundo: Mundo, liga: Liga, tabla: Array = []) -> Dictionary:
	var salida := {}
	if mundo == null or liga == null:
		return salida
	var t := tabla if not tabla.is_empty() else liga.tabla()
	if t.size() < 3:
		return salida
	## Sin ningún partido jugado no hay "si acabara hoy": el orden es el del
	## sorteo y marcar a alguien como descendido sería inventárselo.
	if int((t[0] as Dictionary).get("pj", 0)) <= 0:
		return salida
	var primera := liga if liga.division() == 1 else _liga_de(mundo, liga.pais, 1)
	var segunda := liga if liga.division() == 2 else _liga_de(mundo, liga.pais, 2)
	var hay_promocion: bool = mundo.federacion != null and bool(mundo.federacion.promocion)
	if primera != null and segunda != null:
		var t1 := t if liga == primera else primera.tabla()
		var t2 := t if liga == segunda else segunda.tabla()
		if t1.size() >= 3 and t2.size() >= 3:
			## Misma cuenta que el cierre de temporada: lo que diga la Primera,
			## acotado para que siempre quede alguien en medio.
			var n := clampi(primera.plazas_descenso, 1, mini(t1.size(), t2.size()) - 2)
			var promo := hay_promocion and t1.size() >= n + 2 and t2.size() >= n + 2
			if liga == primera:
				for i in n:
					_poner(salida, t[t.size() - 1 - i], DESCENSO)
				if promo:
					_poner(salida, t[t.size() - 1 - n], PROMOCION)
			elif liga == segunda:
				for i in n:
					_poner(salida, t[i], ASCENSO)
				if promo:
					_poner(salida, t[n], PROMOCION)
	if liga.division() == 1:
		_poner(salida, t[0], CAMPEON)
		_marcar_continentales(mundo, liga, salida)
	return salida

static func _liga_de(mundo: Mundo, pais: String, division: int) -> Liga:
	for l: Liga in mundo.ligas:
		if l.pais == pais and l.division() == division:
			return l
	return null

static func _poner(salida: Dictionary, fila: Dictionary, zona: String) -> void:
	var c: Club = fila["club"]
	salida[c.id] = {"zona": zona, "texto": nombre_zona(zona)}

## El reparto continental tal cual lo haría el sorteo con las tablas de hoy.
## El campeón conserva su oro (es lo más importante que le pasa a un club), pero
## su texto dice también a qué torneo va.
static func _marcar_continentales(mundo: Mundo, liga: Liga, salida: Dictionary) -> void:
	var campeon_copa: Club = mundo.copa.campeon if mundo.copa != null else null
	var reparto := Continental.plazas(mundo.clubes.values(), mundo.ligas, campeon_copa)
	var de_esta := {}
	for c: Club in liga.clubes:
		de_esta[c.id] = true
	for k: String in Continental.claves():
		if not reparto.has(k):
			continue
		var torneo := Idiomas.t(Continental.nombre_conti(k))
		for c: Club in (reparto[k] as Array):
			if not de_esta.has(c.id):
				continue
			if salida.has(c.id):
				if String(salida[c.id]["zona"]) == CAMPEON:
					salida[c.id]["texto"] = "%s  ·  %s" % [nombre_zona(CAMPEON), torneo]
				continue
			salida[c.id] = {"zona": CONTINENTAL, "texto": torneo}
