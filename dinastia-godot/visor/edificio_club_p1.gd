extends RefCounted
## (Parte 1 de 2 de `edificio_club.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `edificio_club.gd`, conserva la clase.)

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
## El mundo, para hablar con la gente en persona (`Gente.charlar`, la junta…).
## Débil: el edificio no debe sujetar la partida en memoria.
static var mundo_ref: WeakRef

## [planta, nombre corto, [[sala, x0 relativo, x1 relativo], ...]]
const PLANTAS := [
	[-2, "Estacionamiento", [["Estacionamiento", -8.0, 3.0], ["Cuarto de máquinas", 3.0, 8.0]]],
	[-1, "Utilería y enfermería", [["Utilería", -8.0, -3.0], ["Enfermería", -3.0, 2.5], ["Vestuario visitante", 2.5, 8.0]]],
	[1, "Oficinas", [["Oficina del DT", -8.0, -2.0], ["Despacho del presidente", -2.0, 3.0], ["Sala de vídeo", 3.0, 8.0]]],
	[2, "Prensa, comedor y museo", [["Sala de prensa", -8.0, -0.5], ["Comedor del plantel", -0.5, 3.5], ["Museo del club", 3.5, 8.0]]],
]

## LOS OBJETOS DE DECORACIÓN COMO CONJUNTOS DE PIEZAS (21-10-2026): antes eran
## cajas y esferas; los que existen en el catálogo común (`Modulos`) se arman con
## muebles de verdad. Cada uno es una lista de piezas [pieza, encima_de, escala]:
## encima_de = -1 en el suelo, i = sobre la pieza i, -2 = a media altura (los
## libros en la estantería). Los muy del club (trofeo, bandera, bufanda, pizarra,
## maqueta, guitarra, balón) siguen hechos a mano con sus colores.
const DECO_MODULAR := {
	"planta": [["pottedPlant", -1, 2.2]],
	"sofa": [["loungeSofa", -1, null]],
	"tele": [["cabinetTelevision", -1, null], ["televisionModern", 0, null]],
	"alfombra": [["rugRound", -1, null]],
	"lampara": [["lampRoundFloor", -1, null]],
	"estanteria": [["bookcaseOpen", -1, null], ["books", -2, null]],
	"cafe": [["sideTable", -1, null], ["kitchenCoffeeMachine", 0, null]],
	"escritorio": [["deskCorner", -1, null], ["laptop", 0, null]],
	"sillon": [["loungeChairRelax", -1, null]],
	"mesa_baja": [["tableCoffee", -1, null]],
	"radio": [["sideTableDrawers", -1, null], ["radio", 0, null]],
	"perchero": [["coatRackStanding", -1, null]],
	"altavoz": [["speaker", -1, null]],
	"nevera": [["kitchenFridgeSmall", -1, null]],
}

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

## La pared del fondo del sótano (−2), con la puerta de la galería que lleva
## al complejo (`GaleriaClub`). En el estadio suelto no hay complejo: persiana.
static func _pared_galeria(nodo: Node3D, x0: float, z_fin: float, y0: float, ancho: float,
		horm: StandardMaterial3D, pared: StandardMaterial3D, c1: Color) -> void:
	var xp := x0 + TunelVestuario.PUERTA_X
	var h0 := xp - GaleriaClub.MEDIO
	var h1 := xp + GaleriaClub.MEDIO
	for tr: Vector2 in StadiumBuilder._tramos_sin_hueco(x0, ancho + 0.6, h0, h1):
		TunelVestuario._caja(nodo, Vector3(tr.x, y0 + ALTO_LIBRE / 2.0, z_fin + 0.15), Vector3(tr.y, ALTO_LIBRE, 0.3), horm, true)
	for tr2: Vector2 in StadiumBuilder._tramos_sin_hueco(x0, ancho, h0, h1):
		TunelVestuario._caja(nodo, Vector3(tr2.x, y0 + ALTO_LIBRE / 2.0, z_fin - 0.02), Vector3(tr2.y, ALTO_LIBRE, 0.04), pared, false)
	## Dintel y marco con el color del club.
	var marco := TunelVestuario._mat(c1, 0.5)
	TunelVestuario._caja(nodo, Vector3(xp, y0 + ALTO_LIBRE - 0.05, z_fin - 0.05), Vector3(h1 - h0 + 0.3, 0.12, 0.1), marco, false)
	for xx in [h0, h1]:
		TunelVestuario._caja(nodo, Vector3(xx, y0 + (ALTO_LIBRE - 0.1) / 2.0, z_fin - 0.05), Vector3(0.12, ALTO_LIBRE - 0.1, 0.1), marco, false)
	var texto := Idiomas.t("GALERÍA AL COMPLEJO")
	if not GaleriaClub.en_ciudad:
		## Persiana bajada: la galería se recorre desde la ciudad.
		var persiana := TunelVestuario._mat(Color(0.62, 0.64, 0.66), 0.45)
		persiana.metallic = 0.6
		TunelVestuario._caja(nodo, Vector3(xp, y0 + ALTO_LIBRE / 2.0, z_fin + 0.1), Vector3(h1 - h0, ALTO_LIBRE, 0.06), persiana, true)
		for k in 14:
			TunelVestuario._caja(nodo, Vector3(xp, y0 + 0.15 + float(k) * 0.24, z_fin + 0.06), Vector3(h1 - h0, 0.03, 0.02),
				TunelVestuario._mat(Color(0.45, 0.47, 0.5), 0.5), false)
		texto += "\n" + Idiomas.t("(se recorre desde la ciudad)")
	TunelVestuario._rotulo(nodo, "⇣ " + texto, Vector3(xp, y0 + ALTO_LIBRE - 0.35, z_fin - 0.14), PI, 30, c1.lerp(Color(0.08, 0.08, 0.1), 0.3))

## Lo que el usuario eligió para esta sala (`InterioresClub`), o vacío.
static func _gusto(sala: String) -> Dictionary:
	var it: Variant = ctx.get("interiores")
	if it is InterioresClub:
		return (it as InterioresClub).salas.get(sala, {})
	return {}

static func _suelo_de(sala: String) -> Color:
	match sala:
		"Estacionamiento", "Cuarto de máquinas":
			return Color(0.42, 0.44, 0.46)
		"Enfermería":
			return Color(0.78, 0.86, 0.88)
		"Oficina del DT", "Despacho del presidente", "Museo del club", "Comedor del plantel":
			return Color(0.55, 0.38, 0.24)
		"Sala de vídeo", "Sala de prensa":
			return Color(0.25, 0.27, 0.33)
	return Color(0.62, 0.62, 0.6)

## Un mueble del catálogo común (`Modulos`) en `p`, girado `giro` (de frente,
## +Z). `solida`: con su caja de choque, como las cajas de siempre.
static func _mod(nodo: Node3D, nombre: String, p: Vector3, giro: float, solida := false, esc: Variant = null, tonos: Dictionary = {}) -> Node3D:
	if not Modulos.existe(nombre):
		return null
	var n := Modulos.tomar(nombre, esc, tonos)
	n.position = p
	n.rotation.y = giro
	nodo.add_child(n)
	if solida:
		var caja: AABB = Modulos.datos(nombre)["caja"]
		var e: Vector3 = n.get_meta("escala", Vector3.ONE)
		var cuerpo := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = caja.size * e
		forma.shape = bs
		forma.position = caja.get_center() * e
		cuerpo.add_child(forma)
		n.add_child(cuerpo)
	return n

## Lo alto que queda una pieza (para poner otra encima).
static func _alto_mod(nombre: String) -> float:
	if not Modulos.existe(nombre):
		return 0.0
	return (Modulos.datos(nombre)["caja"] as AABB).end.y * Modulos.escala(nombre).y

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
				## Camillas de verdad con su mesita (21-10-2026).
				if _mod(nodo, "bedSingle", Vector3(px, y0, caja.position.y + 1.3), PI, true, null, {"carpet": Color(0.92, 0.94, 0.96)}) == null:
					TunelVestuario._caja(nodo, Vector3(px, y0 + 0.55, caja.position.y + 1.3), Vector3(0.9, 0.15, 2.0), blanco, true)
				_mod(nodo, "sideTableDrawers", Vector3(px + 0.75, y0, caja.position.y + 0.55), 0.0)
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
			## (21-10-2026) Muebles de verdad del catálogo común, no cajas: mesa
			## con monitor, teclado y lámpara, sillón de despacho, estantería con
			## libros, sofá de espera, alfombra, planta, perchero y la pizarra.
			_mod(nodo, "rugRectangle", Vector3(cx, y0, cz - 0.1), 0.0, false, null, {"carpet": c1.lerp(Color(0.2, 0.2, 0.2), 0.5)})
			_mod(nodo, "desk", Vector3(cx, y0, cz - 0.6), 0.0, true)
			var sobre := y0 + _alto_mod("desk")
			_mod(nodo, "computerScreen", Vector3(cx, sobre, cz - 0.85), 0.0)
			_mod(nodo, "computerKeyboard", Vector3(cx, sobre, cz - 0.45), 0.0)
			_mod(nodo, "lampSquareTable", Vector3(cx + 0.75, sobre, cz - 0.8), 0.0)
			_mod(nodo, "chairDesk", Vector3(cx, y0, cz + 0.25), PI, true)
			_mod(nodo, "bookcaseOpen", Vector3(caja.position.x + 0.3, y0, cz - 0.4), PI * 0.5, true)
			_mod(nodo, "books", Vector3(caja.position.x + 0.3, y0 + 0.9, cz - 0.4), PI * 0.5)
			_mod(nodo, "loungeSofa", Vector3(caja.end.x - 0.55, y0, cz + 0.6), -PI * 0.5, true, null, {"carpet": c1.lerp(Color(0.15, 0.15, 0.17), 0.35)})
			_mod(nodo, "pottedPlant", Vector3(caja.end.x - 0.45, y0, caja.position.y + 0.5), 0.0, false, 2.2)
			_mod(nodo, "coatRackStanding", Vector3(caja.position.x + 0.45, y0, caja.end.y - 0.6), 0.0)
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
			_mod(nodo, "chairModernFrameCushion", Vector3(cx - 0.6, y0, cz + 0.5), PI)
			_mod(nodo, "chairModernFrameCushion", Vector3(cx + 0.6, y0, cz + 0.5), PI)
			_mod(nodo, "loungeDesignSofa", Vector3(caja.end.x - 0.6, y0, cz + 0.4), -PI * 0.5, true, null, {"carpet": c1.lerp(Color(0.15, 0.15, 0.17), 0.35)})
			_mod(nodo, "tableCoffeeGlass", Vector3(caja.end.x - 1.6, y0, cz + 0.4), PI * 0.5)
			_mod(nodo, "lampRoundFloor", Vector3(caja.end.x - 0.45, y0, caja.position.y + 0.5), 0.0)
			_mod(nodo, "pottedPlant", Vector3(caja.position.x + 0.45, y0, caja.end.y - 0.5), 0.0, false, 2.2)
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
					## Butacas de cine de verdad (antes, cubos del color del club).
					if _mod(nodo, "loungeChair", Vector3(caja.position.x + 0.9 + k * 0.8, y0, caja.position.y + 2.2 + f * 1.1), PI, true, 1.25, {"carpet": c1.lerp(Color(0.12, 0.12, 0.14), 0.4)}) == null:
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
					if _mod(nodo, "chairCushion", Vector3(caja.position.x + 1.0 + k * 0.75, y0, caja.position.y + 3.0 + f2 * 1.0), PI) == null:
						TunelVestuario._caja(nodo, Vector3(caja.position.x + 1.0 + k * 0.75, y0 + 0.45, caja.position.y + 3.0 + f2 * 1.0), Vector3(0.5, 0.9, 0.5), oscuro, false)
			if tipo == "television":
				for k in 3:
					TunelVestuario._caja(nodo, Vector3(caja.position.x + 1.5 + k * 2.2, y0 + 1.5, caja.end.y - 0.5), Vector3(0.4, 0.3, 0.6), oscuro, false)
		"Comedor del plantel":
			## Mesa larga con sillas, la barra con la comida y la campana.
			## (21-10-2026) Mesas y sillas de verdad, con platos y vasos; las sillas
			## miran a la mesa (piezas del catálogo común).
			var n_mesas := maxi(1, int((caja.size.y - 2.6) / 1.6))
			for k in n_mesas:
				var zm := caja.position.y + 2.0 + k * 1.6
				if _mod(nodo, "table", Vector3(cx, y0, zm), PI * 0.5, true) == null:
					TunelVestuario._caja(nodo, Vector3(cx, y0 + 0.75, zm), Vector3(1.0, 0.08, 1.4), madera, true)
				var arriba := y0 + _alto_mod("table")
				for lado: float in [-1.0, 1.0]:
					for f: float in [-0.35, 0.35]:
						_mod(nodo, "chair", Vector3(cx + lado * 0.85, y0, zm + f), -lado * PI * 0.5, false, null, {"carpet": c1.lerp(Color(0.2, 0.2, 0.2), 0.3)})
						_mod(nodo, "comida/plate", Vector3(cx + lado * 0.3, arriba, zm + f), 0.0)
				_mod(nodo, "comida/glass", Vector3(cx, arriba, zm), 0.0)
			TunelVestuario._caja(nodo, Vector3(cx, y0 + 0.5, caja.position.y + 0.4), Vector3(caja.size.x - 0.4, 1.0, 0.6), Texturas.metal(Color(0.75, 0.77, 0.8), 0.35), true)
			for k in 4:
				TunelVestuario._caja(nodo, Vector3(caja.position.x + 0.6 + k * (caja.size.x - 1.2) / 3.0, y0 + 1.05, caja.position.y + 0.4),
					Vector3(0.45, 0.1, 0.35), TunelVestuario._mat([Color(0.9, 0.6, 0.2), Color(0.3, 0.6, 0.25), Color(0.85, 0.85, 0.75), Color(0.7, 0.2, 0.15)][k], 0.8), false)
			TunelVestuario._caja(nodo, Vector3(cx, y0 + 2.7, caja.position.y + 0.4), Vector3(caja.size.x - 0.6, 0.5, 0.7), Texturas.metal(Color(0.6, 0.62, 0.65), 0.4), false)
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

## Los datos de un objeto de decoración para `Modulos.de_datos`.
static func datos_deco(clave: String) -> Array:
	var sal: Array = []
	for d: Array in DECO_MODULAR.get(clave, []):
		var nombre := String(d[0])
		var sobre := int(d[1])
		var y := 0.0
		if sobre >= 0 and sobre < sal.size():
			y = float((sal[sobre]["p"] as Array)[1]) + _alto_mod(String(sal[sobre]["pieza"]))
		elif sobre == -2:
			y = 0.9
		var e: Vector3 = Modulos.escala(nombre, d[2])
		sal.append({"pieza": nombre, "p": [0.0, y, 0.0], "giro": 0.0, "s": [e.x, e.y, e.z]})
	return sal

static func _m(c: Color, r: float = 0.6) -> StandardMaterial3D:
	return TunelVestuario._mat(c, r)
