extends Node
## MENÚS PARTIDOS EN PANTALLAS, DE PUNTA A PUNTA (12-11): abre el menú de verdad (`principal.tscn`) con un club y, por cada pestaña partida,
## salta a cada una de sus secciones como lo hace una tarjeta o un aviso (`_ir_a_chip`) y comprueba que la pantalla pinta SOLO lo suyo:
## un rótulo que debe estar y otro, de la sección vecina, que no. PAIS=… CLUB=… para variar de club (regla 34).
const CASOS := [
	["Finanzas", "_lista_finanzas", "banco", "BONO SOCIAL", "TIENDA DEL CLUB"],
	["Finanzas", "_lista_finanzas", "taquilla", "TIENDA DEL CLUB", "BONO SOCIAL"],
	["Finanzas", "_lista_finanzas", "libro", "LIBRO DE MOVIMIENTOS", "PRECIO DE LA ENTRADA"],
	["Partido", "_lista_partido", "onces", "LOS ONCES", "INFORME"],
	["Táctica", "_lista_tactica", "once", "de 11 elegidos", "REGLAMENTO INTERNO"],
	["Táctica", "_lista_tactica", "balon", "REGLAMENTO INTERNO", "de 11 elegidos"],
	["Entrenar", "_lista_entren", "semana", "PLAN DE LA SEMANA", "PRETEMPORADA"],
	["Entrenar", "_lista_entren", "pretemporada", "PRETEMPORADA", "PLAN DE LA SEMANA"],
	["Clubes", "_lista_clubes", "goleadores", "GOLEADORES", "PTS"],
]
var _p: Principal
var _fallos := 0

func _textos(lista: Node) -> String:
	var t := ""
	for l in lista.find_children("*", "Label", true, false):
		t += (l as Label).text + "\n"
	return t

func _ready() -> void:
	var m := Mundo.new()
	m.generar([OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "BRA"], 121112)
	m.tomar_el_mando(m.ligas[0].clubes[int(OS.get_environment("CLUB")) % m.ligas[0].clubes.size()].id)
	for k in 4:   ## los eventos a pantalla completa de la semana 1 taparían el menú
		var ev := EventosClub.pendiente(m)
		if ev.is_empty():
			break
		EventosClub.aplicar(m, ev, 0)
	PedidoPartida.mundo_pregenerado = m
	Idiomas.idioma = "es"
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	for i in 30:
		await get_tree().process_frame
	CapasTutorial.poner_activas(false)
	print("CLUB ", m.mi_club().nombre)
	for c: Array in CASOS:
		_p._ir_a_chip({"tab": c[0], "secc": c[2]})
		for i in 20:
			await get_tree().process_frame
		var t := _textos(_p.get(String(c[1])) as Node)
		var ok := t.contains(String(c[3])) and not t.contains(String(c[4])) and _p.secc_de(String(c[0])) == String(c[2])
		if not ok:
			_fallos += 1
		print("  %s %s → %s: está «%s» %s, no está «%s» %s" % ["ok   " if ok else "FALLO", c[0], c[2], c[3], t.contains(String(c[3])), c[4], not t.contains(String(c[4]))])
	print("FIN. %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)   ## código de salida: `especiales.sh` encadena dos clubes con &&
