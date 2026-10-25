class_name EntradaCampeonato
extends RefCounted
## ENTRADA AL CAMPEONATO (MEGAPLAN, fase 1 / etapa 5 del flujo; «fase 4» del menú inicial).
## Un club recién creado no aparece de la nada en el calendario: entra de una de dos maneras, con las
## cifras que el dueño VALIDÓ el 24-10 (`docs/PLAN_DEL_LUNES.md` §2.3). Sea B el presupuesto inicial que
## tendría un club de esa división:
##
## |                        | A · REEMPLAZAR un club              | B · PAGAR a la confederación          |
## |------------------------|-------------------------------------|---------------------------------------|
## | Coste                  | ninguno                             | cuota de afiliación = 25 % de B       |
## | Presupuesto de partida | B                                   | 0,75 × B                              |
## | Reputación inicial     | la del reemplazado − 10             | la de un club recién creado − 20      |
## | División               | la del reemplazado                  | la más baja del país (+1 club)        |
## | Confianza directiva    | 60                                  | 40                                    |
## | Ánimo de la afición    | normal                              | −15 al empezar                        |
## | El otro club           | desaparece; jugadores libres        | no se toca                            |
##
## DECISIONES DE ESTA CLASE (lo que la tabla no fijaba; documentado aquí y en la pantalla):
## - B se mide sobre la liga ENTERA, no sobre un club: `Eco.ref_caja(reputación media de la liga)`,
##   la misma fórmula con la que `Mundo._crear_club()` da la caja a cada club al generar el mundo. En la
##   opción B se mide ANTES de sumar el club nuevo (si no, su propia reputación baja abaratara la cuota).
## - A · el club reemplazado deja de existir como tal, pero su OBJETO se reutiliza (mismo id, misma plaza
##   en la liga, el calendario y los torneos que ya tuviera sorteados), igual que hace `fundar_club()`:
##   así nada que apunte a ese id queda colgando. Su nombre, colores e identidad visual se borran.
## - A · sus futbolistas pasan TODOS a la bolsa de libres (`Mundo.libres`), con el motivo «su club
##   desapareció», y se pueden fichar sin traspaso como cualquier libre. Tu plantilla se rehace entera
##   (`Mundo._poblar`) al nivel de tu reputación nueva: ese es el «coste de plantilla» de reemplazar.
## - A · «su afición se reparte»: un tercio de sus socios se queda con el club nuevo (son del barrio y
##   el estadio sigue ahí); los otros dos tercios se reparten a partes iguales entre los demás clubes de
##   esa liga. El estadio (aforo) se hereda.
## - B · el club se crea con el estadio más modesto de esa división y su plantilla es la de un club
##   recién fundado (`Mundo.REP_FUNDACION`): el −20 es el estigma de «compró su plaza» (patrocinio,
##   taquilla, fichajes), no un plantel peor. La liga queda con un club más y el calendario se rehace con
##   descansos si queda impar (`Liga.preparar`). Solo se admite antes de que esa liga juegue una jornada.
## - B · el −15 de ánimo se resta UNA vez al empezar; el ánimo de `Prensa` ya vuelve solo hacia su punto
##   de reposo (≈3 %/semana) y sube con las victorias, que es el «se recupera en ~1 temporada».
## - La dificultad se aplica DESPUÉS (`Principal._arrancar_con` escala la caja): estas cifras son las de
##   la dificultad normal.

const MODO_REEMPLAZAR := "reemplazar"
## «pagar» es también la palabra que usa `OrquestadorMundo.tipo_entrada()`: un solo vocabulario.
const MODO_CONFEDERACION := "pagar"

const REP_MENOS_REEMPLAZAR := 10      ## «recién llegado»
const REP_MENOS_CONFEDERACION := 20   ## «compró su plaza»
const CUOTA_AFILIACION := 0.25        ## de B, al contado
const CONFIANZA_REEMPLAZAR := 60
const CONFIANZA_CONFEDERACION := 40
const ANIMO_CONFEDERACION := -15
## Parte de los socios del club reemplazado que se queda con el club nuevo.
const SOCIOS_QUE_SE_QUEDAN := 1.0 / 3.0
const REP_MINIMA := 1
const MOTIVO_LIBRE := "Su club desapareció de la liga"

# --- consultas puras (no tocan el mundo) ----------------------------------------------------------

## Acepta la entrada venga como venga (la de esta pantalla o la del orquestador: «tipo»/«modo»,
## «club_reemplazado»/«reemplaza»/«club_id») y la deja en {modo, pais, club_reemplazado}.
static func normalizar(entrada: Dictionary, pais_por_defecto: String = "CHI") -> Dictionary:
	var modo := String(entrada.get("tipo", entrada.get("modo", MODO_REEMPLAZAR)))
	if modo == "confederacion":
		modo = MODO_CONFEDERACION
	var id := ""
	for k: String in ["club_reemplazado", "reemplaza", "club_id"]:
		if String(entrada.get(k, "")) != "":
			id = String(entrada[k])
			break
	return {"modo": modo if modo == MODO_CONFEDERACION else MODO_REEMPLAZAR,
		"pais": String(entrada.get("pais", pais_por_defecto)), "club_reemplazado": id}

## Los datos del club (nombre, colores, estadio) desde lo que dejó la configuración del club, con los
## nombres de clave de cualquiera de las etapas («nombre_club»/«nombre», «color1»/«col1», Color o texto).
static func datos_de_config(cfg: Dictionary) -> Dictionary:
	return {
		"nombre": String(cfg.get("nombre_club", cfg.get("nombre", ""))).strip_edges(),
		"color1": _color_texto(cfg.get("color1", cfg.get("col1", ""))),
		"color2": _color_texto(cfg.get("color2", cfg.get("col2", ""))),
		"estadio": String(cfg.get("estadio", "")).strip_edges(),
	}

static func _color_texto(v: Variant) -> String:
	if v is Color:
		return "#" + (v as Color).to_html(false)
	var s := String(v) if v != null else ""
	return s if s == "" or s.begins_with("#") else "#" + s

## B: la caja inicial de un club típico de esa liga.
static func presupuesto_base(l: Liga) -> int:
	if l == null or l.clubes.is_empty():
		return 0
	var s := 0.0
	for c: Club in l.clubes:
		s += float(c.rep)
	return int(round(Eco.ref_caja(s / float(l.clubes.size()))))

## La liga de la división más baja de un país (la de número de división más alto).
static func liga_mas_baja(m: Mundo, pais: String) -> Liga:
	var peor: Liga = null
	for l: Liga in m.ligas:
		if l.pais == pais and (peor == null or l.division() > peor.division()):
			peor = l
	return peor

static func liga_de_club(m: Mundo, c: Club) -> Liga:
	for l: Liga in m.ligas:
		if l.clubes.has(c):
			return l
	return null

## Los clubes que se pueden reemplazar en un país: de la división más alta a la más baja y, dentro de
## cada una, de mayor a menor reputación (como se lee una tabla).
static func candidatos(m: Mundo, pais: String) -> Array[Club]:
	var salida: Array[Club] = []
	for l: Liga in m.ligas:
		if l.pais == pais:
			salida.append_array(l.clubes)
	salida.sort_custom(func(a: Club, b: Club) -> bool:
		return a.rep > b.rep if a.division == b.division else a.division < b.division)
	return salida

## El candidato que se propone de entrada: el más flojo de la división más baja (el mismo club que
## tomaría `Mundo.fundar_club()`), para que «confirmar sin tocar nada» no borre a un grande.
static func candidato_sugerido(m: Mundo, pais: String) -> Club:
	var l := liga_mas_baja(m, pais)
	if l == null or l.clubes.is_empty():
		return null
	var peor: Club = l.clubes[0]
	for c: Club in l.clubes:
		if c.rep < peor.rep:
			peor = c
	return peor

static func rep_reemplazo(reemplazado: Club) -> int:
	return maxi(REP_MINIMA, reemplazado.rep - REP_MENOS_REEMPLAZAR)

static func rep_confederacion() -> int:
	return maxi(REP_MINIMA, Mundo.REP_FUNDACION - REP_MENOS_CONFEDERACION)

## Todas las cifras de una opción, sin aplicar nada. Es lo que enseña la pantalla y lo que viaja en
## `terminado({"entrada": …})`. Devuelve {"error": "..."} si la opción no es posible.
static func previsualizar(m: Mundo, modo: String, pais: String, club_id: String = "") -> Dictionary:
	if modo == MODO_REEMPLAZAR:
		var r: Club = m.clubes.get(club_id)
		if r == null or r.pais != pais:
			return {"error": "elige el club que vas a reemplazar", "modo": modo, "pais": pais}
		var l := liga_de_club(m, r)
		var b := presupuesto_base(l)
		var quedan := int(floor(float(r.socios) * SOCIOS_QUE_SE_QUEDAN))
		return {
			"modo": modo, "tipo": modo, "pais": pais, "club_reemplazado": r.id, "reemplaza": r.id,
			"club_reemplazado_nombre": r.nombre,
			"rep_reemplazado": r.rep, "liga": l.nombre if l != null else "", "division": r.division,
			"presupuesto_base": b, "cuota": 0, "presupuesto": b,
			"rep": rep_reemplazo(r), "confianza": CONFIANZA_REEMPLAZAR, "animo_delta": 0,
			"jugadores_libres": r.plantilla.size(), "socios": quedan, "socios_repartidos": r.socios - quedan,
			"aforo": r.estadio_aforo, "clubes_liga": l.clubes.size() if l != null else 0, "descansos": false,
			"titular": "Nace un club sobre las cenizas de %s" % r.nombre,
		}
	if modo == MODO_CONFEDERACION:
		var l := liga_mas_baja(m, pais)
		if l == null:
			return {"error": "ese país no tiene liga", "modo": modo, "pais": pais}
		if l.jornada_actual > 0:
			return {"error": "la liga ya empezó: hay que esperar a la próxima temporada", "modo": modo, "pais": pais}
		var b := presupuesto_base(l)
		var cuota := int(round(float(b) * CUOTA_AFILIACION))
		var rep := rep_confederacion()
		var aforo := _aforo_modesto(l)
		var n := l.clubes.size() + 1
		return {
			"modo": modo, "tipo": modo, "pais": pais, "club_reemplazado": "", "reemplaza": "",
			"club_reemplazado_nombre": "",
			"rep_reemplazado": 0, "liga": l.nombre, "division": l.division(),
			"presupuesto_base": b, "cuota": cuota, "presupuesto": b - cuota,
			"rep": rep, "confianza": CONFIANZA_CONFEDERACION, "animo_delta": ANIMO_CONFEDERACION,
			"jugadores_libres": 0, "socios": _socios_de(aforo, rep), "socios_repartidos": 0,
			"aforo": aforo, "clubes_liga": n, "descansos": n % 2 == 1,
			"titular": "Un club compra su plaza en %s" % l.nombre,
		}
	return {"error": "modo de entrada desconocido", "modo": modo, "pais": pais}

## La pregunta dura de la primera rueda de prensa de un club que compró su plaza, con el formato de
## `Prensa.entrevista` ({pregunta, opciones[{txt, moral, confianza, socios, tono}]}). La rueda la abre
## `Prensa.abrir_rueda()`, que es de otra zona: queda lista para que la enganche (ver el informe).
static func pregunta_primera_rueda(entrada: Dictionary) -> Dictionary:
	if String(entrada.get("modo", "")) != MODO_CONFEDERACION:
		return {}
	return {"pregunta": "Prensa: 'Su club no ganó la plaza en la cancha: la compró. ¿Qué le dice al hincha que lo ve como un club de cartón?'", "opciones": [
		{"txt": "Que nos juzgue por lo que hagamos en la cancha", "moral": 1, "confianza": 1, "socios": 1, "tono": "calma"},
		{"txt": "Pagamos lo que había que pagar; el que no quiera, que no venga", "moral": 0, "confianza": -1, "socios": -2, "tono": "soberbia"},
		{"txt": "Eso lo decidió la directiva, no yo", "moral": -1, "confianza": -1, "socios": -1, "tono": "evasiva"},
	]}

# --- aplicar ------------------------------------------------------------------------------------

## Aplica la entrada al mundo y te pone al mando. `datos_club`: {nombre, color1, color2, estadio} (lo que
## eligió el jugador en las etapas anteriores). Las cifras se recalculan aquí con `previsualizar()` sobre
## el mundo real -no se fía de las que traiga `entrada`-, así que la pantalla y el motor no pueden
## discrepar. Devuelve el club, o null si la opción no es posible (y entonces no toca nada).
static func aplicar(m: Mundo, entrada: Dictionary, datos_club: Dictionary) -> Club:
	var e := normalizar(entrada, String(entrada.get("pais", "CHI")))
	var modo := String(e["modo"])
	var p := previsualizar(m, modo, String(e["pais"]), String(e["club_reemplazado"]))
	var nombre := String(datos_club.get("nombre", "")).strip_edges()
	if p.has("error") or nombre == "":
		return null
	var c: Club = _reemplazar(m, p, datos_club) if modo == MODO_REEMPLAZAR else _crear_en_confederacion(m, p, datos_club)
	if c == null:
		return null
	m.tomar_el_mando(c.id)
	m.directiva.confianza = int(p["confianza"])
	if int(p["animo_delta"]) != 0:
		m.prensa.mover_animo(int(p["animo_delta"]))
	m.prensa.guardar_portada(String(p["titular"]), _cuerpo_titular(p, c), "neutro" if modo == MODO_REEMPLAZAR else "mal")
	if int(p["cuota"]) > 0:
		m._anotar_movimiento("Cuota de afiliación a la confederación", -int(p["cuota"]))
	return c

static func _reemplazar(m: Mundo, p: Dictionary, datos: Dictionary) -> Club:
	var c: Club = m.clubes.get(String(p["club_reemplazado"]))
	var l := liga_de_club(m, c)
	## 1) Sus futbolistas, a la bolsa de libres. Si la bolsa aún no se había llenado nunca, se llena
	##    antes con la tanda normal: si no, `avanzar_semana` la vería con gente y no generaría la suya.
	if m.libres.is_empty():
		m.generar_libres()
	for j: Jugador in c.plantilla.duplicate():
		c.soltar(j)
		j.club_id = ""
		j.capitan = false
		j.dorsal = 0
		j.motivo_libre = MOTIVO_LIBRE
		j.rechazos_libre = 0
		m.libres.append(j)
	## 2) Su afición se reparte: dos tercios a los demás clubes de su liga, a partes iguales.
	var otros: Array[Club] = []
	for k: Club in l.clubes:
		if k != c:
			otros.append(k)
	var repartidos := int(p["socios_repartidos"])
	if not otros.is_empty():
		var cada := repartidos / otros.size()
		for i in otros.size():
			otros[i].socios += cada + (1 if i < repartidos % otros.size() else 0)
	c.socios = int(p["socios"])
	## 3) Nace el club nuevo en su plaza.
	_vestir(c, datos)
	c.rep = int(p["rep"])
	c.saldo = int(p["presupuesto"])
	c.plantilla.clear()
	c.limpiar_once()
	c.fichajes_cupo.clear()
	c.cupo_cache.clear()
	c.tactica = Tactica.new()
	m._poblar(c)
	return c

static func _crear_en_confederacion(m: Mundo, p: Dictionary, datos: Dictionary) -> Club:
	var l := liga_mas_baja(m, String(p["pais"]))
	## Un id que no choque con ninguno, aunque el mundo venga de una partida cargada (que no guarda el
	## contador de clubes).
	var n := m._seq_club
	while m.clubes.has("c%d" % (n + 1)):
		n += 1
	m._seq_club = n
	var c := m._crear_club([String(datos.get("nombre", "")), "#1e4030", "#c9a227", Mundo.REP_FUNDACION, int(p["aforo"])], String(p["pais"]))
	c.division = int(p["division"])
	_vestir(c, datos)
	m._poblar(c)   ## con la reputación de un club recién fundado; el −20 va después
	c.rep = int(p["rep"])
	c.socios = int(p["socios"])
	c.saldo = int(p["presupuesto_base"])
	c.mover_saldo(-int(p["cuota"]))
	m.clubes[c.id] = c
	l.clubes.append(c)
	l.preparar()
	return c

## Nombre, colores, estadio e identidad visual limpia (sin escudo especial ni camiseta del club anterior).
static func _vestir(c: Club, datos: Dictionary) -> void:
	c.nombre = String(datos.get("nombre", "")).strip_edges()
	var c1 := String(datos.get("color1", ""))
	var c2 := String(datos.get("color2", ""))
	c.color1 = c1 if c1 != "" else "#1e4030"
	c.color2 = c2 if c2 != "" else "#c9a227"
	c.estadio_nombre = String(datos.get("estadio", "")).strip_edges()
	c.identidad_desde_dic({})
	c.bonus_ataque = 1.0
	c.bonus_defensa = 1.0

static func _aforo_modesto(l: Liga) -> int:
	var a := 0
	for c: Club in l.clubes:
		if a == 0 or c.estadio_aforo < a:
			a = c.estadio_aforo
	return a if a > 0 else 8000

## La misma fórmula de socios que `Mundo._crear_club()`.
static func _socios_de(aforo: int, rep: int) -> int:
	return int(float(aforo) * (0.22 + float(rep) / 420.0))

static func _cuerpo_titular(p: Dictionary, c: Club) -> String:
	if String(p["modo"]) == MODO_REEMPLAZAR:
		return "%s deja de existir. %s ocupa su plaza en %s y su estadio; sus %d futbolistas quedan libres." % [
			String(p["club_reemplazado_nombre"]), c.nombre, String(p["liga"]), int(p["jugadores_libres"])]
	return "%s paga %s a la confederación y entra en %s sin haber ganado la plaza en la cancha. La primera rueda de prensa no será tranquila." % [
		c.nombre, Eco.dinero(int(p["cuota"])), String(p["liga"])]
