extends BaseIdea
## s3 (26-10-2026): TEXTOS DEL NÚCLEO CON CLAVES ESTABLES (petición 7 de la sesión 2) y el icono de
## delante con varias oraciones (petición 2). MesaAgente, Negociacion y Movil devolvían castellano
## con las cifras dentro; ahora traducen plantillas fijas con `Idiomas.t` y después ponen las cifras o, en el
## móvil, guardan plantilla y argumentos y traducen al enseñar. Se prueba en los 8 idiomas.
const IDIOMAS := ["en", "pt", "fr", "it", "de", "ca", "pl", "tr"]
## Trozos que delatan una frase castellana sin traducir.
const CASTELLANO := ["Baja a", "Se le ", "Te levantas", "de sueldo", "Mira el reloj", "se levanta de la mesa",
	"Ni para ti", "Así no", "tomando el pelo", "de la comisión", "su chico", "exclusiva con", "prefieren",
	"No le termina", "Me voy dos semanas", "cifra fija", "más dinero", "menos bonos", "porcentaje"]

func _probar() -> void:
	_titulo("S3: TEXTOS DEL NÚCLEO CON CLAVES ESTABLES (MesaAgente, Negociacion, Movil) E ICONOS")
	var antes := Idiomas.idioma
	_mesa()
	_negociacion()
	_movil()
	_icono()
	Idiomas.idioma = antes

func _castellano(s: String) -> String:
	for c: String in CASTELLANO:
		if s.contains(c):
			return c
	return ""

## Todo lo que puede decir la mesa, en una partida entera por cada perfil y tipo.
func _textos_mesa() -> Array[String]:
	var out: Array[String] = []
	for perfil: String in MesaAgente.PERFIL:
		for tipo: String in ["mejora", "comision", "canterano", "exclusiva"]:
			for camino in 3:
				var mesa := MesaAgente.new({"tipo": tipo, "agente": "Rafa Olmo", "perfil": perfil}, 0, 0.0, 77 + camino)
				out.append(mesa.ultima)
				out.append(mesa.texto_farol())
				out.append(mesa.detalle(60))
				if camino == 1:
					out.append(mesa.farol())
				while mesa.estado == "abierta":
					out.append(mesa.regatear(5 if camino == 0 else mesa.pide - 30))
				if camino == 2:
					out.append(MesaAgente.new({"tipo": tipo, "perfil": perfil}, 0, 0.0, 5).plantarse())
	return out

func _mesa() -> void:
	Idiomas.idioma = "es"
	var es := _textos_mesa()
	var malos: Array[String] = []
	var iguales := 0
	for l: String in IDIOMAS:
		Idiomas.idioma = l
		var tr := _textos_mesa()
		for i in tr.size():
			var c := _castellano(tr[i])
			if c != "" or tr[i].contains("%d") or tr[i].contains("%s") or tr[i].contains("%%"):
				malos.append("%s: %s" % [l, tr[i]])
			if tr[i] == es[i]:
				iguales += 1
	_comprobar(malos.is_empty(), "la mesa del agente habla en los 8 idiomas, sin castellano ni restos de formato (%d mal%s)" % [
		malos.size(), (": " + malos[0]) if not malos.is_empty() else ""])
	_comprobar(es.size() > 100 and iguales == 0, "ni una frase de la mesa sale igual que en castellano (%d frases × 8; %d iguales)" % [es.size(), iguales])
	Idiomas.idioma = "es"
	var m := MesaAgente.new({"tipo": "mejora", "agente": "Rafa Olmo", "perfil": "discreto"}, 0, 0.0, 3)
	_comprobar(m.detalle(50) == "+15 % de sueldo", "en castellano sigue igual que antes («%s»)" % m.detalle(50))

func _negociacion() -> void:
	var m := _mundo(3301)
	var vendedor: Club = m.ligas[0].clubes[3]
	var j: Jugador = vendedor.plantilla[0]
	var vistos := {}
	for l: String in ["es"] + IDIOMAS:
		Idiomas.idioma = l
		var n := Negociacion.new(m, j)
		n.fijo = 1000
		var r := n.enviar_oferta()
		if String(r.get("tipo", "")) == "club_pide_mas":
			vistos[l] = String(r.get("prefiere", ""))
	Idiomas.idioma = "es"
	_comprobar(vistos.size() == 9, "una oferta baja da contraoferta en los 9 idiomas (%d)" % vistos.size())
	var bien := true
	for l: String in IDIOMAS:
		bien = bien and vistos.has(l) and String(vistos[l]) != String(vistos.get("es", "")) and _castellano(String(vistos[l])) == ""
	_comprobar(bien, "y lo que prefiere el club viene traducido del núcleo (es «%s», en «%s»)" % [vistos.get("es", ""), vistos.get("en", "")])

func _movil() -> void:
	Idiomas.idioma = "es"
	var mv := Movil.new()
	mv.recibir("Community manager", "📱", "Me voy dos semanas de vacaciones y la directiva quiere que la cuenta la lleves tú. Usuario: %s · Clave: %s · ¡Cuídamela!", 2026, 3, ["@club_fc", "Gloria42!"])
	mv.recibir("Directiva", "🏛️", "%s %s", 2026, 4, ["Presupuesto", "Sin novedades."], true)
	var es := Movil.texto(mv.mensajes[1])
	_comprobar(es.contains("Usuario: @club_fc · Clave: Gloria42!"), "en castellano el mensaje se monta con sus datos («%s»)" % es.left(60))
	var copia := Movil.new()
	copia.desde_dic(JSON.parse_string(JSON.stringify(mv.a_dic())))
	Idiomas.idioma = "en"
	var en := Movil.texto(copia.mensajes[1])
	_comprobar(en.contains("@club_fc") and en.contains("Gloria42!") and _castellano(en) == "",
		"guardado y cargado, y en inglés después: se traduce al enseñarlo («%s»)" % en.left(60))
	var ch := copia.chats()
	_comprobar(String(ch[1]["ultimo"]) == en, "el último mensaje del chat también sale traducido")
	_comprobar(Movil.texto(copia.mensajes[0]) == Idiomas.t("Presupuesto") + " " + Idiomas.t("Sin novedades."),
		"una noticia reenviada traduce su título y su cuerpo («%s»)" % Movil.texto(copia.mensajes[0]))
	Idiomas.idioma = "es"

func _icono() -> void:
	var clave := "Buenas, míster. ¿Un pan para el camino?"
	Idiomas.idioma = "en"
	var esperado := Idiomas.t(clave)
	var con := Idiomas.t("🙏 " + clave)
	_comprobar(esperado != clave and con == "🙏 " + esperado,
		"con un icono delante, una frase de varias oraciones se traduce entera («%s»)" % con)
	_comprobar(Idiomas.t("«Trato hecho.» Te da la mano sin soltarla del todo.") != "«Trato hecho.» Te da la mano sin soltarla del todo.",
		"las que empiezan con comillas siguen traduciéndose")
	Idiomas.idioma = "es"
