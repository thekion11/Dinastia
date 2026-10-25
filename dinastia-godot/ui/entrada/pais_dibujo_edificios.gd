class_name PaisDibujoEdificios
extends RefCounted
## LOS EDIFICIOS ANCHOS de la pantalla de país (pirámides, pórticos, arcos, cúpulas,
## castillos, murallas), dibujados con `PaisTrazo` (coordenadas en alturas, Y arriba).
## Los huecos de arcos y pórticos son huecos DE VERDAD (`PaisTrazo.arcada`): a través
## de ellos se ve la bandera del fondo, que es lo que hace que se lean como edificios y
## no como manchas.

static func dibujar(tipo: String, v: String) -> bool:
	match tipo:
		"piramide": _piramide(v)
		"piramide_escalonada": _escalonada(v)
		"columnas": _columnas(v)
		"arco": _arco(v)
		"coliseo": _coliseo()
		"pagoda": _pagoda(v)
		"cupula": _cupula(v)
		"castillo": _castillo(v)
		"muralla": _muralla(v)
		"piedras": _piedras()
		"acueducto": _acueducto()
		"opera": _opera()
		"esfinge": _esfinge()
		"ruinas": _ruinas()
		"presa": _presa()
		_: return false
	return true

static func _piramide(v: String) -> void:
	if v == "cristal":
		## La pirámide del Louvre: vidrio (la retícula en claro) delante del palacio.
		PaisTrazo.rect(-1.1, 0.0, 1.1, 0.42)
		for i in 12:
			PaisTrazo.rect(-1.0 + i * 0.17, 0.08, -0.94 + i * 0.17, 0.3, true)
		PaisTrazo.rect(-1.12, 0.42, 1.12, 0.46)
		PaisTrazo.pol([-0.62, 0.0, 0.62, 0.0, 0.0, 0.62])
		## La retícula del vidrio: hiladas horizontales y aristas hacia el vértice.
		for i in range(1, 6):
			var t := float(i) / 6.0
			PaisTrazo.linea(-0.62 * (1.0 - t), 0.62 * t, 0.62 * (1.0 - t), 0.62 * t, 0.004, true)
			PaisTrazo.linea(-0.62 + 1.24 * t, 0.0, 0.0, 0.62, 0.004, true)
		return
	## Guiza: Keops, Kefrén (con su remate de caliza) y Micerinos, en escorzo.
	for p: Array in [[0.625, 0.62, 0.62], [-0.105, 1.0, 0.92], [-0.805, 0.42, 0.44]]:
		var x: float = p[0]
		var h: float = p[1]
		var w: float = p[2]
		PaisTrazo.pol([x - w, 0.0, x + w, 0.0, x + w * 0.12, h])
		PaisTrazo.pol([x + w * 0.12, h, x + w, 0.0, x + w * 0.35, 0.0], true)
	PaisTrazo.pol([-0.235, 0.92, 0.025, 0.92, -0.085, 1.0], true)

## Chichén Itzá (nueve terrazas, la escalinata y el templo arriba) y la Pirámide del
## Sol de Teotihuacán (cinco cuerpos anchos, sin templo).
static func _escalonada(v: String) -> void:
	var n := 9 if v == "templo" else 5
	var w0 := 0.92
	var alto_cuerpo := 0.07 if v == "templo" else 0.13
	var w1 := 0.32 if v == "templo" else 0.22
	for i in n:
		var t := float(i) / n
		var w := lerpf(w0, w1, t)
		var y := i * alto_cuerpo
		PaisTrazo.pol([-w, y, w, y, w - 0.035, y + alto_cuerpo, -w + 0.035, y + alto_cuerpo])
		PaisTrazo.rect(-w + 0.02, y + alto_cuerpo * 0.45, w - 0.02, y + alto_cuerpo * 0.55, true)
	var cima := n * alto_cuerpo
	PaisTrazo.pol([-0.1, 0.0, 0.1, 0.0, 0.07, cima, -0.07, cima], true)
	for i in 18:
		var y := cima * float(i) / 18.0
		PaisTrazo.linea(-0.085 + 0.015 * y / cima, y, 0.085 - 0.015 * y / cima, y, 0.004)
	if v == "templo":
		PaisTrazo.rect(-0.24, cima, 0.24, cima + 0.17)
		PaisTrazo.rect(-0.2, cima + 0.17, 0.2, cima + 0.2)
		PaisTrazo.rect(-0.05, cima, 0.05, cima + 0.11, true)

static func _columnas(v: String) -> void:
	match v:
		"brandeburgo":
			PaisTrazo.rect(-0.78, 0.0, 0.78, 0.04)
			for i in 6:
				var x := -0.7 + i * 0.28
				PaisTrazo.rect(x - 0.035, 0.04, x + 0.035, 0.5)
			PaisTrazo.rect(-0.82, 0.5, 0.82, 0.6)
			PaisTrazo.rect(-0.6, 0.6, 0.6, 0.7)
			PaisTrazo.rect(-0.62, 0.7, 0.62, 0.72)
			## La cuadriga: cuatro caballos al trote y la Victoria con su estandarte.
			PaisTrazo.pol([-0.2, 0.72, 0.2, 0.72, 0.18, 0.8, 0.06, 0.84, -0.06, 0.84, -0.18, 0.8])
			PaisTrazo.disco(0.0, 0.9, 0.035)
			PaisTrazo.linea(0.04, 0.84, 0.06, 1.0, 0.008)
			for x: float in [-0.68, 0.68]:
				PaisTrazo.rect(x - 0.1, 0.0, x + 0.1, 0.5)
		"karnak":
			for c: Array in [[-0.75, 0.55], [-0.45, 0.82], [-0.15, 1.0], [0.15, 1.0], [0.45, 0.8], [0.75, 0.5]]:
				var x: float = c[0]
				var h: float = c[1]
				PaisTrazo.rect(x - 0.1, 0.0, x + 0.1, h - 0.08)
				PaisTrazo.pol([x - 0.1, h - 0.08, x + 0.1, h - 0.08, x + 0.14, h - 0.02, x - 0.14, h - 0.02])
				PaisTrazo.rect(x - 0.12, h - 0.02, x + 0.12, h)
				for k in 4:
					PaisTrazo.rect(x - 0.1, 0.12 + k * 0.17, x + 0.1, 0.13 + k * 0.17, true)
			PaisTrazo.rect(-0.3, 0.92, 0.3, 1.0)
		_:
			## El Panteón de Roma: el pórtico de columnas con su frontón y la cúpula.
			PaisTrazo.cupula(0.18, 0.4, 0.55, 0.34)
			PaisTrazo.rect(-0.42, 0.0, 0.78, 0.4)
			PaisTrazo.rect(-0.8, 0.0, -0.1, 0.04)
			for i in 8:
				var x := -0.76 + i * 0.09
				PaisTrazo.rect(x - 0.025, 0.04, x + 0.025, 0.4)
			PaisTrazo.rect(-0.82, 0.4, -0.08, 0.46)
			PaisTrazo.pol([-0.82, 0.46, -0.08, 0.46, -0.45, 0.62])
			PaisTrazo.rect(0.08, 0.72, 0.28, 0.76)

static func _arco(v: String) -> void:
	match v:
		"triunfo":
			PaisTrazo.rect(-0.5, 0.0, 0.5, 0.03)
			PaisTrazo.arcada(-0.46, 0.46, 0.03, 0.7, 1, 0.3, 0.42)
			PaisTrazo.rect(-0.5, 0.7, 0.5, 0.76)
			PaisTrazo.rect(-0.46, 0.76, 0.46, 0.94)
			PaisTrazo.rect(-0.48, 0.94, 0.48, 0.97)
			for x: float in [-0.35, 0.35]:
				PaisTrazo.rect(x - 0.07, 0.2, x + 0.07, 0.48, true)
		"tiwanaku":
			PaisTrazo.rect(-0.62, 0.0, -0.18, 0.62)
			PaisTrazo.rect(0.18, 0.0, 0.62, 0.62)
			PaisTrazo.rect(-0.62, 0.62, 0.62, 0.92)
			PaisTrazo.disco(0.0, 0.8, 0.07, true)
			for i in 11:
				var x := -0.55 + i * 0.11
				PaisTrazo.rect(x - 0.03, 0.66, x + 0.03, 0.72, true)
				PaisTrazo.rect(x - 0.03, 0.86, x + 0.03, 0.89, true)
		"tres":
			## La Puerta de Alcalá: tres arcos de medio punto y dos vanos adintelados.
			PaisTrazo.rect(-0.66, 0.0, 0.66, 0.03)
			PaisTrazo.arcada(-0.42, 0.42, 0.03, 0.64, 3, 0.36, 0.1)
			for x: float in [-0.54, 0.54]:
				PaisTrazo.rect(x - 0.12, 0.03, x - 0.06, 0.64)
				PaisTrazo.rect(x + 0.06, 0.03, x + 0.12, 0.64)
				PaisTrazo.rect(x - 0.12, 0.34, x + 0.12, 0.64)
			PaisTrazo.rect(-0.68, 0.64, 0.68, 0.72)
			PaisTrazo.pol([-0.3, 0.72, 0.3, 0.72, 0.0, 0.86])
		"ciudadela":
			PaisTrazo.arcada(-0.42, 0.42, 0.0, 0.7, 1, 0.38, 0.5)
			PaisTrazo.rect(-0.46, 0.7, 0.46, 0.76)
			PaisTrazo.pol([-0.44, 0.76, 0.44, 0.76, 0.0, 0.92])
			for x: float in [-0.32, 0.32]:
				PaisTrazo.rect(x - 0.04, 0.08, x + 0.04, 0.62, true)
		"ornada":
			## Bab Mansour: el gran arco de herradura entre dos bastiones, con su
			## friso de azulejos (las bandas claras).
			PaisTrazo.rect(-0.7, 0.0, -0.4, 0.66)
			PaisTrazo.rect(0.4, 0.0, 0.7, 0.66)
			PaisTrazo.arcada(-0.4, 0.4, 0.0, 0.8, 1, 0.34, 0.36)
			PaisTrazo.rect(-0.72, 0.66, -0.38, 0.72)
			PaisTrazo.rect(0.38, 0.66, 0.72, 0.72)
			for i in 9:
				var x := -0.68 + i * 0.17
				PaisTrazo.rect(x, 0.8, x + 0.09, 0.86)
			PaisTrazo.rect(-0.4, 0.56, 0.4, 0.6, true)
			PaisTrazo.rect(-0.62, 0.3, -0.48, 0.56, true)
			PaisTrazo.rect(0.48, 0.3, 0.62, 0.56, true)
		_:
			## Un arco natural de roca (el Arco de Darwin, la Roca del Elefante): una
			## mole irregular con su ojo abierto, sobre el agua o la arena.
			PaisTrazo.cresta([-0.66, 0.0, -0.64, 0.4, -0.5, 0.72, -0.2, 0.9, 0.12, 0.92, 0.34, 0.8, 0.5, 0.58,
				0.56, 0.3, 0.52, 0.3, 0.44, 0.42, 0.3, 0.52, 0.12, 0.54, -0.04, 0.48, -0.12, 0.3, -0.14, 0.0])
			PaisTrazo.rect(0.36, 0.0, 0.58, 0.32)
			for k in 3:
				PaisTrazo.trazo([-0.6 + k * 0.4, 0.04, -0.5 + k * 0.4, 0.06, -0.4 + k * 0.4, 0.04], 0.006, true)

## El Coliseo: el anillo alto a la izquierda y el tramo derrumbado que baja a la
## derecha, con sus cuatro pisos de arcos.
static func _coliseo() -> void:
	PaisTrazo.rect(-1.0, 0.0, 1.0, 0.03)
	for piso in 3:
		var y0 := 0.03 + piso * 0.24
		var x1 := 1.0 - piso * 0.32
		PaisTrazo.arcada(-1.0, x1, y0, y0 + 0.24, 10 - piso * 2, y0 + 0.12, 0.05)
	PaisTrazo.rect(-1.0, 0.75, 0.0, 0.94)
	for i in 8:
		PaisTrazo.rect(-0.95 + i * 0.12, 0.8, -0.9 + i * 0.12, 0.88, true)
	PaisTrazo.pol([0.0, 0.75, 0.0, 0.94, 0.16, 0.78, 0.36, 0.75])

## «castillo» = Himeji (base de piedra en talud y cinco tejados que se curvan);
## «puerta» = Gwanghwamun (muralla con tres vanos y el pabellón de doble tejado).
static func _pagoda(v: String) -> void:
	if v == "puerta":
		PaisTrazo.arcada(-0.66, 0.66, 0.0, 0.42, 3, 0.2, 0.22)
		_tejado(0.0, 0.42, 0.62, 0.14)
		PaisTrazo.rect(-0.44, 0.56, 0.44, 0.7)
		for i in 7:
			PaisTrazo.rect(-0.4 + i * 0.13, 0.58, -0.36 + i * 0.13, 0.68, true)
		_tejado(0.0, 0.7, 0.56, 0.17)
		return
	PaisTrazo.pol([-0.62, 0.0, 0.62, 0.0, 0.5, 0.3, -0.5, 0.3])
	var w := 0.5
	var y := 0.3
	for i in 5:
		var h := 0.1 - i * 0.008
		PaisTrazo.rect(-w * 0.82, y, w * 0.82, y + h)
		for k in 4:
			PaisTrazo.rect(-w * 0.6 + k * w * 0.36, y + h * 0.3, -w * 0.52 + k * w * 0.36, y + h * 0.7, true)
		_tejado(0.0, y + h, w, 0.06)
		y += h + 0.06
		w *= 0.8
	PaisTrazo.linea(0.0, y, 0.0, y + 0.04, 0.01)

## Un tejado oriental: alero ancho con las puntas levantadas y la cumbrera.
static func _tejado(cx: float, y: float, w: float, h: float) -> void:
	PaisTrazo.pol([cx - w - 0.06, y + h * 0.35, cx - w, y, cx + w, y, cx + w + 0.06, y + h * 0.35,
		cx + w * 0.7, y + h * 0.55, cx + w * 0.55, y + h, cx - w * 0.55, y + h, cx - w * 0.7, y + h * 0.55])

static func _cupula(v: String) -> void:
	match v:
		"capitolio":
			PaisTrazo.rect(-1.0, 0.0, 1.0, 0.3)
			PaisTrazo.pol([-0.2, 0.3, 0.2, 0.3, 0.0, 0.38])
			PaisTrazo.rect(-0.22, 0.3, 0.22, 0.48)
			PaisTrazo.rect(-0.24, 0.48, 0.24, 0.5)
			for i in 9:
				PaisTrazo.rect(-0.2 + i * 0.05, 0.33, -0.19 + i * 0.05, 0.47, true)
			PaisTrazo.cupula(0.0, 0.5, 0.2, 0.25)
			PaisTrazo.rect(-0.04, 0.74, 0.04, 0.84)
			PaisTrazo.cupula(0.0, 0.84, 0.04, 0.04)
			PaisTrazo.linea(0.0, 0.88, 0.0, 0.94, 0.012)
			for i in 14:
				PaisTrazo.rect(-0.94 + i * 0.135, 0.06, -0.91 + i * 0.135, 0.24, true)
		"observatorio":
			PaisTrazo.cresta([-1.0, 0.0, -0.7, 0.18, -0.3, 0.3, 0.2, 0.32, 0.6, 0.22, 1.0, 0.0])
			for o: Array in [[-0.45, 0.28, 0.17], [0.0, 0.31, 0.2], [0.42, 0.25, 0.16]]:
				var x: float = o[0]
				var y: float = o[1]
				var r: float = o[2]
				PaisTrazo.rect(x - r, y, x + r, y + r * 1.1)
				PaisTrazo.cupula(x, y + r * 1.1, r, r * 0.95)
				PaisTrazo.pol([x - r * 0.12, y + r * 1.1, x + r * 0.12, y + r * 1.1, x + r * 0.08, y + r * 2.0, x - r * 0.08, y + r * 2.0], true)
		_:
			## Las cúpulas sobre un cuerpo de edificio: teatro, palacios y panteones.
			var ancho := {"teatro": 0.75, "palacio": 0.95, "legislativo": 0.95, "panteon": 0.6, "torre": 0.9}
			var w: float = ancho.get(v, 0.8)
			var alto_cuerpo := 0.36 if v != "panteon" else 0.32
			PaisTrazo.rect(-w, 0.0, w, alto_cuerpo)
			for i in int(w * 14):
				PaisTrazo.rect(-w + 0.05 + i * 0.07, 0.06, -w + 0.08 + i * 0.07, alto_cuerpo - 0.06, true)
			PaisTrazo.pol([-w * 0.4, alto_cuerpo, w * 0.4, alto_cuerpo, 0.0, alto_cuerpo + 0.12])
			if v == "torre":
				## El Palacio de López: la torre central que lo distingue.
				PaisTrazo.rect(-0.1, alto_cuerpo, 0.1, 0.78)
				PaisTrazo.rect(-0.07, 0.78, 0.07, 0.86)
				PaisTrazo.cupula(0.0, 0.86, 0.07, 0.06)
				PaisTrazo.linea(0.0, 0.92, 0.0, 0.98, 0.008)
				return
			var r := 0.26 if v != "panteon" else 0.3
			PaisTrazo.rect(-r * 0.85, alto_cuerpo + 0.1, r * 0.85, alto_cuerpo + 0.22)
			PaisTrazo.cupula(0.0, alto_cuerpo + 0.22, r, r * (1.05 if v == "teatro" else 0.9))
			var cima := alto_cuerpo + 0.22 + r * (1.05 if v == "teatro" else 0.9)
			PaisTrazo.rect(-0.03, cima - 0.01, 0.03, cima + 0.07)
			PaisTrazo.linea(0.0, cima + 0.07, 0.0, cima + 0.13, 0.008)
			if v == "teatro":
				for k in 4:
					var a := PI * (0.2 + 0.2 * k)
					PaisTrazo.trazo([cos(a) * r * 0.95, alto_cuerpo + 0.22 + sin(a) * r, 0.0, cima], 0.004, true)
			if v == "palacio":
				for x: float in [-0.7, 0.7]:
					PaisTrazo.cupula(x, alto_cuerpo, 0.1, 0.12)

static func _castillo(v: String) -> void:
	match v:
		"cuentos":
			PaisTrazo.cresta([-0.8, 0.0, -0.6, 0.12, -0.3, 0.2, 0.3, 0.2, 0.6, 0.1, 0.8, 0.0])
			PaisTrazo.rect(-0.45, 0.2, 0.4, 0.5)
			for t: Array in [[-0.48, 0.66, 0.07], [-0.2, 0.86, 0.06], [0.05, 1.0, 0.07], [0.3, 0.8, 0.06], [0.48, 0.62, 0.05]]:
				var x: float = t[0]
				var h: float = t[1]
				var r: float = t[2]
				PaisTrazo.rect(x - r, 0.2, x + r, h - 0.14)
				PaisTrazo.pol([x - r - 0.015, h - 0.14, x + r + 0.015, h - 0.14, x, h])
				PaisTrazo.rect(x - r * 0.3, h - 0.3, x + r * 0.3, h - 0.22, true)
			for i in 6:
				PaisTrazo.rect(-0.38 + i * 0.12, 0.32, -0.35 + i * 0.12, 0.42, true)
		"holsten":
			## La Puerta de Holsten: dos torres gemelas con sus caperuzas cónicas.
			PaisTrazo.rect(-0.55, 0.0, 0.55, 0.55)
			PaisTrazo.arcada(-0.16, 0.16, 0.0, 0.22, 1, 0.07, 0.04, true)
			for x: float in [-0.36, 0.36]:
				PaisTrazo.rect(x - 0.2, 0.0, x + 0.2, 0.62)
				PaisTrazo.pol([x - 0.22, 0.62, x + 0.22, 0.62, x, 0.98])
			PaisTrazo.pol([-0.16, 0.55, 0.16, 0.55, 0.0, 0.72])
			for i in 4:
				PaisTrazo.rect(-0.5 + i * 0.3, 0.36, -0.46 + i * 0.3, 0.44, true)
		"adobe":
			## Kasbah de adobe: torres en talud, almenas en diente y ventanucos.
			for t: Array in [[-0.6, 0.6, 0.16], [-0.25, 0.78, 0.2], [0.18, 0.66, 0.18], [0.55, 0.52, 0.17]]:
				var x: float = t[0]
				var h: float = t[1]
				var w: float = t[2]
				PaisTrazo.pol([x - w, 0.0, x + w, 0.0, x + w * 0.85, h, x - w * 0.85, h])
				for k in 4:
					var xd := x - w * 0.85 + (k + 0.5) * w * 0.425
					PaisTrazo.pol([xd - 0.025, h, xd + 0.025, h, xd, h + 0.05])
				PaisTrazo.rect(x - 0.02, h * 0.6, x + 0.02, h * 0.68, true)
				PaisTrazo.rect(x - w * 0.5, h * 0.3, x - w * 0.5 + 0.03, h * 0.36, true)
			PaisTrazo.rect(-0.8, 0.0, 0.8, 0.22)
		_:
			## Una fortaleza de piedra: lienzo de muralla almenado entre torres.
			PaisTrazo.cresta([-0.8, 0.0, -0.6, 0.1, 0.6, 0.1, 0.8, 0.0])
			PaisTrazo.rect(-0.7, 0.1, 0.7, 0.42)
			for i in 15:
				PaisTrazo.rect(-0.7 + i * 0.1, 0.42, -0.65 + i * 0.1, 0.46)
			for t: Array in [[-0.62, 0.64], [-0.15, 0.82], [0.25, 0.6], [0.62, 0.7]]:
				var x: float = t[0]
				var h: float = t[1]
				PaisTrazo.rect(x - 0.1, 0.1, x + 0.1, h)
				for k in 3:
					PaisTrazo.rect(x - 0.1 + k * 0.08, h, x - 0.06 + k * 0.08, h + 0.04)
				PaisTrazo.rect(x - 0.015, h - 0.18, x + 0.015, h - 0.1, true)

## Murallas: el zigzag de Sacsayhuamán, las tapias de adobe de Chan Chan y la muralla
## con puerta y pabellón de Hwaseong.
static func _muralla(v: String) -> void:
	match v:
		"zigzag":
			var xy: Array = [-1.3, 0.0]
			for i in 9:
				var x := -1.3 + i * 0.3
				xy.append_array([x, 0.32 + (0.12 if i % 2 == 0 else 0.0), x + 0.15, 0.36 + (0.0 if i % 2 == 0 else 0.12)])
			xy.append_array([1.3, 0.0])
			PaisTrazo.pol(xy)
			for i in 14:
				var x := -1.2 + i * 0.18
				PaisTrazo.trazo([x, 0.04, x + 0.06, 0.12, x + 0.02, 0.22, x + 0.08, 0.3], 0.006, true)
			PaisTrazo.cresta([-1.3, 0.36, -0.9, 0.6, -0.3, 0.75, 0.4, 0.7, 1.0, 0.55, 1.3, 0.42])
		"adobe":
			for capa: Array in [[0.0, 0.5, 1.3], [0.0, 0.3, 1.1]]:
				PaisTrazo.rect(-float(capa[2]), 0.0, float(capa[2]), float(capa[1]))
			for i in 22:
				var x := -1.25 + i * 0.115
				PaisTrazo.rect(x, 0.35, x + 0.05, 0.4, true)
				PaisTrazo.rect(x + 0.03, 0.15, x + 0.08, 0.2, true)
			PaisTrazo.pol([-1.3, 0.5, 1.3, 0.5, 1.2, 0.56, -1.2, 0.56])
		_:
			PaisTrazo.rect(-1.3, 0.0, 1.3, 0.34)
			for i in 26:
				PaisTrazo.rect(-1.3 + i * 0.1, 0.34, -1.25 + i * 0.1, 0.38)
			PaisTrazo.arcada(-0.3, 0.3, 0.0, 0.4, 1, 0.14, 0.32)
			_tejado(0.0, 0.42, 0.4, 0.12)
			PaisTrazo.rect(-0.26, 0.54, 0.26, 0.64)
			_tejado(0.0, 0.64, 0.34, 0.14)

static func _piedras() -> void:
	PaisTrazo.cresta([-1.2, 0.0, -0.8, 0.04, 0.8, 0.04, 1.2, 0.0])
	for t: Array in [[-0.85, 0.6], [-0.3, 0.72], [0.3, 0.7], [0.85, 0.56]]:
		var x: float = t[0]
		var h: float = t[1]
		PaisTrazo.pol([x - 0.22, 0.03, x - 0.1, 0.03, x - 0.11, h, x - 0.21, h - 0.02])
		PaisTrazo.pol([x + 0.1, 0.03, x + 0.22, 0.03, x + 0.21, h - 0.01, x + 0.11, h])
		PaisTrazo.pol([x - 0.25, h - 0.02, x + 0.25, h - 0.01, x + 0.24, h + 0.1, x - 0.24, h + 0.09])
	PaisTrazo.pol([0.52, 0.03, 0.62, 0.03, 0.66, 0.38, 0.55, 0.4])
	PaisTrazo.pol([-1.15, 0.03, -0.95, 0.03, -0.98, 0.12, -1.12, 0.1])

## El acueducto de Segovia: dos órdenes de arcos de granito, el alto más ligero.
static func _acueducto() -> void:
	PaisTrazo.arcada(-1.3, 1.3, 0.0, 0.5, 11, 0.36, 0.08)
	PaisTrazo.rect(-1.3, 0.5, 1.3, 0.54)
	PaisTrazo.arcada(-1.3, 1.3, 0.54, 0.9, 11, 0.8, 0.07)
	PaisTrazo.rect(-1.32, 0.9, 1.32, 0.96)

## La Ópera de Sídney: las conchas como velas, de mayor a menor, sobre el podio.
static func _opera() -> void:
	PaisTrazo.rect(-1.2, 0.0, 1.2, 0.18)
	PaisTrazo.pol([-1.2, 0.18, 1.2, 0.18, 1.1, 0.22, -1.1, 0.22])
	for c: Array in [[-0.95, 0.42, 0.55], [-0.6, 0.62, 0.78], [-0.18, 0.75, 1.0], [0.25, 0.45, 0.62], [0.55, 0.35, 0.48], [0.82, 0.25, 0.34]]:
		var x: float = c[0]
		var w: float = c[1]
		var h: float = c[2]
		var p: Array = [x, 0.22]
		for i in 13:
			var t := float(i) / 12.0
			p.append_array([x + w * t, 0.22 + (h - 0.22) * (1.0 - pow(1.0 - t, 2.2)) * (1.0 - t * 0.15)])
		p.append_array([x + w * 1.02, 0.22])
		PaisTrazo.pol(p)
		PaisTrazo.trazo([x + w * 0.1, 0.24, x + w * 0.6, 0.22 + (h - 0.22) * 0.75, x + w * 0.98, 0.22 + (h - 0.22) * 0.86], 0.005, true)

static func _esfinge() -> void:
	PaisTrazo.rect(-1.2, 0.0, 1.2, 0.05)
	## El lomo del león tumbado, de la grupa (derecha) a los hombros (izquierda).
	PaisTrazo.pol([-0.55, 0.05, 1.0, 0.05, 1.06, 0.16, 0.95, 0.3, 0.6, 0.36, 0.0, 0.38, -0.4, 0.42, -0.55, 0.42])
	PaisTrazo.rect(-1.05, 0.05, -0.4, 0.13)
	## La cabeza con el nemes, que cae a los lados como dos alas.
	PaisTrazo.pol([-0.72, 0.36, -0.36, 0.36, -0.4, 0.62, -0.46, 0.8, -0.56, 0.84, -0.66, 0.8, -0.7, 0.62])
	PaisTrazo.pol([-0.62, 0.48, -0.5, 0.48, -0.5, 0.66, -0.6, 0.7, -0.64, 0.6], true)
	for i in 5:
		PaisTrazo.linea(-0.7 + i * 0.07, 0.4, -0.66 + i * 0.07, 0.6, 0.004, true)

## Las ruinas de una misión jesuítica (Trinidad): muros de arenisca con sus arcos rotos.
static func _ruinas() -> void:
	PaisTrazo.rect(-1.0, 0.0, 1.0, 0.04)
	PaisTrazo.arcada(-0.9, 0.3, 0.04, 0.58, 4, 0.36, 0.08)
	PaisTrazo.pol([-0.9, 0.58, -0.5, 0.58, -0.6, 0.7, -0.75, 0.66, -0.9, 0.74])
	PaisTrazo.pol([0.3, 0.04, 0.42, 0.04, 0.42, 0.36, 0.36, 0.4, 0.3, 0.32])
	PaisTrazo.arcada(0.5, 0.9, 0.04, 0.84, 1, 0.5, 0.12)
	PaisTrazo.pol([0.5, 0.84, 0.9, 0.84, 0.8, 0.92, 0.62, 0.95])
	for i in 6:
		PaisTrazo.rect(-0.85 + i * 0.2, 0.46, -0.8 + i * 0.2, 0.52, true)

## La represa de Itaipú: el muro de contrafuertes y el aliviadero con el agua cayendo.
static func _presa() -> void:
	PaisTrazo.pol([-1.4, 0.0, 1.4, 0.0, 1.4, 0.52, -1.4, 0.52])
	for i in 18:
		var x := -1.32 + i * 0.155
		PaisTrazo.pol([x, 0.04, x + 0.08, 0.04, x + 0.07, 0.48, x + 0.01, 0.48], true)
	PaisTrazo.rect(-1.42, 0.52, 1.42, 0.56)
	for i in 10:
		PaisTrazo.rect(0.4 + i * 0.09, 0.56, 0.44 + i * 0.09, 0.62)
