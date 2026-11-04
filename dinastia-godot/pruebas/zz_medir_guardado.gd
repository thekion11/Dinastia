extends Node
## CUÁNTO TARDA GUARDAR (3-11-2026, autoguardado siempre activo): mundo con N países, partes del guardado por separado (instantánea, JSON, empaquetado, disco).
##   PAISES=CHI,ARG,ESP,ENG (por defecto; PAISES=TODOS el mundo entero) · SEMANAS=n (semanas jugadas antes de medir; por defecto 10)
func _ready() -> void:
	await get_tree().process_frame
	var texto := OS.get_environment("PAISES") if OS.get_environment("PAISES") != "" else "CHI,ARG,ESP,ENG"
	var paises: Array[String] = []
	if texto != "TODOS":   ## PAISES=TODOS: el mundo entero (todas las ligas), como en la partida
		for x in texto.split(",", false):
			paises.append(String(x))
	var m := Mundo.new()
	var t0 := Time.get_ticks_msec()
	m.generar(paises, 4242)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	print("GUARDADO generar %s: %d ms (%d clubes)" % [texto, Time.get_ticks_msec() - t0, m.clubes.size()])
	for i in int(OS.get_environment("SEMANAS")) if OS.get_environment("SEMANAS") != "" else 10:
		m.avanzar_semana()
	for rep in 3:
		var a := Time.get_ticks_usec()
		var datos := Partida.instantanea(m)
		var b := Time.get_ticks_usec()
		var crudo := JSON.stringify(datos).to_utf8_buffer()
		var c := Time.get_ticks_usec()
		var paquete := PartidaArchivo.empaquetar(crudo)
		var d := Time.get_ticks_usec()
		var ok := PartidaArchivo.escribir("user://zz_medir.dinastia", crudo)
		var e := Time.get_ticks_usec()
		print("GUARDADO #%d instantánea %5.0f ms · JSON %5.0f ms (%.1f MB) · empaquetar %5.0f ms (%.1f MB) · escribir completo %5.0f ms · ok=%s · TOTAL en hilo principal hoy %5.0f ms" % [
			rep, (b - a) / 1000.0, (c - b) / 1000.0, crudo.size() / 1048576.0, (d - c) / 1000.0, paquete.size() / 1048576.0, (e - d) / 1000.0, str(ok), (e - a) / 1000.0])
	## En segundo plano (el autoguardado de verdad): lo que bloquea el hilo principal y lo que tarda en total.
	for rep in 3:
		GuardadoSegundoPlano.iniciar(m, "zz_medir")
		var t_ini := Time.get_ticks_msec()
		var fotogramas := 0
		while GuardadoSegundoPlano.en_curso():
			await get_tree().process_frame
			fotogramas += 1
		print("GUARDADO en segundo plano #%d: hilo principal %d ms (instantánea + copia) · total %d ms · %d fotogramas libres mientras escribía · ok=%s" % [
			rep, GuardadoSegundoPlano.ms_principal, GuardadoSegundoPlano.ms_total, fotogramas, str(GuardadoSegundoPlano.ultimo_ok)])
	for suf in PartidaArchivo.sufijos():
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://zz_medir.dinastia" + suf))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://zz_medir.dinastia"))
	Partida.borrar("zz_medir")
	get_tree().quit()
