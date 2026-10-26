extends BaseIdea
## EL ORDEN DE `Idiomas._t` CON LAS FRASES ARMADAS (agente trad, 26-10-2026). Dos fallos que dejaban media
## frase en castellano:
##  1. El punto final se quitaba ANTES de partir por « · », así que el último tramo («…no se muerde la
##     lengua.») se buscaba sin su punto y no estaba en la tabla.
##  2. Una frase con « · » que encaja ENTERA en un patrón («🎙 Rueda de prensa · habla X») se partía en
##     tramos antes de probar el patrón y salía a medias.
## Y lo que ya funcionaba tiene que seguir igual (puntos e iconos alrededor de una clave, nombres propios).
func _probar() -> void:
	_titulo("TRAD · orden de Idiomas._t con frases armadas")
	Idiomas.idioma = "en"
	Idiomas._cache.clear()
	var desc := "Lleva más tiempo que el edificio y no se muerde la lengua."
	var armada := "33 años  ·  25 en el club  ·  gruñón  ·  " + desc
	var esperada := Idiomas.t("%d años  ·  %d en el club  ·  %s  ·  %s") % [33, 25, Idiomas.t("gruñón"), Idiomas.t(desc)]
	_comprobar(Idiomas.t(desc) != desc and Idiomas.t(armada) == esperada,
		"el último tramo conserva su punto y se traduce («%s»)" % Idiomas.t(armada))
	var rueda := "🎙 Rueda de prensa · habla Juan Pérez"
	var patron := Idiomas._patron(rueda, 0)
	_comprobar(patron != "" and Idiomas.t(rueda) == patron, "la frase con « · » que encaja entera en un patrón gana al partirla («%s»)" % Idiomas.t(rueda))
	## Lo de siempre, igual.
	var clave := "Mira las finanzas"
	var tc := Idiomas.t(clave)
	_comprobar(tc != clave and Idiomas.t(clave + ".") == tc + ".", "una clave sin punto sigue sirviendo con punto final («%s»)" % Idiomas.t(clave + "."))
	_comprobar(Idiomas.t("🎯 " + clave + " ▸") == "🎯 " + tc + " ▸", "y con icono delante y flecha detrás")
	var nombres := "Fernando de Peol  ·  POR  ·  media 73"
	_comprobar(Idiomas.t(nombres) == "Fernando de Peol  ·  POR  ·  " + Idiomas.t("media 73"), "los nombres propios de un tramo no se tocan («%s»)" % Idiomas.t(nombres))
	_comprobar(Idiomas.t("Primera División  ·  jornada 12 de 30") == Idiomas.t("Primera División") + "  ·  " + Idiomas.t("jornada 12 de 30"),
		"tramos normales, igual")
	## Coste: frases únicas (sin caché), armadas como las de la interfaz.
	var ini := Time.get_ticks_usec()
	for i in 3000:
		Idiomas.t("%d años  ·  %d en el club  ·  gruñón  ·  %s" % [20 + i % 50, i, desc])
		Idiomas.t("Jugador %d  ·  POR  ·  media %d" % [i, 50 + i % 40])
	var us := float(Time.get_ticks_usec() - ini) / 6000.0
	print("  coste medio de Idiomas.t sin caché: %.1f µs por frase" % us)
	_comprobar(us < 2000.0, "coste razonable (%.1f µs por frase sin caché)" % us)
	Idiomas.idioma = "es"
