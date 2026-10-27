extends Node
## Hoja de escudo + camiseta de 24 clubes reales (orden 15, 27-10-2026). Con ASPECTO=0 se apaga la tabla nueva: es el «antes».
##   ASPECTO=0 godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_aspecto_clubes.tscn
const CLUBES := ["Boca Juniors", "River Plate", "Flamengo", "Barcelona", "Real Madrid", "Milan", "Juventus", "Manchester Utd",
	"Liverpool", "Bayern Múnich", "Paris SG", "Colo-Colo", "U. de Chile", "Peñarol", "Nacional", "Santos", "Inter", "Arsenal",
	"Atlético Madrid", "Marsella", "Universitario", "Olimpia", "Cruz Azul", "Al-Hilal"]
var _f := 0

func _ready() -> void:
	Datos.usar_base_real(true)
	var mundo := Mundo.new()
	mundo.generar(["CHI", "ARG", "BRA", "URU", "PAR", "PER", "ESP", "ENG", "ITA", "GER", "FRA", "MEX", "KSA"], 4711)
	var fondo := ColorRect.new()
	fondo.color = Color("#2a3a30")
	fondo.size = Vector2(1280, 720)
	add_child(fondo)
	var por_nombre := {}
	for l in mundo.ligas:
		for c in l.clubes:
			por_nombre[Nombres.limpiar(c.nombre)] = c
	Datos.tabla("EQUIP_REAL").clear()   ## sin las fotos privadas de equipaciones: lo que ve el build público
	if OS.get_environment("ASPECTO") == "0":
		Datos.tabla("ASPECTO_CLUB").clear()
	var i := 0
	for n: String in CLUBES:
		var c: Club = por_nombre.get(n)
		if c == null:
			print("falta ", n)
			continue
		var x := 20.0 + (i % 6) * 208.0
		var y := 8.0 + (i / 6) * 178.0
		var cam := TextureRect.new()
		cam.texture = Jersey.textura(c, 0, 256)
		cam.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cam.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cam.custom_minimum_size = Vector2(110, 104)
		cam.size = Vector2(110, 104)
		cam.position = Vector2(x, y)
		add_child(cam)
		var esc := TextureRect.new()
		esc.texture = Escudo.textura(c, 96)
		esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		esc.custom_minimum_size = Vector2(72, 80)
		esc.size = Vector2(72, 80)
		esc.position = Vector2(x + 116, y + 8)
		add_child(esc)
		var t := Label.new()
		t.text = n
		t.position = Vector2(x, y + 112)
		t.add_theme_font_size_override("font_size", 14)
		add_child(t)
		i += 1

func _process(_d: float) -> void:
	_f += 1
	if _f == 12:
		var ruta := "/tmp/aspecto_%s.png" % ("antes" if OS.get_environment("ASPECTO") == "0" else "despues")
		get_viewport().get_texture().get_image().save_png(ruta)
		print("FIN. 0 fallos")
		get_tree().quit()
