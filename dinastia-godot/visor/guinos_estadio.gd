class_name GuinosEstadio
extends RefCounted
## LOS GUIÑOS DE CADA ESTADIO (MEGAPLAN fase 4, E9). `ESTADIO_CLUB` ya copiaba
## la arquitectura de 176 estadios reales (forma, bandejas, techo, pista,
## focos, fachada) y traía su RASGO en texto -«Herradura abierta a la
## cordillera», «Cuatro torres rojas en las esquinas», «Junto al río»-, pero
## nadie lo dibujaba. Aquí el rasgo se convierte en lo que se ve por encima de
## la grada desde la tele: la montaña, el agua, el desierto, las torres, el
## arco del techo. Y cada estadio gana un APODO genérico (nunca el nombre
## oficial: «El Coloso», «La Caldera», «El Mirador»...), que sale en el
## rótulo del partido.

## El apodo, sacado de la forma, el techo y el rasgo. Siempre el mismo para el
## mismo estadio; "" si no tiene nada que lo distinga.
static func apodo(est: Dictionary) -> String:
	var r := String(est.get("rasgo", "")).to_lower()
	var reglas := [
		["calabaza", "La Calabaza"], ["caldera", "La Caldera"], ["olla", "La Olla"],
		["muralla", "La Muralla"], ["volcán", "El Volcán"], ["burbujas", "Las Burbujas"],
		["joya", "La Joya"], ["templo", "El Templo"], ["teatro", "El Teatro"],
		["cilindro", "El Cilindro"], ["costillas", "Las Costillas"], ["bosque", "El Bosque"],
		["cordillera", "El Mirador"], ["cerro", "El Mirador"], ["montaña", "El Mirador"],
		["lago", "La Ribera"], ["laguna", "La Ribera"], ["río", "La Ribera"], ["támesis", "La Ribera"],
		["mar", "El Malecón"], ["rambla", "El Malecón"], ["desierto", "El Oasis"],
		["minero", "La Mina"], ["acerero", "El Horno"], ["torres rojas", "Las Torres"],
		["rampas", "Las Rampas"], ["torre", "La Torre"], ["3.600", "El Techo del Mundo"],
		["2.300", "La Altura"], ["altura", "La Altura"], ["madera", "El Tablón"],
		["ladrillo", "El Ladrillo"], ["mosaico", "El Mosaico"], ["mural", "El Mural"],
		["barrio", "El Barrio"], ["monumental", "El Monumental"], ["coloso", "El Coloso"],
		["gigante", "El Gigante"], ["retráctil", "La Cúpula"], ["membrana", "La Membrana"],
		["arco", "El Arco"], ["mundialista", "El Mundialista"], ["olímpico", "El Olímpico"],
		["pista", "El Olímpico"], ["nacional", "El Nacional"], ["vidrio", "La Vitrina"],
		["arena", "La Arena"], ["histórico", "El Decano"], ["antiguo", "El Decano"],
		["mítico", "El Decano"], ["techado", "La Caja"], ["empinad", "El Precipicio"],
	]
	for par: Array in reglas:
		if r.contains(String(par[0])):
			return String(par[1])
	if int(est.get("niveles", 1)) >= 3:
		return "El Coloso"
	return ""

## Dibuja los guiños del rasgo alrededor del estadio. `dx`/`dz`: medio ancho y
## medio largo de la cara interior de las tribunas; `fondo`: lo que miden las
## tribunas hacia fuera; `alto`: su altura.
static func montar(root: Node3D, est: Dictionary, dx: float, dz: float, fondo: float, alto: float) -> void:
	var r := String(est.get("rasgo", "")).to_lower()
	if r == "":
		return
	var ax := dx + fondo + 6.0     ## justo por fuera de la grada, de lado
	var az := dz + fondo + 6.0     ## y de fondo
	var nodo := Node3D.new()
	nodo.name = "GuinosEstadio"
	root.add_child(nodo)
	## EL FONDO NATURAL: montaña, volcán, cerros.
	if _hay(r, ["cordillera", "montaña", "3.600", "pie del volcán", "cerro", "altura", "2.300"]):
		var nieve := _hay(r, ["cordillera", "3.600", "volcán"])
		var volcan := r.contains("pie del volcán")
		for k in 5:
			var x := -160.0 + float(k) * 80.0 + float(k % 2) * 25.0
			var h := (95.0 if volcan and k == 2 else 55.0 + float((k * 37) % 30)) * (1.25 if nieve else 0.8)
			_monte(nodo, Vector3(x, 0, -(az + 130.0 + float(k % 3) * 25.0)), h, h * 1.4, nieve, volcan and k == 2)
	## EL AGUA: río, lago, laguna, mar, rambla.
	if _hay(r, ["río", "támesis", "lago", "laguna", "mar", "rambla", "porteño", "caribe"]):
		var mar := _hay(r, ["mar", "rambla", "porteño", "caribe"])
		_agua(nodo, Vector3(ax + (90.0 if mar else 30.0), -0.04, 0), Vector2(160.0 if mar else 40.0, 600.0 if mar else 400.0))
	## EL DESIERTO: arena y dunas bajas alrededor.
	if r.contains("desierto"):
		var arena := StandardMaterial3D.new()
		arena.albedo_color = Color(0.78, 0.64, 0.42)
		arena.roughness = 1.0
		var suelo := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(900, 900)
		suelo.mesh = pm
		suelo.material_override = arena
		suelo.position = Vector3(0, -0.1, 0)  ## sobre la explanada (-0.15), bajo el césped
		nodo.add_child(suelo)
		for k in 14:
			var a := TAU * float(k) / 14.0 + 0.3
			var rad := az + 70.0 + float((k * 23) % 40)
			_duna(nodo, Vector3(cos(a) * rad, 0, sin(a) * rad), arena)
	## EL BOSQUE: un anillo de árboles por fuera.
	if r.contains("bosque"):
		var hoja := StandardMaterial3D.new()
		hoja.albedo_color = Color(0.13, 0.3, 0.14)
		for k in 60:
			var a := TAU * float(k) / 60.0
			var rad := az + 18.0 + float((k * 13) % 20)
			_arbol(nodo, Vector3(cos(a) * rad * (ax / az), 0, sin(a) * rad), 14.0 + float((k * 7) % 9), hoja)
	## LAS TORRES: rojas en las esquinas, de luz, de rampas, o una torre sola.
	if r.contains("torres rojas"):
		_torres(nodo, ax - 4.0, az - 4.0, alto + 22.0, Color(0.72, 0.12, 0.1), false)
	elif r.contains("rampas"):
		_torres(nodo, ax - 2.0, az - 2.0, alto + 6.0, Color(0.55, 0.55, 0.57), true)
	elif r.contains("torre") and not r.contains("torres de luz"):
		var t := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(7.0, alto + 34.0, 7.0)
		t.mesh = bm
		t.material_override = _mate(Color(0.62, 0.58, 0.52) if not r.contains("ladrillo") else Color(0.55, 0.24, 0.17))
		t.position = Vector3(ax + 2.0, (alto + 34.0) / 2.0, -dz * 0.4)
		nodo.add_child(t)
	## EL TECHO QUE SE VE: arco, burbujas, carpa, cometa.
	if r.contains("techo en arco") or r.contains("cometa"):
		var arco := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = dz + fondo * 0.6
		tm.outer_radius = dz + fondo * 0.6 + 2.2
		tm.rings = 48
		arco.mesh = tm
		arco.material_override = _metal(Color(0.85, 0.86, 0.9))
		arco.rotation = Vector3(0, 0, PI / 2.0)
		arco.scale = Vector3(1.0, 1.0, 0.45)
		arco.position = Vector3(0, alto * 0.3, 0)
		nodo.add_child(arco)
	if r.contains("burbujas") or r.contains("carpa"):
		var tela := _mate(Color(0.95, 0.95, 0.97) if r.contains("burbujas") else Color(0.92, 0.88, 0.78))
		for sx in [-1.0, 1.0]:
			for k in 4:
				var d := MeshInstance3D.new()
				var sm := SphereMesh.new()
				sm.radius = 7.0
				sm.height = 7.0 if r.contains("burbujas") else 9.0
				sm.is_hemisphere = true
				d.mesh = sm
				d.material_override = tela
				d.position = Vector3(sx * (dx + fondo * 0.5), alto + 0.5, -dz * 0.6 + float(k) * dz * 0.4)
				nodo.add_child(d)
	## LOS EDIFICIOS: un muro de ciudad detrás de un fondo.
	if r.contains("edificios") or r.contains("en lo alto de la ciudad"):
		for k in 9:
			var b := MeshInstance3D.new()
			var bm2 := BoxMesh.new()
			var h2 := 18.0 + float((k * 29) % 34)
			bm2.size = Vector3(11.0, h2, 10.0)
			b.mesh = bm2
			b.material_override = _mate(Color(0.5, 0.5, 0.53).lerp(Color(0.75, 0.68, 0.58), float(k % 3) / 3.0))
			b.position = Vector3(-50.0 + float(k) * 12.5, h2 / 2.0, -(az + 14.0))
			nodo.add_child(b)

static func _hay(r: String, claves: Array) -> bool:
	for c: String in claves:
		if r.contains(c):
			return true
	return false

static func _mate(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.95
	return m

static func _metal(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.85
	m.roughness = 0.3
	return m

static func _monte(padre: Node3D, pos: Vector3, alto: float, base: float, nieve: bool, crater: bool) -> void:
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = base * (0.12 if crater else 0.02)
	cm.bottom_radius = base
	cm.height = alto
	cm.radial_segments = 9
	m.mesh = cm
	m.material_override = _mate(Color(0.36, 0.33, 0.3) if not crater else Color(0.28, 0.24, 0.22))
	m.position = pos + Vector3(0, alto / 2.0, 0)
	padre.add_child(m)
	if nieve:
		var n := MeshInstance3D.new()
		var cn := CylinderMesh.new()
		cn.top_radius = cm.top_radius
		cn.bottom_radius = base * 0.32
		cn.height = alto * 0.3
		cn.radial_segments = 9
		n.mesh = cn
		n.material_override = _mate(Color(0.93, 0.95, 0.98))
		n.position = pos + Vector3(0, alto * 0.85 + 0.2, 0)
		padre.add_child(n)

static func _agua(padre: Node3D, pos: Vector3, tam: Vector2) -> void:
	var m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = tam
	pm.subdivide_width = 24
	pm.subdivide_depth = 24
	m.mesh = pm
	if ResourceLoader.exists("res://visor/agua.gdshader"):
		var mat := ShaderMaterial.new()
		mat.shader = load("res://visor/agua.gdshader")
		mat.set_shader_parameter("altura_ola", 0.12)  ## que la ola no tape la orilla
		m.material_override = mat
	else:
		m.material_override = _metal(Color(0.12, 0.3, 0.42))
	m.position = pos
	padre.add_child(m)

static func _duna(padre: Node3D, pos: Vector3, mat: Material) -> void:
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 16.0
	sm.height = 7.0
	sm.is_hemisphere = true
	m.mesh = sm
	m.material_override = mat
	m.position = pos + Vector3(0, -0.1, 0)
	m.scale = Vector3(2.2, 1.0, 1.0)
	m.rotation.y = atan2(pos.x, pos.z)
	padre.add_child(m)

static func _arbol(padre: Node3D, pos: Vector3, alto: float, hoja: Material) -> void:
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = alto * 0.28
	cm.height = alto
	cm.radial_segments = 7
	m.mesh = cm
	m.material_override = hoja
	m.position = pos + Vector3(0, alto / 2.0 + 1.5, 0)
	padre.add_child(m)

static func _torres(padre: Node3D, x: float, z: float, alto: float, col: Color, cilindro: bool) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var m := MeshInstance3D.new()
			if cilindro:
				var cm := CylinderMesh.new()
				cm.top_radius = 5.5
				cm.bottom_radius = 5.5
				cm.height = alto
				m.mesh = cm
			else:
				var bm := BoxMesh.new()
				bm.size = Vector3(6.0, alto, 6.0)
				m.mesh = bm
			m.material_override = _mate(col)
			m.position = Vector3(sx * x, alto / 2.0, sz * z)
			padre.add_child(m)
