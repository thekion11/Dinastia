extends RefCounted
## EL TUTORIAL GUIADO, LADO DE LA PANTALLA (fase 0: sale de `Principal`, capas
## 1, 15 y 16).
##
## Una sola responsabilidad: lo que el componente `Tutorial`
## (`ui/componentes/tutorial.gd`) necesita de la pantalla principal. Abrirlo,
## decir QUÉ control señala cada paso (`objetivo`), si el jugador ya hizo lo que
## el paso pedía (`hecho`) y hacerlo por él cuando pulsa «Muéstramelo»
## (`accion`).
##
## Interfaz: `abrir(modo)`, `quizas(modo)`, `objetivo(clave)`, `hecho(clave)`,
## `accion(clave)` y el diccionario `nodos`. El componente sigue llamando a
## Principal por nombre (`abrir_tutorial`, `tutorial_objetivo`,
## `tutorial_hecho`, `tutorial_accion`, con `has_method` delante): esos cuatro
## quedan en Principal como puentes y son el contrato con el componente.
##
## `RefCounted`: la única señal que conecta es la del propio `Tutorial`, un nodo
## hijo de Principal que se libera con ella (y suelta la conexión).

var p: Principal

## Los controles que el tutorial señala, por clave. Se guardan al construir la
## pantalla (`_construir()`); los que ya tenían variable propia se resuelven en
## el momento, en `objetivo()`.
var nodos: Dictionary = {}
var _tutorial: Tutorial = null

func _init(principal: Principal) -> void:
	p = principal

## Abre el recorrido (cierra el que hubiera). Sin modo, el de la carrera actual.
func abrir(modo: String = "") -> void:
	if is_instance_valid(_tutorial):
		_tutorial.queue_free()
	if modo == "":
		modo = p.mundo.roles.modo_actual() if p.mundo != null and p.mundo.roles != null else "dt"
	_tutorial = Tutorial.new()
	p.add_child(_tutorial)
	_tutorial.iniciar(p, modo, p.mundo.mi_club().nombre if p.mundo != null and p.mundo.mi_club() != null else "tu club")
	_tutorial.terminado.connect(func(_completo: bool) -> void:
		Tutorial.marcar_visto()
		_tutorial = null)

## Arranca el recorrido la primera vez que alguien empieza una carrera, o
## siempre si se pidió desde la tarjeta "Tutorial" del menú.
func quizas(modo: String) -> void:
	if not Principal.tutorial_pedido and Tutorial.visto():
		return
	Principal.tutorial_pedido = false
	abrir(modo)

## El control que señala el paso `clave` (o null si no existe).
func objetivo(clave: String) -> Control:
	match clave:
		"estado": return p._sub
		"grupos": return p._fila_grupos
		"chips": return p._fila_sub.get_parent() as Control
		"ficha": return p._ficha
		"tabla": return p._lista_tabla
		"registro": return p._registro
	return nodos.get(clave) as Control

## Lo que completa un paso sin pulsar "Siguiente": que el jugador haya hecho
## eso mismo que la tarjeta le pedía.
func hecho(clave: String) -> bool:
	if not is_instance_valid(p._pestanas):
		return false
	var titulo := p._pestanas.get_tab_title(p._pestanas.current_tab) if p._pestanas.get_tab_count() > 0 else ""
	## Las misiones del tutorial inmersivo: una pestaña concreta, una sección
	## concreta de una pestaña, o la ficha de un jugador concreto.
	if clave.begins_with("tab:"):
		return titulo == clave.substr(4)
	if clave.begins_with("chip:"):
		var partes := clave.substr(5).split("|")
		return titulo == partes[0] and p._seccion_activa({"tab": partes[0], "secc": partes[1] if partes.size() > 1 else ""})
	if clave.begins_with("ficha:"):
		return p._seleccionado != null and p._seleccionado.id == clave.substr(6)
	match clave:
		"grupo": return p._grupo_actual != "central"
		"ficha": return p._seleccionado != null
		"plantel": return (Principal.HUBS["plantel"]["tabs"] as Array).has(titulo)
		"dinero": return (Principal.HUBS["dinero"]["tabs"] as Array).has(titulo)
		"partido": return (Principal.HUBS["partido"]["tabs"] as Array).has(titulo)
	return false

## "Muéstramelo": hace por el jugador lo que pide el paso.
func accion(clave: String) -> void:
	if clave.begins_with("tab:"):
		p._ir_a_pestana(clave.substr(4))
		p._refrescar()
		return
	if clave.begins_with("chip:"):
		var partes := clave.substr(5).split("|")
		p._ir_a_chip({"tab": partes[0], "secc": partes[1] if partes.size() > 1 else ""})
		return
	if clave.begins_with("ficha:"):
		var id := clave.substr(6)
		for j: Jugador in p.mundo.mi_club().plantilla:
			if j.id == id:
				p._ver_ficha(j)
		return
	match clave:
		"ficha":
			if not p.mundo.mi_club().plantilla.is_empty():
				p._ver_ficha(p.mundo.mi_club().plantilla[0])
		"grupo_club": p._elegir_grupo("club")
		"plantel": p._ir_a_pestana("Mi plantel")
		"dinero": p._ir_a_pestana("Finanzas")
		"partido": p._ir_a_pestana("Partido")
