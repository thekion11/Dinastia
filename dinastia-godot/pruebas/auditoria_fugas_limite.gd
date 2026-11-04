extends Node
## CAZA DE FALLOS (4-11-2026, orden de la líder): FUGAS en sesiones largas (el teléfono del dueño juega muchos partidos seguidos).
##   godot --headless --path . res://pruebas/auditoria_fugas_limite.tscn      (FUGAS_N=n partidos, 24 por omisión)
## n partidos 3D seguidos (jugados a toda prisa con «simular lo que queda», abandonados a mitad, con la pausa abierta, cerrados con «atrás»): tras calentar, ni los nodos, ni los huérfanos,
## ni los objetos, ni la memoria estática, ni las conexiones de señales de los autoloads, ni los tweens, ni las voces de sonido vivas pueden crecer partido a partido.
const LIENZO := Vector2(1600, 720)
var _n := 0
var _fallos := 0
var _ui: CarreraJugadorUI
var _muestras: Array = []
var _corriendo := false

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _ready() -> void:
	PartidoJugable.con_ceremonia = false
	ControlesTactiles.forzar = true
	PantallaMovil.dpi_forzado = 400.0
	PantallaMovil.ventana_forzada = Vector2i(2400, 1080)
	PantallaMovil.lienzo_forzado = LIENZO
	AjustesTactil.restaurar()
	CarreraJugadorUI.mundo = null
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		_ui._crear()
	if _n == 20 and not _corriendo:
		_corriendo = true
		await _todo()
		ControlesTactiles.forzar = false
		PantallaMovil.dpi_forzado = 0.0
		PantallaMovil.ventana_forzada = Vector2i.ZERO
		PantallaMovil.lienzo_forzado = Vector2.ZERO
		AjustesTactil.restaurar()
		print("===== FIN. %d fallos =====" % _fallos)
		get_tree().quit(0 if _fallos == 0 else 1)

func _marco(k: int) -> void:
	for i in k:
		await get_tree().process_frame

func _conexiones() -> int:
	var t := 0
	for o: Object in [Sonido, Musica, Idiomas, get_tree(), get_tree().root]:
		for s: Dictionary in o.get_signal_list():
			t += o.get_signal_connection_list(String(s["name"])).size()
	return t

func _voces() -> int:
	var v := 0
	for h in Sonido.get_children():
		if h is AudioStreamPlayer and (h as AudioStreamPlayer).playing:
			v += 1
	return v

func _medir(etiqueta: String) -> void:
	await _marco(4)
	var m := {"e": etiqueta,
		"nodos": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"huerf": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"obj": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"mem": float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0,
		"con": _conexiones(), "tween": get_tree().get_processed_tweens().size() if get_tree().has_method("get_processed_tweens") else 0,
		"voces": _voces()}
	_muestras.append(m)
	print("    %-22s nodos %5d huérfanos %3d objetos %6d mem %6.1f MB conexiones %4d tweens %d voces %d" % [etiqueta, m["nodos"], m["huerf"], m["obj"], m["mem"], m["con"], m["tween"], m["voces"]])

func _abrir() -> PartidoJugable:
	var club := _ui.carrera.club(CarreraJugadorUI.mundo)
	var par := _ui._partido_de_la_semana(club)
	var pj := PartidoJugable.abrir(_ui, CarreraJugadorUI.mundo, _ui.carrera, par[0], par[1], 6.0)
	pj.size = LIENZO
	(pj.get_node("ControlesTactiles") as Control).size = LIENZO
	await _marco(6)
	return pj

func _todo() -> void:
	var total := int(OS.get_environment("FUGAS_N")) if OS.get_environment("FUGAS_N") != "" else 24
	await _medir("inicio")
	for i in total:
		var pj := await _abrir()
		match i % 4:
			0:   ## jugado a toda prisa hasta el final
				pj._simular_resto()
				await _marco(3)
				if is_instance_valid(pj):
					pj.queue_free()
			1:   ## abandonado a mitad (salir al menú)
				await _marco(20)
				pj.queue_free()
			2:   ## con la pausa abierta, y se sale
				pj._alternar_pausa()
				await _marco(5)
				pj.queue_free()
			_:   ## «atrás» dos veces y se sale
				get_tree().root.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
				await _marco(3)
				get_tree().root.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
				await _marco(3)
				if is_instance_valid(pj):
					pj.queue_free()
		await _medir("partido %d (modo %d)" % [i + 1, i % 4])
	## Tendencia: media de los últimos 8 frente a la de los 8 posteriores al calentamiento (partidos 5-12).
	var n := _muestras.size()
	var ini := _muestras.slice(5, 13)
	var fin := _muestras.slice(n - 8, n)
	for k in ["nodos", "huerf", "obj", "mem", "con", "tween", "voces"]:
		var a := 0.0
		var b := 0.0
		for m: Dictionary in ini: a += float(m[k])
		for m: Dictionary in fin: b += float(m[k])
		a /= float(ini.size())
		b /= float(fin.size())
		var tope: float = {"nodos": 40.0, "huerf": 10.0, "obj": 600.0, "mem": 40.0, "con": 12.0, "tween": 4.0, "voces": 6.0}[k]
		_comprobar(b - a <= tope, "%s: sin crecimiento sostenido en %d partidos (%.1f → %.1f, tope +%.0f)" % [k, total, a, b, tope])
