class_name AvisoOnce
extends RefCounted
## ALERTA DE ALINEACIÓN INVÁLIDA (01-11-2026, fase 4 «jugabilidad», idea 1036 «verificar jugando»). Si el once que eligió el
## entrenador tiene a alguien lesionado, sancionado o que ya no está en el club, `Club.once()` lo cambia EN SILENCIO por el
## automático. Ahora, antes de jugar la jornada, el juego avisa de quién falla y de que saldrá el once automático.

## «» si el once elegido vale (o no hay once elegido); si no, el texto del aviso (ya traducido).
static func motivo(c: Club) -> String:
	if c == null or c.once_elegido.size() != 11:
		return ""
	var malos: Array[String] = []
	for id in c.once_elegido:
		var j: Jugador = null
		for q: Jugador in c.plantilla:
			if q.id == id:
				j = q
				break
		if j == null:
			malos.append(Idiomas.t("un jugador que ya no está en el club"))
		elif j.lesion > 0:
			malos.append(Idiomas.t("%s (lesionado)") % j.nombre)
		elif j.suspension > 0:
			malos.append(Idiomas.t("%s (sancionado)") % j.nombre)
	if malos.is_empty():
		return ""
	return Idiomas.t("En tu once elegido no puede jugar: %s. Saldrá el once automático si no lo cambias.") % ", ".join(malos)
