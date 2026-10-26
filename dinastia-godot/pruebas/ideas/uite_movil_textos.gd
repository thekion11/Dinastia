extends BaseIdea
## EL MÓVIL ENTERO EN INGLÉS (25-10-2026, paquete uite). Abre cada app y cada pestaña de Tribuna con
## contenido (tu publicación, la del club, las de los jugadores, los comentarios abiertos) y busca
## castellano que se haya colado: frases de la red, nombres de tipos, avisos.

## Palabras que en una interfaz en inglés solo aparecen si algo quedó sin traducir.
const DELATORAS := [" el ", " los ", " las ", " del ", " por ", " con ", " que ", " una ", " para ", "¿", "¡",
	"ción", "Semana", "semana", "publicaciones", "seguidores", "Apoyarlo", "Cortante", "Agradecer", "Explicar",
	"Con humor", "en línea", "ESTRÉS", "TRABAJO", "Cargado", "EQUILIBRIO", "Tranquilo", "PORTADA", "PRÓXIMO", "Nueva publicación", "Efecto", "tu plantel", "Polémica"]

var _vistos: Array[String] = []

func _probar() -> void:
	_titulo("EL MÓVIL ENTERO EN INGLÉS (uite)")
	var m := _mundo(4242)
	m.redes.publicar(m, "hinchada", ["#Hinchada"])
	m.redes.dar_acceso_club(m)
	m.redes._publican_jugadores(m)
	Idiomas.idioma = "en"
	var tel := Telefono.crear(m, [{"titulo": "Victoria", "cuerpo": "El equipo gana."}])
	add_child(tel)
	for p: Dictionary in m.redes.publicaciones:
		(tel.get("_abiertos") as Dictionary)[int(p["id"])] = true
	for app: String in ["inicio", "mensajes", "noticias", "banco", "calendario", "fotos", "ajustes"]:
		tel.abrir_app(app)
		_recoger(tel, app)
	## La red social es un NOMBRE PROPIO: «Tribuna» (la del estadio) se traduce «Stand», la app no.
	tel.abrir_app("inicio")
	var marca := _textos_de(tel.get("_cuerpo"))
	_comprobar(marca.has("Tribuna") and not marca.has("Stand"), "en inglés la app sigue llamándose «Tribuna»")
	_comprobar(Idiomas.t("Tribuna") == "Stand", "y la tribuna del estadio sí se traduce («Stand»)")
	m.redes.sesion = "dt"
	for sub: String in ["inicio", "perfil", "club", "publicar"]:
		tel.set("_sub", sub)
		tel.abrir_app("tribuna")
		_recoger(tel, "tribuna/" + sub)
	m.redes.sesion = "club"
	tel.set("_sub", "publicar")
	tel.abrir_app("tribuna")
	_recoger(tel, "tribuna/publicar club")
	m.redes.sesion = ""
	tel.abrir_app("tribuna")
	_recoger(tel, "tribuna/login")
	var chats := m.movil.chats()
	_comprobar(not chats.is_empty(), "hay al menos un chat (la clave del club)")
	if not chats.is_empty():
		tel.set("_chat", String(chats[0]["de"]))
		tel.abrir_app("mensajes")
		_recoger(tel, "un chat")
	## MI VIDA, las tres secciones, traducidas como lo hace la pantalla principal.
	var host := Anfitrion.new()
	host.mundo = m
	add_child(host)
	var lista := VBoxContainer.new()
	host.add_child(lista)
	m.vida.estres = 62
	for secc: String in ["bienestar", "hogar", "familia"]:
		PanelVida.pintar(lista, host, m, secc)
		Idiomas.traducir_arbol(lista)
		_recoger_en(lista, null, "mi vida/" + secc)
	Idiomas.idioma = "es"
	_comprobar(_vistos.size() > 60, "se revisaron %d textos del móvil" % _vistos.size())

func _textos_de(n: Node) -> Array[String]:
	var r: Array[String] = []
	for l in n.find_children("*", "Label", true, false):
		if not l.is_queued_for_deletion() and not _borrado(l):
			r.append((l as Label).text)
	return r

## Lo mínimo que PanelVida le pide a la pantalla que lo aloja.
class Anfitrion extends Control:
	var mundo: Mundo
	var _bandeja: Array = []
	func _refrescar() -> void:
		pass

func _recoger(tel: Telefono, donde: String) -> void:
	_recoger_en(tel.get("_cuerpo"), tel.get("_aviso"), donde)

func _recoger_en(cuerpo: Node, aviso: Label, donde: String) -> void:
	var textos: Array[String] = [aviso.text if aviso != null else ""]
	for n in cuerpo.find_children("*", "Control", true, false):
		if n.is_queued_for_deletion() or _borrado(n):
			continue
		if n is Label:
			textos.append((n as Label).text)
		elif n is Button:
			textos.append((n as Button).text)
		elif n is RichTextLabel:
			textos.append((n as RichTextLabel).get_parsed_text())
		elif n is LineEdit:
			textos.append((n as LineEdit).placeholder_text)
	var malos: Array[String] = []
	for t: String in textos:
		_vistos.append(t)
		for d: String in DELATORAS:
			if (" " + t + " ").contains(d):
				malos.append(t.replace("\n", " / "))
				break
	_comprobar(malos.is_empty(), "%s: sin castellano colado %s" % [donde, str(malos.slice(0, 8)) if not malos.is_empty() else ""])

## Lo que `abrir_app` soltó con queue_free sigue colgado hasta el fin del cuadro.
func _borrado(n: Node) -> bool:
	var x := n
	while x != null:
		if x.is_queued_for_deletion():
			return true
		x = x.get_parent()
	return false
