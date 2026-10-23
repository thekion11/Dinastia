class_name VestidorQ
extends "res://visor/vestidor_q_p2.gd"
## (Parte 3 de 3 de `vestidor_q.gd`.)

static func poner_cara(d: Dictionary, datos: Dictionary, piel: Color) -> bool:
	var modelo: Node = d.get("modelo")
	var lk: Variant = datos.get("look")
	if modelo == null or not (lk is Dictionary):
		return false
	var ruta := String(datos.get("foto", ""))
	var foto: Texture2D = Cara.foto_de_ruta(ruta) if ruta != "" else null
	var af := _afin_foto(Cara.puntos_foto(ruta)) if foto != null else []
	var bi := int((lk as Dictionary).get("barba", 0))
	## IGUALITO A LA FOTO (29-9-2026): la foto trae sus propias cejas y su
	## barba; las mallas 3D encima duplicaban cejas y tapaban la barba real.
	## Y la foto se lleva al color de la piel del modelo (balance de blancos y
	## flash de cada fotógrafo): así no se nota dónde termina la foto.
	var tono_foto := Vector3.ONE
	## LA CARA DE VERDAD EN 3D (30-9-2026): si hay malla de su cara, va la
	## malla (forma y píxeles exactos de la foto) en vez de la proyección, y el
	## cuerpo toma el tono EXACTO de su piel en la foto.
	var nombre_foto := Cara.nombre_de_ruta(ruta) if ruta != "" else ""
	## BIBLIOTECA MODULAR (5-10-2026): una cara mezclada y un corte de la
	## biblioteca (jugadores ficticios, creador de personaje) van por el mismo
	## camino que una cara real, con su propio corte y color de pelo.
	var biblio: Variant = datos.get("biblio")
	if foto == null and biblio is Dictionary and CaraMalla.tiene(String((biblio as Dictionary).get("cara", ""))):
		nombre_foto = String(biblio["cara"])
		foto = CaraMalla.foto(nombre_foto)
	var con_malla := false
	if foto != null and CaraMalla.tiene(nombre_foto):
		var cara_hd := CaraMalla.foto(nombre_foto)
		## La piel: la que el segmentador marcó como piel de la cara (sin
		## barba, cejas ni fondo); si no, la media recortada de la malla.
		var medida := CaraMalla.entrada(nombre_foto)
		## Biblioteca sin corte medido (creador: "Ninguno"): el peinado que ya
		## tiene el personaje se respeta tal cual.
		var tocar_pelo := true
		if biblio is Dictionary and String((biblio as Dictionary).get("cara", "")) == nombre_foto \
				and String((biblio as Dictionary).get("pelo", "")) == "":
			tocar_pelo = false
		if biblio is Dictionary and String((biblio as Dictionary).get("cara", "")) == nombre_foto:
			medida = medida.duplicate()
			var hb := BibliotecaCaras.pelo(String(biblio.get("pelo", "")), Color(String(biblio.get("color_pelo", "#2a211b"))))
			if hb.is_empty():
				medida.erase("h")
			else:
				medida["h"] = hb
		var tono := Color(String(medida["s"])) if String(medida.get("s", "")) != "" else CaraMalla.tono_piel(nombre_foto, cara_hd)
		if tono.a > 0.0:
			piel = tono
		if CaraMalla.poner(d, nombre_foto, cara_hd, piel) != null:
			con_malla = true
			_ocultar_cejas_y_barba(d.get("nodo", modelo))
			var pelo_foto := CaraMalla.color_pelo(nombre_foto)
			if not tocar_pelo:
				pass
			elif pelo_foto.a > 0.0:
				_teñir_pelo(d.get("nodo", modelo), pelo_foto)
			## Pelo, barba, cejas y pestañas por capas, medidos en la foto.
			var geo := CaraMalla.geometria(nombre_foto)
			if not tocar_pelo:
				pass
			elif not geo.is_empty() and PeloCapas.poner(d, medida, cara_hd, geo[0], geo[1], geo[2], geo[3]):
				_ocultar_peinado(d.get("nodo", modelo))
			elif medida.get("h") is Dictionary and float(medida["h"].get("largo", 0.0)) >= PeloCapas.LARGO_MELENA:
				## Melena: el peinado largo del pack, del color de su pelo.
				var viejo := (d.get("nodo", modelo) as Node).find_child("Pelo", true, false)
				if viejo != null:
					viejo.get_parent().remove_child(viejo)
					viejo.queue_free()
				## (`PeloQ` aclara su textura x1,7: se le pasa el color ya
				## compensado; si no, un castaño salía gris y un rubio, blanco.)
				var cp := Color(String(medida["h"].get("c", "#2a211b")))
				PeloQ.poner(d, "largo", Color(cp.r / 1.7, cp.g / 1.7, cp.b / 1.7), false)
				_ocultar_cejas_y_barba(d.get("nodo", modelo))
			elif not (medida.get("h") is Dictionary) or bool(medida["h"].get("gorro", false)):
				## Pelo tapado (gorro, gorra) o no visible: corto y oscuro,
				## nunca un peinado inventado.
				var viejo2 := (d.get("nodo", modelo) as Node).find_child("Pelo", true, false)
				if viejo2 != null:
					viejo2.get_parent().remove_child(viejo2)
					viejo2.queue_free()
				PeloQ.poner(d, "corto", Color(0.1, 0.075, 0.06), false)
				_ocultar_cejas_y_barba(d.get("nodo", modelo))
	if foto != null and not con_malla:
		if af.is_empty():
			foto = null
		else:
			_ocultar_cejas_y_barba(d.get("nodo", modelo))
			tono_foto = _ajuste_foto(foto, af, piel)
	## Sin foto usable: los rasgos del retrato.
	var rasgos: Texture2D = null if foto != null else Cara.textura_rasgos(lk)
	var barba: Texture2D = null if foto != null else Cara.textura_barba(lk)
	var iris := Color(String(Cara.IRIS[clampi(int((lk as Dictionary).get("ojos", 0)), 0, Cara.IRIS.size() - 1)]))
	var puesta := false
	for mv in _mallas(modelo):
		var mi: MeshInstance3D = mv
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var orig := mi.mesh.surface_get_material(s)
			var nombre := orig.resource_name if orig != null else ""
			var activo := mi.get_active_material(s)
			if activo is ShaderMaterial and (activo as ShaderMaterial).shader != null \
					and (activo as ShaderMaterial).shader.resource_path == SHADER_EQUIPACION:
				if not bool((activo as ShaderMaterial).get_shader_parameter("usa_reposo")):
					continue
				var clave := "%d|%d|%s|%s" % [activo.get_instance_id(), hash(lk), ruta, con_malla]
				var mc: ShaderMaterial = _cache_cara.get(clave)
				if mc == null:
					mc = (activo as ShaderMaterial).duplicate() as ShaderMaterial
					mc.set_shader_parameter("hay_cara", not con_malla)
					if con_malla:
						mc.set_shader_parameter("hay_malla", true)
						## El cuerpo, del color exacto de su piel en la foto.
						var pl := piel.srgb_to_linear()
						var v := Vector3(pl.r, pl.g, pl.b)
						var gris := v.dot(Vector3(0.2126, 0.7152, 0.0722))
						var e := exposicion_piel(gris)
						## La misma compensación del pie del mapeo de tonos que la cara.
						var gg := maxf(gris, 0.0001)
						var cp := compensar_piel(gris)
						v = Vector3(pow(v.x / gg, 1.0 / cp), pow(v.y / gg, 1.0 / cp),
							pow(v.z / gg, 1.0 / cp)) * gg
						mc.set_shader_parameter("piel_foto", v * e)
					elif foto != null:
						mc.set_shader_parameter("hay_foto", true)
						mc.set_shader_parameter("foto_tex", foto)
						mc.set_shader_parameter("foto_u", af[0])
						mc.set_shader_parameter("foto_v", af[1])
						mc.set_shader_parameter("foto_tono", tono_foto)
						mc.set_shader_parameter("foto_espejo", _lado_foto(Cara.puntos_foto(ruta)))
					else:
						mc.set_shader_parameter("cara_tex", rasgos)
						if barba != null:
							mc.set_shader_parameter("barba_tex", barba)
							mc.set_shader_parameter("barba_color", Color(String((lk as Dictionary).get("peloC", "#231a14"))))
							## Bajo la barba 3D (1, 4 y 6) solo una sombra de pelo.
							mc.set_shader_parameter("barba_fuerza", 0.55 if bi in [1, 4, 6] else 0.95)
					_cache_cara[clave] = mc
				mi.set_surface_override_material(s, mc)
				puesta = true
			elif nombre == MATERIAL_OJOS and ResourceLoader.exists(SHADER_OJOS):
				_con_reposo_simple(mi)
				## OJOS SOLO DE CERCA (19-10-2026): a más de `DIST_OJOS` m un ojo
				## mide como mucho 1,4 píxeles (zoom máximo de la transmisión) y
				## costaba una llamada de dibujo por jugador: −43 en el partido.
				PeloQ.sin_lejos(mi, DIST_OJOS)
				if s >= mi.get_surface_override_material_count():
					continue
				## Con cara real: el iris medido en su foto, y los párpados los
				## pone la malla de la cara (el globo, bien abierto).
				if con_malla and CaraMalla.color_iris(nombre_foto).a > 0.0:
					iris = CaraMalla.color_iris(nombre_foto)
					## Un poco menos de color y de brillo: bajo la luz del
					## juego los castaños se veían naranjas y los azules, neón.
					var gris := iris.get_luminance()
					iris = iris.lerp(Color(gris, gris, gris), 0.35).darkened(0.12)
				var clave_o := "ojos|%s|%s|%s|%s|%s" % [iris.to_html(false), _piel_cuantizada(piel), ruta, con_malla, nombre_foto]
				var mo: ShaderMaterial = _cache_cara.get(clave_o)
				if mo == null:
					mo = ShaderMaterial.new()
					mo.shader = load(SHADER_OJOS)
					mo.set_shader_parameter("iris", iris)
					mo.set_shader_parameter("piel", piel)
					if con_malla:
						## Los párpados los pone su malla; el iris, centrado en SU
						## abertura (si no, parecía bizco). Algo de sombra arriba
						## (apertura) para que el blanco no brille.
						mo.set_shader_parameter("sin_parpados", true)
						mo.set_shader_parameter("apertura", 0.9)
						mo.set_shader_parameter("blanco", 0.72)
						var co := CaraMalla.centros_ojos(nombre_foto)
						if co.size() == 2:
							mo.set_shader_parameter("centro_neg", co[0])
							mo.set_shader_parameter("centro_pos", co[1])
					elif foto != null:
						mo.set_shader_parameter("apertura", 0.78)
						mo.set_shader_parameter("blanco", 0.82)
					_cache_cara[clave_o] = mo
				mi.set_surface_override_material(s, mo)
	return puesta
