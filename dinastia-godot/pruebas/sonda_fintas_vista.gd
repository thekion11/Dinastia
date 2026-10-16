extends Node
## SONDA DE FINTAS EN EL PARTIDO MONTADO POR VistaEstadio (16-10-2026). La sonda
## del motor (`sonda_motor_dt`) mide las fintas de la IA con el motor suelto;
## esta abre el partido de verdad (VistaEstadio + `_montar_motor`) y lo juega
## entero llamando a `_paso_motor` como el reloj del juego, para comparar.
##   godot --headless --path . res://pruebas/sonda_fintas_vista.tscn
##   N=partidos (2), SEMILLA0=mundo (4711)
var _fallos := 0

func _pref_ceremonia(v: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", v)
	cfg.save(CajonAjustes.RUTA)

func _ready() -> void:
	_pref_ceremonia(false)
	var n := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 2
	var s0 := int(OS.get_environment("SEMILLA0")) if OS.get_environment("SEMILLA0") != "" else 4711
	var fintas := 0
	var ok := 0
	var minutos := 0.0
	for i in n:
		var r := await _jugar(s0 + i)
		fintas += int(r[0])
		ok += int(r[1])
		minutos += float(r[2])
	print("FINTAS VISTA %.1f por 90' (%.0f %% engañan) en %.0f minutos" % [
		float(fintas) / maxf(minutos, 1.0) * 90.0, 100.0 * float(ok) / maxf(float(fintas), 1.0), minutos])
	_pref_ceremonia(true)
	print("===== FIN SONDA FINTAS VISTA =====")
	get_tree().quit(0)

func _jugar(semilla: int) -> Array:
	var mundo := Mundo.new()
	mundo.generar(["CHI"], semilla)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var par := mundo.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	var vista := VistaEstadio.new()
	add_child(vista)
	vista.abrir(par[0], 0.85, par[1], partido)
	vista.parar_en_descanso = false
	await get_tree().process_frame
	var mot: MotorJugable = vista.get("_motor")
	if mot == null:
		print("  sin motor")
		return [0, 0, 0.0]
	if OS.get_environment("MITAD") != "":
		mot.duracion_mitad = float(OS.get_environment("MITAD"))
		mot.sortear_anadido()
	if OS.get_environment("SIN_CANSANCIO") != "":
		mot.cansancio_real = false
	if OS.get_environment("MODO") == "reloj":
		## Como `prueba_regates`: el reloj del juego mueve el motor (x3 y x2).
		vista.get("_juego").vel_idx = 3
		Engine.time_scale = 3.0
		var fr := 0
		while mot.estado != "fin" and fr < 60000:
			await get_tree().process_frame
			fr += 1
		Engine.time_scale = 1.0
	else:
		vista.set_process(false)
		var dt := 1.0 / 60.0
		var pasos := 0
		while mot.estado != "fin" and pasos < 60 * 60 * 30:
			vista._paso_motor(dt)
			pasos += 1
	var jugado := (float(mot.mitad - 1) * mot.duracion_mitad + mot.t) / mot.duracion_mitad * 45.0
	print("  semilla %d: %d fintas (%d engañan), minuto %d, %.0f s de motor por mitad" % [semilla, mot.regates_ia, mot.regates_ia_ok, mot.minuto(), mot.duracion_mitad])
	var r := [mot.regates_ia, mot.regates_ia_ok, jugado]
	vista.queue_free()
	await get_tree().process_frame
	return r
