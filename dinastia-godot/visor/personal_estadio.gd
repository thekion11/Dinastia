class_name PersonalEstadio
extends Node3D
## LA GENTE DEL CLUB, EN PERSONA (estadio interactivo 2.0, fase 4).
##
## Pedido: «el personal del club debe tener presencia física, diálogos en
## persona, interacción y rutinas» y «cada uno debe tener su lugar de trabajo
## dentro del estadio». Las diez personas de `Gente` (y el presidente de la
## `Junta`) tienen aquí cuerpo, puesto y una rutina sencilla: trabajan en su
## puesto, salen a dar una vuelta por el pasillo (o la banda) y vuelven. Solo
## están en horario de trabajo (8 a 21 h) cuando se conoce la hora.
##
## Los exploradores (ciudad y estadio) preguntan con `cercano()` quién tiene
## delante y abren la conversación con `RecorridoClub.dialogo()`.

## clave -> [planta, zona del puesto, ropa, color 1, color 2]
const PUESTOS := {
	"conserje": [0, "Vestuario", "abrigo", "5a5f66", "c9c9c9"],
	"jardinero": [0, "Campo", "abrigo", "2e7d32", "a5d6a7"],
	"hincha": [0, "Acceso", "abrigo", "club", "club2"],
	"utilero": [-1, "Utilería", "chandal", "club", "club2"],
	"medico": [-1, "Enfermería", "abrigo", "f2f2f2", "cfe0f5"],
	"chofer": [-2, "Estacionamiento", "abrigo", "1f2a44", "90a4ae"],
	"secretaria": [1, "Pasillo", "traje", "3e2723", "f2f2f2"],
	"ojeador": [1, "Sala de vídeo", "abrigo", "6d4c41", "d7ccc8"],
	"presidente": [1, "Despacho del presidente", "traje", "111111", "f2f2f2"],
	"prensa": [2, "Sala de prensa", "traje", "1f2a44", "f2f2f2"],
	"cocinera": [2, "Comedor del plantel", "abrigo", "ffffff", "222222"],
}

const VEL := 1.25

## La hora del día (la pone la ciudad); −1 = no se sabe, siempre están.
static var hora := -1.0

var datos: Dictionary = {}
var c1 := Color.WHITE
var c2 := Color.BLACK
## Una por persona: {clave, nombre, puesto, planta, nodo, anim, ruta, i, dir, espera, quieto}
var gente: Array = []

func preparar(datos_: Dictionary, col1: Color, col2: Color) -> void:
	datos = datos_
	c1 = col1
	c2 = col2
	name = "PersonalEstadio"
	add_to_group("personal_club")

func _ready() -> void:
	var fichas: Dictionary = (EdificioClub.ctx.get("gente", {}) as Dictionary)
	var semilla := 11
	for clave: String in PUESTOS:
		var p: Array = PUESTOS[clave]
		var ruta := _ruta(clave, int(p[0]), String(p[1]))
		if ruta.is_empty():
			continue
		var ficha: Dictionary = fichas.get(clave, {})
		var nombre := String(ficha.get("nombre", ""))
		if clave == "presidente":
			nombre = String(EdificioClub.ctx.get("presidente", ""))
		if nombre == "":
			nombre = _nombre_de_respaldo(clave)
		var puesto := _puesto(clave)
		var raiz := Node3D.new()
		raiz.position = ruta[0]
		add_child(raiz)
		var asp := PersonajeDT.aleatorio(_rng(semilla))
		asp["ropa"] = String(p[2])
		asp["c_ropa"] = _hex(String(p[3]))
		asp["c_ropa2"] = _hex(String(p[4]))
		asp["corbata"] = clave in ["presidente", "secretaria"]
		asp["gafas"] = "" if clave != "ojeador" else String(asp.get("gafas", ""))
		var d := PersonajeDT.crear(raiz, asp, c1, c2)
		semilla += 7
		var et := Label3D.new()
		et.text = "%s\n%s" % [nombre, Idiomas.t(puesto)]
		et.font_size = 30
		et.pixel_size = 0.004
		et.outline_size = 6
		et.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		et.position = Vector3(0, 2.15, 0)
		et.modulate = Color(1, 0.97, 0.85)
		raiz.add_child(et)
		gente.append({"clave": clave, "nombre": nombre, "puesto": puesto, "planta": int(p[0]), "nodo": raiz,
			"anim": d.get("anim"), "ruta": ruta, "i": 0, "dir": 1, "espera": 4.0 + float(semilla % 13), "quieto": false})

func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r

func _hex(h: String) -> String:
	if h == "club":
		return c1.to_html(false)
	if h == "club2":
		return c2.to_html(false)
	return h

func _puesto(clave: String) -> String:
	if clave == "presidente":
		return "Presidente"
	for f: Array in Gente.ROLES:
		if String(f[0]) == clave:
			return String(f[1])
	return clave

func _nombre_de_respaldo(clave: String) -> String:
	var nombres := ["Rosa Medina", "Tito Barrios", "Chela Ruiz", "Don Aurelio", "Marta Soler", "Pancho Vidal",
		"Doctor Olmos", "El Negro Paz", "Lalo Ferro", "Don Ernesto", "Amalia Rey"]
	return nombres[absi(clave.hash()) % nombres.size()]

## El camino de cada uno: del puesto a su vuelta (y de vuelta). En una sala:
## puesto → puerta (dentro) → puerta (pasillo) → un punto del pasillo.
func _ruta(clave: String, planta: int, zona: String) -> Array:
	var x0: float = datos.get("x0", 0.0)
	var z_fin: float = datos.get("z_fin", 0.0)
	var y := RecorridoClub.y_de(planta)
	match zona:
		"Vestuario":
			var px := x0 + TunelVestuario.PUERTA_X
			return [Vector3(px - 1.2, y, z_fin - 1.8), Vector3(px - 2.5, y, z_fin - 4.0)]
		"Campo":
			return [Vector3(x0 + 12.0, y, 48.0), Vector3(x0 - 12.0, y, 46.0), Vector3(x0 - 14.0, y, 30.0)]
		"Acceso":
			var pa: Vector3 = datos.get("puerta", Vector3.ZERO)
			return [Vector3(pa.x + 0.7, y, pa.z + 2.2), Vector3(pa.x - 0.7, y, pa.z + 2.6)]
		"Pasillo":
			var zp := z_fin - EdificioClub.PASILLO / 2.0
			return [Vector3(x0 + 5.6, y, zp), Vector3(x0 - 5.0, y, zp)]
	## Una sala: su rectángulo grande (no el de la puerta).
	var mejor := Rect2()
	for z: Dictionary in datos.get("zonas", []):
		if int(z.get("planta", 0)) == planta and String(z["nombre"]) == zona:
			var r: Rect2 = z["r"]
			if r.get_area() > mejor.get_area():
				mejor = r
	if mejor.get_area() <= 0.0:
		return []
	var cx := mejor.get_center().x
	var z_tab := z_fin - EdificioClub.PASILLO - 0.1
	return [Vector3(cx + 0.6, y, mejor.position.y + mejor.size.y * 0.35), Vector3(cx, y, z_tab - 0.5),
		Vector3(cx, y, z_tab + 0.7), Vector3(cx + 1.4, y, z_fin - 1.2)]

func _process(delta: float) -> void:
	var de_turno := hora < 0.0 or (hora >= 8.0 and hora < 21.0)
	for g: Dictionary in gente:
		var n: Node3D = g["nodo"]
		if not is_instance_valid(n):
			continue
		n.visible = de_turno or String(g["clave"]) == "hincha"
		if bool(g["quieto"]):
			_anim(g, "parado")
			continue
		if float(g["espera"]) > 0.0:
			g["espera"] = float(g["espera"]) - delta
			_anim(g, "parado")
			continue
		var ruta: Array = g["ruta"]
		var sig := int(g["i"]) + int(g["dir"])
		if sig < 0 or sig >= ruta.size():
			## Final del camino: espera un rato y da la vuelta. En el puesto
			## se queda más (está trabajando).
			g["dir"] = -int(g["dir"])
			g["espera"] = 22.0 + float(absi(String(g["clave"]).hash()) % 18) if sig < 0 else 7.0
			continue
		var meta: Vector3 = ruta[sig]
		var hacia := meta - n.position
		hacia.y = 0.0
		var dist := hacia.length()
		if dist < 0.05:
			g["i"] = sig
			continue
		var paso := minf(dist, VEL * delta)
		n.position += hacia / dist * paso
		n.rotation.y = atan2(hacia.x, hacia.z)
		_anim(g, "caminar")

func _anim(g: Dictionary, nombre: String) -> void:
	var a: AnimationPlayer = g.get("anim") as AnimationPlayer
	if a != null and a.has_animation(nombre) and a.current_animation != nombre:
		a.play(nombre, 0.3)

## Quién está a mano de `p` (coordenadas del estadio) en esta planta.
func cercano(p: Vector3, planta: int, alcance := 1.9) -> Dictionary:
	var mejor: Dictionary = {}
	var md := alcance
	for g: Dictionary in gente:
		var n: Node3D = g["nodo"]
		if int(g["planta"]) != planta or not is_instance_valid(n) or not n.visible:
			continue
		var d := Vector2(n.position.x - p.x, n.position.z - p.z).length()
		if d < md:
			md = d
			mejor = g
	return mejor

## Durante la charla se para y te mira.
func atender(g: Dictionary, hacia: Vector3, si: bool) -> void:
	g["quieto"] = si
	var n: Node3D = g["nodo"]
	if si and is_instance_valid(n):
		var v := hacia - n.position
		n.rotation.y = atan2(v.x, v.z)
