class_name MedirHudAB
extends RefCounted
## (17-11) EL COSTE DEL HUD DE TV EN EL LIENZO 2D, LIMPIO (lo usa `medir_partido.gd`). Las llamadas 3D y los triángulos varían
## mucho entre dos corridas (el partido no va igual con llvmpipe), así que con HUD_AB=1 el HUD (marcador, radar y nombres) se
## enciende y se apaga en tandas de 10 fotogramas DENTRO de la misma corrida y se comparan las llamadas de dibujo del lienzo 2D
## con y sin él (se descartan los 2 primeros fotogramas de cada tanda). Sirve igual con el HUD de antes (caja de texto y radar).

static var _con: Array[float] = []
static var _sin: Array[float] = []

## Devuelve las llamadas 2D de este fotograma; con HUD_AB=1, además alterna el HUD y al final imprime «HUD_AB».
static func leer(vista: Control, i: int, total: int) -> float:
	var v := float(vista.get_viewport().get_render_info(Viewport.RENDER_INFO_TYPE_CANVAS, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME))
	if OS.get_environment("HUD_AB") == "":
		return v
	var encendido := (i / 10) % 2 == 0
	if i % 10 >= 2:
		(_con if encendido else _sin).append(v)
	var sig := ((i + 1) / 10) % 2 == 0
	for c: Variant in [vista.get("_caja_marcador"), vista.get("_radar"), vista.get_node_or_null("NombresTV")]:
		if c != null and is_instance_valid(c):
			(c as CanvasItem).visible = sig
	if i == total - 1:
		var m := func(a: Array[float]) -> float: return 0.0 if a.is_empty() else a.reduce(func(s: float, x: float) -> float: return s + x, 0.0) / a.size()
		print("HUD_AB calidad=%d  lienzo2d con HUD=%.1f  sin HUD=%.1f  coste=%.1f llamadas" % [Calidad.elegida, m.call(_con), m.call(_sin), m.call(_con) - m.call(_sin)])
	return v
