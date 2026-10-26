class_name EstilosMenu
extends RefCounted
## LOS ESTILOS DEL MENÚ CENTRAL (fase 0, paso 3; sale de `Principal`, capas 1, 3, 13 y 14).
##
## Una sola responsabilidad: cómo se VISTE el menú. Los tres estilos
## (píldora, compacto, barra), la píldora con la que se pinta cada chip y
## pestaña, y la rotación de estética cada diez minutos de juego.
## `p` es la pantalla principal: pone la paleta, el fondo y el repintado;
## aquí solo se decide el vestido. `RefCounted`: el reloj se cuelga de `p`.

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

## LOS ESTILOS DE MENÚ (10-9-2026). El usuario los pidió "compatibles y
## modulares": el mismo menú, la misma navegación y los mismos chips, con
## tres vestidos distintos. Como TODO el menú pasa por `pildora()`, cambiar
## de estilo es cambiar una constante y repintar -no hay tres menús, hay uno
## con tres pieles-.
const ESTILOS_MENU := [
	["pildora", "Píldoras redondeadas"],
	["compacto", "Compacto (más aire)"],
	["barra", "Barra clásica (recta)"],
]
var estilo: String = "pildora"

## EL MENÚ CENTRAL CAMBIA DE ESTÉTICA CADA 10 MINUTOS (29-9-2026, mapa de
## metas 24). Pedido: que de forma nativa vaya rotando entre sus diseños. Cada
## diseño junta lo que ya se elegía por separado en Ajustes → Interfaz:
## [paleta, estilo del menú, forma de las tarjetas, fondo]. Cuenta tiempo de
## juego (el temporizador se para si el juego se pausa) y se puede apagar.
const DISENOS_CENTRAL := [
	["bosque", "pildora", "redonda", "nocturna"],
	["esports", "barra", "recta", "neon"],
	["ejecutivo", "pildora", "suave", "trofeo"],
	["marino", "compacto", "marcada", "tunel"],
	["transmision", "barra", "redonda", "tifo"],
	["vino", "pildora", "suave", "vestuario"],
	["cibernetico", "compacto", "recta", "ciudad"],
	["tierra", "pildora", "redonda", "amanecer"],
]
const ROTAR_CADA := 600.0
var rotar := true
var _diseno_i := 0
var _reloj_diseno: Timer

func pildora(texto: String, tam: int = 12, alto: int = 32) -> Button:
	var b := Button.new()
	b.text = texto
	b.toggle_mode = true
	if estilo == "compacto":
		tam = maxi(10, tam - 1)
		alto = maxi(22, alto - 4)
	b.add_theme_font_size_override("font_size", tam)
	b.custom_minimum_size = Vector2(float(texto.length()) * (float(tam) * 0.62) + 30.0, alto)
	## "barra" = esquinas rectas y una línea de acento debajo del activo, que
	## es como se veían las pestañas antes de que todo fuera cápsulas.
	var radio := 3 if estilo == "barra" else int(alto / 2)
	var reposo := StyleBoxFlat.new()
	reposo.bg_color = p._mezcla(p._color_de_paleta(Principal.COL_PANEL), p._color_de_paleta(Principal.COL_TEXTO), 0.07)
	reposo.border_color = p._color_de_paleta(Principal.COL_BORDE)
	reposo.set_border_width_all(1)
	reposo.set_corner_radius_all(radio)
	reposo.content_margin_left = 14
	reposo.content_margin_right = 14
	var encima := reposo.duplicate() as StyleBoxFlat
	encima.bg_color = p._mezcla(p._color_de_paleta(Principal.COL_PANEL), p._color_de_paleta(Principal.COL_TEXTO), 0.18)
	var activa := StyleBoxFlat.new()
	activa.bg_color = p._color_de_paleta(Principal.COL_TEXTO)
	activa.set_corner_radius_all(radio)
	activa.content_margin_left = 14
	activa.content_margin_right = 14
	b.add_theme_stylebox_override("normal", reposo)
	b.add_theme_stylebox_override("hover", encima)
	b.add_theme_stylebox_override("focus", encima)
	b.add_theme_stylebox_override("pressed", activa)
	b.add_theme_color_override("font_color", p._color_de_paleta(Principal.COL_TEXTO))
	b.add_theme_color_override("font_hover_color", p._color_de_paleta(Principal.COL_TEXTO))
	## La píldora activa lleva letra OSCURA sobre fondo claro: es el mismo
	## truco del HTML y lo que hace que no haga falta ningún subrayado.
	b.add_theme_color_override("font_pressed_color", p._color_de_paleta(Principal.COL_FONDO))
	b.add_theme_color_override("font_hover_pressed_color", p._color_de_paleta(Principal.COL_FONDO))
	return b

## El reloj de la rotación: cuenta tiempo de JUEGO (se para con la pausa) y
## se cuelga de la pantalla principal para morir con ella.
func montar_reloj() -> void:
	_reloj_diseno = Timer.new()
	_reloj_diseno.wait_time = ROTAR_CADA
	_reloj_diseno.autostart = true
	_reloj_diseno.timeout.connect(siguiente_diseno)
	p.add_child(_reloj_diseno)

func siguiente_diseno() -> void:
	if not rotar:
		return
	_diseno_i = (_diseno_i + 1) % DISENOS_CENTRAL.size()
	var d: Array = DISENOS_CENTRAL[_diseno_i]
	## Un fundido corto para que el cambio se lea como una transición y no
	## como un parpadeo.
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(velo)
	var tw := p.create_tween()
	tw.tween_property(velo, "color:a", 0.55, 0.35)
	tw.tween_callback(func() -> void:
		p._paleta = String(d[0])
		estilo = String(d[1])
		p._forma_tarjeta = String(d[2])
		p._fondo_elegido = String(d[3])
		p._aplicar_aspecto()
		p._aplicar_fondo()
		p._reconstruir_grupos()
		if p.mundo != null:
			p._refrescar())
	tw.tween_property(velo, "color:a", 0.0, 0.45)
	tw.tween_callback(velo.queue_free)
