class_name GrupoVida
extends Node
## HABLAR EN GRUPO (P1-P3 «MEJORAR», animaciones de vida, 27-10-2026). Junto a las entradas (`CityBuilder.puertas_vida`), de vez en cuando
## tres vecinos llegan andando por distintos lados, se colocan en corro a ~1 m del centro mirándose, y charlan 14-22 s: cada uno con el
## clip «charla» a otro desfase, y la cabeza de cada uno sigue (`LookAtModifier3D`) al que habla, que cambia cada 3 s. Luego se van cada
## uno por su lado. Máximo 1 grupo a la vez; sin azar de la partida (hash del hueco y del contador).
const ALCANCE := 55.0
const PERSONAS := 3
const RADIO := 0.95
const VEL := 1.3

var expl: ExploradorCiudad
var _grupos: Array = []   ## {i, figs: [{fig, a, b, p}], marcas: [Node3D], fase, t, dur, charla}
var _t := 12.0
var _cuenta := 0

static func crear(v: VidaCiudad) -> GrupoVida:
	var s := GrupoVida.new()
	s.name = "GruposVivos"
	s.expl = v.expl
	v.add_child(s)
	return s

func _process(delta: float) -> void:
	_mover(delta)
	if expl == null or not is_instance_valid(expl) or expl.cuerpo == null or expl.cb == null or String(expl.estado) != "calle":
		return
	_t -= delta
	if _t > 0.0 or not _grupos.is_empty():
		return
	_t = 20.0
	var yo: Vector3 = expl.cuerpo.position
	var mejor := -1
	var mejor_d := ALCANCE
	var ps: Array[Dictionary] = expl.cb.puertas_vida
	for i in ps.size():
		var p: Vector3 = ps[i]["p"]
		var d := Vector2(p.x - yo.x, p.z - yo.z).length()
		if d < mejor_d and d > 8.0 and ((i + _cuenta) % 4 == 2):
			mejor = i
			mejor_d = d
	_cuenta += 1
	if mejor >= 0:
		iniciar(mejor)

## Empieza el grupo ante la puerta `i`: el corro se forma en la acera, a 3 m de la fachada.
func iniciar(i: int) -> void:
	var ps: Array[Dictionary] = expl.cb.puertas_vida
	var p: Vector3 = ps[i]["p"]
	var n: Vector3 = ps[i]["n"]
	var centro := p + n * 3.0
	var lado := n.cross(Vector3.UP)
	var figs: Array = []
	var marcas: Array = []
	for k in PERSONAS:
		var ang := TAU * float(k) / float(PERSONAS) + float(absi(hash([i, _cuenta])) % 6) * 0.1
		var sitio := centro + Vector3(sin(ang), 0, cos(ang)) * RADIO
		var origen := sitio + lado * (6.0 if k % 2 == 0 else -6.0) + n * (1.0 + float(k))
		var fig := PeatonVida.nuevo(expl.cb, 9500 + i * 31 + _cuenta * 7 + k)
		if fig.is_empty():
			continue
		var nodo: Node3D = fig["nodo"]
		sitio.y = p.y
		origen.y = p.y
		nodo.position = origen
		nodo.rotation.y = EscaparateVida.rumbo(origen, sitio)
		Mini3D.anim(fig, "caminar", "")
		(fig["anim"] as AnimationPlayer).speed_scale = VEL / MovimientoNatural.NATURAL
		var marca := Node3D.new()
		expl.cb.add_child(marca)
		MiradaBalon.poner_en(nodo, marca)
		marcas.append(marca)
		figs.append({"fig": fig, "a": origen, "b": sitio, "salida": sitio + lado * (10.0 if k % 2 == 1 else -10.0) + n * (2.0 + float(k) * 2.0)})
	if figs.size() < 2:
		for f: Dictionary in figs:
			((f["fig"] as Dictionary)["nodo"] as Node3D).queue_free()
		for m: Node3D in marcas:
			m.queue_free()
		return
	_grupos.append({"i": i, "figs": figs, "marcas": marcas, "centro": centro, "fase": 0, "t": 0.0, "dur": 7.0 / VEL + 1.0, "charla": 14.0 + float(absi(hash([i, 5])) % 9), "habla": 0})

func _mover(delta: float) -> void:
	for g_i in range(_grupos.size() - 1, -1, -1):
		var g: Dictionary = _grupos[g_i]
		g["t"] = float(g["t"]) + delta
		var figs: Array = g["figs"]
		match int(g["fase"]):
			0:   ## llegan al corro
				var u := clampf(float(g["t"]) / float(g["dur"]), 0.0, 1.0)
				for f: Dictionary in figs:
					var nodo: Node3D = (f["fig"] as Dictionary)["nodo"]
					if is_instance_valid(nodo):
						nodo.position = (f["a"] as Vector3).lerp(f["b"], u)
				if u >= 1.0:
					g["fase"] = 1
					g["t"] = 0.0
					for k in figs.size():
						var fig: Dictionary = (figs[k] as Dictionary)["fig"]
						PeatonVida.gesto(fig["nodo"], "charla")
						(fig["anim"] as AnimationPlayer).seek(float(k) * 0.7, true)
			1:   ## charlan: giran hacia el centro y la mirada va al que habla
				var habla := int(float(g["t"]) / 3.0) % figs.size()
				for k in figs.size():
					var nodo: Node3D = ((figs[k] as Dictionary)["fig"] as Dictionary)["nodo"]
					if not is_instance_valid(nodo):
						continue
					var c: Vector3 = g["centro"]
					nodo.rotation.y = MovimientoNatural.girar(nodo.rotation.y, EscaparateVida.rumbo(nodo.position, c), delta)
					var otro: int = (k + 1) % figs.size() if habla == k else habla
					var no: Node3D = ((figs[otro] as Dictionary)["fig"] as Dictionary)["nodo"]
					if is_instance_valid(no):
						((g["marcas"] as Array)[k] as Node3D).position = no.position + Vector3(0, 1.55, 0)
				if float(g["t"]) >= float(g["charla"]):
					g["fase"] = 2
					g["t"] = 0.0
					g["dur"] = 10.0 / VEL + 1.0
					for f: Dictionary in figs:
						f["a"] = f["b"]
						var fig2: Dictionary = f["fig"]
						Mini3D.anim(fig2, "caminar", "")
						(fig2["anim"] as AnimationPlayer).speed_scale = VEL / MovimientoNatural.NATURAL
			_:   ## se van cada uno por su lado
				var u2 := clampf(float(g["t"]) / float(g["dur"]), 0.0, 1.0)
				for f: Dictionary in figs:
					var nodo: Node3D = (f["fig"] as Dictionary)["nodo"]
					if is_instance_valid(nodo):
						nodo.position = (f["a"] as Vector3).lerp(f["salida"], u2)
						nodo.rotation.y = MovimientoNatural.girar(nodo.rotation.y, EscaparateVida.rumbo(f["a"], f["salida"]), delta)
				if u2 >= 1.0:
					_liberar(g)
					_grupos.remove_at(g_i)

func _liberar(g: Dictionary) -> void:
	for f: Dictionary in g["figs"]:
		var n: Node = (f["fig"] as Dictionary).get("nodo")
		if n != null and is_instance_valid(n):
			n.queue_free()
	for m: Node in g["marcas"]:
		if is_instance_valid(m):
			m.queue_free()

func _exit_tree() -> void:
	for g: Dictionary in _grupos:
		_liberar(g)
