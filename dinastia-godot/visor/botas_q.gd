class_name BotasQ
extends RefCounted
## LA HORMA DE LA BOTA (sesión 14, 12-11-2026). El cuerpo Quaternius es un pie DESNUDO: el botín se
## pintaba encima y de cerca se veían los cinco dedos en negro. Aquí, una vez por malla (en
## `VestidorQ._con_reposo`, que ya hace una copia compartida por todos los jugadores), el pie se
## lleva a una horma lisa:
##   - empeine (de `Z0` a `ZC`): en cada corte de 1 cm se mide el ancho y el alto y cada vértice sale
##     hasta el borde de una superelipse con esas medidas (solo hacia fuera);
##   - puntera (desde `ZC`): TODOS los vértices van a una superficie analítica (el corte medido en `ZC`,
##     que se redondea, baja y se va hacia el dedo gordo hasta la punta), con su normal exacta. La forma
##     ya no depende de los dedos.
## Sin mallas ni materiales nuevos: 0 llamadas de dibujo y 0 bytes por jugador. La pose de reposo que
## leen los shaders (UV2 y COLOR) sigue siendo la original. `BOTAS_DESNUDAS=1` mide el antes.

const Z0 := 0.0
const ZC := 0.035
## Solo el pie: por encima de esta altura (m) no se toca.
const Y_MAX := 0.075
## Exponente de la superelipse: 2 = elipse; más, sección más cuadrada (la bota es plana abajo).
const P := 2.6
const PASO := 0.01

## Rehace el pie en los arrays de una superficie (posiciones y normales).
static func aplicar(arr: Array) -> void:
	if OS.get_environment("BOTAS_DESNUDAS") != "" or not (arr[Mesh.ARRAY_VERTEX] is PackedVector3Array):
		return
	var pos: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var r := horma(pos)
	var nuevas: PackedVector3Array = r[0]
	arr[Mesh.ARRAY_VERTEX] = nuevas
	if arr[Mesh.ARRAY_NORMAL] is PackedVector3Array and arr[Mesh.ARRAY_INDEX] is PackedInt32Array:
		var nor := normales(pos, nuevas, arr[Mesh.ARRAY_NORMAL], arr[Mesh.ARRAY_INDEX])
		var exactas: Dictionary = r[1]
		for i: int in exactas:
			nor[i] = exactas[i]
		arr[Mesh.ARRAY_NORMAL] = nor

## [posiciones nuevas, {índice: normal exacta}] (`pos` queda intacto). El cuerpo no trae formas de mezcla.
static func horma(pos: PackedVector3Array) -> Array:
	var cortes := _medir(pos)
	var out := pos.duplicate()
	var exactas := {}
	var cap := _medir_puntera(pos)
	if cortes.is_empty() or cap.is_empty():
		return [out, exactas]
	for i in pos.size():
		var p := pos[i]
		if p.y > Y_MAX or p.z < Z0 or absf(p.x) < 0.05 or absf(p.x) > 0.25:
			continue
		var ax := absf(p.x)
		var puntera := p.z >= ZC
		var sec := _seccion_puntera(cap, p.z) if puntera else _seccion_corte(cortes, p.z)
		if sec.is_empty():
			continue
		var dx := (ax - float(sec[0])) / float(sec[2])
		var dy := (p.y - float(sec[1])) / float(sec[3])
		var r := pow(pow(absf(dx), P) + pow(absf(dy), P), 1.0 / P)
		if r < 0.05 or (not puntera and r > 1.0):
			continue
		var ux := dx / r
		var uy := dy / r
		var q := _punto(sec, ux, uy)
		var w := 1.0 if puntera else smoothstep(Z0, ZC, p.z)
		out[i] = Vector3(signf(p.x) * lerpf(ax, q.x, w), lerpf(p.y, q.y, w), p.z)
		if puntera:
			exactas[i] = _normal(cap, p.z, ux, uy, signf(p.x))
	return [out, exactas]

static func _punto(sec: Array, ux: float, uy: float) -> Vector2:
	return Vector2(float(sec[0]) + ux * float(sec[2]), float(sec[1]) + uy * float(sec[3]))

## La normal de la puntera en (z, dirección ux,uy): en el corte, el gradiente de la superelipse; a lo
## largo, la inclinación con que la sección se encoge (la punta mira hacia delante).
static func _normal(cap: Dictionary, z: float, ux: float, uy: float, lado: float) -> Vector3:
	var sec := _seccion_puntera(cap, z)
	var nx := signf(ux) * pow(absf(ux), P - 1.0) / float(sec[2])
	var ny := signf(uy) * pow(absf(uy), P - 1.0) / float(sec[3])
	var nxy := Vector2(nx, ny).normalized()
	var e := 0.002
	var dq := (_punto(_seccion_puntera(cap, z + e), ux, uy) - _punto(_seccion_puntera(cap, z - e), ux, uy)) / (2.0 * e)
	var nz := -nxy.dot(dq)
	return Vector3(nxy.x * lado, nxy.y, nz).normalized()

## [centro x, centro y, semiancho, semialto] del corte de 1 cm que contiene `z`.
static func _seccion_corte(cortes: Dictionary, z: float) -> Array:
	var k := floori(z / PASO)
	if not cortes.has(k):
		return []
	var c: Vector4 = cortes[k]   ## x_min, x_max, y_min, y_max (con |x|)
	return [(c.x + c.y) * 0.5, (c.z + c.w) * 0.5, maxf((c.y - c.x) * 0.5, 0.004), maxf((c.w - c.z) * 0.5, 0.004)]

## La sección de la puntera a la distancia `z`: el ancho se mantiene y se redondea al final, el centro
## se va hacia el dedo gordo y el alto baja hasta ~1,4 cm sobre la suela en la punta.
static func _seccion_puntera(cap: Dictionary, z: float) -> Array:
	var t := clampf((z - ZC) / maxf(float(cap["z_tip"]) - ZC, 0.01), 0.0, 1.0)
	var c: Vector4 = cap["base"]
	var a := maxf((c.y - c.x) * 0.5 * pow(maxf(1.0 - pow(t, 2.5), 0.0), 0.45), 0.004)
	var cx := lerpf((c.x + c.y) * 0.5, float(cap["x_tip"]), t * t)
	var yb := c.z
	var yt := lerpf(c.w, yb + 0.014, pow(t, 1.3))
	return [cx, (yb + yt) * 0.5, a, maxf((yt - yb) * 0.5, 0.004)]

## Las medidas de la puntera: el corte en `ZC` (x_min, x_max, y_min, y_max con |x|), dónde acaba el
## pie (`z_tip`) y por dónde (`x_tip`, el dedo gordo).
static func _medir_puntera(pos: PackedVector3Array) -> Dictionary:
	var base := Vector4(1e9, -1e9, 1e9, -1e9)
	var z_tip := -1.0
	for p in pos:
		if p.y > Y_MAX or absf(p.x) < 0.05 or absf(p.x) > 0.25 or p.z < Z0:
			continue
		z_tip = maxf(z_tip, p.z)
		if absf(p.z - ZC) < 0.006:
			var ax := absf(p.x)
			base = Vector4(minf(base.x, ax), maxf(base.y, ax), minf(base.z, p.y), maxf(base.w, p.y))
	if z_tip <= ZC or base.x > base.y:
		return {}
	var sx := 0.0
	var n := 0.0
	for p in pos:
		if p.y <= Y_MAX and absf(p.x) >= 0.05 and absf(p.x) <= 0.25 and p.z > z_tip - 0.008:
			sx += absf(p.x)
			n += 1.0
	return {"base": base, "z_tip": z_tip, "x_tip": sx / maxf(n, 1.0)}

## Por cada corte de 1 cm: el rectángulo que ocupa el pie (con |x|, los dos pies a la vez: son
## simétricos), suavizado con los cortes vecinos para que la horma no haga escalones.
static func _medir(pos: PackedVector3Array) -> Dictionary:
	var crudo := {}
	for p in pos:
		if p.y > Y_MAX or p.z < Z0 - PASO or absf(p.x) < 0.05 or absf(p.x) > 0.25:
			continue
		var k := floori(p.z / PASO)
		var ax := absf(p.x)
		var c: Vector4 = crudo.get(k, Vector4(1e9, -1e9, 1e9, -1e9))
		crudo[k] = Vector4(minf(c.x, ax), maxf(c.y, ax), minf(c.z, p.y), maxf(c.w, p.y))
	var cortes := {}
	for k: int in crudo:
		var suma := Vector4.ZERO
		var n := 0.0
		for d in [-1, 0, 1]:
			if crudo.has(k + d):
				var peso := 2.0 if d == 0 else 1.0
				suma += (crudo[k + d] as Vector4) * peso
				n += peso
		cortes[k] = suma / n
	return cortes

## Las normales rehechas para los vértices del empeine que se movieron (media de las caras que los
## tocan, soldando los duplicados de las costuras de UV por su posición original). El resto, igual.
static func normales(viejas: PackedVector3Array, nuevas: PackedVector3Array, nor: PackedVector3Array,
		idx: PackedInt32Array) -> PackedVector3Array:
	var out := nor.duplicate()
	var acum := {}
	var movidos := {}
	for i in viejas.size():
		if not viejas[i].is_equal_approx(nuevas[i]):
			movidos[i] = true
	if movidos.is_empty():
		return out
	for t in range(0, idx.size() - 2, 3):
		var a := idx[t]
		var b := idx[t + 1]
		var c := idx[t + 2]
		if not (movidos.has(a) or movidos.has(b) or movidos.has(c)):
			continue
		var fn := (nuevas[b] - nuevas[a]).cross(nuevas[c] - nuevas[a])
		for v in [a, b, c]:
			var clave := Vector3i((viejas[v] * 10000.0).round())
			acum[clave] = (acum.get(clave, Vector3.ZERO) as Vector3) + fn
	## El orden de los vértices decide hacia dónde mira el producto: el signo se elige UNA vez, el que
	## coincide con las normales originales en la mayoría (por vértice, uno de canto podía darse vuelta).
	var signo := 0.0
	for i: int in movidos:
		signo += (acum.get(Vector3i((viejas[i] * 10000.0).round()), Vector3.ZERO) as Vector3).normalized().dot(nor[i])
	var k := 1.0 if signo >= 0.0 else -1.0
	for i: int in movidos:
		var s: Vector3 = acum.get(Vector3i((viejas[i] * 10000.0).round()), Vector3.ZERO)
		if s.length_squared() > 1e-14:
			out[i] = s.normalized() * k
	return out
