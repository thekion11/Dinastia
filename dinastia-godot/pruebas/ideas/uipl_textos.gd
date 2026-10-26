extends BaseIdea
## PLANTEL, FICHA Y CANTERA EN INGLÉS (25-10-2026, paquete uipl). Pinta la pestaña «Mi plantel», la ficha
## de un jugador propio con una temporada jugada, la de un rival y la cantera, pasa el traductor de la
## pantalla (el mismo que corre en cada refresco) y busca castellano que se haya colado.

## Palabras que en una interfaz en inglés solo aparecen si algo quedó sin traducir.
const DELATORAS := [" el ", " los ", " las ", " del ", " por ", " con ", " que ", " una ", " para ", " años",
	"¿", "¡", "ción", " sin ", "Pie ", "Derecho", "Izquierdo", "Pierna", "Confianza", "Estado mental",
	"Satisfacción", "Minutos", "Rendimiento", "Instalaciones", "Rol prometido", "Ídolo", "Marca personal",
	"Puesto natural", "NOMBRE", "EDAD", "VALOR", "Goles", "Nota", "Debutó", "Hijo de", "lesión", "becado",
	"Becar", "fuga ", "Amarillas", "Mejor cualidad", "Punto débil", "Celebración", "Fiabilidad", "Media",
	"Partidos", "Camarín", "pertenece", "Sueldo", "Contrato", "jugadores", "Todos", "Porteros", "Defensas"]

var _vistos: Array[String] = []
var _p: Node

func _probar() -> void:
	_titulo("PLANTEL, FICHA Y CANTERA EN INGLÉS (uipl)")
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	var m: Mundo = _p.get("mundo")
	m.jugar_temporada()
	m.nueva_temporada()
	var mio := m.mi_club()
	Idiomas.idioma = "en"
	_p.call("_refrescar")
	_p.get("_ui_plantel")._pintar_plantel(mio)
	_recoger(_p.get("_lista_plantel"), "plantel")
	_p.get("_ui_cantera")._pintar_cantera(mio)
	_recoger(_p.get("_lista_cantera"), "cantera")
	## La ficha de cada jugador propio: cada uno ejerce bloques distintos
	## (lesión, premios, crecimiento, rol prometido…).
	for j: Jugador in mio.plantilla:
		_p.call("_ver_ficha", j)
		_bloques_propios(j, m)
		_recoger(_p.get("_ficha"), "ficha propia")
	for c: Club in m.clubes.values():
		if c.id != mio.id and not c.plantilla.is_empty():
			_p.call("_ver_ficha", c.plantilla[0])
			_recoger(_p.get("_ficha"), "ficha ajena")
			break
	## «MED» es la línea de centrocampistas (chips de puesto en otras pantallas) y
	## no la columna de la media, que usa su propia clave «MEDIA».
	_comprobar(Idiomas.t("MED") == "MID" and Idiomas.t("MEDIA") == "OVR", "MED (línea) y MEDIA (columna) no se pisan en inglés")
	Idiomas.idioma = "es"
	_comprobar(_vistos.size() > 200, "se revisaron %d textos" % _vistos.size())

## Los bloques de `FichaJugadorInfo`/`FichaJugadorAcciones` SIN el traductor de la
## pantalla: así los pinta el clic en un jugador (`_ver_ficha` no lo pasa), y
## tienen que salir ya traducidos por su cuenta.
func _bloques_propios(j: Jugador, m: Mundo) -> void:
	var caja := VBoxContainer.new()
	add_child(caja)
	var pal: Dictionary = _p.get("_ui_ficha")._paleta_ficha()
	var nada := func(_x: Variant = null) -> void: pass
	FichaJugadorInfo.pintar_ciega(caja, j, m, pal)
	FichaJugadorInfo.pintar_estadisticas(caja, j, pal)
	FichaJugadorInfo.pintar_perfil_y_premios(caja, j, pal)
	FichaJugadorInfo.pintar_cabeza(caja, j, m, pal)
	FichaJugadorInfo.pintar_promesa(caja, j, m, pal)
	FichaJugadorInfo.pintar_habilidades(caja, j, m, pal)
	FichaJugadorInfo.pintar_historial_medico(caja, j, m, pal)
	FichaJugadorInfo.pintar_vida_personal(caja, j, m, pal)
	FichaJugadorInfo.pintar_historial(caja, j, pal)
	FichaJugadorAcciones.pintar_reconversion(caja, j, m, pal, nada)
	FichaJugadorAcciones.pintar_marca(caja, j, m.mi_club(), m, pal, nada)
	FichaJugadorAcciones.pintar_venta(caja, j, m.mi_club(), m, pal, "", nada, nada, nada)
	_recoger(caja, "bloques propios de la ficha sin traductor", false)
	caja.free()

func _recoger(raiz: Node, donde: String, traducir: bool = true) -> void:
	if traducir:
		_p.call("_traducir_pantalla", raiz)
	var textos: Array[String] = []
	for n in raiz.find_children("*", "Control", true, false):
		if _borrado(n):
			continue
		if n is Label:
			textos.append((n as Label).text)
		elif n is Button:
			textos.append((n as Button).text)
		elif n is RichTextLabel:
			textos.append((n as RichTextLabel).get_parsed_text())
	var malos: Array[String] = []
	for t: String in textos:
		_vistos.append(t)
		for d: String in DELATORAS:
			if (" " + t + " ").contains(d):
				if t.replace("\n", " / ") not in malos:
					malos.append(t.replace("\n", " / "))
				break
	_comprobar(malos.is_empty(), "%s: sin castellano colado %s" % [donde, str(malos.slice(0, 40)) if not malos.is_empty() else ""])

## Lo que se soltó con queue_free sigue colgado hasta el fin del cuadro.
func _borrado(n: Node) -> bool:
	var x := n
	while x != null:
		if x.is_queued_for_deletion():
			return true
		x = x.get_parent()
	return false
