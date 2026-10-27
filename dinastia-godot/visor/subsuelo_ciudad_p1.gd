extends Node3D
## (Parte 1 de 2 de `subsuelo_ciudad.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `subsuelo_ciudad.gd`, conserva la clase.)

## EL SUBSUELO DE LA CIUDAD (27-10-2026, easter egg): bajo cinco tapas de alcantarilla con aro de óxido
## (`RedesCiudadVista._bocas`) hay un nivel entero con los servicios de las redes de `RedesCiudad`:
## el colector con su canal de agua, la galería eléctrica, la del agua potable, la del gas, la sala de
## control (pantalla con el estado de la ciudad, botón de reparar y palanca de cortar la luz del sector)
## y, al fondo, un cuarto olvidado. Se levanta la primera vez que se baja, bajo el mapa (`ORIGEN`).
##
## El estado `subsuelo` del `ExploradorCiudad` lo maneja este objeto: `paso` mueve al jugador, `usar`
## atiende la E. Todo es un laberinto de rectángulos andables (`rects`); las paredes salen solas de sus
## bordes. Si el sector de la entrada se queda sin corriente, las lámparas pasan a rojo de emergencia.

const ORIGEN := Vector3(0.0, -600.0, 0.0)
const ALTO := 4.6
const R := 0.4                               ## radio del cuerpo contra las paredes
const PASO_PARED := 0.5

var redes: RedesCiudadVista
var rects: Array[Rect2] = []
var puntos: Array = []                       ## [{pos: Vector2, k, n, radio}]
var sector_entrada := Vector2i(2, 2)
var _lamparas: Array[StandardMaterial3D] = []
var _luces: Array[OmniLight3D] = []
var _armarios: Array = []                    ## [{sector, lampara, rotulo}]
var _agua: StandardMaterial3D
var _paneles: Array = []                    ## [{vp, panel}] las pantallas del centro de mando
var _acometidas: Array = []                 ## [{ed, luz, agua, rotulo}] un armario por edificio real
var _baliza: OmniLight3D
var _baliza_mat: StandardMaterial3D
var _disyuntor_mat: StandardMaterial3D
var _chispas: StandardMaterial3D
var _origen_calle := Vector3.ZERO            ## la tapa por la que se bajó (para rumbo y distancia a los edificios)
var _rotulo_agua: Label3D
var _rotulo_gas: Label3D
var _ratas: Array = []
var _local := Vector2.ZERO
var _t := 0.0
var _t_texto := 0.0
var _t_zumbido := 0.0
var _t_gota := 1.0
var _secreto_visto := false
var _concreto: StandardMaterial3D
var _suelo: StandardMaterial3D

static func crear(cb: CityBuilder, r: RedesCiudadVista) -> SubsueloCiudad:
	var s := SubsueloCiudad.new()
	s.name = "Subsuelo"
	s.redes = r
	s.position = ORIGEN
	s.visible = false
	cb.add_child(s)
	s.construir()
	return s

static func _mat(c: Color, rug: float = 0.85, emi: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rug
	if emi > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emi
	return m

# ============================================================================ LA E DESDE LA CALLE

## E ante un punto de la ciudad: surtidor, tapa de alcantarilla o algo del propio subsuelo.
## `e` es el `ExploradorCiudad` (sin tipo: el explorador ya conoce esta clase).
static func servicio(e, k: String) -> bool:
	if k.begins_with("surtidor_"):
		return e.vida != null and e.vida.usar_surtidor(k)
	if k.begins_with("tele_"):
		return Teleferico.usar(e, k)
	if k.begins_with("sub_"):
		return e.sub != null and e.sub.usar(e, k)
	if not k.begins_with("alcantarilla_"):
		return false
	if e.modo != "pie" or e.estado != "calle" or e.cb == null or e.cb.expansion == null or e.cb.expansion.redes == null:
		e._aviso.text = Idiomas.t("La tapa pesa: a pie y con calma.")
		return true
	if e.sub == null:
		e.sub = SubsueloCiudad.crear(e.cb, e.cb.expansion.redes)
	e.sub.entrar(e, int(k.get_slice("_", 1)))
	return true

func entrar(e, idx: int) -> void:
	if idx >= 0 and idx < redes.bocas.size():
		sector_entrada = redes.bocas[idx]["sector"]
		_origen_calle = redes.bocas[idx]["pos"]
	e._fundido()
	e._calle_pos = e.cuerpo.position
	e._calle_rumbo = e.rumbo
	e.estado = "subsuelo"
	e._bajo_tierra(true)
	e._luz_cam.visible = true
	visible = true
	e._vel_pie = 0.0
	e.cuerpo.position = ORIGEN + Vector3(-1.5, 0.05, -1.5)
	e.rumbo = PI * 0.5
	e.cuerpo.rotation.y = e.rumbo
	e.cuerpo.visible = not e.primera_persona
	e._cerca = {}
	e._aviso.text = ""
	_actualizar()
	Sonido.toca("puerta", Sonido.Bus.EFECTOS)
	e._colocar_camara(1.0)

func salir(e) -> void:
	e._fundido()
	e.estado = "calle"
	e._t_gente = -1000.0
	e._bajo_tierra(false)
	e._luz_cam.visible = false
	visible = false
	e._vel_pie = 0.0
	e.cuerpo.position = e._calle_pos
	e.rumbo = e._calle_rumbo
	e.cuerpo.rotation.y = e.rumbo
	e.cuerpo.visible = not e.primera_persona
	e._cerca = {}
	e._aviso.text = ""
	Sonido.toca("puerta", Sonido.Bus.EFECTOS)
	e._colocar_camara(1.0)

# ============================================================================ MOVERSE

func _dentro(q: Vector2) -> bool:
	for r in rects:
		if r.has_point(q):
			return true
	return false

func libre(p: Vector2) -> bool:
	return _dentro(p + Vector2(R, R)) and _dentro(p + Vector2(-R, R)) and _dentro(p + Vector2(R, -R)) and _dentro(p + Vector2(-R, -R))

## La cámara no sale de los túneles: si cae en la roca se acerca al personaje.
func encajar_camara(deseo: Vector3, cuerpo: Vector3) -> Vector3:
	var d := deseo
	for _i in 8:
		if _dentro(Vector2(d.x - ORIGEN.x, d.z - ORIGEN.z)):
			break
		d = d.lerp(cuerpo, 0.3)
	d.y = clampf(d.y, ORIGEN.y + 0.4, ORIGEN.y + ALTO - 0.3)
	return d

## Un fotograma en el subsuelo (lo llama `_physics_process` del explorador).
func paso(e, delta: float) -> void:
	var ent: Vector2 = e._entrada()
	var corre := Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
	var objetivo := (3.4 if corre else 1.6) * clampf(ent.y, -0.5, 1.0)
	e._vel_pie = move_toward(e._vel_pie, objetivo, (7.0 if absf(objetivo) > absf(e._vel_pie) else 12.0) * delta)
	e.vel = e._vel_pie
	e.rumbo -= ent.x * delta * 2.6
	var rel: Vector3 = e.cuerpo.position - ORIGEN
	var nueva: Vector3 = rel + Vector3(sin(e.rumbo), 0, cos(e.rumbo)) * e.vel * delta
	if libre(Vector2(nueva.x, nueva.z)):
		rel = nueva
	elif libre(Vector2(nueva.x, rel.z)):
		rel.x = nueva.x
	elif libre(Vector2(rel.x, nueva.z)):
		rel.z = nueva.z
	else:
		e._vel_pie = 0.0
	_local = Vector2(rel.x, rel.z)
	e.cuerpo.position = ORIGEN + Vector3(rel.x, 0.05, rel.z)
	e.cuerpo.rotation.y = e.rumbo
	if e._es_dt:
		e._animar_dt(e.vel)
	elif e._anim != null:
		e._anim.speed_scale = absf(e.vel) / 1.4 if absf(e.vel) > 0.05 else 0.0
	e._colocar_camara(delta)
	e._hud.text = Idiomas.t("🕳 Servicios de la ciudad  ·  W/S/A/D para moverte · V: vista · E: interactuar · Esc: volver al mapa")
	e._cerca = {}
	for p: Dictionary in puntos:
		if (p["pos"] as Vector2).distance_to(_local) < float(p["radio"]):
			e._cerca = {"tipo": "lugar", "k": String(p["k"]), "n": String(p["n"])}
			break
	e._aviso.text = ("E: %s" % Idiomas.t(String(e._cerca["n"]))) if not e._cerca.is_empty() else ""

func usar(e, k: String) -> bool:
	if k == "sub_salir":
		salir(e)
		return true
	return SubsueloMando.usar(self, e, k)

func _decir(e, titulo: String, texto: String) -> void:
	if e.vida != null:
		e.vida._decir(titulo, texto)
	else:
		e._aviso.text = texto

# ============================================================================ VIDA DEL SUBSUELO

func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	_agua.uv1_offset.x = fmod(_t * 0.12, 1.0)
	## Sonido ambiente (con los efectos que ya hay): un zumbido grave continuo y, de vez en cuando, una gota.
	_t_zumbido -= delta
	if _t_zumbido <= 0.0:
		_t_zumbido = 3.0
		Sonido.toca("noche_estadio", Sonido.Bus.AMBIENTE)
	_t_gota -= delta
	if _t_gota <= 0.0:
		_t_gota = 2.5 + fmod(_t * 7.3, 4.5)
		Sonido.toca("clic_suave", Sonido.Bus.AMBIENTE)
	_t_texto -= delta
	if _t_texto <= 0.0:
		_t_texto = 1.0
		_actualizar()
	for r: Dictionary in _ratas:
		var n: Node3D = r["nodo"]
		var huye := absf(n.position.x - _local.x) < 3.0 and absf(n.position.z - _local.y) < 3.0
		var v := 4.0 if huye else 0.8
		if huye:
			r["dir"] = signf(n.position.x - _local.x) if absf(n.position.x - _local.x) > 0.1 else r["dir"]
		n.position.x += float(r["dir"]) * v * delta
		if n.position.x < 6.0 or n.position.x > 58.0:
			r["dir"] = -float(r["dir"])
			n.position.x = clampf(n.position.x, 6.0, 58.0)
		n.rotation.y = 0.0 if float(r["dir"]) > 0.0 else PI

## Lámparas (verde de servicio / rojo de emergencia), armarios y pantallas, con el estado de las redes.
func _actualizar() -> void:
	var m := redes.modelo
	var luz := m.hay_luz(sector_entrada)
	for l in _lamparas:
		l.emission = Color(1.0, 0.82, 0.55) if luz else Color(1.0, 0.12, 0.08)
		l.albedo_color = l.emission
		l.emission_energy_multiplier = 1.6 if luz else 0.5
	for o in _luces:
		o.light_color = Color(1.0, 0.86, 0.66) if luz else Color(1.0, 0.2, 0.15)
		o.light_energy = 1.1 if luz else 0.45
	for a: Dictionary in _armarios:
		var sec := Vector2i(clampi(sector_entrada.x + a["cerca"].x, 0, 4), clampi(sector_entrada.y + a["cerca"].y, 0, 4))
		var ok := m.hay_luz(sec)
		(a["lampara"] as StandardMaterial3D).albedo_color = Color(0.1, 0.8, 0.2) if ok else Color(0.9, 0.1, 0.1)
		(a["lampara"] as StandardMaterial3D).emission = (a["lampara"] as StandardMaterial3D).albedo_color
		(a["rotulo"] as Label3D).text = "SECTOR %d·%d\n%s" % [sec.x, sec.y, "CON LUZ" if ok else "SIN LUZ"]
	SubsueloMando.actualizar(self)
	_rotulo_agua.text = "💧 AGUA POTABLE\nDepósito %d%%" % roundi(m.agua_nivel / RedesCiudad.AGUA_DEPOSITO * 100.0)
	var g := "🔥 GAS · NO FUMAR\n"
	for id in m.gas:
		g += "Gasolinera %d: %d%%\n" % [int(id) + 1, roundi(float(m.gas[id]) / RedesCiudad.GAS_DEPOSITO * 100.0)]
	_rotulo_gas.text = g

# ============================================================================ CONSTRUCCIÓN

func _caja(pos: Vector3, tam: Vector3, mat: Material, giro: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation.y = giro
	add_child(mi)
	return mi

func _tubo(p: Vector3, q: Vector3, r: float, mat: Material) -> void:
	var d := q - p
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = d.length()
	cm.radial_segments = 10
	cm.rings = 0
	mi.mesh = cm
	mi.material_override = mat
	mi.position = (p + q) * 0.5
	mi.basis = Basis(Quaternion(Vector3.UP, d.normalized()))
	add_child(mi)

func _rotulo(pos: Vector3, texto: String, tam: float = 0.012, billboard: bool = true, giro: float = 0.0) -> Label3D:
	var l := Label3D.new()
	l.text = texto
	l.font_size = 48
	l.pixel_size = tam
	l.outline_size = 8
	l.position = pos
	if billboard:
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.rotation.y = giro
	add_child(l)
	return l

func _hueco(x: float, z: float, w: float, h: float) -> void:
	rects.append(Rect2(x, z, w, h))
	_caja(Vector3(x + w * 0.5, -0.2, z + h * 0.5), Vector3(w, 0.4, h), _suelo)
	_caja(Vector3(x + w * 0.5, ALTO + 0.2, z + h * 0.5), Vector3(w, 0.4, h), _concreto)

## Las paredes salen de los bordes de cada hueco, salvo donde otro hueco los atraviesa (las puertas).
func _paredes() -> void:
	for r in rects:
		var lados := [
			[Vector2(r.position.x, r.position.y), Vector2(1, 0), Vector2(0, -1), r.size.x],
			[Vector2(r.position.x, r.end.y), Vector2(1, 0), Vector2(0, 1), r.size.x],
			[Vector2(r.position.x, r.position.y), Vector2(0, 1), Vector2(-1, 0), r.size.y],
			[Vector2(r.end.x, r.position.y), Vector2(0, 1), Vector2(1, 0), r.size.y]]
		for l: Array in lados:
			var ini: Vector2 = l[0]
			var dir: Vector2 = l[1]
			var nor: Vector2 = l[2]
			var n := int(float(l[3]) / PASO_PARED)
			var corre_ini := -1
			for i in n + 1:
				var cerrado := false
				if i < n:
					var q := ini + dir * (float(i) + 0.5) * PASO_PARED + nor * 0.3
					cerrado = not _dentro(q)
				if cerrado and corre_ini < 0:
					corre_ini = i
				elif not cerrado and corre_ini >= 0:
					var largo := float(i - corre_ini) * PASO_PARED
					var c := ini + dir * (float(corre_ini) * PASO_PARED + largo * 0.5) + nor * 0.2
					var tam := Vector3(largo, ALTO, 0.4) if dir.x > 0.5 else Vector3(0.4, ALTO, largo)
					_caja(Vector3(c.x, ALTO * 0.5, c.y), tam, _concreto)
					corre_ini = -1

func _lampara(pos: Vector3, con_luz: bool) -> void:
	var m := _mat(Color(1.0, 0.82, 0.55), 0.5, 1.6)
	_lamparas.append(m)
	_caja(pos, Vector3(1.2, 0.12, 0.3), m)
	if con_luz:
		var o := OmniLight3D.new()
		o.omni_range = 15.0
		o.light_energy = 1.1
		o.shadow_enabled = false
		o.position = pos - Vector3(0, 0.5, 0)
		add_child(o)
		_luces.append(o)

func _textura_agua() -> ImageTexture:
	var img := Image.create(64, 16, false, Image.FORMAT_RGB8)
	var rr := RandomNumberGenerator.new()
	rr.seed = 2710
	for y in 16:
		for x in 64:
			var s := 0.5 + 0.25 * sin(float(x) * 0.5 + float(y) * 0.7) + rr.randf_range(-0.08, 0.08)
			img.set_pixel(x, y, Color(0.12 + s * 0.2, 0.2 + s * 0.28, 0.2 + s * 0.22))
	return ImageTexture.create_from_image(img)

func construir() -> void:
	_concreto = _mat(Color(0.34, 0.35, 0.34), 0.9)
	_suelo = _mat(Color(0.22, 0.22, 0.22), 0.7)
	SubsueloDetalle.materiales(self)
	_agua = _mat(Color(0.5, 0.75, 0.7), 0.1)
	_agua.albedo_texture = _textura_agua()
	_agua.uv1_scale = Vector3(14, 1, 1)
	_agua.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_agua.albedo_color = Color(0.5, 0.75, 0.7, 0.8)
	## Los huecos: pozo, colector, tres galerías, sala de control, pasillo y cuarto olvidado.
	_hueco(-4, -4, 8, 8)
	_hueco(4, -3, 56, 6)
	_hueco(18, -33, 6, 30)
	_hueco(30, 3, 6, 30)
	_hueco(44, -33, 6, 30)
	_hueco(60, -10, 22, 20)
	_hueco(82, -1.5, 16, 3)
	_hueco(98, -5, 12, 10)
	_hueco(69, 10, 4, 4)
	_hueco(56, 14, 40, 24)
	_paredes()
	_pozo()
	_colector()
	(self as SubsueloCiudad)._galeria_electrica()
	(self as SubsueloCiudad)._galeria_agua()
	(self as SubsueloCiudad)._galeria_gas()
	(self as SubsueloCiudad)._cuarto_olvidado()
	SubsueloMando.montar(self)
	SubsueloDetalle.montar(self)
	for i in 4:
		var rata := Node3D.new()
		_caja_en(rata, Vector3(0.32, 0.12, 0.14), _mat(Color(0.12, 0.1, 0.09)), Vector3.ZERO)
		_caja_en(rata, Vector3(0.3, 0.03, 0.03), _mat(Color(0.35, 0.22, 0.22)), Vector3(-0.3, 0, 0))
		rata.position = Vector3(10.0 + float(i) * 11.0, 0.08, 2.3 if i % 2 == 0 else -2.3)
		add_child(rata)
		_ratas.append({"nodo": rata, "dir": 1.0 if i % 2 == 0 else -1.0})

func _caja_en(padre: Node3D, tam: Vector3, mat: Material, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	padre.add_child(mi)

func _pozo() -> void:
	var hierro := _mat(Color(0.3, 0.3, 0.32), 0.5)
	for sx: float in [-0.35, 0.35]:
		_caja(Vector3(sx, ALTO * 0.5, -3.7), Vector3(0.08, ALTO, 0.08), hierro)
	for k in 12:
		_caja(Vector3(0, 0.4 + float(k) * 0.34, -3.7), Vector3(0.7, 0.05, 0.05), hierro)
	## La luz del día que entra por la tapa.
	_caja(Vector3(0, ALTO - 0.02, -3.2), Vector3(1.0, 0.04, 1.0), _mat(Color(0.8, 0.9, 1.0), 0.4, 3.0))
	_lampara(Vector3(0, ALTO - 0.3, 1.5), true)
	_rotulo(Vector3(0, 3.4, 3.7), "COLECTOR PRINCIPAL →", 0.005, false, PI)
	puntos.append({"pos": Vector2(0, -3.0), "k": "sub_salir", "n": "Subir a la calle", "radio": 2.0})

func _colector() -> void:
	var tubo := _mat(Color(0.45, 0.47, 0.5), 0.5)
	_caja(Vector3(32.0, 0.03, 0), Vector3(56.0, 0.04, 2.4), _agua)
	for sz: float in [-2.45, 2.45]:
		_tubo(Vector3(5.0, 3.9, sz), Vector3(59.0, 3.9, sz), 0.22, tubo)
		_tubo(Vector3(5.0, 3.4, sz), Vector3(59.0, 3.4, sz), 0.12, _mat(Color(0.5, 0.2, 0.15), 0.6))
	for k in 8:
		var x := 9.0 + float(k) * 7.0
		_lampara(Vector3(x, ALTO - 0.25, 0), k % 3 == 1)
		for sz: float in [-2.9, 2.9]:
			_caja(Vector3(x, 2.2, sz), Vector3(0.5, 4.4, 0.3), _concreto)
	_rotulo(Vector3(58, 3.2, 0), "← SALA DE CONTROL", 0.01, false, PI * 0.5 + PI)
