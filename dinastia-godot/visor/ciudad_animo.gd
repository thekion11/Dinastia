class_name CiudadAnimo
extends RefCounted
## LA CIUDAD RESPONDE AL CLUB (MEGAPLAN fase 5, originalidad). La ciudad 3D ya
## crecía con la reputación y los socios, pero no se enteraba de cómo iba la
## temporada: daba igual ir primero o estar hundido. Aquí el momento del club
## -puesto en la tabla, racha de las últimas cinco, campeón o descendido- se
## convierte en un ÁNIMO de -1 a 1, y el ánimo se ve en la calle:
##
##  · EUFORIA (campeón o líder en racha): pancartas del club colgadas de las
##    fachadas que miran al estadio, banderas en todo el anillo y el rótulo
##    «🏆 LA CIUDAD ESTÁ DE FIESTA».
##  · BIEN: algunas pancartas.
##  · NORMAL: nada especial (la ciudad de siempre).
##  · MAL: algún grafiti en los bajos y menos color.
##  · CRISIS (descenso o colista en mala racha): persianas metálicas bajadas en
##    los locales, grafitis contra la directiva (frases genéricas, sin nadie
##    real), y el color de la escena se apaga un poco.

const ESTADOS := ["crisis", "mal", "normal", "bien", "euforia"]

## Frases de grafiti: genéricas, contra «la directiva» o de aliento.
const GRAFITIS_MAL := ["¡DESPIERTEN!", "SIN HUEVOS NO HAY GLORIA", "¿Y LA GARRA?", "QUEREMOS JUGADORES"]
const GRAFITIS_CRISIS := ["¡FUERA LA DIRECTIVA!", "VERGÜENZA", "QUE SE VAYAN TODOS", "DEVUELVAN EL ESCUDO", "ESTO NO ES UN CLUB"]

## Calcula el ánimo del club `c` en el mundo `m`:
## {"valor": -1..1, "estado": crisis|mal|normal|bien|euforia, "motivo": texto}.
static func de(m: Mundo, c: Club) -> Dictionary:
	if m == null or c == null:
		return {"valor": 0.0, "estado": "normal", "motivo": ""}
	var liga := m.liga_de(c)
	if liga == null or liga.clubes.size() < 2:
		return {"valor": 0.0, "estado": "normal", "motivo": ""}
	var tabla := liga.tabla()
	var puesto := 1
	for i in tabla.size():
		if tabla[i]["club"] == c:
			puesto = i + 1
	var n := tabla.size()
	var jugadas := int(tabla[puesto - 1]["pj"])
	## La racha: las últimas cinco de liga, +1 ganar, 0 empatar, -1 perder.
	var racha := 0.0
	var vistos := 0
	for k in range(liga.historial.size() - 1, -1, -1):
		for r: Dictionary in liga.historial[k]:
			var gl := int(r["gl"])
			var gv := int(r["gv"])
			if r["local"] == c:
				racha += signf(float(gl - gv))
				vistos += 1
			elif r["visita"] == c:
				racha += signf(float(gv - gl))
				vistos += 1
		if vistos >= 5:
			break
	return evaluar(puesto, n, jugadas, liga.jornadas(), racha, vistos, liga.plazas_descenso, not liga.quedan_jornadas())

## La cuenta pura (se prueba sin mundo). `racha`: suma de las últimas
## `vistos` (+1/0/-1). `terminada`: la liga ya no tiene jornadas.
static func evaluar(puesto: int, n: int, jugadas: int, total: int, racha: float, vistos: int, descenso: int, terminada: bool) -> Dictionary:
	if jugadas == 0:
		return {"valor": 0.0, "estado": "normal", "motivo": "La temporada aún no empezó."}
	## El puesto, de +1 (primero) a -1 (último); pesa más cuanto más avanzada.
	var p := 1.0 - 2.0 * float(puesto - 1) / maxf(1.0, float(n - 1))
	var peso_tabla := clampf(float(jugadas) / maxf(1.0, float(total)), 0.25, 1.0)
	var r := racha / maxf(1.0, float(vistos))
	var v := clampf(p * 0.6 * peso_tabla + r * 0.5, -1.0, 1.0)
	var motivo := "%dº de %d" % [puesto, n]
	if vistos > 0:
		motivo += ", %+d en las últimas %d" % [int(racha), vistos]
	if terminada and puesto == 1:
		v = 1.0
		motivo = "¡Campeones!"
	elif terminada and puesto > n - descenso:
		v = -1.0
		motivo = "Descendidos."
	elif puesto > n - descenso and jugadas >= total * 2 / 3:
		v = minf(v, -0.6)
		motivo += " (en zona de descenso)"
	var est := "normal"
	if v >= 0.7:
		est = "euforia"
	elif v >= 0.3:
		est = "bien"
	elif v <= -0.7:
		est = "crisis"
	elif v <= -0.3:
		est = "mal"
	return {"valor": v, "estado": est, "motivo": motivo}

## Lo pinta sobre la ciudad ya construida. `frentes`: huellas (Rect2 en XZ) de
## los edificios de los frentes urbanos; `estadio`: dónde está.
static func montar(raiz: Node3D, animo: Dictionary, frentes: Array, estadio: Vector3, c1: Color, c2: Color) -> Dictionary:
	var est := String(animo.get("estado", "normal"))
	var nodo := Node3D.new()
	nodo.name = "AnimoCiudad"
	raiz.add_child(nodo)
	var cuenta := {"pancartas": 0, "persianas": 0, "grafitis": 0}
	if est == "normal" or frentes.is_empty():
		return cuenta
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var parte := {"euforia": 1.0, "bien": 0.45, "mal": 0.3, "crisis": 0.75}[est] as float
	var i := 0
	for r: Rect2 in frentes:
		i += 1
		if rng.randf() > parte:
			continue
		## La cara del edificio que mira al estadio: el punto del borde más
		## cercano, y la normal hacia fuera.
		var centro := r.get_center()
		var hacia := Vector2(estadio.x, estadio.z) - centro
		var cara := Vector2.ZERO
		var n := Vector2.ZERO
		if absf(hacia.x) / maxf(1.0, r.size.x) > absf(hacia.y) / maxf(1.0, r.size.y):
			n = Vector2(signf(hacia.x), 0)
			cara = Vector2(centro.x + n.x * (r.size.x * 0.5 + 0.25), centro.y)
		else:
			n = Vector2(0, signf(hacia.y))
			cara = Vector2(centro.x, centro.y + n.y * (r.size.y * 0.5 + 0.25))
		var giro := atan2(n.x, n.y)
		var ancho := minf(r.size.x if n.x == 0.0 else r.size.y, 14.0)
		if est == "euforia" or est == "bien":
			_pancarta(nodo, Vector3(cara.x, 0, cara.y), giro, ancho, c1 if i % 2 == 0 else c2, c2 if i % 2 == 0 else c1)
			cuenta["pancartas"] += 1
		else:
			if est == "crisis":
				_persiana(nodo, Vector3(cara.x, 0, cara.y), giro, ancho)
				cuenta["persianas"] += 1
			if rng.randf() < (0.7 if est == "crisis" else 1.0):
				var frases: Array = GRAFITIS_CRISIS if est == "crisis" else GRAFITIS_MAL
				_grafiti(nodo, Vector3(cara.x, 0, cara.y), giro, String(frases[rng.randi() % frases.size()]), rng)
				cuenta["grafitis"] += 1
	return cuenta

## Una pancarta vertical colgada de la fachada, a dos colores.
static func _pancarta(padre: Node3D, base: Vector3, giro: float, ancho: float, col: Color, franja: Color) -> void:
	var w := clampf(ancho * 0.45, 2.5, 5.0)
	var tela := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(w, 7.0)
	tela.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.9
	tela.material_override = m
	tela.position = base + Vector3(0, 6.2, 0) + Vector3(sin(giro), 0, cos(giro)) * 0.12
	tela.rotation.y = giro
	padre.add_child(tela)
	var banda := MeshInstance3D.new()
	var qb := QuadMesh.new()
	qb.size = Vector2(w, 1.2)
	banda.mesh = qb
	var mb := m.duplicate() as StandardMaterial3D
	mb.albedo_color = franja
	banda.material_override = mb
	banda.position = tela.position + Vector3(sin(giro), 0, cos(giro)) * 0.03
	banda.rotation.y = giro
	padre.add_child(banda)

## Una persiana metálica bajada en el local de abajo.
static func _persiana(padre: Node3D, base: Vector3, giro: float, ancho: float) -> void:
	var p := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(clampf(ancho * 0.6, 3.0, 8.0), 3.2, 0.15)
	p.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.48, 0.49, 0.5)
	m.metallic = 0.6
	m.roughness = 0.55
	p.material_override = m
	p.position = base + Vector3(0, 1.6, 0) + Vector3(sin(giro), 0, cos(giro)) * 0.08
	p.rotation.y = giro
	padre.add_child(p)

## Un grafiti: texto pintado en la pared (no mira a la cámara).
static func _grafiti(padre: Node3D, base: Vector3, giro: float, texto: String, rng: RandomNumberGenerator) -> void:
	var l := Label3D.new()
	l.text = texto
	l.font_size = 64
	l.pixel_size = 0.018
	l.outline_size = 6
	l.outline_modulate = Color(0, 0, 0, 0.6)
	l.modulate = [Color(0.95, 0.2, 0.2), Color(0.1, 0.1, 0.1), Color(0.95, 0.85, 0.2), Color(0.3, 0.6, 1.0)][rng.randi() % 4]
	l.double_sided = true
	l.position = base + Vector3(0, 1.8, 0) + Vector3(sin(giro), 0, cos(giro)) * 0.3
	l.rotation.y = giro
	l.rotation.z = rng.randf_range(-0.08, 0.08)
	padre.add_child(l)
