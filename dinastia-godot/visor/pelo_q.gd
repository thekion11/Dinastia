class_name PeloQ
extends RefCounted
## EL PELO DE LOS JUGADORES 3D (25-9-2026). Hasta hoy los 22 del campo eran
## calvos: el cuerpo de Quaternius viene sin pelo y los peinados de su propio
## pack (Universal Base Characters, CC0) estaban en un zip sin abrir. Aquí se
## ponen, con el MISMO corte que el retrato 2D de la ficha (`Cara.CORTES`),
## teñidos con el color de pelo del jugador, más barba y cejas.
##
## Las mallas son las "Origin at 0": vienen colocadas sobre la cabeza del
## modelo base en su pose de reposo, así que se cuelgan de un `BoneAttachment3D`
## del hueso `Head` corridas por la inversa del reposo de ese hueso -en reposo
## quedan exactamente donde el autor las dejó, y después siguen a la cabeza-.

const CARPETA := "res://assets/characters/quaternius/pelo/"

## Los 24 cortes del retrato -> las cuatro mallas 3D (o nada). [malla, escala].
const DE_CORTE := {
	"corto": ["Hair_Buzzed", 1.0], "rapado": ["Hair_Buzzed", 1.0], "fade": ["Hair_Buzzed", 1.0],
	"undercut": ["Hair_Buzzed", 1.0], "entradas": ["Hair_Buzzed", 1.0], "pincho": ["Hair_Buzzed", 1.02],
	"crestas": ["Hair_Buzzed", 1.02], "mohicano": ["Hair_Buzzed", 1.02],
	"tupe": ["Hair_SimpleParted", 1.0], "flequillo": ["Hair_SimpleParted", 1.0], "mono": ["Hair_SimpleParted", 1.0],
	"tazon": ["Hair_SimpleParted", 1.0], "ondulado": ["Hair_SimpleParted", 1.02], "cortina": ["Hair_SimpleParted", 1.0],
	"rizado": ["Hair_SimpleParted", 1.04], "afro": ["Hair_SimpleParted", 1.10],
	"largo": ["Hair_Long", 1.0], "melena": ["Hair_Long", 1.0], "rastas": ["Hair_Long", 1.0],
	"trenzas": ["Hair_Long", 1.0], "mullet": ["Hair_Long", 1.0],
	"coleta": ["Hair_Buns", 1.0], "samurai": ["Hair_Buns", 1.0],
	"calvo": ["", 1.0],
}

## Estas mallas del pack están colocadas sobre la cabeza del cuerpo FEMENINO
## (más baja y más pequeña): puestas tal cual en el masculino caían corridas y
## dejaban la coronilla al aire. Se pasan desde la cabeza femenina.
const DE_CUERPO_FEMENINO := ["Hair_Long", "Hair_Buns", "Hair_BuzzedFemale", "Eyebrows_Female"]
const MODELO_FEMENINO := "res://assets/characters/quaternius/Superhero_Female_FullBody.gltf"
static var _cabeza_femenina: Variant = null   ## Transform3D del reposo global de su `Head`

static func _reposo_cabeza_femenina() -> Variant:
	if _cabeza_femenina == null:
		var escena: PackedScene = load(MODELO_FEMENINO)
		if escena != null:
			var n := escena.instantiate()
			var esq := _buscar_esqueleto(n)
			if esq != null and esq.find_bone("Head") >= 0:
				_cabeza_femenina = esq.get_bone_global_rest(esq.find_bone("Head"))
			n.free()
	return _cabeza_femenina

static func _buscar_esqueleto(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for h in n.get_children():
		var r := _buscar_esqueleto(h)
		if r != null:
			return r
	return null

static var _mallas := {}   ## nombre -> Mesh (se carga una vez por partida)
## nombre -> transform de su nodo dentro del glTF. Casi todas vienen en metros y
## sin girar, pero el moño viene en centímetros (escala 0,01) y girado 90°:
## sin esto salía como una masa negra flotando al costado del jugador.
static var _nodos := {}
static var _mats := {}     ## color html -> material

static func _malla(nombre: String) -> Mesh:
	if _mallas.has(nombre):
		return _mallas[nombre]
	var m: Mesh = null
	var escena: PackedScene = load(CARPETA + nombre + ".gltf")
	if escena != null:
		var n := escena.instantiate()
		var mi := _buscar_malla(n)
		if mi != null:
			m = mi.mesh
			var t := Transform3D.IDENTITY
			var a: Node = mi
			while a != null and a != n:
				if a is Node3D:
					t = (a as Node3D).transform * t
				a = a.get_parent()
			_nodos[nombre] = t
		n.free()
	_mallas[nombre] = m
	return m

static func _buscar_malla(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n
	for h in n.get_children():
		var r := _buscar_malla(h)
		if r != null:
			return r
	return null

## La textura del pack es gris (media ~143/255): multiplicada por el color del
## pelo, más un poco de ganancia, da el tono con mechones.
## Cada malla usa una de las dos texturas del pack (la de mechones largos para
## el pelo largo, el moño y las cejas finas): con la otra, los UV no calzan.
const TEXTURA_2 := ["Hair_Long", "Hair_Buns", "Eyebrows_Female"]

static func _material(color: Color, tex: int = 1) -> StandardMaterial3D:
	var clave := "%s|%d" % [color.to_html(false), tex]
	if _mats.has(clave):
		return _mats[clave]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(CARPETA + "T_Hair_%d_BaseColor.png" % tex)
	## Los mechones son recortes con transparencia: sin esto se veían los
	## huecos rellenos de negro o, al revés, la cabeza calva debajo.
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.4
	m.albedo_color = Color(minf(color.r * 1.7, 1.0), minf(color.g * 1.7, 1.0), minf(color.b * 1.7, 1.0))
	m.roughness = 0.75
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mats[clave] = m
	return m

## Pone pelo, barba (si `barba`) y cejas a un jugador de `FutbolistaQ.crear()`.
## `corte`: uno de `Cara.CORTES`. Devuelve el nodo del que cuelga todo.
static func poner(d: Dictionary, corte: String, color: Color, barba: bool) -> Node3D:
	var esq: Skeleton3D = d.get("esqueleto")
	if esq == null:
		return null
	var hueso := esq.find_bone("Head")
	if hueso < 0:
		return null
	var anc := BoneAttachment3D.new()
	anc.name = "Pelo"
	anc.bone_name = "Head"
	esq.add_child(anc)
	var desde_cabeza := esq.get_bone_global_rest(hueso).affine_inverse()
	var piezas: Array = []
	var fila: Array = DE_CORTE.get(corte, ["Hair_SimpleParted", 1.0])
	if String(fila[0]) != "":
		piezas.append([String(fila[0]), float(fila[1])])
	if barba:
		piezas.append(["Hair_Beard", 1.0])
	piezas.append(["Eyebrows_Regular", 1.0])
	for p: Array in piezas:
		var malla := _malla(String(p[0]))
		if malla == null:
			continue
		var mi := MeshInstance3D.new()
		mi.name = String(p[0])
		mi.mesh = malla
		mi.material_override = _material(color, 2 if String(p[0]) in TEXTURA_2 else 1)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var t := desde_cabeza
		if String(p[0]) in DE_CUERPO_FEMENINO:
			var rf: Variant = _reposo_cabeza_femenina()
			if rf is Transform3D:
				t = (rf as Transform3D).affine_inverse()
		var k: float = p[1]
		if k != 1.0:
			## Un poco más de volumen alrededor del centro de la cabeza. La
			## escala va en el espacio del MODELO (donde vive la malla), antes
			## de pasarla al del hueso: al revés, el afro salía volando de lado.
			var centro := esq.get_bone_global_rest(hueso).origin + Vector3(0, 0.1, 0)
			t = t * Transform3D(Basis().scaled(Vector3.ONE * k), centro - centro * k)
		## Orden: malla -> (su nodo del glTF) -> espacio del modelo -> volumen
		## extra -> espacio de la cabeza.
		t = t * Transform3D(_nodos.get(String(p[0]), Transform3D.IDENTITY))
		mi.transform = t
		anc.add_child(mi)
	return anc
