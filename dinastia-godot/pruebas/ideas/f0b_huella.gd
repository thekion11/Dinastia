extends BaseIdea
## HUELLA DEL ESTADIO (FASE 0, 25-10-2026). Prueba diferencial del troceo de `StadiumBuilder.build_1`
## por zonas (`visor/estadio_partes_*.gd`): construye varios estadios con semilla fija -las 10 formas y
## variantes que recorren todas las ramas de la tribuna (bandejas, tercios, color por anillo, sector
## visitante, techos)- y saca de cada árbol una HUELLA: nodos (cuántos, en qué orden, con qué nombre y
## clase), número de MeshInstance3D, suma de vértices de las mallas, AABB global redondeada y un resumen
## de cada pieza (transform local, malla, material). Una refactorización pura no puede mover nada de eso.
##
## Tres modos (variables de entorno):
##   F0B_LEGADO=<ruta.gd>  compara EN EL MISMO PROCESO contra una copia del `build` de antes (mismas capas
##                         de abajo, así otro agente puliendo el estadio no ensucia la comparación).
##   F0B_GRABAR=<ruta>     guarda la huella de cada caso en un JSON.
##   F0B_REFERENCIA=<ruta> compara contra un JSON grabado antes.
## Sin variables comprueba lo permanente: dos construcciones del mismo estadio dan la misma huella y
## cada forma levanta lo que promete (tribunas, techos, butacas).

const FORMAS := ["cuenco", "oval", "rect", "caldera", "herradura", "ingles", "dos", "principal",
	"estrecho", "asimetrico"]
const SEMILLA := 4242

func _probar() -> void:
	_titulo("F0B · HUELLA DEL ESTADIO (troceo de build_1 por zonas)")
	var club := Club.new("f0b_club", "Club Huella")
	club.color1 = "#8a1c2b"
	club.color2 = "#f2d16b"
	var casos := _casos()
	var legado: GDScript = null
	var ruta_legado := OS.get_environment("F0B_LEGADO")
	if ruta_legado != "":
		legado = GDScript.new()
		legado.source_code = FileAccess.get_file_as_string(ruta_legado)
		_comprobar(legado.reload() == OK, "carga el build de antes (%s)" % ruta_legado)
	var grabadas := {}
	var referencia := {}
	var ruta_ref := OS.get_environment("F0B_REFERENCIA")
	if ruta_ref != "":
		referencia = JSON.parse_string(FileAccess.get_file_as_string(ruta_ref))
	for nombre: String in casos:
		var est: Dictionary = casos[nombre]
		var mi: Club = club if not nombre.begins_with("sin_club") else null
		var h := _huella(_construir(null, est, mi))
		grabadas[nombre] = h
		_linea("  %-22s nodos %5d · mallas %4d · vértices %8d · recinto %s" % [nombre, h["nodos"], h["mallas"],
			h["vertices"], h["recinto"]])
		if legado != null:
			var hl := _huella(_construir(legado, est, mi))
			_comprobar(h == hl, "%s: igual que el build de antes%s" % [nombre, _diferencias(hl, h)])
		elif not referencia.is_empty():
			_comprobar(referencia.has(nombre) and referencia[nombre] == h,
				"%s: igual que la referencia%s" % [nombre, _diferencias(referencia.get(nombre, {}), h)])
	var ruta_grabar := OS.get_environment("F0B_GRABAR")
	if ruta_grabar != "":
		var f := FileAccess.open(ruta_grabar, FileAccess.WRITE)
		f.store_string(JSON.stringify(grabadas, " ", true))
		f.close()
		_linea("  huella grabada en %s" % ruta_grabar)
	## Lo permanente: misma entrada, mismo estadio (sin esto la comparación no valdría nada).
	var otra := _huella(_construir(null, casos["cuenco"], club))
	_comprobar(otra == grabadas["cuenco"], "el mismo estadio dos veces da la misma huella%s" %
		_diferencias(grabadas["cuenco"], otra))
	for forma: String in FORMAS:
		var h: Dictionary = grabadas[forma]
		_comprobar(int(h["mallas"]) > 100 and int(h["vertices"]) > 10000, "%s levanta un estadio entero" % forma)
	## «dos» no tiene fondos: menos piezas que el cuenco; «principal» es «rect» con una bandeja más en la
	## tribuna de honor (más rampas y un peto más) y la tribuna crece hacia fuera.
	_comprobar(int(grabadas["dos"]["mallas"]) < int(grabadas["cuenco"]["mallas"]), "«dos» deja los fondos sin tribuna")
	_comprobar(int(grabadas["principal"]["mallas"]) > int(grabadas["rect"]["mallas"]) and
		float(grabadas["principal"]["recinto"][3]) > float(grabadas["rect"]["recinto"][3]),
		"«principal» suma la bandeja de su tribuna de honor")

## Los estadios de la prueba: las 10 formas con el perfil por defecto y variantes que pasan por cada
## rama de la tribuna.
func _casos() -> Dictionary:
	var c := {}
	for forma: String in FORMAS:
		c[forma] = {"forma": forma, "niveles": 2}
	c["bandejas_propias"] = {"forma": "cuenco", "niveles": 3, "techo": "visera",
		"bandejas": {"sur": {"asientoP": "damero", "techo": "total"}, "este": {"col1": "#123456",
			"niveles": ["#aa0000", "", "#00aa00"]}, "oeste": {"techo": "sin", "col2": "#eeeeee"}}}
	c["tramos_visitante"] = {"forma": "rect", "niveles": 2, "visita1": "#0044ff", "techo": "membrana",
		"tramos": {"norte": ["franjas", "damero", "sectores"], "este": ["sectores", "franjas", "damero"]}}
	c["principal_total"] = {"forma": "principal", "niveles": 4, "techo": "total", "exterior": true}
	c["sin_club_sin_techo"] = {"forma": "herradura", "niveles": 1, "techo": "sin", "vallas": false}
	return c

func _construir(script: GDScript, est: Dictionary, mi: Club) -> Node3D:
	var raiz := Node3D.new()
	if script == null:
		StadiumBuilder.build(raiz, est.duplicate(true), 40000, 0.8, SEMILLA, mi)
	else:
		script.call("build", raiz, est.duplicate(true), 40000, 0.8, SEMILLA, mi)
	return raiz

## La huella de un árbol (y lo libera). Los nombres automáticos de Godot llevan un contador
## («@MeshInstance3D@123»): se quita el número para que dos construcciones sean comparables.
func _huella(raiz: Node3D) -> Dictionary:
	var lineas := PackedStringArray()
	var clases := {}
	var mallas := 0
	var vertices := 0
	var caja := AABB()
	var hay_caja := false
	## La explanada de fondo (400 x 400 m) se come la caja global: aparte, la del recinto sin ella.
	var recinto := AABB()
	var hay_recinto := false
	var pila: Array = [[raiz, Transform3D.IDENTITY, 0]]
	while not pila.is_empty():
		var e: Array = pila.pop_back()
		var n: Node = e[0]
		var xf: Transform3D = e[1]
		if n is Node3D:
			xf = xf * (n as Node3D).transform
		var clase := n.get_class()
		clases[clase] = int(clases.get(clase, 0)) + 1
		var nombre := String(n.name)
		if nombre.begins_with("@"):
			nombre = nombre.rstrip("0123456789")
		var linea := "%d|%s|%s" % [e[2], nombre, clase]
		if n is Node3D:
			linea += "|" + _t(xf)
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var m := n as MeshInstance3D
			mallas += 1
			var v := _vertices(m.mesh)
			vertices += v
			linea += "|%s:%d|%s" % [m.mesh.get_class(), v, _mat(m.material_override)]
		elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null:
			var mm := (n as MultiMeshInstance3D).multimesh
			linea += "|mm:%d:%d" % [mm.instance_count, _vertices(mm.mesh) if mm.mesh != null else 0]
		if n is VisualInstance3D:
			var a := xf * (n as VisualInstance3D).get_aabb()
			caja = a if not hay_caja else caja.merge(a)
			hay_caja = true
			if a.size.x < 300.0 and a.size.z < 300.0:
				recinto = a if not hay_recinto else recinto.merge(a)
				hay_recinto = true
		lineas.append(linea)
		## Al revés en la pila para recorrer en el orden de los hijos.
		var hijos := n.get_children()
		for i in range(hijos.size() - 1, -1, -1):
			pila.append([hijos[i], xf, e[2] + 1])
	raiz.free()
	return {"nodos": lineas.size(), "mallas": mallas, "vertices": vertices, "clases": clases,
		"aabb": _caja(caja), "recinto": _caja(recinto), "arbol": "\n".join(lineas).md5_text()}

func _caja(a: AABB) -> Array:
	return [_r(a.position.x), _r(a.position.y), _r(a.position.z), _r(a.end.x), _r(a.end.y), _r(a.end.z)]

func _vertices(m: Mesh) -> int:
	var v := 0
	for s in m.get_surface_count():
		## `surface_get_array_len` solo existe en ArrayMesh; las primitivas (BoxMesh…) dan sus arrays.
		v += (m.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return v

func _mat(m: Material) -> String:
	if m == null:
		return "-"
	if m is StandardMaterial3D:
		var s := m as StandardMaterial3D
		return "std:%s:%s:%s:%s" % [s.albedo_color.to_html(), str(s.uv1_scale.snappedf(0.001)),
			str(s.uv1_offset.snappedf(0.001)), "tex" if s.albedo_texture != null else "-"]
	return m.get_class()

func _t(xf: Transform3D) -> String:
	return "%s;%s;%s;%s" % [str(xf.origin.snappedf(0.01)), str(xf.basis.x.snappedf(0.001)),
		str(xf.basis.y.snappedf(0.001)), str(xf.basis.z.snappedf(0.001))]

func _r(x: float) -> float:
	return snappedf(x, 0.01)

## Para el mensaje de fallo: qué campos de la huella cambiaron.
func _diferencias(a: Dictionary, b: Dictionary) -> String:
	var d := PackedStringArray()
	for k in b:
		if a.get(k) != b[k]:
			d.append("%s: %s → %s" % [k, str(a.get(k)), str(b[k])])
	return "" if d.is_empty() else " (" + "; ".join(d) + ")"
