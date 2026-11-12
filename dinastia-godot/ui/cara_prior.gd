class_name CaraPrior
extends RefCounted
## LA CARA POR PAÍS (10-11, encargo del dueño «uniformes y caras», parte 2). Un jugador del que NO hay foto (ni rasgos ni malla medida) recibía una cara al azar
## (en la base real: tono de piel de 8 a partes iguales, barba 0-7, cualquier corte) o una piel por país muy tosca (base pública). Ahora toma sus rasgos de
## `datos/rasgos_pais.json`: las PROPORCIONES de piel, color de pelo, barba y calvicie medidas en las caras reales de ese país (`herramientas/rasgos_por_pais.py`,
## sin nombres ni fotos de nadie). Es determinista por jugador (mismo id, misma cara) y no toca el motor.
const RUTA := "res://datos/rasgos_pais.json"
const MIN_JUGADORES := 12   ## con menos caras medidas, el país usa la media mundial
const PELO_HEX := {"negro": "#1a1a1a", "castano_oscuro": "#3d2a19", "castano": "#6b4a2a", "rubio": "#c8a05a", "claro_o_canoso": "#b9b5ad", "pelirrojo": "#8a3b1f"}
const CORTES_RIZADOS := ["corto", "fade", "rapado", "afro", "rizado", "undercut"]
## La piel MEDIDA en una foto o en la malla 3D sale más oscura que el tono de dibujo de `Cara.PIELES`: se calibra por luminancia (mismas constantes que `rasgos_por_pais.py`).
const FOTO_OSCURA := 0.20
const FOTO_CLARA := 0.68
static var _tabla: Dictionary = {}
static var _listo := false

static func tabla() -> Dictionary:
	if not _listo:
		_listo = true
		if FileAccess.file_exists(RUTA):
			var jp := JSON.new()
			if jp.parse(FileAccess.get_file_as_string(RUTA)) == OK and jp.data is Dictionary:
				_tabla = jp.data
	return _tabla

static func _u(j: Jugador, sal: String) -> float:
	return float(absi((j.id + sal).hash()) % 100000) / 100000.0

static func _elegir(pesos: Array, u: float) -> int:
	var acc := 0.0
	for i in pesos.size():
		acc += float(pesos[i])
		if u < acc:
			return i
	return pesos.size() - 1

## La fila del país de `j` (o la mundial si hay pocas caras medidas); {} si no hay tabla.
static func fila_de(j: Jugador) -> Dictionary:
	var t := tabla()
	if t.is_empty():
		return {}
	var f: Variant = t.get(j.pais, {})
	if f is Dictionary and int((f as Dictionary).get("n", 0)) >= MIN_JUGADORES:
		return f
	## (12-11) Con pocas caras medidas, la media MUNDIAL (clara) no sirve para un país con tono propio conocido (Nigeria, Ghana, Costa de
	## Marfil… salían claros): mejor el modelo del país (`Cara.TONO_MEDIO` / `PielPaises`), que lo trata quien llama al devolver vacío.
	if Cara.TONO_MEDIO.has(j.pais) or PielPaises.TONO.has(j.pais):
		return {}
	return t.get("*", {})

## Piel, color de pelo, barba, corte y calvicie de `j` (sobre `base`). Devuelve false si no hay tabla (queda el modelo anterior).
static func aplicar(base: Dictionary, j: Jugador) -> bool:
	var f := fila_de(j)
	if f.is_empty():
		return false
	var ip := _elegir(f["piel"], _u(j, "prior_piel"))
	base["piel"] = Cara.PIELES[clampi(ip, 0, Cara.PIELES.size() - 1)]
	var claves: Array = PELO_HEX.keys()
	var pesos: Array = claves.map(func(k: String) -> float: return float((f["pelo"] as Dictionary).get(k, 0.0)))
	base["peloC"] = PELO_HEX[claves[_elegir(pesos, _u(j, "prior_pelo"))]]
	barba(base, j, f)
	var calvo := _u(j, "prior_calvo") < float(f["calvo_vet"] if j.edad >= 31 else f["calvo"])
	var oscuro := ip >= 5
	if calvo:
		base["pelo"] = "calvo"
	elif oscuro:
		base["pelo"] = CORTES_RIZADOS[absi((j.id + "prior_corte").hash()) % CORTES_RIZADOS.size()]
	else:
		base["pelo"] = Cara.CORTES_SOBRIOS[absi((j.id + "prior_corte").hash()) % Cara.CORTES_SOBRIOS.size()]
	## Una persona real no lleva marcas inventadas ni adornos (igual que con foto).
	base["acc"] = ""
	base["pecas"] = false
	base["lunar"] = false
	base["cicatriz"] = false
	return true

## Solo la barba (para quien ya tiene piel y pelo medidos pero no barba, p. ej. los de la malla).
static func barba(base: Dictionary, j: Jugador, f: Dictionary = {}) -> void:
	if f.is_empty():
		f = fila_de(j)
	if f.is_empty():
		return
	var claves: Array = (f["barba"] as Dictionary).keys()
	var pesos: Array = claves.map(func(k: String) -> float: return float((f["barba"] as Dictionary)[k]))
	base["barba"] = int(claves[_elegir(pesos, _u(j, "prior_barba"))])

## El índice de `Cara.PIELES` que corresponde a un color de piel medido en foto (calibrado por luminancia).
static func tono_de_foto(hexa: String) -> int:
	var oscuro := Color(Cara.PIELES[Cara.PIELES.size() - 1]).get_luminance()
	var claro := Color(Cara.PIELES[0]).get_luminance()
	var l := oscuro + (Color(hexa).get_luminance() - FOTO_OSCURA) * (claro - oscuro) / (FOTO_CLARA - FOTO_OSCURA)
	var mejor := 0
	var dmin := 99.0
	for i in Cara.PIELES.size():
		var d := absf(Color(Cara.PIELES[i]).get_luminance() - l)
		if d < dmin:
			dmin = d
			mejor = i
	return mejor
