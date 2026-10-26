class_name PaisDibujoPaisaje
extends RefCounted
## EL PAISAJE Y LOS PUENTES de la pantalla de país: montañas (con nieve en el tono
## claro de detalle), cataratas, dunas, farallones, palmeras, la Mano de Punta del Este,
## el teleférico de La Paz y seis puentes. Mismas coordenadas que `PaisTrazo`.
##
## La nieve, el agua y el hielo van en el color de DETALLE, que es más claro que la
## silueta: con eso basta para que un Fuji se lea como el Fuji y no como un triángulo.

static func dibujar(tipo: String, v: String) -> bool:
	match tipo:
		"montana": _montana(v)
		"catarata": _catarata(v)
		"dunas": _dunas()
		"farallones": _farallones()
		"palmeras": _palmeras()
		"mano": _mano()
		"teleferico": _teleferico()
		"puente": _puente(v)
		_: return false
	return true

static func _montana(v: String) -> void:
	match v:
		"cono", "volcan":
			## El cono volcánico de laderas cóncavas (Fuji, Osorno, Cotopaxi,
			## Popocatépetl). El «volcan» es más ancho y con el cráter abierto.
			var w := 1.2 if v == "cono" else 1.25
			var cima := 0.1 if v == "cono" else 0.2
			var hc := 1.0 if v == "cono" else 0.78
			## Sube por la ladera izquierda y baja por la derecha (simétricas).
			var p: Array = []
			for i in 13:
				var t := float(i) / 12.0
				p.append_array([-lerpf(w, cima, pow(t, 0.7)), hc * t])
			for i in 13:
				var t := 1.0 - float(i) / 12.0
				p.append_array([lerpf(w, cima, pow(t, 0.7)), hc * t])
			PaisTrazo.pol(p)
			if v == "cono":
				PaisTrazo.pol([-0.36, 0.7, -0.27, 0.66, -0.2, 0.72, -0.12, 0.65, -0.03, 0.74, 0.06, 0.66, 0.14, 0.73,
					0.22, 0.67, 0.36, 0.7, cima, hc, -cima, hc], true)
			else:
				PaisTrazo.pol([-0.3, 0.6, 0.3, 0.6, cima, hc, -cima, hc], true)
				PaisTrazo.cresta([-1.25, 0.0, -0.9, 0.12, -0.6, 0.18, -0.4, 0.15, -0.2, 0.0])
		"nevado":
			PaisTrazo.cresta([-1.2, 0.0, -0.9, 0.38, -0.7, 0.52, -0.52, 0.48, -0.3, 0.82, -0.12, 0.72, 0.05, 1.0,
				0.22, 0.8, 0.4, 0.86, 0.62, 0.58, 0.85, 0.44, 1.2, 0.0])
			for p: Array in [[-0.3, 0.82, 0.1], [0.05, 1.0, 0.13], [0.4, 0.86, 0.1], [-0.7, 0.52, 0.06]]:
				var x: float = p[0]
				var y: float = p[1]
				var s: float = p[2]
				PaisTrazo.pol([x, y, x + s * 1.4, y - s * 1.3, x + s * 0.6, y - s * 1.0, x + s * 0.1, y - s * 1.6,
					x - s * 0.5, y - s * 1.1, x - s * 1.2, y - s * 1.4], true)
		"mesa":
			PaisTrazo.cresta([-1.2, 0.0, -1.0, 0.2, -0.82, 0.5, -0.7, 0.7, -0.6, 0.74, 0.6, 0.76, 0.72, 0.72,
				0.86, 0.5, 1.0, 0.24, 1.2, 0.0])
			PaisTrazo.pol([-0.6, 0.74, 0.6, 0.76, 0.55, 0.78, -0.55, 0.77], true)
			for i in 9:
				var x := -0.5 + i * 0.13
				PaisTrazo.linea(x, 0.72, x - 0.02, 0.5, 0.005, true)
		"agujas":
			PaisTrazo.cresta([-1.2, 0.0, -0.9, 0.3, -0.6, 0.4, -0.5, 0.7, -0.42, 0.82, -0.34, 0.6, -0.2, 0.62,
				-0.1, 0.94, 0.0, 1.0, 0.1, 0.92, 0.2, 0.64, 0.32, 0.66, 0.42, 0.86, 0.5, 0.74, 0.58, 0.44,
				0.9, 0.3, 1.2, 0.0])
			PaisTrazo.pol([-0.1, 0.94, 0.0, 1.0, 0.1, 0.92, 0.06, 0.86, -0.06, 0.88], true)
		"pan":
			## El Pan de Azúcar (y el Peñol): la mole redondeada que sale de golpe.
			var p: Array = [-0.5, 0.0]
			for i in 17:
				var a := PI - PI * float(i) / 16.0
				p.append_array([cos(a) * 0.42 + 0.05, sin(a) * 0.95 * (1.0 - 0.2 * absf(cos(a)))])
			p.append_array([0.6, 0.0])
			PaisTrazo.pol(p)
			PaisTrazo.cresta([0.4, 0.0, 0.6, 0.32, 0.8, 0.38, 1.0, 0.2, 1.2, 0.0])
			PaisTrazo.trazo([0.05, 0.95, 0.4, 0.62, 0.7, 0.38], 0.004, true)
			PaisTrazo.disco(0.25, 0.79, 0.02, true)
		"roca":
			## Uluru: largo, bajo y de paredes rectas, con las estrías de la lluvia.
			PaisTrazo.cresta([-1.2, 0.0, -1.1, 0.32, -0.95, 0.44, -0.4, 0.48, 0.3, 0.46, 0.9, 0.4, 1.08, 0.26, 1.2, 0.0])
			for i in 14:
				var x := -1.0 + i * 0.15
				PaisTrazo.linea(x, 0.4, x + 0.02, 0.08, 0.004, true)
		"terrazas":
			## Machu Picchu: el Huayna Picchu detrás y la ciudadela en terrazas.
			PaisTrazo.cresta([-1.2, 0.0, -0.9, 0.26, -0.4, 0.34, 0.1, 0.4, 0.28, 0.7, 0.42, 0.95, 0.52, 1.0,
				0.62, 0.86, 0.78, 0.5, 1.0, 0.3, 1.2, 0.0])
			for i in 6:
				var y := 0.06 + i * 0.05
				PaisTrazo.linea(-1.0 + i * 0.08, y, 0.1 - i * 0.02, y, 0.006, true)
			for c: Array in [[-0.6, 0.3], [-0.42, 0.34], [-0.2, 0.36], [-0.05, 0.38]]:
				PaisTrazo.rect(float(c[0]), float(c[1]), float(c[0]) + 0.1, float(c[1]) + 0.05)
				PaisTrazo.pol([float(c[0]) - 0.01, float(c[1]) + 0.05, float(c[0]) + 0.11, float(c[1]) + 0.05,
					float(c[0]) + 0.05, float(c[1]) + 0.09])
		"glaciar":
			PaisTrazo.cresta([-1.2, 0.0, -0.9, 0.7, -0.6, 0.86, -0.3, 0.68, 0.1, 0.9, 0.5, 0.74, 0.9, 0.62, 1.2, 0.0])
			PaisTrazo.pol([-1.2, 0.0, 1.2, 0.0, 1.2, 0.3, 0.9, 0.36, 0.7, 0.32, 0.5, 0.4, 0.3, 0.35, 0.1, 0.42,
				-0.1, 0.36, -0.3, 0.42, -0.5, 0.34, -0.8, 0.38, -1.2, 0.32], true)
			for i in 16:
				var x := -1.1 + i * 0.145
				PaisTrazo.linea(x, 0.32, x + 0.03, 0.06, 0.006)
		"acantilado":
			PaisTrazo.cresta([-1.2, 0.0, -1.2, 0.72, -0.6, 0.76, -0.2, 0.74, 0.05, 0.7, 0.12, 0.5, 0.22, 0.44,
				0.3, 0.2, 0.42, 0.12, 1.2, 0.06, 1.2, 0.0])
			for i in 5:
				PaisTrazo.linea(-1.1 + i * 0.22, 0.7, -1.08 + i * 0.22, 0.2, 0.006, true)
		"colores":
			## Vinicunca: las franjas de minerales en el color de detalle, alternas.
			PaisTrazo.cresta([-1.2, 0.0, -0.8, 0.5, -0.4, 0.78, 0.0, 0.92, 0.4, 0.8, 0.8, 0.52, 1.2, 0.0])
			for i in 5:
				var y := 0.15 + i * 0.14
				PaisTrazo.trazo([-0.95 + i * 0.12, y, -0.4, y + 0.1, 0.0, y + 0.12, 0.4, y + 0.08, 0.95 - i * 0.12, y - 0.04], 0.03, true)
		"tumba":
			## Las tumbas de Hegra: una mole de arenisca con la fachada tallada.
			PaisTrazo.cresta([-1.0, 0.0, -0.9, 0.56, -0.7, 0.8, -0.3, 0.86, 0.3, 0.84, 0.7, 0.74, 0.92, 0.5, 1.0, 0.0])
			PaisTrazo.rect(-0.32, 0.0, 0.32, 0.62, true)
			PaisTrazo.rect(-0.26, 0.0, 0.26, 0.56)
			PaisTrazo.rect(-0.08, 0.0, 0.08, 0.26, true)
			PaisTrazo.pol([-0.2, 0.32, 0.2, 0.32, 0.0, 0.44], true)
			for i in 4:
				PaisTrazo.pol([-0.3 + i * 0.2, 0.62, -0.22 + i * 0.2, 0.62, -0.26 + i * 0.2, 0.7], true)
		"cerro":
			PaisTrazo.cresta([-1.2, 0.0, -0.8, 0.28, -0.4, 0.62, -0.1, 0.9, 0.08, 0.92, 0.4, 0.66, 0.8, 0.32, 1.2, 0.0])
			for i in 6:
				PaisTrazo.trazo([-0.9 + i * 0.3, 0.06, -0.8 + i * 0.3, 0.12, -0.7 + i * 0.3, 0.08], 0.006, true)
		"isla":
			## El Monte Saint-Michel: la roca en la marea, el pueblo y la abadía con
			## su aguja.
			PaisTrazo.rect(-1.2, 0.0, 1.2, 0.04, true)
			PaisTrazo.cresta([-0.8, 0.04, -0.6, 0.14, -0.3, 0.34, -0.15, 0.5, 0.15, 0.5, 0.35, 0.3, 0.6, 0.14, 0.8, 0.04])
			PaisTrazo.rect(-0.2, 0.48, 0.2, 0.66)
			PaisTrazo.pol([-0.2, 0.66, 0.2, 0.66, 0.0, 0.76])
			PaisTrazo.rect(-0.03, 0.72, 0.03, 0.86)
			PaisTrazo.pol([-0.03, 0.86, 0.03, 0.86, 0.0, 1.0])
			for i in 8:
				PaisTrazo.rect(-0.6 + i * 0.16, 0.12 + (0.1 if absi(i - 4) < 3 else 0.0), -0.56 + i * 0.16, 0.18 + (0.1 if absi(i - 4) < 3 else 0.0), true)
		"salar":
			## El Salar de Uyuni: el horizonte plano y los cerros reflejados en el agua.
			PaisTrazo.cresta([-1.2, 0.3, -1.0, 0.44, -0.7, 0.5, -0.5, 0.42, -0.1, 0.62, 0.3, 0.46, 0.7, 0.54, 1.0, 0.4, 1.2, 0.32])
			PaisTrazo.pol([-1.2, 0.3, 1.2, 0.32, 1.2, 0.2, 1.0, 0.25, 0.7, 0.16, 0.3, 0.22, -0.1, 0.08, -0.5, 0.2,
				-0.7, 0.14, -1.0, 0.18, -1.2, 0.26], true)
			PaisTrazo.rect(-1.2, 0.0, 1.2, 0.02)

## Cataratas: «ancha» (Iguazú, Monday) en varios saltos con la selva encima; «alta»
## (Salto Ángel) es el hilo larguísimo que cae del tepuy.
static func _catarata(v: String) -> void:
	if v == "alta":
		PaisTrazo.cresta([-1.1, 0.0, -1.0, 0.7, -0.9, 0.96, -0.2, 1.0, 0.3, 0.98, 0.5, 0.9, 0.6, 0.6, 0.8, 0.3, 1.1, 0.0])
		PaisTrazo.pol([-0.12, 0.98, 0.0, 0.98, 0.04, 0.12, -0.12, 0.12], true)
		for i in 6:
			PaisTrazo.disco(-0.04 + (i - 3) * 0.07, 0.1, 0.05 + 0.02 * (i % 2), true)
		return
	PaisTrazo.cresta([-1.1, 0.0, -1.1, 0.52, -0.6, 0.56, 0.0, 0.54, 0.6, 0.58, 1.1, 0.52, 1.1, 0.0])
	for i in 22:
		var x := -1.08 + i * 0.1
		PaisTrazo.disco(x, 0.6 + 0.03 * sin(i * 1.7), 0.06)
	for s: Array in [[-0.85, 0.22], [-0.45, 0.3], [-0.05, 0.18], [0.3, 0.26], [0.7, 0.2]]:
		var x: float = s[0]
		var w: float = s[1]
		PaisTrazo.pol([x, 0.5, x + w, 0.5, x + w + 0.02, 0.06, x - 0.02, 0.06], true)
		for k in 4:
			var xx := x + w * (k + 0.5) / 4.0
			PaisTrazo.linea(xx, 0.48, xx + 0.01, 0.1, 0.004)
	PaisTrazo.rect(-1.1, 0.0, 1.1, 0.07, true)

static func _dunas() -> void:
	PaisTrazo.cresta([-1.4, 0.0, -1.4, 0.22, -0.9, 0.42, -0.6, 0.36, -0.2, 0.56, 0.2, 0.44, 0.6, 0.32, 1.0, 0.4, 1.4, 0.24, 1.4, 0.0])
	PaisTrazo.trazo([-0.9, 0.42, -0.7, 0.24, -0.4, 0.1], 0.006, true)
	PaisTrazo.trazo([-0.2, 0.56, 0.0, 0.34, 0.3, 0.18], 0.006, true)
	PaisTrazo.trazo([1.0, 0.4, 0.8, 0.2, 0.5, 0.06], 0.006, true)
	for p: Array in [[0.55, 0.62], [0.72, 0.5], [-1.05, 0.55]]:
		_palmera(float(p[0]), 0.2, float(p[1]))

static func _farallones() -> void:
	PaisTrazo.rect(-1.3, 0.0, 1.3, 0.05, true)
	PaisTrazo.cresta([-1.3, 0.05, -1.3, 0.62, -1.1, 0.64, -1.0, 0.5, -0.92, 0.05])
	for f: Array in [[-0.62, 0.18, 0.72], [-0.2, 0.12, 0.5], [0.22, 0.16, 0.66], [0.62, 0.1, 0.4], [0.98, 0.14, 0.58]]:
		var x: float = f[0]
		var w: float = f[1]
		var h: float = f[2]
		PaisTrazo.pol([x - w, 0.05, x + w, 0.05, x + w * 0.8, h * 0.7, x + w * 0.4, h, x - w * 0.5, h * 0.96, x - w * 0.85, h * 0.6])
		PaisTrazo.trazo([x - w * 0.6, h * 0.5, x + w * 0.5, h * 0.48], 0.004, true)

## El Valle de Cocora: las palmas de cera, las más altas del mundo, sobre las lomas.
static func _palmeras() -> void:
	PaisTrazo.cresta([-0.9, 0.0, -0.6, 0.14, -0.2, 0.2, 0.3, 0.16, 0.9, 0.1, 0.9, 0.0])
	for p: Array in [[-0.55, 0.86], [-0.2, 1.0], [0.12, 0.8], [0.45, 0.92], [0.7, 0.66]]:
		_palmera(float(p[0]), 0.14, float(p[1]))

static func _palmera(x: float, y0: float, h: float) -> void:
	PaisTrazo.trazo([x, y0, x + 0.015, y0 + h * 0.5, x - 0.01, y0 + h * 0.85], 0.012)
	var cx := x - 0.01
	var cy := y0 + h * 0.85
	for a: float in [0.2, 0.6, 1.1, 1.6, 2.1, 2.6, 2.95]:
		var d := Vector2(cos(a), sin(a) * 0.5)
		PaisTrazo.trazo([cx, cy, cx + d.x * 0.09, cy + d.y * 0.09 + 0.02, cx + d.x * 0.17, cy + d.y * 0.12 - 0.03], 0.01)

## La Mano de Punta del Este: cinco dedos de hormigón que asoman de la arena.
static func _mano() -> void:
	PaisTrazo.cresta([-0.65, 0.0, -0.4, 0.06, 0.4, 0.06, 0.65, 0.0])
	var pie := PaisTrazo.base
	for d: Array in [[-0.36, 0.48, 22.0, 0.07], [-0.17, 0.84, 9.0, 0.075], [0.0, 1.0, 2.0, 0.08],
			[0.18, 0.86, -7.0, 0.075], [0.4, 0.5, -24.0, 0.08]]:
		PaisTrazo.girar(float(d[0]), 0.04, float(d[2]))
		var w: float = d[3]
		var h: float = d[1]
		PaisTrazo.rect(-w, 0.0, w, h - w)
		PaisTrazo.cupula(0.0, h - w, w, w * 0.9)
		PaisTrazo.rect(-w * 0.6, h - w * 1.8, w * 0.6, h - w * 1.7, true)
		PaisTrazo.fin_giro(pie)

static func _teleferico() -> void:
	PaisTrazo.cresta([-1.2, 0.0, -1.2, 0.08, -0.4, 0.2, 0.2, 0.42, 0.8, 0.74, 1.2, 0.86, 1.2, 0.0])
	for p: Array in [[-0.9, 0.12, 0.3], [-0.1, 0.28, 0.32], [0.62, 0.62, 0.3]]:
		var x: float = p[0]
		PaisTrazo.rect(x - 0.012, float(p[1]), x + 0.012, float(p[1]) + float(p[2]))
		PaisTrazo.rect(x - 0.06, float(p[1]) + float(p[2]), x + 0.06, float(p[1]) + float(p[2]) + 0.02)
	PaisTrazo.trazo([-1.2, 0.4, -0.9, 0.44, -0.5, 0.52, -0.1, 0.62, 0.3, 0.76, 0.62, 0.94, 1.2, 1.0], 0.005)
	PaisTrazo.trazo([-1.2, 0.36, -0.9, 0.4, -0.5, 0.48, -0.1, 0.58, 0.3, 0.72, 0.62, 0.9, 1.2, 0.96], 0.005)
	for c: Array in [[-0.7, 0.46], [-0.3, 0.55], [0.12, 0.66], [0.45, 0.82], [0.9, 0.95]]:
		var x: float = c[0]
		var y: float = c[1]
		PaisTrazo.linea(x, y, x, y - 0.06, 0.004)
		PaisTrazo.rect(x - 0.035, y - 0.12, x + 0.035, y - 0.06)
		PaisTrazo.rect(x - 0.025, y - 0.1, x + 0.025, y - 0.08, true)

static func _puente(v: String) -> void:
	match v:
		"colgante":
			## Golden Gate / Akashi / Occidente: dos torres, el cable principal en
			## catenaria, las péndolas y el tablero.
			PaisTrazo.rect(-1.4, 0.18, 1.4, 0.22)
			for x: float in [-0.7, 0.7]:
				PaisTrazo.rect(x - 0.06, 0.0, x - 0.03, 1.0)
				PaisTrazo.rect(x + 0.03, 0.0, x + 0.06, 1.0)
				for y: float in [0.4, 0.62, 0.84, 0.97]:
					PaisTrazo.rect(x - 0.06, y, x + 0.06, y + 0.025)
			var cable: Array = []
			for i in 41:
				var x := lerpf(-0.7, 0.7, float(i) / 40.0)
				cable.append_array([x, 0.24 + 0.74 * pow(x / 0.7, 2.0)])
			PaisTrazo.trazo(cable, 0.008)
			PaisTrazo.trazo([-1.4, 0.3, -1.05, 0.62, -0.7, 0.98], 0.008)
			PaisTrazo.trazo([0.7, 0.98, 1.05, 0.62, 1.4, 0.3], 0.008)
			for i in range(1, 20):
				var x := lerpf(-0.7, 0.7, float(i) / 20.0)
				PaisTrazo.linea(x, 0.22, x, 0.24 + 0.74 * pow(x / 0.7, 2.0), 0.002)
			PaisTrazo.rect(-1.4, 0.0, 1.4, 0.02, true)
		"arco":
			## Harbour Bridge: el gran arco de celosía por encima del tablero y los
			## pilonos de granito en los extremos.
			var ext: Array = []
			var inte: Array = []
			for i in 33:
				var t := float(i) / 32.0
				var x := lerpf(-1.0, 1.0, t)
				ext.append_array([x, 0.12 + 0.68 * (1.0 - x * x)])
				inte.append_array([x, 0.12 + 0.5 * (1.0 - x * x)])
			PaisTrazo.trazo(ext, 0.03)
			PaisTrazo.trazo(inte, 0.022)
			for i in range(1, 16):
				var x := lerpf(-1.0, 1.0, float(i) / 16.0)
				PaisTrazo.linea(x, 0.12 + 0.5 * (1.0 - x * x), x + 0.06, 0.12 + 0.68 * (1.0 - (x + 0.06) * (x + 0.06)), 0.006)
			PaisTrazo.rect(-1.4, 0.28, 1.4, 0.32)
			for x: float in [-1.15, 1.15]:
				PaisTrazo.rect(x - 0.11, 0.0, x + 0.11, 0.56)
				PaisTrazo.rect(x - 0.12, 0.56, x + 0.12, 0.6)
				PaisTrazo.rect(x - 0.05, 0.36, x + 0.05, 0.48, true)
			PaisTrazo.rect(-1.4, 0.0, 1.4, 0.02, true)
		"basculante":
			## Tower Bridge: dos torres góticas, las pasarelas altas y los tramos bajos.
			PaisTrazo.rect(-1.4, 0.2, 1.4, 0.25)
			PaisTrazo.rect(-0.38, 0.72, 0.38, 0.77)
			PaisTrazo.rect(-0.38, 0.8, 0.38, 0.83)
			for x: float in [-0.48, 0.48]:
				PaisTrazo.rect(x - 0.13, 0.0, x + 0.13, 0.86)
				PaisTrazo.pol([x - 0.13, 0.86, x + 0.13, 0.86, x, 1.0])
				for dx: float in [-0.13, 0.13]:
					PaisTrazo.rect(x + dx - 0.02, 0.86, x + dx + 0.02, 0.92)
				PaisTrazo.arcada(x - 0.1, x + 0.1, 0.36, 0.6, 1, 0.48, 0.12, true)
			PaisTrazo.trazo([-1.4, 0.4, -1.0, 0.3, -0.62, 0.68], 0.012)
			PaisTrazo.trazo([0.62, 0.68, 1.0, 0.3, 1.4, 0.4], 0.012)
			PaisTrazo.rect(-1.4, 0.0, 1.4, 0.02, true)
		"rialto":
			PaisTrazo.pol([-1.0, 0.0, -0.8, 0.0, -0.6, 0.26, -0.3, 0.4, 0.3, 0.4, 0.6, 0.26, 0.8, 0.0, 1.0, 0.0,
				1.0, 0.24, 0.5, 0.5, -0.5, 0.5, -1.0, 0.24])
			PaisTrazo.arcada(-0.5, 0.5, 0.5, 0.72, 6, 0.6, 0.05)
			PaisTrazo.pol([-0.55, 0.72, 0.55, 0.72, 0.36, 0.86, -0.36, 0.86])
			PaisTrazo.rect(-1.2, 0.0, 1.2, 0.02, true)
		_:
			## Atirantados: «mastil» es el Puente de la Mujer (un mástil inclinado y
			## los tirantes a un lado); «atirantado», con dos pilonos en abanico.
			PaisTrazo.rect(-1.4, 0.18, 1.4, 0.23)
			var pilonos: Array = [[0.0, 1.0, 22.0]] if v == "mastil" else [[-0.62, 0.86, 0.0], [0.62, 0.86, 0.0]]
			for p: Array in pilonos:
				var x: float = p[0]
				var inclin: float = deg_to_rad(float(p[2]))
				var top := Vector2(x - sin(inclin) * float(p[1]), cos(inclin) * float(p[1]))
				PaisTrazo.pol([x - 0.04, 0.0, x + 0.04, 0.0, top.x + 0.015, top.y, top.x - 0.015, top.y])
				for k in 7:
					var d := 0.14 + k * 0.11
					PaisTrazo.linea(top.x, top.y - k * 0.04, x + d, 0.23, 0.0035)
					if v != "mastil":
						PaisTrazo.linea(top.x, top.y - k * 0.04, x - d, 0.23, 0.0035)
				if v == "mastil":
					for k in 5:
						PaisTrazo.linea(top.x, top.y - k * 0.06, top.x - 0.2 - k * 0.1, 0.23, 0.0035)
			PaisTrazo.rect(-1.4, 0.0, 1.4, 0.02, true)
			for i in 9:
				PaisTrazo.rect(-1.3 + i * 0.32, 0.0, -1.26 + i * 0.32, 0.18)
