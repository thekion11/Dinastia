class_name Redes
extends RefCounted
## LAS REDES SOCIALES (28-9-2026, pedido: "poder comentar en esas redes, que
## suban fotos, #, cantidad de likes, red oficial del club y del personaje,
## seguidores, publicaciones, poder interactuar con el teléfono").
##
## Una red inventada, TRIBUNA, con dos cuentas tuyas:
##   - la tuya (el DT, `@tu_nombre`), que crece con tu fama mediática;
##   - la oficial del club (`@club_oficial`), que crece con la reputación del
##     club y los resultados, y que publica sola lo que pasa (victorias,
##     derrotas, títulos) a partir de las noticias.
## Los hinchas publican y comentan. Tú puedes PUBLICAR (una foto del
## entrenamiento, un mensaje a la hinchada, una indirecta al rival...) con sus
## hashtags, dar "me gusta" y RESPONDER comentarios. Cada cosa tiene su efecto:
## la reputación por facetas (mediático, social, juego limpio) y el ánimo de
## la hinchada. Las indirectas pueden salir caras: a veces se hace polémica.
## Todos los usuarios, cuentas y la red son inventados.

signal noticia(titulo: String, cuerpo: String)

const MAX_PUBLICACIONES := 80
const MAX_PROPIAS_SEMANA := 2

## [icono, nombre, texto, hashtags sugeridos, faceta, efecto en la faceta,
##  efecto en el ánimo de la hinchada, gancho (multiplica los me gusta),
##  riesgo de polémica 0..1]
const TIPOS := {
	"entreno": ["📸", "Foto del entrenamiento", "Semana de trabajo. Así se prepara el próximo partido.", ["#Trabajo", "#Equipo"], "mediatico", 1, 0, 1.0, 0.0],
	"hinchada": ["🙌", "Mensaje a la hinchada", "Gracias por empujar siempre. Esto es de todos.", ["#Hinchada", "#Juntos"], "social", 1, 2, 1.2, 0.0],
	"victoria": ["🥳", "Celebrar el resultado", "¡Qué partido! Orgulloso de este grupo.", ["#DíaDePartido", "#Victoria"], "mediatico", 1, 1, 1.5, 0.0],
	"familia": ["👨‍👩‍👧", "Foto en familia", "Domingo en casa. Lo más importante.", ["#Familia", "#Descanso"], "social", 1, 0, 1.3, 0.0],
	"cantera": ["🌱", "Apoyo a la cantera", "Los chicos de la academia vienen pisando fuerte.", ["#Cantera", "#Futuro"], "formador", 1, 1, 0.9, 0.0],
	"indirecta": ["🌶️", "Indirecta al rival", "Algunos hablan mucho. Nosotros, en la cancha.", ["#SinExcusas"], "mediatico", 2, 1, 1.8, 0.35],
}
## [icono, nombre, texto de la respuesta, faceta, efecto, riesgo]
const RESPUESTAS := {
	"agradecer": ["🙏", "Agradecer", "¡Gracias por el apoyo!", "social", 1, 0.0],
	"broma": ["😄", "Con humor", "Jaja, tranquilo, que el domingo lo arreglamos.", "mediatico", 1, 0.0],
	"explicar": ["🗒️", "Explicar", "Entiendo la bronca. Estamos trabajando para corregirlo.", "honesto", 1, 0.0],
	"picante": ["🔥", "Contestar picante", "Opinar desde el sofá es fácil.", "mediatico", 1, 0.3],
}
const FANS := ["@hinchadefierro", "@tactica_pura", "@la_grada_habla", "@cronista_del_ascenso",
	"@datosyfutbol", "@elcorner_de_ana", "@puro_barrio_fc", "@mister_de_sofa", "@vozdelsocio",
	"@periodistadeturno", "@abuela_futbolera", "@memesdelgol", "@sub17_para_siempre", "@la_pizarra_rota"]
const COMENTARIOS_BIEN := ["¡Vamos, míster! 🔥", "Esto es lo que queríamos ver.", "Hay proyecto.", "Qué orgullo este equipo.", "Me tapo la boca: tenía razón."]
const COMENTARIOS_MAL := ["Así no, míster.", "Explícame los cambios 🙄", "Hay que dar explicaciones.", "Con esto no alcanza.", "¿Y el plan B?"]
const COMENTARIOS_NEUTROS := ["A ver en qué termina.", "Ojo con esto.", "Se viene debate.", "Buena foto.", "¿Y el refuerzo para cuándo?"]

var cuentas := {
	"dt": {"usuario": "@mister", "nombre": "Míster", "seguidores": 800},
	"club": {"usuario": "@club_oficial", "nombre": "Club", "seguidores": 5000},
}
var publicaciones: Array[Dictionary] = []   ## de la más nueva a la más vieja
var tendencia := "#DíaDePartido"
var _siguiente_id := 1
var _propias_semana := 0
var _semana_propias := -1
var _rng := RandomNumberGenerator.new()

## Pone nombre a las dos cuentas según tu DT y tu club. Se puede volver a
## llamar (cambio de club): la cuenta del club pasa a ser la del nuevo.
func iniciar(m: Mundo) -> void:
	_rng.seed = hash("redes|%d" % m.anio)
	var nom := m.roles.nombre if m.roles != null else "Míster"
	cuentas["dt"]["nombre"] = nom
	cuentas["dt"]["usuario"] = "@" + usuario_de(nom)
	var c := m.mi_club()
	if c != null and String(cuentas["club"]["nombre"]) != c.nombre:
		cuentas["club"]["nombre"] = c.nombre
		cuentas["club"]["usuario"] = "@" + usuario_de(c.nombre) + "_oficial"
		cuentas["club"]["seguidores"] = seguidores_base_club(c)

static func usuario_de(nombre: String) -> String:
	var s := nombre.to_lower().strip_edges()
	for par: Array in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ü", "u"], ["ñ", "n"], [" ", "_"], [".", ""], ["'", ""]]:
		s = s.replace(String(par[0]), String(par[1]))
	return s

static func seguidores_base_club(c: Club) -> int:
	return int(round(pow(float(maxi(c.rep, 10)), 2.2) * 6.0))

## El hashtag del club: #Vamos + su nombre sin espacios.
static func hashtag_club(c: Club) -> String:
	if c == null:
		return "#VamosClub"
	return "#Vamos" + c.nombre.replace(" ", "").replace(".", "")

# --- publicar -------------------------------------------------------------------

func puede_publicar(m: Mundo) -> String:
	var clave := m.anio * 100 + m.semana
	if _semana_propias != clave:
		return ""
	if _propias_semana >= MAX_PROPIAS_SEMANA:
		return "ya publicaste %d veces esta semana: más sería llenar de ruido tu cuenta" % MAX_PROPIAS_SEMANA
	return ""

## Publica desde tu cuenta. Devuelve la publicación, o {"error": motivo}.
func publicar(m: Mundo, tipo: String, hashtags: Array) -> Dictionary:
	if not TIPOS.has(tipo):
		return {"error": "no existe ese tipo de publicación"}
	var no := puede_publicar(m)
	if no != "":
		return {"error": no}
	var clave := m.anio * 100 + m.semana
	if _semana_propias != clave:
		_semana_propias = clave
		_propias_semana = 0
	_propias_semana += 1
	var t: Array = TIPOS[tipo]
	var segs := int(cuentas["dt"]["seguidores"])
	var gancho := float(t[7])
	if tendencia in hashtags:
		gancho *= 1.25
	var likes := int(round(float(segs) * _rng.randf_range(0.03, 0.09) * gancho)) + _rng.randi_range(3, 20)
	var p := _nueva("dt", String(t[2]), hashtags, tipo, m)
	p["likes"] = likes
	p["compartidos"] = int(likes * _rng.randf_range(0.05, 0.18))
	## Los seguidores nuevos que trae la publicación.
	cuentas["dt"]["seguidores"] = segs + int(likes * 0.08)
	## El efecto: la faceta de tu reputación y el ánimo de la grada.
	if m.roles != null and int(t[5]) != 0:
		m.roles.anotar_reputacion(String(t[4]), int(t[5]), "Redes: %s" % String(t[1]).to_lower())
	if m.prensa != null and int(t[6]) != 0:
		m.prensa.animo = clampi(m.prensa.animo + int(t[6]), 0, 100)
	var polemica := _rng.randf() < float(t[8])
	p["polemica"] = polemica
	## Los comentarios de los hinchas.
	var tono := "mal" if polemica else ("bien" if m.prensa == null or m.prensa.animo >= 50 else "")
	_comentar(p, _rng.randi_range(3, 5), tono)
	if polemica:
		if m.roles != null:
			m.roles.anotar_reputacion("honesto", -2, "Polémica en redes")
		noticia.emit("🌶️ Polémica en redes", "Tu publicación «%s» encendió la discusión: %d comentarios y la prensa ya habla del tema." % [String(t[2]).substr(0, 40), (p["comentarios"] as Array).size()])
	return p

## Responde un comentario de una publicación TUYA.
func responder(m: Mundo, pub_id: int, idx: int, tono: String) -> String:
	var p := buscar(pub_id)
	if p.is_empty() or not RESPUESTAS.has(tono):
		return "no se encontró el comentario"
	var cs: Array = p["comentarios"]
	if idx < 0 or idx >= cs.size():
		return "no se encontró el comentario"
	var c: Dictionary = cs[idx]
	if String(c.get("respuesta", "")) != "":
		return "ya le respondiste"
	var r: Array = RESPUESTAS[tono]
	c["respuesta"] = String(r[2])
	c["tono_respuesta"] = tono
	var faceta := String(r[3])
	var delta := int(r[4])
	## Explicarle algo a quien critica suma juego limpio; a quien te apoya, poco.
	if tono == "explicar" and String(c.get("tono", "")) != "mal":
		delta = 0
	if m.roles != null and delta != 0:
		m.roles.anotar_reputacion(faceta, delta, "Redes: respondiste %s" % String(r[1]).to_lower())
	if tono == "picante" and _rng.randf() < float(r[5]):
		if m.roles != null:
			m.roles.anotar_reputacion("honesto", -1, "Discusión con un hincha en redes")
		if m.prensa != null:
			m.prensa.animo = clampi(m.prensa.animo - 2, 0, 100)
		c["respuesta_likes"] = _rng.randi_range(200, 900)
		return "Tu respuesta se hizo viral… y no para bien. La grada se enoja un poco."
	c["respuesta_likes"] = _rng.randi_range(5, 80)
	if tono == "agradecer" and m.prensa != null and String(c.get("tono", "")) == "bien":
		m.prensa.animo = clampi(m.prensa.animo + 1, 0, 100)
	return "Respondiste a %s." % String(c["autor"])

## Me gusta (o lo quitas) en cualquier publicación.
func me_gusta(pub_id: int) -> bool:
	var p := buscar(pub_id)
	if p.is_empty():
		return false
	var ya := bool(p.get("me_gusta_tuyo", false))
	p["me_gusta_tuyo"] = not ya
	p["likes"] = int(p["likes"]) + (-1 if ya else 1)
	return not ya

func buscar(pub_id: int) -> Dictionary:
	for p: Dictionary in publicaciones:
		if int(p["id"]) == pub_id:
			return p
	return {}

func de_cuenta(cuenta: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: Dictionary in publicaciones:
		if String(p["cuenta"]) == cuenta:
			out.append(p)
	return out

## Comentarios sin responder en tus publicaciones (el globito del móvil).
func pendientes() -> int:
	var n := 0
	for p: Dictionary in publicaciones:
		if String(p["cuenta"]) != "dt":
			continue
		for c: Dictionary in p["comentarios"]:
			if String(c.get("respuesta", "")) == "":
				n += 1
	return n

# --- lo que pasa solo -------------------------------------------------------------

## Una noticia del juego → la publica la cuenta del club (si es suya) y un
## hincha opina. Lo llama la interfaz cuando anota una noticia.
func desde_noticia(m: Mundo, titulo: String, cuerpo: String) -> void:
	var bueno := titulo.contains("✅") or titulo.contains("🏆") or titulo.to_lower().contains("gana") or titulo.to_lower().contains("campe")
	var malo := titulo.contains("❌") or titulo.to_lower().contains("pierde") or titulo.to_lower().contains("elimin") or titulo.to_lower().contains("lesi")
	var tono := "bien" if bueno else ("mal" if malo else "")
	var c := m.mi_club()
	var tags: Array = [hashtag_club(c)]
	if bueno or malo:
		tags.append("#DíaDePartido")
	## La cuenta oficial solo cuenta lo que es del club (resultados, títulos).
	if bueno or malo or titulo.contains("🏗") or titulo.contains("✍"):
		var p := _nueva("club", "%s %s" % [titulo, cuerpo.substr(0, 120)], tags, "partido" if (bueno or malo) else "club", m)
		var segs := int(cuentas["club"]["seguidores"])
		p["likes"] = int(round(float(segs) * _rng.randf_range(0.01, 0.04) * (1.6 if bueno else 0.8)))
		p["compartidos"] = int(int(p["likes"]) * _rng.randf_range(0.04, 0.12))
		_comentar(p, _rng.randi_range(2, 4), tono)
	## Y un hincha lo comenta por su cuenta.
	var reacciones: Array = COMENTARIOS_BIEN if tono == "bien" else (COMENTARIOS_MAL if tono == "mal" else COMENTARIOS_NEUTROS)
	var f := _nueva("fan", "%s %s" % [String(reacciones[_rng.randi() % reacciones.size()]), titulo.substr(0, 60)], tags, "opinion", m)
	f["autor"] = FANS[_rng.randi() % FANS.size()]
	f["likes"] = _rng.randi_range(10, 400)
	f["compartidos"] = _rng.randi_range(0, 40)
	_comentar(f, _rng.randi_range(0, 2), tono)

## Cada semana: los seguidores se mueven y cambia la tendencia.
func semana(m: Mundo) -> void:
	var c := m.mi_club()
	if c != null:
		var obj := seguidores_base_club(c)
		var segs := int(cuentas["club"]["seguidores"])
		## Se acercan poco a poco a lo que "le toca" por reputación, más un
		## crecimiento natural pequeño.
		cuentas["club"]["seguidores"] = segs + int((obj - segs) * 0.05) + int(segs * 0.002)
	var fama := 50
	if m.roles != null and m.roles.reputacion != null:
		fama = m.roles.reputacion.valor("mediatico")
	var dt := int(cuentas["dt"]["seguidores"])
	cuentas["dt"]["seguidores"] = maxi(100, dt + int(dt * (float(fama) - 45.0) / 4000.0) + _rng.randi_range(0, 12))
	var tags := ["#DíaDePartido", "#Hinchada", "#Cantera", "#Trabajo", "#Familia", hashtag_club(c)]
	tendencia = String(tags[(m.semana + m.anio) % tags.size()])

func _nueva(cuenta: String, texto: String, hashtags: Array, tipo: String, m: Mundo) -> Dictionary:
	var p := {"id": _siguiente_id, "cuenta": cuenta,
		"autor": String(cuentas[cuenta]["usuario"]) if cuentas.has(cuenta) else "",
		"texto": texto, "hashtags": hashtags.duplicate(), "tipo": tipo,
		"likes": 0, "compartidos": 0, "comentarios": [], "anio": m.anio, "semana": m.semana}
	_siguiente_id += 1
	publicaciones.push_front(p)
	if publicaciones.size() > MAX_PUBLICACIONES:
		publicaciones.resize(MAX_PUBLICACIONES)
	return p

func _comentar(p: Dictionary, n: int, tono: String) -> void:
	for i in n:
		## Una de cada cuatro opiniones va a la contra, siempre: nunca hay
		## unanimidad en redes.
		var t := tono
		if _rng.randf() < 0.25:
			t = "mal" if tono == "bien" else ("bien" if tono == "mal" else ["bien", "mal"][_rng.randi() % 2])
		var lista: Array = COMENTARIOS_BIEN if t == "bien" else (COMENTARIOS_MAL if t == "mal" else COMENTARIOS_NEUTROS)
		(p["comentarios"] as Array).append({"autor": FANS[_rng.randi() % FANS.size()],
			"texto": String(lista[_rng.randi() % lista.size()]), "tono": t, "respuesta": ""})

# --- guardar ----------------------------------------------------------------------

func a_dic() -> Dictionary:
	return {"cuentas": cuentas.duplicate(true), "pubs": publicaciones.duplicate(true), "tend": tendencia,
		"sig": _siguiente_id, "ps": _propias_semana, "sp": _semana_propias}

func desde_dic(d: Dictionary) -> void:
	if d.is_empty():
		return
	cuentas = (d.get("cuentas", cuentas) as Dictionary).duplicate(true)
	publicaciones.clear()
	for p: Variant in d.get("pubs", []):
		publicaciones.append((p as Dictionary).duplicate(true))
	tendencia = String(d.get("tend", tendencia))
	_siguiente_id = int(d.get("sig", 1))
	_propias_semana = int(d.get("ps", 0))
	_semana_propias = int(d.get("sp", -1))
