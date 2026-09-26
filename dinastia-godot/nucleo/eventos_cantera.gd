class_name EventosCantera
extends RefCounted
## LA CANTERA, VIVA (26-9-2026, plan maestro C11). Pedido: *"más interacción con
## la cantera, eventos de la cantera"*. La academia ya tenía chicos, captación y
## progreso semanal; lo que no tenía era VIDA: decisiones con nombre propio.
## Cada ~10 semanas pasa algo con uno de tus chicos y decides en el despacho:
##   - un TORNEO internacional sub-17 invita a la academia;
##   - un chico quiere DEJARLO para estudiar;
##   - unos PADRES exigen que su hijo suba ya al primer equipo;
##   - y, sin decisión, una CONVOCATORIA a la selección juvenil.
## Además, una vez por semana puedes VISITAR el entrenamiento: los chicos lo
## notan (un poco de nivel para todos).
## Sorteos por hash: sin `Azar`.

signal noticia(titulo: String, cuerpo: String)
signal movimiento(concepto: String, monto: int)

var pendiente: Dictionary = {}     ## {tipo, id, nombre, tema, a, b}
var ultima_visita: int = -1

static func _abs(anio: int, sem: int) -> int:
	return anio * 60 + sem

func semana(academia: Academia, c: Club, anio: int, sem: int) -> void:
	if academia == null or academia.chicos.is_empty() or not pendiente.is_empty():
		return
	var h := absi(("cantera|%s|%d|%d" % [c.id if c != null else "", anio, sem]).hash())
	if h % 10 != 0:
		return
	var ch: Dictionary = academia.chicos[(h / 10) % academia.chicos.size()]
	var nombre := String(ch["nombre"])
	match (h / 100) % 4:
		0:
			pendiente = {"tipo": "torneo", "id": ch["id"], "nombre": nombre,
				"tema": "Invitan a la academia a un torneo internacional sub-17 en el extranjero. Viajarían tus mejores chicos, con %s a la cabeza." % nombre,
				"a": "Ir al torneo (viaje y alojamiento)", "b": "Declinar la invitación"}
		1:
			pendiente = {"tipo": "abandono", "id": ch["id"], "nombre": nombre,
				"tema": "%s (%d años) quiere dejar el fútbol para centrarse en los estudios." % [nombre, int(ch["edad"])],
				"a": "Hablar con él y con su familia", "b": "Respetar su decisión"}
		2:
			pendiente = {"tipo": "padres", "id": ch["id"], "nombre": nombre,
				"tema": "Los padres de %s exigen que suba ya al primer equipo o se lo llevan a otro club." % nombre,
				"a": "Subirlo al primer equipo", "b": "Explicarles que aún no está listo"}
		_:
			ch["nivel"] = float(ch["nivel"]) + 2.0
			noticia.emit("🇺🇳 Convocatoria juvenil", "%s es convocado por la selección juvenil de su país. Vuelve con más confianza (+2 de nivel)." % nombre)

## Resuelve el asunto abierto. Devuelve {titulo, cuerpo}.
func resolver(op: String, academia: Academia, c: Club) -> Dictionary:
	if pendiente.is_empty():
		return {}
	var p := pendiente
	pendiente = {}
	var ch := academia.chico(String(p["id"])) if academia != null else {}
	var a := op == "a"
	var cuerpo := ""
	match String(p["tipo"]):
		"torneo":
			if a:
				var coste := Eco.escalar(80000.0, float(c.rep))
				c.mover_saldo(-coste)
				movimiento.emit("Torneo internacional sub-17", -coste)
				for x: Dictionary in academia.chicos:
					x["nivel"] = float(x["nivel"]) + 1.5
				cuerpo = "La academia vuelve del torneo con experiencia: todos los chicos suben un poco."
			else:
				cuerpo = "Otra vez será. Los chicos se quedan entrenando."
		"abandono":
			if a:
				## ¿Se queda? Depende de lo que prometa: los mejores tienen más a
				## qué agarrarse. Por hash, no por `Azar`.
				var queda: bool = not ch.is_empty() and (float(ch.get("nivel", 0)) >= 35.0 or absi(String(p["id"]).hash()) % 2 == 0)
				if queda:
					cuerpo = "Tras hablar con la familia, %s se queda: estudiará y entrenará a la vez." % String(p["nombre"])
				else:
					academia.chicos.erase(ch)
					cuerpo = "%s lo tiene claro y se va. Le deseas suerte." % String(p["nombre"])
			else:
				if not ch.is_empty():
					academia.chicos.erase(ch)
				cuerpo = "%s deja la academia. El club le desea lo mejor." % String(p["nombre"])
		"padres":
			if a:
				var problema := academia.entregar(String(p["id"]))
				cuerpo = ("%s sube al primer equipo. Los padres, felices; el vestuario, a ver qué tal." % String(p["nombre"])) if problema == "" else ("No se pudo subir: %s." % problema)
			else:
				if absi(String(p["id"]).hash()) % 3 == 0 and not ch.is_empty():
					academia.chicos.erase(ch)
					cuerpo = "Los padres no lo aceptan y se llevan a %s a otro club." % String(p["nombre"])
				else:
					cuerpo = "Los padres lo entienden, a regañadientes. %s sigue en la academia." % String(p["nombre"])
	var titulo := "Academia: %s" % String(p["a"] if a else p["b"])
	noticia.emit("🌱 " + titulo, cuerpo)
	return {"titulo": titulo, "cuerpo": cuerpo}

## Visitar el entrenamiento de la academia: una vez por semana.
func visitar(academia: Academia, anio: int, sem: int) -> String:
	if academia == null or academia.chicos.is_empty():
		return "La academia está vacía."
	if ultima_visita == _abs(anio, sem):
		return "Ya pasaste por la academia esta semana."
	ultima_visita = _abs(anio, sem)
	for x: Dictionary in academia.chicos:
		x["nivel"] = float(x["nivel"]) + 0.5
	noticia.emit("🌱 Visita a la academia", "Pasas la mañana con los chicos. Se nota: entrenan con otra cara.")
	return ""

func a_dic() -> Dictionary:
	return {"pendiente": pendiente, "visita": ultima_visita}

func desde_dic(d: Dictionary) -> void:
	pendiente = (d.get("pendiente", {}) as Dictionary).duplicate()
	ultima_visita = int(d.get("visita", -1))
