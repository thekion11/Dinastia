class_name TrofeoModelo
extends RefCounted
## LOS TROFEOS DE CADA COMPETICIÓN (orden 15 e, 27-10-2026): a partir de las tres copas de `assets/trofeos/trofeo_base.glb` se arma una por
## competición parecida a la de verdad (forma de la copa, alto, base, color y adornos), sin copiar ninguna. La receta (`datos/trofeos_modelos.json`):
##   copa    1 clásica con asas · 2 clásica sobre pie fino · 3 ancha y baja (fuente o plato)
##   alto    estira la copa en vertical · ancho engorda el cuenco · pie engorda el tallo (1 = como el modelo)
##   metal   color de la copa (hex) · brillo (0..1, lo metálica que sale)
##   base    {forma: cil|caja|escalon|piramide, alto, ancho, color} (alto y ancho en metros del modelo, ~0.6 de copa) o ausente
##   extras  lista de: corona · tapa · esfera · anillo
## `partes(receta)` devuelve {partes: [{mesh, mat, pos}], alto}: la pieza con la base en y=0; quien la use la escala a su medida.
const TROFEO := "res://assets/trofeos/trofeo_base.glb"
const NODOS := ["gold_trophy1", "gold_trophy2", "gold_trophy3"]
## Radio de la boca y alto de cada copa del modelo (medidos con `captura_trofeo_base`).
const BOCA := [0.23, 0.215, 0.29]
const ALTO_COPA := [0.667, 0.627, 0.478]

static var _meshes: Array = []
static var _tex: Image = null
static var _cache := {}

static func _cargar() -> void:
	if not _meshes.is_empty() or not ResourceLoader.exists(TROFEO):
		return
	var raiz := (load(TROFEO) as PackedScene).instantiate()
	for nombre: String in NODOS:
		var n := raiz.get_node_or_null(nombre) as MeshInstance3D
		_meshes.append(n.mesh if n != null else null)
		if n != null and _tex == null:
			var m := n.mesh.surface_get_material(0) as StandardMaterial3D
			if m != null and m.albedo_texture != null:
				_tex = m.albedo_texture.get_image()
				if _tex.is_compressed():
					_tex.decompress()
				_tex.convert(Image.FORMAT_RGBA8)
	raiz.free()

## ¿Está el modelo base? Sin él no hay trofeos de receta (quien llama cae a la copa de siempre).
static func disponible() -> bool:
	_cargar()
	return not _meshes.is_empty() and _meshes[0] != null and _tex != null

static func _color(h: String, por_defecto: Color) -> Color:
	return Color(h) if h != "" else por_defecto

## La paleta del modelo recoloreada: lo dorado toma el color del metal y lo gris, el de la base.
static func _textura(metal: Color, piedra: Color) -> ImageTexture:
	var img := _tex.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var l := c.get_luminance()
			var oscuro := l < 0.6 and c.s < 0.25   ## el gris oscuro de la paleta es la peana; lo claro y lo dorado, el metal pulido
			var cb := piedra if oscuro else metal
			var f := l / (0.45 if oscuro else 0.8)
			img.set_pixel(x, y, Color(clampf(cb.r * f, 0.0, 1.0), clampf(cb.g * f, 0.0, 1.0), clampf(cb.b * f, 0.0, 1.0), 1.0))
	return ImageTexture.create_from_image(img)

static func _copa_mesh(i: int, alto: float, ancho: float, pie: float) -> ArrayMesh:
	var src: Mesh = _meshes[i]
	var a := src.surface_get_arrays(0)
	var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var h: float = ALTO_COPA[i]
	for k in vs.size():
		var v := vs[k]
		var t := clampf(v.y / h, 0.0, 1.0)
		var s := lerpf(pie, ancho, smoothstep(0.30, 0.55, t))
		vs[k] = Vector3(v.x * s, v.y * alto, v.z * s)
	a[Mesh.ARRAY_VERTEX] = vs
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	return m

static func _mat_liso(c: Color, metal: float, rug: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metal
	m.roughness = rug
	return m

static func _parte(partes: Array, mesh: Mesh, mat: Material, pos: Vector3, copa := false) -> void:
	partes.append({"mesh": mesh, "mat": mat, "pos": pos, "copa": copa})

static func _cilindro(r_arriba: float, r_abajo: float, alto: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_arriba
	c.bottom_radius = r_abajo
	c.height = alto
	c.radial_segments = 28
	c.rings = 1
	return c

## {partes, alto}: ver la cabecera. Se guarda por receta: construirla recorre ~16 000 píxeles y ~2 000 vértices.
static func partes(receta: Dictionary) -> Dictionary:
	_cargar()
	if not disponible():
		return {"partes": [], "alto": 0.0}
	var clave := JSON.stringify(receta)
	if _cache.has(clave):
		return _cache[clave]
	var i := clampi(int(receta.get("copa", 1)) - 1, 0, 2)
	var alto := float(receta.get("alto", 1.0))
	var ancho := float(receta.get("ancho", 1.0))
	var metal := _color(String(receta.get("metal", "")), Color("#e8b838"))
	var base: Dictionary = receta.get("base", {})
	var color_base := _color(String(base.get("color", "")), Color(0.2, 0.2, 0.22))
	var tex := _textura(metal, color_base)
	var mat_copa := StandardMaterial3D.new()
	mat_copa.albedo_texture = tex
	mat_copa.metallic = float(receta.get("brillo", 0.55))
	mat_copa.roughness = 0.3
	mat_copa.cull_mode = BaseMaterial3D.CULL_DISABLED   ## las asas son láminas de una sola cara
	var salida: Array = []
	var y0 := 0.0
	var forma := String(base.get("forma", ""))
	var b_alto := float(base.get("alto", 0.0))
	var b_ancho := float(base.get("ancho", 0.0))
	var mat_base := _mat_liso(color_base, 0.25, 0.45)
	match forma:
		"cil":
			_parte(salida, _cilindro(b_ancho, b_ancho, b_alto), mat_base, Vector3(0, b_alto * 0.5, 0))
		"caja":
			var bx := BoxMesh.new()
			bx.size = Vector3(b_ancho * 2.0, b_alto, b_ancho * 1.6)
			_parte(salida, bx, mat_base, Vector3(0, b_alto * 0.5, 0))
		"escalon":
			_parte(salida, _cilindro(b_ancho, b_ancho, b_alto * 0.5), mat_base, Vector3(0, b_alto * 0.25, 0))
			_parte(salida, _cilindro(b_ancho * 0.72, b_ancho * 0.72, b_alto * 0.5), mat_base, Vector3(0, b_alto * 0.75, 0))
		"piramide":
			_parte(salida, _cilindro(b_ancho * 0.45, b_ancho, b_alto), mat_base, Vector3(0, b_alto * 0.5, 0))
	if forma != "":
		y0 = b_alto
	_parte(salida, _copa_mesh(i, alto, ancho, float(receta.get("pie", 1.0))), mat_copa, Vector3(0, y0, 0), true)
	var y_boca := y0 + float(ALTO_COPA[i]) * alto
	var r_boca := float(BOCA[i]) * ancho
	var mat_metal := _mat_liso(metal, float(receta.get("brillo", 0.55)), 0.3)
	var extras: Array = receta.get("extras", [])
	if extras.has("corona"):
		_parte(salida, _cilindro(r_boca * 0.55, r_boca * 0.6, 0.03), mat_metal, Vector3(0, y_boca + 0.015, 0))
		for k in 5:
			var ang := TAU * float(k) / 5.0
			_parte(salida, _cilindro(0.0, 0.022, 0.07), mat_metal, Vector3(cos(ang), 0, sin(ang)) * r_boca * 0.5 + Vector3(0, y_boca + 0.065, 0))
		y_boca += 0.1
	if extras.has("tapa"):
		_parte(salida, _cilindro(0.0, r_boca * 0.95, r_boca * 0.9), mat_metal, Vector3(0, y_boca + r_boca * 0.45, 0))
		var pomo := SphereMesh.new()
		pomo.radius = 0.025
		pomo.height = 0.05
		_parte(salida, pomo, mat_metal, Vector3(0, y_boca + r_boca * 0.9 + 0.02, 0))
		y_boca += r_boca * 0.9 + 0.05
	if extras.has("esfera"):
		var es := SphereMesh.new()
		es.radius = r_boca * 0.5
		es.height = r_boca
		_parte(salida, es, mat_metal, Vector3(0, y_boca + r_boca * 0.3, 0))
		y_boca += r_boca * 0.8
	if extras.has("anillo"):
		var to := TorusMesh.new()
		to.inner_radius = 0.045
		to.outer_radius = 0.075
		_parte(salida, to, mat_metal, Vector3(0, y0 + float(ALTO_COPA[i]) * alto * 0.3, 0))
	var r := {"partes": salida, "alto": y_boca}
	_cache[clave] = r
	return r

## Un Node3D con la pieza entera, de `alto_final` metros (para el visor y las pruebas).
static func nodo(receta: Dictionary, alto_final: float) -> Node3D:
	var p := partes(receta)
	var raiz := Node3D.new()
	if (p["partes"] as Array).is_empty():
		return raiz
	var esc := alto_final / maxf(float(p["alto"]), 0.01)
	for d: Dictionary in p["partes"]:
		var mi := MeshInstance3D.new()
		mi.mesh = d["mesh"]
		mi.material_override = d["mat"]
		mi.position = (d["pos"] as Vector3) * esc
		mi.scale = Vector3.ONE * esc
		raiz.add_child(mi)
	return raiz
