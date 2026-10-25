extends BaseIdea
## DE CADENAS DE IF A TABLAS (FASE 0, 25-10-2026). Prueba diferencial de dos refactorizaciones puras:
##   - `DisenosKit.color_en`: el `match` gigante de las 62 familias de camiseta pasó a una tabla
##     familia → fórmula (`FORMULAS`) y un intérprete corto;
##   - `CatalogoJugadas._fases_de`: el `match` de las 60 jugadas pasó a una tabla de datos (`FASES`).
## Ninguna de las dos puede cambiar un solo resultado. Se muestrea una rejilla (u, v) del torso -y un poco
## más allá, por las mangas en u = ±1,05- para TODOS los diseños con tres juegos de colores, se dibuja la
## camiseta 2D entera de cada diseño, y se sacan las fases de cada jugada del catálogo (y de un código
## que no existe). Los colores se comparan bit a bit (float32 en base64), no redondeados.
##
## Modos (variables de entorno):
##   F0D_GRABAR=<ruta>      guarda la huella en un JSON (se hizo con el código de antes en /tmp/aud/f0d_antes.json).
##   F0D_REFERENCIA=<ruta>  compara contra ese JSON.
##   F0D_LEGADO_KIT=<ruta>  compara EN EL MISMO PROCESO contra una copia del `disenos_kit_p2.gd` de antes.
##   F0D_LEGADO_JUG=<ruta>  ídem contra una copia del `catalogo_jugadas.gd` de antes.
## Sin variables comprueba lo permanente: la huella coincide con la sellada aquí (HUELLA_*), toda familia de
## DISENOS tiene su fórmula, y las fases que salen son copias que se pueden tocar sin estropear la tabla.

## Huellas selladas tras comprobar que el código nuevo da lo mismo que el de antes (25-10-2026). Si cambias
## una fórmula A PROPÓSITO (y el shader `visor/equipacion_q.gdshader` con ella), vuelve a sellarlas.
const HUELLA_KIT := 346227002
const HUELLA_JUG := 1598632468

## Tres juegos de 5 colores: primarios, apagados y uno con negro y blanco (el 0 y el 4 cambian de papel).
const PALETAS := [
	["c8102e", "ffffff", "0033a0", "ffd100", "111111"],
	["2e4a3f", "b5a26a", "6b2737", "d9d2c5", "47566b"],
	["000000", "f4f4f4", "e4002b", "00a3e0", "7a7a7a"],
]
const NU := 45
const NV := 41

func _probar() -> void:
	_titulo("F0D · DE CADENAS DE IF A TABLAS (color_en y _fases_de)")
	var h := _huella()
	_linea("  diseños %d · muestras por diseño %d · camisetas %d · jugadas %d" % [DisenosKit.DISENOS.size(),
		PALETAS.size() * NU * NV, h["camisetas"].size(), h["jugadas"].size()])
	var ruta_grabar := OS.get_environment("F0D_GRABAR")
	if ruta_grabar != "":
		var f := FileAccess.open(ruta_grabar, FileAccess.WRITE)
		f.store_string(JSON.stringify(h, " ", true))
		f.close()
		_linea("  huella grabada en %s" % ruta_grabar)
	var ruta_ref := OS.get_environment("F0D_REFERENCIA")
	if ruta_ref != "":
		var ref: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ruta_ref))
		for parte: String in ["rejilla", "camisetas", "jugadas"]:
			_comparar(parte, ref.get(parte, {}), h[parte], "la referencia")
	_legado_kit(OS.get_environment("F0D_LEGADO_KIT"), h)
	_legado_jug(OS.get_environment("F0D_LEGADO_JUG"), h)
	_permanente(h)

## Dos diccionarios clave → texto: cuenta las claves que no coinciden y nombra las primeras.
func _comparar(parte: String, antes: Dictionary, ahora: Dictionary, contra: String) -> void:
	var malas: Array[String] = []
	for k: String in antes:
		if not ahora.has(k) or String(ahora[k]) != String(antes[k]):
			malas.append(k)
	for k: String in ahora:
		if not antes.has(k):
			malas.append(k + " (nueva)")
	_comprobar(not antes.is_empty() and malas.is_empty(), "%s: %d claves iguales que %s%s" % [parte, antes.size(),
		contra, "" if malas.is_empty() else " · distintas: %s" % ", ".join(malas.slice(0, 8))])

## La huella: por diseño y paleta, los colores de la rejilla; por diseño, la camiseta 2D; por jugada, su
## definición entera escrita con `var_to_str` (claves en orden, números exactos).
func _huella(kit: Variant = null, jug: Variant = null) -> Dictionary:
	var rejilla := {}
	var camisetas := {}
	for d: Array in DisenosKit.DISENOS:
		for p in PALETAS.size():
			rejilla["%s|%d" % [d[0], p]] = _rejilla(kit, d, _cols(PALETAS[p]))
		if kit == null:
			var img := DisenosKit._imagen_camiseta(String(d[0]), _cols(PALETAS[0]), 2, 64)
			camisetas[String(d[0])] = Marshalls.raw_to_base64(img.get_data())
	var jugadas := {}
	var ids: Array = CatalogoJugadas.todos_los_ids()
	ids.append("XXX-99")
	for id: String in ids:
		var def: Dictionary = CatalogoJugadas.obtener_definicion(id) if jug == null else jug.call("obtener_definicion", id)
		jugadas[id] = var_to_str(def)
	return {"rejilla": rejilla, "camisetas": camisetas, "jugadas": jugadas}

func _rejilla(kit: Variant, d: Array, cols: Array[Color]) -> String:
	var px := PackedFloat32Array()
	for iv in NV:
		for iu in NU:
			var u := -1.1 + 2.2 * float(iu) / float(NU - 1)
			var v := float(iv) / float(NV - 1)
			var c: Color = DisenosKit.color_en(d, cols, u, v) if kit == null else kit.call("color_en", d, cols, u, v)
			px.append_array([c.r, c.g, c.b, c.a])
	return Marshalls.raw_to_base64(px.to_byte_array())

func _cols(hexes: Array) -> Array[Color]:
	var r: Array[Color] = []
	for x: String in hexes:
		r.append(Color("#" + x))
	return r

func _cargar(ruta: String, quitar_clase: bool) -> GDScript:
	var s := GDScript.new()
	var codigo := FileAccess.get_file_as_string(ruta)
	if quitar_clase:
		## La copia no puede declarar la misma clase global que el original.
		codigo = codigo.replace("class_name CatalogoJugadas\n", "")
	s.source_code = codigo
	_comprobar(s.reload() == OK, "carga la copia de antes (%s)" % ruta)
	return s

func _legado_kit(ruta: String, h: Dictionary) -> void:
	if ruta == "":
		return
	var s := _cargar(ruta, false)
	var antes := {}
	for d: Array in DisenosKit.DISENOS:
		for p in PALETAS.size():
			antes["%s|%d" % [d[0], p]] = _rejilla(s, d, _cols(PALETAS[p]))
	_comparar("rejilla", antes, h["rejilla"], "el color_en de antes (mismo proceso)")

func _legado_jug(ruta: String, h: Dictionary) -> void:
	if ruta == "":
		return
	var s := _cargar(ruta, true)
	var antes := {}
	var ids: Array = CatalogoJugadas.todos_los_ids()
	ids.append("XXX-99")
	for id: String in ids:
		antes[id] = var_to_str(s.call("obtener_definicion", id))
	_comparar("jugadas", antes, h["jugadas"], "el _fases_de de antes (mismo proceso)")

func _sello(partes: Array) -> int:
	var todo := PackedStringArray()
	for parte: Dictionary in partes:
		var claves: Array = parte.keys()
		claves.sort()
		for k: String in claves:
			todo.append(k + "=" + String(parte[k]))
	return "\n".join(todo).hash()

## Una constante de un script o de sus capas de abajo (leída en tiempo de ejecución: así esta prueba también
## corre con el código de antes, que no tenía la tabla, para grabar la referencia).
func _constante(ruta: String, nombre: String) -> Dictionary:
	var s: Script = load(ruta)
	while s != null:
		var m := s.get_script_constant_map()
		if m.has(nombre):
			return m[nombre]
		s = s.get_base_script()
	return {}

func _permanente(h: Dictionary) -> void:
	var sk := _sello([h["rejilla"], h["camisetas"]])
	var sj := _sello([h["jugadas"]])
	_linea("  sello kit %d · sello jugadas %d" % [sk, sj])
	_comprobar(sk == HUELLA_KIT, "los colores de las camisetas son los sellados (%d)" % sk)
	_comprobar(sj == HUELLA_JUG, "las fases de las jugadas son las selladas (%d)" % sj)
	## Toda familia de DISENOS tiene su fórmula (si no, caería en silencio al color de fondo).
	var formulas: Dictionary = DisenosKit.FORMULAS
	var sin_formula: Array[String] = []
	for d: Array in DisenosKit.DISENOS:
		var f := int(d[2])
		if f > 0 and f < 100 and not formulas.has(f):
			sin_formula.append("%s (%d)" % [d[0], f])
	_comprobar(sin_formula.is_empty(), "toda familia de DISENOS tiene fórmula en FORMULAS %s" % [sin_formula])
	## Cada jugada del catálogo está en la tabla de fases (el reglamento sin entrada usa la plantilla).
	var tabla_fases: Dictionary = _constante("res://nucleo/catalogo_jugadas.gd", "FASES")
	var sin_fases: Array[String] = []
	for id: String in CatalogoJugadas.todos_los_ids():
		if not id.begins_with("REG") and not tabla_fases.has(id):
			sin_fases.append(id)
	_comprobar(sin_fases.is_empty(), "toda jugada ATQ/DEF/POR tiene sus fases en FASES %s" % [sin_fases])
	## Las fases son copias: tocarlas (el reproductor podría) no estropea la tabla para la próxima vez.
	var a: Dictionary = CatalogoJugadas.obtener_definicion("ATQ-02")
	var fases: Array = a["fases"]
	var editable := not fases.is_read_only()
	for fase: Dictionary in fases:
		editable = editable and not fase.is_read_only() and not (fase["destinos"] as Dictionary).is_read_only()
	_comprobar(editable, "las fases que salen se pueden modificar (no son la tabla constante)")
	if editable:
		(fases[0] as Dictionary)["duracion"] = 99.0
		((fases[0] as Dictionary)["destinos"] as Dictionary)["DC"] = Vector3.ZERO
	var b: Dictionary = CatalogoJugadas.obtener_definicion("ATQ-02")
	_comprobar(var_to_str(b) == String(h["jugadas"]["ATQ-02"]), "tocar una copia no cambia la siguiente definición")
