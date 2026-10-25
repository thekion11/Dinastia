extends BaseIdea
## LA RED SOCIAL Y MI VIDA, EN LOS 9 IDIOMAS (25-10-2026, paquete uite). Todo lo que el móvil enseña
## sale de los catálogos de `Redes` (tipos de publicación, respuestas, comentarios de la hinchada, lo
## que publican los jugadores) y de unas pocas frases de la interfaz: cada una tiene que cambiar al
## pasar por `Idiomas.t` en los 8 idiomas que no son el castellano.

const IDIOMAS := ["en", "pt", "fr", "it", "de", "ca", "pl", "tr"]
## Lo que en ese idioma se escribe igual que en castellano (es la traducción correcta, no un olvido).
const IGUALES := {"Indirecta al rival": ["ca"], "maestro": ["it"], "pupilo": ["pt"],
	"💪 Joaquín Campos (moral +3).": ["pt", "fr", "ca", "tr"], "Agradecer": ["pt"], "Explicar": ["pt", "ca"],
	"seguidores": ["pt"], "Publicar": ["pt", "ca"], "Tranquilo": ["pt"], "Comentado.": ["pt"], "Transporte público": ["pt"]}

func _probar() -> void:
	_titulo("RED SOCIAL Y MI VIDA EN 9 IDIOMAS (uite)")
	var frases: Array[String] = []
	for d: Array in Redes.TIPOS.values():
		frases.append_array([String(d[1]), String(d[2])])
	for d: Array in Redes.TIPOS_CLUB.values():
		frases.append_array([String(d[1]), String(d[2])])
	for d: Array in Redes.RESPUESTAS.values():
		frases.append_array([String(d[1]), String(d[2])])
	for d: Array in Redes.COMENTAR_JUGADOR.values():
		frases.append_array([String(d[1]), String(d[2])])
	for lista: Array in Redes.PUBLICA_JUGADOR.values():
		for d: Array in lista:
			frases.append(String(d[1]))
	for c: String in Redes.COMENTARIOS_BIEN + Redes.COMENTARIOS_MAL + Redes.COMENTARIOS_NEUTROS:
		frases.append(c)
	for d: Array in Politica.POSTURAS.values():
		frases.append_array([String(d[0]), String(d[1])])
	for tabla: Dictionary in [VidaDT.OCIO, VidaDT.VIVIENDAS, VidaDT.TRANSPORTES]:
		for d: Array in tabla.values():
			frases.append(String(d[0]))
	frases.append_array(["maestro", "pupilo", "publicaciones", "seguidores", "siguiendo", "en línea",
		"⚽ tu plantel", "Nueva publicación", "Nueva publicación del club", "Efecto: ánimo de la grada %+d",
		" · vende en la tienda", "Efecto: %s %+d", ", ánimo de la grada %+d", " · ⚠️ puede hacerse polémica",
		"✔ Publicado: %s me gusta en el primer rato.", "✔ Sesión iniciada: %s", "Todavía no hay nada.",
		"Publica algo desde ➕ y empezará la conversación.", "Inicio", "Tu perfil", "Cuenta del club", "Publicar",
		"Preparación de partidos +%.1f%%", "Estrés", "Trabajo", "Familia", "Tranquilo", "Cargado",
		"Al límite: el vestuario lo nota", "⚖️ EQUILIBRIO VIDA / TRABAJO",
		## Los motivos del núcleo, como los enseña el aviso (`_frase`: mayúscula y punto).
		"Clave incorrecta.", "No existe ese usuario.", "Esa cuenta no es tuya: la lleva el community manager del club.",
		"Tu respuesta se hizo viral… y no para bien. La grada se enoja un poco.", "Comentado.",
		"Respondiste a @vozdelsocio.", "💪 Joaquín Campos (moral +3).",
		"Ya publicaste 2 veces esta semana: más sería llenar de ruido tu cuenta.",
		"La cuenta del club ya publicó 3 veces esta semana.", "No tienes acceso a la cuenta del club.",
		"No existe ese tipo de publicación.", "No hay ninguna sesión abierta."])
	var malas: Array[String] = []
	for f: String in frases:
		var faltan: Array[String] = []
		for idi: String in IDIOMAS:
			if idi in IGUALES.get(f, []):
				continue
			Idiomas.idioma = idi
			if Idiomas.t(f) == f:
				faltan.append(idi)
		if not faltan.is_empty():
			malas.append("%s [%s]" % [f, ",".join(faltan)])
	Idiomas.idioma = "es"
	for x in malas:
		_linea("    sin traducir: " + x)
	_comprobar(malas.is_empty(), "las %d frases de la red y de Mi vida están en los 9 idiomas (%d faltan)" % [frases.size(), malas.size()])
