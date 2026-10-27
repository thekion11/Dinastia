class_name PanelMando
extends Control
## UNA PANTALLA DEL CENTRO DE MANDO (27-10-2026). Se dibuja a mano (rectángulos y texto) dentro de un SubViewport
## que `SubsueloMando` pega en la pared de la sala de control. Tres modos, del modelo `RedesCiudad`:
##  · «mapa»: sinóptico de los 25 sectores (luz, agua, inundación) con los edificios conectados.
##  · «curvas»: generación contra demanda de las últimas 24 horas, depósito, lluvia, viento y gas.
##  · «alertas»: registro de incidencias, estado del evento del apagón y tabla de edificios.

const FONDO := Color(0.015, 0.04, 0.06)
const LINEA := Color(0.1, 0.3, 0.36)
const TITULO := Color(0.45, 0.9, 1.0)
const OK := Color(0.1, 0.75, 0.4)
const MAL := Color(0.9, 0.15, 0.12)
const AVISO := Color(0.95, 0.75, 0.15)
const AGUA := Color(0.2, 0.5, 0.95)
const TEXTO := Color(0.82, 0.92, 0.95)
const GRIS := Color(0.45, 0.55, 0.6)
const MAPA_X := 24.0
const MAPA_Y := 72.0
const MAPA_LADO := 480.0

var modelo: RedesCiudad
var modo := "mapa"
var sector_entrada := Vector2i(2, 2)

func _t(p: Vector2, texto: String, tam: int = 18, col: Color = TEXTO, ancho: float = -1.0, alinea: int = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(ThemeDB.fallback_font, p, texto, alinea, ancho, tam, col)

func _cabecera(titulo: String, sub: String) -> void:
	draw_rect(Rect2(0, 0, size.x, 52), Color(0.03, 0.12, 0.16))
	draw_rect(Rect2(0, 50, size.x, 2), TITULO)
	_t(Vector2(24, 35), titulo, 26, TITULO)
	_t(Vector2(size.x - 424, 35), sub, 18, GRIS, 400.0, HORIZONTAL_ALIGNMENT_RIGHT)
	## Reloj del sistema y el punto de «en vivo» que parpadea.
	var vivo := (Time.get_ticks_msec() / 800) % 2 == 0
	draw_circle(Vector2(size.x - 712, 29), 6.0, MAL if vivo else Color(0.3, 0.05, 0.05))
	_t(Vector2(size.x - 700, 36), "EN VIVO · %02d:00" % modelo.hora_dia, 16, TEXTO)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), FONDO)
	if modelo == null:
		return
	match modo:
		"curvas":
			_curvas()
		"alertas":
			_alertas()
		_:
			_mapa()

# ============================================================================ MAPA

func _punto(pos: Vector3) -> Vector2:
	return Vector2(MAPA_X + (pos.x + 1375.0) / 2750.0 * MAPA_LADO, MAPA_Y + (pos.z + 1375.0) / 2750.0 * MAPA_LADO)

func _mapa() -> void:
	_cabecera("MAPA SINÓPTICO · REDES", "5×5 sectores · luz · agua · drenaje")
	var celda := MAPA_LADO / 5.0
	for sec in RedesCiudad.sectores():
		var r := Rect2(MAPA_X + float(sec.x) * celda, MAPA_Y + float(sec.y) * celda, celda - 3.0, celda - 3.0)
		var luz := modelo.hay_luz(sec)
		draw_rect(r, Color(0.04, 0.26, 0.17) if luz else Color(0.4, 0.05, 0.05))
		if bool(modelo.inundado.get(sec, false)):
			draw_rect(r, Color(0.1, 0.3, 0.9, 0.55))
		if not modelo.hay_agua(sec):
			draw_rect(r, AVISO, false, 3.0)
		if sec == sector_entrada:
			draw_rect(r.grow(-6.0), TITULO, false, 2.0)
		_t(r.position + Vector2(8, 20), "%d·%d" % [sec.x, sec.y], 15, GRIS)
		_t(r.position + Vector2(8, celda - 14.0), "%.1f MW" % (modelo.demanda_sector(sec) * RedesCiudad.curva(modelo.hora_dia)), 14, TEXTO)
	for ed: Dictionary in modelo.edificios:
		var p := _punto(ed["pos"])
		var est := modelo.estado_edificio(ed)
		var col := OK if bool(est["luz"]) else MAL
		if String(ed["uso"]) == "hospital":
			draw_rect(Rect2(p - Vector2(8, 3), Vector2(16, 6)), Color.WHITE)
			draw_rect(Rect2(p - Vector2(3, 8), Vector2(6, 16)), Color.WHITE)
		else:
			draw_circle(p, 6.0, col)
			draw_arc(p, 8.0, 0, TAU, 14, Color.WHITE if bool(est["agua"]) else AGUA, 2.0)
	var x := MAPA_X + MAPA_LADO + 40.0
	_t(Vector2(x, 90), "BALANCE ELÉCTRICO", 20, TITULO)
	_barra(Rect2(x, 104, 420, 22), modelo.generacion / 60.0, OK, "Generación %.1f MW" % modelo.generacion)
	_barra(Rect2(x, 140, 420, 22), modelo.demanda / 60.0, AVISO, "Demanda %.1f MW" % modelo.demanda)
	_t(Vector2(x, 200), "RED DE AGUA", 20, TITULO)
	_barra(Rect2(x, 214, 420, 22), modelo.agua_nivel / RedesCiudad.AGUA_DEPOSITO, AGUA, "Depósito %d%%" % roundi(modelo.agua_nivel / RedesCiudad.AGUA_DEPOSITO * 100.0))
	_t(Vector2(x, 280), "CLIMA", 20, TITULO)
	_t(Vector2(x, 306), "Viento %d%% · Lluvia %.0f mm/h" % [roundi(modelo.viento * 100.0), modelo.lluvia], 18)
	_t(Vector2(x, 360), "LEYENDA", 20, TITULO)
	draw_rect(Rect2(x, 372, 22, 16), Color(0.04, 0.26, 0.17))
	_t(Vector2(x + 30, 386), "con luz", 16)
	draw_rect(Rect2(x + 130, 372, 22, 16), Color(0.4, 0.05, 0.05))
	_t(Vector2(x + 160, 386), "sin luz", 16)
	draw_rect(Rect2(x + 260, 372, 22, 16), Color(0.1, 0.3, 0.9, 0.8))
	_t(Vector2(x + 290, 386), "inundado", 16)
	draw_rect(Rect2(x, 400, 22, 16), AVISO, false, 3.0)
	_t(Vector2(x + 30, 414), "sin presión de agua", 16)
	draw_circle(Vector2(x + 262, 408), 6.0, OK)
	_t(Vector2(x + 275, 414), "edificio conectado", 16)
	_t(Vector2(x, 470), "%d edificios conectados · %d aislados" % [modelo.edificios.size(), _aislados()], 17, GRIS)

func _aislados() -> int:
	var n := 0
	for ed: Dictionary in modelo.edificios:
		if bool(ed["aislado"]):
			n += 1
	return n

func _barra(r: Rect2, f: float, col: Color, texto: String) -> void:
	draw_rect(r, Color(0.06, 0.12, 0.15))
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(f, 0.0, 1.0), r.size.y)), col)
	draw_rect(r, LINEA, false, 1.0)
	_t(r.position + Vector2(8, 17), texto, 15, Color.WHITE)

# ============================================================================ CURVAS

func _curvas() -> void:
	_cabecera("CURVAS DE CARGA · 24 H", "generación frente a demanda")
	var a := Rect2(50, 90, 640, 380)
	draw_rect(a, Color(0.03, 0.08, 0.1))
	for k in 5:
		var y := a.position.y + a.size.y * float(k) / 4.0
		draw_line(Vector2(a.position.x, y), Vector2(a.end.x, y), LINEA, 1.0)
		_t(Vector2(8, y + 5), "%d" % roundi(60.0 * (1.0 - float(k) / 4.0)), 14, GRIS)
	var h := modelo.historial
	var n := h.size()
	var ancho := a.size.x / float(RedesCiudad.HISTORIAL_MAX)
	var previo := Vector2.INF
	for i in n:
		var m: Dictionary = h[i]
		var x := a.position.x + float(i) * ancho
		var dh := a.size.y * clampf(float(m["dem"]) / 60.0, 0.0, 1.0)
		draw_rect(Rect2(x + 2.0, a.end.y - dh, ancho - 4.0, dh), AVISO if int(m["sin_luz"]) == 0 else MAL)
		var p := Vector2(x + ancho * 0.5, a.end.y - a.size.y * clampf(float(m["gen"]) / 60.0, 0.0, 1.0))
		if previo != Vector2.INF:
			draw_line(previo, p, OK, 3.0)
		draw_circle(p, 3.5, OK)
		previo = p
	_t(Vector2(a.position.x, a.end.y + 28), "▇ demanda   ▬ generación   (rojo: hubo sectores sin luz)", 15, GRIS)
	var x := 730.0
	_t(Vector2(x, 100), "DEPÓSITO DE AGUA", 18, TITULO)
	_barra(Rect2(x, 112, 260, 24), modelo.agua_nivel / RedesCiudad.AGUA_DEPOSITO, AGUA, "%d%%" % roundi(modelo.agua_nivel / RedesCiudad.AGUA_DEPOSITO * 100.0))
	_t(Vector2(x, 178), "LLUVIA", 18, TITULO)
	_barra(Rect2(x, 190, 260, 24), modelo.lluvia / 25.0, AGUA, "%.0f mm/h" % modelo.lluvia)
	_t(Vector2(x, 256), "VIENTO", 18, TITULO)
	_barra(Rect2(x, 268, 260, 24), modelo.viento, OK, "%d%%" % roundi(modelo.viento * 100.0))
	_t(Vector2(x, 334), "GASOLINERAS", 18, TITULO)
	var i := 0
	for id in modelo.gas:
		var f := float(modelo.gas[id]) / RedesCiudad.GAS_DEPOSITO
		_barra(Rect2(x, 346 + float(i) * 30.0, 260, 24), f, OK if f > 0.25 else MAL, "Gasolinera %d · %d%%" % [int(id) + 1, roundi(f * 100.0)])
		i += 1
	_t(Vector2(x, 466), "Sectores sin luz: %d de 25" % roundi((1.0 - modelo.fraccion_luz()) * 25.0), 17, TEXTO)

# ============================================================================ ALERTAS

func _alertas() -> void:
	_cabecera("ALERTAS Y EDIFICIOS", "registro de incidencias · conexiones")
	var ev := modelo.evento
	var y := 82.0
	if ev.activo:
		var parpadeo := (Time.get_ticks_msec() / 600) % 2 == 0
		draw_rect(Rect2(24, y, 470, 92), Color(0.5, 0.05, 0.05) if parpadeo else Color(0.3, 0.03, 0.03))
		_t(Vector2(36, y + 28), "⚠ APAGÓN DE TORMENTA", 24, Color.WHITE)
		_t(Vector2(36, y + 54), ("[✔] " if ev.rearmado else "[  ] ") + "1. Rearmar el disyuntor (galería eléctrica)", 16, Color.WHITE)
		_t(Vector2(36, y + 78), "[  ] 2. Reconectar la red (botón verde)", 16, Color.WHITE)
		y += 108.0
	else:
		draw_rect(Rect2(24, y, 470, 40), Color(0.04, 0.2, 0.14))
		_t(Vector2(36, y + 27), "SIN INCIDENCIAS GRAVES · red estable", 18, OK)
		y += 56.0
	_t(Vector2(24, y + 4), "REGISTRO", 18, TITULO)
	y += 26.0
	for linea in modelo.registro:
		if y > 540.0:
			break
		_t(Vector2(24, y), String(linea), 15, AVISO if String(linea).contains("SIN LUZ") or String(linea).contains("disyuntor") else TEXTO, 480.0)
		y += 22.0
	var x := 530.0
	_t(Vector2(x, 90), "EDIFICIO", 15, GRIS)
	_t(Vector2(x + 250, 90), "kW", 15, GRIS)
	_t(Vector2(x + 310, 90), "LUZ", 15, GRIS)
	_t(Vector2(x + 360, 90), "AGUA", 15, GRIS)
	draw_line(Vector2(x, 96), Vector2(size.x - 24, 96), LINEA, 1.0)
	var fila := 0
	for ed: Dictionary in modelo.edificios:
		if fila >= 19:
			break
		var py := 120.0 + float(fila) * 23.0
		var est := modelo.estado_edificio(ed)
		_t(Vector2(x, py), String(ed["nombre"]), 15, MAL if bool(ed["aislado"]) else TEXTO, 240.0)
		_t(Vector2(x + 250, py), str(int(est["kw"])), 15)
		draw_circle(Vector2(x + 322, py - 5), 6.0, OK if bool(est["luz"]) else MAL)
		draw_circle(Vector2(x + 376, py - 5), 6.0, AGUA if bool(est["agua"]) else MAL)
		if bool(ed["generador"]):
			_t(Vector2(x + 400, py), "GEN", 12, AVISO)
		elif bool(ed["aislado"]):
			_t(Vector2(x + 400, py), "AISL", 12, MAL)
		fila += 1
