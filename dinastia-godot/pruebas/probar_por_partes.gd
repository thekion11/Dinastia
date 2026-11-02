extends Node
## El estadio y la ciudad armados POR PARTES (entre fotogramas, con la pantalla de carga encima)
## quedan iguales que armados de una vez: mismos nodos (tipo y nombre) y mismas mallas, mirados 10
## fotogramas después (lo diferido ya creado; sin posiciones: la gente ya camina). El estadio,
## exacto. La ciudad ya variaba entre dos armados iguales en el código original (qué edificio de
## poco detalle sale en 2-3 sitios, comprobado el 30-10): se admiten hasta 12 filas distintas.
## Y por partes se cede de verdad: hay varios fotogramas por el medio (30-10-2026).

var _fallos := 0
var _cuadros := 0   ## cuadros vistos por la señal `process_frame` (Engine.get_process_frames() no avanza de forma fiable en headless: 2 esperas = 1)

func _un_cuadro() -> void:
	_cuadros += 1

## Espera a que lo diferido (gente, tráfico) termine de crearse: el árbol no cambia durante 8 cuadros seguidos (tope 240).
## Antes eran 10 cuadros fijos y, según la máquina, a veces no bastaban (el «dos armados dan lo mismo» oscilaba en el CI).
func _esperar_estable(raiz: Node) -> void:
	var antes := -1
	var quietos := 0
	for i in 240:
		await get_tree().process_frame
		var ahora := raiz.find_children("*", "", true, false).size()
		quietos = quietos + 1 if ahora == antes else 0
		antes = ahora
		if quietos >= 8:
			return

func _ready() -> void:
	_correr.call_deferred()

func _correr() -> void:
	get_tree().process_frame.connect(_un_cuadro)
	var m := Mundo.new()
	m.generar(["CHI"], 777)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	var huellas := {}
	for partes: bool in [false, true, false]:
		Azar.sembrar(4242)
		var v := VistaEstadio.new()
		v.por_partes = partes
		add_child(v)
		var f0 := _cuadros
		await v.abrir(c, 0.5, null, null, m.perfil_estadio_de(c))
		var n := _cuadros - f0
		_comprobar(not partes or n >= 3, "estadio por partes cede fotogramas (%d)" % n)
		_comprobar(v.process_mode == Node.PROCESS_MODE_INHERIT, "estadio vuelve a procesar")
		await _esperar_estable(v)
		huellas["estadio%s" % partes] = huellas.get("estadio%s" % partes, []) + [_huella(v)]
		v.free()
	for partes: bool in [false, true, false]:
		Azar.sembrar(4242)
		var vc := VistaCiudad.new()
		vc.por_partes = partes
		add_child(vc)
		var f1 := _cuadros
		await vc.abrir(c, m.obras, m.ciudad, m.perfil_estadio_de(c))
		var n2 := _cuadros - f1
		_comprobar(not partes or n2 >= 3, "ciudad por partes cede fotogramas (%d)" % n2)
		await _esperar_estable(vc)   ## lo que se crea diferido (gente, tráfico) en los dos modos
		huellas["ciudad%s" % partes] = huellas.get("ciudad%s" % partes, []) + [_huella(vc)]
		vc.free()
	for que in ["estadio", "ciudad"]:
		var de_una: Array = huellas[que + "false"]
		var tope := 0 if que == "estadio" else 12
		var base := _distintas(de_una[0], de_una[1])
		var pp := _distintas(huellas[que + "true"][0], de_una[0])
		print("%s: filas distintas de una vez/de una vez %d, por partes/de una vez %d" % [que, base, pp])
		_comprobar(base <= tope, "%s: dos armados de una vez dan lo mismo (base)" % que)
		_comprobar(pp <= tope, "%s: por partes = de una vez" % que)
	print("FIN. %d fallos" % _fallos)
	get_tree().quit()

func _comprobar(ok: bool, que: String) -> void:
	if not ok:
		_fallos += 1
		print("FALLO ", que)

## Tipo, nombre (sin los @números que pone Godot) y malla de cada nodo, ordenados.
func _huella(n: Node) -> PackedStringArray:
	var filas := PackedStringArray()
	_recorrer(n, filas)
	filas.sort()
	return filas

## Cuántas filas sobran en una o en otra (como multiconjuntos).
func _distintas(a: PackedStringArray, b: PackedStringArray) -> int:
	var cuenta := {}
	for f in a:
		cuenta[f] = int(cuenta.get(f, 0)) + 1
	for f in b:
		cuenta[f] = int(cuenta.get(f, 0)) - 1
	var n := 0
	for k in cuenta:
		n += absi(int(cuenta[k]))
		## `PARTES_DETALLE=1`: qué filas sobran (para cazar lo que no sale igual entre dos armados).
		if int(cuenta[k]) != 0 and OS.get_environment("PARTES_DETALLE") == "1":
			print("  %+d %s" % [int(cuenta[k]), k])
	return n

func _recorrer(n: Node, filas: PackedStringArray) -> void:
	var nombre := str(n.name)
	if nombre.begins_with("@"):
		nombre = nombre.get_slice("@", 1)
	var fila := n.get_class() + ":" + nombre
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		fila += ":" + str((n as MeshInstance3D).mesh.get_class()) + str((n as MeshInstance3D).get_aabb().size.snapped(Vector3.ONE * 0.01))
	if n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null:
		fila += ":mm" + str((n as MultiMeshInstance3D).multimesh.instance_count)
	filas.append(fila)
	for h in n.get_children():
		_recorrer(h, filas)
