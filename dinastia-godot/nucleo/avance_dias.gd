class_name AvanceDias
extends RefCounted
## EL AVANCE POR DÍAS, PASO 3 (núcleo, 17-11-2026): el que decide DÓNDE SE DETIENE el avance. La pantalla «Avanzar» (`ui/avanzar/`) solo lo dibuja.
## Avanzar es pasar DÍAS (0 = lunes … 6 = domingo): al pasar del domingo corre la semana real del juego (`rodar`, que la pantalla enlaza con
## `AvanceSemana`); después de cada día se mira si hay algo que mostrar: los eventos del calendario de ese día (`EventosDia.del_dia`: partidos, mercado,
## fechas del país) y los que dejaron los sistemas (`DisparadoresDia.consultar`, que solo observa). El avance se detiene en el PRIMER día con eventos.
## Regla de la extensión: esta lógica pasará a C++ con esta versión como gemela exacta.

const TOPE_DIAS := 60   ## nunca se avanza más de esto de una sola vez (red de seguridad; una temporada sin eventos no existe)

## Lo que hay que mostrar HOY (día `dia` de la semana actual): calendario + disparadores, cada uno con `clase`, `zona` y `origen`.
static func eventos_de_hoy(m: Mundo, est: Dictionary, dia: int) -> Array:
	var out: Array = EventosDia.del_dia(m, 0, dia)
	out.append_array(DisparadoresDia.consultar(m, est))
	return out

## La fecha del día (mes 1-12, día del mes) de la semana actual: `Calendario.fecha`.
static func fecha_de(m: Mundo, dia: int) -> Dictionary:
	return Calendario.fecha(m.anio, m.semana, dia)

## (`dia` = -1: la semana ya corrió con el partido y el avance empieza mirando el lunes.) Avanza día a día desde `dia` hasta el primer día con eventos. `rodar` (Callable sin argumentos) corre la semana real al pasar del domingo.
## Devuelve {"dia", "eventos", "plan", "pasados": [{dia, mes, dia_mes}], "fin": bool}; `fin` = la temporada se acabó (sin eventos que mostrar:
## lo atiende el cierre de temporada); `pasados` son los días recorridos (el último es el de la parada) para la animación del calendario.
static func avanzar(m: Mundo, est: Dictionary, dia: int, rodar: Callable, un_dia := false) -> Dictionary:
	var pasados: Array = []
	var d := dia
	for _i in TOPE_DIAS:
		if d >= 6:
			d = 0
			rodar.call()
		else:
			d += 1
		var f := fecha_de(m, d)
		pasados.append({"dia": d, "mes": int(f.get("mes", 1)), "dia_mes": int(f.get("dia", 1))})
		if not m.temporada_en_curso():
			return {"dia": d, "eventos": [], "plan": EventosDia.plan_de_parada([]), "pasados": pasados, "fin": true}
		var evs := eventos_de_hoy(m, est, d)
		if not evs.is_empty() or un_dia:   ## `un_dia` («Avanzar 1 día» del desplegable): se detiene tras UN día, haya o no eventos
			return {"dia": d, "eventos": evs, "plan": EventosDia.plan_de_parada(evs), "pasados": pasados, "fin": false}
	return {"dia": d, "eventos": [], "plan": EventosDia.plan_de_parada([]), "pasados": pasados, "fin": false}
