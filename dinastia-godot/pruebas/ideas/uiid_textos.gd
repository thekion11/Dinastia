extends BaseIdea
## IDENTIDAD, EDITOR, ESTADIO Y CIUDAD EN INGLÉS (25-10-2026, paquete uiid). Pinta las cuatro pantallas
## con todo desplegado (identidad y comercial del club, el editor con un club y un jugador abiertos, el
## diseñador del estadio con tribunas y tercios a la vista, la ciudad), pasa el traductor de la pantalla
## (el mismo que corre en cada refresco) y busca castellano que se haya colado. Además mira que los
## selectores de color arranquen con un color OPACO: uno transparente se ve como un damero y no dice
## de qué color es el club.

## Palabras que en una interfaz en inglés solo aparecen si algo quedó sin traducir.
const DELATORAS := [" el ", " los ", " las ", " del ", " por ", " con ", " que ", " una ", " para ", " años",
	"¿", "¡", "ción", " sin ", "Color ", "Bajan", "Victoria", "puntos", "Cancha", "Sede", "Reputación",
	"Aforo", "Media", "Proyección", "Edad", "Dorsal", "Puesto", "Rasgo", "País", "Corte", "Accesorio",
	"Barba", "Nariz", "Boca", "Ojos", "Cara", "Mandíbula", "Pecas", "Lunar", "Cicatriz", "Titular",
	"Alternativa", "arquero", "Diseño", "Forma", "Patrón", "Símbolo", "sorteo", "Fondo", "Borde",
	"Techo", "Focos", "Butacas", "Banderas", "Túnel", "Tribuna", "Anillo", "Tercio", "Fachada",
	"Superficie", "césped", "Banquillos", "Pantallas", "Sonido", "Entra cada", "Aporta", "Total de",
	"Contrato", "Rentan", "semana", "Negocios", "Ingreso", "Relación", "Estado", "Seguridad",
	"Cámaras", "Riesgo", "Cubierta", "Ahorro", "Certific", "Paneles", "Permiso", "Subvención",
	"Conciertos", "Obra social", "Reunión", "Entradas", "libre", "Festejo", "Balón", "Tipo de",
	"Natural", "Híbrido", "Sintético", "SÍ", "NO", "Firmar", "Firmado", "Romper", "Tuyo", "Operando",
	"vigente", "Requiere", "Medias", "short", "tipografía", "liso", "franjas", "banda", "mitad"]

var _vistos: Array[String] = []
var _p: Node

func _probar() -> void:
	_titulo("IDENTIDAD, EDITOR, ESTADIO Y CIUDAD EN INGLÉS (uiid)")
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	var m: Mundo = _p.get("mundo")
	var mio := m.mi_club()
	mio.saldo = 999999999
	_colores_opacos(mio)
	Idiomas.idioma = "es" if OS.get_environment("UIID_LISTA") != "" else "en"
	for secc: String in ["identidad", "comercial"]:
		_p.set("_secc_gente", secc)
		_p.call("_limpiar", _p.get("_lista_gente"))
		_p.get("_ui_gente").call("_pintar_gente")
		_recoger(_p.get("_lista_gente"), "gente · " + secc)
	m.estadio.reformar(mio, {"personalizar_bandejas": true, "personalizar_tramos": true}, m.obras)
	_p.call("_pintar_estadio", mio)
	_recoger(_p.get("_lista_estadio"), "estadio")
	_p.set("_ed_club", mio.id)
	_p.set("_ed_jugador", (mio.plantilla[0] as Jugador).id)
	_p.get("_ui_editor").call("_pintar_editor")
	_recoger(_p.get("_lista_editor"), "editor")
	m.ciudad.permiso_ok = false
	_p.call("_pintar_ciudad", mio)
	_recoger(_p.get("_lista_ciudad"), "ciudad")
	Idiomas.idioma = "es"
	_comprobar(_vistos.size() > 250, "se revisaron %d textos" % _vistos.size())

## Los selectores de color del editor y de identidad, en castellano y sin traducir nada.
func _colores_opacos(mio: Club) -> void:
	_p.set("_secc_gente", "identidad")
	_p.call("_limpiar", _p.get("_lista_gente"))
	_p.call("_pintar_identidad", mio)
	_p.set("_ed_club", mio.id)
	_p.get("_ui_editor").call("_pintar_editor")
	var malos: Array[String] = []
	var n := 0
	for raiz: Node in [_p.get("_lista_gente"), _p.get("_lista_editor")]:
		for cp in raiz.find_children("*", "ColorPickerButton", true, false):
			n += 1
			if (cp as ColorPickerButton).color.a < 0.99:
				malos.append(str((cp as ColorPickerButton).color))
	_comprobar(n >= 10 and malos.is_empty(), "%d selectores de color, todos opacos %s" % [n, str(malos)])

func _recoger(raiz: Node, donde: String) -> void:
	if OS.get_environment("UIID_LISTA") != "":
		_listar_sin_traducir(raiz)
		return
	_p.call("_traducir_pantalla", raiz)
	var textos: Array[String] = []
	for n in raiz.find_children("*", "Control", true, false):
		if _borrado(n):
			continue
		if n is OptionButton:
			for i in (n as OptionButton).item_count:
				textos.append((n as OptionButton).get_item_text(i))
		elif n is Label:
			textos.append((n as Label).text)
		elif n is Button:
			textos.append((n as Button).text)
		if n is Control and (n as Control).tooltip_text != "":
			textos.append((n as Control).tooltip_text)
		if n is LineEdit and (n as LineEdit).placeholder_text != "":
			textos.append((n as LineEdit).placeholder_text)
	var malos: Array[String] = []
	for t: String in textos:
		_vistos.append(t)
		for d: String in DELATORAS:
			if (" " + t + " ").contains(d):
				if t.replace("\n", " / ") not in malos:
					malos.append(t.replace("\n", " / "))
				break
	for x in malos:
		print("    ES: ", x)
	_comprobar(malos.is_empty(), "%s: sin castellano colado (%d textos, %d malos)" % [donde, textos.size(), malos.size()])

## Lo que se soltó con queue_free sigue colgado hasta el fin del cuadro.
func _borrado(n: Node) -> bool:
	var x := n
	while x != null:
		if x.is_queued_for_deletion():
			return true
		x = x.get_parent()
	return false

## Ayuda para escribir el parche de traducciones (UIID_LISTA=1): con la interfaz
## en castellano, cada texto pintado cuya traducción al inglés sale igual, una
## por línea y sin repetir.
var _listadas := {}
func _listar_sin_traducir(raiz: Node) -> void:
	var antes := Idiomas.idioma
	for n in raiz.find_children("*", "Control", true, false):
		var fuentes: Array = []
		if n is OptionButton:
			for i in (n as OptionButton).item_count:
				fuentes.append((n as OptionButton).get_item_text(i))
		elif n is Label or n is Button:
			fuentes.append(n.get("text"))
		if (n as Control).tooltip_text != "":
			fuentes.append((n as Control).tooltip_text)
		if n is LineEdit:
			fuentes.append((n as LineEdit).placeholder_text)
		for f: Variant in fuentes:
			var src := String(f)
			Idiomas.idioma = "en"
			var igual := Idiomas.t(src) == src
			Idiomas.idioma = antes
			if src.strip_edges() == "" or _listadas.has(src) or not igual:
				continue
			if RegEx.create_from_string("[A-Za-zÁÉÍÓÚáéíóúñÑ]{3}").search(src) == null:
				continue
			_listadas[src] = true
			print("SINTRAD\t", src.replace("\n", "\\n"))
