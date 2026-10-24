extends Node
## Lista TODOS los textos del móvil, app por app, en el idioma pedido, para cazar frases sin traducir (23-10-2026).
##   IDIOMA=en godot --headless --path . res://pruebas/auditar_textos_movil.tscn
var _n := 0
var _p: Node
var _tel: Telefono
var _idioma := "en"
const APPS := ["inicio", "tribuna", "mensajes", "noticias", "banco", "calendario", "fotos", "ajustes"]

func _ready() -> void:
	if OS.get_environment("IDIOMA") != "":
		_idioma = OS.get_environment("IDIOMA")
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 9:
		Idiomas.idioma = _idioma
	if _n == 10:
		var m: Mundo = _p.get("mundo")
		m.redes.publicar(m, "hinchada", ["#Hinchada", m.redes.tendencia])
		_p.call("_anotar", "Victoria", "El equipo gana 2-1.")
		var pop := Telefono.abrir(_p, m)
		_tel = pop.find_children("*", "Telefono", true, false)[0]
	if _n >= 12 and (_n - 12) % 6 == 0:
		var i := (_n - 12) / 6
		if i > 0:
			_volcar(APPS[i - 1])
		if i < APPS.size():
			_tel.abrir_app(APPS[i])
		else:
			get_tree().quit()

func _volcar(app: String) -> void:
	var textos: Array[String] = []
	for n in _tel.find_children("*", "", true, false):
		if n is Label and (n as Label).text.strip_edges() != "":
			textos.append((n as Label).text.replace("\n", " ⏎ "))
		elif n is Button and (n as Button).text.strip_edges() != "":
			textos.append("[%s]" % (n as Button).text)
	print("APP %s: %s" % [app, " | ".join(textos)])
