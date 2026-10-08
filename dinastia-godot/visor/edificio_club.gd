class_name EdificioClub
extends RefCounted
## EL EDIFICIO DEL CLUB, POR PLANTAS (estadio interactivo 2.0, fase 2).
##
## Pedido: «todos esos lugares que creamos en el estadio deben estar
## físicamente en el estadio, además de todo lo que tiene el estadio: pisos
## negativos, oficina del DT…». Sobre la misma huella del vestuario local
## (`TunelVestuario`, planta 0) se apilan:
##   −2  estacionamiento (coches según el nivel de «park») y cuarto de máquinas
##   −1  utilería, enfermería («med») y vestuario visitante
##    1  oficina del DT, despacho del presidente y sala de vídeo («video»)
##    2  sala de prensa (`ClubDentro.sala_prensa`) y museo («museo», títulos)
## Se sube y se baja en ascensor (E). Cada planta tiene un pasillo al fondo y
## sus salas se abren a él; `zonas()` da por dónde se puede caminar.
##
## Lo que el juego sabe del club (niveles, plantilla, presidente…) llega por
## `ctx`, que rellena `Principal._refrescar()` como `PersonajeDT.del_usuario`:
## la vista del estadio y la ciudad no tienen el mundo delante.

const ALTO_PLANTA := 4.0
const ALTO_LIBRE := 3.4
## Fondo del pasillo (al lado de la fachada de atrás) y ancho de las puertas.
const PASILLO := 2.8
const PUERTA := 1.6
## El hueco del ascensor, el mismo en todas las plantas (x relativo al eje).
const ASC_X0 := -4.4
const ASC_X1 := -2.2

## {inst: {clave: nivel}, dentro: {vestuario, sala_prensa, palco},
##  plantilla: [[dorsal, nombre]], titulos: int, presidente: String}
static var ctx: Dictionary = {}

## [planta, nombre corto, [[sala, x0 relativo, x1 relativo], ...]]
const PLANTAS := [
	[-2, "Estacionamiento", [["Estacionamiento", -8.0, 3.0], ["Cuarto de máquinas", 3.0, 8.0]]],
	[-1, "Utilería y enfermería", [["Utilería", -8.0, -3.0], ["Enfermería", -3.0, 2.5], ["Vestuario visitante", 2.5, 8.0]]],
	[1, "Oficinas", [["Oficina del DT", -8.0, -2.0], ["Despacho del presidente", -2.0, 3.0], ["Sala de vídeo", 3.0, 8.0]]],
	[2, "Prensa y museo", [["Sala de prensa", -8.0, 1.5], ["Museo del club", 1.5, 8.0]]],
]

static func nombre_planta(p: int) -> String:
	if p == 0:
		return "Vestuario y túnel"
	for f: Array in PLANTAS:
		if int(f[0]) == p:
			return String(f[1])
	return ""

static func plantas() -> Array:
	var sal: Array = [0]
	for f: Array in PLANTAS:
		sal.append(int(f[0]))
	sal.sort()
	return sal

static func nivel(clave: String) -> int:
	return int((ctx.get("inst", {}) as Dictionary).get(clave, 0))

## Las zonas transitables de las plantas (la 0 la da `TunelVestuario`, aquí
## solo su ascensor). Van primero los ascensores: ganan al pisar.
static func zonas(x0: float, z_out: float, z_fin: float) -> Array:
	var sal: Array = []
	for p in plantas():
		sal.append({"nombre": "Ascensor", "planta": p, "techo": ALTO_LIBRE,
			"r": Rect2(x0 + ASC_X0, z_fin - 1.7, ASC_X1 - ASC_X0, 1.4)})
	var z_tabique := z_fin - PASILLO - 0.1
	for f: Array in PLANTAS:
		var p := int(f[0])
		sal.append({"nombre": "Pasillo", "planta": p, "techo": ALTO_LIBRE,
			"r": Rect2(x0 - TunelVestuario.VEST_MEDIO + 0.4, z_tabique + 0.3, TunelVestuario.VEST_MEDIO * 2.0 - 0.8, PASILLO - 0.6)})
		for sala: Array in f[2]:
			var a: float = x0 + float(sala[1])
			var b: float = x0 + float(sala[2])
			sal.append({"nombre": String(sala[0]), "planta": p, "techo": ALTO_LIBRE,
				"r": Rect2(a + 0.5, z_out + 0.5, b - a - 1.0, z_tabique - z_out - 0.8)})
			## La puerta: une la sala con el pasillo.
			var c := (a + b) / 2.0
			sal.append({"nombre": String(sala[0]), "planta": p, "techo": ALTO_LIBRE,
				"r": Rect2(c - PUERTA / 2.0 + 0.2, z_tabique - 0.6, PUERTA - 0.4, 1.4)})
	return sal

static func montar(padre: Node3D, x0: float, z_out: float, z_fin: float, c1: Color, c2: Color,
		horm: StandardMaterial3D, luz: StandardMaterial3D, nombre_club: String) -> void:
	var nodo := Node3D.new()
	nodo.name = "EdificioClub"
	padre.add_child(nodo)
	var ancho := TunelVestuario.VEST_MEDIO * 2.0
	var zc := (z_out + z_fin) / 2.0
	var fondo := z_fin - z_out
	var z_tabique := z_fin - PASILLO - 0.1
	var pared := TunelVestuario._mat(Color(0.94, 0.94, 0.92), 0.85)
	var suelo := TunelVestuario._mat(Color(0.5, 0.5, 0.52), 0.9)
	var vidrio: StandardMaterial3D = Texturas.cristal(true, true)
	## El ascensor de la planta 0 (dentro del vestuario, junto a la pizarra).
	_ascensor(nodo, x0, z_fin, 0.0)
	for f: Array in PLANTAS:
		var p := int(f[0])
		var y0 := float(p) * ALTO_PLANTA
		var bajo_tierra := p < 0
		## El cascarón de la planta.
		TunelVestuario._caja(nodo, Vector3(x0, y0 - 0.1, zc), Vector3(ancho + 0.6, 0.2, fondo + 0.6), horm, true)
		TunelVestuario._caja(nodo, Vector3(x0, y0 + 0.01, zc), Vector3(ancho, 0.02, fondo), suelo, false)
		TunelVestuario._caja(nodo, Vector3(x0, y0 + ALTO_LIBRE + 0.25, zc), Vector3(ancho + 0.6, 0.5, fondo + 0.6), horm, true)
		for lado in [-1.0, 1.0]:
			TunelVestuario._caja(nodo, Vector3(x0 + lado * (TunelVestuario.VEST_MEDIO + 0.15), y0 + ALTO_LIBRE / 2.0, zc),
				Vector3(0.3, ALTO_LIBRE, fondo + 0.6), horm, true)
			TunelVestuario._caja(nodo, Vector3(x0 + lado * (TunelVestuario.VEST_MEDIO - 0.02), y0 + ALTO_LIBRE / 2.0, zc),
				Vector3(0.04, ALTO_LIBRE, fondo), pared, false)
		for zz in [z_out - 0.15, z_fin + 0.15]:
			TunelVestuario._caja(nodo, Vector3(x0, y0 + ALTO_LIBRE / 2.0, zz), Vector3(ancho + 0.6, ALTO_LIBRE, 0.3), horm, true)
		TunelVestuario._caja(nodo, Vector3(x0, y0 + ALTO_LIBRE / 2.0, z_fin - 0.02), Vector3(ancho, ALTO_LIBRE, 0.04), pared, false)
		TunelVestuario._caja(nodo, Vector3(x0, y0 + ALTO_LIBRE / 2.0, z_out + 0.02), Vector3(ancho, ALTO_LIBRE, 0.04), pared, false)
		## Ventanas corridas en las plantas de arriba (a la calle y a los lados).
		if not bajo_tierra:
			TunelVestuario._caja(nodo, Vector3(x0, y0 + 1.9, z_fin + 0.31), Vector3(ancho - 1.0, 1.4, 0.04), vidrio, false)
		## El tabique del pasillo, con una puerta por sala.
		var huecos: Array = []
		for sala: Array in f[2]:
			var c := x0 + (float(sala[1]) + float(sala[2])) / 2.0
			huecos.append(Vector2(c - PUERTA / 2.0, c + PUERTA / 2.0))
		var tramos: Array = [Vector2(x0 - TunelVestuario.VEST_MEDIO, x0 + TunelVestuario.VEST_MEDIO)]
		for h: Vector2 in huecos:
			var nuevos: Array = []
			for t: Vector2 in tramos:
				for tr: Vector2 in StadiumBuilder._tramos_sin_hueco((t.x + t.y) / 2.0, t.y - t.x, h.x, h.y):
					nuevos.append(Vector2(tr.x - tr.y / 2.0, tr.x + tr.y / 2.0))
			tramos = nuevos
		for t: Vector2 in tramos:
			TunelVestuario._caja(nodo, Vector3((t.x + t.y) / 2.0, y0 + ALTO_LIBRE / 2.0, z_tabique), Vector3(t.y - t.x, ALTO_LIBRE, 0.2), pared, true)
		for h: Vector2 in huecos:
			TunelVestuario._caja(nodo, Vector3((h.x + h.y) / 2.0, y0 + (ALTO_LIBRE + 2.4) / 2.0, z_tabique), Vector3(h.y - h.x, ALTO_LIBRE - 2.4, 0.2), pared, false)
		## Tabiques entre salas.
		var salas: Array = f[2]
		for i in range(1, salas.size()):
			var xs := x0 + float(salas[i][1])
			TunelVestuario._caja(nodo, Vector3(xs, y0 + ALTO_LIBRE / 2.0, (z_out + z_tabique) / 2.0),
				Vector3(0.2, ALTO_LIBRE, z_tabique - z_out), pared, true)
		TunelVestuario._caja(nodo, Vector3(x0, y0 + ALTO_LIBRE - 0.01, z_fin - PASILLO / 2.0), Vector3(ancho - 0.1, 0.02, PASILLO - 0.1),
			TunelVestuario._mat(Color(0.9, 0.9, 0.88), 0.9), false)
		## Luz del pasillo y rótulo de la planta junto al ascensor.
		var lp := OmniLight3D.new()
		lp.position = Vector3(x0, y0 + ALTO_LIBRE - 0.4, z_fin - PASILLO / 2.0)
		lp.omni_range = 10.0
		lp.light_energy = 1.0
		nodo.add_child(lp)
		TunelVestuario._rotulo(nodo, Idiomas.t("PLANTA %d · %s") % [p, Idiomas.t(String(f[1])).to_upper()],
			Vector3(x0 + (ASC_X0 + ASC_X1) / 2.0, y0 + ALTO_LIBRE - 0.45, z_fin - 0.06), PI, 34, c1.lerp(Color(0.1, 0.1, 0.12), 0.2))
		_ascensor(nodo, x0, z_fin, y0)
		## Cada sala: su rótulo sobre la puerta (del lado del pasillo), su luz y
		## su contenido.
		for sala: Array in salas:
			var a: float = x0 + float(sala[1])
			var b: float = x0 + float(sala[2])
			var c := (a + b) / 2.0
			TunelVestuario._rotulo(nodo, Idiomas.t(String(sala[0])).to_upper(), Vector3(c, y0 + 2.75, z_tabique + 0.12), 0.0, 34, Color(0.15, 0.16, 0.2))
			var o := OmniLight3D.new()
			o.position = Vector3(c, y0 + ALTO_LIBRE - 0.4, (z_out + z_tabique) / 2.0)
			o.omni_range = maxf(6.0, (b - a) * 0.9)
			o.light_energy = 1.3
			nodo.add_child(o)
			TunelVestuario._caja(nodo, Vector3(c, y0 + ALTO_LIBRE - 0.03, (z_out + z_tabique) / 2.0), Vector3(1.8, 0.05, 0.6), luz, false)
			## Suelo y techo propios de la sala.
			TunelVestuario._caja(nodo, Vector3(c, y0 + 0.025, (z_out + z_tabique) / 2.0), Vector3(b - a - 0.2, 0.01, z_tabique - z_out - 0.1),
				TunelVestuario._mat(_suelo_de(String(sala[0])), 0.75), false)
			TunelVestuario._caja(nodo, Vector3(c, y0 + ALTO_LIBRE - 0.01, (z_out + z_tabique) / 2.0), Vector3(b - a - 0.2, 0.02, z_tabique - z_out - 0.1),
				TunelVestuario._mat(Color(0.9, 0.9, 0.88), 0.9), false)
			var caja := Rect2(a + 0.2, z_out + 0.2, b - a - 0.4, z_tabique - z_out - 0.4)
			_amueblar(nodo, String(sala[0]), caja, y0, c1, c2, nombre_club)

static func _suelo_de(sala: String) -> Color:
	match sala:
		"Estacionamiento", "Cuarto de máquinas":
			return Color(0.42, 0.44, 0.46)
		"Enfermería":
			return Color(0.78, 0.86, 0.88)
		"Oficina del DT", "Despacho del presidente", "Museo del club":
			return Color(0.55, 0.38, 0.24)
		"Sala de vídeo", "Sala de prensa":
			return Color(0.25, 0.27, 0.33)
	return Color(0.62, 0.62, 0.6)

## El ascensor: puertas de acero con su botonera, en la fachada de atrás.
static func _ascensor(nodo: Node3D, x0: float, z_fin: float, y0: float) -> void:
	var acero: StandardMaterial3D = Texturas.metal(Color(0.72, 0.74, 0.76), 0.35)
	var cx := x0 + (ASC_X0 + ASC_X1) / 2.0
	TunelVestuario._caja(nodo, Vector3(cx, y0 + 1.15, z_fin - 0.08), Vector3(ASC_X1 - ASC_X0 - 0.3, 2.3, 0.08), acero, false)
	TunelVestuario._caja(nodo, Vector3(cx, y0 + 1.15, z_fin - 0.13), Vector3(0.02, 2.2, 0.02), TunelVestuario._mat(Color(0.2, 0.2, 0.22), 0.5), false)
	var boton := TunelVestuario._mat(Color(1, 0.8, 0.3), 0.3)
	boton.emission_enabled = true
	boton.emission = Color(1, 0.75, 0.25)
	TunelVestuario._caja(nodo, Vector3(x0 + ASC_X1 + 0.1, y0 + 1.2, z_fin - 0.1), Vector3(0.12, 0.25, 0.04), boton, false)
	TunelVestuario._rotulo(nodo, "▲▼ " + Idiomas.t("ASCENSOR"), Vector3(cx, y0 + 2.5, z_fin - 0.14), PI, 28, Color(0.2, 0.22, 0.26))

## Los muebles de cada sala. `caja`: el suelo libre de la sala (x, z).
static func _amueblar(nodo: Node3D, sala: String, caja: Rect2, y0: float, c1: Color, c2: Color, nombre_club: String) -> void:
	var cx := caja.get_center().x
	var cz := caja.get_center().y
	var madera := TunelVestuario._mat(Color(0.5, 0.34, 0.2), 0.7)
	var oscuro := TunelVestuario._mat(Color(0.14, 0.15, 0.17), 0.6)
	var club := TunelVestuario._mat(c1, 0.6)
	match sala:
		"Estacionamiento":
			## Líneas de las plazas, pilares y un coche por plaza ocupada.
			var linea := TunelVestuario._mat(Color(0.95, 0.85, 0.2), 0.6)
			var plazas := clampi(3 + nivel("park") * 2, 3, 12)
			var rutas := ["res://assets/ciudad/kenney_cars/sedan.glb", "res://assets/ciudad/kenney_cars/suv.glb",
				"res://assets/ciudad/kenney_cars/hatchback-sports.glb", "res://assets/ciudad/kenney_cars/van.glb"]
			var ancho_pl := 2.6
			var n_fila := int(caja.size.x / ancho_pl)
			for k in mini(plazas, n_fila * 2):
				var fila := k / n_fila
				var col := k % n_fila
				var px := caja.position.x + (float(col) + 0.5) * ancho_pl
				var pz := caja.position.y + 2.4 if fila == 0 else caja.end.y - 2.4
				TunelVestuario._caja(nodo, Vector3(px - ancho_pl / 2.0, y0 + 0.03, pz), Vector3(0.1, 0.01, 4.6), linea, false)
				var esc := load(rutas[k % rutas.size()]) as PackedScene
				if esc != null:
					var coche: Node3D = esc.instantiate()
					coche.scale = Vector3.ONE * 1.45
					coche.position = Vector3(px, y0 + 0.02, pz)
					coche.rotation.y = 0.0 if fila == 0 else PI
					nodo.add_child(coche)
			for k in 3:
				TunelVestuario._caja(nodo, Vector3(caja.position.x + caja.size.x * (0.25 + 0.25 * k), y0 + ALTO_LIBRE / 2.0, cz),
					Vector3(0.5, ALTO_LIBRE, 0.5), TunelVestuario._mat(Color(0.6, 0.6, 0.62), 0.9), true)
		"Cuarto de máquinas":
			var metal: StandardMaterial3D = Texturas.metal(Color(0.55, 0.57, 0.6), 0.45)
			for k in 2:
				var cal := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.6
				cm.bottom_radius = 0.6
				cm.height = 2.2
				cal.mesh = cm
				cal.position = Vector3(caja.position.x + 1.2 + k * 1.6, y0 + 1.1, caja.position.y + 1.2)
				cal.material_override = metal
				nodo.add_child(cal)
			TunelVestuario._caja(nodo, Vector3(caja.end.x - 0.5, y0 + 1.0, cz), Vector3(0.5, 2.0, 2.6), TunelVestuario._mat(Color(0.75, 0.75, 0.7), 0.5), true)
			TunelVestuario._caja(nodo, Vector3(cx, y0 + 2.9, cz), Vector3(caja.size.x - 0.4, 0.3, 0.3), metal, false)
		"Utilería":
			## Estanterías de botas, cestos de balones y el burro de la ropa.
			for k in 3:
				TunelVestuario._caja(nodo, Vector3(caja.position.x + 0.4, y0 + 0.4 + k * 0.6, cz), Vector3(0.6, 0.06, caja.size.y - 1.0), madera, false)
			TunelVestuario._caja(nodo, Vector3(caja.position.x + 0.4, y0 + 1.0, cz), Vector3(0.6, 2.0, 0.08), madera, true)
			for k in 4:
				var b := MeshInstance3D.new()
				var sm := SphereMesh.new()
				sm.radius = 0.11
				sm.height = 0.22
				b.mesh = sm
				b.position = Vector3(cx + 0.4 + (k % 2) * 0.25, y0 + 0.7, cz + (k / 2) * 0.25)
				b.material_override = TunelVestuario._mat(Color(0.95, 0.95, 0.95), 0.4)
				nodo.add_child(b)
			TunelVestuario._caja(nodo, Vector3(cx + 0.5, y0 + 0.3, cz + 0.12), Vector3(0.7, 0.6, 0.7), oscuro, true)
			for k in 5:
				TunelVestuario._caja(nodo, Vector3(caja.end.x - 0.5, y0 + 1.5, caja.position.y + 0.8 + k * 0.6), Vector3(0.06, 0.8, 0.5), club, false)
			TunelVestuario._caja(nodo, Vector3(caja.end.x - 0.5, y0 + 1.95, cz), Vector3(0.05, 0.05, caja.size.y - 0.8), Texturas.metal(Color(0.7, 0.7, 0.72), 0.4), false)
		"Enfermería":
			var camas := clampi(1 + nivel("med") / 3, 1, 4)
			var blanco := TunelVestuario._mat(Color(0.95, 0.96, 0.97), 0.6)
			for k in camas:
				var px := caja.position.x + 1.0 + k * (caja.size.x - 2.0) / maxf(1.0, float(camas - 1)) if camas > 1 else cx
				TunelVestuario._caja(nodo, Vector3(px, y0 + 0.55, caja.position.y + 1.3), Vector3(0.9, 0.15, 2.0), blanco, true)
				TunelVestuario._caja(nodo, Vector3(px, y0 + 0.25, caja.position.y + 1.3), Vector3(0.8, 0.5, 1.8), Texturas.metal(Color(0.65, 0.67, 0.7), 0.4), false)
			TunelVestuario._caja(nodo, Vector3(caja.end.x - 0.4, y0 + 1.0, caja.end.y - 0.8), Vector3(0.6, 2.0, 1.2), blanco, true)
			TunelVestuario._rotulo(nodo, "✚", Vector3(cx, y0 + 2.4, caja.position.y + 0.05), 0.0, 120, Color(0.85, 0.15, 0.15))
		"Vestuario visitante":
			var gris := TunelVestuario._mat(Color(0.6, 0.62, 0.65), 0.7)
			TunelVestuario._caja(nodo, Vector3(caja.end.x - 0.35, y0 + 0.45, cz), Vector3(0.45, 0.08, caja.size.y - 0.6), madera, true)
			TunelVestuario._caja(nodo, Vector3(caja.position.x + 0.35, y0 + 0.45, cz), Vector3(0.45, 0.08, caja.size.y - 0.6), madera, true)
			for k in int(caja.size.y / 1.0):
				TunelVestuario._caja(nodo, Vector3(caja.end.x - 0.1, y0 + 1.6, caja.position.y + 0.5 + k), Vector3(0.1, 1.2, 0.85), gris, false)
			TunelVestuario._rotulo(nodo, Idiomas.t("VISITANTE"), Vector3(cx, y0 + 2.6, caja.position.y + 0.05), 0.0, 60, Color(0.3, 0.3, 0.35))
		"Oficina del DT":
			## Escritorio con ordenador, sillón, estantería con la copa y la pizarra.
			TunelVestuario._caja(nodo, Vector3(cx, y0 + 0.75, cz - 0.6), Vector3(2.0, 0.08, 0.9), madera, true)
			TunelVestuario._caja(nodo, Vector3(cx, y0 + 0.37, cz - 0.6), Vector3(1.9, 0.74, 0.8), madera, false)
			TunelVestuario._caja(nodo, Vector3(cx, y0 + 1.05, cz - 0.85), Vector3(0.7, 0.45, 0.04), oscuro, false)
			TunelVestuario._caja(nodo, Vector3(cx, y0 + 0.5, cz + 0.3), Vector3(0.6, 1.0, 0.6), oscuro, true)
			TunelVestuario._caja(nodo, Vector3(caja.position.x + 0.3, y0 + 1.1, cz), Vector3(0.4, 2.2, 2.0), madera, true)
			TunelVestuario._caja(nodo, Vector3(cx, y0 + 1.7, caja.position.y + 0.05), Vector3(2.4, 1.2, 0.05), TunelVestuario._mat(Color(0.95, 0.96, 0.97), 0.3), false)
			TunelVestuario._rotulo(nodo, nombre_club.to_upper(), Vector3(cx, y0 + 2.55, caja.position.y + 0.1), 0.0, 40, c1)
		"Despacho del presidente":
			TunelVestuario._caja(nodo, Vector3(cx, y0 + 0.78, cz - 0.3), Vector3(2.6, 0.1, 1.1), TunelVestuario._mat(Color(0.3, 0.18, 0.1), 0.4), true)
			TunelVestuario._caja(nodo, Vector3(cx, y0 + 0.38, cz - 0.3), Vector3(2.5, 0.76, 1.0), TunelVestuario._mat(Color(0.3, 0.18, 0.1), 0.4), false)
			TunelVestuario._caja(nodo, Vector3(cx, y0 + 0.6, cz + 0.6), Vector3(0.7, 1.2, 0.7), TunelVestuario._mat(Color(0.35, 0.1, 0.1), 0.5), true)
			for k in 2:
				var mastil := TunelVestuario._caja(nodo, Vector3(caja.position.x + 0.6 + k * 0.6, y0 + 1.2, caja.position.y + 0.5), Vector3(0.05, 2.4, 0.05), Texturas.metal(Color(0.8, 0.7, 0.3), 0.3), false)
				mastil.name = "Mastil"
				TunelVestuario._caja(nodo, Vector3(caja.position.x + 0.85 + k * 0.6, y0 + 2.0, caja.position.y + 0.5), Vector3(0.5, 0.35, 0.02), club if k == 0 else TunelVestuario._mat(c2, 0.6), false)
			var pres := String(ctx.get("presidente", ""))
			if pres != "":
				TunelVestuario._rotulo(nodo, pres, Vector3(cx, y0 + 0.95, cz + 0.27), 0.0, 22, Color(0.95, 0.85, 0.5))
		"Sala de vídeo":
			var filas := clampi(1 + nivel("video") / 3, 1, 4)
			TunelVestuario._caja(nodo, Vector3(cx, y0 + 1.7, caja.position.y + 0.08), Vector3(caja.size.x - 1.0, 1.6, 0.06), oscuro, false)
			var pant := TunelVestuario._mat(Color(0.2, 0.5, 0.3), 0.3)
			pant.emission_enabled = true
			pant.emission = Color(0.15, 0.45, 0.25)
			TunelVestuario._caja(nodo, Vector3(cx, y0 + 1.7, caja.position.y + 0.12), Vector3(caja.size.x - 1.2, 1.4, 0.02), pant, false)
			for f in filas:
				for k in int((caja.size.x - 1.0) / 0.8):
					TunelVestuario._caja(nodo, Vector3(caja.position.x + 0.9 + k * 0.8, y0 + 0.45, caja.position.y + 2.2 + f * 1.1), Vector3(0.6, 0.9, 0.6), club, true)
		"Sala de prensa":
			var tipo := String((ctx.get("dentro", {}) as Dictionary).get("sala_prensa", "mesa"))
			var filas2 := 2 if tipo == "mesa" else (3 if tipo == "decente" else 4)
			## El photocall con el escudo y las marcas, y la mesa con micrófonos.
			TunelVestuario._caja(nodo, Vector3(cx, y0 + 1.6, caja.position.y + 0.08), Vector3(caja.size.x - 1.0, 2.6, 0.06), TunelVestuario._mat(c1.lerp(Color.WHITE, 0.15), 0.6), false)
			for k in 8:
				TunelVestuario._rotulo(nodo, nombre_club.to_upper() if k % 2 == 0 else "DINASTÍA", Vector3(caja.position.x + 1.2 + (k % 4) * (caja.size.x - 2.4) / 3.0, y0 + 2.4 - (k / 4) * 0.9, caja.position.y + 0.13), 0.0, 26, c2)
			TunelVestuario._caja(nodo, Vector3(cx, y0 + 0.75, caja.position.y + 1.1), Vector3(3.0, 0.08, 0.8), oscuro, true)
			TunelVestuario._caja(nodo, Vector3(cx, y0 + 0.37, caja.position.y + 1.35), Vector3(3.0, 0.74, 0.05), oscuro, false)
			for f2 in filas2:
				for k in int((caja.size.x - 1.6) / 0.75):
					TunelVestuario._caja(nodo, Vector3(caja.position.x + 1.0 + k * 0.75, y0 + 0.45, caja.position.y + 3.0 + f2 * 1.0), Vector3(0.5, 0.9, 0.5), oscuro, false)
			if tipo == "television":
				for k in 3:
					TunelVestuario._caja(nodo, Vector3(caja.position.x + 1.5 + k * 2.2, y0 + 1.5, caja.end.y - 0.5), Vector3(0.4, 0.3, 0.6), oscuro, false)
		"Museo del club":
			## Vitrinas con una copa por título (hasta 12) y la camiseta histórica.
			var vitrinas := clampi(2 + nivel("museo") / 2, 2, 6)
			var titulos := clampi(int(ctx.get("titulos", 0)), 0, 12)
			var oro := Texturas.metal(Color(0.95, 0.78, 0.3), 0.25)
			for k in vitrinas:
				var px := caja.position.x + 0.9 + k * (caja.size.x - 1.8) / maxf(1.0, float(vitrinas - 1))
				var pz := caja.position.y + 1.0
				TunelVestuario._caja(nodo, Vector3(px, y0 + 0.5, pz), Vector3(0.8, 1.0, 0.8), oscuro, true)
				TunelVestuario._caja(nodo, Vector3(px, y0 + 1.45, pz), Vector3(0.8, 0.9, 0.8), Texturas.cristal(true, true), false)
				if k < titulos:
					var copa := MeshInstance3D.new()
					var cm := CylinderMesh.new()
					cm.top_radius = 0.16
					cm.bottom_radius = 0.06
					cm.height = 0.45
					copa.mesh = cm
					copa.position = Vector3(px, y0 + 1.25, pz)
					copa.material_override = oro
					nodo.add_child(copa)
			TunelVestuario._caja(nodo, Vector3(caja.end.x - 0.08, y0 + 1.6, cz + 0.5), Vector3(0.06, 1.0, 0.8), club, false)
			TunelVestuario._rotulo(nodo, Idiomas.t("%d títulos") % int(ctx.get("titulos", 0)), Vector3(cx, y0 + 2.6, caja.position.y + 0.05), 0.0, 44, Color(0.85, 0.7, 0.3))
