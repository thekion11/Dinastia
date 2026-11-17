class_name HudTV
extends RefCounted
## EL HUD DE TV DEL PARTIDO EN EL ESTADIO (17-11, puntos 4-6 de `COMPARACION_REFERENCIAS_PARTIDO_2026-11-16.md`): monta en
## `VistaEstadio` el marcador de televisión (`MarcadorTV`), los nombres y aros sobre el campo (`NombresTV`, solo con el motor) y deja
## el radar (`RadarPartido`) con el balón, los colores de los clubes y el que manejas. Informe: `docs/04_auditorias/HUD_TV_2026-11-17.md`.

## Devuelve el marcador (la vista lo guarda en `_caja_marcador`; su `etiqueta` oculta es el `_marcador` de texto de siempre).
static func montar(vista: Control, partido: Partido, motor: Node, balon: Node3D, radar: RadarPartido) -> MarcadorTV:
	var m := MarcadorTV.poner(vista, partido.local, partido.visita)
	if motor != null:
		NombresTV.poner(vista)
	if radar != null:
		radar.balon = balon
		radar.motor = motor
		var par := colores_distintos(partido.local, partido.visita)
		radar.color_local = par[0]
		radar.color_visita = par[1]
		colocar_radar(vista, radar)
		## Al girar el teléfono (o cambiar la ventana) se vuelve a colocar.
		vista.resized.connect(func() -> void:
			if is_instance_valid(radar):
				colocar_radar(vista, radar))
	return m

## EL PARTIDO DE LA RUTA (`PartidoJugable`, 3D en un `SubViewport` a la resolución reducida del móvil): los nombres, aros y el
## triángulo del que manejas en 2D (sustituyen al triángulo y al aro 3D de `MarcadorJugador`, que salían pixelados y el triángulo tapaba
## el centro de abajo) y el radar ARRIBA AL CENTRO (abajo están el mando táctil, la ficha y la ayuda). Los nombres van justo encima del
## 3D y debajo de todo el HUD y de los botones táctiles. Devuelve el radar (va en el `_hud` de la pantalla: se esconde con él).
static func montar_jugable(pj: Control, motor: Node, l: Club, v: Club) -> RadarPartido:
	var n := NombresTV.poner(pj)
	pj.call_deferred("_ver_rotulos", true)   ## apaga los 22 rótulos 3D (pixelados en el móvil): `_ver_rotulos` ya mira si hay `NombresTV`
	n.triangulo = true
	n.z_index = 0
	for h in pj.get_children():
		if h is SubViewportContainer:
			pj.move_child(n, h.get_index() + 1)
			break
	var r := RadarPartido.new()
	r.name = "RadarPartido"
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.motor = motor
	r.siempre_usuario = true
	r.jugadores = motor.get("jugadores")
	r.balon = motor.get("balon") as Node3D
	var par := colores_distintos(l, v)
	r.color_local = par[0]
	r.color_visita = par[1]
	pj.add_child(r)
	var f := HudTactil.f(pj) * 0.85   ## algo menor que el del estadio: arriba al centro comparte la franja con el marcador y tus números
	r.escala = f
	r.anchor_left = 0.5
	r.anchor_right = 0.5
	r.offset_left = -105.0 * f
	r.offset_right = 105.0 * f
	r.offset_top = 14.0 * f
	r.offset_bottom = 14.0 * f + 136.0 * f
	return r

## Los colores de los dos clubes en el radar: el fuerte de cada uno, y si se parecen (dos clubes de blanco, o el verde del visitante
## que pasa a su blanco), el visitante prueba sus otros colores y, si ninguno vale, el local el suyo; en último caso, blanco y negro.
static func colores_distintos(l: Club, v: Club) -> Array[Color]:
	var cl: Array[Color] = [MarcadorTV.color_vivo(l)]
	var cv: Array[Color] = [MarcadorTV.color_vivo(v)]
	if l != null:
		cl.append(MarcadorTV.color_vivo(l, true))
	if v != null:
		cv.append(MarcadorTV.color_vivo(v, true))
		cv.append(_legible(Color(v.color1)))
	for a: Color in cl:
		for b: Color in cv:
			if not _parecidos(a, b):
				return [a, b]
	return [Color.WHITE, Color(0.12, 0.12, 0.14)]

static func _legible(c: Color) -> Color:
	if c.v < 0.55:
		c.v = 0.55
	return c

static func _parecidos(a: Color, b: Color) -> bool:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length() < 0.25

## ABAJO AL CENTRO (como en FC Mobile), justo encima de la barra de estrategias (`BarraEstrategias`, a 64 px del borde), con el tamaño
## del HUD del móvil (`HudTactil.f`). Con controles táctiles (abajo van el stick y los botones de acción) sube ARRIBA al centro, bajo
## la franja del marcador, para no tapar el mando.
static func colocar_radar(vista: Control, radar: RadarPartido) -> void:
	var f := HudTactil.f(vista)
	radar.escala = f
	var w := 210.0 * f
	var h := 136.0 * f
	radar.anchor_left = 0.5
	radar.anchor_right = 0.5
	radar.offset_left = -w * 0.5
	radar.offset_right = w * 0.5
	if HudTactil.activo(vista):
		radar.anchor_top = 0.0
		radar.anchor_bottom = 0.0
		radar.offset_top = 64.0 * f
		radar.offset_bottom = 64.0 * f + h
	else:
		var abajo := 64.0 + 48.0 * f
		radar.anchor_top = 1.0
		radar.anchor_bottom = 1.0
		radar.offset_top = -abajo - h
		radar.offset_bottom = -abajo
