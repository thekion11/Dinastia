extends BaseIdea
## R5 (3-11): la caché en disco del audio sintetizado. Un sonido y una pieza de música se sintetizan UNA vez, se guardan, y el segundo «arranque» los LEE
## idénticos y mucho más rápido; un archivo roto no tumba nada (se vuelve a sintetizar); y la caché se puede apagar.

const CARPETA := "user://cache_audio_prueba"

func _borrar() -> void:
	var d := DirAccess.open(CARPETA)
	if d != null:
		for f in d.get_files():
			d.remove(f)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CARPETA))

func _ready() -> void:
	await get_tree().process_frame
	_titulo("R5 · CACHÉ EN DISCO DEL AUDIO SINTETIZADO")
	_borrar()
	CacheAudio.carpeta_prueba = CARPETA
	_comprobar(CacheAudio.activa(), "la caché está activa (carpeta de prueba)")
	var nombre := "gol_campana"   ## el sonido que más tarda (~1,6 s)
	var t0 := Time.get_ticks_usec()
	var a: Array = Sonido._sintetizar_banco(nombre)
	var t_sintesis := (Time.get_ticks_usec() - t0) / 1000.0
	_comprobar(FileAccess.file_exists(CARPETA + "/s_" + nombre + ".bin"), "tras sintetizar, el banco queda guardado en disco")
	t0 = Time.get_ticks_usec()
	var b: Array = Sonido._sintetizar_banco(nombre)
	var t_cache := (Time.get_ticks_usec() - t0) / 1000.0
	_comprobar(a.size() == b.size() and a.size() > 0, "el banco leído tiene las mismas variantes (%d)" % b.size())
	var igual := true
	for i in a.size():
		var x := a[i] as AudioStreamWAV
		var y := b[i] as AudioStreamWAV
		igual = igual and x.data == y.data and x.format == y.format and x.mix_rate == y.mix_rate and x.stereo == y.stereo and x.loop_mode == y.loop_mode \
			and x.loop_begin == y.loop_begin and x.loop_end == y.loop_end
	_comprobar(igual, "idéntico byte a byte al sintetizado")
	print("  síntesis %.0f ms · leído de la caché %.0f ms (×%.0f más rápido)" % [t_sintesis, t_cache, t_sintesis / maxf(t_cache, 0.01)])
	_comprobar(t_cache * 5.0 < t_sintesis, "leer es al menos 5 veces más rápido que sintetizar")
	## Música: una pieza.
	var clave := String(Musica.PIEZAS.keys()[0])
	var m1 := Musica._componer(clave)
	var m2 := Musica._componer(clave)
	_comprobar(m1.data == m2.data and FileAccess.file_exists(CARPETA + "/m_" + clave + ".bin"), "la música también: se guarda y se lee igual (%s)" % clave)
	## Un archivo roto no tumba nada.
	var f := FileAccess.open(CARPETA + "/s_" + nombre + ".bin", FileAccess.WRITE)
	f.store_string("esto no es un banco")
	f.close()
	var c: Array = Sonido._sintetizar_banco(nombre)
	_comprobar(c.size() == a.size() and (c[0] as AudioStreamWAV).data == (a[0] as AudioStreamWAV).data, "con el archivo roto se vuelve a sintetizar, igual que antes")
	## Apagable.
	OS.set_environment("DINASTIA_SIN_CACHE_AUDIO", "1")
	_comprobar(not CacheAudio.activa(), "DINASTIA_SIN_CACHE_AUDIO=1 la apaga")
	OS.unset_environment("DINASTIA_SIN_CACHE_AUDIO")
	CacheAudio.carpeta_prueba = ""
	_borrar()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
