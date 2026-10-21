extends Node
## PRÁCTICA LIBRE (21-10-2026, M-130): se abre desde la sala de minijuegos, tomas
## el mando al momento, el rival no se mueve de su sitio, el reloj no acaba y un
## balón del rival vuelve a tus pies.
##   godot --headless --path . res://pruebas/prueba_practica.tscn
var _p: Node
var _v: VistaEstadio
var _n := 0
var _fallos := 0
var _antes := {}

func _ok(c: bool, t: String) -> void:
	print(("  ok    " if c else "  FALLO ") + t)
	if not c:
		_fallos += 1

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 5:
		var sala := SalaMinijuegos.abrir(_p, _p.get("mundo"))
		sala.call("_abrir_practica", _p, _p.get("mundo"))
		for h in _p.get_children():
			if h is VistaEstadio:
				_v = h
		_ok(_v != null and _v.practica, "la sala abre la práctica libre")
		_ok(not sala.visible, "la sala se esconde detrás")
		if _v == null:
			print("===== FIN PRÁCTICA. sin vista =====")
			get_tree().quit()
	if _v == null:
		return
	var m: MotorJugable = _v.get("_motor")
	if _n == 12:
		_ok(m != null and m.practica, "el motor está en práctica")
		_ok(m.control_equipo >= 0, "tomas el mando de tu equipo al empezar")
		for p: Dictionary in m.jugadores:
			if (0 if bool(p["es_local"]) else 1) != m.control_equipo and not bool(p["por"]):
				_antes[String(p["id"])] = m.pos(p)
	if _n > 12 and _n < 400:
		for k in 3:
			m.paso(1.0 / 60.0)
	if _n == 200:
		## Le regalo el balón a un rival: tiene que volver a mis pies.
		for p: Dictionary in m.jugadores:
			if (0 if bool(p["es_local"]) else 1) != m.control_equipo and not bool(p["por"]):
				m.poseedor = p
				break
	if _n == 202:
		_ok(m.poseedor.is_empty() or (0 if bool(m.poseedor["es_local"]) else 1) == m.control_equipo, "un balón del rival vuelve a tu equipo")
	if _n == 400:
		var lejos := 0.0
		for p: Dictionary in m.jugadores:
			if _antes.has(String(p["id"])):
				lejos = maxf(lejos, m.pos(p).distance_to(_antes[String(p["id"])]))
		_ok(lejos < 6.0, "el rival se queda en su sitio (lo que más se movió: %.1f m)" % lejos)
		_ok(m.estado != "fin" and m.mitad == 1, "el reloj no acaba la parte")
		print("===== FIN PRÁCTICA. %d fallos =====" % _fallos)
		get_tree().quit()
