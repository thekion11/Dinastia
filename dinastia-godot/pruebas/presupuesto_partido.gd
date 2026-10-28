extends Node
## PRESUPUESTO DE TRIÁNGULOS Y LLAMADAS DE DIBUJO DEL PARTIDO (M-338, 27-10-2026). Abre un partido jugable de verdad, lo deja correr unos fotogramas y mide con el
## renderizador (`Viewport.get_render_info`) lo que cuesta cada CATEGORÍA: se apaga una por una y lo que baja es lo suyo. Compara con el presupuesto escrito
## (`PRESUPUESTO`, y `docs/04_auditorias/presupuesto_partido.md`) y FALLA si alguna se pasa. Necesita pantalla (sin ella, el renderizador no cuenta nada: no hace nada).
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/presupuesto_partido.tscn      (MEDIR=1 solo imprime la tabla)
## Los números son los del cuadro visible desde la cámara del partido (con recorte de visibilidad y niveles de detalle), no los de toda la escena.
const MARGEN := 1.15   ## lo que se mide más un 15 % es el techo que se escribe en el presupuesto
## categoría: [triángulos máx., llamadas de dibujo máx.]: lo medido el 27-10 más un 15 % (ver `docs/04_auditorias/presupuesto_partido.md`). Bajan, no suben:
## quien suba un techo tiene que decir por qué en el doc. «estadio» INCLUYE a «publico» y «butacas» (son MultiMesh de las tribunas), así que las categorías no suman el total.
## «extras», «cesped» y «balon» miden 0 o casi con la cámara del saque (fuera de cuadro o demasiado pequeños): sus techos son holguras, no medidas.
const PRESUPUESTO := {
	"total": [2953334, 2444], "jugadores": [79904, 63], "publico": [889910, 27], "butacas": [1786659, 20], "estadio": [2767256, 240],
	"entorno": [591987, 1983], "extras": [60000, 40], "cesped": [100, 8], "balon": [4000, 10],
}
const CATEGORIAS := ["jugadores", "publico", "butacas", "estadio", "entorno", "extras", "cesped", "balon"]
var _n := 0
var _ui: CarreraJugadorUI
var _pj: PartidoJugable
var _fase := 0
var _base := {}
var _grupos := {}
var _medidas := {}
var _fallos := 0

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("sin pantalla el renderizador no cuenta: no se mide nada")
		print("===== FIN. 0 fallos =====")
		get_tree().quit()
		return
	## REBAJAS=0 enciende lo de antes de las rebajas #1-#3 (para medir y fotografiar el «antes»).
	if OS.get_environment("REBAJAS") == "0":
		StadiumBuilder.butaca_detalle_filas = 99
		EntornoEstadio.optimizar_partido = false
	PartidoJugable.con_ceremonia = false
	CarreraJugadorUI.mundo = null
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)

## A qué categoría pertenece un nodo hijo directo de la raíz del partido.
func _categoria_de(n: Node) -> String:
	var nom := String(n.name)
	if nom.begins_with("Cesped") or nom.begins_with("Linea"):
		return "cesped"
	if nom == "EntornoEstadio":
		return "entorno"
	if nom in ["Mascota", "Camarografo", "TunelVestuario", "TorreFocos", "ProyectoresFocos", "VallasLed"] or nom.begins_with("Sombra"):
		return "extras"
	if nom == "Ball":
		return "balon"
	if n is WorldEnvironment or n is Light3D or n is Camera3D:
		return ""
	return "estadio"

func _recoger() -> void:
	for c in _grupos.keys():
		_grupos[c] = []
	for c in CATEGORIAS:
		_grupos[c] = []
	for h in _pj._raiz.get_children():
		var cat := _categoria_de(h)
		if cat != "":
			(_grupos[cat] as Array).append(h)
	## El público y las butacas son MultiMesh dentro de las tribunas: se apagan ellos solos, no la tribuna entera.
	var pila: Array = (_grupos["estadio"] as Array).duplicate()
	while not pila.is_empty():
		var n: Node = pila.pop_back()
		if n is MultiMeshInstance3D:
			var nom := String(n.name)
			if nom.begins_with("Personas"):
				(_grupos["publico"] as Array).append(n)
			elif nom.begins_with("Butacas"):
				(_grupos["butacas"] as Array).append(n)
		pila.append_array(n.get_children())
	for j in _pj.motor.jugadores:
		(_grupos["jugadores"] as Array).append(j["node"])

func _info() -> Dictionary:
	var vp: Viewport = _pj._vp
	return {"tri": vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
		"llamadas": vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)}

func _medir() -> Dictionary:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	return _info()

func _apagar(lista: Array, visible: bool) -> void:
	for x in lista:
		if is_instance_valid(x) and x is Node3D:
			(x as Node3D).visible = visible

func _process(_d: float) -> void:
	_n += 1
	if _n == 5:
		_ui._crear()
	if _n == 15:
		var club := _ui.carrera.club(CarreraJugadorUI.mundo)
		var par := _ui._partido_de_la_semana(club)
		_pj = PartidoJugable.abrir(_ui, CarreraJugadorUI.mundo, _ui.carrera, par[0], par[1], 120.0)
	if _n == 120 and _fase == 0:
		_fase = 1
		## El mundo se congela (tiempo a cero) para que cada cuadro sea el mismo: sin esto la cámara y los jugadores se mueven entre una medida y la otra.
		Engine.time_scale = 0.0
		_medir_todo()

func _medir_todo() -> void:
	_recoger()
	## Referencia de FPS en ESTA máquina (renderizado por software si no hay GPU): no entra en el presupuesto, solo se imprime.
	var t0 := Time.get_ticks_usec()
	for k in 40:
		await RenderingServer.frame_post_draw
	var fps := 40.0 / (float(Time.get_ticks_usec() - t0) / 1000000.0)
	_base = await _medir()
	_medidas["total"] = _base
	## Cada categoría se mide EN PAREJA: el cuadro justo antes (con todo) y el cuadro justo después de apagarla, para que lo que se mueva entre uno y
	## otro (jugadores, cámara) no cuente como suyo.
	for cat: String in CATEGORIAS:
		var antes := await _medir()
		_apagar(_grupos[cat], false)
		var m := await _medir()
		_apagar(_grupos[cat], true)
		_medidas[cat] = {"tri": maxi(0, int(antes["tri"]) - int(m["tri"])), "llamadas": maxi(0, int(antes["llamadas"]) - int(m["llamadas"]))}
	print("")
	print("FPS de referencia en esta máquina (%s): %.2f" % [RenderingServer.get_video_adapter_name(), fps])
	print("PRESUPUESTO DEL PARTIDO (cuadro visible desde la cámara del partido)")
	print("  %-10s %12s %10s   %12s %10s" % ["categoría", "triángulos", "llamadas", "techo tri.", "techo ll."])
	var medir := OS.get_environment("MEDIR") != ""
	for cat: String in ["total"] + CATEGORIAS:
		var tri := int(_medidas[cat]["tri"])
		var ll := int(_medidas[cat]["llamadas"])
		var tope: Array = PRESUPUESTO[cat]
		var ok := medir or (tri <= int(tope[0]) and ll <= int(tope[1]))
		print("  %-10s %12d %10d   %12d %10d   %s" % [cat, tri, ll, int(tope[0]), int(tope[1]), "ok" if ok else "FALLO: se pasa del presupuesto"])
		if not ok:
			_fallos += 1
	if medir:
		print("  (techos sugeridos = medido + %d %%)" % int((MARGEN - 1.0) * 100))
		for cat: String in ["total"] + CATEGORIAS:
			print("  \"%s\": [%d, %d]," % [cat, int(ceil(float(_medidas[cat]["tri"]) * MARGEN)), int(ceil(float(_medidas[cat]["llamadas"]) * MARGEN))])
	Engine.time_scale = 1.0
	print("===== FIN. %d fallos =====" % _fallos)
	get_tree().quit(0 if _fallos == 0 else 1)
