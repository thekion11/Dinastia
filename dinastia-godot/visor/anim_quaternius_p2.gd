extends "res://visor/anim_quaternius_p1.gd"
## [Capa 2/3 de `anim_quaternius.gd`] cargar_futbol, _nueva, _huesos_rigidos, _limitar_rodillas, _bakear_futbol_global, cargar_futbol_global … (+9)

## Carga el clip `archivo` (nombre del .fbx SIN extension, p.ej.
## "08_Side_Foot_Kick_ue5") y lo RETARGETEA -de verdad, no solo reapuntando la
## ruta- a `esq`/`prefijo`. `bucle` en false por defecto -son golpes/gestos de
## una vez, no ciclos de locomocion-. Devuelve null si el archivo no existe,
## mismo criterio que `cargar_real()`: quien llama decide si cae a la version
## a mano.
##
## POR QUE HACE FALTA RETARGETING DE VERDAD Y NO ALCANZA CON REAPUNTAR LA
## RUTA (que es lo que hace `cargar_real()` con la libreria de Quaternius):
## ese pack es del MISMO creador/pipeline que `FutbolistaQ`, con el reposo de
## cada hueso garantizado igual -copiar la rotacion absoluta tal cual
## funciona-. Este pack es de un esqueleto "UE5 Manny" genuino de un pipeline
## DISTINTO (Rokoko/Anderson Rohr): mismos NOMBRES de hueso, pero el reposo
## -la orientacion "cero" de cada hueso- no es necesariamente el mismo. Copiar
## la rotacion ABSOLUTA de un hueso tal cual, sin contemplar que su "cero" no
## es el mismo que el nuestro, es exactamente lo que producia el jugador
## flotando y retorcido en el primer intento (confirmado con captura real,
## `futbol_real_patear_*.png`, y descartado un simple desfase de altura con
## `pruebas/diagnostico_offset_pelvis.gd`: el reposo de la pelvis casi
## coincide, el problema estaba en las rotaciones, no en la posicion).
##
## El arreglo, mismo principio que ya usa `_pista()` en todo este fichero
## -las claves son un DESVIO sobre el reposo, no un valor absoluto-, aplicado
## en sentido inverso: para cada fotograma, `desvio = reposo_origen.inverse()
## * valor_absoluto_del_clip` -que rotacion representa ESTE fotograma
## relativa al cero de SU esqueleto-, y despues `nuevo = reposo_nuestro *
## desvio` -esa misma rotacion relativa, aplicada sobre NUESTRO cero-.
##
## ESE REBASE POR SI SOLO NO ALCANZABA: con el de arriba ya puesto, el
## jugador dejaba de flotar (la POSICION quedaba bien) pero seguia tumbado
## boca abajo en el piso en las 5 animaciones probadas, incluida una
## (`mostrar_tarjeta`) que no tiene ningun motivo para tocar el suelo -senal
## de un desfase SISTEMICO, no del contenido de cada clip-. Comparando el
## reposo de `root` en los dos esqueletos con `pruebas/diagnostico_offset_
## pelvis.gd` (real, no supuesto) se encontro la causa: el fotograma t=0 de
## la pista de `root` en el clip de origen (-90 en X) NO coincide con lo que
## `get_bone_rest()` reporta como su propio reposo (0 en X) -mientras que
## `pelvis` para abajo si coincide con su reposo-. Osea `root` recibe algun
## tratamiento de importacion FBX distinto al resto de la jerarquia, y
## retargetearlo como a cualquier otro hueso introduce ahi un giro que se
## arrastra a toda la cadena que cuelga de el. Arreglo confirmado con
## captura real: DESCARTAR la pista de rotacion de `root` por completo -que
## mande siempre nuestro propio reposo- deja al resto de la jerarquia
## (pelvis, columna, piernas, brazos) perfectamente de pie en 4 de los 5
## clips probados. El quinto (`celebrar`, `12_Goal_Celebration_01`) seguia
## mal -muy probablemente porque ESE clip especifico es una voltereta real de
## festejo, que si necesita que `root` rote de verdad-: se cambio a la
## variante `13_Goal_Celebration_02` en vez de forzar ese caso, verificado
## tambien con captura real (salto con el brazo en alto, de pie).
static func cargar_futbol(archivo: String, esq: Skeleton3D, prefijo: String, bucle: bool = false) -> Animation:
	var datos := _cargar_clip_futbol(archivo)
	var original: Animation = datos["anim"]
	if original == null:
		return null
	var reposo_origen: Dictionary = datos["reposo"]
	var copia: Animation = original.duplicate(true)
	copia.loop_mode = Animation.LOOP_LINEAR if bucle else Animation.LOOP_NONE
	var eliminar: Array[int] = []
	for i in copia.get_track_count():
		var ruta := str(copia.track_get_path(i))
		var hueso_origen := ruta.substr(ruta.rfind(":") + 1)
		var hueso: String = MAPA_HUESO_FUTBOL.get(hueso_origen, hueso_origen)
		var i_nuestro := esq.find_bone(hueso)
		## "root" se descarta a proposito -confirmado con captura real, ver el
		## comentario largo encima de esta funcion-: su reposo de importacion
		## no calza entre los dos esqueletos, y retargetearlo como a cualquier
		## otro hueso tumbaba al jugador. Con esto descartado, manda siempre
		## NUESTRO propio reposo de root y el resto de la jerarquia queda bien.
		if hueso == "root" or i_nuestro < 0 or not reposo_origen.has(hueso_origen):
			eliminar.append(i)
			continue
		copia.track_set_path(i, NodePath("%s:%s" % [prefijo, hueso]))
		var rp_origen: Dictionary = reposo_origen[hueso_origen]
		var t_nuestro := esq.get_bone_rest(i_nuestro)
		if copia.track_get_type(i) == Animation.TYPE_ROTATION_3D:
			var rot_reposo_origen: Quaternion = rp_origen["rot"]
			var rot_reposo_nuestro := t_nuestro.basis.get_rotation_quaternion()
			for k in copia.track_get_key_count(i):
				var tt := copia.track_get_key_time(i, k)
				var abs_origen: Quaternion = copia.track_get_key_value(i, k)
				var desvio := rot_reposo_origen.inverse() * abs_origen
				copia.rotation_track_insert_key(i, tt, rot_reposo_nuestro * desvio)
		elif copia.track_get_type(i) == Animation.TYPE_POSITION_3D:
			var pos_reposo_origen: Vector3 = rp_origen["pos"]
			var pos_reposo_nuestro := t_nuestro.origin
			for k in copia.track_get_key_count(i):
				var tt := copia.track_get_key_time(i, k)
				var abs_origen: Vector3 = copia.track_get_key_value(i, k)
				var desvio := abs_origen - pos_reposo_origen
				copia.position_track_insert_key(i, tt, pos_reposo_nuestro + desvio)
	eliminar.reverse()
	for i in eliminar:
		copia.remove_track(i)
	return copia

static func _nueva(dur: float, bucle: bool) -> Animation:
	var a := Animation.new()
	a.length = dur
	a.loop_mode = Animation.LOOP_LINEAR if bucle else Animation.LOOP_NONE
	return a

## HUESOS RÍGIDOS (25-9-2026). El retarget global copia la pose GLOBAL de cada
## hueso del actor, posición incluida, y el actor tiene otras proporciones: en
## el festejo de rodillas la rodilla quedaba 14 cm fuera de la punta del muslo.
## Es decir, en todo el mocap los miembros se estiraban y encogían, cosa que un
## hueso de verdad no hace. Se devuelve cada hueso a su largo de reposo y solo
## se conserva el GIRO; la pelvis (y la raíz) sí guardan su desplazamiento,
## que es el que lleva el cuerpo por el campo y lo sube y baja.
static func _huesos_rigidos(esq: Skeleton3D) -> void:
	var pelvis := esq.find_bone("pelvis")
	for i in esq.get_bone_count():
		if i == pelvis or esq.get_bone_parent(i) < 0:
			continue
		esq.set_bone_pose_position(i, esq.get_bone_rest(i).origin)

static func _limitar_rodillas(esq: Skeleton3D) -> void:
	for n: String in ["calf_l", "calf_r"]:
		var i := esq.find_bone(n)
		if i < 0:
			continue
		var reposo := esq.get_bone_rest(i).basis.get_rotation_quaternion()
		var rel := reposo.inverse() * esq.get_bone_pose_rotation(i)
		if rel.w < 0.0:
			rel = -rel
		if rad_to_deg(rel.get_angle()) <= RODILLA_MAX:
			continue
		esq.set_bone_pose_rotation(i, reposo * Quaternion(rel.get_axis(), deg_to_rad(RODILLA_MAX)))

## SI hace falta que `raiz` este dentro del SceneTree -al reves de lo que
## se penso en un primer intento-. `AnimationPlayer.seek(t, true)` sobre
## `ap_origen` no actualiza de verdad la pose del esqueleto de origen si el
## AnimationPlayer nunca recibio `NOTIFICATION_READY` -y eso solo pasa cuando
## el nodo esta en el arbol de verdad-, aunque la llamada no tire ningun
## error. CONFIRMADO CON CAPTURA REAL Y NO SOLO SUPUESTO (21-9-2026): sacar el
## `add_child` (hecho para evitar el error "Parent node is busy setting up
## children" al llamar `terminar()` desde el propio `_ready()` de otra
## escena) dejaba `thigh_l` exactamente en su reposo, sin variar ni un
## decimal, durante los 10+ segundos completos del bucle de horneado -prueba
## de que `seek()` no estaba moviendo nada de verdad, no de que el retarget
## estuviera mal-. Arreglo: colgar `raiz` de `esq_referencia` -el esqueleto
## del jugador REAL que llamo a esto, que por contrato de `terminar()` YA
## esta en el arbol y por lo tanto YA NO esta "ocupado"- en vez de la raiz
## del SceneTree, que si puede estar ocupada si esto se llama en cadena desde
## el `_ready()` de otro nodo que se esta armando.
static func _bakear_futbol_global(archivo: String, esq_referencia: Skeleton3D) -> Animation:
	if _cache_futbol_global.has(archivo):
		return _cache_futbol_global[archivo]
	var resultado: Animation = null
	var packed: PackedScene = load(CARPETA_FUTBOL + archivo + ".fbx")
	if packed != null:
		var raiz := Node3D.new()
		esq_referencia.add_child(raiz)
		var nodo_origen: Node3D = packed.instantiate()
		raiz.add_child(nodo_origen)
		var ap_origen := _buscar_ap(nodo_origen)
		var esq_origen := _buscar_esqueleto(nodo_origen)
		var molde := FutbolistaQ.crear(FutbolistaQ.ALTURA_BASE)
		raiz.add_child(molde["nodo"])
		var esq_molde: Skeleton3D = molde["esqueleto"]
		if ap_origen != null and esq_origen != null and ap_origen.has_animation_library(""):
			var lib_origen := ap_origen.get_animation_library("")
			if lib_origen.has_animation("clip"):
				var clip_origen: Animation = lib_origen.get_animation("clip")
				var retarget := RetargetFutbolQ.crear(esq_origen, esq_molde)
				resultado = _nueva(clip_origen.length, false)
				var pistas_rot: Dictionary = {}
				var pistas_pos: Dictionary = {}
				for i in esq_molde.get_bone_count():
					var nombre := esq_molde.get_bone_name(i)
					var pr := resultado.add_track(Animation.TYPE_ROTATION_3D)
					resultado.track_set_path(pr, NodePath(":%s" % nombre))
					resultado.track_set_interpolation_type(pr, Animation.INTERPOLATION_LINEAR)
					var pp := resultado.add_track(Animation.TYPE_POSITION_3D)
					resultado.track_set_path(pp, NodePath(":%s" % nombre))
					resultado.track_set_interpolation_type(pp, Animation.INTERPOLATION_LINEAR)
					pistas_rot[i] = pr
					pistas_pos[i] = pp
				ap_origen.play("clip")
				## El primer fotograma de estos FBX es la pose de enlace (brazos
				## en T, rodillas rectas), no el movimiento: la auditoría
				## biomecánica lo vio como un salto de 49 rad/s en el primer
				## 1/30 s de los festejos. Se hornea desde el segundo fotograma.
				var t := PASO_HORNEADO
				resultado.length = maxf(0.1, clip_origen.length - PASO_HORNEADO)
				while t < clip_origen.length + PASO_HORNEADO * 0.5:
					var tt := minf(t, clip_origen.length)
					ap_origen.seek(tt, true)
					retarget.aplicar()
					_huesos_rigidos(esq_molde)
					_limitar_rodillas(esq_molde)
					for i in esq_molde.get_bone_count():
						resultado.rotation_track_insert_key(pistas_rot[i], tt - PASO_HORNEADO, esq_molde.get_bone_pose_rotation(i))
						resultado.position_track_insert_key(pistas_pos[i], tt - PASO_HORNEADO, esq_molde.get_bone_pose_position(i))
					t += PASO_HORNEADO
		raiz.free()
	_cache_futbol_global[archivo] = resultado
	return resultado

## Igual que `cargar_futbol()` pero via el retarget GLOBAL -ver el comentario
## largo encima de `_bakear_futbol_global()`-. Usar esta version, no la local,
## para cualquier accion nueva del mocap de futbol: es la que se verifico
## contra el esqueleto de origen, no solo "se ve de pie".
static func cargar_futbol_global(archivo: String, esq: Skeleton3D, prefijo: String, bucle: bool = false) -> Animation:
	var base := _bakear_futbol_global(archivo, esq)
	if base == null:
		return null
	var copia: Animation = base.duplicate(true)
	copia.loop_mode = Animation.LOOP_LINEAR if bucle else Animation.LOOP_NONE
	for i in copia.get_track_count():
		var ruta := str(copia.track_get_path(i))
		var hueso := ruta.substr(ruta.rfind(":") + 1)
		copia.track_set_path(i, NodePath("%s:%s" % [prefijo, hueso]))
	return copia

static func _idx(esq: Skeleton3D, clave: String) -> int:
	return esq.find_bone(HUESOS.get(clave, clave))

## Corrige una clave de brazo para que el cero signifique "brazo caido al
## costado" -mismo criterio que `AnimMixamo._ajustar()` para el otro modelo,
## constante distinta porque el esqueleto es distinto.
static func _ajustar(clave: String, g: Vector3) -> Vector3:
	if clave == "brazo_i":
		return Vector3(g.x, g.y, g.z + BRAZO_ABAJO_Z)
	if clave == "brazo_d":
		return Vector3(g.x, g.y, g.z - BRAZO_ABAJO_Z)
	return g

static func _pista(anim: Animation, esq: Skeleton3D, clave: String, claves: Array, prefijo: String) -> void:
	var i := _idx(esq, clave)
	if i < 0:
		return
	var reposo := esq.get_bone_rest(i).basis.get_rotation_quaternion()
	var pista := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(pista, NodePath("%s:%s" % [prefijo, esq.get_bone_name(i)]))
	anim.track_set_interpolation_type(pista, Animation.INTERPOLATION_CUBIC)
	for k in claves:
		var t: float = k[0]
		var g: Vector3 = _ajustar(clave, k[1])
		var desvio := Quaternion.from_euler(Vector3(deg_to_rad(g.x), deg_to_rad(g.y), deg_to_rad(g.z)))
		anim.rotation_track_insert_key(pista, t, reposo * desvio)

## `lineal`: para las caderas que acompañan a `_pierna_apoyada()`. Con
## interpolación cúbica la cadera se pasaba de largo entre claves y los pies,
## calculados para la cadera "de verdad", se hundían en el césped.
static func _pista_pos(anim: Animation, esq: Skeleton3D, clave: String, claves: Array, prefijo: String, lineal: bool = false) -> void:
	var i := _idx(esq, clave)
	if i < 0:
		return
	var reposo := esq.get_bone_rest(i).origin
	## BUG VIEJO CORREGIDO (25-9-2026): la pelvis cuelga de `root`, que viene
	## girado -90° en X, así que en SU espacio la altura es Z y la Y es
	## adelante-atrás. Los desplazamientos se escriben pensando en el mundo
	## (Y = arriba) y se pasan aquí al espacio del padre: antes, el "salto" del
	## cabezazo y del festejo movían la cadera hacia atrás en vez de hacia
	## arriba. Medido con el reposo de la pelvis: (0; 0,043; 0,949) -de pie, la
	## altura está en Z-.
	var padre := esq.get_bone_parent(i)
	var a_padre := Basis()
	if padre >= 0:
		a_padre = esq.get_bone_global_rest(padre).basis.orthonormalized().inverse()
	var pista := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(pista, NodePath("%s:%s" % [prefijo, esq.get_bone_name(i)]))
	anim.track_set_interpolation_type(pista, Animation.INTERPOLATION_LINEAR if lineal else Animation.INTERPOLATION_CUBIC)
	for k in claves:
		anim.position_track_insert_key(pista, k[0], reposo + a_padre * (k[1] as Vector3))

static func _pierna_anat(a: Animation, esq: Skeleton3D, lado: String, claves: Array, prefijo: String) -> void:
	## claves: [t, cadera, rodilla, tobillo] -cadera + = muslo adelante,
	## rodilla + = doblada, tobillo + = punta abajo-.
	var km: Array = []
	var kr: Array = []
	var kp: Array = []
	for k: Array in claves:
		km.append([k[0], Vector3(-float(k[1]), 0, 0)])
		kr.append([k[0], Vector3(float(k[2]) - RODILLA_REPOSO, 0, 0)])
		kp.append([k[0], Vector3(float(k[3]), 0, 0)])
	_pista(a, esq, "muslo_" + lado, km, prefijo)
	_pista(a, esq, "pierna_" + lado, kr, prefijo)
	_pista(a, esq, "pie_" + lado, kp, prefijo)

## Cinemática inversa de dos segmentos en el plano sagital: con la cadera
## desplazada `(dy, dz)` y el tobillo en `(pie_z, pie_y)` -relativos a su
## posición de reposo, 0 = en el suelo donde estaba-, devuelve [cadera,
## rodilla, tobillo] en grados anatómicos, con la rodilla hacia delante y el pie
## plano. Largos medidos del reposo del propio esqueleto.
static func _ik_pierna(esq: Skeleton3D, lado: String, dy: float, dz: float, pie_z: float = 0.0, pie_y: float = 0.0) -> Array:
	var s := "l" if lado == "i" else "r"
	var cad := esq.get_bone_global_rest(esq.find_bone("thigh_" + s)).origin
	var rod := esq.get_bone_global_rest(esq.find_bone("calf_" + s)).origin
	var tob := esq.get_bone_global_rest(esq.find_bone("foot_" + s)).origin
	var l1 := cad.distance_to(rod)
	var l2 := rod.distance_to(tob)
	var v := Vector2((tob.z + pie_z) - (cad.z + dz), (tob.y + pie_y) - (cad.y + dy))
	var r := clampf(v.length(), absf(l1 - l2) + 0.01, l1 + l2 - 0.002)
	var phi := atan2(v.x, -v.y)
	var a1 := acos(clampf((l1 * l1 + r * r - l2 * l2) / (2.0 * l1 * r), -1.0, 1.0))
	var cadera := rad_to_deg(phi + a1)
	var rodilla := 180.0 - rad_to_deg(acos(clampf((l1 * l1 + l2 * l2 - r * r) / (2.0 * l1 * l2), -1.0, 1.0)))
	## Pie plano: la suma de giros del muslo, la pierna y el pie vuelve a cero.
	## Pero el tobillo solo dorsiflexiona unos 35° (tope del tendón de Aquiles):
	## en una sentadilla profunda, pasado eso se levanta el talón, como en una
	## persona de verdad.
	var tobillo := clampf(cadera - (rodilla - RODILLA_REPOSO), -35.0, 50.0)
	return [cadera, rodilla, tobillo]

## Una pierna APOYADA: la cadera baja o se desplaza y el pie se queda plantado.
## claves: [t, dy, dz, pie_z, pie_y] (metros, espacio del esqueleto). Es lo que
## evita los pies atravesando el césped cuando el cuerpo se agacha.
static func _pierna_apoyada(a: Animation, esq: Skeleton3D, lado: String, claves: Array, prefijo: String) -> void:
	## Se resuelve cada 1/20 s interpolando los OBJETIVOS (cadera y pie), no
	## solo en las claves: interpolar ángulos entre dos poses resueltas no
	## mantiene el pie en su sitio, y a mitad de camino se hundía en el césped.
	var anat: Array = []
	var norm: Array = []
	for k: Array in claves:
		norm.append([float(k[0]), float(k[1]), float(k[2]), float(k[3]) if k.size() > 3 else 0.0, float(k[4]) if k.size() > 4 else 0.0])
	for n in norm.size():
		var k0: Array = norm[n]
		var pasos := 1
		if n + 1 < norm.size():
			pasos = maxi(1, int(ceil((float(norm[n + 1][0]) - float(k0[0])) * 20.0)))
		for p in pasos:
			if n + 1 >= norm.size() and p > 0:
				break
			var f := float(p) / float(pasos)
			var k1: Array = norm[mini(n + 1, norm.size() - 1)]
			var v: Array = []
			for c in 5:
				v.append(lerpf(float(k0[c]), float(k1[c]), f))
			var r := _ik_pierna(esq, lado, v[1], v[2], v[3], v[4])
			anat.append([v[0], r[0], r[1], r[2]])
	_pierna_anat(a, esq, lado, anat, prefijo)

## Una ventana de una animación, empezando en 0. `sin_xz` fija la X/Z de la
## pelvis a la del primer fotograma de la ventana.
## `reposo_pelvis`: con `sin_xz`, la pelvis se clava en su posición de REPOSO en
## horizontal -no en la del primer fotograma-: algunos clips arrancan con el
## actor a 3,8 m de su origen, y el jugador se veía desplazado de su sitio.
static func recortar(base: Animation, desde_f: float, hasta_f: float, bucle: bool, sin_xz: bool, reposo_pelvis: Variant = null) -> Animation:
	var a := Animation.new()
	var t0 := base.length * clampf(desde_f, 0.0, 1.0)
	var t1 := base.length * clampf(hasta_f, 0.0, 1.0)
	a.length = maxf(0.1, t1 - t0)
	a.loop_mode = Animation.LOOP_LINEAR if bucle else Animation.LOOP_NONE
	for i in base.get_track_count():
		var tipo := base.track_get_type(i)
		if tipo != Animation.TYPE_ROTATION_3D and tipo != Animation.TYPE_POSITION_3D and tipo != Animation.TYPE_SCALE_3D:
			continue
		var ruta := base.track_get_path(i)
		var nueva := a.add_track(tipo)
		a.track_set_path(nueva, ruta)
		a.track_set_interpolation_type(nueva, base.track_get_interpolation_type(i))
		var es_pelvis := tipo == Animation.TYPE_POSITION_3D and str(ruta).ends_with(":pelvis")
		var primero: Variant = null
		## El valor exacto en los dos bordes, interpolado: sin esto la ventana
		## empezaba en el primer fotograma de clave que cayera dentro y el
		## primer instante saltaba.
		var tiempos: Array[float] = [t0]
		for k in base.track_get_key_count(i):
			var tk := base.track_get_key_time(i, k)
			if tk > t0 and tk < t1:
				tiempos.append(tk)
		tiempos.append(t1)
		for tk: float in tiempos:
			var v: Variant
			match tipo:
				Animation.TYPE_ROTATION_3D: v = base.rotation_track_interpolate(i, tk)
				Animation.TYPE_POSITION_3D: v = base.position_track_interpolate(i, tk)
				_: v = base.scale_track_interpolate(i, tk)
			if es_pelvis and sin_xz:
				if primero == null:
					primero = v
				## La pelvis vive en el espacio de su padre (`root`), que viene
				## girado: ahí la ALTURA es Z, no Y (medido: 0,95 en Z al estar de
				## pie). Se busca el eje vertical por el valor -el de ~0,9 m- y se
				## congelan los otros dos, que son el avance por el campo.
				## Con el reposo a mano, el eje vertical sale del reposo (de pie,
				## ~0,95 m): un clip que arranca a 3,8 m del origen engañaba a la
				## detección por el primer fotograma.
				var p0: Vector3 = reposo_pelvis if reposo_pelvis is Vector3 else primero as Vector3
				var eje := 0
				if absf(p0.y) > absf(p0[eje]):
					eje = 1
				if absf(p0.z) > absf(p0[eje]):
					eje = 2
				var fijo: Vector3 = reposo_pelvis if reposo_pelvis is Vector3 else p0
				fijo[eje] = (v as Vector3)[eje]
				v = fijo
			match tipo:
				Animation.TYPE_ROTATION_3D: a.rotation_track_insert_key(nueva, tk - t0, v)
				Animation.TYPE_POSITION_3D: a.position_track_insert_key(nueva, tk - t0, v)
				_: a.scale_track_insert_key(nueva, tk - t0, v)
	return a

## A MANO, lo que el mocap no trae. Mismo criterio que `patear()`: solo los
## ejes ya medidos con la sonda (X de piernas, tronco y brazo adelante-atrás;
## Z de brazo al costado, espejado entre lados).
##
## El lamento: manos a las rodillas, tronco caído, cabeza gacha -el defensa que
## acaba de ver el gol en contra-.
static func lamento(esq: Skeleton3D, prefijo: String) -> Animation:
	var a := _nueva(2.4, false)
	## La cadera baja Y se va un poco atrás, como hace el cuerpo para no caerse
	## hacia delante al doblar el tronco; los pies no se mueven del sitio.
	var cad := [[0.0, 0.0, 0.0], [0.5, -0.12, -0.05], [2.0, -0.13, -0.06], [2.4, -0.05, -0.02]]
	var kc: Array = []
	var kp: Array = []
	for c: Array in cad:
		kc.append([c[0], Vector3(0, c[1], c[2])])
		kp.append([c[0], c[1], c[2]])
	_pista_pos(a, esq, "cadera", kc, prefijo, true)
	_pista(a, esq, "espalda1", [[0.0, Vector3.ZERO], [0.5, Vector3(18, 0, 0)], [2.0, Vector3(20, 0, 0)], [2.4, Vector3(8, 0, 0)]], prefijo)
	_pista(a, esq, "espalda2", [[0.0, Vector3.ZERO], [0.5, Vector3(16, 0, 0)], [2.4, Vector3(6, 0, 0)]], prefijo)
	_pista(a, esq, "cuello", [[0.0, Vector3.ZERO], [0.6, Vector3(28, 0, 0)], [1.4, Vector3(24, 8, 0)], [2.0, Vector3(28, -8, 0)], [2.4, Vector3(10, 0, 0)]], prefijo)
	for lado: String in ["i", "d"]:
		var z := 6.0 if lado == "i" else -6.0
		_pierna_apoyada(a, esq, lado, kp, prefijo)
		_pista(a, esq, "brazo_" + lado, [[0.0, Vector3(0, 0, z)], [0.5, Vector3(38, 0, z)], [2.4, Vector3(14, 0, z)]], prefijo)
		_pista(a, esq, "antebrazo_" + lado, [[0.0, Vector3.ZERO], [0.5, Vector3(12, 0, 0)], [2.4, Vector3.ZERO]], prefijo)
	return a
