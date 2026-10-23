extends "res://visor/stadium_builder_p10_p1.gd"
## [Capa 11/12 de `stadium_builder.gd`] build_2, build

## Tramo 2 de 2 de `build` (la norma de 450 líneas la troceó).
static func build_2(root: Node3D, est: Dictionary, ocupacion: float, seed_val: int, mi: Club, g: Dictionary, dz: float, dx: float, abierta: int, abiertas: Array, niveles: int, alto: float, techo: String, stand_mat: StandardMaterial3D, fondo_trib: float, ang: float, caras_fachada: Array):

	## LAS ESQUINAS TAMBIÉN LLEVAN GENTE (22-9-2026). "Falta un tramo" -el
	## usuario lo vio de inmediato justo después de la ronda de las butacas
	## reales-: en una forma "esquinas: true" (cuenco/oval/caldera/inglés/
	## herradura, todas menos "rect") estos 4 bloques cierran el hueco entre
	## dos tribunas rectas, pero usaban `stand_mat` -la misma fachada de
	## hormigón LISO de los muros, ni un solo asiento ni una sola cabeza-. En
	## un recinto ovalado de verdad la grada da toda la vuelta sin cortes; acá
	## se veía como un tramo de pared ciega metido a la fuerza entre dos
	## tribunas llenas. Misma textura de grada que ya usa el resto del
	## estadio (`_make_stand_texture()`, mismos colores/patrón/ocupación),
	## sin repetir (`uv1_scale=1`, el bloque es chico, 12m, no hace falta
	## repetir cada 20m) y con el mismo filtro anisotrópico que ya lleva
	## `crowd_mat` -mismo criterio que Tramo, no dejar una textura de grada
	## nueva sin la corrección de aliasing ya encontrada el 21-9-2026-.
	## BUG REAL (23-9-2026, ultimo de los 12 de la auditoria): la condicion era
	## `esquinas and abierta < 0`, o sea que en cuanto una tribuna faltaba
	## -"herradura"- se quitaban LAS CUATRO esquinas, incluidas las dos del
	## extremo CERRADO, donde las dos tribunas vecinas si existen y el hueco
	## entre ellas queda a la vista. Ahora se decide esquina por esquina.
	_tm("tribunas")
	if bool(g["esquinas"]):
		var esquina_mat := StandardMaterial3D.new()
		esquina_mat.albedo_texture = _make_stand_texture(
			str(est.get("asientoP", "franjas")),
			_c(est.get("asiento1"), "#2b6b45"), _c(est.get("asiento2"), "#ffffff"),
			_c(est.get("asiento3"), "#20272a"), seed_val, clampf(ocupacion, 0.05, 0.98))
		esquina_mat.roughness = 1.0
		esquina_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		esquina_mat.uv1_scale = Vector3(1.0, 1.0, 1.0)
		## BUG REAL (23-9-2026): el bloque iba en `(dx-3, dz-3)` con 12 m de
		## lado, o sea x de dx-9 a dx+3. La cara interior de las tribunas está
		## en dx-5,5: **la esquina sobresalía 3,5 m hacia dentro del cuenco**,
		## como un pilar metido delante de las dos tribunas vecinas, y a la vez
		## enterraba el extremo de cada rampa con sus butacas. En la forma más
		## chica ("inglés", dx=45) llegaba a 2 m de la línea de banda.
		##
		## Y SEGUNDA VUELTA, con el graderío por bandejas: la esquina tiene que
		## usar el MISMO centro y el MISMO fondo que las tribunas, que ahora
		## dependen de cuántas bandejas hay. Dejada en `(dx, dz)` con 11 m
		## fijos, en un estadio de 5 bandejas quedaba como una torre suelta de
		## 46 m por delante de las dos tribunas, en vez de cerrando el hueco.
		for sx in [1.0, -1.0]:
			for sz in [1.0, -1.0]:
				## `stands` numera 0 = fondo en +dz, 1 = fondo en -dz. Una
				## esquina solo se quita si da al fondo que no existe.
				if (0 in abiertas and sz > 0.0) or (1 in abiertas and sz < 0.0):
					continue
				_esquina_grada(root, sx, sz, dx, dz, alto, niveles,
					esquina_mat, stand_mat, ang, est, ocupacion, seed_val,
					techo in ["anillo", "total", "membrana", "retractil"])
				caras_fachada.append_array(_caras_esquina(sx, sz, dx, dz, alto, niveles,
					techo in ["anillo", "total", "membrana", "retractil"]))
	elif abiertas.is_empty():
		## ESQUINAS CERRADAS EN LAS FORMAS SIN GRADA DE ESQUINA (21-10-2026, «el
		## estadio por fuera»): en «rect» y «principal» quedaban cuatro huecos por
		## los que se veía el revés de las gradas. Como en los estadios ingleses,
		## cada esquina la cierra un edificio bajo de servicios con su fachada.
		for sx in [1.0, -1.0]:
			for sz in [1.0, -1.0]:
				var p0 := Vector3(sx * (dx - FRENTE_TRIBUNA), 0.0, sz * (dz - FRENTE_TRIBUNA))
				var lado_e := fondo_trib + 2.0
				var alto_e := maxf(alto * 0.55, 7.0)
				var c_e := p0 + Vector3(sx, 0.0, sz) * (lado_e * 0.5)
				_box(root, Vector3(c_e.x, alto_e / 2.0, c_e.z), Vector3(lado_e, alto_e, lado_e), stand_mat)
				for n: Vector3 in [Vector3(sx, 0, 0), Vector3(0, 0, sz)]:
					caras_fachada.append(FachadaEstadio.cara(c_e + n * (lado_e * 0.5), n, lado_e, alto_e, "esquina", false, lado_e, niveles))

	# vallas perimetrales, siempre por dentro de la cara interior de la tribuna
	_tm("esquinas")
	if bool(est.get("vallas", true)):
		## Metal de verdad (17-9-2026, ronda 5): es literalmente una malla/reja
		## perimetral, el material menos "plastico" posible para esto.
		var valla := Texturas.metal(Color(0.12, 0.13, 0.15), 0.5)
		## Con el paso del túnel abierto: la valla del fondo +Z se parte.
		for tr: Vector2 in _tramos_sin_hueco(0.0, 78.0, tunel_x(est) - 2.6, tunel_x(est) + 2.6):
			_box(root, Vector3(tr.x, 0.6, 56.5), Vector3(tr.y, 1.2, 0.3), valla)
		_box(root, Vector3(0, 0.6, -56.5), Vector3(78.0, 1.2, 0.3), valla)
		_box(root, Vector3(38.0, 0.6, 0), Vector3(0.3, 1.2, 113.0), valla)
		_box(root, Vector3(-38.0, 0.6, 0), Vector3(0.3, 1.2, 113.0), valla)

	## CONECTORES MUDOS DEL DISEÑADOR DE ESTADIO (23-9-2026). El usuario pidió
	## "una buena revisión a las bandejas en el ámbito de los conectores", y es
	## el mismo patrón que este proyecto ya persiguió dos veces en `nucleo/`:
	## cosas que EXISTEN en el catálogo, se cobran, y no las mira nadie. En el
	## visor había cuatro, y una de ellas es el capítulo MÁS CARO del diseñador.
	_tm("vallas")
	_pista_atletismo(root, est, dx, dz)
	## El túnel de verdad: pasillo, cubierta del hueco y vestuario.
	_tm("pista")
	TunelVestuario.montar(root, est, niveles, mi)
	_tm("tunel")
	_banderas(root, est, dx, dz, alto, niveles, mi)
	## LOS GUIÑOS DEL ESTADIO REAL (MEGAPLAN fase 4, E9): lo que dice su rasgo.
	_tm("banderas")
	GuinosEstadio.montar(root, est, dx, dz, fondo_tribuna(niveles), alto)
	_tm("guinos")
	_focos(root, str(est.get("focos", "torres")), dx, dz, alto, color_luz(est), str(est.get("focosCol", "")))
	## B6.2: lo que hay FUERA del recinto: taquillas, tienda y estacionamiento.
	_tm("focos")
	if bool(est.get("exterior", false)):
		_exterior(root, est, dx, dz, niveles, mi)
	_tm("exterior")
	_pantallas(root, str(est.get("pantalla", "dos")), dz, alto, est, mi, abierta, abiertas)
	_tm("pantallas")
	## LA FACHADA DE VERDAD (16-10-2026, `FachadaEstadio`): estructura, piel,
	## puertas, escaleras y cubierta vista desde fuera, según el estilo del estadio.
	var donde_escudo := str(est.get("escudoDonde", "sin"))
	var tex_escudo: Texture2D = null
	if mi != null and donde_escudo in ["fachada", "todo"]:
		tex_escudo = Escudo.textura(mi, 256)
	if not caras_fachada.is_empty():
		## La primera cara con tribuna lleva el escudo si la del túnel no existe.
		var con_escudo := false
		for cf: Dictionary in caras_fachada:
			con_escudo = con_escudo or bool(cf.get("escudo", false))
		if not con_escudo:
			for cf: Dictionary in caras_fachada:
				if cf["tipo"] == "tribuna":
					cf["escudo"] = true
					break
	var fachada := FachadaEstadio.montar(root, est, caras_fachada, seed_val, niveles, tex_escudo)
	_tm("fachada")
	if mi != null:
		_escudo_tribuna(root, mi, donde_escudo, dx, dz, alto, fachada.find_child("EscudoFachada", false, false) != null)
	## Obras con andamios y grúa, palcos, prensa, museo, tienda y la mascota
	## (26-9-2026, `EstadioExtras`).
	_tm("club")
	EstadioExtras.construir(root, est, dx, dz, alto, niveles, mi)
	_tm("extras")
	if OS.get_environment("SIN_SOMBRA_UNICA") == "":
		_sombra_unica(root)
		_tm("sombra")

static func build(root: Node3D, est: Dictionary, cap_efectiva: int, ocupacion: float, seed_val: int, mi: Club = null) -> void:
	var _r1 = build_1(root, est, cap_efectiva, ocupacion, seed_val, mi)
	est = _r1[0]
	var g: Dictionary = _r1[1]
	var dz: float = _r1[2]
	var dx: float = _r1[3]
	var abierta: int = _r1[4]
	var abiertas: Array = _r1[5]
	var niveles: int = _r1[6]
	var alto: float = _r1[7]
	var techo: String = _r1[8]
	var stand_mat: StandardMaterial3D = _r1[9]
	var fondo_trib: float = _r1[10]
	var ang: float = _r1[11]
	var caras_fachada: Array = _r1[12]
	build_2(root, est, ocupacion, seed_val, mi, g, dz, dx, abierta, abiertas, niveles, alto, techo, stand_mat, fondo_trib, ang, caras_fachada)
