class_name PeatonQ
extends RefCounted
## LOS PEATONES, CON PERSONAS DE VERDAD (26-9-2026). Pedido del usuario: *"hay
## personas 3D del paquete del fútbol (son más que solo el calvo): ponlas como
## peatones, solo ponles ropa o barba y cosas así"*.
##
## Son los cuerpos del paquete Quaternius (hombre y mujer, los mismos de los
## futbolistas) con:
##   - ropa de calle pintada por `equipacion_q.gdshader` en modo `civil` (sin
##     escudo, marca ni dorsal) y `largo` (manga larga y pantalón largo):
##     camiseta lisa, a rayas, a cuadros tipo franela o polerón con capucha de
##     otro color, vaqueros, chinos o pantalón de buzo, y zapatillas;
##   - peinado de los ocho del paquete (`PeloQ`), barba en uno de cada tres
##     hombres, y su color de pelo;
##   - tono de piel y estatura variados;
##   - caminando con el clip "caminar" de la Universal Animation Library.
## Lejos de la cámara se dejan de dibujar (`visibility_range_end`): la ciudad
## puede tener decenas sin notarse en los fotogramas.

const PIELES := ["f1c7a5", "e0b08a", "c68d68", "a86b45", "7a4e32", "5a3a26"]
const PELOS := [Color(0.08, 0.06, 0.05), Color(0.25, 0.16, 0.09), Color(0.45, 0.3, 0.16), Color(0.7, 0.55, 0.3), Color(0.55, 0.55, 0.55), Color(0.85, 0.85, 0.82)]
const CORTES_H := ["corto", "fade", "tupe", "flequillo", "rizado", "largo", "coleta", "rapado"]
const CORTES_M := ["largo", "melena", "coleta", "trenzas", "corto"]
## [diseño, nombre]: lo que se ve por la calle.
const PRENDAS := ["liso", "liso", "liso", "franjas_finas", "aros_finos", "cuadros_chicos", "tartan", "mangas_contraste", "canesu"]
const PANTALONES := ["274472", "1f2f4f", "3a3a3a", "c2b280", "5a4a3a", "111111", "6b6b70"]
const ROPA := ["ffffff", "111111", "c62828", "1565c0", "2e7d32", "f9a825", "6a1b9a", "455a64", "8d6e63", "ec407a", "00838f", "ef6c00", "9e9e9e"]

## Crea el peatón (sin terminar: `terminar()` cuando ya esté en el árbol).
static func crear(rng: RandomNumberGenerator) -> Dictionary:
	var mujer := rng.randf() < 0.45
	var d := FutbolistaQ.crear(rng.randf_range(1.58, 1.72) if mujer else rng.randf_range(1.66, 1.92), "female" if mujer else "male")
	if d.is_empty():
		return d
	d["mujer"] = mujer
	d["semilla"] = rng.randi()
	return d

## Lo arma cuando ya está en el árbol: medidas, ropa, pelo y paso.
static func terminar(d: Dictionary) -> void:
	if d.is_empty():
		return
	var nodo: Node3D = d["nodo"]
	if not nodo.is_inside_tree():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(d["semilla"])
	FutbolistaQ.terminar(d, false)
	var mujer: bool = d["mujer"]
	var c1 := Color(String(ROPA[rng.randi() % ROPA.size()]))
	var c2 := Color(String(ROPA[rng.randi() % ROPA.size()]))
	var pant := Color(String(PANTALONES[rng.randi() % PANTALONES.size()]))
	var piel := Color(String(PIELES[rng.randi() % PIELES.size()]))
	var pelo_col: Color = PELOS[rng.randi() % PELOS.size()]
	var zapatilla: String = ["ffffff", "111111", "8d6e63", "1565c0"][rng.randi() % 4]
	var kit := {
		"dis": String(PRENDAS[rng.randi() % PRENDAS.size()]),
		"cols": [c1.to_html(false), c2.to_html(false), c2.darkened(0.3).to_html(false), "ffffff", "111111"],
		"trim": 1 if rng.randf() < 0.5 else 0,
		"cuello": 1 if rng.randf() < 0.7 else 2,
		"pant": {"dis": "liso", "c1": pant.to_html(false), "c2": pant.to_html(false)},
		"med": {"dis": "lisas", "c1": pant.to_html(false), "c2": pant.to_html(false)},
		"bot": {"mod": "clasico", "c1": zapatilla, "c2": zapatilla, "c3": "eeeeee"},
		"acc": {},
		"civil": true,
	}
	VestidorQ.vestir_equipacion(d, c1, c2, "liso", piel, pelo_col, pant, pant, true, kit, 0)
	var corte: String = CORTES_M[rng.randi() % CORTES_M.size()] if mujer else CORTES_H[rng.randi() % CORTES_H.size()]
	PeloQ.poner(d, corte, pelo_col, not mujer and rng.randf() < 0.35)
	var ap: AnimationPlayer = d["anim"]
	if ap.has_animation("caminar"):
		ap.play("caminar")
		ap.seek(rng.randf() * ap.current_animation_length, true)
		ap.speed_scale = rng.randf_range(0.9, 1.1)
	## Lejos de la cámara no se dibuja (ni su sombra).
	for mi in nodo.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).visibility_range_end = 220.0
		(mi as MeshInstance3D).visibility_range_end_margin = 20.0
