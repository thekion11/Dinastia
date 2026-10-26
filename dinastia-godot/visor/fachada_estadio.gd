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
			## MURO CORTINA DE VERDAD (26-10-2026, «cajas grises»): era negro liso
			## (0,035) y desde la calle cada paño de vidrio se leía como un agujero
			## sin fondo entre las lamas. Ahora lleva su despiece: montantes cada
			## 1,33 m, travesaños cada 2 m y cada vidrio con su reflejo del cielo
			## (más claro arriba) y su tono propio. Mismas UV (en metros/4) y misma
			## llamada de dibujo: solo cambia el material.
			m = StandardMaterial3D.new()
			m.albedo_texture = _tex_muro_cortina(false)
			m.albedo_color = Color(0.5, 0.58, 0.66)
			m.metallic = 0.35
			m.roughness = 0.14
			m.metallic_specular = 0.6
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			## Algo de luz dentro: vestíbulos y escaleras encendidas (no todos los
			## vidrios por igual: la máscara enciende unos más que otros).
			m.emission_enabled = true
			m.emission = Color(1.0, 0.86, 0.62)
			m.emission_texture = _tex_muro_cortina(true)
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
	## LAS PIEZAS OSCURAS SE LEEN (26-10-2026): las lamas, la celosía o la chapa de un
	## club de negro eran una mancha sin relieve (todas sus caras igual de negras). Sin
	## tocar el color del club: brillo de pintura satinada (refleja el cielo en los
	## cantos que lo miran) y un borde de luz rasante en las aristas.
	if clave in [K_REVEST, K_ACENTO] and m.albedo_color.get_luminance() < 0.16 and m.albedo_texture == null:
		m.roughness = 0.28
		m.metallic_specular = 0.8
		m.rim_enabled = true
		m.rim = 0.55
		m.rim_tint = 0.35
	return m

## La textura del muro cortina: 4 × 4 m (una unidad de UV) en 96 px. Con
## `luz` = la máscara de emisión: los vidrios encendidos de noche (unos más que
## otros) y los montantes apagados.
static var _tex_cortina := {}
static func _tex_muro_cortina(luz: bool) -> ImageTexture:
	if _tex_cortina.has(luz):
		return _tex_cortina[luz]
	var n := 96
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	## 3 columnas (1,33 m) × 2 filas (2 m) de vidrios por baldosa.
	var tonos: Array[float] = []
	var luces: Array[float] = []
	for k in 6:
		tonos.append(rng.randf_range(0.82, 1.08))
		luces.append([0.12, 0.5, 0.85][rng.randi() % 3])
	for y in n:
		for x in n:
			var cx := x % 32
			var cy := y % 48
			var marco := cx < 2 or cx > 29 or cy < 2 or cy > 45
			var k := (x / 32) + 3 * (y / 48)
			var v: float
			if luz:
				v = 0.0 if marco else luces[k]
			elif marco:
				v = 0.78
			else:
				## El reflejo del cielo: más claro en lo alto de cada vidrio.
				v = tonos[k] * lerpf(0.62, 0.36, float(cy) / 47.0)
			img.set_pixel(x, y, Color(v, v, v))
	img.generate_mipmaps()
	_tex_cortina[luz] = ImageTexture.create_from_image(img)
	return _tex_cortina[luz]

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
