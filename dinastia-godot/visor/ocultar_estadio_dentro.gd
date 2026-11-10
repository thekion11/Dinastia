class_name OcultarEstadioDentro
extends RefCounted
## DENTRO DEL EDIFICIO DEL CLUB, LO DE FUERA NO SE DIBUJA (10-11-2026, rendimiento en móvil; la sesión 5 midió con `pruebas/medir_club.tscn` ~850 llamadas y 1,1 M de triángulos
## porque la cámara (Godot no oculta lo tapado) dibujaba también las gradas, la hinchada, los focos y el entorno detrás de las paredes; sin ellos ~340-370 llamadas).
## Se ocultan los hijos de primer nivel del estadio (`_raiz3d`) que no son luces, cámara, el edificio (`TunelVestuario`) ni el explorador. `Exterior` (la calle) y `Fachada` solo se
## conservan mientras pueden verse por una ABERTURA: la boca del túnel al campo (plano z = `z_boca`), la boca del túnel al vestuario (z = `z_out`) o las ventanas del fondo del edificio
## (plantas 1 y 2, plano z = `z_fin`+0,31). La decisión sale del campo de visión de la cámara (`boca_visible`): una rejilla de 0,6 m sobre la abertura con `is_position_in_frustum`; a
## menos de 1,5 m de ella siempre se ve. No desaparece nada que se viera: en cuanto la abertura entra en el campo de visión, vuelve (sesión 7).
##   · planta ≠ 0: estadio fuera siempre; calle y fachada solo con una ventana a la vista (los sótanos no tienen);
##   · planta 0, «Vestuario» (sala cerrada): estadio fuera si no se ve la boca del túnel (z_out);
##   · planta 0, «Túnel»: estadio, calle y fachada fuera si no se ve la boca al campo (z_boca);
##   · el campo, la banda y el acceso: todo se dibuja.
## Se guarda lo que estaba visible antes y se devuelve tal cual al salir al campo o del recorrido.

const CONSERVAR := ["TunelVestuario"]
const CALLE := ["Exterior", "Fachada"]
const META := "estadio_oculto_dentro"
const META_CLAVE := "estadio_oculto_dentro_clave"
const META_CONO := "estadio_oculto_dentro_cono"   ## {nodo: visible antes} de lo que el cono de visión por la boca deja fuera
const META_AABB := "estadio_aabb_cono"
const META_PLANTAS := "estadio_oculto_dentro_plantas"   ## {nodo «Planta_p»: visible antes}
const META_PLANTAS_CLAVE := "estadio_oculto_dentro_plantas_clave"

## Llamar cada vez que se refresca la zona (barato: solo actúa al cambiar lo que hay que ocultar). `camara` y `datos` (los del explorador) son opcionales; sin ellos, como antes
## (planta ≠ 0 oculta todo salvo la calle y la fachada).
static func actualizar(explorador: Node3D, planta: int, zona := "", camara: Camera3D = null, datos: Dictionary = {}, viaje := false) -> void:
	_plantas(explorador, planta, zona, viaje)
	_estadio_y_calle(explorador, planta, zona, camara, datos)
	_cono(explorador, planta, zona, camara, datos)

static func _estadio_y_calle(explorador: Node3D, planta: int, zona: String, camara: Camera3D, datos: Dictionary) -> void:
	var ver := camara != null and not datos.is_empty()
	var estadio := false
	var calle := false
	if planta != 0:
		estadio = true
		if ver and datos.has("z_fin"):
			calle = planta < 0 or not ventana_visible(camara, datos, planta)
	elif ver and zona == "Vestuario" and datos.has("z_out"):   ## (10-11) sin la medida del túnel no se oculta nada
		estadio = not boca_visible(camara, datos, float(datos["z_out"]))
	elif ver and zona == "Túnel" and datos.has("z_boca"):
		estadio = not boca_visible(camara, datos, float(datos["z_boca"]))
		calle = estadio
	var clave := (1 if estadio else 0) + (2 if calle else 0)
	if int(explorador.get_meta(META_CLAVE, 0)) == clave:
		return
	_restaurar_cono(explorador)   ## lo que el cono dejó fuera vuelve antes de anotar «lo que estaba visible»
	_devolver_estadio(explorador)
	if clave == 0:
		return
	var raiz := explorador.get_parent()
	if raiz == null:
		return
	var ocultos: Dictionary = {}
	for h in raiz.get_children():
		if not (h is Node3D) or h is Light3D or h is Camera3D or h == explorador or String(h.name) in CONSERVAR:
			continue
		if String(h.name) in CALLE:
			if not calle:
				continue
		elif not estadio:
			continue
		ocultos[h] = (h as Node3D).visible
		(h as Node3D).visible = false
	explorador.set_meta(META, ocultos)
	explorador.set_meta(META_CLAVE, clave)

## ¿Cae alguna parte de la abertura rectangular (a lo ancho `x0` ± `medio`, de y = `y_min` a `y_max`, en el plano z) dentro del campo de visión de `camara`?
static func _abertura_visible(camara: Camera3D, x0: float, medio: float, y_min: float, y_max: float, z: float) -> bool:
	if not camara.is_inside_tree():
		return true
	if absf(camara.position.z - z) < 1.5:
		return true
	var padre := camara.get_parent() as Node3D
	var x := -medio
	while x <= medio + 0.01:
		var y := y_min
		while y <= y_max + 0.01:
			var q := Vector3(x0 + x, y, z)
			if camara.is_position_in_frustum(padre.to_global(q) if padre != null else q):
				return true
			y += 0.6
		x += 0.6
	return false

## La boca del túnel (el plano z, con margen para los marcos).
static func boca_visible(camara: Camera3D, datos: Dictionary, z: float) -> bool:
	return _abertura_visible(camara, float(datos["x0"]), TunelMedidas.MEDIO + 0.5, 0.0, TunelMedidas.ALTO + 0.5, z)

## Las ventanas corridas del fondo del edificio de una planta ≥ 1 (a z_fin + 0,31, de y0 + 1,2 a y0 + 2,6, casi todo el ancho).
static func ventana_visible(camara: Camera3D, datos: Dictionary, planta: int) -> bool:
	var y0 := float(planta) * EdificioClub.ALTO_PLANTA
	return _abertura_visible(camara, float(datos["x0"]), TunelMedidas.VEST_MEDIO - 0.5, y0 + 1.2, y0 + 2.6, float(datos["z_fin"]) + 0.31)

## EL CONO POR LA BOCA DEL TÚNEL (sesión 7): con la boca a la vista, lo único del estadio que se ve es lo que cae dentro de la pirámide que va de la cámara a la boca (con 0,5 m de margen).
## Cada hijo de primer nivel del estadio (tribunas, entorno…) cuya caja queda entera fuera de esa pirámide, o detrás de la boca, no se dibuja. Se recalcula cada fotograma (unas decenas de cajas)
## y se devuelve al salir del túnel. Solo planta 0 y zona «Túnel» con la cámara a más de 1,5 m del plano de la boca.
static func _cono(explorador: Node3D, planta: int, zona: String, camara: Camera3D, datos: Dictionary) -> void:
	var raiz := explorador.get_parent()
	var antes: Dictionary = explorador.get_meta(META_CONO, {})
	var activo := planta == 0 and zona == "Túnel" and camara != null and raiz != null and datos.has("z_boca") and datos.has("x0") \
		and absf(camara.position.z - float(datos["z_boca"])) > 1.5 and int(explorador.get_meta(META_CLAVE, 0)) == 0
	if not activo:
		if not antes.is_empty():
			for n: Variant in antes:
				if is_instance_valid(n):
					(n as Node3D).visible = bool(antes[n])
			explorador.set_meta(META_CONO, {})
		return
	var c := camara.position
	var z := float(datos["z_boca"])
	var x0 := float(datos["x0"])
	var m := TunelMedidas.MEDIO + 0.5
	var esq: Array[Vector3] = [Vector3(x0 - m, -0.5, z), Vector3(x0 + m, -0.5, z), Vector3(x0 + m, TunelMedidas.ALTO + 0.5, z), Vector3(x0 - m, TunelMedidas.ALTO + 0.5, z)]
	var centro := Vector3(x0, TunelMedidas.ALTO / 2.0, z)
	var planos: Array[Plane] = []
	for i in 4:
		var pl := Plane(c, esq[i], esq[(i + 1) % 4])
		if pl.distance_to(centro) < 0.0:
			pl = Plane(-pl.normal, -pl.d)
		planos.append(pl)
	planos.append(Plane(Vector3(0, 0, -1), Vector3(0, 0, z)))   ## solo lo que está más allá de la boca (z menor)
	for h in raiz.get_children():
		if not (h is Node3D) or h is Light3D or h is Camera3D or h == explorador or String(h.name) in CONSERVAR or String(h.name) in CALLE:
			continue
		var n := h as Node3D
		if not n.has_meta(META_AABB):
			n.set_meta(META_AABB, _caja_de(n))
		var caja: AABB = n.get_meta(META_AABB)
		if caja.size == Vector3.ZERO:
			continue
		var fuera := false
		for pl: Plane in planos:
			var todo_fuera := true
			for k in 8:
				if pl.distance_to(caja.get_endpoint(k)) >= 0.0:
					todo_fuera = false
					break
			if todo_fuera:
				fuera = true
				break
		if fuera and n.visible:
			if not antes.has(n):
				antes[n] = true
			n.visible = false
		elif not fuera and antes.has(n):
			n.visible = bool(antes[n])
			antes.erase(n)
	explorador.set_meta(META_CONO, antes)

static func _restaurar_cono(explorador: Node3D) -> void:
	var cono: Dictionary = explorador.get_meta(META_CONO, {})
	for n: Variant in cono:
		if is_instance_valid(n):
			(n as Node3D).visible = bool(cono[n])
	explorador.set_meta(META_CONO, {})

## La caja (en coordenadas de la raíz del estadio) de todo lo que dibuja un hijo del estadio.
static func _caja_de(n: Node3D) -> AABB:
	var caja := AABB()
	var primera := true
	var lista: Array = [n] if n is GeometryInstance3D else []
	lista.append_array(n.find_children("*", "GeometryInstance3D", true, false))
	for g: Variant in lista:
		var gi := g as GeometryInstance3D
		var t := Transform3D.IDENTITY
		var x: Node = gi
		while x != null and x != n.get_parent():
			if x is Node3D:
				t = (x as Node3D).transform * t
			x = x.get_parent()
		var a := t * gi.get_aabb()
		caja = a if primera else caja.merge(a)
		primera = false
	return caja

## LAS PLANTAS DEL EDIFICIO QUE NO SE VEN (sesión 7): cada planta cuelga de su nodo «Planta_p» (`EdificioClub.montar`). Dentro de la planta p solo se dibuja ella; en el vestuario y el
## túnel (cerrados) no se dibuja ninguna (el vestuario y su ascensor cuelgan del edificio, no de una planta); en el campo, la banda y el acceso (se ve la fachada) y mientras el ascensor viaja
## se dibujan todas. Se vuelve a calcular si el edificio se rehace (`EdificioClub.reconstruir`).
static func _plantas(explorador: Node3D, planta: int, zona: String, viaje: bool) -> void:
	var arbol := explorador.get_tree()
	var raiz := explorador.get_parent()
	var edificio: Node3D = null
	if arbol != null and raiz != null:
		for n: Node in arbol.get_nodes_in_group("edificio_club"):   ## (10-11) el de ESTA escena (otro club cargado a la vez no cuenta)
			if n is Node3D and raiz.is_ancestor_of(n):
				edificio = n
				break
	var oculta := -99   ## -99: ninguna; 99: todas; otro: todas menos esa
	if edificio != null and not viaje:
		if planta != 0:
			oculta = planta
		elif zona == "Vestuario" or zona == "Túnel":
			oculta = 99
	var clave := [oculta, edificio.get_instance_id() if edificio != null else 0]
	if explorador.get_meta(META_PLANTAS_CLAVE, [-99, 0]) == clave:
		return
	var antes: Dictionary = explorador.get_meta(META_PLANTAS, {})
	for n: Variant in antes:
		if is_instance_valid(n):
			(n as Node3D).visible = bool(antes[n])
	antes = {}
	if oculta != -99 and edificio != null:
		for h in edificio.get_children():
			if h is Node3D and h.has_meta("planta") and (oculta == 99 or int(h.get_meta("planta")) != oculta):
				antes[h] = (h as Node3D).visible
				(h as Node3D).visible = false
	explorador.set_meta(META_PLANTAS, antes)
	explorador.set_meta(META_PLANTAS_CLAVE, clave)

## Deja el estadio como estaba (también al cerrar el recorrido).
static func devolver(explorador: Node3D) -> void:
	_restaurar_cono(explorador)
	_devolver_estadio(explorador)
	_devolver_plantas(explorador)

static func _devolver_estadio(explorador: Node3D) -> void:
	var ocultos: Dictionary = explorador.get_meta(META, {})
	for h: Variant in ocultos:
		if is_instance_valid(h):
			(h as Node3D).visible = bool(ocultos[h])
	explorador.set_meta(META, {})
	explorador.set_meta(META_CLAVE, 0)

static func _devolver_plantas(explorador: Node3D) -> void:
	var plantas: Dictionary = explorador.get_meta(META_PLANTAS, {})
	for n: Variant in plantas:
		if is_instance_valid(n):
			(n as Node3D).visible = bool(plantas[n])
	explorador.set_meta(META_PLANTAS, {})
	explorador.set_meta(META_PLANTAS_CLAVE, [-99, 0])
