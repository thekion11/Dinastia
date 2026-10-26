class_name CasaDT
extends Node3D
## LA CASA DEL DT POR DENTRO (fase 3, bloque 4 «Casa y familia», 26-10-2026).
## Plan del lunes §2.2c: *«entrar a tu casa: salón, cocina, dormitorio; pareja, hijos
## y mascota con cuerpo (`VidaDT.perfil`) y 2-3 frases según `familia`; cama (dormir),
## mesa (comer), sofá (ocio de la semana)»*.
##
## No dibuja nada nuevo por su cuenta: la sala es la VIVIENDA del sistema de
## interiores (`InteriorInstalacion.en_mundo`, la misma que se pasea en la ciudad),
## a la que se le suma el dormitorio (cama y mesilla del catálogo `Modulos`) y se
## le quitan los desconocidos que trae de serie (un cocinero y un paseante: en tu
## casa solo vive tu familia). La familia sale de `VidaDT.perfil` (ficticia, por
## hash) con el mismo patrón de cuerpos que el personal del estadio.
##
## Solo lógica y 3D: ningún botón. Quien recorre (ExploradorCiudad) pregunta
## `cercano(pos)` y, con E, llama a `usar(clave)`; el resultado se enseña como
## quiera (cuadro de diálogo, móvil...). Sin `_process` ni RigidBody: los
## cuerpos ya se mueven solos con su nodo «Vida».

## A menos de esto (m) de un punto de uso, se puede usar.
const RADIO_USO := 1.6
## Lo que baja el estrés una tarde en el sofá.
const ESTRES_SOFA := 2
## Hora a la que te levantas al dormir en tu cama.
const HORA_LEVANTARSE := 8

## Dónde queda cada cosa DENTRO de la vivienda (coordenadas de la sala; la
## puerta está en z = +fondo/2). Sofá y mesa son los de `_vivienda`; la cama la
## pone esta clase en el rincón libre de la izquierda, junto a la puerta.
const POS_CAMA := Vector3(-4.6, 0, 3.45)
const POS_USO := {
	"cama": Vector3(-3.3, 0, 3.4),
	"sofa": Vector3(-3.2, 0, -1.6),
	"mesa": Vector3(3.3, 0, 0.8),
}
const POS_PAREJA := Vector3(0.4, 0, -1.6)
const POS_HIJOS := [Vector3(1.2, 0, 2.2), Vector3(2.3, 0, 2.5), Vector3(0.2, 0, 2.6)]
const POS_MASCOTA := Vector3(-1.4, 0, 2.4)

## Lo que te dice la familia según lo contenta que está (`VidaDT.familia`).
## Ficticio y casero; nada de religión ni política.
const FRASES := {
	"contenta": [
		"¡Por fin en casa! Hoy cenamos todos juntos.",
		"Vimos el partido por la tele. ¡Qué orgullo!",
		"Guardamos el postre para ti. Siéntate un rato.",
	],
	"normal": [
		"Hola. ¿Cómo fue el día en el club?",
		"Llegaste justo: la cena está casi lista.",
		"El fin de semana podríamos salir a algún lado, ¿no?",
	],
	"dolida": [
		"Casi no te vemos. ¿Vas a cenar con nosotros hoy?",
		"Otra vez tarde. Te guardamos un plato, por si acaso.",
		"La casa sin ti se siente muy callada.",
	],
}

var mundo: Mundo
var interior: InteriorInstalacion
## Los cuerpos de la familia: {clave, nombre, nodo, anim}.
var cuerpos: Array[Dictionary] = []
## El día (año|semana|día) en que ya se charló con la familia (+1 de familia una vez al día).
var _dia_charla := ""
var _origen := Vector3.ZERO

# ============================================================================ MONTAR

## Construye la casa colgada de `raiz3d`, con la puerta en `origen + (0, 0, fondo/2)`.
func montar(raiz3d: Node3D, mundo_: Mundo, origen: Vector3) -> void:
	mundo = mundo_
	_origen = origen
	name = "CasaDT"
	position = origen
	raiz3d.add_child(self)
	var club: Club = mundo.mi_club() if mundo != null else null
	interior = InteriorInstalacion.en_mundo(self, "edificio_vivienda|" + Idiomas.t("Tu casa"), club)
	if interior == null:
		return
	_sin_desconocidos()
	_dormitorio()
	_familia()

## La vivienda de serie trae un cocinero y un paseante inventados: fuera, que
## aquí vive tu familia. Se vacían las listas para que nada los mueva.
func _sin_desconocidos() -> void:
	for lista: Array in [interior._fijos, interior._caminantes]:
		for e: Dictionary in lista:
			var d: Dictionary = e.get("d", {})
			if d.has("nodo") and is_instance_valid(d["nodo"]):
				(d["nodo"] as Node).queue_free()
		lista.clear()

## El dormitorio: cama de matrimonio (o individual si vives solo) con su mesilla
## y lámpara, del catálogo modular, en el rincón izquierdo junto a la puerta.
func _dormitorio() -> void:
	var solo := mundo == null or mundo.vida == null or String(mundo.vida.perfil.get("pareja", "")) == ""
	var cama := "bedSingle" if solo else "bedDouble"
	if not Modulos.existe(cama):
		return
	var tela := Color(0.36, 0.45, 0.6)
	var n := Modulos.tomar(cama, null, {"carpet": tela, "carpetDarker": tela.darkened(0.25)})
	n.position = POS_CAMA
	n.rotation.y = PI * 0.5
	add_child(n)
	if Modulos.existe("cabinetBedDrawerTable"):
		var mesilla := Modulos.tomar("cabinetBedDrawerTable")
		mesilla.position = POS_CAMA + Vector3(0.0, 0, -1.35)
		mesilla.rotation.y = PI * 0.5
		add_child(mesilla)
		if Modulos.existe("lampRoundTable"):
			var alto := (Modulos.datos("cabinetBedDrawerTable")["caja"] as AABB).size.y * Modulos.escala("cabinetBedDrawerTable").y
			var lampara := Modulos.tomar("lampRoundTable")
			lampara.position = mesilla.position + Vector3(0, alto, 0)
			add_child(lampara)

# =========================================================================== FAMILIA

## Pareja, hijos y mascota con cuerpo. Si el perfil aún no existe, se crea con el
## id del club (como hace el panel de Mi Vida).
func _familia() -> void:
	if mundo == null or mundo.vida == null:
		return
	if mundo.vida.perfil.is_empty() and mundo.mi_club() != null:
		mundo.vida.crear_perfil(mundo.mi_club().id)
	var perfil: Dictionary = mundo.vida.perfil
	var semilla := absi(("casa|" + String(perfil.get("pareja", "")) + str(perfil.get("hijos", []))).hash())
	var pareja := String(perfil.get("pareja", ""))
	if pareja != "":
		_persona("pareja", pareja, POS_PAREJA, 0.0, -1, semilla)
	var hijos: Array = perfil.get("hijos", [])
	for i in mini(hijos.size(), POS_HIJOS.size()):
		var h: Dictionary = hijos[i]
		_persona("hijo", String(h.get("nombre", "")), POS_HIJOS[i], -0.4 + 0.4 * float(i), int(h.get("edad", 8)), semilla + 11 * (i + 1))
	if String(perfil.get("mascota", "")) != "":
		_mascota(String(perfil["mascota"]), POS_MASCOTA)

func _rng(semilla: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = semilla
	return r

## Un cuerpo según el nombre (patrón de `PersonalEstadio`): mujer si el nombre lo
## es, ropa de casa, y los niños con altura de niño (`edad` ≥ 0).
func _persona(clave: String, nombre: String, pos: Vector3, giro: float, edad: int, semilla: int) -> void:
	var raiz := Node3D.new()
	raiz.name = "Familia_" + clave
	raiz.position = pos
	raiz.rotation.y = giro
	add_child(raiz)
	var rng := _rng(semilla)
	var asp := PersonajeDT.aleatorio(rng)
	var mujer := PersonalEstadio.nombre_de_mujer(nombre)
	asp["cuerpo"] = "female" if mujer else "male"
	asp["barba"] = bool(asp["barba"]) and not mujer and edad < 0
	if mujer and String(asp["pelo"]) in ["calvo", "rapado", "fade", "samurai"]:
		asp["pelo"] = "melena"
	if edad >= 0:
		## Niños y adolescentes: de 1,10 m a 1,40 m según la edad; nada de canas ni barba.
		asp["altura"] = clampf(0.95 + float(edad) * 0.032, 1.1, 1.4)
		asp["edad"] = edad
		asp["pelo"] = "corto" if not mujer else "melena"
		asp["tatuaje"] = 0
		asp["gafas"] = ""
	else:
		asp["altura"] = clampf(float(asp["altura"]), 1.6, 1.74) if mujer else clampf(float(asp["altura"]), 1.68, 1.86)
		asp["edad"] = 30 + semilla % 16
	## Ropa de estar por casa, sin corbata ni gorra.
	asp["ropa"] = ["sudadera", "polo", "vaqueros", "rayas"][rng.randi() % 4]
	asp["corbata"] = false
	asp["gorra"] = false
	asp["bufanda"] = false
	var c1 := Color.from_hsv(rng.randf(), 0.35, 0.75)
	var c2 := Color(0.92, 0.9, 0.86)
	var d := PersonajeDT.crear(raiz, asp, c1, c2)
	if d.is_empty():
		raiz.queue_free()
		return
	var et := Label3D.new()
	et.text = nombre
	et.font_size = 26
	et.pixel_size = 0.0022
	et.visibility_range_end = 14.0
	et.outline_size = 6
	et.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	et.position = Vector3(0, float(asp["altura"]) + 0.3, 0)
	et.modulate = Color(1, 0.97, 0.85)
	raiz.add_child(et)
	cuerpos.append({"clave": clave, "nombre": nombre, "nodo": raiz, "anim": d.get("anim"), "pos": pos})

## La mascota: no hay modelo de perro en los kits, así que es un perrito de cajas
## (cuerpo, cabeza, orejas, patas y cola) con su nombre encima.
func _mascota(nombre: String, pos: Vector3) -> void:
	var raiz := Node3D.new()
	raiz.name = "Mascota"
	raiz.position = pos
	raiz.rotation.y = 0.7
	add_child(raiz)
	var pelo := Mini3D.mat(Color(0.62, 0.45, 0.28), 0.9)
	var oscuro := Mini3D.mat(Color(0.25, 0.18, 0.12), 0.8)
	Mini3D.caja(raiz, Vector3(0, 0.34, 0), Vector3(0.24, 0.22, 0.5), pelo)
	Mini3D.caja(raiz, Vector3(0, 0.5, 0.3), Vector3(0.2, 0.18, 0.22), pelo)
	Mini3D.caja(raiz, Vector3(0, 0.46, 0.43), Vector3(0.1, 0.08, 0.1), oscuro)
	for sx: float in [-1.0, 1.0]:
		Mini3D.caja(raiz, Vector3(sx * 0.08, 0.6, 0.28), Vector3(0.05, 0.1, 0.06), oscuro)
		for sz: float in [-0.17, 0.17]:
			Mini3D.caja(raiz, Vector3(sx * 0.08, 0.12, sz), Vector3(0.07, 0.24, 0.08), pelo)
	Mini3D.caja(raiz, Vector3(0, 0.45, -0.3), Vector3(0.05, 0.05, 0.18), pelo)
	var et := Label3D.new()
	et.text = nombre
	et.font_size = 22
	et.pixel_size = 0.0022
	et.visibility_range_end = 10.0
	et.outline_size = 6
	et.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	et.position = Vector3(0, 0.85, 0)
	raiz.add_child(et)

# ===================================================================== PUNTOS DE USO

## Los sitios donde se puede hacer algo: {clave, pos (mundo), texto («E: Dormir»), nombre}.
## La pareja y cada hijo son un punto cada uno (clave "pareja" / "hijo").
func puntos() -> Array[Dictionary]:
	var sal: Array[Dictionary] = []
	if interior == null:
		return sal
	for k: String in ["cama", "mesa", "sofa"]:
		sal.append({"clave": k, "pos": _origen + (POS_USO[k] as Vector3), "texto": "E: " + Idiomas.t(_verbo(k)), "nombre": ""})
	for c: Dictionary in cuerpos:
		sal.append({"clave": String(c["clave"]), "pos": _origen + (c["pos"] as Vector3),
			"texto": "E: " + Idiomas.t("Hablar con %s") % String(c["nombre"]), "nombre": String(c["nombre"])})
	return sal

static func _verbo(clave: String) -> String:
	match clave:
		"cama":
			return "Dormir"
		"mesa":
			return "Comer"
		"sofa":
			return "Descansar en el sofá"
	return "Hablar"

## El punto de uso a menos de `RADIO_USO` de `p` (el más cercano), o {} si no hay.
func cercano(p: Vector3) -> Dictionary:
	var mejor := {}
	var mejor_d := RADIO_USO
	for pt: Dictionary in puntos():
		var q: Vector3 = pt["pos"]
		var d := Vector2(p.x - q.x, p.z - q.z).length()
		if d < mejor_d:
			mejor_d = d
			mejor = pt
	return mejor

# ========================================================================== ACCIONES

## Usa un punto. Devuelve {titulo, texto, minutos, actividad} ya traducido y aplica el
## efecto en el mundo (reloj, necesidades, vida). Clave desconocida → {}.
func usar(clave: String, nombre := "") -> Dictionary:
	if mundo == null or mundo.reloj == null:
		return {}
	match clave:
		"cama":
			var mins := mundo.reloj.esperar_hasta(HORA_LEVANTARSE, "dormir")
			return {"titulo": Idiomas.t("Dormir"), "texto": Idiomas.t("Duermes en tu cama hasta las 08:00. Te levantas descansado."),
				"minutos": mins, "actividad": "dormir"}
		"mesa":
			var mins := mundo.reloj.avanzar_minutos(30, "comer")
			return {"titulo": Idiomas.t("Comer"), "texto": Idiomas.t("Comes tranquilo en casa. El hambre se va."),
				"minutos": mins, "actividad": "comer"}
		"sofa":
			var mins := mundo.reloj.avanzar_minutos(90, "libre")
			if mundo.vida != null:
				mundo.vida.estres = maxi(mundo.vida.estres - ESTRES_SOFA, 0)
			return {"titulo": Idiomas.t("Descansar en el sofá"), "texto": Idiomas.t("Una hora y media de sofá y tele. El estrés baja un poco."),
				"minutos": mins, "actividad": "libre"}
		"pareja", "hijo":
			return _charla(clave, nombre)
	return {}

## Una frase de la familia según `VidaDT.familia`; la primera charla de cada día
## suma 1 a la familia (tope 100).
func _charla(clave: String, nombre: String) -> Dictionary:
	var v: VidaDT = mundo.vida
	if v == null:
		return {}
	if nombre == "":
		for c: Dictionary in cuerpos:
			if String(c["clave"]) == clave:
				nombre = String(c["nombre"])
				break
	var tramo := "contenta" if v.familia >= 70 else ("normal" if v.familia >= 40 else "dolida")
	var lista: Array = FRASES[tramo]
	var hoy := "%d|%d|%d" % [mundo.reloj.anio, mundo.reloj.semana, mundo.reloj.dia]
	var i := absi((hoy + "|" + nombre).hash()) % lista.size()
	var texto := "%s: «%s»" % [nombre, Idiomas.t(String(lista[i]))]
	if _dia_charla != hoy:
		_dia_charla = hoy
		v.familia = clampi(v.familia + 1, 0, 100)
	return {"titulo": Idiomas.t("Hablar con %s") % nombre, "texto": texto, "minutos": 0, "actividad": "libre"}

## La sala (`InteriorInstalacion`) no cuelga del árbol: se libera con la casa.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and interior != null and is_instance_valid(interior) and not interior.is_inside_tree():
		interior.free()
		interior = null

## Para los choques del que recorre: los círculos del mobiliario (sin paredes ni suelo).
func obstaculos() -> PackedVector3Array:
	return Optimizar.obstaculos(self, [] as Array[Rect2], 0.4, 0.5)
