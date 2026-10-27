class_name TejadoTipo
extends RefCounted
## TEJADOS DISTINTOS POR TIPO (S5 «look GTA», 27-10-2026). Todos los bloques de pisos acababan en la misma azotea de grava. Ahora la
## semilla del bloque elige entre cuatro: 0 plana (la de siempre), 1 a DOS AGUAS de teja (solo bloques bajos), 2 con DEPÓSITO DE AGUA
## sobre patas y antena, 3 JARDÍN en la azotea (césped, arbustos y macetas). Todo son cajas del MultiMesh del bloque.

const PLANA := 0
const DOS_AGUAS := 1
const DEPOSITO := 2
const JARDIN := 3
const TEJA := Color(0.62, 0.3, 0.22)

## El tipo que le toca a un bloque: los de más de 4 pisos no llevan teja (no se leería desde la calle).
static func tipo_de(semilla: int, pisos: int) -> int:
	var t := posmod(hash([semilla, 31]), 4)
	if t == DOS_AGUAS and pisos > 4:
		t = DEPOSITO
	return t

## `centro`: centro del bloque a ras de suelo; `alto`: altura del último forjado; `ancho`/`fondo`: planta; devuelve el tipo montado.
static func montar(ex: CiudadExpansion, centro: Vector3, rot: Basis, ancho: float, fondo: float, alto: float, pisos: int, semilla: int) -> int:
	var t := tipo_de(semilla, pisos)
	var r := RandomNumberGenerator.new()
	r.seed = semilla + 11
	var y0 := alto + 0.3
	match t:
		DOS_AGUAS:
			var h := fondo * 0.5
			var subida := 2.3
			var ang := atan2(subida, h)
			var largo := sqrt(h * h + subida * subida) + 0.3
			for lado: float in [1.0, -1.0]:
				var base := rot * Basis(Vector3.RIGHT, ang * lado)
				ex._mod_caja(centro + rot * Vector3(0, y0 + subida * 0.5, lado * h * 0.5), Vector3(ancho + 0.6, 0.18, largo), base, TEJA)
			ex._mod_caja(centro + rot * Vector3(0, y0 + subida, 0), Vector3(ancho + 0.6, 0.22, 0.4), rot, TEJA.darkened(0.25))
			## Hastiales escalonados en los dos extremos (el triángulo de pared bajo el tejado).
			for lado_x: float in [1.0, -1.0]:
				var pasos := 6
				for k in pasos:
					var f := 1.0 - float(k + 1) / float(pasos)   ## el escalón cabe bajo la teja: no asoma dentado
					ex._mod_caja(centro + rot * Vector3(lado_x * (ancho * 0.5 - 0.15), y0 + subida * (float(k) + 0.5) / float(pasos), 0), Vector3(0.3, subida / float(pasos), maxf(fondo * f, 0.2)), rot, Color(0.9, 0.86, 0.78))
		DEPOSITO:
			var gris := Color(0.55, 0.57, 0.6)
			var ox := (r.randf() - 0.5) * ancho * 0.4
			var oz := (r.randf() - 0.5) * fondo * 0.3
			for sx: float in [-0.8, 0.8]:
				for sz: float in [-0.8, 0.8]:
					ex._mod_caja(centro + rot * Vector3(ox + sx, y0 + 0.7, oz + sz), Vector3(0.14, 1.4, 0.14), rot, Color(0.25, 0.25, 0.28))
			ex._mod_caja(centro + rot * Vector3(ox, y0 + 2.3, oz), Vector3(1.9, 1.8, 1.9), rot, gris)
			ex._mod_caja(centro + rot * Vector3(ox, y0 + 2.3, oz), Vector3(1.9, 1.8, 1.9), rot * Basis(Vector3.UP, PI * 0.25), gris)
			ex._mod_caja(centro + rot * Vector3(ox, y0 + 3.25, oz), Vector3(1.5, 0.14, 1.5), rot * Basis(Vector3.UP, PI * 0.125), Color(0.3, 0.3, 0.33))
			## Antena: mástil y dos travesaños.
			var ax := -ox * 0.6 + (r.randf() - 0.5) * 2.0
			ex._mod_caja(centro + rot * Vector3(ax, y0 + 1.8, -oz - 2.0), Vector3(0.08, 3.6, 0.08), rot, Color(0.35, 0.35, 0.38))
			for k in 2:
				ex._mod_caja(centro + rot * Vector3(ax, y0 + 2.6 + float(k) * 0.7, -oz - 2.0), Vector3(1.0 - 0.3 * float(k), 0.05, 0.05), rot, Color(0.35, 0.35, 0.38))
		JARDIN:
			var verde := Color(0.3, 0.5, 0.24)
			ex._mod_caja(centro + rot * Vector3(0, y0 + 0.12, 0), Vector3(maxf(ancho - 1.6, 1.0), 0.28, maxf(fondo - 1.6, 1.0)), rot, verde)
			for k in r.randi_range(4, 8):
				var px := (r.randf() - 0.5) * (ancho - 3.0)
				var pz := (r.randf() - 0.5) * (fondo - 3.0)
				var tam := 0.7 + r.randf() * 0.7
				var vv := Color(0.17 + r.randf() * 0.1, 0.36 + r.randf() * 0.14, 0.15)
				ex._mod_caja(centro + rot * Vector3(px, y0 + 0.3 + tam * 0.5, pz), Vector3(tam, tam, tam), rot * Basis(Vector3.UP, r.randf() * PI), vv)
			for k in 3:
				ex._mod_caja(centro + rot * Vector3((float(k) - 1.0) * 1.6, y0 + 0.5, fondo * 0.5 - 1.1), Vector3(0.5, 0.45, 0.5), rot, Color(0.72, 0.42, 0.3))
	return t
