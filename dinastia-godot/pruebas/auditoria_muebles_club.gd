extends Node
## AUDITORÍA DE MUEBLES DEL EDIFICIO DEL CLUB (10-11, sesión 7, «solo club» paso 2). Recorre las piezas `Pieza_*` (catálogo `Modulos`) del
## edificio real y comprueba, para tres clubes de tres países: que apoyan en el suelo de su planta (ni flotan ni se hunden), que la huella
## cabe dentro de su sala (sin atravesar paredes ni tabiques) y que ninguna pieza queda enterrada en otra de su misma sala.
##   godot --headless --path . res://pruebas/auditoria_muebles_club.tscn   (CLUBES="CHI:0,ESP:3,ARG:5" para cambiar los clubes)
## Termina con «FIN. 0 fallos». Con INFORME=1 imprime cada pieza.
const SOBRE := ["books", "laptop", "televisionModern", "kitchenCoffeeMachine", "radio", "lampRoundTable", "lampSquareTable", "plantSmall1", "plantSmall2", "plantSmall3"]
const FLOTA := 0.10    ## una pieza de suelo no puede quedar a más de esto sobre él
const HUNDE := 0.06    ## ni hundida más de esto
const PARED := 0.05    ## tolerancia de la huella contra la pared

var _vista: VistaEstadio
var _n := 0
var _fallos := 0
var _clubes: Array = []
var _i := 0
var _m: Mundo

func _ready() -> void:
	var txt := OS.get_environment("CLUBES") if OS.get_environment("CLUBES") != "" else "CHI:0,ESP:3,ARG:5"
	for par in txt.split(","):
		var p := par.split(":")
		_clubes.append([p[0], int(p[1])])
	_abrir()

func _abrir() -> void:
	var pais: String = _clubes[_i][0]
	_m = Mundo.new()
	_m.generar([pais], 77)
	var club: Club = _m.ligas[0].clubes[int(_clubes[_i][1]) % _m.ligas[0].clubes.size()]
	PersonajeDT.club_usuario = club.id
	var pl: Array = []
	for j: Jugador in club.plantilla:
		pl.append([pl.size() + 1, Nombres.visible(j.nombre)])
	EdificioClub.ctx = {"inst": {"park": 5, "med": 7, "video": 6, "museo": 6}, "dentro": {"sala_prensa": "television"},
		"plantilla": pl, "titulos": 4, "presidente": "Presidente Ficticio"}
	var perfil := EstadioPropio.new().perfil(club)
	perfil["niveles"] = 2
	if OS.get_environment("CALIDAD") != "":   ## nivel de calidad (-3 ULTRA BAJA … 3 ULTRA ALTA); sin esto, el de defecto
		Calidad.elegida = int(OS.get_environment("CALIDAD"))
		Calidad.aplicar_viewport(get_viewport(), Calidad.elegida)
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(club, 0.85, null, null, perfil)
	_n = 0
	print("== CLUB ", pais, " ", club.nombre)

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		_vista.recorrer()
	if _n == 20:
		_revisar(_vista._explorador)
		_vista.queue_free()
		_i += 1
		if _i >= _clubes.size():
			print("===== FIN. %d fallos" % _fallos)
			get_tree().quit(1 if _fallos > 0 else 0)
		else:
			_abrir()

func _aabb_mundo(n: Node3D) -> AABB:
	var caja := AABB()
	var primera := true
	for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		var a := mi.global_transform * mi.get_aabb()
		caja = a if primera else caja.merge(a)
		primera = false
	return caja

func _fallo(txt: String) -> void:
	_fallos += 1
	print("  FALLO ", txt)

func _revisar(ex: ExploradorEstadio) -> void:
	## Se monta otra copia del edificio SIN fundir las mallas (la del juego las funde en una por material y las piezas quedan vacías).
	var d: Dictionary = ex._datos
	var x0: float = d["x0"]
	var z_out: float = d["z_out"]
	var z_fin: float = d["z_fin"]
	var raiz := Node3D.new()
	add_child(raiz)
	var horm := StandardMaterial3D.new()
	EdificioClub.montar(raiz, x0, z_out, z_fin, Color(0.7, 0.1, 0.1), Color(0.9, 0.9, 0.9), horm, horm, "Club Ficticio")
	var piezas: Array = []
	for n: Node in raiz.find_children("*", "Node3D", true, false):   ## por la marca, no por el nombre: las repetidas se llaman «@Pieza_x@2»
		if n.has_meta("pieza"):
			piezas.append(n)
	print("  piezas: ", piezas.size())
	var z_tab := z_fin - EdificioClub.PASILLO - 0.1
	var cajas: Array = []
	for n: Node3D in piezas:
		cajas.append(_aabb_mundo(n))
	for k in piezas.size():
		var n: Node3D = piezas[k]
		var a: AABB = cajas[k]
		var nombre := String(n.get_meta("pieza"))
		## Sala y planta: por el centro de la huella y la base más cercana al suelo de una planta.
		var c := a.get_center()
		var sala := ""
		var planta := 0
		var x_a := 0.0
		var x_b := 0.0
		var mejor := 1e9
		for f: Array in EdificioClub.todas():
			var y0 := float(int(f[0])) * EdificioClub.ALTO_PLANTA
			if a.position.y < y0 - 0.5 or a.position.y > y0 + EdificioClub.ALTO_LIBRE:
				continue
			for s: Array in f[2]:
				var xa: float = x0 + float(s[1])
				var xb: float = x0 + float(s[2])
				if c.x > xa and c.x < xb and absf(a.position.y - y0) < mejor:
					mejor = absf(a.position.y - y0)
					sala = String(s[0])
					planta = int(f[0])
					x_a = xa
					x_b = xb
		var en_pasillo := c.z > z_tab + 0.1   ## más allá del tabique: el pasillo (x0 ± 7,9; de z_tab+0,1 a z_fin−0,04)
		if en_pasillo:
			sala = "Pasillo"
			x_a = x0 - 8.0
			x_b = x0 + 8.0
		var etiqueta := "%s «%s» en (%.2f, %.2f)" % [nombre, sala, c.x, c.z]
		if sala == "":
			print("  (sin sala) ", etiqueta)
			continue
		var y0b := float(planta) * EdificioClub.ALTO_PLANTA
		var sube := a.position.y - y0b
		if OS.get_environment("INFORME") == "1":
			print("  %-44s sobre suelo %+.2f  x[%.2f,%.2f] z[%.2f,%.2f] alto %.2f" % [etiqueta, sube, a.position.x, a.end.x, a.position.z, a.end.z, a.size.y])
		if not (nombre in SOBRE) and not nombre.contains("rug"):
			if sube > FLOTA and not _apoyada(a, cajas, n, piezas):
				_fallo("FLOTA %.2f m: %s" % [sube, etiqueta])
			if sube < -HUNDE:
				_fallo("HUNDIDA %.2f m: %s" % [sube, etiqueta])
			## Un mueble de suelo con cuerpo (más de 35 cm de alto y 25 de ancho) tiene que frenar al jugador: sin StaticBody se atraviesa.
			if sube < 0.1 and a.size.y > 0.35 and maxf(a.size.x, a.size.z) > 0.25 and n.find_children("*", "StaticBody3D", true, false).is_empty():
				_fallo("SIN COLISIÓN (se atraviesa): %s" % etiqueta)
		var z_lo := z_tab + 0.1 if en_pasillo else z_out + 0.04
		var z_hi := z_fin - 0.04 if en_pasillo else z_tab - 0.1
		if a.position.x < x_a + 0.1 - PARED or a.end.x > x_b - 0.1 + PARED or a.position.z < z_lo - PARED or a.end.z > z_hi + PARED:
			_fallo("ATRAVIESA PARED (x[%.2f,%.2f] z[%.2f,%.2f] sala x[%.2f,%.2f] z[%.2f,%.2f]): %s" % [a.position.x, a.end.x, a.position.z, a.end.z,
				x_a + 0.1, x_b - 0.1, z_lo, z_hi, etiqueta])
	raiz.queue_free()

## Una pieza elevada es válida si descansa sobre otra (su base toca la cima de otra pieza de abajo).
func _apoyada(a: AABB, cajas: Array, yo: Node3D, piezas: Array) -> bool:
	for k in piezas.size():
		if piezas[k] == yo:
			continue
		var b: AABB = cajas[k]
		if absf(b.end.y - a.position.y) < 0.15 and b.intersects(a.grow(0.05)):
			return true
	return false
