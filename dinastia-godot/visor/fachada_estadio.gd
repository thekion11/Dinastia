class_name FachadaEstadio
extends "res://visor/fachada_estadio_p2.gd"
## [Capa 3/3 de `fachada_estadio.gd`] _material, _volcar, montar

static func _material(clave: String, p: Dictionary) -> StandardMaterial3D:
	var m: StandardMaterial3D
	var estilo: String = p["estilo"]
	match clave:
		K_ESTRUCTURA:
			if estilo in ["clasico", "porticos"]:
				m = Texturas.hormigon(p["estructura"], 73).duplicate()
			else:
				m = StandardMaterial3D.new()
				m.albedo_color = p["estructura"]
				m.roughness = 0.55
				m.metallic = 0.15
		K_REVEST:
			if estilo == "membrana":
				m = Texturas.tela(p["revest"], 0.6).duplicate()
				## La trama a escala de lona (las UV van a 4 m por unidad).
				m.uv1_scale = Vector3(4.0, 4.0, 1.0)
				## De noche la membrana se enciende por dentro, como las de verdad.
				if p["noche"] == "noche":
					m.emission_enabled = true
					m.emission = (p["luz"] as Color).lerp(Color.WHITE, 0.5)
					m.emission_energy_multiplier = 0.35
			else:
				m = StandardMaterial3D.new()
				m.albedo_color = p["revest"]
				m.roughness = 0.5
				m.metallic = 0.25 if estilo in ["celosia", "barrio"] else 0.05
		K_PANEL:
			## Hormigón prefabricado más claro que la estructura (se lee el
			## despiece aunque la cara quede a la sombra).
			m = Texturas.hormigon((p["estructura"] as Color).lerp(Color(0.93, 0.92, 0.88), 0.55), 29).duplicate()
		K_ACENTO:
			m = StandardMaterial3D.new()
			m.albedo_color = p["acento"]
			m.roughness = 0.55
		K_VIDRIO:
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.035, 0.04, 0.05)
			m.metallic = 0.0
			m.roughness = 0.3
			m.metallic_specular = 0.55
			## Algo de luz dentro: vestíbulos y escaleras encendidas.
			m.emission_enabled = true
			m.emission = Color(1.0, 0.86, 0.62)
			m.emission_energy_multiplier = 0.55 if p["noche"] == "noche" else 0.0
		K_LUZ:
			m = StandardMaterial3D.new()
			m.albedo_color = p["luz"]
			m.emission_enabled = true
			m.emission = p["luz"]
			var energia := {"noche": 2.6, "tarde": 1.1, "niebla": 1.2, "lluvia": 1.2}
			m.emission_energy_multiplier = float(energia.get(p["noche"], 0.45))
		_:  # metal de calle: tornos, barandillas
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.62, 0.64, 0.67)
			m.roughness = 0.35
			m.metallic = 0.45
	return m

static func _volcar(nodo: Node3D, nombre: String, malla: _Malla, p: Dictionary, rango: float) -> void:
	var am := malla.cerrar(func(k: String) -> Material: return _material(k, p))
	if am == null:
		return
	var mi := MeshInstance3D.new()
	mi.name = nombre
	mi.mesh = am
	if rango > 0.0:
		mi.visibility_range_end = rango
		mi.visibility_range_end_margin = rango * 0.1
	nodo.add_child(mi)

## ---------------------------------------------------------------------------
## EL MONTAJE
## ---------------------------------------------------------------------------
static func montar(root: Node3D, est: Dictionary, caras: Array, seed_val: int, niveles: int,
		escudo: Texture2D = null) -> Node3D:
	var estilo := estilo_de(est, seed_val, niveles)
	var h := absi(("fachada_var:%d" % seed_val).hash())
	var p := _paleta(est, estilo, h)
	var nodo := Node3D.new()
	nodo.name = "Fachada"
	nodo.set_meta("estilo", estilo)
	root.add_child(nodo)
	var grande := _Malla.new()
	var detalle := _Malla.new()
	var ctx := {"estilo": estilo, "h": h, "p": p, "grande": grande, "detalle": detalle,
		"nodo": nodo, "puerta": 0, "escudo": escudo, "escudo_puesto": false}
	## Las puertas se numeran en el orden de las caras (tribunas y luego esquinas).
	for c: Dictionary in caras:
		if float(c["L"]) < 2.0 or float(c["H"]) < 2.0:
			continue
		_vestir(ctx, c)
	_volcar(nodo, "FachadaEstructura", grande, p, 0.0)
	_volcar(nodo, "FachadaDetalle", detalle, p, RANGO_DETALLE)
	return nodo
