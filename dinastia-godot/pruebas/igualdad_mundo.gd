extends Node
## IGUALDAD DEL MUNDO SIMULADO (2-11-2026, M-388): 40 semanas de dos ligas con semilla fija y una huella de saldos, plantillas y tablas. Para tocar `Balance`
## (o cualquier perilla de la economía y del partido simulado) sabiendo si el resultado cambia: si cambia a propósito, se actualiza `ESPERADO` diciéndolo.
##   godot --headless --path . res://pruebas/igualdad_mundo.tscn          (ACTUALIZAR=1 imprime la huella)
## 2-11 (fusión con main): cambia a propósito, entra el día de partido por aforo y precios reales y los viajes por distancia (`Viajes`).
## 3-11 (orden 22 U4): cambia a propósito, solo por los NOMBRES de guiño corregidos (vocales y letras dobles, guiones):
## algunos rasgos se siembran con el nombre del jugador. Ni el balance ni el motor cambian.
## 3-11 (calibración de goles, a propósito): `Balance.CONVERSION` 0,30 → 0,28 (el partido simulado daba 2,92 goles/partido; ahora 2,70). Cambian los marcadores y, con ellos, tablas y primas;
## era 998022970. `igualdad_motor` no cambia (el motor jugable no usa `CONVERSION`).
## 3-11 (cifras del partido, a propósito): amarillas y rojas del partido simulado al fútbol real (`Balance.P_AMARILLA` 0,031 → 0,040 y `P_ROJA_SEGUNDA` 0,18 → 0,09: 2,74 → 3,71 amarillas y
## 0,22 → 0,15 rojas por partido); más tarjetas consumen más azar y cambian marcadores, plantillas y tablas; era 4013618777. `igualdad_motor` no cambia.
## 3-11 (penales, a propósito): cada llegada puede acabar en falta dentro del área (`Balance.P_PENAL` 0,03 × perfil del árbitro; 0,00 → 0,31 penales por partido, convertidos al 77 %) y
## `Balance.CONVERSION` baja de 0,28 a 0,267 para mantener los goles en ~2,7. Cambian marcadores, tablas y primas; era 1935461399. `igualdad_motor` no cambia.
## 3-11 (ventaja de campo, a propósito): `Balance.BONO_LOCAL`/`BONO_VISITA` 1,08/0,94 → 1,18/0,86 (victoria local 39,8 % → 46,3 %; goles 2,72). Cambian marcadores, tablas y primas; era 1992993185. `igualdad_motor` no cambia.
## 4-11 (reglas, a propósito; banco `partido_reglas`): en el simulado la roja sanciona el partido SIGUIENTE (`Disciplina.sanciona`) y la 5.ª
## amarilla de la temporada sanciona (`Disciplina.acumula`). Cambian los onces y, con ellos, marcadores y tablas; era 4140416706. `igualdad_motor` no cambia.
## 4-11 (A4-GES-003): la ficha mental de cada jugador sale de un hash y no del azar → cambia la huella a propósito; era 324543228. `igualdad_motor` no cambia.
## 4-11 (A4-PAR-L01, tarjetas del simulado, a propósito): la 2.ª amarilla cuenta en el PARTIDO (antes, total par de la temporada), la roja
## saca del once y la tarjeta solo cae en quien juega; `P_AMARILLA` 0,040 → 0,045 (3,65 amarillas y 0,16 rojas). Era 31094042.
## 4-11 (A4-PAR-003 de PES 6, a propósito): la nota y la forma del cambiado/expulsado ya no usan el bono del equipo contrario. Era 2563391786.
## 4-11 (A4-GES-006, a propósito): el entrenamiento sube más (0,10→0,13 y 0,014→0,018, freno 4/6) para que el juvenil haga +4-6 con el plan normal. Era 450552767.
## 4-11 (A4-GES-006, tope duro, a propósito): lo ganado por entrenamiento (semanal, mentorías, prob. semanal) no pasa de +6 en la temporada (+2 de la curva anual = «no más de +8» del dueño). Era 194965960.
## 4-11 (PES 6, reglas al límite, a propósito): un lesionado SALE del campo (cambio de la CPU en el acto, el ayudante del DT a los 3 minutos; sin cambios, el equipo sigue con uno menos) y sin portero la defensa supone un «portero» de 35 (`PartidoLesiones`). Era 689438746. `igualdad_motor` no cambia.
## 4-11 (RECALIBRACIÓN DEL SIMULADO, decisión del dueño, a propósito): ~25 remates por partido (antes ~10; `Balance.LLEGADAS_K`), ~8,5 a puerta, ~11 % de conversión, el portero para el ~68 % de lo que va a puerta, y el cociente ataque/defensa se satura (`SATURA_LN`, A4-PAR-L02: 71 contra 48 da ~3,8 goles y como mucho ~8 en vez de 7,7 y hasta 15-0). Los goles siguen en ~2,7. Era 2200717894. `igualdad_motor` no cambia.
const ESPERADO := "1113735177"   ## 10-11 (a propósito): formación y estilo de cada club (EstiloClub, equilibrados); antes 3463485184

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 99)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	for i in 40:
		m.avanzar_semana()
	var s := PackedStringArray()
	for c: Club in m.clubes.values():
		s.append("%s:%d:%d" % [c.id, c.saldo, c.plantilla.size()])
	for l in m.ligas:
		for c: Club in l.clubes:
			s.append("%s:%s" % [c.id, str(l.tabla_de(c) if l.has_method("tabla_de") else "")])
	var huella := str(hash("|".join(s)))
	print("HUELLA ", huella)
	var ok := OS.get_environment("ACTUALIZAR") != "" or huella == ESPERADO
	print(("  ok    " if ok else "  FALLO ") + "la huella del mundo coincide con la guardada (%s)" % ESPERADO)
	print("===== FIN. %d fallos =====" % (0 if ok else 1))
	get_tree().quit(0 if ok else 1)
