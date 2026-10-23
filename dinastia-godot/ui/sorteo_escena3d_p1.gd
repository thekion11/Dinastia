extends Node3D
## (Parte 1 de 3 de `sorteo_escena3d.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `sorteo_escena3d.gd`, conserva la clase.)

## El plató del sorteo, en 3D de verdad.
##
## No es una imagen con brillos: es una escena Forward+ (Vulkan) con bombo de
## cristal, bolas con FÍSICA que se apelotonan y ruedan solas, focos de estudio
## con volumen, suelo reflectante y cámara con profundidad de campo. El proyecto
## ya estaba en Forward+ por el estadio 3D, así que aquí no hubo que cambiar el
## método de render -que es de proyecto, no de escena-: solo aprovecharlo.
##
## POR QUÉ FÍSICA Y NO UNA ANIMACIÓN. Una animación de bolas dando vueltas se
## nota falsa a la segunda vez que la ves, porque repite igual. Con `RigidBody3D`
## cada sorteo se apelotona distinto, las bolas se empujan entre ellas y ruedan
## hasta parar. Es la misma razón por la que el partido se simula en vez de
## guionizarse.
##
## EL BOMBO NO LLEVA COLISIONADOR CÓNCAVO. Una malla cóncava para un cuenco sale
## cara y deja colarse cuerpos pequeños. En su lugar hay un anillo de cajas
## inclinadas hacia dentro más un disco de suelo: converge igual, cuesta una
## fracción y ninguna bola se escapa.

## Cuántas bolas hay dentro. Más de veinte y en la Intel UHD de esta máquina la
## física empieza a costar sin que se note nada en pantalla.
const BOLAS_MAX := 46
const RADIO_BOMBO := 0.78
const RADIO_BOLA := 0.072

var _camara: Camera3D
var _bombo: Node3D
var _bolas: Array[RigidBody3D] = []
var _bola_fuera: MeshInstance3D
var _escudo_placa: MeshInstance3D
var _confeti: GPUParticles3D
var _focos: Array[SpotLight3D] = []
var _acento := Color("f5c518")
var _t := 0.0
## Cuenta atrás para el siguiente empujón a las bolas. Ver `_process()`.
var _agitacion := 0.0

## Los planos de cámara. Ver la nota en `_process()`: se corta entre ellos en
## cada bola, que es lo que hace que la escena se lea como una retransmisión y
## no como un salvapantallas girando.
const PLANOS := [
	## General de sala: se ve el escenario, el público y la pantalla. Es el plano
	## con el que se abre y al que se vuelve para respirar.
	{"pos": Vector3(0.0, 2.35, 5.6), "mira": Vector3(0.0, 1.7, -1.2)},
	## Medio del bombo, ligeramente lateral: el plano de trabajo.
	{"pos": Vector3(-1.5, 1.85, 3.0), "mira": Vector3(0.1, 1.45, -0.6)},
	## Contrapicado desde el otro lado, con el presentador en primer término.
	## POR QUÉ ESTE ÁNGULO Y NO OTRO (14-9-2026): con el humanoide real, un
	## ángulo demasiado lateral respecto a hacia dónde mira el presentador
	## (gira -32° en `_montar_presentador_modelo()`) alinea el codo con la
	## cámara y el brazo -doblado de verdad, con el codo hacia el hombro y el
	## antebrazo colgando- se ve proyectado como una sola línea recta
	## "estirada", aunque el hueso esté perfectamente posado (comprobado con
	## `pruebas/captura_parado_aislado.gd`: mismos ángulos de hueso, un plano se
	## ve normal y el otro no). Casi de frente a hacia dónde mira -menos de
	## unos 35-40° de diferencia entre cámara y giro del cuerpo- el codo deja
	## de alinearse con el eje de vista y el brazo se lee doblado, no recto.
	{"pos": Vector3(0.5, 1.62, 2.5), "mira": Vector3(0.85, 1.3, -0.4)},
	## Cerrado de la pantalla gigante: el plano del anuncio.
	{"pos": Vector3(0.3, 2.9, 1.4), "mira": Vector3(0.0, 3.2, -6.0)},
]
var _plano := 0
var _mezcla_plano := 1.0
var _cam_pos := Vector3(0.0, 2.35, 5.6)
var _cam_mira := Vector3(0.0, 1.7, -1.2)

# ---------------------------------------------------------------------------
#  LA TEXTURA DEL BALÓN
# ---------------------------------------------------------------------------
#
# NO SE PUEDE USAR EL SVG PLANO DE `Sorteo._textura_bola()`. Ese dibujo es un
# círculo visto de frente; envuelto en una esfera, la proyección equirectangular
# lo estira sin piedad y los pentágonos salen como manchas derretidas hacia los
# polos. En la primera captura las bolas parecían palomitas.
#
# La forma correcta es generar la textura EN EL ESPACIO DE LA ESFERA: para cada
# téxel se calcula la dirección 3D a la que corresponde y se mira su ángulo
# contra los doce vértices de un icosaedro, que son exactamente los centros de
# los doce pentágonos negros de un balón clásico. Así los parches salen redondos
# desde cualquier ángulo, porque se han definido sobre la esfera y no sobre un
# papel.

const TEX_ANCHO := 512
const TEX_ALTO := 256
static var _tex_balon: Texture2D = null

# ---------------------------------------------------------------------------
#  LA PANTALLA GIGANTE Y EL PRESENTADOR
# ---------------------------------------------------------------------------

## LA PANTALLA DEL FONDO. En un sorteo de verdad la pared no es decorado: es
## donde aparece el club que acaba de salir, en grande, para que lo vea la sala.
## Sin ella la cinemática no CUENTA nada — el bombo se agita y hay que fiarse de
## un rótulo pequeño abajo.
##
## Se hace con un `SubViewport` que contiene interfaz 2D normal -escudo, nombre,
## grupo- y su `ViewportTexture` se pega como emisión a un plano. Es la única
## forma de tener TEXTO NÍTIDO dentro de una escena 3D: una malla con letras se
## ve borrosa en cuanto la cámara se mueve, y el rasterizador de SVG de este
## proyecto ni siquiera dibuja `<text>`.
var _pantalla_vp: SubViewport
var _pantalla_escudo: TextureRect
var _pantalla_nombre: Label
var _pantalla_grupo: Label

## EL PRESENTADOR: el mismo cuerpo Quaternius (CC0) que usan los 22 del
## campo, con traje liso pintado por `VestidorQ`, respirando de pie (`parado`)
## y con el gesto de sacar la bola resuelto con `mostrar_tarjeta`. Si el
## modelo no cargara, queda la silueta de cajas de respaldo.
var _brazo: Node3D
var _mano: MeshInstance3D
## El AnimationPlayer del modelo real, si se pudo montar. Null -> se usa el
## brazo suelto de respaldo (silueta), que sigue funcionando igual que antes.
var _anim_presentador: AnimationPlayer

## SI SE USA EL HUMANOIDE O LA SILUETA DE RESPALDO.
const USAR_MODELO_HUMANO := true

## EL PRESENTADOR REALISTA (25-9-2026): el modelo que el usuario dejó en su
## Drive para esto ("un tipo" para el sorteo), `navy-jacket-portrait`, un
## escaneo de una persona real -ver `PersonaRealista`-. Con chaqueta oscura,
## camiseta negra y pantalón gris: de gala sin llegar a traje. No tiene
## esqueleto, así que el gesto de sacar la bola se hace con el cuerpo entero:
## se gira hacia el bombo y se inclina, mientras la bola sube.
var _presentador_real: Node3D
var _giro_presentador := 0.0

## Cambia de plano. La lleva `Sorteo` en cada bola.
func cortar_plano(indice: int = -1) -> void:
	_plano = (randi() % PLANOS.size()) if indice < 0 else (indice % PLANOS.size())
	_mezcla_plano = 0.0

## Los doce vértices de un icosaedro normalizados. Salen de las tres "tarjetas
## áureas" perpendiculares: (0, ±1, ±φ) y sus rotaciones cíclicas.
static func _vertices_icosaedro() -> Array[Vector3]:
	var phi := (1.0 + sqrt(5.0)) / 2.0
	var v: Array[Vector3] = []
	for a in [-1.0, 1.0]:
		for b in [-phi, phi]:
			v.append(Vector3(0, a, b).normalized())
			v.append(Vector3(a, b, 0).normalized())
			v.append(Vector3(b, 0, a).normalized())
	return v

static func textura_balon() -> Texture2D:
	if _tex_balon != null:
		return _tex_balon
	var vs := _vertices_icosaedro()
	var img := Image.create(TEX_ANCHO, TEX_ALTO, false, Image.FORMAT_RGB8)
	## El ángulo del parche: 0,45 rad deja los pentágonos separados por costuras
	## blancas de grosor creíble. Más y se tocan; menos y parecen lunares.
	var umbral := 0.45
	var borde := 0.035
	for y in TEX_ALTO:
		## v va de 0 (polo norte) a 1 (polo sur): latitud de π/2 a -π/2.
		var lat := PI * (0.5 - float(y) / float(TEX_ALTO - 1))
		var cl := cos(lat)
		var sl := sin(lat)
		for x in TEX_ANCHO:
			var lon := TAU * float(x) / float(TEX_ANCHO - 1)
			var dir := Vector3(cl * cos(lon), sl, cl * sin(lon))
			var mejor := 9.0
			for vv in vs:
				var ang := acos(clampf(dir.dot(vv), -1.0, 1.0))
				if ang < mejor:
					mejor = ang
			var c: Color
			if mejor < umbral - borde:
				c = Color(0.09, 0.10, 0.12)
			elif mejor < umbral:
				## Antialias del borde: sin esto las costuras salen dentadas y se
				## nota muchísimo cuando la bola gira.
				var t := (mejor - (umbral - borde)) / borde
				c = Color(0.09, 0.10, 0.12).lerp(Color(0.96, 0.96, 0.94), t)
			else:
				## El blanco no es plano: un gradiente muy suave hacia las
				## costuras da la sensación de cuero cosido en vez de plástico.
				var s := clampf((mejor - umbral) / 0.35, 0.0, 1.0)
				c = Color(0.88, 0.88, 0.86).lerp(Color(0.99, 0.99, 0.97), s)
			img.set_pixel(x, y, c)
	_tex_balon = ImageTexture.create_from_image(img)
	return _tex_balon

# --- decorado ----------------------------------------------------------------

## El suelo: negro y PULIDO, para que refleje el bombo y las luces. El reflejo es
## lo que separa un plató de una caja negra con cosas dentro.
func _montar_suelo(fondo: Color) -> void:
	var m := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(40, 40)
	m.mesh = plano
	var mat := StandardMaterial3D.new()
	mat.albedo_color = fondo.darkened(0.8)
	mat.metallic = 0.85
	mat.roughness = 0.12
	mat.metallic_specular = 0.9
	m.material_override = mat
	m.position.y = -0.02
	add_child(m)

func _montar_sala(fondo: Color) -> void:
	var oscuro := StandardMaterial3D.new()
	oscuro.albedo_color = fondo.darkened(0.72)
	oscuro.roughness = 0.75

	## LA TARIMA. Elevada 42 cm sobre el patio de butacas, que es lo que hace que
	## se lea como escenario y no como suelo. El bombo se apoya encima.
	var deck := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(13.0, 0.42, 7.0)
	deck.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = fondo.darkened(0.62)
	dmat.metallic = 0.45
	dmat.roughness = 0.3
	deck.material_override = dmat
	deck.position = Vector3(0, 0.21, -1.6)
	add_child(deck)
	## El canto luminoso del borde: en toda gala la tarima lleva una tira de LED
	## que la dibuja contra la oscuridad del patio.
	var canto := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(13.0, 0.05, 0.06)
	canto.mesh = cm
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = _acento
	cmat.emission_enabled = true
	cmat.emission = _acento
	cmat.emission_energy_multiplier = 2.2
	canto.material_override = cmat
	canto.position = Vector3(0, 0.40, 1.9)
	add_child(canto)

	## LAS PAREDES LATERALES, giradas hacia dentro. Cierran el encuadre por los
	## lados: sin ellas la vista se escapa a negro y la sala no tiene tamaño.
	for lado in [-1.0, 1.0]:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.25, 6.5, 9.0)
		m.mesh = bm
		m.material_override = oscuro
		m.position = Vector3(lado * 7.2, 3.2, -1.5)
		m.rotation.y = deg_to_rad(-lado * 9.0)
		add_child(m)

	## EL TECHO Y EL TRUSS. Las barras negras cruzadas de las que cuelgan los
	## focos. Es el detalle que más dice "esto es un recinto" con menos gasto.
	var techo := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(15.0, 0.3, 12.0)
	techo.mesh = tm
	techo.material_override = oscuro
	techo.position = Vector3(0, 6.3, -0.5)
	add_child(techo)
	var barra := StandardMaterial3D.new()
	barra.albedo_color = Color(0.13, 0.14, 0.16)
	barra.metallic = 0.7
	barra.roughness = 0.45
	for i in 4:
		var t := MeshInstance3D.new()
		var bm2 := BoxMesh.new()
		bm2.size = Vector3(13.0, 0.14, 0.14)
		t.mesh = bm2
		t.material_override = barra
		t.position = Vector3(0, 5.85, -3.2 + float(i) * 1.6)
		add_child(t)
		## Los cuerpos de foco colgados del truss, apagados salvo el central.
		for j in 7:
			var foco := MeshInstance3D.new()
			var fm := CylinderMesh.new()
			fm.top_radius = 0.11
			fm.bottom_radius = 0.15
			fm.height = 0.34
			foco.mesh = fm
			foco.material_override = barra
			foco.position = Vector3(-4.5 + float(j) * 1.5, 5.62, -3.2 + float(i) * 1.6)
			foco.rotation.x = deg_to_rad(28.0)
			add_child(foco)

## La pantalla de fondo con paneles LED en el color de la competición. Es lo que
## da la identidad: el mismo sorteo en azul es la Champions y en amarillo la
## Libertadores, sin escribir el nombre en ninguna parte.
func _montar_pared(fondo: Color) -> void:
	var pared := Node3D.new()
	pared.position = Vector3(0, 0, -6.4)
	add_child(pared)
	## LA PARED ANTES ERA RUIDO PURO: cada panel con un brillo al azar sin
	## relación con el de al lado, y en captura se leía como un tablero de
	## ajedrez verde y amarillo, no como una pantalla. Una pared LED de
	## verdad muestra UN gráfico -un degradado, un logo, una animación- que
	## varía suave de panel a panel; el único ruido de una pantalla real es
	## la costura entre módulos, que es un detalle minúsculo, no el 65% de
	## rango que había aquí. Ahora el brillo sale de la DISTANCIA al centro
	## de la pared -un resplandor que se apaga hacia los bordes, como el
	## gráfico de fondo de cualquier plató- y el azar que queda es solo la
	## costura, con un rango diez veces más chico.
	var centro_col := 10.5
	var centro_fila := 6.0
	for fila in 13:
		for col in 22:
			var p := MeshInstance3D.new()
			var caja := BoxMesh.new()
			caja.size = Vector3(0.62, 0.42, 0.06)
			p.mesh = caja
			var mat := StandardMaterial3D.new()
			var dist := Vector2(float(col) - centro_col, float(fila) - centro_fila).length() / 12.0
			var v := clampf(1.0 - dist, 0.1, 1.0)
			## La costura entre módulos: una variación mínima, no el brillo.
			v += (fmod(float(fila * 7 + col * 13) * 0.137, 1.0) - 0.5) * 0.08
			v = clampf(v, 0.08, 1.0)
			## OJO CON LA ENERGÍA. A 1,7 la pared quemaba la escena entera: el
			## bombo se veía en contraluz, los rótulos no se leían y todo salía
			## amarillo. Una pared LED de plató ILUMINA POCO -está lejos y es
			## decorado-, así que va por debajo de 0,4. Se vio en captura, que es
			## la única forma de cazar un problema de exposición.
			mat.albedo_color = fondo.darkened(0.35)
			mat.emission_enabled = true
			mat.emission = _acento.lerp(fondo, 0.7)
			mat.emission_energy_multiplier = v * 0.6
			p.material_override = mat
			p.position = Vector3(-6.6 + float(col) * 0.63, 0.55 + float(fila) * 0.43, 0.0)
			pared.add_child(p)

## Tres focos de estudio y un contraluz. Los focos se mueven en `_process`: un
## plató con las luces quietas parece una foto.
func _montar_luces() -> void:
	for i in 3:
		var f := SpotLight3D.new()
		## La luz PRINCIPAL va blanca. Tiñendo los tres focos con el acento, un
		## sorteo de Libertadores salía entero amarillo y no se distinguía el
		## cristal del metal ni del balón. El color lo pone el decorado -pared,
		## aro, contraluz-, no la luz que baña al sujeto.
		f.light_color = Color.WHITE if i == 1 else Color.WHITE.lerp(_acento, 0.4)
		f.light_energy = 4.0 if i == 1 else 2.4
		f.spot_range = 14.0
		f.spot_angle = 26.0
		f.spot_attenuation = 1.4
		f.shadow_enabled = i == 1
		var pos := Vector3(-2.6 + float(i) * 2.6, 4.2, 1.4)
		add_child(f)
		f.look_at_from_position(pos, Vector3(0, 1.4, -0.6), Vector3.UP)
		_focos.append(f)
	## RELLENO de frente (MEGAPLAN fase 1): sin él, fuera de los conos de los
	## focos todo era negro -el presentador, la tarima, la mitad del bombo-.
	var relleno := DirectionalLight3D.new()
	relleno.light_color = Color(1.0, 0.97, 0.92)
	relleno.light_energy = 0.7
	relleno.shadow_enabled = false
	relleno.rotation_degrees = Vector3(-28, 8, 0)
	add_child(relleno)
	## Contraluz frío por detrás: recorta la silueta del bombo contra la pared.
	var contra := OmniLight3D.new()
	contra.light_color = _acento
	contra.light_energy = 4.5
	contra.omni_range = 9.0
	contra.position = Vector3(0, 1.6, -2.6)
	add_child(contra)

## El colisionador del cuenco: anillo de cajas inclinadas hacia dentro más un
## disco de suelo. Ver la nota de cabecera.
func _montar_paredes_fisicas() -> void:
	## EL CUENCO DE VERDAD (MEGAPLAN fase 1): antes era un disco del radio
	## entero en el fondo y paredes que empezaban más arriba; por la rendija del
	## borde se escapaban 43 de las 46 bolas y caían al vacío. Ahora son cajas
	## TANGENTES a la esfera, en anillos de latitud que se solapan, y un disco
	## pequeño en el fondo: misma forma que el cristal.
	var cuerpo := StaticBody3D.new()
	_bombo.add_child(cuerpo)
	var grueso := 0.08
	var suelo := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = RADIO_BOMBO * sin(deg_to_rad(16.0))
	cil.height = grueso
	suelo.shape = cil
	suelo.position = Vector3(0, -RADIO_BOMBO - grueso * 0.5, 0)
	cuerpo.add_child(suelo)
	var lados := 20
	for th_g: float in [16.0, 32.0, 48.0, 64.0, 80.0, 92.0]:
		var th := deg_to_rad(th_g)
		var r_lat := RADIO_BOMBO * sin(th)
		for i in lados:
			var ph := float(i) * TAU / float(lados)
			var n := Vector3(sin(th) * cos(ph), -cos(th), sin(th) * sin(ph))
			var forma := CollisionShape3D.new()
			var caja := BoxShape3D.new()
			caja.size = Vector3(maxf(0.08, TAU * r_lat / float(lados) * 1.25), RADIO_BOMBO * deg_to_rad(16.0) * 1.35, grueso)
			forma.shape = caja
			var zx := n
			var xx := Vector3(-sin(ph), 0.0, cos(ph))
			var yx := zx.cross(xx).normalized()
			forma.transform = Transform3D(Basis(xx, yx, zx), n * (RADIO_BOMBO + grueso * 0.5))
			cuerpo.add_child(forma)
