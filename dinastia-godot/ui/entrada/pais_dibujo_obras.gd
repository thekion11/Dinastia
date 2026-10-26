class_name PaisDibujoObras
extends RefCounted
## LAS TORRES Y LAS ESTATUAS de la pantalla de país, dibujadas con `PaisTrazo` (lee su
## cabecera: coordenadas en alturas, Y hacia arriba, origen en el centro de la base).
## Cada función es una silueta reconocible, no un plano: se cuidan las proporciones que
## hacen que un monumento se lea de un vistazo (el ensanche de la Torre Eiffel, el reloj
## del Big Ben, la bola de la torre de Berlín) y se omite el resto.

static func dibujar(tipo: String, v: String) -> bool:
	match tipo:
		"obelisco": _obelisco()
		"torre_reloj": _torre_reloj(v)
		"celosia": _celosia(v)
		"estatua": _estatua(v)
		"moai": _moai()
		"torre_inclinada": _pisa()
		"rascacielos": _rascacielos(v)
		"torre_tv": _torre_tv(v)
		"faro": _faro()
		"noria": _noria()
		"molino": _molinos()
		"mitad_mundo": _mitad_mundo()
		"agujas": _agujas()
		"platillo": _platillo()
		_: return false
	return true

static func _obelisco() -> void:
	PaisTrazo.rect(-0.12, 0.0, 0.12, 0.03)
	PaisTrazo.rect(-0.09, 0.03, 0.09, 0.06)
	PaisTrazo.pol([-0.055, 0.06, 0.055, 0.06, 0.04, 0.9, 0.0, 1.0, -0.04, 0.9])
	PaisTrazo.pol([0.0, 0.08, 0.055, 0.06, 0.04, 0.9, 0.0, 1.0], true) ## la cara en sombra

## El Big Ben: fuste, la caja del reloj que sobresale, el campanario y la aguja.
## «puerta» es la Torre del Reloj de Cartagena: una puerta de muralla con su torrecilla.
static func _torre_reloj(v: String) -> void:
	if v == "puerta":
		PaisTrazo.arcada(-0.42, 0.42, 0.0, 0.42, 3, 0.16, 0.12)
		PaisTrazo.rect(-0.44, 0.42, 0.44, 0.46)
		PaisTrazo.rect(-0.12, 0.46, 0.12, 0.74)
		PaisTrazo.disco(0.0, 0.62, 0.065, true)
		PaisTrazo.rect(-0.14, 0.74, 0.14, 0.77)
		PaisTrazo.arcada(-0.1, 0.1, 0.77, 0.9, 1, 0.82, 0.04)
		PaisTrazo.cupula(0.0, 0.9, 0.08, 0.09)
		PaisTrazo.linea(0.0, 0.98, 0.0, 1.03, 0.008)
		return
	PaisTrazo.rect(-0.1, 0.0, 0.1, 0.6)
	for k in 6:
		PaisTrazo.rect(-0.07 + k * 0.028, 0.08, -0.06 + k * 0.028, 0.56, true)
	PaisTrazo.rect(-0.125, 0.6, 0.125, 0.78)
	PaisTrazo.disco(0.0, 0.69, 0.085, true)
	PaisTrazo.disco(0.0, 0.69, 0.07)
	PaisTrazo.linea(0.0, 0.69, 0.0, 0.74, 0.008, true)
	PaisTrazo.linea(0.0, 0.69, 0.035, 0.69, 0.008, true)
	PaisTrazo.rect(-0.105, 0.78, 0.105, 0.84)
	PaisTrazo.pol([-0.105, 0.84, 0.105, 0.84, 0.0, 1.0])
	for x: float in [-0.11, 0.11]:
		PaisTrazo.pol([x - 0.015, 0.78, x + 0.015, 0.78, x, 0.88])

## La Torre Eiffel (y la de Tokio, más esbelta y con dos miradores): cuatro patas que se
## curvan hacia dentro, el arco bajo la primera planta, el tramo medio y la aguja.
static func _celosia(v: String) -> void:
	var k := 0.8 if v == "tokio" else 1.0
	var pata := PackedFloat32Array([-0.36, 0.0, -0.25, 0.0, -0.12, 0.24, -0.2, 0.24])
	PaisTrazo.pol([pata[0] * k, 0.0, pata[2] * k, 0.0, pata[4] * k, 0.24, pata[6] * k, 0.24])
	PaisTrazo.pol([-pata[0] * k, 0.0, -pata[6] * k, 0.24, -pata[4] * k, 0.24, -pata[2] * k, 0.0])
	## El arco: la viga curva que une las patas por debajo de la primera planta.
	var curva: Array = []
	for i in 13:
		var a := PI * float(i) / 12.0
		curva.append_array([cos(a) * 0.2 * k, 0.12 + sin(a) * 0.07])
	PaisTrazo.trazo(curva, 0.018)
	PaisTrazo.rect(-0.22 * k, 0.24, 0.22 * k, 0.27)
	PaisTrazo.pol([-0.16 * k, 0.27, 0.16 * k, 0.27, 0.075 * k, 0.55, -0.075 * k, 0.55])
	PaisTrazo.rect(-0.1 * k, 0.55, 0.1 * k, 0.575)
	PaisTrazo.pol([-0.065 * k, 0.575, 0.065 * k, 0.575, 0.016, 0.93, -0.016, 0.93])
	if v == "tokio":
		PaisTrazo.rect(-0.05, 0.74, 0.05, 0.78)
	PaisTrazo.linea(0.0, 0.93, 0.0, 1.0, 0.008)
	## El encaje de hierro: aspas claras sobre las patas y el tramo medio.
	for i in 4:
		var y0 := 0.29 + i * 0.065
		var w0 := (0.15 - i * 0.02) * k
		PaisTrazo.linea(-w0, y0, w0 - 0.02 * k, y0 + 0.06, 0.004, true)
		PaisTrazo.linea(w0, y0, -w0 + 0.02 * k, y0 + 0.06, 0.004, true)

## «brazos» = Cristo Redentor sobre el Corcovado; «antorcha» = la Estatua de la
## Libertad sobre su pedestal; «columna» = el Ángel de la Independencia.
static func _estatua(v: String) -> void:
	match v:
		"brazos":
			PaisTrazo.cresta([-0.38, 0.0, -0.22, 0.12, -0.08, 0.2, 0.08, 0.2, 0.24, 0.1, 0.38, 0.0])
			PaisTrazo.rect(-0.04, 0.2, 0.04, 0.3)
			PaisTrazo.pol([-0.055, 0.3, 0.055, 0.3, 0.04, 0.78, -0.04, 0.78])
			PaisTrazo.pol([-0.34, 0.74, 0.34, 0.74, 0.34, 0.765, 0.04, 0.78, -0.04, 0.78, -0.34, 0.765])
			PaisTrazo.disco(0.0, 0.825, 0.035)
		"antorcha":
			PaisTrazo.rect(-0.2, 0.0, 0.2, 0.06)
			PaisTrazo.pol([-0.15, 0.06, 0.15, 0.06, 0.12, 0.36, -0.12, 0.36])
			PaisTrazo.rect(-0.09, 0.36, 0.09, 0.4)
			PaisTrazo.pol([-0.075, 0.4, 0.075, 0.4, 0.05, 0.77, -0.05, 0.77])
			PaisTrazo.pol([0.025, 0.72, 0.06, 0.73, 0.085, 0.93, 0.06, 0.93])
			PaisTrazo.pol([0.05, 0.93, 0.1, 0.93, 0.075, 1.0])
			PaisTrazo.rect(-0.1, 0.6, -0.055, 0.69)
			PaisTrazo.disco(0.0, 0.81, 0.035)
			for i in 5:
				var a := PI * (0.15 + 0.7 * float(i) / 4.0)
				PaisTrazo.linea(cos(a) * 0.03, 0.83 + sin(a) * 0.03, cos(a) * 0.075, 0.83 + sin(a) * 0.065, 0.007)
		_:
			PaisTrazo.rect(-0.2, 0.0, 0.2, 0.08)
			PaisTrazo.rect(-0.12, 0.08, 0.12, 0.2)
			PaisTrazo.pol([-0.04, 0.2, 0.04, 0.2, 0.032, 0.8, -0.032, 0.8])
			PaisTrazo.rect(-0.05, 0.8, 0.05, 0.83)
			PaisTrazo.pol([-0.015, 0.83, 0.015, 0.83, 0.012, 0.93, -0.012, 0.93])
			PaisTrazo.disco(0.0, 0.95, 0.017)
			PaisTrazo.pol([-0.01, 0.9, -0.1, 0.98, -0.07, 0.86])
			PaisTrazo.pol([0.01, 0.9, 0.1, 0.98, 0.07, 0.86])
			PaisTrazo.linea(0.012, 0.93, 0.03, 1.0, 0.006)

## Los moáis del Ahu Tongariki: una fila de cabezas sobre su plataforma, de alturas
## distintas, con la frente pesada y la nariz larga que los hace inconfundibles.
static func _moai() -> void:
	PaisTrazo.rect(-0.72, 0.0, 0.72, 0.07)
	var xs := [-0.52, -0.26, 0.0, 0.26, 0.52]
	var hs := [0.74, 0.86, 1.0, 0.82, 0.7]
	for i in xs.size():
		var x: float = xs[i]
		var s: float = hs[i] * 0.93
		PaisTrazo.pol([x - 0.1 * s, 0.07, x + 0.1 * s, 0.07, x + 0.11 * s, 0.07 + 0.55 * s, x + 0.12 * s, 0.07 + 0.78 * s,
			x + 0.085 * s, 0.07 + 0.9 * s, x - 0.09 * s, 0.07 + 0.9 * s, x - 0.115 * s, 0.07 + 0.78 * s,
			x - 0.11 * s, 0.07 + 0.55 * s])
		PaisTrazo.rect(x - 0.1 * s, 0.07 + 0.66 * s, x + 0.1 * s, 0.07 + 0.69 * s, true)
		PaisTrazo.pol([x - 0.02 * s, 0.07 + 0.64 * s, x + 0.02 * s, 0.07 + 0.64 * s, x + 0.01 * s, 0.07 + 0.42 * s,
			x - 0.04 * s, 0.07 + 0.4 * s], true)

## La Torre de Pisa: ocho cuerpos de arquerías, girada sus 4 grados.
static func _pisa() -> void:
	var pie := PaisTrazo.base
	PaisTrazo.girar(0.0, 0.0, -4.0)
	PaisTrazo.rect(-0.14, 0.0, 0.14, 0.13)
	for i in 6:
		var y0 := 0.13 + i * 0.105
		PaisTrazo.rect(-0.15, y0, 0.15, y0 + 0.012)
		PaisTrazo.arcada(-0.13, 0.13, y0 + 0.012, y0 + 0.105, 5, y0 + 0.07, 0.018)
	PaisTrazo.rect(-0.15, 0.76, 0.15, 0.775)
	PaisTrazo.rect(-0.1, 0.775, 0.1, 0.88)
	PaisTrazo.cupula(0.0, 0.88, 0.1, 0.035)
	PaisTrazo.fin_giro(pie)

static func _rascacielos(v: String) -> void:
	match v:
		"escalonado":
			PaisTrazo.rect(-0.28, 0.0, 0.28, 0.12)
			PaisTrazo.rect(-0.2, 0.12, 0.2, 0.52)
			PaisTrazo.rect(-0.14, 0.52, 0.14, 0.62)
			PaisTrazo.rect(-0.1, 0.62, 0.1, 0.7)
			PaisTrazo.rect(-0.06, 0.7, 0.06, 0.78)
			PaisTrazo.pol([-0.04, 0.78, 0.04, 0.78, 0.015, 0.88, -0.015, 0.88])
			PaisTrazo.linea(0.0, 0.88, 0.0, 1.0, 0.007)
			for i in 7:
				PaisTrazo.rect(-0.15 + i * 0.05, 0.14, -0.14 + i * 0.05, 0.5, true)
		"aguja":
			PaisTrazo.pol([-0.16, 0.0, 0.16, 0.0, 0.11, 0.6, 0.04, 0.92, 0.0, 1.0, -0.04, 0.92, -0.11, 0.6])
			PaisTrazo.pol([0.0, 0.0, 0.16, 0.0, 0.11, 0.6, 0.04, 0.92, 0.0, 1.0], true)
		"agujero":
			## El Kingdom Centre: dos alas que suben y el gran hueco en parábola arriba.
			## Cada mitad es un polígono simple: sube por fuera, cruza la punta y baja
			## por el borde del hueco (una parábola), así el hueco queda transparente.
			PaisTrazo.pol([-0.17, 0.0, 0.17, 0.0, 0.12, 0.62, -0.12, 0.62])
			for lado: float in [-1.0, 1.0]:
				var p: Array = []
				for i in 9:
					var t := float(i) / 8.0
					p.append_array([lado * (0.12 - 0.09 * pow(t, 1.5)), 0.62 + 0.38 * t])
				p.append_array([0.0, 1.0, 0.0, 0.97])
				for i in range(1, 9):
					var s := float(i) / 8.0
					p.append_array([lado * 0.08 * sqrt(s), 0.97 - 0.31 * s])
				p.append_array([0.0, 0.66, 0.0, 0.62])
				PaisTrazo.pol(p)
			PaisTrazo.rect(-0.07, 0.84, 0.07, 0.86)
		"gemelas", "congreso":
			var a := 0.75 if v == "congreso" else 1.0
			PaisTrazo.rect(-0.2, 0.0, -0.04, a)
			PaisTrazo.rect(0.04, 0.0, 0.2, a)
			if v == "congreso":
				PaisTrazo.rect(-0.04, 0.6, 0.04, 0.66)
				PaisTrazo.rect(-0.8, 0.0, 0.8, 0.08)
				## El cuenco boca arriba (la Cámara) y la cúpula (el Senado).
				PaisTrazo.elipse(-0.48, 0.2, 0.2, 0.12, PI, TAU)
				PaisTrazo.cupula(0.48, 0.08, 0.18, 0.1)
			for i in 10:
				var y := 0.08 + i * (a - 0.12) / 10.0
				PaisTrazo.rect(-0.19, y, -0.05, y + 0.012, true)
				PaisTrazo.rect(0.05, y, 0.19, y + 0.012, true)
		_:
			## El Palacio Salvo: el bloque, la torre de cuerpos que se estrechan y el remate.
			PaisTrazo.rect(-0.3, 0.0, 0.3, 0.42)
			PaisTrazo.rect(-0.16, 0.42, 0.16, 0.6)
			PaisTrazo.rect(-0.11, 0.6, 0.11, 0.74)
			PaisTrazo.pol([-0.08, 0.74, 0.08, 0.74, 0.05, 0.86, -0.05, 0.86])
			PaisTrazo.cupula(0.0, 0.86, 0.05, 0.06)
			PaisTrazo.linea(0.0, 0.9, 0.0, 1.0, 0.008)
			for i in 5:
				PaisTrazo.rect(-0.26 + i * 0.12, 0.05, -0.22 + i * 0.12, 0.38, true)

## Torres de televisión: fuste, la cabina (bola en Berlín, tambor en Seúl, Sídney y
## Johannesburgo, celosía en El Cairo, tres miradores en la Skytree) y la antena.
static func _torre_tv(v: String) -> void:
	match v:
		"bola":
			PaisTrazo.pol([-0.06, 0.0, 0.06, 0.0, 0.025, 0.55, -0.025, 0.55])
			PaisTrazo.disco(0.0, 0.62, 0.085)
			PaisTrazo.rect(-0.07, 0.6, 0.07, 0.615, true)
			PaisTrazo.pol([-0.02, 0.68, 0.02, 0.68, 0.008, 0.82, -0.008, 0.82])
			PaisTrazo.linea(0.0, 0.82, 0.0, 1.0, 0.006)
		"aguja":
			PaisTrazo.pol([-0.13, 0.0, 0.13, 0.0, 0.035, 0.58, -0.035, 0.58])
			PaisTrazo.rect(-0.06, 0.55, 0.06, 0.6)
			PaisTrazo.pol([-0.03, 0.6, 0.03, 0.6, 0.02, 0.74, -0.02, 0.74])
			PaisTrazo.rect(-0.04, 0.72, 0.04, 0.75)
			PaisTrazo.pol([-0.015, 0.75, 0.015, 0.75, 0.0, 1.0])
		"celosia":
			PaisTrazo.pol([-0.07, 0.0, 0.07, 0.0, 0.05, 0.72, -0.05, 0.72])
			for i in 12:
				var y := 0.04 + i * 0.056
				PaisTrazo.linea(-0.05, y, 0.05, y + 0.05, 0.004, true)
				PaisTrazo.linea(0.05, y, -0.05, y + 0.05, 0.004, true)
			PaisTrazo.pol([-0.05, 0.72, 0.05, 0.72, 0.09, 0.78, 0.09, 0.82, -0.09, 0.82, -0.09, 0.78])
			PaisTrazo.rect(-0.04, 0.82, 0.04, 0.86)
			PaisTrazo.linea(0.0, 0.86, 0.0, 1.0, 0.008)
		_:
			PaisTrazo.pol([-0.08, 0.0, 0.08, 0.0, 0.035, 0.62, -0.035, 0.62])
			PaisTrazo.pol([-0.06, 0.62, 0.06, 0.62, 0.12, 0.66, 0.12, 0.72, -0.12, 0.72, -0.12, 0.66])
			PaisTrazo.rect(-0.11, 0.685, 0.11, 0.7, true)
			PaisTrazo.rect(-0.08, 0.72, 0.08, 0.75)
			PaisTrazo.pol([-0.02, 0.75, 0.02, 0.75, 0.008, 0.86, -0.008, 0.86])
			PaisTrazo.linea(0.0, 0.86, 0.0, 1.0, 0.006)

static func _faro() -> void:
	PaisTrazo.cresta([-0.4, 0.0, -0.3, 0.07, -0.1, 0.1, 0.12, 0.1, 0.3, 0.06, 0.4, 0.0])
	PaisTrazo.pol([-0.1, 0.1, 0.1, 0.1, 0.065, 0.72, -0.065, 0.72])
	for i in 3:
		var y := 0.2 + i * 0.18
		var w := 0.1 - (y - 0.1) * 0.056
		PaisTrazo.rect(-w, y, w, y + 0.07, true)
	PaisTrazo.rect(-0.1, 0.72, 0.1, 0.75)
	PaisTrazo.rect(-0.055, 0.75, 0.055, 0.85, true)
	for x: float in [-0.055, -0.018, 0.018, 0.055]:
		PaisTrazo.linea(x, 0.75, x, 0.85, 0.006)
	PaisTrazo.cupula(0.0, 0.85, 0.07, 0.08)
	PaisTrazo.linea(0.0, 0.93, 0.0, 0.99, 0.008)

## La London Eye: la rueda, los radios, las cápsulas y las patas en A.
static func _noria() -> void:
	var cy := 0.54
	var r := 0.44
	var aro: Array = []
	for i in 49:
		var a := TAU * float(i) / 48.0
		aro.append_array([cos(a) * r, cy + sin(a) * r])
	PaisTrazo.trazo(aro, 0.014)
	for i in 16:
		var a := TAU * float(i) / 16.0
		PaisTrazo.linea(0.0, cy, cos(a) * r, cy + sin(a) * r, 0.003)
		PaisTrazo.elipse(cos(a) * (r + 0.03), cy + sin(a) * (r + 0.03), 0.022, 0.016, 0.0, TAU)
	PaisTrazo.disco(0.0, cy, 0.03)
	PaisTrazo.linea(0.0, cy, -0.3, 0.0, 0.018)
	PaisTrazo.linea(0.0, cy, -0.18, 0.0, 0.014)
	PaisTrazo.rect(-0.5, 0.0, 0.5, 0.025)

## Los molinos de Consuegra en la loma: torre blanca, caperuza y cuatro aspas.
static func _molinos() -> void:
	PaisTrazo.cresta([-1.1, 0.0, -0.7, 0.1, -0.2, 0.15, 0.3, 0.14, 0.8, 0.08, 1.1, 0.0])
	var pie := PaisTrazo.base
	for m: Array in [[-0.62, 0.62, 25.0], [0.0, 0.85, 10.0], [0.6, 0.66, 40.0]]:
		var x: float = m[0]
		var s: float = m[1]
		PaisTrazo.pol([x - 0.1 * s, 0.13, x + 0.1 * s, 0.13, x + 0.08 * s, 0.13 + 0.42 * s, x - 0.08 * s, 0.13 + 0.42 * s])
		PaisTrazo.rect(x - 0.02 * s, 0.13, x + 0.02 * s, 0.13 + 0.1 * s, true)
		PaisTrazo.pol([x - 0.095 * s, 0.13 + 0.42 * s, x + 0.095 * s, 0.13 + 0.42 * s, x, 0.13 + 0.56 * s])
		PaisTrazo.girar(x + 0.07 * s, 0.13 + 0.47 * s, float(m[2]))
		for k in 4:
			var a := TAU * float(k) / 4.0
			var d := Vector2(cos(a), sin(a))
			var n := Vector2(-d.y, d.x)
			PaisTrazo.linea(0.0, 0.0, d.x * 0.4 * s, d.y * 0.4 * s, 0.006)
			PaisTrazo.pol([d.x * 0.1 * s, d.y * 0.1 * s, d.x * 0.4 * s, d.y * 0.4 * s,
				(d.x * 0.4 + n.x * 0.07) * s, (d.y * 0.4 + n.y * 0.07) * s,
				(d.x * 0.1 + n.x * 0.07) * s, (d.y * 0.1 + n.y * 0.07) * s], true)
		PaisTrazo.fin_giro(pie)

## El monumento de la Mitad del Mundo: la torre troncocónica y el globo con su meridiano.
static func _mitad_mundo() -> void:
	PaisTrazo.rect(-0.28, 0.0, 0.28, 0.04)
	PaisTrazo.pol([-0.17, 0.04, 0.17, 0.04, 0.12, 0.7, -0.12, 0.7])
	PaisTrazo.rect(-0.012, 0.04, 0.012, 0.7, true)
	PaisTrazo.disco(0.0, 0.84, 0.14)
	PaisTrazo.trazo([0.0, 0.7, -0.07, 0.75, -0.1, 0.84, -0.07, 0.93, 0.0, 0.98], 0.006, true)
	PaisTrazo.linea(-0.14, 0.84, 0.14, 0.84, 0.006, true)

## La Sagrada Familia: el haz de torres de alturas distintas, cada una rematada en su
## bulbo, sobre la nave.
static func _agujas() -> void:
	PaisTrazo.rect(-0.5, 0.0, 0.5, 0.24)
	PaisTrazo.pol([-0.5, 0.24, 0.5, 0.24, 0.3, 0.34, -0.3, 0.34])
	var torres := [[-0.42, 0.62], [-0.3, 0.74], [-0.18, 0.78], [-0.07, 0.86], [0.0, 1.0],
		[0.07, 0.88], [0.18, 0.8], [0.3, 0.72], [0.42, 0.6]]
	for t: Array in torres:
		var x: float = t[0]
		var h: float = t[1]
		var w := 0.045 if h < 0.9 else 0.06
		PaisTrazo.pol([x - w, 0.2, x + w, 0.2, x + w * 0.55, h - 0.12, x, h - 0.04, x - w * 0.55, h - 0.12])
		PaisTrazo.disco(x, h - 0.03, w * 0.45)
		for k in 4:
			PaisTrazo.rect(x - w * 0.5, 0.3 + k * 0.1, x + w * 0.5, 0.31 + k * 0.1, true)
	PaisTrazo.arcada(-0.3, 0.3, 0.0, 0.2, 3, 0.1, 0.06, true)

## El MAC de Niterói, de Niemeyer: el platillo sobre su pie, junto a la rampa roja.
static func _platillo() -> void:
	PaisTrazo.cresta([-0.9, 0.0, -0.8, 0.08, -0.5, 0.12, 0.5, 0.12, 0.8, 0.07, 0.9, 0.0])
	PaisTrazo.pol([-0.1, 0.12, 0.1, 0.12, 0.13, 0.32, -0.13, 0.32])
	PaisTrazo.pol([-0.13, 0.32, 0.13, 0.32, 0.62, 0.46, 0.66, 0.56, 0.4, 0.66, -0.4, 0.66, -0.66, 0.56, -0.62, 0.46])
	PaisTrazo.rect(-0.6, 0.53, 0.6, 0.58, true)
	PaisTrazo.trazo([0.62, 0.12, 0.55, 0.22, 0.4, 0.3, 0.3, 0.4], 0.02)
	PaisTrazo.cupula(0.0, 0.66, 0.18, 0.06)
