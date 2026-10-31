class_name DetalleFachada
extends RefCounted
## OBJETOS PEQUEÑOS POR MANZANA (S5 «look GTA», 27-10-2026). Cada bloque modular de pisos recibe, con su propia semilla (no toca el
## azar del bloque), lo que hace que una pared deje de ser un plano liso: aires acondicionados colgados de la fachada con su rejilla,
## un cable de servicio que cruza la fachada, carteles junto a la puerta y, en la pared lateral, un grafiti de colores. Todo son cajas
## del MultiMesh de cajas del bloque (`_mod_caja`): cero nodos nuevos.

const COLORES_CARTEL := [Color(0.85, 0.2, 0.2), Color(0.95, 0.8, 0.2), Color(0.2, 0.5, 0.85), Color(0.9, 0.9, 0.88), Color(0.2, 0.65, 0.4)]
const COLORES_TAG := [Color(0.95, 0.25, 0.55), Color(0.2, 0.85, 0.9), Color(0.98, 0.85, 0.1), Color(0.55, 0.9, 0.2), Color(0.95, 0.5, 0.1)]

## `frente`: centro de la fachada a ras de suelo; `rot`: giro del bloque (+Z = hacia la calle); `s`: tamaño de módulo;
## `w`/`d`/`pisos`: tamaño del bloque; `piso_alto`: alto de un piso; `puerta_i`: columna de la puerta.
static func montar(ex: CiudadExpansion, frente: Vector3, rot: Basis, s: float, w: int, pisos: int, piso_alto: float, puerta_i: int, semilla: int) -> int:
	var r := RandomNumberGenerator.new()
	r.seed = semilla + 7
	var n := 0
	var ancho := float(w) * s
	var gris := Color(0.62, 0.63, 0.65)
	var oscuro := Color(0.12, 0.12, 0.13)
	## Aires acondicionados en la fachada, de 0 a 3, en pisos altos.
	if pisos >= 2:
		for k in r.randi_range(0, 3):
			var px := (float(r.randi() % w) - float(w - 1) * 0.5) * s + (r.randf() - 0.5) * s * 0.4
			var py := float(r.randi_range(1, pisos - 1)) * piso_alto + piso_alto * 0.42
			var c := frente + rot * Vector3(px, py, 0.3)
			ex._mod_caja(c, Vector3(0.95, 0.6, 0.55), rot, gris)
			ex._mod_caja(c + rot * Vector3(0, 0, 0.28), Vector3(0.8, 0.46, 0.04), rot, oscuro)
			n += 1
	## Cable de servicio: una línea oscura en dos tramos con caída, de lado a lado de la fachada.
	if r.randf() < 0.7 and pisos >= 2:
		var yc := piso_alto * (1.0 + r.randf() * 0.5) + piso_alto * 0.8
		for mitad in 2:
			var cx := (-0.25 if mitad == 0 else 0.25) * ancho
			var y := yc - (0.18 if mitad == 0 else 0.0)
			ex._mod_caja(frente + rot * Vector3(cx, y, 0.1), Vector3(ancho * 0.5, 0.05, 0.05), rot, oscuro)
		n += 1
	## ARRIATES Y MACETAS a pie de fachada (S5, patios y jardines a nivel de calle): tierra, matas y flores en una franja de 0,55 m
	## pegada a la pared, a un lado y a veces al otro de la puerta; no estorban a quien camina por la acera.
	var x_p := (float(puerta_i) - float(w - 1) * 0.5) * s
	for lado_a: float in [-1.0, 1.0]:
		if r.randf() < 0.55:
			var cx := x_p + lado_a * s * (0.78 + r.randf() * 0.12)
			if absf(cx) > ancho * 0.5 - 1.2:
				continue
			var largo_a := 1.6 + r.randf() * 1.0
			ex._mod_caja(frente + rot * Vector3(cx, 0.17, 0.34), Vector3(largo_a, 0.34, 0.55), rot, Color(0.38, 0.27, 0.19))
			for k in r.randi_range(3, 5):
				var tam := 0.45 + r.randf() * 0.4
				var px := cx + (float(k) / 4.0 - 0.5) * largo_a * 0.85
				ex._mod_caja(frente + rot * Vector3(px, 0.34 + tam * 0.5, 0.34), Vector3(tam, tam, tam * 0.8), rot * Basis(Vector3.UP, r.randf() * PI), Color(0.17 + r.randf() * 0.1, 0.38 + r.randf() * 0.15, 0.16))
				if r.randf() < 0.6:
					ex._mod_caja(frente + rot * Vector3(px + 0.05, 0.34 + tam + 0.06, 0.34), Vector3(0.16, 0.16, 0.16), rot, COLORES_TAG[r.randi() % COLORES_TAG.size()])
			ex.cuenta["arriates"] = int(ex.cuenta.get("arriates", 0)) + 1
			n += 1
	## Carteles junto a la puerta.
	var lado := -1.0 if r.randf() < 0.5 else 1.0
	var x_puerta := (float(puerta_i) - float(w - 1) * 0.5) * s
	if w >= 3 and r.randf() < 0.75:
		var col: Color = COLORES_CARTEL[r.randi() % COLORES_CARTEL.size()]
		ex._mod_caja(frente + rot * Vector3(x_puerta + lado * s * 0.9, 1.5, 0.06), Vector3(0.9, 1.3, 0.05), rot, col)
		ex._mod_caja(frente + rot * Vector3(x_puerta + lado * s * 0.9, 1.5, 0.09), Vector3(0.7, 0.18, 0.02), rot, Color(0.95, 0.95, 0.92))
		n += 1
	## Grafiti en la pared lateral (la de la izquierda del bloque), a la altura de una persona: tres trazos de color vivo.
	if r.randf() < 0.45:
		var lz := -s * (0.8 + r.randf() * 0.5)
		var base := frente + rot * Vector3(-ancho * 0.5 - 0.02, 0.0, lz)
		var col2: Color = COLORES_TAG[r.randi() % COLORES_TAG.size()]
		for k in 3:
			ex._mod_caja(base + rot * Vector3(0, 1.0 + 0.35 * float(k) + r.randf() * 0.1, 0.5 * float(k % 2) - 0.3), Vector3(0.04, 0.22, 0.9 - 0.2 * float(k)), rot, col2)
		n += 1
	return n
