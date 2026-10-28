class_name MiradorCerro
extends Node3D
## EL MIRADOR DE LA CIMA (27-10-2026): la plataforma de la estación de arriba del teleférico. Al subir (`Teleferico.usar`) el
## explorador pasa al estado «cima» y este objeto lo mueve (`paso`) por una plataforma con barandilla, bancos, un telescopio
## (E: mirar la ciudad) y la puerta de la estación (E: bajar). La plataforma está a la altura real de la cima (la ciudad
## está 280 m más abajo y se ve entera). Fuera de ella no se puede andar.

const MITAD := Vector2(27.0, 20.0)
const RADIO_ESTACION := 11.5

var tele: Teleferico
var centro := Vector3.ZERO
var puntos: Array = []          ## [{pos: Vector2 (x, z del mundo), k, n, radio}]

func configurar(t: Teleferico, b: CityBuilder, _giro: float) -> void:
	tele = t
	centro = t.cima
	t.add_child(self)
	var losa := b._mat_simple(Color(0.58, 0.58, 0.56), 0.9)
	var acero := b._mat_simple(Color(0.3, 0.32, 0.34), 0.5)
	var madera := b._mat_simple(Color(0.42, 0.3, 0.2), 0.8)
	_caja(b, centro + Vector3(0, -0.15, 0), Vector3(MITAD.x * 2.0 + 2.0, 0.3, MITAD.y * 2.0 + 2.0), losa)
	## Barandilla: cuatro tramos y postes cada 6 m.
	for lado: float in [-1.0, 1.0]:
		_caja(b, centro + Vector3(0, 1.1, lado * MITAD.y), Vector3(MITAD.x * 2.0, 0.12, 0.12), acero)
		_caja(b, centro + Vector3(lado * MITAD.x, 1.1, 0), Vector3(0.12, 0.12, MITAD.y * 2.0), acero)
		for k in 9:
			_caja(b, centro + Vector3(-MITAD.x + float(k) * MITAD.x * 0.25, 0.55, lado * MITAD.y), Vector3(0.1, 1.1, 0.1), acero)
		for k2 in 7:
			_caja(b, centro + Vector3(lado * MITAD.x, 0.55, -MITAD.y + float(k2) * MITAD.y / 3.0), Vector3(0.1, 1.1, 0.1), acero)
	for k3 in 3:
		_caja(b, centro + Vector3(-16.0 + float(k3) * 8.0, 0.45, -16.0), Vector3(3.0, 0.5, 0.9), madera)
	## El telescopio: pie, tubo y un cartel.
	_caja(b, centro + Vector3(18.0, 0.7, 14.0), Vector3(0.3, 1.4, 0.3), acero)
	var tubo := b._cil_en(centro + Vector3(18.0, 1.55, 14.0), 0.18, 1.1, acero)
	tubo.rotation.z = PI * 0.3
	var l := Label3D.new()
	l.text = Idiomas.t("MIRADOR DEL CERRO") + "\n" + Idiomas.t("420 m sobre la ciudad")
	l.font_size = 48
	l.pixel_size = 0.012
	l.outline_size = 8
	l.position = centro + Vector3(0, 3.2, MITAD.y + 0.2)
	add_child(l)
	puntos = [{"pos": Vector2(centro.x, centro.z + RADIO_ESTACION + 0.6), "k": "tele_cima", "n": "Teleférico: bajar a la ciudad", "radio": 3.2},
		{"pos": Vector2(centro.x + 18.0, centro.z + 14.0), "k": "tele_mirar", "n": "Mirar por el telescopio", "radio": 2.6}]

func _caja(b: CityBuilder, pos: Vector3, tam: Vector3, mat: Material) -> void:
	var mi := b._caja_en(pos, tam, mat)
	b.remove_child(mi)
	mi.position = pos
	add_child(mi)

func libre(p: Vector2) -> bool:
	for dx: float in [-0.4, 0.4]:
		for dz: float in [-0.4, 0.4]:
			var q := p + Vector2(dx, dz)
			if absf(q.x - centro.x) > MITAD.x - 0.3 or absf(q.y - centro.z) > MITAD.y - 0.3:
				return false
			if q.distance_to(Vector2(centro.x, centro.z)) < RADIO_ESTACION:
				return false
	return true

func _decir(e, titulo: String, texto: String) -> void:
	if e.vida != null:
		e.vida._decir(titulo, texto)
	else:
		e._aviso.text = texto

func _tiempo(e, minutos: int) -> void:
	if e.vida != null and e.vida.mundo != null and e.vida.mundo.reloj != null:
		e.vida.mundo.reloj.avanzar_minutos(minutos, "libre")

func entrar(e) -> void:
	e._fundido()
	_tiempo(e, 12)
	e._calle_pos = e.cuerpo.position
	e._calle_rumbo = e.rumbo
	e.estado = "cima"
	e._vel_pie = 0.0
	e.cuerpo.position = Vector3(centro.x, centro.y + 0.1, centro.z + 15.0)
	e.rumbo = PI
	e.cuerpo.rotation.y = e.rumbo
	e.cuerpo.visible = not e.primera_persona
	e._cerca = {}
	e._aviso.text = ""
	e._colocar_camara(1.0)
	Sonido.toca("puerta", Sonido.Bus.EFECTOS)
	_decir(e, Idiomas.t("Teleférico del Cerro"), Idiomas.t("Doce minutos de ascenso entre nubes y cables. Desde la cima, la ciudad entera cabe en la mano."))

func salir(e) -> void:
	e._fundido()
	_tiempo(e, 12)
	e.estado = "calle"
	e._t_gente = -1000.0
	e._vel_pie = 0.0
	e.cuerpo.position = e._calle_pos
	e.rumbo = e._calle_rumbo
	e.cuerpo.rotation.y = e.rumbo
	e.cuerpo.visible = not e.primera_persona
	e._cerca = {}
	e._aviso.text = ""
	e._colocar_camara(1.0)
	Sonido.toca("puerta", Sonido.Bus.EFECTOS)

func mirar(e) -> void:
	_decir(e, Idiomas.t("Telescopio"), Idiomas.t("Ahí abajo: el estadio, el río, las dos líneas de metro y los autobuses dando vueltas. Se oye muy lejos el rumor de la ciudad."))

## Un fotograma en la cima: anda por la plataforma y busca algo con lo que interactuar.
func paso(e, delta: float) -> void:
	var ent: Vector2 = e._entrada()
	var corre := Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
	var objetivo := (3.4 if corre else 1.6) * clampf(ent.y, -0.5, 1.0)
	e._vel_pie = move_toward(e._vel_pie, objetivo, (7.0 if absf(objetivo) > absf(e._vel_pie) else 12.0) * delta)
	e.vel = e._vel_pie
	e.rumbo -= ent.x * delta * 2.6
	var p: Vector3 = e.cuerpo.position
	var nueva: Vector3 = p + Vector3(sin(e.rumbo), 0, cos(e.rumbo)) * e.vel * delta
	if libre(Vector2(nueva.x, nueva.z)):
		p = nueva
	elif libre(Vector2(nueva.x, p.z)):
		p.x = nueva.x
	elif libre(Vector2(p.x, nueva.z)):
		p.z = nueva.z
	else:
		e._vel_pie = 0.0
	e.cuerpo.position = Vector3(p.x, centro.y + 0.1, p.z)
	e.cuerpo.rotation.y = e.rumbo
	if e._es_dt:
		e._animar_dt(e.vel)
	elif e._anim != null:
		e._anim.speed_scale = absf(e.vel) / 1.4 if absf(e.vel) > 0.05 else 0.0
	e._colocar_camara(delta)
	e._hud.text = Idiomas.t("⛰ Mirador del Cerro  ·  W/S/A/D para moverte · V: vista · E: interactuar · Esc: volver al mapa")
	e._cerca = {}
	for pt: Dictionary in puntos:
		if (pt["pos"] as Vector2).distance_to(Vector2(p.x, p.z)) < float(pt["radio"]):
			e._cerca = {"tipo": "lugar", "k": String(pt["k"]), "n": String(pt["n"])}
			break
	e._aviso.text = ("E: %s" % Idiomas.t(String(e._cerca["n"]))) if not e._cerca.is_empty() else ""
