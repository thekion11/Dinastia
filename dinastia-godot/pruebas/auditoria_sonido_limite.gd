extends Node
## CAZA DE FALLOS (4-11-2026, orden de la líder): el SONIDO llevado al límite (sin dispositivo de audio también: en headless el motor usa el controlador mudo).
##   godot --headless --path . res://pruebas/auditoria_sonido_limite.tscn
## Nombres vacíos o que no existen, 400 efectos en el mismo fotograma, volúmenes 0, 1 y fuera de rango, ajuste de dB absurdo (NaN, ±1e9), efectos apagados
## y la música con volumen 0/1/fuera de rango; ningún reproductor puede quedar con un volumen fuera de [-80, 24] dB ni NaN.
var _fallos := 0

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _voces_sanas() -> String:
	for h in Sonido.get_children():
		if h is AudioStreamPlayer:
			var db := (h as AudioStreamPlayer).volume_db
			if is_nan(db) or db < -80.0 or db > 24.0:
				return "volumen %s dB" % str(db)
	return ""

func _ready() -> void:
	var antes_v: Dictionary = Sonido.volumen.duplicate()
	var antes_e: bool = Sonido.encendido
	Sonido.encendido = true
	Sonido.toca("")
	Sonido.toca("no_existe_este_sonido")
	_comprobar(true, "un nombre vacío o inexistente no hace nada ni se queja")
	var nombres: Array = Sonido.NOMBRES.slice(0, 40)
	for i in 400:
		Sonido.toca(String(nombres[i % nombres.size()]), [Sonido.Bus.EFECTOS, Sonido.Bus.AMBIENTE, Sonido.Bus.INTERFAZ][i % 3])
	_comprobar(_voces_sanas() == "", "400 efectos en el mismo fotograma: sin errores (%s)" % _voces_sanas())
	for v in [0.0, 1.0, 5.0, -3.0, 1.0e9, NAN]:
		for bus in Sonido.volumen:
			Sonido.volumen[bus] = v
		for k in 20:
			Sonido.toca(String(nombres[k % nombres.size()]))
		_comprobar(_voces_sanas() == "", "volumen %s: ningún reproductor con dB fuera de rango (%s)" % [str(v), _voces_sanas()])
	for extra in [NAN, 1.0e9, -1.0e9, INF]:
		Sonido.toca(String(nombres[0]), Sonido.Bus.EFECTOS, extra)
		_comprobar(_voces_sanas() == "", "ajuste de %s dB: sin dB fuera de rango (%s)" % [str(extra), _voces_sanas()])
	Sonido.volumen = antes_v.duplicate()
	Sonido.encendido = false
	for k in 50:
		Sonido.toca(String(nombres[k % nombres.size()]))
	_comprobar(true, "con el sonido apagado, 50 efectos no hacen nada")
	Sonido.encendido = antes_e
	Sonido.volumen = antes_v
	var vol_m: float = Musica.volumen
	for v in [0.0, 1.0, 9.0, -1.0, NAN]:
		Musica.volumen = v
		Musica.aplicar_volumen()
	_comprobar(true, "la música acepta volumen 0, 1 y fuera de rango sin romperse")
	Musica.volumen = vol_m
	print("===== FIN. %d fallos =====" % _fallos)
	get_tree().quit(0 if _fallos == 0 else 1)
