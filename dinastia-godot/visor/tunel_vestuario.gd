class_name TunelVestuario
extends RefCounted
## EL TÚNEL DE VESTUARIOS DE VERDAD (7-10-2026).
##
## Pedido del usuario (ROADMAP 2-septies): *"La zona del túnel deben ser más
## reales, a futuro el estadio será navegable con el protagonista."* Hasta hoy
## el túnel era una mole de hormigón con una placa negra delante: no había
## nada detrás. Ahora:
##   - la tribuna del fondo +Z tiene un HUECO de verdad (muro, zócalo y primera
##     bandeja partidos, ver `StadiumBuilder.build`), cubierto por una losa de
##     hormigón con sus petos, como el corte que deja un túnel en la grada baja;
##   - por el hueco pasa un PASILLO con suelo, paredes, techo, luces, el nombre
##     del club, fotos de su historia y la señal «AL CAMPO»;
##   - el pasillo atraviesa la tribuna y llega al VESTUARIO, un edificio detrás
##     del muro: taquillas con las camisetas, bancos, la pizarra, la camilla y
##     las duchas;
##   - todo tiene colisión (`StaticBody3D`) y `datos()` da las zonas por las
##     que se puede caminar: lo usa `ExploradorEstadio` para recorrerlo a pie.
##
## Todo sale de la misma geometría que el resto del recinto (`dz`, la forma y
## las bandejas), así que el túnel queda a ras en cualquiera de las 8 formas.

## Medio ancho libre del pasillo y su alto libre.
const MEDIO := 2.4
const ALTO := 3.0
## La puerta del club en la fachada de atrás del vestuario (a la calle):
## desplazada del eje para no chocar con la pizarra.
const PUERTA_X := 5.5
const PUERTA_MEDIO := 1.3
## Vestuario: medio ancho y fondo.
const VEST_MEDIO := 8.0
const VEST_FONDO := 13.0

## La geometría del túnel para un perfil de estadio: dónde está la boca, dónde
## sale por detrás de la tribuna y por dónde se puede caminar.
static func datos(est: Dictionary, niveles: int) -> Dictionary:
	var g := StadiumBuilder.geom_de_forma(String(est.get("forma", "cuenco")))
	var dz: float = g["dz"]
	var x0 := StadiumBuilder.tunel_x(est)
	var z_boca := dz - StadiumBuilder.FRENTE_TRIBUNA
	var z_out := z_boca + StadiumBuilder.fondo_tribuna(niveles)
	var z_fin := z_out + VEST_FONDO
	var zonas: Array = [
		{"nombre": "Vestuario", "r": Rect2(x0 - VEST_MEDIO + 0.6, z_out + 0.6, (VEST_MEDIO - 0.6) * 2.0, VEST_FONDO - 1.2), "techo": ALTO + 0.4},
		{"nombre": "Túnel", "r": Rect2(x0 - MEDIO + 0.35, z_boca - 0.6, (MEDIO - 0.35) * 2.0, z_out - z_boca + 1.4), "techo": ALTO},
		## De la boca a la cancha: el paso entre las vallas.
		{"nombre": "Banda", "r": Rect2(x0 - MEDIO + 0.35, 53.8, (MEDIO - 0.35) * 2.0, z_boca - 53.2), "techo": 99.0},
		{"nombre": "Campo", "r": Rect2(-37.2, -54.6, 74.4, 109.2), "techo": 99.0},
		## La puerta del club en la fachada de atrás: da a la calle (ciudad).
		{"nombre": "Acceso", "r": Rect2(x0 + PUERTA_X - PUERTA_MEDIO + 0.3, z_fin - 1.0, (PUERTA_MEDIO - 0.3) * 2.0, 4.0), "techo": 99.0},
	]
	## Las plantas del edificio del club (estadio 2.0): sus ascensores van
	## delante para ganar al pisar.
	zonas = EdificioClub.zonas(x0, z_out, z_fin) + zonas
	return {"x0": x0, "z_boca": z_boca, "z_out": z_out, "z_fin": z_fin, "zonas": zonas,
		"inicio": Vector3(x0 + 3.0, 0.02, z_fin - 3.2), "rumbo_inicio": PI,
		"puerta": Vector3(x0 + PUERTA_X, 0.02, z_fin + 0.2),
		"abierta": 0 in (g.get("abiertas", [g["abierta"]] if int(g["abierta"]) >= 0 else []) as Array)}

## ¿En qué zona transitable cae `p` (coordenadas del estadio)? Vacío si en
## ninguna. Lo usan los dos exploradores (el del estadio y el de la ciudad).
static func zona_en(zonas: Array, p: Vector3, planta: int = 0) -> Dictionary:
	for z: Dictionary in zonas:
		if int(z.get("planta", 0)) == planta and (z["r"] as Rect2).has_point(Vector2(p.x, p.z)):
			return z
	return {}

## Monta pasillo, cubierta, pórtico y vestuario. `mi` puede ser null (rival).
static func montar(root: Node3D, est: Dictionary, niveles: int, mi: Club = null) -> void:
	var d := datos(est, niveles)
	var x0: float = d["x0"]
	var z_boca: float = d["z_boca"]
	var z_out: float = d["z_out"]
	var z_fin: float = d["z_fin"]
	var nodo := Node3D.new()
	nodo.name = "TunelVestuario"
	root.add_child(nodo)
	var c1 := StadiumBuilder._c(est.get("asiento1"), "#2b6b45")
	var c2 := StadiumBuilder._c(est.get("asiento2"), "#ffffff")
	if mi != null:
		c1 = StadiumBuilder._c(mi.color_escudo1(), c1.to_html())
		c2 = StadiumBuilder._c(mi.color_escudo2(), c2.to_html())
	var horm: StandardMaterial3D = Texturas.hormigon(Color(0.52, 0.53, 0.55), 23).duplicate()
	var pared := _mat(Color(0.93, 0.93, 0.9), 0.85)
	var zocalo := _mat(c1.lerp(Color(0.1, 0.1, 0.12), 0.25), 0.6)
	var suelo := _mat(Color(0.16, 0.17, 0.19).lerp(c1, 0.18), 0.95)
	var techo := _mat(Color(0.82, 0.83, 0.84), 0.9)
	var luz := _mat(Color(1, 0.98, 0.92), 0.4)
	luz.emission_enabled = true
	luz.emission = Color(1, 0.96, 0.88)
	luz.emission_energy_multiplier = 2.2
	luz.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var largo := z_out - z_boca + 0.4
	var zc := (z_boca + z_out) / 2.0 + 0.2

	## EL PASILLO. Paredes gruesas (llegan hasta el borde del hueco de la
	## grada, así no queda un canto suelto entre la pared y la butaca).
	var grueso := StadiumBuilder.TUNEL_HUECO - MEDIO
	_caja(nodo, Vector3(x0, 0.01, zc), Vector3(MEDIO * 2.0, 0.02, largo), suelo, false)
	for lado in [-1.0, 1.0]:
		var xp: float = x0 + lado * (MEDIO + grueso / 2.0)
		_caja(nodo, Vector3(xp, ALTO / 2.0, zc), Vector3(grueso, ALTO, largo), pared, true)
		## Zócalo del color del club en la cara de dentro, hasta 1,1 m.
		_caja(nodo, Vector3(x0 + lado * (MEDIO - 0.02), 0.55, zc), Vector3(0.04, 1.1, largo), zocalo, false)
		## Pasamanos.
		_caja(nodo, Vector3(x0 + lado * (MEDIO - 0.08), 1.0, zc), Vector3(0.06, 0.06, largo - 1.0),
			Texturas.metal(Color(0.7, 0.72, 0.74), 0.4), false)
	_caja(nodo, Vector3(x0, ALTO + 0.2, zc), Vector3(StadiumBuilder.TUNEL_HUECO * 2.0, 0.4, largo), techo, true)
	## Luces del techo: una tira cada 3,5 m y una luz de verdad cada 7.
	var z := z_boca + 1.2
	var k := 0
	while z < z_out - 0.5:
		_caja(nodo, Vector3(x0, ALTO - 0.03, z), Vector3(1.6, 0.05, 0.35), luz, false)
		if k % 2 == 0:
			var o := OmniLight3D.new()
			o.position = Vector3(x0, ALTO - 0.4, z)
			o.omni_range = 6.5
			o.light_energy = 1.3
			o.light_color = Color(1, 0.96, 0.9)
			nodo.add_child(o)
		z += 3.5
		k += 1

	## LO QUE SE LEE AL PASAR: el escudo, el nombre, fotos de la historia y la
	## señal de salida. Los textos van con `Label3D` (como las vallas LED).
	var nombre := Nombres.visible(mi.nombre) if mi != null else String(est.get("club_nombre", "LOCAL"))
	_rotulo(nodo, Idiomas.t("AL CAMPO") + "  ↑", Vector3(x0, ALTO - 0.45, z_boca + 0.6), 0.0, 44, Color(1, 0.95, 0.75))
	_rotulo(nodo, nombre.to_upper(), Vector3(x0 - MEDIO + 0.03, 2.2, zc), PI / 2.0, 72, c2.lerp(Color.WHITE, 0.3))
	_rotulo(nodo, Idiomas.t("AQUÍ SE DEJA TODO"), Vector3(x0 + MEDIO - 0.03, 2.2, z_boca + 2.0), -PI / 2.0, 52, c1.lerp(Color.WHITE, 0.1))
	var hist: Dictionary = Datos.tabla("HISTORIA_CLUBES").get(Nombres.limpiar(mi.nombre), {}) if mi != null and Datos.tiene("HISTORIA_CLUBES") else {}
	var fotos := [str(hist.get("fundado", "")), str(hist.get("apodo", "")), Idiomas.t("Campeones"), Idiomas.t("La afición")]
	var z_f := z_boca + 4.0
	for f: String in fotos:
		if z_f > z_out - 2.0:
			break
		_cuadro(nodo, Vector3(x0 + MEDIO - 0.04, 1.75, z_f), c1, f)
		z_f += 2.6
	if mi != null:
		var tex := Escudo.textura(mi, 256)
		if tex != null:
			var em := StandardMaterial3D.new()
			em.albedo_texture = tex
			em.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			var q := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(1.5, 1.5)
			q.mesh = qm
			q.material_override = em
			## Al fondo del pasillo, sobre la puerta del vestuario, mirando al campo.
			q.position = Vector3(x0, ALTO - 0.9, z_out - 0.25)
			q.rotation.y = PI
			nodo.add_child(q)

	## EL PÓRTICO DE SALIDA: dos pilares y un dintel con el nombre, a ras de la
	## cara de la tribuna.
	var portico := _mat(c1.lerp(Color(0.12, 0.12, 0.14), 0.35), 0.5)
	for lado in [-1.0, 1.0]:
		_caja(nodo, Vector3(x0 + lado * (MEDIO + grueso / 2.0), (ALTO + 0.8) / 2.0, z_boca - 0.2),
			Vector3(grueso + 0.2, ALTO + 0.8, 0.5), portico, true)
	_caja(nodo, Vector3(x0, ALTO + 0.4, z_boca - 0.2), Vector3(StadiumBuilder.TUNEL_HUECO * 2.0 + 0.2, 0.8, 0.5), portico, false)
	_rotulo(nodo, nombre.to_upper(), Vector3(x0, ALTO + 0.4, z_boca - 0.46), PI, 56, c2.lerp(Color.WHITE, 0.4))

	## LA CUBIERTA SOBRE EL HUECO DE LA GRADA: donde la rampa ya va por encima
	## del techo del pasillo, una losa de hormigón con su misma inclinación;
	## y a los dos lados, los petos que cierran el corte entre las butacas.
	if not bool(d["abierta"]):
		var ang := deg_to_rad(StadiumBuilder.RAKE_GRADOS)
		var d0 := (ALTO + 0.45 - StadiumBuilder.ALTURA_PIE) / tan(ang)
		var d1 := StadiumBuilder.FONDO_BANDEJA
		var lr := (d1 - d0) / cos(ang)
		var dm := (d0 + d1) / 2.0
		var y_sup := StadiumBuilder.ALTURA_PIE + dm * tan(ang)
		var losa := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(StadiumBuilder.TUNEL_HUECO * 2.0, 0.4, lr)
		losa.mesh = bm
		losa.position = Vector3(x0, y_sup, z_boca + dm)
		losa.rotation.x = -ang
		losa.material_override = horm
		nodo.add_child(losa)
		var lp := d1 / cos(ang)
		for lado in [-1.0, 1.0]:
			var peto := MeshInstance3D.new()
			var pm := BoxMesh.new()
			pm.size = Vector3(0.3, 1.1, lp)
			peto.mesh = pm
			peto.position = Vector3(x0 + lado * (StadiumBuilder.TUNEL_HUECO - 0.15),
				StadiumBuilder.ALTURA_PIE + d1 / 2.0 * tan(ang) + 0.75, z_boca + d1 / 2.0)
			peto.rotation.x = -ang
			peto.material_override = horm
			nodo.add_child(peto)
	else:
		## Sin tribuna en ese fondo («dos»): una pasarela cubierta, con tejado.
		_caja(nodo, Vector3(x0, ALTO + 0.6, zc), Vector3(StadiumBuilder.TUNEL_HUECO * 2.0 + 0.6, 0.2, largo + 0.6), portico, false)

	_vestuario(nodo, x0, z_out, z_fin, c1, c2, pared, suelo, techo, luz, horm, nombre, mi)
	EdificioClub.montar(nodo, x0, z_out, z_fin, c1, c2, horm, luz, nombre)
	## La gente del club, cada uno en su puesto (solo en el estadio propio).
	if mi == null or mi.id == PersonajeDT.club_usuario:
		var personal := PersonalEstadio.new()
		personal.preparar(d, c1, c2)
		nodo.add_child(personal)

static func _vestuario(nodo: Node3D, x0: float, z_out: float, z_fin: float, c1: Color, c2: Color,
		pared: StandardMaterial3D, suelo: StandardMaterial3D, techo: StandardMaterial3D,
		luz: StandardMaterial3D, horm: StandardMaterial3D, nombre: String, mi: Club) -> void:
	var alto := ALTO + 0.4
	var zc := (z_out + z_fin) / 2.0
	var ancho := VEST_MEDIO * 2.0
	## La caja del edificio: muros de hormigón por fuera y pintura por dentro.
	_caja(nodo, Vector3(x0, 0.01, zc), Vector3(ancho, 0.02, VEST_FONDO), suelo, false)
	_caja(nodo, Vector3(x0, alto + 0.25, zc), Vector3(ancho + 0.6, 0.5, VEST_FONDO + 0.6), horm, true)
	_caja(nodo, Vector3(x0, alto - 0.02, zc), Vector3(ancho - 0.1, 0.04, VEST_FONDO - 0.1), techo, false)
	for lado in [-1.0, 1.0]:
		_caja(nodo, Vector3(x0 + lado * (VEST_MEDIO + 0.15), alto / 2.0, zc), Vector3(0.3, alto, VEST_FONDO + 0.6), horm, true)
	## La fachada de atrás, con la PUERTA DEL CLUB a la calle.
	for tr: Vector2 in StadiumBuilder._tramos_sin_hueco(x0, ancho + 0.6, x0 + PUERTA_X - PUERTA_MEDIO, x0 + PUERTA_X + PUERTA_MEDIO):
		_caja(nodo, Vector3(tr.x, alto / 2.0, z_fin + 0.15), Vector3(tr.y, alto, 0.3), horm, true)
	_caja(nodo, Vector3(x0 + PUERTA_X, (alto + 2.6) / 2.0, z_fin + 0.15), Vector3(PUERTA_MEDIO * 2.0, alto - 2.6, 0.3), horm, false)
	## Marquesina y felpudo del club.
	_caja(nodo, Vector3(x0 + PUERTA_X, 2.85, z_fin + 1.0), Vector3(PUERTA_MEDIO * 2.0 + 1.2, 0.12, 1.6), _mat(c1.lerp(Color(0.1, 0.1, 0.12), 0.3), 0.5), false)
	_caja(nodo, Vector3(x0 + PUERTA_X, 0.03, z_fin + 1.0), Vector3(PUERTA_MEDIO * 2.0, 0.03, 1.2), _mat(c1, 0.9), false)
	_rotulo(nodo, Idiomas.t("ENTRADA DEL CLUB"), Vector3(x0 + PUERTA_X, 3.15, z_fin + 1.81), 0.0, 40, Color(1, 1, 1))
	## La pared del lado del túnel, con la puerta del pasillo.
	for tr: Vector2 in StadiumBuilder._tramos_sin_hueco(x0, ancho + 0.6, x0 - MEDIO, x0 + MEDIO):
		_caja(nodo, Vector3(tr.x, alto / 2.0, z_out + 0.15), Vector3(tr.y, alto, 0.3), horm, true)
	## Pintura de dentro (una piel fina sobre los muros).
	for lado in [-1.0, 1.0]:
		_caja(nodo, Vector3(x0 + lado * (VEST_MEDIO - 0.02), alto / 2.0, zc), Vector3(0.04, alto, VEST_FONDO), pared, false)
	_caja(nodo, Vector3(x0, alto / 2.0, z_fin - 0.02), Vector3(ancho, alto, 0.04), pared, false)

	## Taquillas con las camisetas a lo largo de las dos paredes largas, con
	## su banco delante. El número y el color son los del club.
	var madera := _mat(Color(0.55, 0.38, 0.22), 0.7)
	var taquilla := _mat(Color(0.62, 0.48, 0.32).lerp(c1, 0.15), 0.6)
	var camiseta := _mat(c1, 0.8)
	var dorsal := 1
	for lado in [-1.0, 1.0]:
		var x_t: float = x0 + lado * (VEST_MEDIO - 0.45)
		var z_t := z_out + 1.6
		while z_t < z_fin - 3.4:
			_caja(nodo, Vector3(x_t, 1.25, z_t), Vector3(0.8, 2.5, 0.95), taquilla, true)
			## La camiseta colgada, mirando al centro del vestuario.
			_caja(nodo, Vector3(x_t - lado * 0.43, 1.55, z_t), Vector3(0.06, 0.8, 0.62), camiseta, false)
			## Con la plantilla a mano (estadio 2.0), el dorsal y el nombre de
			## cada jugador; si no, solo el número.
			## Solo en el estadio propio (en la ciudad `mi` es null y es el tuyo).
			var plantilla: Array = EdificioClub.ctx.get("plantilla", []) if (mi == null or mi.id == PersonajeDT.club_usuario) else []
			var txt := str(dorsal)
			var t_tam := 40
			if dorsal - 1 < plantilla.size():
				var fila: Array = plantilla[dorsal - 1]
				txt = "%d\n%s" % [int(fila[0]), String(fila[1])]
				t_tam = 24
			_rotulo(nodo, txt, Vector3(x_t - lado * 0.47, 1.6, z_t), -lado * PI / 2.0, t_tam, c2)
			dorsal += 1
			z_t += 1.05
		_caja(nodo, Vector3(x0 + lado * (VEST_MEDIO - 1.25), 0.45, (z_out + z_fin - 3.0) / 2.0),
			Vector3(0.45, 0.08, VEST_FONDO - 5.0), madera, true)
	## La pizarra táctica al fondo, con el dibujo de la jugada.
	var pizarra := _mat(Color(0.95, 0.96, 0.97), 0.3)
	_caja(nodo, Vector3(x0, 1.7, z_fin - 0.1), Vector3(3.2, 1.6, 0.06), pizarra, false)
	_rotulo(nodo, "4-3-3\n○ → ✕", Vector3(x0, 1.75, z_fin - 0.15), PI, 46, Color(0.15, 0.2, 0.5))
	## La camilla del fisio y las duchas (alicatado y alcachofas) en una esquina.
	_caja(nodo, Vector3(x0 + 3.0, 0.75, z_fin - 4.6), Vector3(0.8, 0.12, 2.0), _mat(Color(0.2, 0.35, 0.55), 0.6), true)
	_caja(nodo, Vector3(x0 + 3.0, 0.35, z_fin - 4.6), Vector3(0.6, 0.7, 1.6), Texturas.metal(Color(0.6, 0.62, 0.64), 0.5), false)
	var azulejo := _mat(Color(0.82, 0.9, 0.93), 0.25)
	## Las duchas, en la pared del lado de la camilla (la otra tiene la puerta).
	_caja(nodo, Vector3(x0 - VEST_MEDIO + 0.06, alto / 2.0, z_fin - 1.7), Vector3(0.06, alto, 2.8), azulejo, false)
	for k in 2:
		_caja(nodo, Vector3(x0 - VEST_MEDIO + 0.3, 2.2, z_fin - 1.0 - float(k) * 1.3), Vector3(0.3, 0.06, 0.18),
			Texturas.metal(Color(0.8, 0.8, 0.82), 0.3), false)
	## Banco central con la bolsa de cada uno.
	_caja(nodo, Vector3(x0, 0.45, zc - 0.5), Vector3(1.2, 0.08, 4.0), madera, true)
	## Luces del techo y una de relleno cálida.
	for zz in [z_out + 2.5, zc, z_fin - 2.5]:
		_caja(nodo, Vector3(x0, alto - 0.05, zz), Vector3(3.0, 0.05, 0.5), luz, false)
		var o := OmniLight3D.new()
		o.position = Vector3(x0, alto - 0.5, zz)
		o.omni_range = 13.0
		o.light_energy = 1.6
		nodo.add_child(o)
	## Luz de pared a los dos lados: si no, las taquillas quedan en sombra.
	for lado in [-1.0, 1.0]:
		var ol := OmniLight3D.new()
		ol.position = Vector3(x0 + lado * (VEST_MEDIO - 2.2), alto - 0.4, zc)
		ol.omni_range = 7.5
		ol.light_energy = 1.1
		ol.light_color = Color(1, 0.95, 0.86)
		nodo.add_child(ol)
	## Fuera, sobre la fachada que da a la calle: el letrero.
	_rotulo(nodo, Idiomas.t("VESTUARIOS") + " · " + nombre.to_upper(), Vector3(x0, alto - 0.6, z_fin + 0.32), 0.0, 60, Color(1, 1, 1))
	## Y dentro, sobre la puerta del túnel, lo que se lee al salir.
	_rotulo(nodo, Idiomas.t("¡A POR ELLOS!"), Vector3(x0, alto - 0.5, z_out + 0.33), 0.0, 50, c1.lerp(Color.WHITE, 0.2))

## Una caja con material y, si `solida`, con colisión.
static func _caja(padre: Node3D, pos: Vector3, tam: Vector3, mat: Material, solida: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	padre.add_child(mi)
	if solida:
		var cuerpo := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = tam
		forma.shape = bs
		cuerpo.add_child(forma)
		cuerpo.position = pos
		padre.add_child(cuerpo)
	return mi

static func _mat(c: Color, rugosidad: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rugosidad
	return m

## Texto en 3D. `giro`: rotación en Y (0 = mira a +Z).
static func _rotulo(padre: Node3D, texto: String, pos: Vector3, giro: float, tam: int, col: Color) -> void:
	var l := Label3D.new()
	l.text = texto
	l.font_size = tam
	l.pixel_size = 0.006
	l.modulate = col
	l.outline_size = 6
	l.outline_modulate = Color(0, 0, 0, 0.6)
	l.position = pos
	l.rotation.y = giro
	l.double_sided = false
	l.shaded = false
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	padre.add_child(l)

## Un cuadro colgado en la pared derecha del pasillo (mirando a -X).
static func _cuadro(padre: Node3D, pos: Vector3, c: Color, texto: String) -> void:
	var marco := _mat(Color(0.12, 0.1, 0.08), 0.5)
	_caja(padre, pos, Vector3(0.05, 1.0, 1.5), marco, false)
	_caja(padre, pos + Vector3(-0.03, 0, 0), Vector3(0.02, 0.84, 1.34), _mat(c.lerp(Color(0.85, 0.82, 0.74), 0.55), 0.8), false)
	if texto != "":
		_rotulo(padre, texto, pos + Vector3(-0.05, 0, 0), -PI / 2.0, 30, Color(0.1, 0.1, 0.12))
