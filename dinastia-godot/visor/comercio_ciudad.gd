class_name ComercioCiudad
extends RefCounted
## EL GANCHO ÚNICO de la E ante los puntos de comercio de la ciudad (tienda de la gasolinera, cajeros y máquinas expendedoras), aparte de
## `SubsueloCiudad.servicio` (redes) para no tocar su archivo y con una sola llamada en `explorador_ciudad_p4.gd`.
## HORARIO DE COMERCIOS (4-11-2026, A4-M3D-014, decisión del dueño): de `ABRE` a `CIERRA` h por el reloj del juego; fuera de ese horario están cerrados
## (el aviso lo dice y la E no entra ni compra). Son comercios las tiendas de la ciudad (`ExploradorCiudad.SALA_DE_ROTULO`, menos el hotel y la peña del club),
## la tienda deportiva, la sala de peluches y la ventanilla del banco; la gasolinera, los cajeros y las expendedoras siguen abiertos las 24 h.
const ABRE := 8.0
const CIERRA := 20.0
const SIEMPRE_ABIERTOS := ["edificio_hotel", "edificio_pena"]

static func es_comercio(k: String) -> bool:
	if k.begins_with("deportes_") or k.begins_with("peluches_") or k.begins_with("banco_"):
		return true
	return ExploradorCiudad.SALA_DE_ROTULO.values().has(k) and not SIEMPRE_ABIERTOS.has(k)

static func abierto_a(hora: float) -> bool:
	return hora >= ABRE and hora < CIERRA

## ¿Está `k` cerrado ahora? Sin vida o sin mundo (pruebas sueltas) se da por abierto.
static func cerrado(e, k: String) -> bool:
	if not es_comercio(k) or e == null or e.vida == null or e.vida.mundo == null or e.vida.mundo.reloj == null:
		return false
	return not abierto_a(float(e.vida.mundo.reloj.hora_decimal()))

## El aviso de la E ante `k` (de nombre `n`): «E: Farmacia», o «Farmacia · CERRADO …» con el comercio cerrado.
static func aviso(e, k: String, n: String) -> String:
	return "%s · %s" % [n, Idiomas.t("CERRADO · abre de 8:00 a 20:00")] if cerrado(e, k) else "E: %s" % n

static func servicio(e, k: String) -> bool:
	if cerrado(e, k):
		return true   ## cerrado: la E no hace nada (el aviso de pantalla ya lo dice)
	return GasolineraTienda.servicio(e, k) or TiendaDeportiva.servicio(e, k) or CajeroCiudad.servicio(e, k) or ExpendedoraCiudad.servicio(e, k) or BancoCiudad.servicio(e, k) or PeluchesCiudad.servicio(e, k) or RecreativaRetro.servicio(e, k)
