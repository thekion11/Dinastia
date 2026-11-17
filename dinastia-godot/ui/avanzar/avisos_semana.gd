class_name AvisosSemana
extends RefCounted
## LOS AVISOS DE CADA SEMANA QUE CORRE (17-11-2026): el cierre del mercado y el cierre de mes. Antes vivían solo dentro de `AvanceSemana._avanzar_semana`, así que al
## jugar o saltar el partido (que hacen correr la semana por otro camino) no salían: era una regresión del avance por días. Ahora los dan los TRES caminos
## (`_avanzar_semana`, `JornadaPartido._seguir_tras_partido` ya sea jugando o saltando) con este único código. `antes` va antes de correr la semana y `despues` después.

static var _mercado_avisado := -1   ## para no repetir el aviso del cierre del mercado en la misma semana

## ¿Hay que avisar del cierre del mercado esta semana? (queda ≤ 2 semanas) Devuelve las semanas que quedan, o 0 si no toca.
static func semanas_para_cierre(m: Mundo) -> int:
	if m.mercado_abierto() and m.semanas_de_mercado() <= 2 and _mercado_avisado != m.semana:
		return m.semanas_de_mercado()
	return 0

## Antes de correr la semana: avisa del cierre del mercado y devuelve la caja de ahora (para el cierre de mes).
static func antes(p: Principal) -> int:
	var q := semanas_para_cierre(p.mundo)
	if q > 0:
		_mercado_avisado = p.mundo.semana
		Aviso.mostrar(p, "mercado", "⏳", "El mercado cierra",
			"Queda%s %d semana%s para el cierre. Lo que no fiches ahora, no lo fichas hasta la próxima ventana." % [
				"" if q == 1 else "n", q, "" if q == 1 else "s"], "mercado_cierra")
	return p.mundo.mi_club().saldo

## El texto del cierre de mes («la caja sube/baja X»), o "" si esta semana no cierra mes.
static func cierre_de_mes(m: Mundo, p: Principal, caja_antes: int) -> String:
	if m.semana % Finanzas.SEMANAS_DEL_MES != 1 or m.semana <= 1:
		return ""
	var delta := m.mi_club().saldo - caja_antes
	return "[color=#c9a227]Cierre de mes:[/color] la caja %s %s" % ["sube" if delta >= 0 else "baja", p._dinero(absi(delta))]

## Después de correr la semana: escribe el cierre de mes en el registro.
static func despues(p: Principal, caja_antes: int) -> void:
	var t := cierre_de_mes(p.mundo, p, caja_antes)
	if t != "":
		p._escribir(t)
