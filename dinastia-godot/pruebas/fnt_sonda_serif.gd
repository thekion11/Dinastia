extends SceneTree
func _init() -> void:
	var s := Fuentes.serif(Fuentes.SERIF_ROTULO, "Cinzel", 700)
	print("ROT creada")
	var g := Fuentes.serif(["Georgia", "Cambria", "Charter", "Bitstream Charter"], "Gelasio", 400, true)
	print("GEO nombre='", g.get_font_name(), "'")
	var c := Fuentes.propia("Cinzel"); var ge := Fuentes.propia("Gelasio")
	var t := "ąćęłńóśźżĄĆĘŁŃÓŚŹŻğĞıİşŞçÇöÖüÜàèíòúïñÑ¿¡ºª€"
	var fc := ""; var fg := ""
	for ch in t:
		if not c.has_char(ch.unicode_at(0)): fc += ch
		if not ge.has_char(ch.unicode_at(0)): fg += ch
	print("FALTA cinzel '", fc, "' gelasio '", fg, "'")
	quit()
