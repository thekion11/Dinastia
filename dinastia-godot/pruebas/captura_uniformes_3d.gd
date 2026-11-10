extends Node
## UNIFORMES EN EL PARTIDO 3D con la cámara real (10-11): 3 cruces de 3 países distintos donde chocan los colores de la camiseta local.
##   PAR=0..2 herramientas/captura.sh res://pruebas/captura_uniformes_3d.tscn      (salida: user://uni3d_<PAR>_<n>.png → /tmp/cap)
## Busca en un mundo de 8 países los pares (de países distintos) cuyos uniformes locales chocan y toma los tres primeros de países nuevos.
const PAISES: Array[String] = ["ESP", "ARG", "GER", "BRA", "FRA", "ENG", "ITA", "MEX"]
const ARRANQUE := 150
var _n := 0
var _vista: VistaEstadio
var _par := 0
var _tomadas := 0
var _p: Partido
const MINUTOS := [2, 9]

func _ready() -> void:
	_par = int(OS.get_environment("PAR")) if OS.get_environment("PAR") != "" else 0
	var m := Mundo.new()
	m.generar(PAISES, 9137)
	var elegidos: Array = []
	var usados := {}
	var todos: Array[Club] = []
	for c: Club in m.clubes.values():
		todos.append(c)
	todos.sort_custom(func(a: Club, b: Club) -> bool: return a.id < b.id)
	for a: Club in todos:
		for b: Club in todos:
			if a.pais == b.pais or usados.has(a.pais) or usados.has(b.pais) or elegidos.size() >= 3:
				continue
			if Puente3D.chocan(Puente3D.kit(a), Puente3D.kit(b)):
				elegidos.append([a, b])
				usados[a.pais] = true
				usados[b.pais] = true
	print("cruces: ", elegidos.map(func(p: Array) -> String: return "%s (%s) – %s (%s)" % [p[0].nombre, p[0].pais, p[1].nombre, p[1].pais]))
	if elegidos.size() <= _par:
		print("no hay cruce ", _par)
		get_tree().quit()
		return
	var a: Club = elegidos[_par][0]
	var b: Club = elegidos[_par][1]
	m.mi_club_id = a.id
	var p := Partido.new(a, b)
	_p = p
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(a, 0.9, b, p)
	_vista.get("_juego").vel_idx = 4
	var kv := Puente3D.kit_visita(a, b)
	print("local %s %s/%s %s | visita %s: kit propio %s → lleva %s/%s %s" % [a.nombre, a.color_kit1(), a.color_kit2(), Puente3D.kit(a)["estilo"], b.nombre, Puente3D.kit(b)["c1"], kv["c1"], kv["c2"], kv["estilo"]])

func _process(_d: float) -> void:
	_n += 1
	if _n < ARRANQUE or _p == null or _tomadas >= MINUTOS.size() or _p.minuto < MINUTOS[_tomadas]:
		return
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/cap/uni3d_%d_%d.png" % [_par, _tomadas])
	_tomadas += 1
	print("captura ", _tomadas)
	if _tomadas >= 2:
		get_tree().quit()
