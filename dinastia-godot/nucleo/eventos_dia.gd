class_name EventosDia
extends RefCounted
## EL AVANCE POR DÍAS, PASO 1: EL MODELO DE EVENTOS DEL DÍA (17-11-2026).
## Maqueta aprobada por el dueño: `docs/04_auditorias/maqueta_avanzar_2026-11-16.html`; plan en `docs/04_auditorias/AVANCE_POR_DIAS_IMPLEMENTACION.md`.
##
## Qué hace: toma los eventos del calendario (`EventosFecha`) y los CLASIFICA como pidió el dueño, para que la pantalla «Avanzar» sepa qué hacer
## cuando el cursor llega a un día con eventos:
##   - PARTIDO:  el avance se detiene, se vuelve al menú de inicio y donde estaba «Avanzar» salen «Jugar partido» y «Saltar partido».
##   - PANTALLA: evento importante con animación propia: se abre a pantalla completa y, al cerrarlo, se vuelve al menú.
##   - AVISO:    evento menor: se sale al menú, campana roja en la tarjeta de su ZONA y el avance queda parado hasta pulsar Avanzar otra vez.
## Todo es lectura y aritmética: no consume `Azar` ni cambia el mundo.
##
## NO escribe ninguna fecha ni texto de memoria ni festividad: los aporta `Calendario` (el calendario por país, otra sesión) y entrarán por un
## enganche aparte (ver el plan). Cuando existan, MEMORIA será PANTALLA sobria (sin música ni animaciones) y las demás fechas, AVISO.
##
## Regla de la extensión: esta lógica pasará a C++ (`nativo/src`) con ESTA versión como gemela exacta (respaldo de Android y Web).

const PARTIDO := "partido"
const PANTALLA := "pantalla"
const AVISO := "aviso"
## Las zonas del menú de inicio donde sale la campana de un aviso.
const ZONAS := ["equipo", "mercado", "cantera", "finanzas", "prensa", "vestuario"]

## Clase de cada tipo de `EventosFecha`. Lo que no esté aquí es un AVISO (lo menor nunca ocupa la pantalla).
const CLASE_DE_TIPO := {"liga": PARTIDO, "copa": PARTIDO, "conti": PARTIDO, "fin": PANTALLA, "mercado_abre": AVISO, "mercado_cierra": AVISO}
## Zona de la campana de cada AVISO.
const ZONA_DE_TIPO := {"mercado_abre": "mercado", "mercado_cierra": "mercado"}
const ZONA_POR_DEFECTO := "prensa"

static func clase_de(e: Dictionary) -> String:
	return String(CLASE_DE_TIPO.get(String(e.get("tipo", "")), AVISO))

## La zona de la campana: solo los AVISOS la tienen ("" para partidos y pantallas completas).
static func zona_de(e: Dictionary) -> String:
	if clase_de(e) != AVISO:
		return ""
	var z := String(ZONA_DE_TIPO.get(String(e.get("tipo", "")), ZONA_POR_DEFECTO))
	return z if ZONAS.has(z) else ZONA_POR_DEFECTO

static func con_clase(e: Dictionary) -> Dictionary:
	var c: Dictionary = e.duplicate()
	c["clase"] = clase_de(e)
	c["zona"] = zona_de(e)
	return c

## Los eventos del día `dia` (0 = lunes) de la semana `k` contando desde hoy (0 = esta), cada uno con su `clase` y su `zona`, en el orden de `EventosFecha`.
static func del_dia(m: Mundo, k: int, dia: int) -> Array:
	var out: Array = []
	for s: Dictionary in EventosFecha.semanas(m, k + 1):
		if int(s["k"]) != k:
			continue
		for e: Dictionary in s["eventos"]:
			if int(e["dia"]) == dia:
				out.append(con_clase(e))
	return out

## Dónde se detiene el avance: el primer día con eventos desde (`k`, `dia`) INCLUIDO, dentro del horizonte de semanas.
## Devuelve {"k", "dia", "eventos"} o {} si no queda ninguno.
static func proxima_parada(m: Mundo, k := 0, dia := 0, horizonte := EventosFecha.VISTA) -> Dictionary:
	for s: Dictionary in EventosFecha.semanas(m, horizonte):
		var kk := int(s["k"])
		if kk < k:
			continue
		for d in range(dia if kk == k else 0, 7):
			var lista: Array = []
			for e: Dictionary in s["eventos"]:
				if int(e["dia"]) == d:
					lista.append(con_clase(e))
			if not lista.is_empty():
				return {"k": kk, "dia": d, "eventos": lista}
	return {}

## Qué hace la pantalla al llegar a una parada: las PANTALLAS completas (en orden), los AVISOS por zona, el PARTIDO del día (el primero; si hay
## más, quedan en `partidos`) y si hay que VOLVER AL MENÚ (siempre que haya cualquier evento).
static func plan_de_parada(eventos: Array) -> Dictionary:
	var pantallas: Array = []
	var avisos: Dictionary = {}
	var partidos: Array = []
	for e: Dictionary in eventos:
		match String(e.get("clase", clase_de(e))):
			PARTIDO:
				partidos.append(e)
			PANTALLA:
				pantallas.append(e)
			_:
				var z := String(e.get("zona", zona_de(e)))
				if not avisos.has(z):
					avisos[z] = []
				(avisos[z] as Array).append(e)
	return {
		"pantallas": pantallas,
		"avisos": avisos,
		"partido": partidos[0] if not partidos.is_empty() else {},
		"partidos": partidos,
		"vuelve_al_menu": not eventos.is_empty(),
		"dia_de_partido": not partidos.is_empty(),
	}
