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
const META_PLANTAS := "estadio_oculto_dentro_plantas"   ## {nodo «Planta_p»: visible antes}
const META_PLANTAS_CLAVE := "estadio_oculto_dentro_plantas_clave"

## Llamar cada vez que se refresca la zona (barato: solo actúa al cambiar lo que hay que ocultar). `camara` y `datos` (los del explorador) son opcionales; sin ellos, como antes
## (planta ≠ 0 oculta todo salvo la calle y la fachada).
static func actualizar(explorador: Node3D, planta: int, zona := "", camara: Camera3D = null, datos: Dictionary = {}, viaje := false) -> void:
	_plantas(explorador, planta, zona, viaje)
	var ver := camara != null and not datos.is_empty()
	var estadio := false
	var calle := false
	if planta != 0:
		estadio = true
		if ver:
			calle = planta < 0 or not ventana_visible(camara, datos, planta)
	elif ver and zona == "Vestuario":
		estadio = not boca_visible(camara, datos, float(datos["z_out"]))
	elif ver and zona == "Túnel":
		estadio = not boca_visible(camara, datos, float(datos["z_boca"]))
		calle = estadio
	var clave := (1 if estadio else 0) + (2 if calle else 0)
	if int(explorador.get_meta(META_CLAVE, 0)) == clave:
		return
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

## LAS PLANTAS DEL EDIFICIO QUE NO SE VEN (sesión 7): cada planta cuelga de su nodo «Planta_p» (`EdificioClub.montar`). Dentro de la planta p solo se dibuja ella; en el vestuario y el
## túnel (cerrados) no se dibuja ninguna (el vestuario y su ascensor cuelgan del edificio, no de una planta); en el campo, la banda y el acceso (se ve la fachada) y mientras el ascensor viaja
## se dibujan todas. Se vuelve a calcular si el edificio se rehace (`EdificioClub.reconstruir`).
static func _plantas(explorador: Node3D, planta: int, zona: String, viaje: bool) -> void:
	var arbol := explorador.get_tree()
	var edificio := arbol.get_first_node_in_group("edificio_club") as Node3D if arbol != null else null
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
