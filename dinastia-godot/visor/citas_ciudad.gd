class_name CitasCiudad
extends Node
## LAS CITAS EN PERSONA, EN 3D (fase 4, bloques 1-2, 26-10-2026). Plan §2.2d: la
## flecha del HUD te lleva a la cita marcada con «Ir» en la Agenda; la persona está
## con cuerpo en su sitio SOLO en su hora (`Citas.en_hora`); con E se abre la charla
## (las dos respuestas de `Citas.opciones`) y lo que pasa es `Citas.resolver`.
##
## Reutiliza lo del prólogo: `PrologoMentor` para el cuerpo (nombre, cargo, semilla =
## misma cara siempre) y `PrologoHud` para la flecha y el panel de pregunta (su botón de
## saltar el prólogo queda escondido). Cuelga de `VidaCiudad`, que lo crea al engancharse.

const RADIO_HABLAR := 2.2
const RADIO_APARECER := 90.0

var mundo: Mundo
var expl: ExploradorCiudad
var vida: VidaCiudad
var hud: PrologoHud
## id de cita → PrologoMentor en su sitio.
var cuerpos: Dictionary = {}
var cerca_id := ""
## Los futbolistas del vestuario en horario (fase 5, bloque 1).
var vestuario: VestuarioVivo = null
var _abierta := ""
var _t := 0.0

static func crear(v: VidaCiudad) -> CitasCiudad:
	var s := CitasCiudad.new()
	s.name = "Citas"
	s.mundo = v.mundo
	s.expl = v.expl
	s.vida = v
	v.add_child(s)
	return s

func _ready() -> void:
	hud = PrologoHud.new()
	add_child(hud)
	hud.directiva_respondida.connect(_responder)
	if hud._saltar != null:
		hud._saltar.visible = false
	hud.flecha(false)
	vestuario = VestuarioVivo.crear(self)

func _process(delta: float) -> void:
	if mundo == null or mundo.citas == null or expl == null or not is_instance_valid(expl) or expl.cuerpo == null:
		return
	_t -= delta
	if _t <= 0.0:
		_t = 0.5
		_revisar_cuerpos()
	_flecha()
	_buscar_cerca()

# ===================================================================== DÓNDE ES

## El punto de la cita en el mundo (o INF si el sitio no existe en esta ciudad).
func punto_de(ct: Dictionary) -> Vector3:
	var l := mundo.citas.lugar(ct)
	if String(l["donde"]) == "estadio":
		return _centro_zona(String(l["lugar"]), int(l["planta"]))
	if expl.cb == null:
		return Vector3.INF
	for pc: Dictionary in expl.cb.puntos_clic:
		if String(pc["k"]) == String(l["lugar"]):
			return pc["pos"]
	return Vector3.INF

func _centro_zona(zona: String, planta: int) -> Vector3:
	var mejor := Rect2()
	for z: Dictionary in expl._est.get("zonas", []):
		if String(z["nombre"]) == zona and int(z.get("planta", 0)) == planta:
			var r: Rect2 = z["r"]
			if r.get_area() > mejor.get_area():
				mejor = r
	if mejor.get_area() <= 0.0:
		return Vector3.INF
	var c := mejor.get_center()
	return CityBuilder.ESTADIO_EN + Vector3(c.x, RecorridoClub.y_de(planta), c.y)

## ¿El jugador está en el mismo «mundo» que la cita (dentro del club o en la calle)?
func _mismo_sitio(ct: Dictionary) -> bool:
	var dentro := String(expl.estado) == "estadio"
	var l := mundo.citas.lugar(ct)
	if String(l["donde"]) == "estadio":
		return dentro and int(expl._planta) == int(l["planta"])
	return String(expl.estado) == "calle"

# ======================================================================= CUERPOS

## Cada medio segundo: la persona aparece en su sitio en su hora (si estás cerca de
## ese mundo) y se va al pasar la hora o al cumplirse la cita.
func _revisar_cuerpos() -> void:
	var vivas := {}
	for ct: Dictionary in mundo.citas.pendientes():
		var id := String(ct["id"])
		if not mundo.citas.en_hora(ct, mundo.reloj) or not _mismo_sitio(ct):
			continue
		var p := punto_de(ct)
		if p == Vector3.INF or Vector2(p.x - expl.cuerpo.position.x, p.z - expl.cuerpo.position.z).length() > RADIO_APARECER:
			continue
		vivas[id] = true
		if cuerpos.has(id) and is_instance_valid(cuerpos[id]):
			continue
		var per := PrologoMentor.new()
		expl.cb.add_child(per)
		var club := mundo.mi_club()
		var c1 := Color(club.color1) if club != null else Color(0.2, 0.3, 0.5)
		var c2 := Color(club.color2) if club != null else Color.WHITE
		per.crear({"nombre": String(ct["quien"]), "cargo": String(ct["cargo"]), "semilla": "cita_" + String(ct["quien"]), "canas": String(ct["tipo"]) == "junta"}, c1, c2)
		var sitio := p if String(mundo.citas.lugar(ct)["donde"]) == "estadio" else expl.buscar_libre(p + Vector3(2.5, 0, 2.5))
		per.colocar(sitio, 0.0)
		per.mirar_a(expl.cuerpo.position)
		cuerpos[id] = per
	for id: String in cuerpos.keys():
		if not vivas.has(id) and id != _abierta:
			if is_instance_valid(cuerpos[id]):
				(cuerpos[id] as Node).queue_free()
			cuerpos.erase(id)

# ======================================================================== FLECHA

func _flecha() -> void:
	var ct := mundo.citas.por_id(mundo.citas.objetivo)
	if ct.is_empty() or String(ct["estado"]) != "pendiente" or _abierta != "" or not expl.is_physics_processing():
		hud.flecha(false)
		return
	var p := punto_de(ct)
	if p == Vector3.INF:
		hud.flecha(false)
		return
	var yo := expl.cuerpo.position
	var adelante := -expl.camara.global_transform.basis.z
	var hacia := Vector3(p.x - yo.x, 0, p.z - yo.z)
	var ang := atan2(hacia.x, hacia.z) - atan2(adelante.x, adelante.z)
	var l := mundo.citas.lugar(ct)
	var otra := ""
	if String(l["donde"]) == "estadio" and String(expl.estado) != "estadio":
		otra = Idiomas.t("entra al estadio")
	elif String(l["donde"]) == "estadio" and int(expl._planta) != int(l["planta"]):
		otra = Idiomas.t("planta %+d · usa el ascensor") % int(l["planta"])
	elif String(l["donde"]) == "ciudad" and String(expl.estado) != "calle":
		otra = Idiomas.t("sal a la calle")
	hud.flecha(true, ang, hacia.length(), otra)

# ========================================================================= HABLAR

func _buscar_cerca() -> void:
	cerca_id = ""
	if _abierta != "":
		return
	for id: String in cuerpos:
		var per: PrologoMentor = cuerpos[id]
		if not is_instance_valid(per):
			continue
		if Vector2(per.position.x - expl.cuerpo.position.x, per.position.z - expl.cuerpo.position.z).length() < RADIO_HABLAR:
			cerca_id = id
			per.mirar_a(expl.cuerpo.position)
			expl._aviso.text = Idiomas.t("E: hablar con %s") % per.nombre
			return

## La E del explorador: true si la cita se quedó con ella.
func usar() -> bool:
	if cerca_id == "" and _abierta == "" and vestuario != null and vestuario.usar():
		return true
	if cerca_id == "" or _abierta != "":
		return false
	var ct := mundo.citas.por_id(cerca_id)
	if ct.is_empty():
		return false
	_abierta = cerca_id
	var per: PrologoMentor = cuerpos.get(cerca_id)
	if per != null and is_instance_valid(per):
		per.hablar(true)
		expl._hablando_con = per
		expl._t_burbuja = 120.0
		expl._colocar_camara(1.0)
	expl.pausar(true)
	var club := mundo.mi_club()
	var color := Color(club.color1).lerp(Color.WHITE, 0.35) if club != null else Color(1.0, 0.86, 0.5)
	hud.pregunta_directiva("%s · %s" % [String(ct["quien"]), String(ct["cargo"])], color,
		"%s %s" % [String(ct["quien"]).get_slice(" ", 0), String(ct["asunto"])], mundo.citas.opciones(mundo, ct))
	return true

func _responder(i: int) -> void:
	if _abierta == "":
		return
	var id := _abierta
	_abierta = ""
	var r := mundo.citas.resolver(mundo, id, i)
	expl.pausar(false)
	expl._t_burbuja = 0.0
	expl._hablando_con = null
	if cuerpos.has(id) and is_instance_valid(cuerpos[id]):
		(cuerpos[id] as PrologoMentor).hablar(false)
		(cuerpos[id] as PrologoMentor).adelantarse(expl.cuerpo.position + Vector3(4.0, 0, 4.0))
		var per: Node = cuerpos[id]
		get_tree().create_timer(2.5).timeout.connect(func() -> void:
			if is_instance_valid(per):
				per.queue_free())
		cuerpos.erase(id)
	if not r.is_empty():
		vida._decir(String(r["titulo"]), String(r["texto"]))
	Sonido.toca("clic", Sonido.Bus.EFECTOS)
