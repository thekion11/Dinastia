class_name Modulos
## LAS PIEZAS DEL JUEGO, MODULARES Y REUTILIZABLES (21-10-2026). Pedido del dueño
## (tras el informe técnico, punto 11): «reusar es para TODOS los objetos y poder
## SEPARAR y UNIR de forma modular».
##
## Hasta hoy el catálogo de piezas (los 930 modelos de Kenney + los muebles de
## Quaternius, con sus escalas medidas) vivía dentro de `InteriorInstalacion` y
## cada sitio que quería un mueble se lo hacía a mano con cajas. Aquí queda un
## único catálogo para todo el juego:
##   · `ruta`, `escala`, `datos`  qué es una pieza, a qué tamaño real va y sus
##     mallas ya centradas (la carga se hace UNA vez por pieza y se guarda).
##   · `tomar` / `devolver`       RECICLAJE: una pieza que se deja de usar no se
##     destruye, se guarda apagada y la siguiente que se pida sale de ahí.
##   · `unir` / `separar`         varias piezas forman un CONJUNTO (una mesa con
##     sus sillas, un rincón de la oficina) que se mueve y se guarda de una vez,
##     y se puede volver a desarmar en sus piezas sueltas.
##   · `a_datos` / `de_datos`     un conjunto como lista de {pieza, posición,
##     giro, escala}: así se guarda con la partida y se rearma igual.
##   · `listar(kit)`              qué piezas hay en un kit.
## Un nombre de pieza es «kit/pieza» («suburbano/tree-large») o solo «pieza» para
## los muebles de Kenney («loungeSofa»), igual que en los interiores.

const KITS := ["muebles", "comida", "mini_mercado", "mini_arcade", "suburbano", "industrial", "kit_edificios",
	"edificios_modulares", "tren", "montana_rusa"]
## Cuántas piezas apagadas se guardan como mucho de cada tipo.
const RESERVA_MAX := 24

static var _reserva := {}

## La ruta del modelo de una pieza (la misma regla de siempre).
static func ruta(nombre: String) -> String:
	return InteriorInstalacion._ruta_pieza(nombre)

## La escala a medidas reales (medida por kit; la comida, pieza a pieza).
static func escala(nombre: String, forzada: Variant = null) -> Vector3:
	return InteriorInstalacion._escala_de(nombre, forzada)

## Mallas centradas (huella en el origen, base en y = 0), caja y asiento.
static func datos(nombre: String) -> Dictionary:
	return InteriorInstalacion._pieza(nombre)

static func existe(nombre: String) -> bool:
	return ResourceLoader.exists(ruta(nombre))

## Una pieza lista para poner en la escena: de la reserva si hay, o nueva.
## `tonos`: {material: Color} para teñirla («carpet» = la tela, «wood» = la
## madera...), como en los interiores; sin nada, los tonos propios de la pieza.
static func tomar(nombre: String, forzada: Variant = null, tonos: Dictionary = {}) -> Node3D:
	var t := (InteriorInstalacion.TONOS_PIEZA.get(nombre, {}) as Dictionary).duplicate() if not nombre.contains("/") else {}
	t.merge(tonos, true)
	var clave := _clave(nombre, t)
	var lista: Array = _reserva.get(clave, [])
	while not lista.is_empty():
		var n: Node3D = lista.pop_back()
		if is_instance_valid(n):
			n.visible = true
			n.transform = Transform3D.IDENTITY
			n.set_meta("escala", escala(nombre, forzada))
			(n.get_child(0) as Node3D).scale = escala(nombre, forzada)
			return n
	return _nueva(nombre, forzada, t)

static func _clave(nombre: String, tonos: Dictionary) -> String:
	return nombre if tonos.is_empty() else nombre + "|" + str(tonos)

static func _nueva(nombre: String, forzada: Variant, tonos: Dictionary) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "Pieza_" + nombre.replace("/", "_")
	raiz.set_meta("pieza", nombre)
	raiz.set_meta("tonos", tonos)
	raiz.set_meta("escala", escala(nombre, forzada))
	## Un nodo intermedio lleva la escala: así la pieza se gira y se mueve con
	## su raíz sin deformarse, y `a_datos` lee la escala aparte.
	var cuerpo := Node3D.new()
	cuerpo.name = "Cuerpo"
	cuerpo.scale = escala(nombre, forzada)
	raiz.add_child(cuerpo)
	for e: Array in datos(nombre)["mallas"]:
		var mi := MeshInstance3D.new()
		mi.mesh = InteriorInstalacion._malla_tenida(e[0], tonos)
		mi.transform = e[1]
		cuerpo.add_child(mi)
	return raiz

## La pieza se deja de usar: sale de la escena y espera, apagada, a la próxima.
static func devolver(n: Node3D) -> void:
	if n == null or not is_instance_valid(n):
		return
	var nombre := String(n.get_meta("pieza", ""))
	var clave := _clave(nombre, n.get_meta("tonos", {}))
	if n.get_parent() != null:
		n.get_parent().remove_child(n)
	var lista: Array = _reserva.get(clave, [])
	if nombre == "" or lista.size() >= RESERVA_MAX:
		n.free()
		return
	n.visible = false
	lista.append(n)
	_reserva[clave] = lista

## Cuántas hay guardadas de una pieza sin teñir (para las pruebas).
static func en_reserva(nombre: String) -> int:
	return (_reserva.get(nombre, []) as Array).size()

## Vacía la reserva (al cerrar una escena grande, para no guardar memoria de más).
static func vaciar_reserva() -> void:
	for nombre: String in _reserva:
		for n: Node3D in _reserva[nombre]:
			if is_instance_valid(n):
				n.free()
	_reserva.clear()

# ------------------------------------------------------------- conjuntos

## UNIR: forma un conjunto con estas piezas, que conservan su sitio en el mundo.
## Devuelve el nodo del conjunto, colgado donde estaba la primera pieza.
static func unir(piezas: Array, nombre_conjunto := "Conjunto") -> Node3D:
	var c := Node3D.new()
	c.name = nombre_conjunto
	c.set_meta("conjunto", true)
	if piezas.is_empty():
		return c
	var primera: Node3D = piezas[0]
	var padre := primera.get_parent()
	if padre != null:
		padre.add_child(c)
		c.global_transform = Transform3D(Basis.IDENTITY, primera.global_position)
	for p: Node3D in piezas:
		var g := p.global_transform if p.is_inside_tree() else p.transform
		if p.get_parent() != null:
			p.get_parent().remove_child(p)
		c.add_child(p)
		if c.is_inside_tree():
			p.global_transform = g
		else:
			p.transform = g
	return c

## SEPARAR: deshace el conjunto; sus piezas quedan sueltas en el mismo sitio.
static func separar(c: Node3D) -> Array[Node3D]:
	var sueltas: Array[Node3D] = []
	var padre := c.get_parent()
	for p in c.get_children():
		if not (p is Node3D):
			continue
		var g := (p as Node3D).global_transform if c.is_inside_tree() else c.transform * (p as Node3D).transform
		c.remove_child(p)
		if padre != null:
			padre.add_child(p)
			(p as Node3D).global_transform = g
		else:
			(p as Node3D).transform = g
		sueltas.append(p as Node3D)
	if padre != null:
		padre.remove_child(c)
	c.free()
	return sueltas

## Un conjunto (o una pieza suelta) como datos: [{pieza, p, giro, s}], en
## coordenadas del propio conjunto. Es lo que se guarda con la partida.
static func a_datos(c: Node3D) -> Array:
	var sal: Array = []
	var hijos: Array = c.get_children() if c.has_meta("conjunto") else [c]
	for p in hijos:
		if not (p is Node3D) or not (p as Node3D).has_meta("pieza"):
			continue
		var n := p as Node3D
		var t := n.transform if c.has_meta("conjunto") else Transform3D.IDENTITY
		var s: Vector3 = n.get_meta("escala", Vector3.ONE)
		var d := {"pieza": String(n.get_meta("pieza")), "p": [t.origin.x, t.origin.y, t.origin.z],
			"giro": t.basis.get_euler().y, "s": [s.x, s.y, s.z]}
		var tonos: Dictionary = n.get_meta("tonos", {})
		if not tonos.is_empty():
			var th := {}
			for k: String in tonos:
				th[k] = (tonos[k] as Color).to_html(false)
			d["tonos"] = th
		sal.append(d)
	return sal

## Rearma un conjunto desde sus datos (las piezas salen de la reserva si hay).
static func de_datos(lista: Array, nombre_conjunto := "Conjunto") -> Node3D:
	var c := Node3D.new()
	c.name = nombre_conjunto
	c.set_meta("conjunto", true)
	for d: Dictionary in lista:
		var nombre := String(d.get("pieza", ""))
		if nombre == "" or not existe(nombre):
			continue
		var s: Array = d.get("s", [1, 1, 1])
		var tonos := {}
		for k: String in (d.get("tonos", {}) as Dictionary):
			tonos[k] = Color(String(d["tonos"][k]))
		var n := tomar(nombre, Vector3(float(s[0]), float(s[1]), float(s[2])), tonos)
		var p: Array = d.get("p", [0, 0, 0])
		n.transform = Transform3D(Basis(Vector3.UP, float(d.get("giro", 0.0))), Vector3(float(p[0]), float(p[1]), float(p[2])))
		c.add_child(n)
	return c

## Las piezas de un kit (nombres listos para `tomar`). Funciona también en el
## juego exportado, donde junto al modelo solo queda su `.import`/`.remap`.
static func listar(kit: String) -> PackedStringArray:
	var sal := PackedStringArray()
	var d := DirAccess.open("res://assets/kenney/" + kit)
	if d == null:
		return sal
	for f in d.get_files():
		var base := f.trim_suffix(".import").trim_suffix(".remap")
		if base.ends_with(".glb"):
			var nombre := base.trim_suffix(".glb") if kit == "muebles" else "%s/%s" % [kit, base.trim_suffix(".glb")]
			if not sal.has(nombre):
				sal.append(nombre)
	return sal
