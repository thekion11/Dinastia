class_name AnimQuaternius
extends RefCounted
## Fabrica de animaciones para el esqueleto Quaternius (`FutbolistaQ`), el
## segundo modelo de jugador. Mismo principio que `AnimMixamo` -las claves son
## DESVIOS sobre la pose de reposo del propio hueso, no rotaciones absolutas-
## pero un esqueleto distinto de verdad (estilo Unreal Engine, no
## `mixamorig_*`) necesita sus propios ejes: se midieron por separado,
## renderizando una sonda hueso por hueso (`pruebas/sonda_ejes_q.gd`), no
## copiados del otro archivo. Ejes confirmados asi, para las dos piernas y
## los dos brazos SIN invertir signo entre izquierda y derecha (la mirada del
## rig es simetrica en X, solo Y/Z cambian de signo entre lados):
##   muslo/rodilla/tobillo -> eje X, positivo = adelante / se dobla / puntera arriba
##   brazo (adelante-atras) -> eje X, positivo = adelante
##   brazo (sube-baja)      -> eje Z, positivo = sube
##
## POR AHORA: solo "parado" y "correr" -las dos que mas se ven en un partido-.
## El resto del catalogo de AnimMixamo (patear, celebrar, faltas...) es
## trabajo aparte, no de esta ronda.

const HUESOS := {
	"cadera": "pelvis",
	"espalda1": "spine_01",
	"espalda2": "spine_02",
	"espalda3": "spine_03",
	"cuello": "neck_01",
	"cabeza": "Head",
	"brazo_i": "upperarm_l",
	"antebrazo_i": "lowerarm_l",
	"mano_i": "hand_l",
	"brazo_d": "upperarm_r",
	"antebrazo_d": "lowerarm_r",
	"mano_d": "hand_r",
	"muslo_i": "thigh_l",
	"pierna_i": "calf_l",
	"pie_i": "foot_l",
	"muslo_d": "thigh_r",
	"pierna_d": "calf_r",
	"pie_d": "foot_r",
}

## LOS BRAZOS EN REPOSO ESTAN EN T -igual que en el otro modelo-: el desvio
## en Z que hace falta para que caigan a los costados, medido con la sonda
## (`sonda_brazo_z40.png`: +40 SUBE el brazo izquierdo desde el reposo
## horizontal, asi que para bajarlo hace falta el signo contrario y bastante
## mas angulo). CONFIRMADO CON CAPTURA REAL (18-9-2026, primer intento de
## "parado"): el mismo signo en el brazo derecho lo mandaba PARA ARRIBA en
## vez de para abajo -el eje Z SI esta espejado entre los dos brazos, a
## diferencia del eje X de piernas/brazo-adelante-atras, que no lo esta-. Por
## eso brazo_d usa el signo contrario, no el mismo.
const BRAZO_ABAJO_Z := -82.0

## MOVIMIENTO CAPTURADO DE VERDAD, NO A MANO (18-9-2026). El usuario probo una
## captura de `celebrar` y con toda razon la vio "de muniaco" -rigida, sin el
## peso ni el timing de un movimiento humano real, porque yo estaba
## adivinando angulos-. Encontramos la "Universal Animation Library" de
## Quaternius (CC0, gratis, mismo esqueleto de 65 huesos que este modelo, sin
## necesitar retargeting) y la version SIN root motion se copio a
## `res://assets/characters/quaternius/anims/UAL1_Standard.glb`. Esta funcion
## saca un clip de ahi y le reapunta cada pista a NUESTRO esqueleto -las
## pistas del glb original apuntan a "Armature/Skeleton3D:hueso" relativas a
## SU PROPIO AnimationPlayer, hay que cambiar el path pero conservar el
## nombre del hueso, que es identico en los dos modelos-.
const RUTA_UAL := "res://assets/characters/quaternius/anims/UAL1_Standard.glb"
static var _packed_ual: PackedScene
static var _lib_ual: AnimationLibrary

## Se guarda solo la LIBRERIA (un Resource, con su propio refcount, no un
## Node), no el AnimationPlayer ni el resto de la escena -esa se instancia
## una vez, se le saca la libreria, y se libera al toque con `free()`. La
## primera version dejaba el Node huerfano vivo para siempre (nunca se
## agregaba al arbol, asi que nunca se liberaba solo): funcionaba, pero
## Godot lo marcaba como fuga de mallas/shaders/RIDs al cerrar el proceso.
static func _lib_real() -> AnimationLibrary:
	if _lib_ual != null:
		return _lib_ual
	if _packed_ual == null:
		_packed_ual = load(RUTA_UAL)
	if _packed_ual == null:
		return null
	var nodo: Node3D = _packed_ual.instantiate()
	var ap := _buscar_ap(nodo)
	if ap != null and ap.has_animation_library(""):
		_lib_ual = ap.get_animation_library("")
	nodo.free()
	return _lib_ual

static func _buscar_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _buscar_ap(c)
		if r:
			return r
	return null

## Copia el clip real `nombre_real` (p.ej. "Idle", "Walk", "Jog_Fwd",
## "Sprint") reapuntando cada pista a `prefijo` (el mismo que usa `_pista()`
## para este esqueleto). Devuelve null si el clip no existe -para que quien
## llama pueda quedarse con la version a mano como respaldo en vez de romper.
static func cargar_real(nombre_real: String, prefijo: String) -> Animation:
	var lib := _lib_real()
	if lib == null:
		return null
	if not lib.has_animation(nombre_real):
		return null
	var original: Animation = lib.get_animation(nombre_real)
	var copia: Animation = original.duplicate(true)
	## Los clips de locomocion (parado/caminar/trotar/correr) se reproducen en
	## bucle en este proyecto; el glb no siempre trae ese modo marcado.
	copia.loop_mode = Animation.LOOP_LINEAR
	for i in copia.get_track_count():
		var ruta := str(copia.track_get_path(i))
		var hueso := ruta.substr(ruta.rfind(":") + 1)
		copia.track_set_path(i, NodePath("%s:%s" % [prefijo, hueso]))
	return copia

## MOCAP DE FUTBOL DE VERDAD (19-9-2026). El usuario consiguio -gratis, uso
## comercial libre, sin atribucion- el pack "Free mocap pack 05: Soccer" de
## Anderson Rohr (Gumroad): 21 clips reales (patadas, penales, festejos,
## atajadas, tarjetas), exportados en 3 esqueletos. Se uso la version "UE5"
## (Manny) porque su nomenclatura de huesos es casi identica a la nuestra
## -confirmado con `pruebas/diagnostico_mocap_ue5.gd`, no supuesto-: mismos
## `pelvis`/`spine_01..03`/`clavicle_l`/`upperarm_l`/`thigh_l`/`calf_l`/
## `foot_l`/`ball_l`... La UNICA diferencia real es que ellos usan "head" en
## minuscula y este esqueleto "Head" con mayuscula -de ahi `MAPA_HUESO_FUTBOL`-.
## Su esqueleto trae ademas huesos que el nuestro no tiene (spine_04/05,
## neck_02, huesos de torsion "_twist_", metacarpianos): esas pistas se
## descartan en vez de dejarlas apuntando a un hueso que no existe -Godot no
## truena por una NodePath de hueso invalida, pero es basura muerta en el
## recurso, mejor no guardarla-.
const CARPETA_FUTBOL := "res://assets/characters/quaternius/anims_futbol/"
const MAPA_HUESO_FUTBOL := {"head": "Head"}
static var _cache_futbol := {}

## `_cache_futbol[archivo]` guarda un Dictionary con "anim" (el Animation tal
## cual vino del fbx) y "reposo" (hueso -> {"rot": Quaternion, "pos": Vector3}
## de SU PROPIO esqueleto, no el nuestro). Hace falta guardar el reposo de
## origen porque el retargeting real necesita los DOS reposos, no solo el
## nuestro -ver el porque en el comentario de `cargar_futbol()`.
static func _cargar_clip_futbol(archivo: String) -> Dictionary:
	if _cache_futbol.has(archivo):
		return _cache_futbol[archivo]
	var salida := {"anim": null, "reposo": {}}
	var packed: PackedScene = load(CARPETA_FUTBOL + archivo + ".fbx")
	if packed != null:
		var nodo: Node3D = packed.instantiate()
		var ap := _buscar_ap(nodo)
		var esq_origen := _buscar_esqueleto(nodo)
		if ap != null and ap.has_animation_library("") and esq_origen != null:
			var lib := ap.get_animation_library("")
			if lib.has_animation("clip"):
				salida["anim"] = lib.get_animation("clip")
				var reposo := {}
				for i in esq_origen.get_bone_count():
					var nombre := esq_origen.get_bone_name(i)
					var t := esq_origen.get_bone_rest(i)
					reposo[nombre] = {"rot": t.basis.get_rotation_quaternion(), "pos": t.origin}
				salida["reposo"] = reposo
		nodo.free()
	_cache_futbol[archivo] = salida
	return salida

static func _buscar_esqueleto(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var r := _buscar_esqueleto(c)
		if r:
			return r
	return null

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

## RETARGET GLOBAL (20/21-9-2026). `cargar_futbol()` (arriba) retargetea pista
## por pista, en espacio LOCAL de cada hueso -mismo espacio que usa `_pista()`
## para las animaciones a mano-. Verificado con captura real superpuesta al
## esqueleto de origen (`pruebas/diagnostico_retarget_global.gd`, imagen
## `retarget_global_power_kick_lado.png` contra `mocap_origen_power_kick_
## lado.png`): el metodo local produce una postura "plausible" -de pie, sin
## romperse- pero que NO reproduce el gesto real -el origen se inclina
## adelante en la patada de potencia, el retarget local salia inclinado
## ATRAS-. El metodo GLOBAL (`RetargetFutbolQ`, en `visor/retarget_futbol_q.gd`)
## SI calza con el origen: mide la pose de cada hueso en espacio global
## RELATIVO A LA RAIZ ANIMADA (no relativo a su propio reposo local), y por
## eso no lo engaña la correccion de importacion de -90° que trae el hueso
## `root` del FBX -se cancela sola al dividir por la pose animada de la
## propia raiz en vez de intentar adivinar su reposo "correcto"-.
##
## `RetargetFutbolQ.aplicar()` es en TIEMPO REAL -necesita el AnimationPlayer
## de origen ya posicionado en el fotograma que se quiere y escribe la pose
## directo en un Skeleton3D vivo-, no sirve para guardar en una
## `AnimationLibrary` tal cual. Esta funcion lo "hornea": arma una escena
## descartable (el fbx de origen + un `FutbolistaQ` molde, los dos
## temporalmente colgados de la raiz del arbol para que el posado funcione),
## recorre el clip a 30 muestras por segundo aplicando el retarget en cada
## paso, y graba la pose LOCAL resultante de cada hueso del molde como
## claves de un `Animation` nuevo -con rutas SIN prefijo (":hueso") para que
## `cargar_futbol_global()` pueda reapuntarlas a cualquier instancia despues,
## mismo patron de cache-una-vez-y-reapuntar que ya usan `cargar_real()` y
## `cargar_futbol()`-.
const PASO_HORNEADO := 1.0 / 30.0
static var _cache_futbol_global := {}

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
				var t := 0.0
				while t < clip_origen.length + PASO_HORNEADO * 0.5:
					var tt := minf(t, clip_origen.length)
					ap_origen.seek(tt, true)
					retarget.aplicar()
					for i in esq_molde.get_bone_count():
						resultado.rotation_track_insert_key(pistas_rot[i], tt, esq_molde.get_bone_pose_rotation(i))
						resultado.position_track_insert_key(pistas_pos[i], tt, esq_molde.get_bone_pose_position(i))
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

static func _pista_pos(anim: Animation, esq: Skeleton3D, clave: String, claves: Array, prefijo: String) -> void:
	var i := _idx(esq, clave)
	if i < 0:
		return
	var reposo := esq.get_bone_rest(i).origin
	var pista := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(pista, NodePath("%s:%s" % [prefijo, esq.get_bone_name(i)]))
	anim.track_set_interpolation_type(pista, Animation.INTERPOLATION_CUBIC)
	for k in claves:
		anim.position_track_insert_key(pista, k[0], reposo + (k[1] as Vector3))

static func _nueva(dur: float, bucle: bool) -> Animation:
	var a := Animation.new()
	a.length = dur
	a.loop_mode = Animation.LOOP_LINEAR if bucle else Animation.LOOP_NONE
	return a

## Mapa animacion-nuestra -> clip real de la Universal Animation Library,
## para las que SI tienen equivalente real.
const CLIP_REAL := {
	"parado": "Idle",
	"caminar": "Walk",
	"trotar": "Jog_Fwd",
	"correr": "Sprint",
}

## Mapa animacion-nuestra -> clip del mocap de futbol real (Anderson Rohr,
## ver `cargar_futbol()`). `cabezazo` se queda a mano: el pack gratis no trae
## cabezazo, solo pateo/penal/festejo/atajada/tarjeta/regate/entrada.
const CLIP_FUTBOL := {
	"patear": "09_Power_Kick_ue5",
	"celebrar": "13_Goal_Celebration_02_ue5",
}

## Animaciones NUEVAS que no existian antes -sin version a mano de respaldo,
## si el archivo no carga simplemente no se agregan a la libreria-.
const CLIP_FUTBOL_NUEVO := {
	"mostrar_tarjeta": "20_Yellow_Card_ue5",
	"atajar": "15_Goalkeeper_Save_01_ue5",
	"penal": "10_Penalty_Kick_01_ue5",
}

## Las acciones de futbol de este rig se mantuvieron opt-in mientras se
## terminaba su retarget. Las capturas de 20-9-2026 probaron que tanto la
## version a mano como el primer rebase del FBX UE5 (`cargar_futbol()`, en
## espacio LOCAL) deforman la silueta; no se debian colar en un partido solo
## porque el recurso existiera. Corregido el 21-9-2026 con el retarget
## GLOBAL (`cargar_futbol_global()`, ver el comentario largo mas arriba):
## verificado con captura real contra el esqueleto de origen para las 5
## acciones -patear, celebrar, atajar, mostrar_tarjeta, penal-, las 5 calzan.
## La bandera `acciones_experimentales` se mantiene -sigue siendo una decision
## aparte activarlas en partidos de verdad via `PlayerSpawner`, esto solo dice
## que el contenido ya no esta roto-. La locomocion real de Quaternius (Idle/
## Walk/Jog/Sprint) nunca dependio de esta bandera, se agrega siempre.
static func construir(esq: Skeleton3D, ruta_esqueleto: String = "", acciones_experimentales: bool = false) -> AnimationLibrary:
	var prefijo := ruta_esqueleto if ruta_esqueleto != "" else str(esq.name)
	var lib := AnimationLibrary.new()
	var a_mano := {
		"parado": parado(esq, prefijo),
		"caminar": correr(esq, prefijo, 1.05, 0.3),
		"trotar": correr(esq, prefijo, 0.72, 0.55),
		"correr": correr(esq, prefijo, 0.52, 1.0),
	}
	for clave in a_mano:
		var real: Animation = cargar_real(CLIP_REAL[clave], prefijo)
		lib.add_animation(clave, real if real != null else a_mano[clave])
	## "sentado" no tiene equivalente en la Universal Animation Library
	## (ninguno de los 43 clips gratis es una pose sentada) -se queda a mano,
	## sin intentar `cargar_real()` primero.
	lib.add_animation("sentado", sentado(esq, prefijo))
	if acciones_experimentales:
		var a_mano_futbol := {
			"patear": patear(esq, prefijo),
			"celebrar": celebrar(esq, prefijo),
		}
		for clave in a_mano_futbol:
			var real: Animation = cargar_futbol_global(CLIP_FUTBOL[clave], esq, prefijo)
			lib.add_animation(clave, real if real != null else a_mano_futbol[clave])
		lib.add_animation("cabezazo", cabezazo(esq, prefijo))
		for clave in CLIP_FUTBOL_NUEVO:
			var real: Animation = cargar_futbol_global(CLIP_FUTBOL_NUEVO[clave], esq, prefijo)
			if real != null:
				lib.add_animation(clave, real)
	return lib

## El remate. Mismo diseno de tres tiempos que `AnimMixamo.patear()` -armar,
## soltar, acompanar-, recalibrado a los ejes propios de este esqueleto. Solo
## eje X en todo (pierna de golpeo, pierna de apoyo, los dos brazos de
## contrapeso): es el eje que se confirmo IGUAL de un lado y del otro con la
## sonda, asi que aqui no hace falta pelear con el espejo de Z como en el
## brazo caido de `parado()`/`correr()` -el baseline de Z ya lo pone
## `_ajustar()` solo, esta animacion no le suma nada mas en Z-.
static func patear(esq: Skeleton3D, prefijo: String) -> Animation:
	var a := _nueva(0.85, false)
	_pista(a, esq, "espalda3", [[0.0, Vector3(-6, 0, 0)], [0.32, Vector3(-16, 0, 0)],
		[0.46, Vector3(6, 0, 0)], [0.85, Vector3(-4, 0, 0)]], prefijo)
	# pierna derecha: la que golpea -arma atras, dispara adelante, acompana-
	_pista(a, esq, "muslo_d", [[0.0, Vector3(-10, 0, 0)], [0.32, Vector3(-52, 0, 0)],
		[0.48, Vector3(58, 0, 0)], [0.85, Vector3(6, 0, 0)]], prefijo)
	_pista(a, esq, "pierna_d", [[0.0, Vector3(14, 0, 0)], [0.32, Vector3(92, 0, 0)],
		[0.48, Vector3(6, 0, 0)], [0.85, Vector3(18, 0, 0)]], prefijo)
	_pista(a, esq, "pie_d", [[0.0, Vector3(0, 0, 0)], [0.32, Vector3(24, 0, 0)],
		[0.48, Vector3(-22, 0, 0)], [0.85, Vector3(0, 0, 0)]], prefijo)
	# pierna izquierda: la de apoyo, casi quieta
	_pista(a, esq, "muslo_i", [[0.0, Vector3(6, 0, 0)], [0.48, Vector3(-8, 0, 0)], [0.85, Vector3(0, 0, 0)]], prefijo)
	_pista(a, esq, "pierna_i", [[0.0, Vector3(12, 0, 0)], [0.48, Vector3(26, 0, 0)], [0.85, Vector3(10, 0, 0)]], prefijo)
	# los dos brazos contrapesan el latigazo, solo en X -sin sumar Z, que es
	# donde este esqueleto espeja entre lados-.
	_pista(a, esq, "brazo_i", [[0.0, Vector3(-14, 0, 0)], [0.34, Vector3(-58, 0, 0)],
		[0.5, Vector3(-20, 0, 0)], [0.85, Vector3(-10, 0, 0)]], prefijo)
	_pista(a, esq, "brazo_d", [[0.0, Vector3(10, 0, 0)], [0.34, Vector3(34, 0, 0)],
		[0.5, Vector3(6, 0, 0)], [0.85, Vector3(8, 0, 0)]], prefijo)
	return a

## El salto de cabeza. Calco directo de `AnimMixamo.cabezazo()` -mismo diseno,
## mismos numeros donde el hueso equivalente existe- con dos ajustes: "espalda"
## (un solo hueso en el modelo viejo) pasa a `espalda2` (el tramo medio de la
## columna en este esqueleto de 3 tramos), y los brazos se escriben con el
## signo de Z YA MIRADO A MANO por lado -14/-14 y 58/-58, igual que el
## original- en vez de dejarselo a `_ajustar()`: esa funcion solo mueve el
## PISO (la constante `BRAZO_ABAJO_Z`), no espeja los deltas que le manda cada
## animacion, así que cada animacion tiene que mirar sus propios deltas de Z
## igual que ya hacia el fichero Mixamo (confirmado con la sonda: Z sube/baja
## el brazo con el mismo signo en el input pero en direcciones reales
## opuestas entre lados).
static func cabezazo(esq: Skeleton3D, prefijo: String) -> Animation:
	var a := _nueva(1.0, false)
	_pista_pos(a, esq, "cadera", [[0.0, Vector3.ZERO], [0.35, Vector3(0, 0.22, 0)],
		[0.62, Vector3(0, 0.26, 0)], [1.0, Vector3.ZERO]], prefijo)
	_pista(a, esq, "espalda2", [[0.0, Vector3(0, 0, 0)], [0.4, Vector3(22, 0, 0)],
		[0.6, Vector3(-26, 0, 0)], [1.0, Vector3(0, 0, 0)]], prefijo)
	_pista(a, esq, "cuello", [[0.0, Vector3(0, 0, 0)], [0.4, Vector3(16, 0, 0)],
		[0.58, Vector3(-20, 0, 0)], [1.0, Vector3(0, 0, 0)]], prefijo)
	_pista(a, esq, "brazo_i", [[0.0, Vector3(-40, 0, 14)], [0.4, Vector3(-40, 0, 58)], [1.0, Vector3(-40, 0, 14)]], prefijo)
	_pista(a, esq, "brazo_d", [[0.0, Vector3(-40, 0, -14)], [0.4, Vector3(-40, 0, -58)], [1.0, Vector3(-40, 0, -14)]], prefijo)
	_pista(a, esq, "muslo_i", [[0.0, Vector3(0, 0, 0)], [0.45, Vector3(38, 0, 0)], [1.0, Vector3(0, 0, 0)]], prefijo)
	_pista(a, esq, "pierna_i", [[0.0, Vector3(-6, 0, 0)], [0.45, Vector3(-72, 0, 0)], [1.0, Vector3(-6, 0, 0)]], prefijo)
	return a

## El festejo de gol: correr con los brazos abiertos y saltar, en bucle -la
## clasica-. Calco de `AnimMixamo.celebrar()`, mismo criterio que `cabezazo()`
## para "espalda" (-> `espalda2`) y para el Z de los brazos (ya venia
## pre-espejado en el original: 96/-96, 128/-128, se copia tal cual). El
## antebrazo del original solo gira 16 grados en Z -un detalle cosmetico
## minusculo, sin verificar con sonda en este esqueleto-, asi que se omite en
## vez de arriesgar un eje sin medir por un movimiento que apenas se nota.
static func celebrar(esq: Skeleton3D, prefijo: String) -> Animation:
	var a := _nueva(1.6, true)
	_pista_pos(a, esq, "cadera", [[0.0, Vector3.ZERO], [0.4, Vector3(0, 0.24, 0)],
		[0.8, Vector3.ZERO], [1.2, Vector3(0, 0.1, 0)], [1.6, Vector3.ZERO]], prefijo)
	_pista(a, esq, "espalda2", [[0.0, Vector3(4, 0, 0)], [0.4, Vector3(-12, 0, 0)], [1.6, Vector3(4, 0, 0)]], prefijo)
	_pista(a, esq, "cabeza", [[0.0, Vector3(-14, 0, 0)], [0.8, Vector3(-18, 8, 0)], [1.6, Vector3(-14, 0, 0)]], prefijo)
	_pista(a, esq, "brazo_i", [[0.0, Vector3(-20, 0, 96)], [0.4, Vector3(-30, 0, 128)],
		[0.8, Vector3(-20, 0, 96)], [1.6, Vector3(-20, 0, 96)]], prefijo)
	_pista(a, esq, "brazo_d", [[0.0, Vector3(-20, 0, -96)], [0.4, Vector3(-30, 0, -128)],
		[0.8, Vector3(-20, 0, -96)], [1.6, Vector3(-20, 0, -96)]], prefijo)
	_pista(a, esq, "muslo_i", [[0.0, Vector3(18, 0, 0)], [0.4, Vector3(46, 0, 0)], [0.8, Vector3(-18, 0, 0)],
		[1.2, Vector3(30, 0, 0)], [1.6, Vector3(18, 0, 0)]], prefijo)
	_pista(a, esq, "muslo_d", [[0.0, Vector3(-18, 0, 0)], [0.4, Vector3(30, 0, 0)], [0.8, Vector3(18, 0, 0)],
		[1.2, Vector3(-14, 0, 0)], [1.6, Vector3(-18, 0, 0)]], prefijo)
	_pista(a, esq, "pierna_i", [[0.0, Vector3(-40, 0, 0)], [0.4, Vector3(-88, 0, 0)], [1.6, Vector3(-40, 0, 0)]], prefijo)
	_pista(a, esq, "pierna_d", [[0.0, Vector3(-30, 0, 0)], [0.8, Vector3(-70, 0, 0)], [1.6, Vector3(-30, 0, 0)]], prefijo)
	return a

static func parado(esq: Skeleton3D, prefijo: String) -> Animation:
	var a := _nueva(3.2, true)
	_pista_pos(a, esq, "cadera", [[0.0, Vector3.ZERO], [1.6, Vector3(0, 0.012, 0)], [3.2, Vector3.ZERO]], prefijo)
	_pista(a, esq, "espalda1", [[0.0, Vector3(0, 0, 0)], [1.6, Vector3(-2, 0, 0)], [3.2, Vector3.ZERO]], prefijo)
	_pista(a, esq, "cabeza", [[0.0, Vector3(0, -3, 0)], [1.6, Vector3(0, 3, 0)], [3.2, Vector3(0, -3, 0)]], prefijo)
	_pista(a, esq, "brazo_i", [[0.0, Vector3(0, 0, 4)], [1.6, Vector3(0, 0, 7)], [3.2, Vector3(0, 0, 4)]], prefijo)
	_pista(a, esq, "brazo_d", [[0.0, Vector3(0, 0, -4)], [1.6, Vector3(0, 0, -7)], [3.2, Vector3(0, 0, -4)]], prefijo)
	return a

## SENTADO (22-9-2026, pedido directo del usuario tras ver el banquillo de
## pie: "que los que no caben estén sentados"). Pose estatica -con la misma
## respiracion sutil que ya usa `parado()`, para que no se lea como una
## estatua entre gente que sí se mueve-, solo eje X en muslo/rodilla/pie -el
## mismo eje ya calibrado con la sonda para correr/patear, sin ejes nuevos
## sin medir-. El truco real no esta en el angulo de las piernas -90 grados
## en la cadera, otros 90 en la rodilla, la geometria de sentarse en
## cualquier silla- sino en que rotar el muslo NO mueve la cadera en el
## espacio: `FutbolistaQ` sigue de pie a la altura de pelvis=1.03m (medido,
## `pruebas/diagnostico_altura_cadera_q.gd`) aunque las piernas ya esten
## dobladas -"flotando sentado en el aire" en vez de apoyado en un banco-.
## Por eso esto SOLO es la mitad de la solucion: quien llame a esto tiene que
## bajar la raiz del modelo (`ALTO_ASIENTO_OFFSET`) para que la cadera caiga a
## la altura real de un asiento, ver `visor/player_spawner.gd::spawn_
## sentados()`.
const ALTO_ASIENTO_OFFSET := -0.47

static func sentado(esq: Skeleton3D, prefijo: String) -> Animation:
	var a := _nueva(3.4, true)
	_pista_pos(a, esq, "cadera", [[0.0, Vector3.ZERO], [1.7, Vector3(0, 0.01, 0)], [3.4, Vector3.ZERO]], prefijo)
	_pista(a, esq, "espalda1", [[0.0, Vector3(-4, 0, 0)], [1.7, Vector3(-6, 0, 0)], [3.4, Vector3(-4, 0, 0)]], prefijo)
	_pista(a, esq, "cabeza", [[0.0, Vector3(0, -3, 0)], [1.7, Vector3(0, 3, 0)], [3.4, Vector3(0, -3, 0)]], prefijo)
	## Cadera: 90° adelante -el muslo pasa de colgar vertical a quedar
	## horizontal, apoyado en el asiento-.
	_pista(a, esq, "muslo_i", [[0.0, Vector3(90, 0, 0)]], prefijo)
	_pista(a, esq, "muslo_d", [[0.0, Vector3(90, 0, 0)]], prefijo)
	## Rodilla: -100°, NO +92 -CORREGIDO 22-9-2026 con una sonda real
	## (`pruebas/sonda_rodilla_sentado.gd`, barrido de -150 a 90 con el muslo
	## ya fijo en 90, una imagen por valor, el mismo metodo que ya usaba este
	## proyecto para huesos nuevos sin calibrar). +92 -el primer numero, nunca
	## verificado con una imagen aislada, solo "parecia razonable"- doblaba la
	## pantorrilla hacia ARRIBA Y ATRAS, el pie casi contra el gluteo -el
	## mismo signo que ya usa `_pierna()`/`patear()` para el retroceso de una
	## zancada, que resulta ser la direccion CONTRARIA a la que hace falta
	## cuando el muslo YA esta horizontal-. -100 deja la pantorrilla colgando
	## hacia el piso, el pie cerca de donde estaria si la persona estuviera
	## sentada de verdad -confirmado con la imagen de la sonda, no a ojo en
	## el codigo-. -80 se queda corto (la pantorrilla todavia muy abierta),
	## -120 se pasa (el pie se cruza detras de la rodilla).
	_pista(a, esq, "pierna_i", [[0.0, Vector3(-100, 0, 0)]], prefijo)
	_pista(a, esq, "pierna_d", [[0.0, Vector3(-100, 0, 0)]], prefijo)
	## Pie: leve correccion para que quede plano en el piso, no en punta.
	_pista(a, esq, "pie_i", [[0.0, Vector3(-6, 0, 0)]], prefijo)
	_pista(a, esq, "pie_d", [[0.0, Vector3(-6, 0, 0)]], prefijo)
	## Brazos apoyados hacia adelante, sobre las rodillas -antebrazo doblado,
	## no colgando a los costados como de pie-.
	_pista(a, esq, "brazo_i", [[0.0, Vector3(18, 0, 6)]], prefijo)
	_pista(a, esq, "brazo_d", [[0.0, Vector3(18, 0, -6)]], prefijo)
	_pista(a, esq, "antebrazo_i", [[0.0, Vector3(60, 0, 0)]], prefijo)
	_pista(a, esq, "antebrazo_d", [[0.0, Vector3(60, 0, 0)]], prefijo)
	return a

## Ciclo de zancada, mismo diseno de 4 tiempos que `AnimMixamo.correr()`
## (contacto -> apoyo -> impulso -> recogida), recalibrado a los ejes de
## este esqueleto.
static func correr(esq: Skeleton3D, prefijo: String, dur: float, f: float) -> Animation:
	var a := _nueva(dur, true)
	var t1 := dur * 0.25
	var t2 := dur * 0.5
	var t3 := dur * 0.75
	var muslo: float = 42.0 * f
	var rodilla: float = 75.0 * f
	var brazo: float = 38.0 * f

	_pista_pos(a, esq, "cadera", [
		[0.0, Vector3(0, -0.025 * f, 0)], [t1, Vector3(0, 0.03 * f, 0)],
		[t2, Vector3(0, -0.025 * f, 0)], [t3, Vector3(0, 0.03 * f, 0)],
		[dur, Vector3(0, -0.025 * f, 0)]], prefijo)
	_pista(a, esq, "espalda3", [[0.0, Vector3(-4.0 * f, 0, 0)]], prefijo)
	_pista(a, esq, "espalda1", [
		[0.0, Vector3(0, 5.0 * f, 0)], [t2, Vector3(0, -5.0 * f, 0)], [dur, Vector3(0, 5.0 * f, 0)]], prefijo)

	_pierna(a, esq, "muslo_i", "pierna_i", "pie_i", 0.0, dur, muslo, rodilla, prefijo)
	_pierna(a, esq, "muslo_d", "pierna_d", "pie_d", t2, dur, muslo, rodilla, prefijo)

	## Brazos en contrafase de las piernas -brazo_i adelante cuando pierna_i
	## atras, como al correr de verdad-. Eje Z fijo en BRAZO_ABAJO_Z (via
	## `_ajustar`), eje X hace el vaiven adelante-atras.
	_pista(a, esq, "brazo_i", [
		[0.0, Vector3(-brazo, 0, 0)], [t2, Vector3(brazo, 0, 0)], [dur, Vector3(-brazo, 0, 0)]], prefijo)
	_pista(a, esq, "brazo_d", [
		[0.0, Vector3(brazo, 0, 0)], [t2, Vector3(-brazo, 0, 0)], [dur, Vector3(brazo, 0, 0)]], prefijo)
	_pista(a, esq, "antebrazo_i", [
		[0.0, Vector3(0, 0, 0)], [t2, Vector3(0, 0, 0)]], prefijo)
	_pista(a, esq, "antebrazo_d", [
		[0.0, Vector3(0, 0, 0)], [t2, Vector3(0, 0, 0)]], prefijo)
	return a

static func _pierna(a: Animation, esq: Skeleton3D, mus: String, rod: String, pie: String,
		off: float, dur: float, muslo: float, rodilla: float, prefijo: String) -> void:
	var fases := [
		[0.00,  muslo,        rodilla * 0.16,  -14.0],
		[0.25, -muslo * 0.35,  rodilla * 0.10,   4.0],
		[0.50, -muslo * 0.80,  rodilla * 0.30,  22.0],
		[0.75,  muslo * 0.55,  rodilla,         -8.0],
		[1.00,  muslo,         rodilla * 0.16, -14.0],
	]
	var km: Array = []
	var kr: Array = []
	var kp: Array = []
	for fase in fases:
		var t: float = fmod(float(fase[0]) * dur + off, dur)
		km.append([t, Vector3(fase[1], 0, 0)])
		kr.append([t, Vector3(fase[2], 0, 0)])
		kp.append([t, Vector3(fase[3], 0, 0)])
	km.append([dur, km[0][1]])
	kr.append([dur, kr[0][1]])
	kp.append([dur, kp[0][1]])
	_pista(a, esq, mus, km, prefijo)
	_pista(a, esq, rod, kr, prefijo)
	_pista(a, esq, pie, kp, prefijo)
