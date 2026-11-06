extends "res://pruebas/banco/estadio_p1.gd"
## [Capa extra de `estadio.gd`] _probar_fundir_r2

## R2 (3-11): `FundirPiezas.fundir_sueltas` y `fundir_profundo(..., por_firma)` (la grada y el túnel en MÍNIMO).
func _probar_fundir_r2() -> void:
	_titulo("FUNDIR PIEZAS: SUELTAS Y POR FIRMA (R2)")
	## R2 (3-11, MÍNIMO): las piezas SUELTAS sin nombre (cajas, cilindros, placas) en una superficie por material y sombra; lo que tiene nombre, meta o grupo se queda.
	var r2 := Node3D.new()
	add_child(r2)
	var verde := StandardMaterial3D.new()
	var gris := StandardMaterial3D.new()
	gris.albedo_color = Color(0.4, 0.4, 0.4)
	for i in 6:
		var s := MeshInstance3D.new()
		if i % 2 == 0:
			s.mesh = BoxMesh.new()
		else:
			var cil := CylinderMesh.new()
			cil.radial_segments = 8
			cil.rings = 1
			s.mesh = cil
		s.material_override = verde if i < 4 else gris
		s.position = Vector3(i, 0, 0)
		r2.add_child(s)
	var con_nombre := MeshInstance3D.new()
	con_nombre.name = "Bandera"
	con_nombre.mesh = BoxMesh.new()
	con_nombre.material_override = verde
	r2.add_child(con_nombre)
	var con_meta := MeshInstance3D.new()
	con_meta.mesh = BoxMesh.new()
	con_meta.material_override = verde
	con_meta.set_meta("cuerpo", true)
	r2.add_child(con_meta)
	_comprobar(FundirPiezas.fundir_sueltas(r2) == 6, "R2: funde las 6 piezas sueltas sin nombre")
	var fund: MeshInstance3D = r2.get_node("SueltasFundidas")
	_comprobar(fund.mesh.get_surface_count() == 2 and fund.mesh.surface_get_material(0) == verde and fund.mesh.surface_get_material(1) == gris, "R2: una superficie por material, los mismos materiales")
	_comprobar(is_instance_valid(con_nombre) and con_nombre.get_parent() == r2 and is_instance_valid(con_meta) and con_meta.get_parent() == r2, "R2: la pieza con nombre y la que lleva meta se quedan")
	r2.queue_free()
	## Materiales distintos pero iguales en lo que se ve comparten superficie (`por_firma`); si cambia el color, no.
	var r3 := Node3D.new()
	add_child(r3)
	var colores := [Color.RED, Color.RED, Color.BLUE]
	for i in 3:
		var mi := MeshInstance3D.new()
		mi.mesh = BoxMesh.new()
		var mt := StandardMaterial3D.new()
		mt.albedo_color = colores[i]
		mi.material_override = mt
		r3.add_child(mi)
	_comprobar(FundirPiezas._firma_material(StandardMaterial3D.new()) == FundirPiezas._firma_material(StandardMaterial3D.new()), "R2: dos materiales iguales tienen la misma firma")
	FundirPiezas.fundir_profundo(r3, "Fundido", [], true)
	_comprobar((r3.get_node("Fundido") as MeshInstance3D).mesh.get_surface_count() == 2, "R2: 3 materiales (2 iguales) → 2 superficies con `por_firma`")
	r3.queue_free()

## (7-11) `Optimizar.celdas_de` (por tramos del buffer) da lo MISMO que repartir instancia a instancia: mismas celdas, mismo orden y los mismos datos. El formato del buffer (origen en
## 3, 7 y 11; color y datos detrás) se comprobó con renderizador real: en modo sin pantalla un MultiMesh no guarda datos, por eso aquí se arma el buffer a mano.
func _probar_celdas_agrupado() -> void:
	_titulo("TROCEAR AGRUPADOS POR TRAMOS DEL BUFFER: IGUAL QUE INSTANCIA A INSTANCIA")
	for ordenado: bool in [false, true]:
		var paso := 20
		var n := 600
		var buf := PackedFloat32Array()
		buf.resize(n * paso)
		var rg := RandomNumberGenerator.new()
		rg.seed = 7
		for i in n:
			for q in paso:
				buf[i * paso + q] = rg.randf()   # datos distintos en todas las posiciones
			buf[i * paso + 3] = (float(i) / float(n) * 800.0 - 400.0) if ordenado else rg.randf_range(-400.0, 400.0)
			buf[i * paso + 7] = rg.randf_range(0.0, 5.0)
			buf[i * paso + 11] = rg.randf_range(-400.0, 400.0)
		var gt := Transform3D(Basis.from_euler(Vector3(0, 0.7, 0)), Vector3(30.0, 0.0, -20.0))
		var nuevo := Optimizar.celdas_de(gt, buf, paso, 100.0)
		var ref := {}
		for i in n:
			var o := gt * Vector3(buf[i * paso + 3], buf[i * paso + 7], buf[i * paso + 11])
			var kk := Vector2i(floori(o.x / 100.0), floori(o.z / 100.0))
			if not ref.has(kk):
				ref[kk] = []
			(ref[kk] as Array).append(i)
		var iguales := nuevo.size() == ref.size()
		for kk: Vector2i in ref:
			if not nuevo.has(kk):
				iguales = false
				continue
			var esperado := PackedFloat32Array()
			for i: int in ref[kk]:
				esperado.append_array(buf.slice(i * paso, (i + 1) * paso))
			iguales = iguales and (nuevo[kk] as Array)[1] == esperado and int((nuevo[kk] as Array)[0]) * paso == esperado.size()
		_comprobar(iguales and ref.size() > 20, "partir un agrupado por tramos del buffer da lo mismo que instancia a instancia (%s, %d celdas)" % ["ordenado" if ordenado else "aleatorio", ref.size()])

## (7-11) El paseo a pie en ULTRA BAJA y BAJA: la niebla de profundidad y la animación que se pausa detrás de la cámara.
func _probar_paseo_optimizado() -> void:
	_titulo("PASEO A PIE OPTIMIZADO: NIEBLA Y ANIMACIÓN DETRÁS DE LA CÁMARA")
	## (7-11) En ULTRA BAJA la gente del club se dibuja solo a menos de 90 m (desde el mapa aéreo eran 163 piezas invisibles); en ALTA, sin tope.
	var nivel0 := Calidad.elegida
	var dd := TunelVestuario.datos({"forma": "cuenco"}, 2)
	var con_tope: Array[int] = []
	for nivel: int in [Calidad.ULTRA_BAJA, Calidad.ALTA]:
		Calidad.elegida = nivel
		var pe := PersonalEstadio.new()
		pe.preparar(dd, Color.RED, Color.WHITE)
		add_child(pe)
		var n_tope := 0
		for g: Node in pe.find_children("*", "GeometryInstance3D", true, false):
			if is_equal_approx((g as GeometryInstance3D).visibility_range_end, 90.0):
				n_tope += 1
		con_tope.append(n_tope)
		pe.free()
	Calidad.elegida = nivel0
	_comprobar(con_tope[0] > 20 and con_tope[1] == 0, "la gente del club tiene tope de 90 m en ULTRA BAJA (%d piezas) y no en ALTA (%d)" % [con_tope[0], con_tope[1]])
	## (7-11) Niebla de profundidad del paseo a pie: se pone (del 43 % al 100 % del alcance a pie) y al salir deja el entorno como estaba.
	var nn := Node3D.new()
	add_child(nn)
	var ent := Environment.new()
	ent.fog_enabled = false
	var mundo := nn.get_world_3d()
	var ent0: Environment = mundo.environment
	mundo.environment = ent
	OptimizarGrada.niebla_a_pie(nn, true)
	var puesta := ent.fog_enabled and ent.fog_mode == Environment.FOG_MODE_DEPTH and is_equal_approx(ent.fog_depth_end, OptimizarGrada.alcance_a_pie())
	OptimizarGrada.niebla_a_pie(nn, false)
	_comprobar(puesta and not ent.fog_enabled and ent.fog_mode == Environment.FOG_MODE_EXPONENTIAL, "la niebla del paseo a pie se pone según el alcance a pie de la calidad y al salir el entorno queda como estaba")
	mundo.environment = ent0
	nn.free()
	## (7-11) Un peatón detrás de la cámara (a más de 3 m) no anima; delante, o pegado, sí.
	var mira_ := Vector3(0, 0, -1)
	_comprobar(not TraficoCiudad.detras(Vector3.ZERO, mira_, Vector3(0, 0, -10)) and TraficoCiudad.detras(Vector3.ZERO, mira_, Vector3(0, 0, 10)) and not TraficoCiudad.detras(Vector3.ZERO, mira_, Vector3(0, 0, 2)),
		"un peatón detrás de la cámara no anima; delante o pegado a ella, sí")

## (7-11) Alcance de los rótulos 3D según su tamaño: el del personal (6 cm) a ~17 m, el letrero de la fachada (1,5 m) a 90 m, y no se toca el que ya trae un tope menor.
func _probar_rotulos_cercanos() -> void:
	_titulo("RÓTULOS 3D: ALCANCE SEGÚN EL TAMAÑO DEL TEXTO")
	var raiz := Node3D.new()
	var pequeno := Label3D.new()
	pequeno.font_size = 26
	pequeno.pixel_size = 0.0022
	var grande := Label3D.new()
	grande.font_size = 160
	grande.pixel_size = 0.01
	var corto := Label3D.new()
	corto.font_size = 160
	corto.pixel_size = 0.01
	corto.visibility_range_end = 14.0
	for l: Label3D in [pequeno, grande, corto]:
		raiz.add_child(l)
	var n := OptimizarGrada.rotulos_cercanos(raiz)
	_comprobar(n == 2 and pequeno.visibility_range_end > 15.0 and pequeno.visibility_range_end < 20.0 and is_equal_approx(grande.visibility_range_end, 90.0) and is_equal_approx(corto.visibility_range_end, 14.0),
		"el rótulo pequeño alcanza ~17 m, el grande 90 m y el que ya traía un tope menor se queda (%d tocados)" % n)
	raiz.free()


## (7-11) `Optimizar.a_buffer` da el mismo `buffer` que `inv * t` instancia a instancia: se reconstruye la transformación desde las filas de 12 floats.
func _probar_a_buffer() -> void:
	_titulo("AGRUPAR: BUFFER DE TRANSFORMACIONES")
	var ts: Array = [Transform3D(Basis(Vector3(0.3, 1.1, -0.4), 0.9).scaled(Vector3(1.5, 0.8, 2.0)), Vector3(10.0, -2.0, 33.5)), Transform3D(Basis.IDENTITY, Vector3(-4.0, 0.5, 7.0))]
	var inv := Transform3D(Basis(Vector3.UP, 0.5), Vector3(100.0, 3.0, -50.0)).affine_inverse()
	var b := Optimizar.a_buffer(ts, inv)
	var bien := b.size() == 24
	for i in ts.size():
		var esperado: Transform3D = inv * (ts[i] as Transform3D)
		var o := i * 12
		var r := Transform3D(Basis(Vector3(b[o], b[o + 4], b[o + 8]), Vector3(b[o + 1], b[o + 5], b[o + 9]), Vector3(b[o + 2], b[o + 6], b[o + 10])), Vector3(b[o + 3], b[o + 7], b[o + 11]))
		bien = bien and r.is_equal_approx(esperado)
	_comprobar(bien, "a_buffer reproduce `inv * t` de cada instancia (filas 3x4, origen en 3, 7 y 11)")

## (7-11) El pasto del Drive se dibuja a 28 m en ULTRA BAJA/BAJA y a 42 m desde MEDIA BAJA.
func _probar_pasto_distancia() -> void:
	_titulo("PASTO DEL DRIVE: DISTANCIA SEGÚN CALIDAD")
	var antes := Calidad.elegida
	Calidad.elegida = Calidad.ULTRA_BAJA
	var a := PastoCiudad.distancia()
	Calidad.elegida = Calidad.BAJA
	var b := PastoCiudad.distancia()
	Calidad.elegida = Calidad.MEDIA_BAJA
	var c := PastoCiudad.distancia()
	Calidad.elegida = antes
	_comprobar(is_equal_approx(a, 28.0) and is_equal_approx(b, 28.0) and is_equal_approx(c, 42.0), "distancia del pasto: ULTRA BAJA 28, BAJA 28, MEDIA BAJA 42 (%.0f, %.0f, %.0f)" % [a, b, c])

## (7-11) Caras reales: la caché guarda los bytes ya decodificados (no el texto base64) y `_datos` los lee igual.
func _probar_cara_bytes() -> void:
	_titulo("CARAS REALES: CACHÉ EN BYTES")
	CaraMalla._cargar()
	var clave := ""
	for k: String in CaraMalla._mallas:
		var e: Variant = CaraMalla._mallas[k]
		if e is Dictionary and (e as Dictionary).get("m") is PackedByteArray:
			clave = k
			break
	if clave == "":
		_comprobar(true, "sin caras reales en este contenedor (nada que comprobar)")
		return
	var d := CaraMalla._datos(clave)
	_comprobar(d.size() >= 2 and (d[0] as PackedVector3Array).size() == CaraMalla._n, "la cara «%s» sale de la caché en bytes con %d vértices" % [clave, CaraMalla._n])

## (7-11) `Banca` (script mínimo, lo usa el menú) da la misma lista que `VistaEstadio.disponibles_fuera_del_once`: sin lesionados ni sancionados, por media de mayor a menor.
func _probar_banca_ligera() -> void:
	_titulo("BANCA: SCRIPT MÍNIMO")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var c: Club = m.ligas[0].clubes[0]
	c.plantilla[0].lesion = 3
	var once: Array = c.once()
	var a := Banca.disponibles_fuera_del_once(c, once)
	var b := VistaEstadio.disponibles_fuera_del_once(c, once)
	var orden := true
	for i in range(1, a.size()):
		orden = orden and (a[i - 1] as Jugador).ovr >= (a[i] as Jugador).ovr
	_comprobar(a.size() > 5 and a == b and orden and not a.has(c.plantilla[0]) and not once.any(func(j): return a.has(j)), "la banca sale igual (%d jugadores), ordenada y sin lesionados ni titulares" % a.size())

## (7-11) `Optimizar.fundir_pequenas`: los trozos con pocas instancias se juntan por celdas más grandes sin perder ni duplicar instancias; los grandes se quedan igual.
func _probar_fundir_pequenas() -> void:
	_titulo("TROCEO: TROZOS PEQUEÑOS FUNDIDOS")
	var por := {}
	var total := 0
	for i in 12:
		var buf := PackedFloat32Array()
		var n := 3 + i
		buf.resize(n * 12)
		for q in buf.size():
			buf[q] = float(i * 1000 + q)
		por[Vector2i(i % 4, i / 4)] = [n, buf]
		total += n
	var grande := PackedFloat32Array()
	grande.resize(Optimizar.MIN_TROZO * 12)
	por[Vector2i(40, 40)] = [Optimizar.MIN_TROZO, grande]
	total += Optimizar.MIN_TROZO
	var f := Optimizar.fundir_pequenas(por)
	var cuenta := 0
	var coherente := true
	for k: Vector2i in f:
		var v: Array = f[k]
		cuenta += int(v[0])
		coherente = coherente and (v[1] as PackedFloat32Array).size() == int(v[0]) * 12
	_comprobar(cuenta == total and coherente and f.size() == 2 and f.has(Vector2i(40, 40)), "12 trozos pequeños → 1 junto, el grande intacto, mismas instancias (%d de %d, %d trozos)" % [cuenta, total, f.size()])

## (7-11) El precalentado del menú (caras y animaciones) solo corre desde MEDIA BAJA hacia arriba; en ULTRA BAJA y BAJA se apaga (RAM).
func _probar_precalentado_por_calidad() -> void:
	_titulo("PRECALENTADO DEL MENÚ SEGÚN LA CALIDAD")
	var antes := Calidad.elegida
	var r := []
	for q in [Calidad.ULTRA_BAJA, Calidad.BAJA, Calidad.MEDIA_BAJA, Calidad.MEDIA, Calidad.ALTA]:
		Calidad.elegida = q
		r.append(PrecalentarAnim.permitido())
	Calidad.elegida = antes
	_comprobar(str(r) == str([false, false, true, true, true]), "permitido: ULTRA BAJA no, BAJA no, MEDIA BAJA sí, MEDIA sí, ALTA sí (%s)" % str(r))

## (7-11) `FundirPiezas.fundir_ciudad`: las primitivas sueltas con el mismo material y celda se funden en una malla, las solas, con escala desigual o con nombre propio se quedan, y la geometría no se mueve.
func _probar_fundir_ciudad() -> void:
	_titulo("FUNDIR LA CIUDAD: PRIMITIVAS POR MATERIAL Y CELDA")
	var raiz := Node3D.new()
	add_child(raiz)
	var rojo := StandardMaterial3D.new()
	rojo.albedo_color = Color.RED
	var azul := StandardMaterial3D.new()
	azul.albedo_color = Color.BLUE
	var aabb_antes := AABB()
	for i in 5:
		var mi := MeshInstance3D.new()   ## (nombre automático «@MeshInstance3D@N»: nadie la busca)
		mi.mesh = BoxMesh.new()
		mi.material_override = rojo
		raiz.add_child(mi)
		mi.position = Vector3(i * 3.0, 0.5, 2.0)
		aabb_antes = aabb_antes.merge(mi.global_transform * mi.get_aabb()) if i > 0 else mi.global_transform * mi.get_aabb()
	var lejos := MeshInstance3D.new()
	lejos.mesh = BoxMesh.new()
	lejos.material_override = rojo
	raiz.add_child(lejos)
	lejos.position = Vector3(900.0, 0.5, 900.0)
	var otra := MeshInstance3D.new()
	otra.mesh = CylinderMesh.new()
	(otra.mesh as CylinderMesh).radial_segments = 8   ## (las de la ciudad ya vienen rebajadas por `Optimizar.primitivas`)
	(otra.mesh as CylinderMesh).rings = 1
	otra.material_override = azul
	raiz.add_child(otra)
	var otra2 := MeshInstance3D.new()
	otra2.mesh = CylinderMesh.new()
	(otra2.mesh as CylinderMesh).radial_segments = 8
	(otra2.mesh as CylinderMesh).rings = 1
	otra2.material_override = azul
	raiz.add_child(otra2)
	otra2.position = Vector3(1.0, 0, 0)
	var estirada := MeshInstance3D.new()
	estirada.mesh = BoxMesh.new()
	estirada.material_override = rojo
	raiz.add_child(estirada)
	estirada.scale = Vector3(1, 3, 1)
	var elegida := MeshInstance3D.new()
	elegida.name = "Banco"
	elegida.mesh = BoxMesh.new()
	elegida.material_override = rojo
	raiz.add_child(elegida)
	var n := FundirPiezas.fundir_ciudad(raiz, 80.0)
	var fund: Array = raiz.find_children("FundidoCiudad*", "MeshInstance3D", true, false)
	var union := AABB()
	var primero := true
	for f in fund:
		var caja: AABB = (f as MeshInstance3D).mesh.get_aabb()
		union = caja if primero else union.merge(caja)
		primero = false
	_comprobar(n == 7 and fund.size() == 2 and raiz.get_child_count() == 5, "7 piezas → 2 mallas (5 cajas rojas, 2 cilindros azules); quedan la lejana, la estirada y la «Banco» (%d fundidas, %d mallas, %d hijos)" % [n, fund.size(), raiz.get_child_count()])
	_comprobar(union.encloses(aabb_antes.grow(-0.01)) or absf(union.size.x - aabb_antes.size.x) < 0.5, "la geometría fundida ocupa el mismo sitio que las cajas originales")
	raiz.queue_free()

## (7-11) `SubsistemasQuietos`: bajo un subsistema registrado todo es quieto salvo lo que cuelga de sus nodos móviles; si no está registrado, nada lo es.
func _probar_subsistemas_quietos() -> void:
	_titulo("SUBSISTEMAS CON SCRIPT CUYA GEOMETRÍA ES QUIETA")
	var sub := Node3D.new()
	var tren := Node3D.new()
	var parte_tren := MeshInstance3D.new()
	var andén := MeshInstance3D.new()
	sub.add_child(tren)
	tren.add_child(parte_tren)
	sub.add_child(andén)
	var sin_registro := SubsistemasQuietos.permite(sub, andén)
	SubsistemasQuietos.estaticos[sub] = {tren: true}
	var quieto := SubsistemasQuietos.permite(sub, andén)
	var movil := SubsistemasQuietos.permite(sub, parte_tren)
	SubsistemasQuietos.limpiar()
	_comprobar(not sin_registro and quieto and not movil and SubsistemasQuietos.estaticos.is_empty(), "sin registro nada es quieto; registrado, el andén sí y la pieza del tren no; limpiar vacía el registro")
	sub.free()
