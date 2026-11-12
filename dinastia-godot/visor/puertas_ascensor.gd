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

const FONDO_CABINA := 1.5    ## metros de fondo que APARENTA la cabina (es un plano con `cabina_ascensor.gdshader`)
const SONIDO_LLEGADA := "notificacion"   ## el timbre al abrirse

## Pone el hueco del ascensor de una planta: `cx` centro, `z` plano de la pared del fondo, `y0` suelo de la planta, `ancho` del hueco.
## `acento`: color del club (franja del suelo de la cabina). `planta`: lo que marca el indicador de encima («2», «-1»); vacío = sin indicador.
static func poner(nodo: Node3D, cx: float, z: float, y0: float, ancho: float, acento := Color(0.1, 0.3, 0.7), planta := "") -> void:
	var marco := PiezasObra._mat(Color(0.16, 0.17, 0.19), 0.4)
	var acero: StandardMaterial3D = Texturas.metal(Color(0.72, 0.74, 0.76), 0.35)
	var alto := 2.3
	## La CABINA, visible con las puertas abiertas (12-11): un plano 1 cm DELANTE de la pared (la pared llega a z−0,04 y en el mismo plano
	## parpadeaba) que DIBUJA una cabina con fondo: espejo, pasamanos, plafón y suelo con la franja del club. Cuelga de un nodo con script
	## para que el fundido de mallas de la calidad mínima no lo toque (igual que las hojas).
	var hueco := CabinaAscensor.new()
	hueco.position = Vector3(cx, y0 + alto / 2.0, z - 0.045)
	hueco.rotation.y = PI   ## el plano mira a −Z, hacia el pasillo
	nodo.add_child(hueco)
	var plano := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(ancho, alto)
	plano.mesh = qm
	plano.name = "CabinaAscensor"
	plano.material_override = _mat_cabina(Vector2(ancho, alto), acento)
	plano.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hueco.add_child(plano)
	if planta != "":
		_indicador(nodo, cx, z, y0 + alto + 0.28, planta)
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

## El material de la cabina: uno por tamaño de hueco y color (todas las plantas de un club lo comparten).
static var _cabinas := {}
static func _mat_cabina(tam: Vector2, acento: Color) -> ShaderMaterial:
	var k := "%s|%s" % [tam, acento.to_html(false)]
	if not _cabinas.has(k):
		var m := ShaderMaterial.new()
		m.shader = load("res://visor/cabina_ascensor.gdshader")
		m.set_shader_parameter("hueco", tam)
		m.set_shader_parameter("fondo", FONDO_CABINA)
		m.set_shader_parameter("acento", acento)
		_cabinas[k] = m
	return _cabinas[k]

## El indicador de planta sobre el dintel: una pantalla negra con la planta en ámbar encendido, como los de verdad.
static func _indicador(nodo: Node3D, cx: float, z: float, y: float, planta: String) -> void:
	PiezasObra._caja(nodo, Vector3(cx, y, z - 0.07), Vector3(0.62, 0.26, 0.06), PiezasObra._mat(Color(0.03, 0.03, 0.04), 0.25), false)
	PiezasObra._caja(nodo, Vector3(cx, y, z - 0.065), Vector3(0.68, 0.32, 0.04), Texturas.metal(Color(0.72, 0.74, 0.76), 0.35), false)
	var l := Label3D.new()
	l.text = "▲ %s ▼" % planta
	l.font_size = 30
	l.pixel_size = 0.006
	l.modulate = Color(1.0, 0.72, 0.2)
	l.outline_size = 0
	l.position = Vector3(cx, y, z - 0.105)
	l.rotation.y = PI
	l.shaded = false
	l.double_sided = false
	l.name = "IndicadorPlanta"
	nodo.add_child(l)

## Abre o cierra las hojas de la planta cuyo suelo está en `y0`. `dur` a mano para las pruebas; devuelve los Tween creados.
static func mover(arbol: SceneTree, y0: float, abrir: bool, dur := -1.0) -> Array[Tween]:
	var tws: Array[Tween] = []
	if arbol == null:
		return tws
	if abrir and dur < 0.0 and not abiertas(arbol, y0) and _hay_hojas(arbol, y0):
		Sonido.toca(SONIDO_LLEGADA, Sonido.Bus.EFECTOS, -6.0)   ## (12-11) el timbre de llegada
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

static func _hay_hojas(arbol: SceneTree, y0: float) -> bool:
	for h: Node in arbol.get_nodes_in_group(GRUPO):
		if h is Node3D and absf(float(h.get_meta("y0", -999.0)) - y0) < 0.5:
			return true
	return false
