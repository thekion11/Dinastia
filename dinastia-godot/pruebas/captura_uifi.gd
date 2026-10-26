extends Node
## CAPTURAS DEL PAQUETE uifi (sesión 2, 25-10-2026): finanzas (balance y flujo
## de caja), mercado con una mesa de negociación abierta tras una ronda, y la
## mesa del representante. Abre `principal.tscn` de verdad: la cámara real.
##   UIFI_FASE=antes RESOLUCION=1280x720 herramientas/captura.sh res://pruebas/captura_uifi.tscn
## Deja pruebas/capturas/uifi_<fase>_<res>_{finanzas,mercado,mesa}.jpg

const ESPERA := 12

var _pantalla: Node
var _n := 0
var _fase := "antes"
var _res := ""

func _ready() -> void:
	_fase = OS.get_environment("UIFI_FASE") if OS.get_environment("UIFI_FASE") != "" else "antes"
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _guardar(nombre: String) -> void:
	var img := get_viewport().get_texture().get_image()
	_res = "%dx%d" % [img.get_width(), img.get_height()]
	var ruta := "res://pruebas/capturas/uifi_%s_%s_%s.png" % [_fase, _res, nombre]
	img.save_png(ruta)
	print("captura: ", ruta)

## Busca la etiqueta con ese texto y desplaza su ScrollContainer hasta dejarla arriba.
func _desplazar_a(raiz: Node, texto: String) -> void:
	var l := _buscar(raiz, texto)
	if l == null:
		print("AVISO: no se encontró «%s»" % texto)
		return
	var s: Node = l.get_parent()
	while s != null and not (s is ScrollContainer):
		s = s.get_parent()
	if s != null:
		var sc := s as ScrollContainer
		sc.scroll_vertical = int(l.global_position.y - sc.global_position.y) + sc.scroll_vertical - 8
		print("desplazado a «%s»: %d de %d" % [texto, sc.scroll_vertical, int(sc.get_v_scroll_bar().max_value)])

func _buscar(raiz: Node, texto: String) -> Control:
	for h in raiz.get_children():
		if (h is Label and String((h as Label).text).contains(texto)) or (h is Button and String((h as Button).text).contains(texto)):
			return h as Control
		var r := _buscar(h, texto)
		if r != null:
			return r
	return null

## Con esperas de reloj y no de fotogramas: las listas entran con un fundido
## (`modulate.a` de 0 a 1) y sin GPU un fotograma dura lo que quiera.
func _esperar(seg: float) -> void:
	await get_tree().create_timer(seg).timeout

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		_recorrer()

func _recorrer() -> void:
	var mundo: Mundo = _pantalla.get("mundo")
	_pantalla.call("_ir_a_pestana", "Finanzas")
	_pantalla.call("_refrescar")
	await _esperar(0.6)
	_desplazar_a(_pantalla.get("_lista_finanzas"), "BALANCE")
	await _esperar(1.2)
	_guardar("finanzas")
	_desplazar_a(_pantalla.get("_lista_finanzas"), "FLUJO DE CAJA")
	await _esperar(0.8)
	_guardar("finanzas_flujo")
	_desplazar_a(_pantalla.get("_lista_finanzas"), "CAMPAÑAS")
	await _esperar(0.8)
	_guardar("finanzas_banco")
	## La mesa de negociación con el primer objetivo que acepte sentarse.
	var mio := mundo.mi_club()
	for c: Club in mundo.clubes.values():
		if c == mio or c.plantilla.is_empty():
			continue
		var j: Jugador = c.plantilla[0]
		if mundo.mercado.abrir_negociacion(j) == "":
			break
	_pantalla.call("_ir_a_pestana", "Mercado")
	if mundo.mercado.negociacion != null:
		_pantalla.call("_enviar_oferta_negociacion")
	_pantalla.call("_refrescar")
	await _esperar(1.5)
	_guardar("mercado")
	_desplazar_a(_pantalla.get("_panel_mercado"), "FILTRAR")
	await _esperar(0.8)
	_guardar("mercado_lista")
	var e := {"tipo": "mejora", "agente": "R. Maldonado", "perfil": "tiburon", "pid": "j9",
		"txt": "Quiere mejorar el contrato de su cliente."}
	var mesa := MesaAgente.new(e, 0, 0.0, 4242)
	mesa.regatear(mesa.ofertas()[2])
	_pantalla.add_child(MesaAgenteUI.new(mesa, func(_m: MesaAgente) -> void: pass))
	await _esperar(1.5)
	_guardar("mesa")
	get_tree().quit(0)
