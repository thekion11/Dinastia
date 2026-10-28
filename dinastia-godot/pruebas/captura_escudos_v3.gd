extends Node
## Hoja de 48 clubes al azar (semilla fija) cuyo escudo cambió en «escudos v3». ANTES=ruta.json carga la tabla ASPECTO_CLUB de antes.
##   [ANTES=/tmp/ant/pack_antes.json] godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_escudos_v3.tscn
var _f := 0

func _ready() -> void:
	Datos.usar_base_real(true)
	var mundo := Mundo.new()
	mundo.generar(["CHI", "ARG", "BRA", "URU", "PAR", "PER", "ESP", "ENG", "ITA", "GER", "FRA", "MEX", "KSA", "COL", "ECU", "POR", "NED", "TUR"], 4711)
	var fondo := ColorRect.new()
	fondo.color = Color("#2a3a30")
	fondo.size = Vector2(1280, 720)
	add_child(fondo)
	Datos.tabla("EQUIP_REAL").clear()
	var antes := OS.get_environment("ANTES")
	var viejo := {}
	if antes != "":
		viejo = (JSON.parse_string(FileAccess.get_file_as_string(antes)) as Dictionary).get("tablas", {}).get("ASPECTO_CLUB", {})
	var nuevo: Dictionary = Datos.tabla("ASPECTO_CLUB")
	var cambiados: Array = []
	var por_nombre := {}
	for l in mundo.ligas:
		for c in l.clubes:
			por_nombre[c.nombre] = c
	var pack: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://datos/pack_real.json")) as Dictionary).get("tablas", {}).get("ASPECTO_CLUB", {})
	var ant0: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("/tmp/ant/pack_antes.json")) as Dictionary).get("tablas", {}).get("ASPECTO_CLUB", {}) if FileAccess.file_exists("/tmp/ant/pack_antes.json") else {}
	for k: String in pack:
		var a: Dictionary = ant0.get(k, {})
		if por_nombre.has(k) and pack[k] != a and String(a.get("emblema", "")) == "" and String(a.get("letras", "")) == "":
			cambiados.append(k)
	cambiados.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = 2810
	var elegidos: Array = []
	while elegidos.size() < mini(48, cambiados.size()):
		var k: String = cambiados[rng.randi() % cambiados.size()]
		if not elegidos.has(k):
			elegidos.append(k)
	if antes != "":
		nuevo.clear()
		nuevo.merge(viejo)
	var i := 0
	for n: String in elegidos:
		var c: Club = por_nombre[n]
		var x := 16.0 + (i % 8) * 156.0
		var y := 8.0 + (i / 8) * 118.0
		var esc := TextureRect.new()
		esc.texture = Escudo.textura(c, 96)
		esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		esc.size = Vector2(72, 80)
		esc.position = Vector2(x + 36, y)
		add_child(esc)
		var t := Label.new()
		t.text = n
		t.position = Vector2(x, y + 82)
		t.size = Vector2(150, 24)
		t.clip_text = true
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.add_theme_font_size_override("font_size", 12)
		add_child(t)
		i += 1

func _process(_d: float) -> void:
	_f += 1
	if _f == 12:
		get_viewport().get_texture().get_image().save_png("/tmp/escudos_v3_%s.png" % ("antes" if OS.get_environment("ANTES") != "" else "despues"))
		print("FIN. 0 fallos")
		get_tree().quit()
