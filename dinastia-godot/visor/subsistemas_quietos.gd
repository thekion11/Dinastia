class_name SubsistemasQuietos
extends RefCounted
## SUBSISTEMAS CON SCRIPT CUYA GEOMETRÍA ES QUIETA (7-11, meta de llamadas de dibujo, autorizado por la líder de rendimiento). `Optimizar.agrupar`, `Optimizar.obstaculos` y
## `FundirPiezas.fundir_ciudad` dejan en paz todo lo que cuelga de un nodo con script (puede moverlo). El metro, la estación y el teleférico tienen script, pero ese script solo mueve unos
## nodos concretos (trenes, cabinas…): aquí se apuntan, por subsistema, los subárboles que SÍ se mueven; el resto de sus mallas cuenta como quieto y se agrupa o se funde como cualquier otra.
## Se rellena al empezar `agrupar` (`registrar`) y se vacía en `OptimizarGrada.al_final` (`limpiar`).

static var estaticos := {}   ## nodo con script → {nodo móvil: true}

## ¿El nodo `p` (con script) es un subsistema quieto en el que `mi` no cuelga de nada móvil?
static func permite(p: Node, mi: Node) -> bool:
	if not estaticos.has(p):
		return false
	var mov: Dictionary = estaticos[p]
	var q: Node = mi
	while q != null and q != p:
		if mov.has(q):
			return false
		q = q.get_parent()
	return true

static func limpiar() -> void:
	estaticos.clear()

## Busca los subsistemas conocidos bajo `raiz` y apunta lo que mueven.
static func registrar(raiz: Node) -> void:
	estaticos.clear()
	if OS.get_environment("SIN_QUIETOS") != "":   ## SIN_QUIETOS=1: como antes (para las capturas «antes»)
		return
	var metro := raiz.find_child("Metro", true, false) as MetroCiudad
	if metro != null:
		var mov := {}
		for l: Dictionary in metro.lineas:
			for clave in ["nodos", "nodos_x"]:
				for n: Variant in l.get(clave, []):
					if n is Node:
						mov[n] = true
		estaticos[metro] = mov
	## La estación central: el script solo mueve sus trenes (y crea la gente después).
	var estacion := raiz.find_child("EstacionCentral", true, false) as EstacionCentral
	if estacion != null:
		var mov_e := {}
		for t: Dictionary in estacion._trenes:
			if t.get("nodo") is Node:
				mov_e[t["nodo"]] = true
		estaticos[estacion] = mov_e
	## El teleférico: el script solo mueve y balancea las cabinas.
	var tele := raiz.find_child("Teleferico", true, false) as Teleferico
	if tele != null:
		var mov_t := {}
		for c: Node3D in tele.cabinas:
			mov_t[c] = true
		estaticos[tele] = mov_t
