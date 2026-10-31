class_name VestuarioVivo
extends Node
## EL VESTUARIO CON VIDA (fase 5, bloque 1, 27-10-2026). Plan §2.2f: *«laborables de 10 a 12,
## 3-5 futbolistas con cuerpo junto a su taquilla (nombre y dorsal de la plantilla real); E =
## frase según su moral y rol»*. Solo textos: nada cambia en el partido. Cuelga de
## `CitasCiudad` (que ya tiene el explorador, el mundo y la E) y usa los cuerpos genéricos
## (`PrologoMentor` en chándal del club, cara por nombre).

const HORA_DESDE := 10
const HORA_HASTA := 12
const CUANTOS := 4
const RADIO_HABLAR := 2.0
## Lo que te dicen según la moral (≥ 70 contentos, 40-69 normales, < 40 molestos).
const FRASES := {
	"alta": ["¡Con ganas, míster! El sábado vamos a por todas.", "El grupo está enchufado. Se nota en los entrenamientos.", "Si me pone, no le fallo."],
	"media": ["Todo bien, míster. A seguir trabajando.", "¿Jugamos con la misma idea el sábado?", "El físico va bien; los minutos ya llegarán."],
	"baja": ["Míster, necesito minutos. Así no puedo.", "Hay cosas en el vestuario que no me gustan.", "¿Puedo hablar con usted después del entrenamiento?"],
}

var mundo: Mundo
var expl: ExploradorCiudad
var vida: VidaCiudad
var cuerpos: Array[Dictionary] = []   ## {nodo: PrologoMentor, jugador: Jugador}
var cerca: Dictionary = {}
var _t := 0.0

static func crear(c: CitasCiudad) -> VestuarioVivo:
	var s := VestuarioVivo.new()
	s.name = "Vestuario"
	s.mundo = c.mundo
	s.expl = c.expl
	s.vida = c.vida
	c.add_child(s)
	return s

## ¿Toca que haya futbolistas en el vestuario? (laborables de 10 a 12, reloj de la partida).
func toca() -> bool:
	var r := mundo.reloj
	return r != null and r.dia <= 4 and r.hora() >= HORA_DESDE and r.hora() < HORA_HASTA

func _process(delta: float) -> void:
	if expl == null or not is_instance_valid(expl) or expl.cuerpo == null:
		return
	_t -= delta
	if _t <= 0.0:
		_t = 0.5
		revisar()
	_buscar_cerca()

## Cada medio segundo: con el DT dentro del club, en la planta 0 y en horario, los cuerpos
## aparecen junto a las taquillas; si no, se van.
func revisar() -> void:
	var activo := String(expl.estado) == "estadio" and int(expl._planta) == 0 and toca()
	if not activo:
		if not cuerpos.is_empty():
			for c: Dictionary in cuerpos:
				if is_instance_valid(c["nodo"]):
					(c["nodo"] as Node).queue_free()
			cuerpos.clear()
		return
	if not cuerpos.is_empty():
		return
	var r := _rect_vestuario()
	var club := mundo.mi_club()
	if r.get_area() <= 0.0 or club == null:
		return
	var plantilla: Array = club.plantilla.duplicate()
	plantilla.sort_custom(func(a: Jugador, b: Jugador) -> bool: return (a.dorsal if a.dorsal > 0 else 99) < (b.dorsal if b.dorsal > 0 else 99))
	var k := 0
	for j: Jugador in plantilla:
		if k >= CUANTOS:
			break
		var lado := -1.0 if k % 2 == 0 else 1.0
		var x := (r.position.x + 0.9) if lado < 0.0 else (r.end.x - 0.9)
		var z := r.position.y + 1.6 + float(k / 2) * 1.6
		var per := PrologoMentor.new()
		expl.cb.add_child(per)
		per.crear({"nombre": Nombres.visible(j.nombre), "cargo": "%d · %s" % [j.dorsal, j.pos], "semilla": "jug_" + j.id, "ropa": "chandal",
			"c_ropa": club.color1, "c_ropa2": club.color2}, Color(club.color1), Color(club.color2))
		per.colocar(CityBuilder.ESTADIO_EN + Vector3(x, RecorridoClub.y_de(0), z), -lado * PI * 0.5)
		cuerpos.append({"nodo": per, "jugador": j})
		k += 1

func _rect_vestuario() -> Rect2:
	var mejor := Rect2()
	for z: Dictionary in expl._est.get("zonas", []):
		if String(z["nombre"]) == "Vestuario" and int(z.get("planta", 0)) == 0:
			var rr: Rect2 = z["r"]
			if rr.get_area() > mejor.get_area():
				mejor = rr
	return mejor

func _buscar_cerca() -> void:
	cerca = {}
	if cuerpos.is_empty() or (vida != null and vida.citas_3d != null and vida.citas_3d.cerca_id != ""):
		return
	for c: Dictionary in cuerpos:
		var per: PrologoMentor = c["nodo"]
		if not is_instance_valid(per):
			continue
		if Vector2(per.position.x - expl.cuerpo.position.x, per.position.z - expl.cuerpo.position.z).length() < RADIO_HABLAR:
			cerca = c
			per.mirar_a(expl.cuerpo.position)
			expl._aviso.text = Idiomas.t("E: hablar con %s") % per.nombre
			return

## La E junto a un futbolista: una frase según su moral (y gesticula). true si la usó.
func usar() -> bool:
	if cerca.is_empty():
		return false
	var j: Jugador = cerca["jugador"]
	var per: PrologoMentor = cerca["nodo"]
	var tramo := "alta" if j.moral >= 70 else ("media" if j.moral >= 40 else "baja")
	var lista: Array = FRASES[tramo]
	var r := mundo.reloj
	var i := absi(("%d|%d|%d|%s" % [r.anio, r.semana, r.dia, j.id]).hash()) % lista.size()
	if is_instance_valid(per):
		per.hablar(true)
		get_tree().create_timer(3.5).timeout.connect(func() -> void:
			if is_instance_valid(per):
				per.hablar(false))
	if vida != null:
		vida._decir(per.nombre, Idiomas.t(String(lista[i])))
	return true
