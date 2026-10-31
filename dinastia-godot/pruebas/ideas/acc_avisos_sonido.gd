extends BaseIdea
## M-283 (28-10-2026): los sonidos con significado salen escritos abajo de la pantalla (Ajustes → Accesibilidad).
##   herramientas/ideas.sh acc_avisos_sonido

func _probar() -> void:
	_titulo("M-283: AVISOS VISUALES DE SONIDO")
	var antes := Sonido.encendido
	AvisosSonido._activo = 0
	Sonido.toca("silbato")
	_comprobar(Sonido._avisos == null or Sonido._avisos._caja.get_child_count() == 0, "apagado: no sale nada")
	AvisosSonido._activo = 1
	Sonido.encendido = false
	Sonido.toca("silbato")
	Sonido.toca("silbato")
	Sonido.toca("gol")
	Sonido.toca("clic")
	var caja: VBoxContainer = Sonido._avisos._caja if Sonido._avisos != null else null
	var textos: Array[String] = []
	if caja != null:
		for h in caja.get_children():
			textos.append((h as Label).text)
	_comprobar(textos == ["🔊 Silbato", "🔊 ¡Gol! La grada estalla"], "encendido y con el sonido apagado: silbato (una vez) y gol, el clic no (%s)" % str(textos))
	for k in AvisosSonido.TEXTOS:
		Sonido.toca(String(k))
	_comprobar(caja != null and caja.get_child_count() == AvisosSonido.MAX, "no se apilan más de %d" % AvisosSonido.MAX)
	for h in caja.get_children():
		h.set_meta("hasta", 0)
	Sonido._avisos._process(0.0)
	_comprobar(caja.get_child_count() == 0, "pasado su tiempo, se van")
	Idiomas.idioma = "en"
	_comprobar(AvisosSonido.texto("roja") == "🔊 Red card", "traducido (en: %s)" % AvisosSonido.texto("roja"))
	Idiomas.idioma = "es"
	AvisosSonido._activo = -1
	Sonido.encendido = antes
