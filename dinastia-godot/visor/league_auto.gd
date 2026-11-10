class_name LeagueAuto
extends RefCounted
## LAS ANIMACIONES INTERMEDIAS DE LEAGUE-SOCCER (10-11-2026, fase 4c de `docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md`;
## Apache 2.0). Copia de `GenerateAutoAnims` (L onthepitch/player/humanoid/animcollection.cpp): para cada par de plantillas
## (de entrada y de salida) y 9 direcciones, si la combinación es legal según sus reglas, un clip de 25 cuadros que pasa de la
## una a la otra (cada hueso mezclado con la curva del original) girando el cuerpo hacia la nueva dirección; y su espejo.
## Los DATOS de todas salen al cargar (`generar`, baratos) y entran en la elección como cualquier otro clip; la ANIMACIÓN se
## construye solo la primera vez que se elige (`construir`), así no hay cientos de clips sin usar ni un tirón al empezar.
## Sin el «inclinarse hacia la curva» del original (≤ 2°). `LS_AUTO=0` las quita de la elección.

static var activas := OS.get_environment("LS_AUTO") != "0"
const CUADROS := 25
const MARGEN := 0.01
const ANGULOS := [0.0, 0.25, -0.25, 0.5, -0.5, 0.75, -0.75, 0.99, -0.99]   ## L GetAngle(direction), en π

## Velocidad escalonada → número (L GetVelocityID): parado 0, trote 1, trote rápido 2, carrera 3.
static func id_vel(v: float) -> int:
	return {0.0: 0, 3.5: 1, 5.0: 2, 8.0: 3}.get(LeagueMovimiento.rango(v), 0)

## ¿Es legal la intermedia de `t1` a `t2` en la dirección `a` (rad)? Las reglas activas del original, en su orden.
static func legal(t1: Dictionary, t2: Dictionary, a: float) -> bool:
	var vi := id_vel(float(t1["v_entra"]))
	var vo := id_vel(float(t2["v_sale"]))
	var nat := LeagueMovimiento.nativo()   ## (C++: `league_legal`, misma cuenta)
	if nat != null:
		return nat.league_legal(vi, vo, float(t2["cuerpo_sale"]), float(t1["cuerpo_ini"]), a)
	return legal_gd(vi, vo, float(t2["cuerpo_sale"]), float(t1["cuerpo_ini"]), a)

static func legal_gd(vi: int, vo: int, cuerpo_sale: float, cuerpo_ini: float, a: float) -> bool:
	if vo - vi > 1:
		return false   ## aceleración máxima
	if roundi(vo * cos(a) - vi) < -3:
		return false   ## frenada máxima (dar la vuelta no es «mantener la velocidad»)
	if vi == 3 and vo == 1 and (absf(cuerpo_sale) > 0.25 * PI + MARGEN or absf(a) > 0.25 * PI + MARGEN):
		return false   ## de carrera a trote, ni de espaldas ni girando mucho
	if vi > 0 and vo > 0 and absf(a) > 0.5 * PI + MARGEN:
		return false
	if vi + vo > 4 and absf(a) > 0.25 * PI + MARGEN:
		return false   ## carrera con carrera o con trote rápido: giros pequeños
	var delta_cuerpo := wrapf(cuerpo_sale - cuerpo_ini, -PI, PI)
	if absf(a + delta_cuerpo) > PI + MARGEN:
		return false   ## no girar más de media vuelta (para eso está el camino corto)
	return true

## Los datos de todas las intermedias legales (y sus espejos), como los de `LeagueMovimiento.clips()`.
static func generar(plantillas: Dictionary) -> Array:
	var sal: Array = []
	var nombres: Array = []
	for n: String in plantillas:
		if not n.ends_with("_espejo"):
			nombres.append(n)
	for n1: String in nombres:
		for n2: String in nombres:
			for f: float in ANGULOS:
				var a := f * PI
				var t1: Dictionary = plantillas[n1]
				var t2: Dictionary = plantillas[n2]
				if not legal(t1, t2, a):
					continue
				for espejo in [false, true]:
					var s := -1.0 if espejo else 1.0
					var c := {"nombre": "ls_auto__%s__%s__%d%s" % [n1.trim_prefix("ls_templates__"), n2.trim_prefix("ls_templates__"),
							roundi(f * 180.0), "_espejo" if espejo else ""],
						"entra": t1["entra"], "sale": t2["sale"], "ang": a * s, "cuerpo": wrapf(a + float(t2["cuerpo"]), -PI, PI) * s,
						"cuerpo_ini": float(t1["cuerpo_ini"]) * s, "cuerpo_sale": float(t2["cuerpo_sale"]) * s, "reposo": 1,
						"largo": (CUADROS - 1) / 100.0, "pie": "I" if espejo else "D", "pie_sale": "D" if espejo else "I",
						"auto": [n1 + ("_espejo" if espejo else ""), n2 + ("_espejo" if espejo else ""), a * s,
							float(t1["v_entra"]), float(t2["v_sale"])]}
					sal.append(c)
	return sal

## `curve(x, bias)` del original: de lineal a sinusoidal.
static func curva(x: float, sesgo: float) -> float:
	return (sin((x - 0.5) * PI) * 0.5 + 0.5) * sesgo + x * (1.0 - sesgo)

## La mezcla en el cuadro `f` (0-24): la del original, que concentra el cambio en el medio y lo adelanta si hay mucho cambio.
static func mezcla(f: int, c: Dictionary) -> Array:
	var datos: Array = c["auto"]
	var vi := id_vel(float(c["entra"]))
	var vo := id_vel(float(c["sale"]))
	var media := clampf(float(vi + vo) / 6.0, 0.0, 1.0)
	var cambio := (Vector2(0, -float(datos[4])).rotated(float(datos[2])) - Vector2(0, -float(datos[3]))).length() * (100.0 / CUADROS)
	var orig := clampf(f - 1.0, 0.0, CUADROS - 3.0) / (CUADROS - 3.0)
	var b := pow(orig, 0.3 + 0.4 * media + 0.3 * clampf(cambio / 20.0, 0.0, 1.0))
	return [curva(b, 0.7), orig]

static var _plantillas := {}

## La plantilla convertida (de `league.res`), una vez por prefijo: `cargar_real` hace una copia entera en cada llamada.
static func _plantilla(nombre: String, prefijo: String) -> Animation:
	var k := prefijo + "|" + nombre
	if not _plantillas.has(k):
		_plantillas[k] = load("res://visor/anim_quaternius.gd").cargar_real(nombre, prefijo)
	return _plantillas[k]

## Construye la animación de una intermedia en la biblioteca de `ap` (con las plantillas convertidas de `league.res`).
static func construir(c: Dictionary, ap: AnimationPlayer, prefijo: String) -> bool:
	var datos: Array = c["auto"]
	var a1 := _plantilla(String(datos[0]), prefijo)
	var a2 := _plantilla(String(datos[1]), prefijo)
	var modelo := ap.get_node_or_null(ap.root_node)
	if a1 == null or a2 == null or modelo == null:
		return false
	var esqs := modelo.find_children("*", "Skeleton3D", true, false)
	var giro_padre := Quaternion.IDENTITY   ## la pelvis gira sobre la vertical del esqueleto: se pasa a su espacio local
	if not esqs.is_empty():
		var esq := esqs[0] as Skeleton3D
		var ip := esq.find_bone("pelvis")
		if ip >= 0 and esq.get_bone_parent(ip) >= 0:
			giro_padre = esq.get_bone_global_rest(esq.get_bone_parent(ip)).basis.get_rotation_quaternion()
	var sal := Animation.new()
	sal.length = (CUADROS - 1) / 100.0
	sal.loop_mode = Animation.LOOP_NONE
	var cuadros: Array = [0, 1]
	for f in range(2, CUADROS - 2, 2):
		cuadros.append(f)
	cuadros.append_array([CUADROS - 2, CUADROS - 1])
	var ang := float(datos[2])
	var mezclas := PackedFloat64Array()
	for f: int in cuadros:
		var m := mezcla(f, c)
		mezclas.append(float(m[0]))
		mezclas.append(float(m[1]))
	var nat := LeagueMovimiento.nativo()   ## (C++: `league_mezclar`, mismo bucle)
	if nat != null:
		nat.league_mezclar(sal, a1, a2, PackedInt32Array(cuadros), mezclas, ang, giro_padre)
	else:
		mezclar_gd(sal, a1, a2, PackedInt32Array(cuadros), mezclas, ang, giro_padre)
	var lib := ap.get_animation_library("")
	if not lib.has_animation(String(c["nombre"])):
		lib.add_animation(String(c["nombre"]), sal)
	return true

## El bucle de huesos (la referencia del C++): cada hueso mezclado entre las dos plantillas con la mezcla del cuadro; la pelvis,
## además, gira hacia la nueva dirección sobre la vertical del esqueleto. `mezclas` = [bias, orig] por cuadro.
static func mezclar_gd(sal: Animation, a1: Animation, a2: Animation, cuadros: PackedInt32Array, mezclas: PackedFloat64Array, ang: float,
		giro_padre: Quaternion) -> void:
	for i in a1.get_track_count():
		var tipo := a1.track_get_type(i)
		var ruta := a1.track_get_path(i)
		var j := a2.find_track(ruta, tipo)
		if j < 0 or not (tipo == Animation.TYPE_ROTATION_3D or tipo == Animation.TYPE_POSITION_3D):
			continue
		var k := sal.add_track(tipo)
		sal.track_set_path(k, ruta)
		var pelvis := String(ruta).ends_with(":pelvis")
		for x in cuadros.size():
			var t := cuadros[x] / 100.0
			var m0 := mezclas[x * 2]
			var m1 := mezclas[x * 2 + 1]
			if tipo == Animation.TYPE_ROTATION_3D:
				var r: Quaternion = a1.rotation_track_interpolate(i, minf(t, a1.length)).slerp(
					a2.rotation_track_interpolate(j, minf(t, a2.length)), m0)
				if pelvis:
					var arriba := Quaternion(Vector3.UP, ang * (m0 * 0.7 + m1 * 0.3))
					r = (giro_padre.inverse() * arriba * giro_padre) * r
				sal.rotation_track_insert_key(k, t, r)
			else:
				sal.position_track_insert_key(k, t, a1.position_track_interpolate(i, minf(t, a1.length)).lerp(
					a2.position_track_interpolate(j, minf(t, a2.length)), m0))
