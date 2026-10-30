extends RefCounted
## LO QUE EL MENÚ NECESITA DEL JUEGO ENTERO (30-10-2026, arranque). Nombrar `Partida`, `Mundo`,
## `Escudo`, `Logros`, `Meta`, `Principal`… desde el menú hacía que Godot compilase ~560 de los 627
## scripts ANTES de enseñarlo (3,3 de los 4,6 s del arranque exportado). Aquí van esas llamadas, y
## el menú no nombra este script: lo pide en un hilo (`Inicio._con_pesado`) y, mientras se compila,
## ya se ve; lo que depende de él (partida en curso, perfil, álbum) se rellena al llegar.
## Sin `class_name` a propósito: si alguien lo nombrara, volvería a compilarse todo al arrancar.

static func hay_partida() -> bool:
	return not Partida.listar().is_empty()

static func cargar(nombre: String) -> Mundo:
	return Partida.cargar(nombre)

static func borrar(nombre: String) -> void:
	Partida.borrar(nombre)

## Entra a una partida cargada: con el prólogo visto y la vida encendida, en 3D; si no, el menú.
static func entrar_en(arbol: SceneTree, m: Mundo) -> void:
	Principal.mundo_a_cargar = m
	var d := VidaCiudad.arranque_3d(m)
	if d != "":
		PrologoDT.directo = d
		arbol.change_scene_to_file(OrquestadorMundo.PROLOGO)
		return
	arbol.change_scene_to_file("res://escenas/principal.tscn")

static func archivo_ui() -> Node:
	return PartidaArchivoUI.new()

static func escudo(c: Club, alto: int) -> Texture2D:
	return Escudo.textura(c, alto)

static func perfil() -> Dictionary:
	var p := Logros.perfil_leer()
	return Logros.perfil_nivel(int(p["xp"]))

static func meta() -> Dictionary:
	return Meta.leer()

static func hay_legado() -> bool:
	return Meta.hay_legado()

static func heredar(si: Variant = null) -> bool:
	if si != null:
		Meta.heredar_proximo = bool(si)
	return Meta.heredar_proximo

static func abrir_meta(padre: Node) -> void:
	PanelMeta.abrir(padre)

static func estado_entrada(estado: Dictionary) -> void:
	OrquestadorEntrada.estado_inicial = estado

static func medir(arbol: SceneTree) -> void:
	Medicion.empezar(arbol)
