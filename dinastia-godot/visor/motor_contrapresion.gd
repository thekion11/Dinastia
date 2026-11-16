class_name MotorContrapresion
extends RefCounted
## CONTRAPRESIÓN (16-11-2026, fallo F-01 del informe AAA, cap. 5): «tras la pérdida = ALTO» no cambiaba nada en el motor 3D.
## Causa medida (3 semillas, MotorJugable puro, presión media): (1) alargar la ventana del gatillo de 0,6 a 1,5 s no cambiaba a
## nadie, porque en esos pasos ya saltaba otro gatillo (banda, de espaldas, zona: ~76 % del tiempo de posesión rival), y con
## presión media el segundo presionador ya corría igual; (2) el bloque que mandaba apretar a «los cercanos» pedía estar a menos
## de 9 m del balón sin ser el primero ni el segundo presionador ni defensa: se cumplía 0-4 veces por partido (≤ 0,2 s).
## Ahora, durante `VENTANA` s desde que el rival recupera el balón, el equipo contrapresiona de verdad:
##   · el segundo presionador va AL portador (doble marca), con cualquier nivel de presión;
##   · los `CIERRES` medios o delanteros más cercanos al balón (a menos de `RADIO` m) cierran las líneas de pase hacia los
##     compañeros del portador más próximos (se plantan en la línea, del lado del receptor);
##   · la línea defensiva no recula aunque el portador esté libre (`_linea_defensiva`).
## El precio es el de correr: los que contrapresionan esprintan y gastan aguante (un coste extra en `_coste_aguante` se probó y
## se descartó: con 30 partidos borraba el efecto en el motor de siempre).
## Vale para el motor de siempre y para C4 (que usa nuestra colocación sin balón: `MotorCombinado._sin_flag3` → `_ia_defensa`).
## `SIN_CONTRAPRESION=1` = como antes (para medir).
const VENTANA := 3.0   ## (medido con 30 partidos: 2,5 s y sin morder en el 40 % propio del campo salía peor)
const RADIO := 24.0
const CIERRES := 2
const EN_LINEA := 0.6   ## dónde se planta en la línea portador → receptor (0 = en el portador, 1 = en el receptor)
static var _sin := OS.has_environment("SIN_CONTRAPRESION")

## ¿El equipo (`local`) acaba de perder el balón y juega con «tras la pérdida» ALTO?
static func activa(m: MotorJugable, local: bool) -> bool:
	if _sin or m.poseedor.is_empty() or bool(m.poseedor["es_local"]) == local or m._tac(local, "tras_perdida") < 2:
		return false
	var dt := m.t - float(m._eq_tomo_en[1 if local else 0])
	return dt >= 0.0 and dt < VENTANA

## Destino de `p` en la contrapresión (o `Vector3.INF` si no le toca): el segundo presionador al portador; los cierres, a la línea de pase.
static func objetivo(m: MotorJugable, p: Dictionary, pp: Array) -> Vector3:
	var local := bool(p["es_local"])
	if not activa(m, local):
		return Vector3.INF
	var b := m.balon.position
	var id := String(p.get("id", ""))
	if id != "" and id == String(pp[1]):
		p["correr"] = true
		return b + (m._arco_propio(p) - b).normalized() * 1.2
	var c: Dictionary = _cierres(m, local, pp)
	if not c.has(id):
		return Vector3.INF
	p["correr"] = true
	return c[id]

## {id → punto} de los que cierran líneas de pase; se calcula una vez por paso y por equipo.
static func _cierres(m: MotorJugable, local: bool, pp: Array) -> Dictionary:
	var cache: Dictionary = m.get_meta("contrapresion", {})
	var pid := String(m.poseedor.get("id", ""))   ## (16-11, revisión de F-01) la posesión puede cambiar dentro del mismo paso
	if not is_equal_approx(float(cache.get("t", -1.0)), m.t) or String(cache.get("pid", "")) != pid:
		cache = {"t": m.t, "pid": pid}
	if cache.has(local):
		return cache[local]
	var b := m.balon.position
	var portador := m.pos(m.poseedor)
	var mios: Array = []
	var suyos: Array = []
	for q: Dictionary in m.jugadores:
		if bool(q["por"]):
			continue
		if bool(q["es_local"]) == local:
			var qid := String(q.get("id", ""))
			if qid != String(pp[0]) and qid != String(pp[1]) and not (m._rol(q) in ["DFC", "LD", "LI"]) and m.pos(q).distance_to(b) < RADIO:
				mios.append([m.pos(q).distance_to(b), q])
		elif q != m.poseedor:
			suyos.append([m.pos(q).distance_to(portador), q])
	mios.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
	suyos.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
	var r := {}
	var libres: Array = suyos.slice(0, CIERRES)
	for e: Array in mios.slice(0, CIERRES):
		if libres.is_empty():
			break
		var mio: Dictionary = e[1]
		var yo := m.pos(mio)
		var k := 0
		for i in libres.size():
			if m.pos(libres[i][1] as Dictionary).distance_to(yo) < m.pos(libres[k][1] as Dictionary).distance_to(yo):
				k = i
		r[String(mio.get("id", ""))] = portador.lerp(m.pos(libres[k][1] as Dictionary), EN_LINEA)
		libres.remove_at(k)
	cache[local] = r
	m.set_meta("contrapresion", cache)
	return r
