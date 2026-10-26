class_name VallasLed
extends Node3D
## LAS VALLAS LED DEL PERÍMETRO, con marca de verdad y cambiando solas.
##
## Sale de los dos videos de referencia del usuario, que coinciden en esto por
## encima de cualquier otra cosa del estadio:
##   - `marca/referencia/ea_fc25_referencia.mp4`: el anillo de paneles rodea el
##     campo entero y se lee "EA FC25" / "EA FC24" panel por panel, con cada
##     panel de un color distinto.
##   - `marca/referencia/ejemplo-partido.mp4` (Soccer Manager 2026): lo mismo,
##     con "SOCCER MANAGER 2026" repetido y alternando blanco y dorado.
##
## Hasta hoy `StadiumBuilder._vallas_publicidad()` ponía 54 cajas de COLOR LISO
## alternando tres tonos: la silueta estaba, el contenido no. Es la misma clase
## de hueco que tenía la pantalla gigante antes de esta misma tanda.
##
## POR QUÉ UN NODO Y NO SOLO GEOMETRÍA: una valla LED que nunca cambia es un
## cartel pintado. Cambiar el anuncio es lo que la delata como pantalla, y para
## eso hace falta algo vivo en el árbol. Este nodo es ese algo, y es barato a
## propósito -ver `_process()`.
##
## NO SE FUNDE ENTRE ANUNCIOS, CORTA EN SECO. Se probó pensar el fundido y se
## descartó por una razón concreta: `Label3D` con transparencia real (sin
## `ALPHA_CUT_DISCARD`) mete 54 superficies transparentes a ordenar delante de
## la grada, que es justo el tipo de cosa que produce parpadeos de ordenación;
## y con `ALPHA_CUT_DISCARD` el "fundido" sería el texto apareciendo de golpe
## igual. Una valla LED de verdad tampoco funde: corta.

## Cuánto dura cada anuncio en un panel.
const SEG := 5.0
## Desfase entre panel y panel, para que el anillo cambie en ola y no los 54 de
## golpe -que es lo que se ve en los dos videos-.
const DESFASE := 0.42

## {"texto": String, "fondo": Color, "tinta": Color}
var _anuncios: Array = []
## Un material por anuncio, creados una sola vez: 54 paneles comparten los 6.
var _materiales: Array[StandardMaterial3D] = []
## {"caja": MeshInstance3D, "label": Label3D, "fase": float, "ult": int}
var _paneles: Array = []
var _t := 0.0

func sembrar(anuncios: Array) -> void:
	_anuncios = anuncios
	_materiales.clear()
	for a: Dictionary in _anuncios:
		var m := StandardMaterial3D.new()
		var fondo: Color = a.get("fondo", Color(0.10, 0.11, 0.13))
		m.albedo_color = fondo
		m.roughness = 0.42
		m.metallic = 0.15
		## Emisión baja a propósito: es un panel encendido visto de lado, no un
		## foco. Con más se come el contraste del texto de encima (es el mismo
		## error que ya costó dos vueltas en la pantalla gigante el 22-9).
		m.emission_enabled = true
		m.emission = fondo
		m.emission_energy_multiplier = 0.16
		_materiales.append(m)

## Lo llama `StadiumBuilder._una_valla()` panel por panel. El `idx` decide con
## qué anuncio arranca cada uno: si todos empezaran por el primero, el anillo
## entero diría lo mismo a la vez y se leería como una pancarta, no como LED.
func registrar(caja: MeshInstance3D, label: Label3D, idx: int) -> void:
	## Sin sombra propia (20-10-2026): 36 cajas de 1,1 m se volvían a dibujar en
	## cada pasada de sombra del sol por un borde que desde la TV no se ve.
	caja.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var p := {"caja": caja, "label": label, "fase": float(idx) * DESFASE, "ult": -1}
	_paneles.append(p)
	_pintar(p, idx)

## EL ANILLO REACCIONA AL PARTIDO (MEGAPLAN fase 2): en el gol y en los
## cambios todas las vallas cortan al mismo mensaje y parpadean con los colores
## del club unos segundos; luego vuelven solas a los anuncios (como en FC).
var _evento := {}
var _mat_evento: Array[StandardMaterial3D] = []

## `palabras`: se reparten panel a panel ("¡GOOOL!", "LAUTARO FC"...).
func evento(palabras: Array, c1: Color, c2: Color, seg: float = 6.0) -> void:
	if _paneles.is_empty() or palabras.is_empty():
		return
	_mat_evento.clear()
	for col: Color in [c1, c2]:
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.roughness = 0.42
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = 0.45
		_mat_evento.append(m)
	var tinta1 := Color.WHITE if c1.get_luminance() < 0.55 else Color(0.08, 0.08, 0.1)
	var tinta2 := Color.WHITE if c2.get_luminance() < 0.55 else Color(0.08, 0.08, 0.1)
	_evento = {"palabras": palabras, "hasta": _t + seg, "tintas": [tinta1, tinta2], "paso": -1}

func _pintar_evento() -> void:
	var paso := int(floor(_t / 0.35))
	if paso == int(_evento["paso"]):
		return
	_evento["paso"] = paso
	var palabras: Array = _evento["palabras"]
	var tintas: Array = _evento["tintas"]
	for i in _paneles.size():
		var p: Dictionary = _paneles[i]
		var k := (i + paso) % 2
		var l: Label3D = p["label"]
		if is_instance_valid(l):
			l.text = String(palabras[i % palabras.size()])
			l.modulate = tintas[k]
		_poner(p, _mat_evento[k])

## LAS CAJAS EN DOS MULTIMESH (20-10-2026): eran 36 piezas con su llamada de
## dibujo cada una (y cambiar de anuncio era cambiar de material). Ahora las
## laterales y las del fondo son un `MultiMesh` cada una, con el color y el
## brillo del panel por instancia (shader de abajo): 2 llamadas en vez de 36.
## Se montan en el primer fotograma, cuando ya están todas registradas.
## LA VALLA ES UNA PANTALLA, NO UN LADRILLO DE COLOR (25-10-2026, ultra pulido):
## antes la caja entera -dorso, cantos y tapa incluidos- brillaba con el color del
## anuncio, y desde la grada o la cámara de la banda se veían ladrillos de colores.
## Ahora solo la CARA QUE MIRA AL CAMPO es pantalla (con su marco negro arriba y
## abajo y, de cerca, la rejilla de los LED, que se funde con la distancia para no
## hacer muaré); el resto es la carcasa negra de cualquier valla de verdad. Todo
## relativo al nodo (en la ciudad el estadio va movido).
const SHADER_PANEL := """
shader_type spatial;
render_mode cull_back;
void fragment() {
	// En el espacio del mundo relativo al nodo (en un MultiMesh la matriz de la
	// instancia no es fiable en vertex(): probado con una captura).
	vec3 v_n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 v_p = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz - NODE_POSITION_WORLD;
	// Las laterales están en |x| = 37; las del fondo, en |z| = 55,5 y |x| <= 33.
	bool lateral = abs(v_p.x) > 35.0;
	float hacia = lateral ? -v_n.x * sign(v_p.x) : -v_n.z * sign(v_p.z);
	float frente = step(0.7, hacia);
	float marco = step(v_p.y, 0.06) + step(1.04, v_p.y);
	float pantalla = frente * (1.0 - clamp(marco, 0.0, 1.0));
	float s = lateral ? v_p.z : v_p.x;
	vec2 celda = fract(vec2(s, v_p.y) / 0.03) - 0.5;
	float led = 1.0 - smoothstep(0.28, 0.46, length(celda));
	float cerca = 1.0 - smoothstep(0.004, 0.012, fwidth(s));
	float rejilla = mix(1.0, 0.45 + 0.75 * led, cerca);
	vec3 carcasa = vec3(0.035, 0.037, 0.042);
	ALBEDO = mix(carcasa, COLOR.rgb * rejilla, pantalla);
	ROUGHNESS = mix(0.6, 0.42, pantalla);
	METALLIC = 0.15;
	EMISSION = COLOR.rgb * COLOR.a * rejilla * pantalla;
}
"""
var _multis := {}     ## tamaño de caja (String) -> MultiMesh
var _montado := false

func _montar_multimesh() -> void:
	_montado = true
	var grupos := {}
	for p: Dictionary in _paneles:
		var c: MeshInstance3D = p["caja"]
		if not is_instance_valid(c) or not (c.mesh is BoxMesh):
			continue
		var k := str((c.mesh as BoxMesh).size)
		if not grupos.has(k):
			grupos[k] = []
		grupos[k].append(p)
	var sh := Shader.new()
	sh.code = SHADER_PANEL
	var mat := ShaderMaterial.new()
	mat.shader = sh
	for k: String in grupos:
		var lista: Array = grupos[k]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = (lista[0]["caja"] as MeshInstance3D).mesh
		mm.instance_count = lista.size()
		for i in lista.size():
			var p: Dictionary = lista[i]
			var c: MeshInstance3D = p["caja"]
			mm.set_instance_transform(i, c.transform)
			mm.set_instance_color(i, _color_de(c.material_override))
			p["mm"] = mm
			p["mi"] = i
			c.queue_free()
			p["caja"] = null
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Paneles%d" % _multis.size()
		mmi.multimesh = mm
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		_multis[k] = mm

## El color de un material de panel: albedo, y en alfa el brillo (emisión).
static func _color_de(m: Material) -> Color:
	var sm := m as StandardMaterial3D
	if sm == null:
		return Color(0.1, 0.11, 0.13, 0.16)
	## El material estándar pasa sus colores de sRGB a lineal; el shader recibe
	## el color de la instancia tal cual, así que se convierte aquí.
	var col := sm.albedo_color.srgb_to_linear()
	col.a = sm.emission_energy_multiplier if sm.emission_enabled else 0.0
	return col

## Pone el material (su color) en el panel, sea caja suelta o instancia.
func _poner(p: Dictionary, m: StandardMaterial3D) -> void:
	p["color"] = _color_de(m)
	if p.has("mm"):
		(p["mm"] as MultiMesh).set_instance_color(int(p["mi"]), p["color"])
		return
	var c: MeshInstance3D = p["caja"]
	if is_instance_valid(c):
		c.material_override = m

func _process(delta: float) -> void:
	if _anuncios.is_empty() or _paneles.is_empty():
		return
	if not _montado:
		_montar_multimesh()
	_t += delta
	if not _evento.is_empty():
		if _t < float(_evento["hasta"]):
			_pintar_evento()
			return
		_evento = {}
		for p: Dictionary in _paneles:
			p["ult"] = -999
	for p: Dictionary in _paneles:
		## Solo una división y una comparación por panel y por frame. El texto
		## de un `Label3D` reconstruye su malla al asignarlo, así que solo se
		## toca cuando el anuncio DE VERDAD cambió -no en cada frame-.
		var ciclo := int(floor((_t + float(p["fase"])) / SEG))
		if ciclo != int(p["ult"]):
			_pintar(p, ciclo)

func _pintar(p: Dictionary, ciclo: int) -> void:
	if _anuncios.is_empty():
		return
	p["ult"] = ciclo
	var a: Dictionary = _anuncios[posmod(ciclo, _anuncios.size())]
	var l: Label3D = p["label"]
	if is_instance_valid(l):
		l.text = String(a.get("texto", ""))
		l.modulate = a.get("tinta", Color.WHITE)
	_poner(p, _materiales[posmod(ciclo, _materiales.size())])
