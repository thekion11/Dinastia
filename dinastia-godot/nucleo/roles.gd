class_name Roles
extends "res://nucleo/roles_p4.gd"
## (Parte 5 de 5 de `roles.gd`.)

## `bonusReputacion()` DEL HTML, LAS DOS PARTES QUE FALTABAN (10-9-2026).
## La de cantera ya estaba portada (`Cantera.multiplicador_de_reputacion()`,
## `1+(rep-50)*0.005`); estas dos no existían en ningún sitio, así que el
## prestigio del entrenador no ayudaba a fichar ni a vender la camiseta, que
## es justo lo que la card "⭐ BONUS POR REPUTACIÓN" del HTML promete.
## La cuarta parte del HTML (`.sueldo`) no se porta: allí es código muerto,
## se calcula y se muestra pero nada la usa.

## Lo que el prestigio suma a las ganas de venir de un jugador: `fichajes-1`
## del HTML, que `deseoDeVenir()` SUMA a la probabilidad. A prestigio 99 son
## +0,29; a prestigio 20, -0,18.
func bono_reputacion_fichajes() -> float:
	return float(prestigio - 50) * 0.006 + reputacion.bono_fichajes()

## Lo que el prestigio multiplica en las ofertas de marcas y de zonas
## publicitarias -`generarSponsorOfertas()` y `generarOfertasZona()` del
## HTML-. NO toca el patrocinio semanal genérico de `Finanzas`: en el HTML
## tampoco lo toca.
func multiplicador_sponsor() -> float:
	## Prestigio, faceta mediática y el nivel del club (patrocinadores premium).
	var m := _mundo()
	var rep_club: int = m.mi_club().rep if m != null and m.mi_club() != null else 50
	return (1.0 + float(prestigio - 50) * 0.004) * reputacion.mult_marcas() * Reputacion.mult_patrocinio(rep_club)

func tiene(clave: String) -> bool:
	if clave == "licB":
		return licencia >= 1
	if clave == "licA":
		return licencia >= 2
	if clave == "licPro":
		return licencia >= 3
	return bienes.has(clave)

## Compra algo para ti. Devuelve "" si se hizo, o el motivo por el que no.
func comprar_dt(clave: String) -> String:
	var it: Array = []
	for f: Array in COMPRAS_DT:
		if String(f[0]) == clave:
			it = f
	if it.is_empty():
		return "eso no existe"
	if tiene(clave):
		return "ya lo tienes"
	## Las licencias van en orden: no hay atajo a la PRO.
	if clave == "licA" and licencia < 1:
		return "primero necesitas la licencia B"
	if clave == "licPro" and licencia < 2:
		return "primero necesitas la licencia A"
	var coste := int(it[2])
	if patrimonio < coste:
		return "tu patrimonio no alcanza: cuesta %s" % Cesiones.dinero(coste)
	patrimonio -= coste
	var m := _mundo()
	match clave:
		"licB": licencia = 1
		"licA": licencia = 2
		"licPro": licencia = 3
		_: bienes[clave] = true
	## Los puntos del árbol: es lo que convierte invertir en ti en algo que se
	## nota en el campo la semana siguiente.
	var puntos := 2 if clave == "licPro" else 1
	if m != null and m.entrenamiento != null:
		m.entrenamiento.dt_sumar_puntos(puntos)
	aviso.emit("Inversión en tu carrera", "%s. %s" % [String(it[1]), String(it[3])])
	return ""

## El pulso semanal del bolsillo: cobras, y cada diez semanas de trabajo ganas un
## punto de habilidad. Lo llama `Mundo`.
func semana_patrimonio() -> void:
	patrimonio += sueldo_semanal()
	semanas_trabajadas += 1
	if semanas_trabajadas % 10 == 0:
		var m := _mundo()
		if m != null and m.entrenamiento != null:
			m.entrenamiento.dt_sumar_puntos(1)

## Busca rival si todavía no hay. Lo llama el pulso semanal: la rivalidad la
## calienta `Logros`, aquí solo se le pone cara y nombre al de enfrente.
func buscar_rival_dt() -> void:
	if not rival_dt.is_empty():
		return
	var m := _mundo()
	if m == null or m.logros == null or m.mi_club() == null:
		return
	var mejor_id := ""
	var mejor_calor := 0
	for f: Dictionary in m.logros.rivalidades():
		var c: Club = f.get("club")
		if c == null or c == m.mi_club():
			continue
		if int(f.get("valor", 0)) > mejor_calor:
			mejor_calor = int(f.get("valor", 0))
			mejor_id = c.id
	if mejor_id == "" or mejor_calor < CALOR_PARA_RIVAL:
		return
	var c2: Club = m.clubes.get(mejor_id)
	if c2 == null:
		return
	var d := Previa.dt_de(c2)
	rival_dt = {
		"club_id": c2.id, "nombre": String(d.get("nombre", "")),
		"estilo": String(d.get("descripcion", "")),
		"pj": 0, "g": 0, "e": 0, "p": 0, "tension": 50, "desde": m.anio,
	}
	noticia_carrera.emit("Tienes un rival personal",
		"La prensa ya lo llama duelo: %s contra %s. Cada vez que se crucen, se hablará más de ustedes dos que del partido." % [
			nombre, String(rival_dt["nombre"])])

## Un cruce contra él. Devuelve true si el duelo se salió de la cancha.
func registrar_duelo(rival_id: String, gane: bool, empate: bool) -> bool:
	if rival_dt.is_empty() or String(rival_dt["club_id"]) != rival_id:
		return false
	rival_dt["pj"] = int(rival_dt["pj"]) + 1
	if gane:
		rival_dt["g"] = int(rival_dt["g"]) + 1
		rival_dt["tension"] = clampi(int(rival_dt["tension"]) + 8, 0, 100)
	elif empate:
		rival_dt["e"] = int(rival_dt["e"]) + 1
		rival_dt["tension"] = clampi(int(rival_dt["tension"]) + 3, 0, 100)
	else:
		rival_dt["p"] = int(rival_dt["p"]) + 1
		rival_dt["tension"] = clampi(int(rival_dt["tension"]) + 10, 0, 100)
	if int(rival_dt["tension"]) < TENSION_QUE_ESTALLA or not Azar.suerte(0.4):
		return false
	## Y cuando estalla, se paga en prestigio: ganar el duelo caliente vale el
	## triple que ganar un partido, y perderlo también se nota.
	prestigio = clampi(prestigio + (3 if gane else -1), 0, 100)
	rival_dt["tension"] = 60
	noticia_carrera.emit("El duelo se sale de la cancha",
		"Tú y %s os cruzasteis en el túnel. Los micrófonos lo cogieron todo y mañana no se hablará de otra cosa." % String(rival_dt["nombre"]))
	return true

func nombrar_leyenda_viva(j: Jugador) -> String:
	if not leyenda_viva.is_empty():
		return "%s ya es la leyenda viva del club" % String(leyenda_viva["nombre"])
	if j == null:
		return "no hay a quién nombrar"
	var m := _mundo()
	leyenda_viva = {
		"nombre": Nombres.visible(j.nombre), "pos": j.pos_e,
		"desde": m.anio if m != null else 0, "visitas": 0,
	}
	if m != null and m.prensa != null:
		m.prensa.mover_animo(8)
	noticia_carrera.emit("Leyenda viva del club",
		"%s queda ligado al club de por vida. Vendrá a los entrenamientos, hablará con los chicos y estará en cada acto. La gente lo va a agradecer." % String(leyenda_viva["nombre"]))
	return ""

## Cada seis semanas se sienta con un chico. Es de los pocos sistemas del juego
## cuyo efecto es tan pequeño que casi no se ve en la ficha, y esa es la idea:
## "estas cosas no salen en ninguna estadística".
func semana_leyenda_viva() -> void:
	if leyenda_viva.is_empty():
		return
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return
	leyenda_viva["visitas"] = int(leyenda_viva["visitas"]) + 1
	if int(leyenda_viva["visitas"]) % 6 != 0:
		return
	var jovenes: Array[Jugador] = []
	for j: Jugador in m.mi_club().plantilla:
		if j.edad <= 21:
			jovenes.append(j)
	if not jovenes.is_empty():
		var chico: Jugador = jovenes[Azar.ent(0, jovenes.size() - 1)]
		chico.cambiar_moral(Azar.ent(4, 9), "Directiva")
		if Azar.suerte(0.25) and chico.ovr < chico.pot:
			chico.ajustar_media(1)
		if Azar.suerte(0.3):
			noticia_carrera.emit("Charla de la leyenda",
				"%s se quedó una hora hablando con %s después del entrenamiento. Estas cosas no salen en ninguna estadística." % [
					String(leyenda_viva["nombre"]), chico.nombre])
	if m.prensa != null:
		m.prensa.mover_animo(1)

func precio_filial(c: Club) -> int:
	return int(round(Eco.ref_caja(float(c.rep)) * PRECIO_FILIAL))

func mi_club_id_actual() -> String:
	var m := _mundo()
	return m.mi_club_id if m != null else ""

func comprar_filial(c: Club) -> String:
	var m := _mundo()
	if m == null or m.entrenamiento == null or not m.entrenamiento.puede_comprar_filiales():
		return "hace falta la habilidad «Magnate» del árbol de entrenador"
	if c == null:
		return "ese club no existe"
	if c.id == mi_club_id_actual():
		return "no puedes comprar el club que diriges"
	if filiales.has(c.id):
		return "ya es tuyo"
	var precio := precio_filial(c)
	if patrimonio < precio:
		return "te faltan %s de patrimonio personal" % Cesiones.dinero(precio - patrimonio)
	patrimonio -= precio
	filiales.append(c.id)
	noticia_carrera.emit("Compraste un club",
		"Adquiriste el control de %s por %s. Ahora es tu club filial: recibes dividendos cada tres meses." % [
			c.nombre, Cesiones.dinero(precio)])
	return ""

## Los dividendos, cada doce semanas. Salen del tamaño del club: un filial grande
## renta mucho más, que es exactamente por lo que se paga por él.
func semana_filiales() -> void:
	if filiales.is_empty():
		return
	var m := _mundo()
	if m == null or m.semana % SEMANAS_DIVIDENDO != 0:
		return
	var total := 0
	for cid: String in filiales:
		var c: Club = m.clubes.get(cid)
		if c != null:
			total += c.rep * c.rep * 40
	if total <= 0:
		return
	patrimonio += total
	noticia_carrera.emit("Dividendos de tus clubes",
		"Tus participaciones te dejaron %s de patrimonio personal." % Cesiones.dinero(total))

func candidatos_sucesion() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	var m := _mundo()
	if m == null:
		return salida
	## Tu ayudante: conoce el vestuario mejor que nadie y por eso le dan el
	## margen más largo.
	if m.staff != null and m.staff.nivel("at") > 0:
		salida.append({"tipo": "ayudante", "nombre": "Tu ayudante técnico",
			"desc": "Conoce el vestuario mejor que nadie.", "margen": 14})
	if not leyenda_viva.is_empty():
		salida.append({"tipo": "leyenda", "nombre": String(leyenda_viva["nombre"]),
			"desc": "Leyenda del club. La gente lo idolatra, pero nunca ha dirigido.", "margen": 8})
	## Un canterano tuyo ya retirado.
	if m.cantera != null and not m.cantera.leyendas.is_empty():
		var ultima: Dictionary = m.cantera.leyendas[m.cantera.leyendas.size() - 1]
		salida.append({"tipo": "exjugador", "nombre": String(ultima.get("nombre", "")),
			"desc": "Ex jugador de tu era. Quiere devolver lo que recibió.", "margen": 10})
	salida.append({"tipo": "externo", "nombre": _nombre_de_persona(),
		"desc": "Nombre de fuera con cartel. Traerá su propia gente y su propia idea.", "margen": 18})
	return salida

func elegir_sucesor(i: int) -> String:
	var lista := candidatos_sucesion()
	if i < 0 or i >= lista.size():
		return "ese candidato no existe"
	sucesor = lista[i]
	noticia_carrera.emit("Sucesión resuelta",
		"Dejas el club en manos de %s. %s El directorio le da un margen de %d partidos." % [
			String(sucesor["nombre"]), String(sucesor["desc"]), int(sucesor["margen"])])
	return ""

func mover_desgaste(d: int) -> void:
	desgaste = clampi(desgaste + d, 0, 100)

func quemado() -> bool:
	return desgaste >= DESGASTE_ALTO

## Cuánto le resta el desgaste a lo que consigues en una rueda de prensa. Con la
## cabeza fundida, lo que dices sale peor: es el único efecto y es suficiente.
func factor_desgaste() -> float:
	if not quemado():
		return 1.0
	return 0.6

## El pulso semanal del desgaste. Lo llama `Mundo` junto al resto.
func semana_desgaste(gano_algo: bool, funa: int) -> void:
	## Una semana en el cargo cansa un poco. Ganar descansa; la funa quema.
	var d := 1
	if gano_algo:
		d -= 3
	d += 1 if funa > 50 else 0
	d += 1 if funa > 75 else 0
	mover_desgaste(d)

## Se cierra el capítulo de un club y se abre otro. Lo llama `tomar_el_mando()`
## cuando ya había un club antes: es lo que convierte una partida larga en una
## CARRERA y no en una sucesión de clubes sin memoria.
func cerrar_capitulo(club_id: String, nombre_club: String, anio: int, motivo: String) -> void:
	if club_id == "":
		return
	for c: Dictionary in curriculum:
		if String(c.get("club", "")) == club_id and int(c.get("hasta", 0)) == 0:
			c["hasta"] = anio
			c["motivo"] = motivo
			c["trofeos"] = trofeos.size()
			return

func abrir_capitulo(club_id: String, nombre_club: String, anio: int) -> void:
	if club_id == "":
		return
	curriculum.append({
		"club": club_id, "nombre": nombre_club, "desde": anio, "hasta": 0,
		"trofeos": 0, "motivo": "",
	})
	## El parón entre clubes descansa: llegar a un sitio nuevo con la cabeza
	## despejada es de las pocas cosas buenas de que te echen.
	desgaste = maxi(0, desgaste - 35)

## Sortea si alguien llama. Devuelve la oferta, o vacío.
func sortear_oferta_de_club() -> Dictionary:
	var m := _mundo()
	if m == null or not oferta_de_club.is_empty():
		return {}
	if m.semana - _ultima_oferta < SEMANAS_ENTRE_OFERTAS:
		return {}
	var mio := m.mi_club()
	if mio == null or prestigio < PRESTIGIO_PARA_OFERTA:
		return {}
	if not Azar.suerte(0.06):
		return {}
	## Los que podrían quererte: mejores que el tuyo, pero no tanto como para
	## que sea absurdo. Un 96 no llama a un entrenador de 60 de prestigio.
	var candidatos: Array[Club] = []
	for c: Club in m.clubes.values():
		if c.id == mio.id:
			continue
		if c.rep > mio.rep and c.rep <= mio.rep + 14 and c.rep <= prestigio + 30:
			candidatos.append(c)
	if candidatos.is_empty():
		return {}
	_ultima_oferta = m.semana
	var elegido: Club = candidatos[Azar.ent(0, candidatos.size() - 1)]
	oferta_de_club = {
		"club_id": elegido.id, "nombre": elegido.nombre,
		"mejora": elegido.rep - mio.rep,
		"sueldo": Eco.escalar(9000.0 * (0.6 + float(prestigio) / 100.0), float(elegido.rep)),
	}
	return oferta_de_club

## Aceptar es irse: se cierra el capítulo de este club y se abre el del otro.
## Rechazar tampoco es gratis —la directiva se entera de que te llamaron— pero
## sube la confianza: quedarse habiendo podido irse se agradece.
func responder_oferta_de_club(acepta: bool) -> String:
	if oferta_de_club.is_empty():
		return "no hay ninguna oferta sobre la mesa"
	var m := _mundo()
	var nombre := String(oferta_de_club["nombre"])
	var destino := String(oferta_de_club["club_id"])
	oferta_de_club = {}
	if not acepta:
		if m != null and m.directiva != null:
			m.directiva.mover_confianza(4, "rechazar una oferta de otro club")
		return "Dices que no a %s. En el club se enteran, y se agradece." % nombre
	if m != null:
		m.tomar_el_mando(destino)
	return "Te vas a %s. Capítulo cerrado; empieza otro." % nombre

## Para que otros sistemas (mercado, prensa, cantera) anoten lo suyo.
func anotar_reputacion(faceta: String, delta: int, motivo: String) -> void:
	_rep(faceta, delta, motivo)
