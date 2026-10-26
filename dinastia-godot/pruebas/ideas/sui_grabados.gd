extends BaseIdea
## Los clics de interfaz grabados (Kenney, CC0) se cargan del .ogg y lo demás sigue sintetizado.

const GRABADOS := ["menu_mover", "clic_suave", "menu_aceptar", "clic", "menu_atras", "menu_seccion", "silbato",
	"pitido_final", "medio_tiempo", "tambor", "tambor_visitante"]

func _probar() -> void:
	_titulo("SONIDO: grabaciones de interfaz en audio/ui (sui)")
	for n: String in GRABADOS:
		var b: Array = Sonido.banco(n)
		var ok := b.size() == 1 and b[0] is AudioStreamOggVorbis \
			and (b[0] as AudioStream).resource_path == Sonido.ruta_grabado(n)
		_comprobar(ok, "«%s» suena con su .ogg (%s)" % [n, Sonido.ruta_grabado(n)])
		var f: Dictionary = Sonido.ficha(n)
		_comprobar(bool(f.get("grabado", false)) and int(f.get("pico", 0)) > 300 and float(f.get("segundos", 0.0)) > 0.0,
			"la ficha de «%s» mide onda de verdad: pico %d, %.3f s" % [n, int(f.get("pico", 0)), float(f.get("segundos", 0.0))])
		## Comparación con la receta sintetizada que sustituye: el ajuste debe dejar la
		## grabación en el mismo orden de volumen (±6 dB), nunca por encima de golpe.
		var w: AudioStreamWAV = Sonido._sintetizar(n, 0.0)
		var ps := 1
		for i in range(0, w.data.size() - 1, 2):
			ps = maxi(ps, absi(w.data.decode_s16(i)))
		var efectivo := 20.0 * log(float(f.get("pico", 1)) / float(ps)) / log(10.0) + float(Sonido.AJUSTE_DB.get(n, 0.0))
		print("  %-13s pico %5d (síntesis %5d)  %.3f s  ajuste %.1f dB -> %+.1f dB sobre la síntesis" % [n, int(f.get("pico", 0)), ps, float(f.get("segundos", 0.0)), float(Sonido.AJUSTE_DB.get(n, 0.0)), efectivo])
		_comprobar(absf(efectivo) <= 6.0, "«%s» queda a %+.1f dB de la síntesis que reemplaza (máx ±6)" % [n, efectivo])
	for n: String in ["menu_cambio", "gol", "abrir"]:
		var b: Array = Sonido.banco(n)
		_comprobar(not ResourceLoader.exists(Sonido.ruta_grabado(n)) and b.size() == Sonido.VARIANTES and b[0] is AudioStreamWAV,
			"«%s» no tiene archivo y sigue sintetizándose (%d variantes)" % [n, b.size()])
		print("  %-13s (síntesis) pico %5d" % [n, int(Sonido.ficha(n).get("pico", 0))])
	_comprobar(Sonido.banco("no_existe_xyz").is_empty(), "un nombre fuera del catálogo y sin archivo da banco vacío")
