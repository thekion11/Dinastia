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
const ESPERADO := "1935461399"

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
