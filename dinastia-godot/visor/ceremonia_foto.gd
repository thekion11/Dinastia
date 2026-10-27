class_name CeremoniaFoto
extends RefCounted
## LA FOTO DE EQUIPO (semana 4 del plan, «Partido III: espectáculo», 27-10-2026): tras las alineaciones y antes
## del sorteo, el once local posa en dos filas en su mitad, de cara a la tribuna principal (+X): seis de pie
## detrás y cinco agachados delante; la cámara de los fotógrafos, de frente, y unos flashes. Al acabar, cada
## uno vuelve a su sitio de la fila (es un corte de cámara: nadie se teletransporta en el plano).

const X_ATRAS := 9.0
const X_DELANTE := 9.9
const PASO := 0.95
const CAMARA := Vector3(15.2, 1.7, -6.0)
const MIRA := Vector3(9.4, 1.0, -6.0)
const Z_GRUPO := -6.0

## Coloca a los once locales para la foto. Devuelve [nodo, posición, rotación] para devolverlos luego.
static func colocar(jugadores: Array, anim_de: Callable) -> Array:
	var guardado: Array = []
	var once: Array = []
	for p: Dictionary in jugadores:
		if bool(p["es_local"]):
			once.append(p)
	for i in once.size():
		var p: Dictionary = once[i]
		var nd: Node3D = p["node"]
		guardado.append([nd, nd.position, nd.rotation.y])
		var atras := i < 6
		var en_fila := i if atras else i - 6
		var n_fila := mini(6, once.size()) if atras else once.size() - 6
		var z := Z_GRUPO + (float(en_fila) - float(n_fila - 1) * 0.5) * PASO
		nd.position = Vector3(X_ATRAS if atras else X_DELANTE, 0.0, z)
		nd.rotation.y = PI * 0.5
		anim_de.call(p.get("anim"), "parado" if atras else "agachado")
	return guardado

static func devolver(guardado: Array, jugadores: Array, anim_de: Callable) -> void:
	for g: Array in guardado:
		var nd: Node3D = g[0]
		if is_instance_valid(nd):
			nd.position = g[1]
			nd.rotation.y = float(g[2])
	for p: Dictionary in jugadores:
		if bool(p["es_local"]):
			anim_de.call(p.get("anim"), "parado")

## La luz de los flashes, delante del grupo (se enciende a destellos con `destellar`).
static func luz(raiz: Node3D) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.omni_range = 14.0
	l.light_energy = 0.0
	l.shadow_enabled = false
	l.position = CAMARA + Vector3(-1.5, 0.4, 0.0)
	l.name = "FlashFoto"
	raiz.add_child(l)
	return l

## Un destello cada ~0,45 s, de 0,07 s, a lo largo de la fase (`s` = segundos dentro de la foto).
static func destellar(l: OmniLight3D, s: float) -> void:
	if not is_instance_valid(l):
		return
	var fase := fmod(s + 0.2, 0.45)
	l.light_energy = 9.0 if fase < 0.07 and s > 0.6 else 0.0
