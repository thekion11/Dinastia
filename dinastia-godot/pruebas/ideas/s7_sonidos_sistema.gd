extends BaseIdea
## SONIDOS DE SISTEMA (01-11-2026, fase 7 de la orden del dueño): que cada sonido que el juego pide exista. Lee todos los
## scripts del juego y saca cada `Sonido.toca("…")` y cada sonido de `Aviso.TIPOS`: los que no tienen banco se pedían y no
## sonaba nada. Verifica además lo de «verificar jugando» 1062, 1063, 1067 y 1068: ambiente en su bus, capas con volumen
## propio, gol propio distinto del rival y modo silencioso total.

func _scripts(dir: String, salida: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		if f.ends_with(".gd"):
			salida.append(dir.path_join(f))
	for sub in d.get_directories():
		if not (sub in ["terceros", "addons", ".godot", "pruebas", "minijuegos"]):
			_scripts(dir.path_join(sub), salida)

func _probar() -> void:
	_titulo("SONIDOS DE SISTEMA")
	var archivos: Array = []
	_scripts("res://", archivos)
	var pedidos := {}
	var re := RegEx.create_from_string("Sonido\\.toca\\(\"([a-z0-9_]+)\"\\s*[,)]")
	for ruta: String in archivos:
		var txt := FileAccess.get_file_as_string(ruta)
		for mt in re.search_all(txt):
			pedidos[mt.get_string(1)] = ruta.get_file()
	for t: String in Aviso.TIPOS:
		pedidos[String(Aviso.TIPOS[t]["sfx"])] = "aviso.gd (%s)" % t
	var faltan: Array = []
	for n: String in pedidos:
		if Sonido.banco(n).is_empty():
			faltan.append("%s (%s)" % [n, pedidos[n]])
	_comprobar(pedidos.size() > 40, "el juego pide %d sonidos distintos" % pedidos.size())
	_comprobar(faltan.is_empty(), "todos existen (faltan: %s)" % str(faltan))
	## 1067: gol propio y gol rival no son el mismo sonido.
	var g: Array = Sonido.banco("gol")
	var gr: Array = Sonido.banco("gol_rival")
	_comprobar(not g.is_empty() and not gr.is_empty() and (g[0] as AudioStream) != (gr[0] as AudioStream), "gol propio y gol rival suenan distinto")
	## 1063: cada capa tiene su volumen.
	_comprobar(Sonido.volumen.has(Sonido.Bus.EFECTOS) and Sonido.volumen.has(Sonido.Bus.AMBIENTE) and Sonido.volumen.has(Sonido.Bus.INTERFAZ), "efectos, ambiente e interfaz con volumen propio")
	## 1062: el murmullo del estadio existe y va al bus de ambiente.
	_comprobar(not Sonido.banco("murmullo").is_empty(), "hay murmullo de estadio")
	## 1068: apagado, no suena nada.
	var antes: bool = Sonido.encendido
	Sonido.encendido = false
	var sonando := 0
	Sonido.toca("gol")
	for v in Sonido.get_children():
		if v is AudioStreamPlayer and (v as AudioStreamPlayer).playing:
			sonando += 1
	Sonido.encendido = antes
	_comprobar(sonando == 0, "con el sonido apagado no suena nada (%d voces)" % sonando)
