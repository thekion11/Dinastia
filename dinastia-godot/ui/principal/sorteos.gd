extends Node
## LOS SORTEOS CONTINENTALES Y DE COPA (fase 0: sale de `Principal`, capa 10).
##
## Una sola responsabilidad: escuchar los sorteos de los torneos y enseñar la
## cinemática de los que te tocan, de una en una. También avisa del resultado de
## TU club en SU continental, porque comparte el mismo ciclo de vida (hay que
## reconectar tras cada resorteo).
##
## Interfaz: `conectar()`, `conectar_mi_continental()` y `encolar(d)`. Principal
## la posee (`_sorteos`) y conserva los métodos de siempre como puentes
## (`_conectar_sorteos()`, `_conectar_mi_continental()`, `_encolar_sorteo()`).
##
## Es un `Node` hijo de Principal, no un `RefCounted`, a propósito: las lambdas
## que se conectan a las señales del mundo quedan atadas a este nodo, y Godot
## las desconecta solo cuando se libera -igual que cuando vivían en Principal-.
## Un `RefCounted` quedaría vivo dentro de esas conexiones tras cerrar la
## pantalla y llamaría a una Principal ya liberada.

var p: Principal

## LOS SORTEOS. Solo se enseña la cinemática de los torneos donde JUEGA tu club:
## el bombo de un continental que no te toca sería una espera sin premio.
##
## Y se encolan. Al empezar temporada se sortean varios continentales a la vez, y
## sin cola la segunda cinemática pisaría a la primera -o peor, se abrirían dos
## superpuestas y el juego se quedaría con dos capas modales encima.
var _cola: Array = []
var _abierto: bool = false

func _init(principal: Principal = null) -> void:
	p = principal
	name = "Sorteos"

## Conecta la cinemática de sorteo (todos los continentales: es un espectáculo,
## no un peaje) y el resultado de TU club en el suyo (ver
## `conectar_mi_continental()`). Hay que volver a llamarla tras CADA
## resorteo -al tomar el mando y en cada cierre de temporada, ver
## `_nueva_temporada()`-, porque `Continental.sortear()` siempre crea
## instancias NUEVAS: conectar solo la primera vez dejaba sin sorteo visible y
## sin aviso de resultado la Champions/Libertadores desde la segunda temporada
## en adelante. El candado por objeto es necesario además porque `mundo.copa`
## SÍ persiste entre cambios de club -mismo bug ya cazado en
## `federacion.noticia`-: sin él, cada despido/trotamundos/oferta aceptada
## sumaba OTRA conexión sobre el mismo `copa`, y una sola eliminatoria abría la
## MISMA cinemática de sorteo una vez por cada cambio de club de la partida.
func conectar() -> void:
	for k: String in p.mundo.continentales:
		var t: Continental = p.mundo.continentales[k]
		if t.has_meta("_ui_conectado_sorteo"):
			continue
		t.set_meta("_ui_conectado_sorteo", true)
		var clave := k
		t.sorteo_grupos.connect(func(grupos: Array) -> void:
			encolar({"tipo": "grupos", "clave": clave, "grupos": grupos}))
		t.sorteo_eliminatoria.connect(func(ronda: String, parejas: Array) -> void:
			encolar({"tipo": "cruces", "clave": clave, "ronda": ronda, "parejas": parejas}))
	if p.mundo.copa != null and not p.mundo.copa.has_meta("_ui_conectado_sorteo"):
		p.mundo.copa.set_meta("_ui_conectado_sorteo", true)
		p.mundo.copa.sorteo_eliminatoria.connect(func(ronda: String, parejas: Array) -> void:
			encolar({"tipo": "cruces", "clave": "copa", "ronda": ronda, "parejas": parejas}))
	conectar_mi_continental()

## El resultado de TU club en SU torneo continental -mismo trato que ya tiene
## `copa` en las noticias, portado el 14-9-2026-: campeón, ronda superada y el
## premio de pasar de la fase de grupos. `Continental extends Copa` hereda las
## tres señales de siempre; hasta entonces ninguna estaba conectada -ganar el
## trofeo más grande del juego no avisaba de nada-.
func conectar_mi_continental() -> void:
	var c := p.mundo.mi_continental()
	if c == null or c.has_meta("_ui_conectado"):
		return
	c.set_meta("_ui_conectado", true)
	c.campeon_proclamado.connect(func(campeon: Club) -> void:
		if campeon == p.mundo.mi_club():
			Aviso.mostrar(p, "dinero", "🏆", "Campeón de %s" % c.nombre,
				"El trofeo continental es tuyo. Entra el premio de campeón a la caja."))
	c.ronda_terminada.connect(func(nombre_ronda: String, resultados: Array) -> void:
		for r: Dictionary in resultados:
			if r.get("pasa") == p.mundo.mi_club():
				Aviso.mostrar(p, "dinero", "🎟️", "Pasas de ronda en %s" % c.nombre,
					"%s superada. Cada eliminatoria continental que se gana es premio." % nombre_ronda, "ronda_superada")
				return)
	c.grupos_terminados.connect(func(clasificados: Array) -> void:
		if clasificados.has(p.mundo.mi_club()):
			Aviso.mostrar(p, "dinero", "🎟️", "Clasificas a cuartos de %s" % c.nombre,
				"Terminas entre los ocho de la fase de grupos: cobras el premio de clasificación.", "ronda_superada"))

## Pone un sorteo en la cola (solo si te toca) y abre el siguiente si no hay
## ninguno en pantalla.
func encolar(d: Dictionary) -> void:
	if not _me_toca(d):
		return
	_cola.append(d)
	_siguiente()

## Cuántos sorteos esperan turno y si hay uno abierto (para las pruebas).
func pendientes() -> int:
	return _cola.size()

func abierto() -> bool:
	return _abierto

## Solo si tu club está dentro. Es la diferencia entre una ceremonia y un peaje.
func _me_toca(d: Dictionary) -> bool:
	var mio := p.mundo.mi_club()
	if mio == null:
		return false
	if String(d["tipo"]) == "grupos":
		for g: Array in d["grupos"]:
			if g.has(mio):
				return true
		return false
	for par: Array in d["parejas"]:
		if par[0] == mio or par[1] == mio:
			return true
	return false

## La cinemática cuelga de Principal (no de este nodo, que no es un `Control`):
## tapa toda la pantalla y al cerrarse repinta y abre la siguiente de la cola.
func _siguiente() -> void:
	if _abierto or _cola.is_empty():
		return
	_abierto = true
	var d: Dictionary = _cola.pop_front()
	var v := Sorteo.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.add_child(v)
	v.terminado.connect(func() -> void:
		v.queue_free()
		_abierto = false
		p._refrescar()
		_siguiente())
	if String(d["tipo"]) == "grupos":
		v.abrir_grupos(String(d["clave"]), d["grupos"], p.mundo.mi_club())
	else:
		v.abrir_eliminatoria(String(d["clave"]), String(d["ronda"]), d["parejas"], p.mundo.mi_club())
