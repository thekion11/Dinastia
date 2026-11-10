class_name PuertasAscensor
extends RefCounted
## LAS PUERTAS DEL ASCENSOR DEL CLUB (10-11, reestructuración «solo club», paso 2). Antes eran una plancha de acero fija. Ahora cada planta tiene un
## MARCO oscuro, un FONDO de cabina iluminado y DOS HOJAS que se abren al llegar el ascensor (se recogen hacia los lados) y se vuelven a cerrar
## unos segundos después o cuando alguien sale de viaje. Todo visual y sin choque. `AscensorViaje` las maneja con `mover`.
const GRUPO := "hoja_ascensor"
const SEG_ABRIR := 0.6
const SEG_CERRAR := 0.45
const SEG_ABIERTO := 3.0     ## cuánto se quedan abiertas tras llegar
const RECOGIDA := 0.12       ## escala en x de una hoja recogida

## Pone el hueco del ascensor de una planta: `cx` centro, `z` plano de la pared del fondo, `y0` suelo de la planta, `ancho` del hueco.
static func poner(nodo: Node3D, cx: float, z: float, y0: float, ancho: float) -> void:
	var marco := PiezasObra._mat(Color(0.16, 0.17, 0.19), 0.4)
	var acero: StandardMaterial3D = Texturas.metal(Color(0.72, 0.74, 0.76), 0.35)
	var cabina := PiezasObra._mat_unico(Color(0.9, 0.86, 0.74), 0.7)
	cabina.emission_enabled = true
	cabina.emission = Color(0.95, 0.85, 0.6)
	cabina.emission_energy_multiplier = 0.6
	var alto := 2.3
	## El fondo de la cabina, visible con las puertas abiertas: 1 cm DELANTE de la pared (la pared llega a z−0,04; antes la cabina estaba dentro
	## de ella con su cara a z−0,04 en el MISMO plano y, con las puertas abiertas, las dos se peleaban por el z-buffer: parpadeo).
	PiezasObra._caja(nodo, Vector3(cx, y0 + alto / 2.0, z - 0.045), Vector3(ancho, alto, 0.01), cabina, false)
	for lado: float in [-1.0, 1.0]:
		PiezasObra._caja(nodo, Vector3(cx + lado * (ancho / 2.0 + 0.04), y0 + (alto + 0.1) / 2.0, z - 0.09), Vector3(0.08, alto + 0.1, 0.12), marco, false)
	PiezasObra._caja(nodo, Vector3(cx, y0 + alto + 0.05, z - 0.09), Vector3(ancho + 0.16, 0.1, 0.12), marco, false)
	## Dos hojas: el pivote está en el borde EXTERIOR, así al encogerse en x se recogen contra la jamba.
	for lado: float in [-1.0, 1.0]:
		var pivote := HojaAscensor.new()   ## con script: el fundido de mallas la deja suelta
		pivote.position = Vector3(cx + lado * ancho / 2.0, y0, z - 0.08)
		pivote.add_to_group(GRUPO)
		pivote.set_meta("y0", y0)
		nodo.add_child(pivote)
		PiezasObra._caja(pivote, Vector3(-lado * ancho / 4.0, alto / 2.0, 0.0), Vector3(ancho / 2.0, alto, 0.06), acero, false)
		PiezasObra._caja(pivote, Vector3(-lado * (ancho / 2.0 - 0.03), alto / 2.0, -0.04), Vector3(0.02, alto - 0.1, 0.02), marco, false)   ## junta central

## Abre o cierra las hojas de la planta cuyo suelo está en `y0`. `dur` a mano para las pruebas; devuelve los Tween creados.
static func mover(arbol: SceneTree, y0: float, abrir: bool, dur := -1.0) -> Array[Tween]:
	var tws: Array[Tween] = []
	if arbol == null:
		return tws
	for h: Node in arbol.get_nodes_in_group(GRUPO):
		if not (h is Node3D) or absf(float(h.get_meta("y0", -999.0)) - y0) > 0.5:
			continue
		var n := h as Node3D
		var destino := RECOGIDA if abrir else 1.0
		var t := dur if dur >= 0.0 else (SEG_ABRIR if abrir else SEG_CERRAR)
		if h.has_meta("tween"):
			var viejo: Tween = h.get_meta("tween")
			if viejo != null and viejo.is_valid():
				viejo.kill()
		var tw := n.create_tween()
		tw.tween_property(n, "scale:x", destino, t).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		h.set_meta("tween", tw)
		tws.append(tw)
	return tws

## Las hojas de esa planta están (casi) abiertas.
static func abiertas(arbol: SceneTree, y0: float) -> bool:
	for h: Node in arbol.get_nodes_in_group(GRUPO):
		if h is Node3D and absf(float(h.get_meta("y0", -999.0)) - y0) < 0.5:
			return (h as Node3D).scale.x < 0.5
	return false
