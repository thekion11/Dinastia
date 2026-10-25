class_name HojasPersonaje
extends TabContainer
## LAS HOJAS DEL ASPECTO (25-10-2026): Cuerpo · Cara y pelo · Ropa · Accesorios.
## Las comparten la etapa de entrada (`PantallaPersonaje`) y el creador del menú
## (`CreadorPersonaje`, que suma su hoja de Conjuntos con `hoja_extra`).
##
## Guarda el aspecto (`asp`, el `Dictionary` de `PersonajeDT`) y su historial
## para Deshacer; cada cambio avisa con `cambiado` (la vista 3D se rearma).
## Lo que no tiene sentido con lo elegido se apaga con una nota, en vez de
## dejarlo tocar sin efecto: barba en una mujer, corbata sin traje, el tatuaje
## bajo una manga larga, un corte medido sin cara de la biblioteca...

signal cambiado(asp: Dictionary)

const HISTORIAL_MAX := 40
## Nombres de los peinados del 3D (los de `PELO_NOM` donde coinciden).
const PEINADOS := {"corto": "Corto clásico", "fade": "Degradado", "tupe": "Tupé", "flequillo": "Flequillo",
	"ondulado": "Ondulado", "rizado": "Rizado", "afro": "Afro", "largo": "Largo suelto", "melena": "Melena",
	"coleta": "Coleta", "samurai": "Moño samurái", "rastas": "Rastas", "rapado": "Rapado", "calvo": "Calvo"}
const CORTES_MEDIDOS := {"calvo": "Calvo", "degradado": "Degradado", "melena": "Melena",
	"melena_rizada": "Melena rizada", "normal": "Normal", "rapado": "Rapado", "tupe": "Tupé", "afro": "Afro"}
const COLORES_ROPA := ["1f2a44", "111111", "3a3a3a", "5a4636", "2e3f2a", "6a1b2a", "20354d", "c9c1b0"]
const COLORES_ROPA2 := ["f2f2f2", "cfe0f5", "e8e0d0", "ffc9c9", "d9d9d9", "111111"]

var asp: Dictionary = PersonajeDT.BASE.duplicate()
## Colores del club (el chándal, la gorra y la bufanda los usan siempre).
var c1 := Color("1f5fa8")
var c2 := Color.WHITE
## Una hoja más al final (Conjuntos del creador): `func() -> Control`.
var hoja_extra: Callable = Callable()
var hoja_extra_titulo := ""
var _historial: Array = []
var _ultima_clave := ""
var _ultima_vez := 0

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_font_size_override("font_size", Tema.TAM_CUERPO + 1)
	pintar()

## Pone un aspecto entero (aleatorio, un conjunto, lo guardado). `historial`:
## si se puede volver al anterior con Deshacer.
func poner(nuevo: Dictionary, historial := true) -> void:
	if historial:
		_apilar()
	asp = PersonajeDT.aspecto(nuevo)
	_ultima_clave = ""
	pintar()
	cambiado.emit(asp)

func puede_deshacer() -> bool:
	return not _historial.is_empty()

func deshacer() -> void:
	if _historial.is_empty():
		return
	asp = _historial.pop_back()
	_ultima_clave = ""
	pintar()
	cambiado.emit(asp)

func _apilar() -> void:
	_historial.append(asp.duplicate())
	if _historial.size() > HISTORIAL_MAX:
		_historial.pop_front()

## Un rasgo. Arrastrar un deslizador o el selector de color manda decenas de
## cambios seguidos de la misma clave: cuentan como UNO para Deshacer.
func cambiar(clave: String, valor: Variant, repintar := false) -> void:
	if asp.get(clave) == valor:
		if repintar:
			pintar()
		return
	var ahora := Time.get_ticks_msec()
	if clave != _ultima_clave or ahora - _ultima_vez > 1200:
		_apilar()
	_ultima_clave = clave
	_ultima_vez = ahora
	asp[clave] = valor
	if repintar:
		pintar()
	cambiado.emit(asp)

## Rehace las hojas conservando la pestaña y lo que se había bajado en ella
## (antes, cada clic en una opción del fondo devolvía la hoja arriba del todo).
func pintar() -> void:
	if not is_inside_tree():
		return
	var cual := current_tab if get_tab_count() > 0 else 0
	var bajado := 0
	if cual < get_child_count() and get_child(cual) is ScrollContainer:
		bajado = (get_child(cual) as ScrollContainer).scroll_vertical
	for h in get_children():
		remove_child(h)
		h.queue_free()
	var hojas: Array = [[_hoja_cuerpo(), "Cuerpo"], [_hoja_cara(), "Cara y pelo"], [_hoja_ropa(), "Ropa"],
		[_hoja_accesorios(), "Accesorios"]]
	if hoja_extra.is_valid():
		hojas.append([hoja_extra.call(), hoja_extra_titulo])
	for i in hojas.size():
		add_child(hojas[i][0])
		set_tab_title(i, Idiomas.t(String(hojas[i][1])))
	current_tab = clampi(cual, 0, get_tab_count() - 1)
	var sc := get_child(current_tab) as ScrollContainer
	if sc != null and bajado > 0:
		_volver_a_bajar.call_deferred(sc, bajado)

func _volver_a_bajar(sc: ScrollContainer, bajado: int) -> void:
	if is_instance_valid(sc):
		sc.scroll_vertical = bajado

## Una hoja con desplazamiento vertical y su columna.
static func hoja() -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var m := MarginContainer.new()
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for lado: String in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + lado, 14 if lado != "right" else 18)
	sc.add_child(m)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	m.add_child(vb)
	return vb

static func raiz(vb: VBoxContainer) -> Control:
	return vb.get_parent().get_parent() as Control

func _mujer() -> bool:
	return String(asp.get("cuerpo", "male")) == "female"

func _hoja_cuerpo() -> Control:
	var vb := hoja()
	var cb := cambiar
	ControlesPersonaje.opciones(vb, asp, "Cuerpo", "cuerpo", [["male", "Hombre"], ["female", "Mujer"]], cb)
	ControlesPersonaje.deslizador(vb, asp, "Estatura", "altura", 1.55, 2.02, 0.01,
		func(v: float) -> String: return ("%.2f m" % v).replace(".", ","), cb)
	for par: Array in [["Complexión", "complexion"], ["Hombros", "hombros"], ["Barriga", "barriga"],
			["Piernas", "piernas"], ["Cabeza", "cabeza"]]:
		ControlesPersonaje.deslizador(vb, asp, String(par[0]), String(par[1]), -1.0, 1.0, 0.05,
			func(v: float) -> String: return ControlesPersonaje.palabra_rasgo(v), cb)
	ControlesPersonaje.nota(vb, "Arrastra el personaje para girarlo; con la rueda, acércate. Así te verán en la banda en cada partido.")
	return raiz(vb)

func _hoja_cara() -> Control:
	var vb := hoja()
	var cb := cambiar
	var mujer := _mujer()
	ControlesPersonaje.muestras(vb, asp, "Tono de piel", "piel", PersonajeDT.PIELES, cb)
	## BIBLIOTECA MODULAR: caras mezcladas (del tono elegido) y cortes medidos.
	## Se guarda el NÚMERO de cara: sigue valiendo si después cambia el tono.
	if BibliotecaCaras.hay():
		var n_caras := BibliotecaCaras.del_tono(Color(String(asp.get("piel", "c68d68")))).size()
		var caras: Array = [[-1, Idiomas.t("Clásica")]]
		for i in n_caras:
			caras.append([i, Idiomas.t("Cara %d de %d") % [i + 1, n_caras]])
		if int(asp.get("cara", -1)) >= n_caras:
			asp["cara"] = int(asp["cara"]) % maxi(n_caras, 1)
		ControlesPersonaje.selector(vb, asp, "Cara", "cara", caras, cb, mujer,
			"por ahora, solo con cuerpo de hombre" if mujer else "mezclas de varias personas: no son la cara de nadie")
	ControlesPersonaje.muestras(vb, asp, "Color de ojos", "ojos", PersonajeDT.OJOS, cb)
	var peinados: Array = []
	for k: String in PersonajeDT.CORTES:
		peinados.append([k, String(PEINADOS.get(k, k.capitalize()))])
	var con_gorra := bool(asp.get("gorra", false))
	ControlesPersonaje.opciones(vb, asp, "Peinado", "pelo", peinados, cb, false,
		"con gorra solo asoma lo corto" if con_gorra else "")
	if BibliotecaCaras.hay() and not mujer:
		var sin_cara := int(asp.get("cara", -1)) < 0
		var cortes: Array = [["", Idiomas.t("Ninguno (el peinado)")]]
		var cuenta := {}
		for k: String in BibliotecaCaras.pelos():
			var nom := BibliotecaCaras.nombre_pelo(k)
			cuenta[nom] = int(cuenta.get(nom, 0)) + 1
			cortes.append([k, "%s · %d" % [Idiomas.t(String(CORTES_MEDIDOS.get(nom, nom.capitalize()))), cuenta[nom]]])
		ControlesPersonaje.selector(vb, asp, "Corte medido", "corte_med", cortes, cb, sin_cara or con_gorra,
			"elige antes una cara" if sin_cara else ("no va con gorra" if con_gorra else "cortes sacados de fotos, sobre la cara elegida"))
	ControlesPersonaje.muestras(vb, asp, "Color de pelo", "color_pelo", PersonajeDT.COLORES_PELO, cb)
	ControlesPersonaje.interruptor(vb, asp, "Barba", "barba", cb, mujer, "solo con cuerpo de hombre" if mujer else "")
	return raiz(vb)

func _hoja_ropa() -> Control:
	var vb := hoja()
	var cb := cambiar
	var ropa := String(asp.get("ropa", "traje"))
	ControlesPersonaje.opciones(vb, asp, "Estilo", "ropa", PersonajeDT.ROPAS, cb)
	if ropa == "chandal":
		ControlesPersonaje.nota(vb, "El chándal lleva siempre los colores del club.")
	else:
		ControlesPersonaje.muestras(vb, asp, "Color principal", "c_ropa", COLORES_ROPA + [c1.to_html(false)], cb)
		ControlesPersonaje.muestras(vb, asp, "Color secundario", "c_ropa2", COLORES_ROPA2 + [c2.to_html(false)], cb)
	var corbata := ropa in PersonajeDatos.CON_CORBATA
	ControlesPersonaje.interruptor(vb, asp, "Corbata", "corbata", cb, not corbata, "" if corbata else "con traje o abrigo")
	var manga := ropa in PersonajeDatos.CON_MANGA_CORTA
	ControlesPersonaje.interruptor(vb, asp, "Manga corta", "manga_corta", cb, not manga,
		"" if manga else "con polo, camisa o jersey")
	return raiz(vb)

func _hoja_accesorios() -> Control:
	var vb := hoja()
	var cb := cambiar
	ControlesPersonaje.opciones(vb, asp, "Gafas", "gafas", PersonajeDT.GAFAS, cb)
	var luce := bool(asp.get("manga_corta", false)) and String(asp.get("ropa", "")) in PersonajeDatos.CON_MANGA_CORTA
	ControlesPersonaje.opciones(vb, asp, "Tatuaje", "tatuaje", PersonajeDT.TATUAJES, cb, false,
		"" if luce else "se ve con manga corta")
	ControlesPersonaje.rotulo(vb, "Complementos")
	for par: Array in [["Gorra del club", "gorra"], ["Bufanda del club", "bufanda"], ["Auriculares", "auriculares"],
			["Reloj", "reloj"], ["Pendientes", "pendiente"], ["Cadena al cuello", "cadena"]]:
		ControlesPersonaje.interruptor(vb, asp, String(par[0]), String(par[1]), cb)
	return raiz(vb)
