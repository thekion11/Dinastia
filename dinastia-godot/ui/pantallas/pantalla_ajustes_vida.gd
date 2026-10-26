class_name AjustesVida
extends RefCounted
## AJUSTES → JUEGO → «VIDA PRIVADA» (26-10-2026, propuesta s4 fila 5). Elige
## cuánto pesan el hambre y el sueño del DT (`Necesidades.modo`). Va en la partida,
## no en las preferencias: cada carrera decide la suya. Sin partida no se pinta.

const ETIQUETAS := {"completa": "Completa", "ligera": "Ligera", "apagada": "Apagada"}
const EXPLICA := {
	"completa": "Comer y dormir cuentan: si fallan, aumentan las posibilidades de que las cosas salgan mal.",
	"ligera": "Hambre y sueño se ven y avisan, pero nunca castigan.",
	"apagada": "El PC come y duerme por ti: solo fútbol y club.",
}

static func pintar(p: Principal) -> void:
	if p.mundo == null or p.mundo.necesidades == null:
		return
	var n: Necesidades = p.mundo.necesidades
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("VIDA PRIVADA")
	p._lista_ajustes.add_child(t)
	var fila := HBoxContainer.new()
	fila.name = "FilaVida"
	fila.add_theme_constant_override("separation", 4)
	p._lista_ajustes.add_child(fila)
	for m: String in Necesidades.MODOS:
		var modo := m
		var b := Button.new()
		b.name = "Vida_" + modo
		b.text = Idiomas.t(String(ETIQUETAS[modo]))
		b.add_theme_font_size_override("font_size", 11)
		b.toggle_mode = true
		b.button_pressed = n.modo == modo
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			n.poner_modo(modo)
			p._refrescar())
		fila.add_child(b)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = Idiomas.t(String(EXPLICA.get(n.modo, EXPLICA["completa"])))
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_ajustes.add_child(ex)
	p._lista_ajustes.add_child(HSeparator.new())
