extends Node
## Verifica los cinco arreglos de Federación del 14-9-2026:
##  1) `castigo_directiva` mueve de verdad la confianza de la directiva
##     (antes: nadie la escuchaba, licencia denegada/dopaje/cupo juvenil no
##     hacían nada).
##  2) `escandalo` mueve de verdad la funa de la hinchada (mismo problema).
##  3) `votacion_abierta` ahora deja una noticia en la bandeja -antes era la
##     única de las nueve señales de la clase sin ningún `noticia.emit()`,
##     100% muda-.
##  4) El título de la votación pendiente usa la clave real de la tabla
##     ("t"), no "titulo" -esa clave nunca existió y el jugador veía el id
##     interno en crudo ("tvigual") en vez del texto ("Reparto igualitario...").
##  5) El botón "A favor" manda "a" de verdad. Antes mandaba "si", y
##     `Federacion.votar()` -portado tal cual del HTML- solo reconoce "a":
##     tu voto a favor nunca sumaba el bono de `a_favor` ni se registraba
##     como `vote_a`, y el mensaje de "ganaste/perdiste" salía invertido.
##
##   godot --headless --path . res://pruebas/captura_federacion_conectada.tscn

const ESPERA := 6

var _n := 0
var _pantalla: Node
var _fallos := 0

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n != ESPERA:
		return

	var mun = _pantalla.get("mundo")
	var fed = mun.federacion

	## 1) castigo_directiva -> Directiva.mover_confianza()
	var conf_antes: int = mun.directiva.confianza
	fed.castigo_directiva.emit(-7, "prueba")
	var conf_despues: int = mun.directiva.confianza
	_comprobar(conf_despues == conf_antes - 7,
		"castigo_directiva mueve la confianza (%d -> %d)" % [conf_antes, conf_despues])

	## 2) escandalo -> Prensa._mover_funa()
	var funa_antes: int = mun.prensa.funa
	fed.escandalo.emit(9, "prueba")
	var funa_despues: int = mun.prensa.funa
	_comprobar(funa_despues == funa_antes + 9,
		"escandalo mueve la funa (%d -> %d)" % [funa_antes, funa_despues])

	## 3) votacion_abierta ahora avisa con noticia.
	fed.voto_pendiente = {}
	var bandeja_antes: int = _pantalla.get("_bandeja").size()
	var abierta := false
	for i in 500:
		if not fed.abrir_votacion().is_empty():
			abierta = true
			break
	_comprobar(abierta, "abrir_votacion() dispara al menos una vez en 500 intentos (prob. 5%%/semana)")
	var bandeja_despues: int = _pantalla.get("_bandeja").size()
	_comprobar(bandeja_despues > bandeja_antes,
		"abrir la votacion deja una fila nueva en la bandeja (%d -> %d)" % [bandeja_antes, bandeja_despues])

	## 4) y 5): título real + botón "A favor" cuenta de verdad.
	fed.voto_pendiente = {"id": "tvigual", "t": "Reparto igualitario de los derechos de TV",
		"a": "Votar a favor", "b": "Votar en contra",
		"desc": "Descripción de prueba, no viene del catálogo real."}
	_pantalla.call("_pintar_federacion", mun.mi_club())
	var visto := _texto_de(_pantalla.get("_lista_fed"))
	_comprobar(visto.find("Reparto igualitario") != -1,
		"el título muestra el texto real de la moción")
	_comprobar(visto.find("tvigual") == -1,
		"el título ya NO muestra el id en crudo")

	_pantalla.call("_votar", "a")
	_comprobar(not fed.votos.is_empty() and bool((fed.votos[0] as Dictionary).get("vote_a", false)),
		"votar 'A favor' desde la pantalla real se registra como voto a favor")

	print("FIN. %d fallo(s)" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)

func _texto_de(cont: Control) -> String:
	var out := ""
	for hijo in cont.get_children():
		if hijo is Label:
			out += (hijo as Label).text + "\n"
	return out

func _comprobar(ok: bool, msg: String) -> void:
	if ok:
		print("OK  " + msg)
	else:
		_fallos += 1
		print("MAL " + msg)
