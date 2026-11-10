extends Node
## COLISIONES DEL CLUB A PIE (23-10-2026, pedido: «hay barreras invisibles
## ilógicas, paredes que se atraviesan y también a las personas»).
## Comprueba con el explorador REAL (`ExploradorEstadio.paso`):
##  1. paredes: caminar contra ellas nunca deja al cuerpo fuera de las zonas;
##  2. muebles: pasos al azar nunca terminan dentro de algo con colisión;
##  3. gente: caminar de frente contra una persona del personal no la atraviesa;
##  4. barreras invisibles: desde el punto de salida de cada planta se puede
##     llegar (con el cuerpo entero) al centro de cada sala, del campo y de la calle.
##
##   godot --headless --path . res://pruebas/prueba_colisiones_club.tscn
## Termina con «FIN. 0 fallos» y código de salida 0.

var _vista: VistaEstadio
var _ex: ExploradorEstadio
var _n := 0
var _fallos := 0

func _ok(cond: bool, texto: String) -> void:
	if cond:
		print("  ok   ", texto)
	else:
		_fallos += 1
		print("  FALLO ", texto)

func _ready() -> void:
	var m := Mundo.new()
	m.generar([OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "CHI"], 77)   ## PAIS=ESP CLUB=3: otro país y club (regla 34)
	var club: Club = m.ligas[0].clubes[int(OS.get_environment("CLUB")) % m.ligas[0].clubes.size()]
	## El personal solo existe en el estadio del club propio.
	PersonajeDT.club_usuario = club.id
	var ep := EstadioPropio.new()
	var perfil := ep.perfil(club)
	perfil["forma"] = "cuenco"
	perfil["tunel"] = "central"
	perfil["niveles"] = 2
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(club, 0.85, null, null, perfil)

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		_vista.recorrer()
		_ex = _vista._explorador
	if _n == 30:
		_correr()
		print("===== FIN. %d fallos" % _fallos)
		get_tree().quit(1 if _fallos > 0 else 0)

func _y(p: int) -> float:
	return RecorridoClub.y_de(p)

func _poner(x: float, z: float, planta: int, rumbo: float) -> void:
	_ex.planta = planta
	_ex.cuerpo.position = Vector3(x, _y(planta), z)
	_ex.rumbo = rumbo
	_ex.vel = 0.0

func _correr() -> void:
	var zonas: Array = _ex.zonas
	var pe := _ex._personal()
	print("[1] paredes: contra el muro del vestuario")
	var d: Dictionary = _ex._datos
	var x0: float = d["x0"]
	var z_out: float = d["z_out"]
	## En el vestuario, mirando a +X (rumbo PI/2) contra la pared lateral.
	_poner(x0, z_out + 6.0, 0, PI / 2.0)
	var peor := 0
	for i in 240:
		_ex.paso(Vector2(0, 1), true, 1.0 / 30.0)
		if not ColisionClub.cabe(zonas, _ex.cuerpo.position, 0):
			peor += 1
	_ok(peor == 0, "el cuerpo nunca sale de las zonas contra la pared (%d pasos fuera)" % peor)

	print("[2] muebles: caminatas al azar")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var dentro := 0
	var bloqueos := 0
	var pasos := 0
	var plantas: Array = []
	for z: Dictionary in zonas:
		if not (int(z.get("planta", 0)) in plantas):
			plantas.append(int(z.get("planta", 0)))
	for rep in 120:
		var pl: int = plantas[rng.randi() % plantas.size()]
		var cand: Array = []
		for z: Dictionary in zonas:
			if int(z.get("planta", 0)) == pl and String(z["nombre"]) != "Campo":
				cand.append(z)
		var zz: Dictionary = cand[rng.randi() % cand.size()]
		var r: Rect2 = zz["r"]
		var px := r.position.x + rng.randf() * r.size.x
		var pz := r.position.y + rng.randf() * r.size.y
		_poner(px, pz, pl, rng.randf() * TAU)
		if not ColisionClub.cabe(zonas, _ex.cuerpo.position, pl) or ColisionClub.toca_mueble(_ex.cuerpo, _ex.cuerpo.position):
			continue
		for i in 90:
			var antes := _ex.cuerpo.position
			_ex.paso(Vector2(rng.randf_range(-0.6, 0.6), 1), i % 2 == 0, 1.0 / 30.0)
			pasos += 1
			if ColisionClub.toca_mueble(_ex.cuerpo, _ex.cuerpo.position):
				dentro += 1
			if (_ex.cuerpo.position - antes).length() < 0.001:
				bloqueos += 1
	_ok(dentro == 0, "ningún paso termina dentro de un mueble (%d de %d)" % [dentro, pasos])
	print("       (pasos en que algo frenó el paso: %d)" % bloqueos)

	print("[3] gente: de frente contra una persona")
	var probadas := 0
	var atravesadas := 0
	if pe != null:
		for g: Dictionary in pe.gente:
			var n: Node3D = g["nodo"]
			if not is_instance_valid(n) or not n.visible or bool(g["quieto"]):
				continue
			var pl := int(g["planta"])
			## 1,5 m al sur de la persona (z menor), mirando a +Z hacia ella.
			var sx := n.position.x
			var sz := n.position.z - 1.5
			_poner(sx, sz, pl, 0.0)
			if not ColisionClub.cabe(zonas, _ex.cuerpo.position, pl):
				continue
			g["quieto"] = true
			probadas += 1
			for i in 90:
				_ex.paso(Vector2(0, 1), false, 1.0 / 30.0)
			var dist := Vector2(n.position.x - _ex.cuerpo.position.x, n.position.z - _ex.cuerpo.position.z).length()
			if dist < ColisionClub.RADIO + ColisionClub.RADIO_GENTE - 0.05 and _ex.cuerpo.position.z > n.position.z - 0.05:
				atravesadas += 1
			g["quieto"] = false
	_ok(probadas > 0, "hay personas con las que probar (%d)" % probadas)
	_ok(atravesadas == 0, "ninguna persona se atraviesa (%d de %d)" % [atravesadas, probadas])

	print("[5] cada sala: empujar contra las paredes en 8 direcciones sin salir del edificio ni entrar en un mueble")
	_por_salas(zonas)

	print("[4] barreras invisibles: alcanzar cada sala con el cuerpo entero")
	for pl in plantas:
		var salida := Vector3.ZERO
		var tiene := false
		if pl == 0:
			salida = _ex._datos["inicio"]  # donde aparece el personaje: siempre libre
			tiene = true
		for z: Dictionary in zonas:
			if tiene:
				break
			if int(z.get("planta", 0)) == pl and String(z["nombre"]) == "Ascensor":
				var r: Rect2 = z["r"]
				salida = Vector3(r.get_center().x, _y(pl), r.get_center().y)
				tiene = true
				break
		if not tiene:
			continue
		_ex.planta = pl
		var alcanzado := _inundar(zonas, salida, pl)
		for z: Dictionary in zonas:
			if int(z.get("planta", 0)) != pl:
				continue
			var nom := String(z["nombre"])
			if nom in ["Ascensor", "Pasillo", "Banda"]:
				continue
			var r: Rect2 = z["r"]
			if minf(r.size.x, r.size.y) < 1.2:
				continue  # puertas y huecos de paso: se prueban por las salas
			var c := r.get_center()
			var hay := false
			for k in alcanzado:
				if absf(k.x - c.x) < 1.6 and absf(k.y - c.y) < 1.6:
					hay = true
					break
			_ok(hay, "planta %d: se llega a «%s»" % [pl, nom])

## Lo que se alcanza andando desde `ini` (rejilla de 0,25 m, cuerpo entero).
func _inundar(zonas: Array, ini: Vector3, planta: int) -> Array:
	var PASO := 0.25
	var visto := {}
	var cola: Array = [Vector2i(roundi(ini.x / PASO), roundi(ini.z / PASO))]
	var lista: Array = []
	visto[cola[0]] = true
	var i := 0
	while i < cola.size() and cola.size() < 200000:
		var c: Vector2i = cola[i]
		i += 1
		var p := Vector3(c.x * PASO, _y(planta), c.y * PASO)
		lista.append(Vector2(p.x, p.z))
		for v in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = c + v
			if visto.has(q):
				continue
			visto[q] = true
			var pq := Vector3(q.x * PASO, _y(planta), q.y * PASO)
			if ColisionClub.cabe(zonas, pq, planta) and not ColisionClub.toca_mueble(_ex.cuerpo, pq):
				cola.append(q)
	return lista

## (10-11, sesión 7) Recorre CADA sala de cada planta: desde el centro de su zona empuja a la carrera en 8 direcciones durante 6 s. En cada paso el cuerpo
## tiene que seguir dentro de la envolvente del edificio (paredes interiores a ±7,98 m de x0, de z_out a z_fin) y fuera de todo mueble/tabique.
func _por_salas(zonas: Array) -> void:
	var d: Dictionary = _ex._datos
	var x0: float = d["x0"]
	var z_out: float = d["z_out"]
	var z_fin: float = d["z_fin"]
	var salas := 0
	var fuera := 0
	var dentro := 0
	var peor := ""
	for f: Array in EdificioClub.todas():
		var pl := int(f[0])
		for s: Array in f[2]:
			var mejor: Dictionary = {}
			for z: Dictionary in zonas:
				if int(z.get("planta", 0)) == pl and String(z["nombre"]) == String(s[0]) and (mejor.is_empty() or (z["r"] as Rect2).get_area() > (mejor["r"] as Rect2).get_area()):
					mejor = z
			if mejor.is_empty():
				continue
			var c: Vector2 = (mejor["r"] as Rect2).get_center()
			salas += 1
			for dir in 8:
				var a := TAU * float(dir) / 8.0
				## Si el centro cae en un mueble (la mesa del comedor), se busca el punto libre más cercano en pasos de 0,25 m.
				var ini := Vector3(c.x, _y(pl), c.y)
				var hallado := false
				for radio in range(0, 13):
					for k in 8:
						var q := ini + Vector3(cos(TAU * float(k) / 8.0), 0.0, sin(TAU * float(k) / 8.0)) * 0.25 * float(radio)
						if ColisionClub.cabe(zonas, q, pl) and not ColisionClub.toca_mueble(_ex.cuerpo, q):
							ini = q
							hallado = true
							break
					if hallado:
						break
				if not hallado:
					continue
				_poner(ini.x, ini.z, pl, a)
				for i in 180:
					_ex.paso(Vector2(0, 1), true, 1.0 / 30.0)
					var p := _ex.cuerpo.position
					if p.x < x0 - 7.98 + 0.25 or p.x > x0 + 7.98 - 0.25 or p.z < z_out + 0.04 + 0.25 or p.z > z_fin - 0.04 - 0.25:
						fuera += 1
						peor = "planta %d «%s» dirección %d: (%.2f, %.2f)" % [pl, String(s[0]), dir, p.x, p.z]
					if ColisionClub.toca_mueble(_ex.cuerpo, p, ColisionClub.RADIO - 0.05):
						dentro += 1
						peor = "planta %d «%s» dirección %d dentro de un mueble: (%.2f, %.2f)" % [pl, String(s[0]), dir, p.x, p.z]
	_ok(salas >= 10, "se recorrieron las salas (%d)" % salas)
	_ok(fuera == 0, "el cuerpo nunca sale del edificio (%d pasos fuera) %s" % [fuera, peor if fuera > 0 else ""])
	_ok(dentro == 0, "el cuerpo nunca entra en un mueble o tabique (%d pasos dentro) %s" % [dentro, peor if dentro > 0 else ""])
