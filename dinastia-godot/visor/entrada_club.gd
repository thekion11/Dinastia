class_name EntradaClub
extends RefCounted
## LA ENTRADA DEL CLUB (8-10-2026).
##
## Pedido: «la entrada es poco realista, y debe haber un portero que abra; que
## haya un diálogo y una animación». Antes la puerta del club era un hueco en
## el muro con un toldo. Ahora es una entrada de verdad, en la fachada trasera
## del edificio del vestuario (coordenadas del estadio, como `TunelVestuario`):
##   - puertas de cristal CORREDERAS (dos hojas que se esconden en el muro),
##   - pórtico con pilastras del club, marquesina con el nombre y escudo,
##   - escalón de granito y felpudo, maceteros y dos mástiles con banderas,
##   - la GARITA del portero (control de acceso) a un lado.
## El portero es una persona más de `PersonalEstadio` (puesto «Puerta»): desde
## la calle se habla con él (`RecorridoClub.dialogo_portero`) y es él quien abre.

const HOJA := TunelVestuario.PUERTA_MEDIO
const ALTO_HOJA := 2.55
const SEG_ABRIR := 0.9

static func centro(x0: float) -> float:
	return x0 + TunelVestuario.PUERTA_X

## Donde espera el portero (junto a la puerta, del lado de la garita) y la
## garita (para que la ciudad no meta gente ni coches dentro).
static func sitio_portero(x0: float, z_fin: float) -> Vector3:
	return Vector3(centro(x0) + HOJA + 0.9, 0.02, z_fin + 1.3)

static func rect_garita(x0: float, z_fin: float) -> Rect2:
	return Rect2(centro(x0) + HOJA + 1.5, z_fin + 0.35, 1.8, 1.8)

static func montar(nodo: Node3D, x0: float, z_fin: float, c1: Color, c2: Color,
		horm: StandardMaterial3D, nombre: String, mi: Club) -> void:
	var px := centro(x0)
	var zf := z_fin + 0.3
	var e := Node3D.new()
	e.name = "EntradaClub"
	nodo.add_child(e)
	var acero := TunelVestuario._mat(Color(0.3, 0.32, 0.35), 0.35)
	acero.metallic = 0.7
	var granito := TunelVestuario._mat(Color(0.36, 0.37, 0.4), 0.45)
	var club := TunelVestuario._mat(c1, 0.5)
	var club_osc := TunelVestuario._mat(c1.lerp(Color(0.08, 0.08, 0.1), 0.35), 0.5)
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color(0.55, 0.7, 0.78, 0.35)
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidrio.roughness = 0.05
	vidrio.metallic = 0.4

	## LAS PUERTAS: dos hojas de cristal con marco, en el plano del muro.
	var puerta := Node3D.new()
	puerta.name = "PuertaClub"
	puerta.position = Vector3(px, 0.0, z_fin + 0.15)
	puerta.add_to_group("puerta_club")
	puerta.set_meta("abierta", false)
	e.add_child(puerta)
	for lado in [-1.0, 1.0]:
		var hoja := Node3D.new()
		hoja.name = "Hoja" + ("I" if lado < 0.0 else "D")
		hoja.position = Vector3(lado * HOJA / 2.0, 0, 0)
		hoja.set_meta("cerrada", hoja.position)
		hoja.set_meta("abierta", Vector3(lado * HOJA * 1.45, 0, 0.0))
		puerta.add_child(hoja)
		TunelVestuario._caja(hoja, Vector3(0, ALTO_HOJA / 2.0, 0), Vector3(HOJA - 0.06, ALTO_HOJA - 0.1, 0.03), vidrio, false)
		for yy in [0.05, ALTO_HOJA - 0.05]:
			TunelVestuario._caja(hoja, Vector3(0, yy, 0), Vector3(HOJA, 0.1, 0.07), acero, false)
		for xx in [-HOJA / 2.0 + 0.04, HOJA / 2.0 - 0.04]:
			TunelVestuario._caja(hoja, Vector3(xx, ALTO_HOJA / 2.0, 0), Vector3(0.08, ALTO_HOJA, 0.07), acero, false)
		## Tirador vertical junto al canto de cierre y una franja del club.
		TunelVestuario._caja(hoja, Vector3(-lado * (HOJA / 2.0 - 0.18), 1.1, 0.07), Vector3(0.04, 0.9, 0.04), acero, false)
		TunelVestuario._caja(hoja, Vector3(0, 1.45, 0.02), Vector3(HOJA - 0.2, 0.08, 0.01), club, false)
	## Dintel de acero sobre las hojas (el hueco del muro llega a 2,6 m).
	TunelVestuario._caja(e, Vector3(px, ALTO_HOJA + 0.03, z_fin + 0.15), Vector3(HOJA * 2.0 + 0.1, 0.1, 0.12), acero, false)

	## EL PÓRTICO: pilastras del club, frontón con el nombre y el escudo.
	for lado2 in [-1.0, 1.0]:
		TunelVestuario._caja(e, Vector3(px + lado2 * (HOJA + 0.35), 1.75, zf + 0.15), Vector3(0.55, 3.5, 0.3), club, true)
	TunelVestuario._caja(e, Vector3(px, 3.85, zf + 0.15), Vector3(HOJA * 2.0 + 1.3, 0.7, 0.3), club_osc, false)
	var letrero := Label3D.new()
	letrero.text = nombre.to_upper()
	letrero.font_size = 56
	letrero.pixel_size = 0.006
	letrero.outline_size = 8
	letrero.modulate = Color(1, 0.96, 0.85)
	letrero.position = Vector3(px, 3.85, zf + 0.32)
	e.add_child(letrero)
	if mi != null:
		var tex := Escudo.textura(mi, 256)
		if tex != null:
			var esc := Sprite3D.new()
			esc.texture = tex
			esc.pixel_size = 1.1 / 256.0
			esc.position = Vector3(px, 4.75, zf + 0.05)
			esc.shaded = false
			e.add_child(esc)

	## LA MARQUESINA: losa volada con dos tirantes y luz por debajo.
	var fondo_m := 2.6
	TunelVestuario._caja(e, Vector3(px, 3.08, zf + fondo_m / 2.0), Vector3(HOJA * 2.0 + 2.8, 0.16, fondo_m), acero, false)
	TunelVestuario._caja(e, Vector3(px, 3.2, zf + fondo_m - 0.05), Vector3(HOJA * 2.0 + 2.9, 0.22, 0.12), club, false)
	for lado3 in [-1.0, 1.0]:
		var tir := TunelVestuario._caja(e, Vector3(px + lado3 * (HOJA + 1.2), 3.6, zf + fondo_m * 0.5), Vector3(0.06, 0.06, fondo_m * 1.15), acero, false)
		tir.rotation.x = -0.42
	var luz := StandardMaterial3D.new()
	luz.albedo_color = Color(1, 0.97, 0.88)
	luz.emission_enabled = true
	luz.emission = Color(1, 0.95, 0.82)
	luz.emission_energy_multiplier = 1.8
	TunelVestuario._caja(e, Vector3(px, 2.99, zf + fondo_m * 0.55), Vector3(HOJA * 2.0, 0.02, 0.25), luz, false)
	var o := OmniLight3D.new()
	o.position = Vector3(px, 2.7, zf + 1.2)
	o.omni_range = 6.0
	o.light_energy = 0.9
	o.light_color = Color(1, 0.94, 0.82)
	e.add_child(o)

	## EL SUELO: escalón de granito y felpudo del club.
	TunelVestuario._caja(e, Vector3(px, 0.07, zf + 1.1), Vector3(HOJA * 2.0 + 2.6, 0.14, 2.2), granito, false)
	TunelVestuario._caja(e, Vector3(px, 0.15, zf + 0.75), Vector3(HOJA * 2.0 - 0.2, 0.02, 1.1), TunelVestuario._mat(c1.darkened(0.25), 0.95), false)
	## Placa y maceteros.
	TunelVestuario._rotulo(e, Idiomas.t("ENTRADA DEL CLUB · SOLO PERSONAL"), Vector3(px - HOJA - 0.35, 2.2, zf + 0.32), 0.0, 22, Color(1, 1, 1))
	var hoja_v := TunelVestuario._mat(Color(0.2, 0.42, 0.2), 0.9)
	var maceta := TunelVestuario._mat(Color(0.18, 0.18, 0.2), 0.6)
	for lado4 in [-1.0, 1.0]:
		var mx: float = px + lado4 * (HOJA + 1.15)
		TunelVestuario._caja(e, Vector3(mx, 0.45, zf + 0.6), Vector3(0.7, 0.9, 0.7), maceta, false)
		var arbusto := MeshInstance3D.new()
		var esf := SphereMesh.new()
		esf.radius = 0.5
		esf.height = 1.1
		arbusto.mesh = esf
		arbusto.material_override = hoja_v
		arbusto.position = Vector3(mx, 1.3, zf + 0.6)
		e.add_child(arbusto)
	## Dos mástiles con las banderas del club.
	for k in 2:
		var bx := px - HOJA - 3.0 - float(k) * 1.6
		TunelVestuario._caja(e, Vector3(bx, 3.6, zf + 2.4), Vector3(0.09, 7.2, 0.09), acero, false)
		var tela := TunelVestuario._caja(e, Vector3(bx + 0.75, 6.4, zf + 2.4), Vector3(1.4, 0.9, 0.02),
			TunelVestuario._mat(c1 if k == 0 else c2, 0.8), false)
		tela.rotation.y = 0.25

	## LA GARITA del portero: cabina con ventanas, mostrador y su luz.
	var g := rect_garita(x0, z_fin)
	var gc := Vector3(g.get_center().x, 0, g.get_center().y)
	var blanco := TunelVestuario._mat(Color(0.9, 0.9, 0.88), 0.7)
	TunelVestuario._caja(e, gc + Vector3(0, 0.5, 0), Vector3(g.size.x, 1.0, g.size.y), blanco, true)
	TunelVestuario._caja(e, gc + Vector3(0, 1.65, 0), Vector3(g.size.x - 0.05, 1.3, g.size.y - 0.05), vidrio, false)
	for cx in [-1.0, 1.0]:
		for cz in [-1.0, 1.0]:
			TunelVestuario._caja(e, gc + Vector3(cx * (g.size.x / 2.0 - 0.04), 1.65, cz * (g.size.y / 2.0 - 0.04)), Vector3(0.08, 1.3, 0.08), acero, false)
	TunelVestuario._caja(e, gc + Vector3(0, 2.4, 0), Vector3(g.size.x + 0.4, 0.2, g.size.y + 0.4), club_osc, false)
	TunelVestuario._rotulo(e, Idiomas.t("CONTROL DE ACCESO"), gc + Vector3(0, 2.4, g.size.y / 2.0 + 0.22), 0.0, 22, Color(1, 1, 1))
	var lg := OmniLight3D.new()
	lg.position = gc + Vector3(0, 2.0, 0)
	lg.omni_range = 3.5
	lg.light_energy = 0.6
	e.add_child(lg)

## Abre o cierra las hojas (deslizan dentro del muro). Vale para todas las
## puertas del club que haya en escena.
static func abrir(arbol: SceneTree, si: bool) -> void:
	if arbol == null:
		return
	for p: Node in arbol.get_nodes_in_group("puerta_club"):
		if bool(p.get_meta("abierta", false)) == si:
			continue
		p.set_meta("abierta", si)
		for h: Node in p.get_children():
			var hoja := h as Node3D
			var meta: Vector3 = hoja.get_meta("abierta" if si else "cerrada")
			var tw := hoja.create_tween()
			tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw.tween_property(hoja, "position", meta, SEG_ABRIR)
		Sonido.toca("puerta", Sonido.Bus.EFECTOS)

static func abierta(arbol: SceneTree) -> bool:
	if arbol == null:
		return false
	for p: Node in arbol.get_nodes_in_group("puerta_club"):
		return bool(p.get_meta("abierta", false))
	return false
