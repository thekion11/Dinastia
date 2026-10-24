extends Control
## [Capa 1/3 de `minijuegos_ciudad.gd`] juego_de, abrir, _lbl, _fondo_ciudad, _autografos_empezar, _salpicar … (+5)

## LOS MINIJUEGOS DE LA CIUDAD (7-10-2026, pedido: «puedes crear minijuegos
## dentro de la ciudad»). Se abren al llegar a un lugar (E en el modo a pie o
## al volante, o clic en el mapa):
##   · Plaza Mayor → AUTÓGRAFOS: los hinchas asoman entre la gente; tócalos
##     antes de que se vayan (30 s). Más reputación del club, más hinchas.
##   · Puerto → PESCA: el corcho flota; cuando grita «¡PICA!», tienes un
##     instante para tirar. Seis lanzadas.
##   · Karting → CONTRARRELOJ: tres vueltas al óvalo con tu kart (flechas o
##     WASD); salirte del asfalto te frena.
##   · Universidad / Cine → la TRIVIA del club.  · Parques → PENALES con los
##     chicos del barrio.
## Todo con un generador propio: jugar no cambia la partida.

const LUGARES := {
	"ciudad_plaza_mayor": "autografos", "ciudad_puerto": "pesca", "karting": "karting",
	"ciudad_universidad": "trivia", "ciudad_cine": "trivia", "ciudad_parque": "penales",
	"ciudad_parque_lago": "penales", "ciudad_instituto": "trivia",
}

static var records := {"autografos": 0, "pesca": 0, "karting": 0.0}


## EN 3D (7-10-2026, pedido: «los mini juegos también deben ser 3D con
## animaciones»): cada juego monta su escena con `Mini3D` -la plaza con su
## fuente y los hinchas que se acercan caminando, el muelle con la caña, el
## corcho y el pez que salta, el circuito con su kart y los rivales- y la
## interfaz (título, aviso, botones) queda encima.

var juego := ""
var rep := 60
var _rng := RandomNumberGenerator.new()
var _titulo: Label
var _aviso: Label
var _t := 0.0
var _puntos := 0
var _activo := false
var _v := {}
var _cam: Camera3D
var _raiz: Node3D

# ------------------------------------------------------------- AUTÓGRAFOS
## La Plaza Mayor: tú en medio, junto a la fuente; los hinchas llegan
## caminando desde la gente, levantan la mano y te piden la firma. Tócalos (o
## E) antes de que se cansen: firmas, el hincha lo celebra y se va feliz. Si
## tardas, se va con las manos en la cabeza.

var _yo := {}
var _hinchas: Array = []   ## {d, estado, t, angulo, objetivo, firma(Label3D)}
var _prox_hincha := 0.0

# ------------------------------------------------------------- PESCA
## El muelle del puerto fluvial: lanzas la caña (el corcho vuela y cae al
## agua), esperas viendo cómo flota, y cuando se hunde y salpica -«¡PICA!»-
## tienes un instante para tirar. El pez sale del agua dando la vuelta y cae
## en el muelle. Seis lanzadas.

var _lanzadas := 0
var _estado_pesca := "espera"   ## lanzando / espera / pica / fin
var _capturas: Array = []
var _cana: Node3D
var _punta: Node3D
var _corcho: Node3D
var _sedal: MeshInstance3D
var _sedal_mesh: ImmediateMesh
var _corcho_base := Vector3(0.6, 0.05, -10.0)
var _agua_mat: ShaderMaterial
var _bote: Node3D
const PECES := [["🐟 una mojarra", 1, Color(0.7, 0.72, 0.6)], ["🐠 un pez payaso (¿en un río?)", 2, Color(1.0, 0.5, 0.1)],
	["🐡 un pez globo", 2, Color(0.9, 0.8, 0.4)], ["🦈 ¡un tiburón de río!", 5, Color(0.45, 0.5, 0.58)],
	["🥾 una bota vieja", 0, Color(0.3, 0.2, 0.12)], ["🐟 una trucha", 3, Color(0.55, 0.6, 0.45)]]

const SHADER_AGUA := """
shader_type spatial;
render_mode cull_disabled;
uniform vec4 color_hondo : source_color = vec4(0.03, 0.12, 0.16, 1.0);
uniform vec4 color_claro : source_color = vec4(0.1, 0.26, 0.3, 1.0);
void vertex() {
	float t = TIME;
	VERTEX.y += sin(VERTEX.x * 0.35 + t * 1.3) * 0.08 + cos(VERTEX.z * 0.5 + t * 1.1) * 0.06;
}
void fragment() {
	float t = TIME;
	vec2 p = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
	float r = sin(p.x * 1.7 + t * 1.8) * cos(p.y * 1.3 - t * 1.4);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = mix(color_hondo.rgb, color_claro.rgb, 0.5 + 0.25 * r) + vec3(fres * 0.12);
	ROUGHNESS = 0.18;
	METALLIC = 0.1;
	SPECULAR = 0.7;
}
"""

# ------------------------------------------------------------- KARTING
## El circuito del karting en 3D: un óvalo de dos rectas y dos curvas con
## pianos rojos y blancos, barreras de neumáticos, la grada y la meta a
## cuadros. Tu kart (flechas o WASD) contra tres rivales que siguen la
## trazada; cámara detrás. Tres vueltas; salirte del asfalto te frena.

const KART_VEL := 24.0
const RECTA := 34.0
const RADIO := 22.0
const ANCHO_PISTA := 11.0
var _kart_n: Node3D
var _kp := Vector3(0, 0, RADIO)
var _kr := PI * 0.5
var _kv := 0.0
var _vueltas := 0
var _crono := 0.0
var _empezado := false
var _fin_kart := false
var _paso_arriba := false
var _cuenta := 3.5
var _rivales: Array = []   ## {n, s, v, lado}
var _semaforo: Label
var _mi_total := 0.0

static func juego_de(k: String) -> String:
	return String(LUGARES.get(k, ""))

static func abrir(padre: Control, juego: String, club: Club) -> Control:
	var mundo: Mundo = null
	var p := padre
	while p != null and mundo == null:
		if p.get("mundo") is Mundo:
			mundo = p.get("mundo")
		p = p.get_parent() as Control
	match juego:
		"trivia":
			if mundo != null:
				return TriviaClub.mostrar(padre, mundo)
			return null
		"penales":
			if mundo != null:
				return MinijuegoPenales.mostrar(padre, mundo)
			return null
	var n := MinijuegosCiudad.new()
	n.juego = juego
	n.rep = club.rep if club != null else 60
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(n)
	n._montar()
	return n

func _lbl(t: String, tam: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

## Edificios de fondo: bloques con ventanas, para que ningún juego flote en la nada.
func _fondo_ciudad(centro: Vector3, radio: float, desde: float, hasta: float, n: int) -> void:
	var cols := [Color(0.86, 0.8, 0.7), Color(0.75, 0.62, 0.5), Color(0.92, 0.9, 0.86), Color(0.6, 0.66, 0.72), Color(0.8, 0.72, 0.6)]
	var vidrio := Mini3D.mat(Color(0.25, 0.32, 0.4), 0.2)
	for i in n:
		var a := lerpf(desde, hasta, (float(i) + 0.5) / float(n))
		var alto := _rng.randf_range(9.0, 24.0)
		var ancho := _rng.randf_range(7.0, 11.0)
		var p := centro + Vector3(sin(a), 0, cos(a)) * radio
		var b := Mini3D.caja(_raiz, p + Vector3(0, alto * 0.5, 0), Vector3(ancho, alto, 7.0), Mini3D.mat(cols[i % cols.size()], 0.85))
		b.rotation.y = a
		## Ventanas en la cara que mira al centro.
		for f in int(alto / 3.2):
			for c in int(ancho / 2.4):
				var v := Mini3D.caja(b, Vector3(-ancho * 0.5 + 1.4 + float(c) * 2.4, -alto * 0.5 + 2.2 + float(f) * 3.2, -3.52), Vector3(1.2, 1.5, 0.05), vidrio)
				v.rotation.y = 0.0

func _autografos_empezar() -> void:
	_t = 30.0
	_activo = true
	_aviso.text = Idiomas.t("¡Toca a los hinchas que levantan la mano antes de que se vayan! (clic, toque o E)")
	## La plaza: adoquín, el círculo central, la fuente, bancos y farolas.
	Mini3D.caja(_raiz, Vector3(0, -0.1, 0), Vector3(140, 0.2, 140), Mini3D.mat(Color(0.5, 0.45, 0.4), 0.9))
	## Adoquines en damero suave y el círculo central de piedra más oscura.
	var lose := Mini3D.mat(Color(0.56, 0.5, 0.44), 0.9)
	for i in range(-8, 9):
		for j in range(-8, 9):
			if (i + j) % 2 == 0 and Vector2(i, j).length() > 4.6:
				Mini3D.caja(_raiz, Vector3(float(i) * 2.0, 0.005, float(j) * 2.0), Vector3(2.0, 0.01, 2.0), lose)
	Mini3D.cilindro(_raiz, Vector3(0, 0.01, 0), 9.0, 0.04, Mini3D.mat(Color(0.4, 0.36, 0.33), 0.85))
	Mini3D.cilindro(_raiz, Vector3(0, 0.02, 0), 8.4, 0.04, Mini3D.mat(Color(0.62, 0.58, 0.52), 0.85))
	var piedra := Mini3D.mat(Color(0.82, 0.8, 0.76), 0.7)
	var agua := Mini3D.mat(Color(0.3, 0.55, 0.75, 0.85), 0.05)
	Mini3D.cilindro(_raiz, Vector3(0, 0.4, -7.5), 3.4, 0.8, piedra)
	Mini3D.cilindro(_raiz, Vector3(0, 0.78, -7.5), 3.1, 0.1, agua)
	Mini3D.cilindro(_raiz, Vector3(0, 1.6, -7.5), 0.35, 2.4, piedra)
	Mini3D.cilindro(_raiz, Vector3(0, 2.9, -7.5), 1.3, 0.25, piedra, 0.9)
	var chorro := Mini3D.cilindro(_raiz, Vector3(0, 3.6, -7.5), 0.12, 1.2, Mini3D.mat(Color(0.7, 0.85, 1.0, 0.6), 0.05, 0.3), 0.04)
	chorro.name = "Chorro"
	var madera := Mini3D.mat(Color(0.5, 0.33, 0.2), 0.8)
	var hierro := Mini3D.mat(Color(0.12, 0.12, 0.13), 0.4)
	for k in 6:
		var a := TAU * float(k) / 6.0 + 0.5
		var p := Vector3(sin(a), 0, cos(a)) * 12.5
		var banco := Mini3D.caja(_raiz, p + Vector3(0, 0.45, 0), Vector3(2.2, 0.12, 0.6), madera)
		banco.rotation.y = a
		Mini3D.caja(banco, Vector3(0, 0.35, -0.28), Vector3(2.2, 0.5, 0.08), madera)
		var f := p * 1.25
		Mini3D.cilindro(_raiz, f + Vector3(0, 2.2, 0), 0.08, 4.4, hierro)
		Mini3D.esfera(_raiz, f + Vector3(0, 4.5, 0), 0.32, Mini3D.mat(Color(1.0, 0.92, 0.7), 0.3, 1.2))
	_fondo_ciudad(Vector3.ZERO, 46.0, -PI * 0.95, PI * 0.95, 14)
	## Tú, con ropa de calle, mirando a la cámara.
	_yo = Mini3D.persona(_raiz, _rng, Vector3(0, 0, 0))
	if not _yo.is_empty():
		Mini3D.anim(_yo, "saludo_mano")
	## Gente de relleno al fondo, paseando o mirando.
	for k in 6:
		var a := _rng.randf_range(-2.4, 2.4)
		var d := Mini3D.persona(_raiz, _rng, Vector3(sin(a), 0, -cos(a)) * _rng.randf_range(17.0, 24.0))
		if not d.is_empty():
			(d["nodo"] as Node3D).rotation.y = _rng.randf() * TAU
			Mini3D.anim(d, ["aplaudir", "parado", "cruzar_brazos", "saludar_publico"][k % 4], "")
	## El grupo de hinchas que se acercan (se reciclan).
	for k in 7:
		var d := Mini3D.persona(_raiz, _rng, Vector3(0, -50, 0))
		if d.is_empty():
			continue
		var firma := Label3D.new()
		firma.text = "✍️"
		firma.font_size = 96
		firma.pixel_size = 0.009
		firma.outline_size = 18
		firma.outline_modulate = Color(0.1, 0.1, 0.1, 0.85)
		firma.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		firma.no_depth_test = true
		firma.position = Vector3(0, 2.25, 0)
		firma.visible = false
		(d["nodo"] as Node3D).add_child(firma)
		_hinchas.append({"d": d, "estado": "fuera", "t": 0.0, "firma": firma, "objetivo": Vector3.ZERO, "salida": Vector3.ZERO})
	_cam.position = Vector3(0, 3.4, 8.6)
	_cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)

## Salpicadura: un anillo que se abre en el agua y gotas que saltan.
func _salpicar(p: Vector3, fuerza: float) -> void:
	var anillo := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.18
	tm.outer_radius = 0.24
	anillo.mesh = tm
	anillo.material_override = Mini3D.mat(Color(0.9, 0.95, 1.0, 0.7), 0.1)
	anillo.position = p + Vector3(0, 0.03, 0)
	_raiz.add_child(anillo)
	var tw := anillo.create_tween().set_parallel(true)
	tw.tween_property(anillo, "scale", Vector3(5, 1, 5) * fuerza + Vector3.ONE, 0.9)
	tw.tween_property(anillo.material_override, "albedo_color:a", 0.0, 0.9)
	tw.chain().tween_callback(anillo.queue_free)
	for k in int(6 * fuerza) + 3:
		var g := Mini3D.esfera(_raiz, p, 0.04, Mini3D.mat(Color(0.85, 0.92, 1.0, 0.8), 0.1))
		var dest := p + Vector3(_rng.randf_range(-0.5, 0.5), 0, _rng.randf_range(-0.5, 0.5)) * fuerza
		var alto := _rng.randf_range(0.3, 0.8) * fuerza
		var tg := g.create_tween()
		tg.tween_method(func(f: float) -> void:
			g.position = p.lerp(dest, f) + Vector3(0, sin(f * PI) * alto, 0), 0.0, 1.0, 0.5)
		tg.tween_callback(g.queue_free)

## El pez sale del agua dando vueltas y cae en el muelle.
func _pez_salta(pez: Array) -> void:
	var p := Node3D.new()
	_raiz.add_child(p)
	var col: Color = pez[2]
	if String(pez[0]).contains("bota"):
		Mini3D.caja(p, Vector3(0, 0.2, 0), Vector3(0.4, 0.64, 0.24), Mini3D.mat(col, 0.8))
		Mini3D.caja(p, Vector3(0, -0.06, 0.2), Vector3(0.4, 0.2, 0.6), Mini3D.mat(col, 0.8))
	else:
		var tam := 3.2 if String(pez[0]).contains("tiburón") else 2.0
		var cuerpo := Mini3D.esfera(p, Vector3.ZERO, 0.16 * tam, Mini3D.mat(col, 0.3))
		cuerpo.scale = Vector3(0.55, 0.8, 2.0)
		var cola := Mini3D.caja(p, Vector3(0, 0, 0.36 * tam), Vector3(0.03, 0.22, 0.14) * tam, Mini3D.mat(col.darkened(0.2), 0.4))
		cola.rotation.x = 0.4
		Mini3D.esfera(p, Vector3(0.06, 0.04, -0.22) * tam, 0.025, Mini3D.mat(Color.BLACK, 0.2))
	var desde := _corcho_base
	var hasta := Vector3(0.6, 0.8, -1.2)
	_salpicar(desde, 1.0)
	var tw := p.create_tween()
	tw.tween_method(func(f: float) -> void:
		p.position = desde.lerp(hasta, f) + Vector3(0, sin(f * PI) * 3.0, 0)
		p.rotation = Vector3(f * TAU * 1.5, f * 2.0, 0), 0.0, 1.0, 1.1)
	tw.tween_interval(1.0)
	tw.tween_property(p, "scale", Vector3.ONE * 0.01, 0.3)
	tw.tween_callback(p.queue_free)

func _nueva_lanzada() -> void:
	if _lanzadas >= 6:
		_estado_pesca = "fin"
		records["pesca"] = maxi(int(records["pesca"]), _puntos)
		_aviso.text = Idiomas.t("Fin de la pesca: %d puntos. %s") % [_puntos, ", ".join(_capturas) if not _capturas.is_empty() else Idiomas.t("Hoy no picó nada.")]
		_corcho.visible = false
		Mini3D.anim(_yo, "celebrar" if _puntos >= 10 else "parado", "parado")
		return
	_estado_pesca = "lanzando"
	_aviso.text = Idiomas.t("Lanzada %d de 6…") % (_lanzadas + 1)
	_corcho_base = Vector3(_rng.randf_range(-1.6, 2.4), 0.0, _rng.randf_range(-11.5, -8.5))
	## La caña va atrás y sale disparada; el corcho vuela en arco al agua.
	var tw := create_tween()
	tw.tween_property(_cana, "rotation:x", 1.25, 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_cana, "rotation:x", -0.25, 0.22).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(func() -> void:
		_corcho.visible = true
		_corcho.position = _punta.global_position)
	tw.tween_method(func(f: float) -> void:
		var a := _punta.global_position
		var p := a.lerp(_corcho_base, f)
		p.y = lerpf(a.y, _corcho_base.y, f) + sin(f * PI) * 2.5
		_corcho.position = p, 0.0, 1.0, 0.75)
	tw.tween_property(_cana, "rotation:x", 0.15, 0.4)
	tw.tween_callback(func() -> void:
		_salpicar(_corcho_base, 0.6)
		_estado_pesca = "espera"
		_t = _rng.randf_range(1.5, 4.5)
		_aviso.text = Idiomas.t("Lanzada %d de 6. Espera a que pique…") % (_lanzadas + 1))

## Recoge el sedal y prepara la siguiente lanzada.
func _recoger(espera: float) -> void:
	_estado_pesca = "sacando"
	var tw := create_tween()
	tw.tween_interval(espera * 0.5)
	tw.tween_method(func(f: float) -> void:
		_corcho.position = _corcho_base.lerp(_punta.global_position, f), 0.0, 1.0, 0.5)
	tw.tween_callback(func() -> void: _corcho.visible = false)
	tw.tween_interval(espera * 0.5)
	tw.tween_callback(_nueva_lanzada)

func _tirar() -> void:
	if _estado_pesca == "pica":
		var pez: Array = PECES[_rng.randi() % PECES.size()]
		_puntos += int(pez[1])
		_capturas.append(String(pez[0]).split(" ", true, 1)[0])
		_aviso.text = Idiomas.t("¡Sacaste %s! (+%d)") % [pez[0], pez[1]]
		_lanzadas += 1
		_estado_pesca = "sacando"
		_cana.rotation.x = 0.9
		create_tween().tween_property(_cana, "rotation:x", 0.15, 0.8)
		_pez_salta(pez)
		Mini3D.anim(_yo, "puno_al_aire" if int(pez[1]) > 0 else "manos_cabeza", "brazos_al_frente")
		_recoger(1.8)
	elif _estado_pesca == "espera":
		_aviso.text = Idiomas.t("Tiraste antes de tiempo: se espantó el pez.")
		_lanzadas += 1
		Mini3D.anim(_yo, "cabeza_gacha", "brazos_al_frente")
		_recoger(1.2)

func _pesca_empezar() -> void:
	## El río: un plano con oleaje propio.
	var agua := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(260, 260)
	pm.subdivide_width = 80
	pm.subdivide_depth = 80
	agua.mesh = pm
	var sh := Shader.new()
	sh.code = SHADER_AGUA
	_agua_mat = ShaderMaterial.new()
	_agua_mat.shader = sh
	agua.material_override = _agua_mat
	agua.position = Vector3(0, -0.1, -60)
	_raiz.add_child(agua)
	## El muelle de tablones sobre pilotes, con la orilla detrás.
	var madera := Mini3D.mat(Color(0.48, 0.34, 0.22), 0.85)
	var madera2 := Mini3D.mat(Color(0.4, 0.28, 0.18), 0.9)
	for k in 14:
		Mini3D.caja(_raiz, Vector3(0, 0.62, 6.0 - float(k) * 0.62), Vector3(3.2, 0.1, 0.56), madera if k % 2 == 0 else madera2)
	for z: float in [5.8, 2.5, -0.8, -2.0]:
		for x: float in [-1.5, 1.5]:
			Mini3D.cilindro(_raiz, Vector3(x, -0.4, z), 0.14, 2.2, madera2)
	Mini3D.caja(_raiz, Vector3(0, 0.0, 12.0), Vector3(80, 1.2, 12), Mini3D.mat(Color(0.35, 0.5, 0.25), 0.9))
	Mini3D.caja(_raiz, Vector3(0, 0.3, 7.5), Vector3(80, 0.6, 3), Mini3D.mat(Color(0.55, 0.52, 0.46), 0.9))
	## Bolardos, un balde y una caja de cebos.
	Mini3D.cilindro(_raiz, Vector3(-1.3, 0.85, -1.6), 0.12, 0.4, Mini3D.mat(Color(0.15, 0.15, 0.16), 0.4))
	Mini3D.cilindro(_raiz, Vector3(1.1, 0.85, 1.2), 0.22, 0.42, Mini3D.mat(Color(0.25, 0.45, 0.75), 0.5), 0.26)
	Mini3D.caja(_raiz, Vector3(-1.0, 0.8, 2.0), Vector3(0.6, 0.3, 0.4), Mini3D.mat(Color(0.75, 0.2, 0.15), 0.5))
	## La otra orilla: árboles y la ciudad.
	var hoja := Mini3D.mat(Color(0.2, 0.42, 0.2), 0.9)
	var tronco := Mini3D.mat(Color(0.35, 0.24, 0.15), 0.9)
	Mini3D.caja(_raiz, Vector3(0, 0.2, -95), Vector3(260, 2.0, 14), Mini3D.mat(Color(0.32, 0.46, 0.24), 0.9))
	for k in 26:
		var x := -120.0 + float(k) * 9.5 + _rng.randf_range(-2, 2)
		Mini3D.cilindro(_raiz, Vector3(x, 2.2, -92), 0.3, 2.4, tronco)
		Mini3D.cilindro(_raiz, Vector3(x, 5.0, -92), 2.2, 4.5, hoja, 0.0)
	_fondo_ciudad(Vector3(0, 0, -40), 72.0, PI * 0.82, PI * 1.18, 12)
	## Un bote amarrado que se mece.
	_bote = Node3D.new()
	_bote.position = Vector3(-6.5, 0.1, -3.0)
	_raiz.add_child(_bote)
	Mini3D.caja(_bote, Vector3(0, 0.25, 0), Vector3(1.6, 0.5, 4.2), Mini3D.mat(Color(0.85, 0.85, 0.82), 0.6))
	Mini3D.caja(_bote, Vector3(0, 0.52, 0), Vector3(1.7, 0.06, 4.3), Mini3D.mat(Color(0.1, 0.35, 0.6), 0.6))
	Mini3D.caja(_bote, Vector3(0, 0.45, 0.4), Vector3(1.4, 0.08, 0.4), madera)
	## Tú, en la punta del muelle, mirando al río.
	_yo = Mini3D.persona(_raiz, _rng, Vector3(0, 0.67, -1.6))
	if not _yo.is_empty():
		(_yo["nodo"] as Node3D).rotation.y = PI
		Mini3D.anim(_yo, "brazos_al_frente", "")
	## La caña: gira desde la mano (pivote) y lleva la punta al final.
	_cana = Node3D.new()
	_cana.position = Vector3(0.12, 1.62, -2.15)
	_raiz.add_child(_cana)
	var vara := Mini3D.cilindro(_cana, Vector3(0, 0, -1.4), 0.025, 2.8, Mini3D.mat(Color(0.15, 0.12, 0.1), 0.4), 0.008)
	vara.rotation.x = PI * 0.5
	Mini3D.cilindro(_cana, Vector3(0.05, -0.02, -0.15), 0.05, 0.08, Mini3D.mat(Color(0.7, 0.7, 0.72), 0.3)).rotation.z = PI * 0.5
	_punta = Node3D.new()
	_punta.position = Vector3(0, 0, -2.8)
	_cana.add_child(_punta)
	_cana.rotation.x = 0.55
	## El corcho rojo y blanco.
	_corcho = Node3D.new()
	_raiz.add_child(_corcho)
	Mini3D.esfera(_corcho, Vector3(0, 0.06, 0), 0.11, Mini3D.mat(Color(0.9, 0.12, 0.1), 0.4))
	Mini3D.esfera(_corcho, Vector3(0, 0.14, 0), 0.08, Mini3D.mat(Color.WHITE, 0.4))
	Mini3D.cilindro(_corcho, Vector3(0, 0.26, 0), 0.012, 0.16, Mini3D.mat(Color(0.95, 0.85, 0.2), 0.4))
	_corcho.visible = false
	## El sedal: una línea que va de la punta al corcho.
	_sedal_mesh = ImmediateMesh.new()
	_sedal = MeshInstance3D.new()
	_sedal.mesh = _sedal_mesh
	var ms := StandardMaterial3D.new()
	ms.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ms.albedo_color = Color(0.95, 0.95, 0.95, 0.85)
	ms.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_sedal.material_override = ms
	_raiz.add_child(_sedal)
	_cam.position = Vector3(3.6, 3.1, 3.4)
	_cam.look_at(Vector3(-0.4, 0.4, -7.5), Vector3.UP)
	var tirar := Button.new()
	tirar.text = Idiomas.t("¡TIRAR! (espacio)")
	tirar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	tirar.offset_top = -120
	tirar.offset_bottom = -80
	tirar.offset_left = -110
	tirar.offset_right = 110
	tirar.pressed.connect(_tirar)
	add_child(tirar)
	_nueva_lanzada()
