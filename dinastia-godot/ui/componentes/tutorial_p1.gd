extends Control
## [Capa 1/3 de `tutorial.gd`] _negrita, contexto, _nombre_mentor, mentor_de, _paso, _dt_o … (+17)

## EL TUTORIAL INMERSIVO (25-9-2026, segunda versión).
##
## La primera versión era un recorrido de interfaz con tarjetas genéricas
## ("Los seis bloques", "La ficha del jugador"...) y un solo paso propio por
## modo. El usuario pidió más: "debe ser inmersivo según modo de juego". Así
## que ahora no es un manual, es tu PRIMER DÍA en el cargo:
##
##  * Un PRÓLOGO de cine -franjas negras, el escudo del club, la fecha y una
##    escena escrita a máquina- que cuenta cómo llegas: al entrenador lo deja
##    un taxi frente al estadio, al interino lo despierta el teléfono a
##    medianoche, al jeque lo esperan las cámaras en la pista...
##  * Un MENTOR con cara, nombre y cargo que te habla en primera persona: el
##    presidente si entrenas, tu jefe si eres ayudante, el enviado del fondo si
##    eres el jeque. Y habla de TU partida: de tu estrella por su nombre, del
##    rival del domingo, del objetivo que puso el directorio, de la caja.
##  * MISIONES que se cumplen HACIENDO la cosa en la pantalla real (abrir la
##    táctica, mirar la ficha de tu estrella, estudiar al rival). Al cumplirse
##    se marcan con un ✔ y el mentor sigue solo. "Muéstramelo" la hace por ti.
##  * Cada modo tiene su propio guion: las misiones del director deportivo son
##    el mercado y los contratos, las del ayudante el entrenamiento y el
##    camarín, las del director de cantera la academia...
##  * Un EPÍLOGO con las misiones cumplidas y la despedida del mentor.
##
## Todo el guion sale de `guion()`, estático y sin interfaz, para que el banco
## pueda comprobar los ocho modos sin abrir ninguna pantalla. `contexto()`
## saca de la partida los datos con los que habla el mentor.

signal terminado(completo: bool)

const AJUSTES := "user://ajustes.cfg"
const SECCION := "tutorial"

const COL_FONDO := Color("121a14")
const COL_BORDE := Tema.ACENTO
const COL_TEXTO := Tema.TEXTO
const COL_SUAVE := Tema.SUAVE
const COL_ORO := Tema.ORO
const COL_HECHO := Color("5fd08a")
const ANCHO_TARJETA := 560.0
## Letras por segundo de la máquina de escribir.
const LETRAS_SEG := 70.0

## Las pestañas y secciones a las que una misión puede mandar (`tab:X`,
## `chip:X|Y`). El banco comprueba que ninguna apunte a una que no exista.
const PESTANAS := ["Mi plantel", "Táctica", "Entrenar", "Enfermería", "Camarín", "Cantera",
	"Contratos", "Partido", "Calendario", "Finanzas", "Mercado", "Libres", "Clubes", "Estadio"]
const CHIPS := ["Gente|identidad", "Gente|kits", "Club|infra", "Club|directorio", "Club|staff"]

var _principal: Node
var _guion: Dictionary = {}
var _pasos: Array[Dictionary] = []
var _i := 0
var _t := 0.0
var _fase := "prologo"
var _hecho_al_entrar := false
var _cumplidas: Dictionary = {}
var _t_cumplida := -1.0
var _escribiendo := false
var _prologo: Control
var _lbl_prologo: RichTextLabel
var _btn_prologo: Button
var _tarjeta: PanelContainer
var _marco_cara: PanelContainer
var _panel_aspecto: VBoxContainer
var _modo := "dt"
var _aspecto: Dictionary = {}
var _fondo_retrato := Color.BLACK
var _lbl_nombre: Label
var _lbl_cargo: Label
var _lbl_progreso: Label
var _lbl_texto: RichTextLabel
var _caja_mision: PanelContainer
var _lbl_mision: Label
var _btn_atras: Button
var _btn_sig: Button
var _btn_mostrar: Button
var _btn_extra: Button
var _marco: Panel
var _sombras: Array[ColorRect] = []

## El mentor de cada modo: quién te recibe el primer día. El nombre sale del
## club -siempre el mismo para el mismo club- y nunca de `Azar`, que es el
## generador de la partida y no se puede mover desde la interfaz.
const _PILAS := ["Ernesto", "Ramiro", "Aurelio", "Clemente", "Octavio", "Humberto", "Leopoldo",
	"Fausto", "Anselmo", "Rigoberto", "Teodoro", "Gilberto"]
const _APELLIDOS := ["Valdivia", "Arancibia", "Montalvo", "Echenique", "Sotomayor", "Quiroga",
	"Villaseca", "Bustamante", "Larrondo", "Iturriaga", "Cifuentes", "Barahona"]

## EL ASPECTO DEL MENTOR, PERSONALIZABLE. Sale de su semilla (siempre el
## mismo para el mismo club) y encima va lo que el jugador haya elegido con ✎,
## guardado por modo en `user://ajustes.cfg`.
const SECCION_ASPECTO := "mentor_aspecto"

## Negrita de verdad (la sintética del texto enriquecido montaba letras).
static func _negrita() -> Font:
	var f := FontVariation.new()
	f.base_font = ThemeDB.fallback_font
	f.variation_embolden = 0.7
	return f

# ---------------------------------------------------------------------------
#  LO QUE SABE EL MENTOR DE TU PARTIDA
# ---------------------------------------------------------------------------

static func contexto(mundo: Mundo, club_por_defecto: String = "tu club") -> Dictionary:
	var ctx := {"club": club_por_defecto, "estadio": "el estadio", "objetivo": "", "confianza": 50,
		"caja": "", "rival": "", "local": true, "liga": "la liga", "estrella": {}, "joven": {},
		"dt": "", "anio": 0, "socios": 0, "meta_cantera": 0, "chico": {}, "c1": "#2b6b45", "c2": "#ffffff"}
	if mundo == null or mundo.mi_club() == null:
		return ctx
	var c := mundo.mi_club()
	ctx["club"] = c.nombre
	ctx["estadio"] = c.estadio_nombre if c.estadio_nombre != "" else "Estadio " + c.nombre
	ctx["c1"] = c.color1
	ctx["c2"] = c.color2
	ctx["caja"] = Eco.dinero(c.saldo)
	ctx["anio"] = mundo.anio
	ctx["socios"] = c.socios if c.socios > 0 else c.estadio_aforo
	if mundo.directiva != null:
		ctx["objetivo"] = mundo.directiva.objetivo
		ctx["confianza"] = mundo.directiva.confianza
	for l in mundo.ligas:
		if l.clubes.has(c):
			ctx["liga"] = l.nombre
	var par := mundo.proximo_partido()
	if par.size() == 2:
		var rival: Club = par[1] if par[0] == c else par[0]
		ctx["rival"] = rival.nombre
		ctx["local"] = par[0] == c
	var estrella: Jugador = null
	var joven: Jugador = null
	for j: Jugador in c.plantilla:
		if estrella == null or j.ovr > estrella.ovr:
			estrella = j
		if j.edad <= 21 and (joven == null or j.pot > joven.pot):
			joven = j
	if estrella != null:
		ctx["estrella"] = {"id": estrella.id, "nombre": estrella.nombre, "ovr": estrella.ovr, "pos": estrella.pos_e}
	if joven != null and joven != estrella:
		ctx["joven"] = {"id": joven.id, "nombre": joven.nombre, "edad": joven.edad, "pot": joven.pot}
	if mundo.roles != null:
		var dt := mundo.roles.dt_nombre()
		ctx["dt"] = dt if dt != "—" else ""
		ctx["meta_cantera"] = int(mundo.roles.cantera.get("meta", 0))
	if mundo.academia != null and not mundo.academia.chicos.is_empty():
		var mejor: Dictionary = {}
		for ch: Dictionary in mundo.academia.chicos:
			if mejor.is_empty() or mundo.academia.proyeccion(ch).y > mundo.academia.proyeccion(mejor).y:
				mejor = ch
		ctx["chico"] = {"nombre": String(mejor["nombre"]), "edad": int(mejor["edad"])}
	return ctx

static func _nombre_mentor(semilla: String) -> String:
	var h := absi(semilla.hash())
	return "%s %s" % [_PILAS[h % _PILAS.size()], _APELLIDOS[(h / 7) % _APELLIDOS.size()]]

static func mentor_de(modo: String, ctx: Dictionary) -> Dictionary:
	var club := String(ctx["club"])
	match modo:
		"ayudante":
			var jefe := String(ctx["dt"]) if String(ctx["dt"]) != "" else _nombre_mentor(club + "dt")
			return {"nombre": jefe, "cargo": "Primer entrenador de %s · tu jefe" % club, "semilla": "m_" + jefe, "canas": false}
		"cantera":
			var coord := _nombre_mentor(club + "acad")
			return {"nombre": coord, "cargo": "Coordinador de la Academia de %s" % club, "semilla": "m_" + coord, "canas": true}
		"imperio":
			var dg := _nombre_mentor(club + "dg")
			return {"nombre": dg, "cargo": "Director general de %s · tu mano derecha" % club, "semilla": "m_" + dg, "canas": false}
		"jeque":
			var env := _nombre_mentor(club + "fondo")
			return {"nombre": env, "cargo": "Consejero delegado del fondo", "semilla": "m_" + env, "canas": false}
		"creador":
			var socio := _nombre_mentor(club + "socio")
			return {"nombre": socio, "cargo": "Socio fundador de %s" % club, "semilla": "m_" + socio, "canas": false}
	var pres := _nombre_mentor(club + "pres")
	return {"nombre": pres, "cargo": "Presidente de %s" % club, "semilla": "m_" + pres, "canas": true}

static func _paso(titulo: String, texto: String, mision: String = "", objetivo: String = "",
		hecho: String = "", mostrar: String = "") -> Dictionary:
	var d := {"titulo": titulo, "texto": texto}
	if mision != "":
		d["mision"] = mision
	if objetivo != "":
		d["objetivo"] = objetivo
	if hecho != "":
		d["hecho"] = hecho
	if mostrar != "":
		d["mostrar"] = mostrar
	return d

static func _dt_o(ctx: Dictionary) -> String:
	return "[b]%s[/b]" % ctx["dt"] if String(ctx["dt"]) != "" else "el entrenador"

static func _obj(ctx: Dictionary) -> String:
	return String(ctx["objetivo"]).to_lower() if String(ctx["objetivo"]) != "" else "una temporada digna"

static func _ficha(j: Dictionary, titulo: String, texto: String) -> Dictionary:
	return _paso(titulo, texto + "\n\nSu ficha lo dice todo: atributos, forma, moral, contrato.",
		"Abre la ficha de %s" % j["nombre"], "ficha", "ficha:%s" % j["id"], "ficha:%s" % j["id"])

static func _ficha_estrella(ctx: Dictionary, frase: String) -> Dictionary:
	var e: Dictionary = ctx["estrella"]
	if e.is_empty():
		return _paso("La estrella", "Toque a cualquier jugador y su ficha se abre aquí: atributos, forma, moral, contrato.",
			"Abre la ficha de un jugador", "ficha", "ficha")
	return _ficha(e, "La estrella", frase % [e["nombre"], int(e["ovr"])])

static func _caja(ctx: Dictionary) -> String:
	return String(ctx["caja"]) if String(ctx["caja"]) != "" else "lo justo"

## Los pasos de orientación que sirven a cualquier cargo, dichos por el mentor.
static func _pasos_comunes(dirige: bool) -> Array[Dictionary]:
	var p: Array[Dictionary] = []
	p.append(_paso("El club entero", "Todo el club está en esos seis bloques de arriba: [b]CENTRAL, CLUB, GENTE, HISTORIA, OPERACIONES y AJUSTES[/b]. Cada uno abre su fila de accesos debajo.", "Toca cualquier bloque", "grupos", "grupo", "grupo_club"))
	p.append(_paso("Lo que va pasando", "Resultados, lesiones, ofertas, la prensa... todo llega aquí. Lo urgente, además, salta como aviso.", "", "registro"))
	if dirige:
		p.append(_paso("El tiempo", "Cuando esté listo: [b]Dirigir el partido[/b] para jugarlo en directo -cambios, órdenes, charla en el descanso-, o [b]Avanzar semana[/b] para que se juegue solo.", "", "calendario"))
	else:
		p.append(_paso("El tiempo", "El calendario avanza desde aquí: [b]Avanzar semana[/b], o día a día con [b]Un día[/b].", "", "calendario"))
	p.append(_paso("Guardar", "Y una cosa que aquí nadie hace por usted: [b]guardar[/b]. Antes de irse, siempre.", "", "guardar"))
	return p

static func _final(despedida: String) -> Dictionary:
	return {"titulo": "¡A jugar!", "texto": despedida, "final": true}

static func _rival(ctx: Dictionary) -> String:
	return String(ctx["rival"]) if String(ctx["rival"]) != "" else "nuestro próximo rival"

static func _miles(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

## {mentor, lugar, sonido, prologo, pasos}. Cada paso: `titulo`, `texto` (lo
## que dice el mentor, BBCode), y opcionales `mision` (la tarea, en una
## línea), `objetivo` (qué control resaltar), `hecho` (qué acción lo cumple:
## `grupo`, `ficha`, `ficha:<id>`, `tab:<pestaña>`, `chip:<pestaña>|<sección>`)
## y `mostrar` (qué hace "Muéstramelo", mismas claves). El último es `final`.
static func guion(modo: String, ctx: Dictionary) -> Dictionary:
	var m := mentor_de(modo, ctx)
	var g := {"mentor": m}
	var club := "[b]%s[/b]" % ctx["club"]
	var yo := String(m["nombre"])
	var estadio := String(ctx["estadio"])
	var p: Array[Dictionary] = []
	match modo:
		"dir":
			g["lugar"] = "Oficina de la dirección deportiva · lunes"
			g["sonido"] = "abrir"
			g["prologo"] = "Una oficina con vista al campo. Sobre la mesa, la carpeta de fichajes de %s y un café que ya se enfrió.\n\n[b]%s[/b] cierra la puerta y se sienta frente a ti.\n\n[i]«El entrenador entrena. Tú construyes el club.»[/i]" % [club, yo]
			p.append(_paso("Tu despacho", "Bienvenido. Te lo digo claro desde el primer día: el once lo pone %s. Lo tuyo es que tenga con qué ganar.\n\nEsto es lo que te pedimos esta temporada: [b]%s[/b]." % [_dt_o(ctx), _obj(ctx)], "", "estado"))
			p.append(_paso("La plantilla", "Antes de comprar, mira lo que tienes. Ábreme la plantilla.", "Abre el plantel", "plantel", "tab:Mi plantel", "tab:Mi plantel"))
			p.append(_ficha_estrella(ctx, "Ese es %s, nuestro mejor jugador: media [b]%d[/b]. Todo el mundo va a preguntar por él. Tú decides si es innegociable."))
			p.append(_paso("Los contratos", "Lo que más dinero hace perder no es un mal fichaje, es un contrato mal hecho. Revisa cuándo vence cada uno.", "Revisa los contratos", "plantel", "tab:Contratos", "tab:Contratos"))
			p.append(_paso("La caja", "Esta es la caja: [b]%s[/b]. Sueldos, fichajes y obras salen de aquí. Un club sin caja no ficha, y uno en rojo acaba con el banco en la puerta." % _caja(ctx), "Mira las finanzas", "dinero", "tab:Finanzas", "tab:Finanzas"))
			p.append(_paso("El mercado", "Y aquí está tu terreno. Filtra por puesto, mira lo que puedes pagar y negocia. Si fichas a alguien que %s no quiere, lo vas a oír." % _dt_o(ctx), "Abre el mercado", "dinero", "tab:Mercado", "tab:Mercado"))
			p.append(_paso("El entrenador", "Puedes pedirle cosas a %s -más minutos para la cantera, rotar a los cansados-, pero cada vez que te metes en su trabajo la relación se desgasta. Eso está en [b]CLUB → Personal del Club[/b]." % _dt_o(ctx), "Mira el personal del club", "grupos", "chip:Club|staff", "chip:Club|staff"))
			p.append_array(_pasos_comunes(false))
			p.append(_final("Cuando la ventana de fichajes cierre, que se note tu mano. Yo estaré en el palco."))
		"ayudante":
			g["lugar"] = "Ciudad deportiva · 6:30 de la mañana"
			g["sonido"] = "silbato"
			g["prologo"] = "Seis y media de la mañana, antes que nadie. Conos, petos, el silbato colgado del cuello.\n\n[b]%s[/b] llega con el termo en la mano y te mira de arriba abajo.\n\n[i]«Bienvenido al cuerpo técnico de %s. Aquí se empieza cargando balones.»[/i]" % [yo, club]
			p.append(_paso("Las reglas", "Que quede claro: [b]no fichas, no vendes y no pones el once[/b]. Eso es cosa mía. Tú me preparas al equipo para que yo gane el domingo.\n\nHazlo bien y algún día este banco será tuyo.", "", "estado"))
			p.append(_paso("El grupo", "Primero, conoce al grupo. Nombre, puesto, forma. Te los quiero oír decir de memoria para el viernes.", "Abre el plantel", "plantel", "tab:Mi plantel", "tab:Mi plantel"))
			p.append(_paso("El entrenamiento", "Esto es lo tuyo. Carga de trabajo, ejercicios, a quién se le da prioridad. Un equipo que entrena mal llega muerto al minuto setenta.", "Abre el entrenamiento", "plantel", "tab:Entrenar", "tab:Entrenar"))
			p.append(_ficha_estrella(ctx, "Y a %s me lo cuidas como oro: media [b]%d[/b]. Si se rompe en un entrenamiento tuyo, hablamos."))
			p.append(_paso("El camarín", "El camarín es un ecosistema: hay líderes, hay grupos, hay quien se enfada si no juega. Tú eres quien lo escucha. Yo no tengo tiempo.", "Visita el camarín", "plantel", "tab:Camarín", "tab:Camarín"))
			p.append(_paso("La cantera", "Y los chicos. Si encuentras uno que valga, me lo traes. Eso también cuenta para tu ascenso.", "Pasa por la cantera", "plantel", "tab:Cantera", "tab:Cantera"))
			p.append_array(_pasos_comunes(false))
			p.append(_final("Mañana a la misma hora. Y trae café para los dos."))
		"interino":
			g["lugar"] = "Medianoche · suena el teléfono"
			g["sonido"] = "telefono"
			g["prologo"] = "El teléfono suena a medianoche. Una voz cansada:\n\n[i]«%s está hundido. Necesitamos a alguien para [b]cinco fechas[/b]. Solo cinco.»[/i]\n\nA la mañana siguiente, el vestuario está en silencio y la tabla, pegada en la pared, dice lo que nadie quiere leer." % club
			p.append(_paso("Cinco fechas", "Gracias por venir. Soy %s. No le voy a dar vueltas: estamos en el fondo y no hay dinero para fichar. [b]Cinco fechas para salvar la categoría.[/b]\n\nNo le puedo echar: su contrato ya trae fecha de término. Pero tampoco le voy a poder salvar yo." % yo, "", "estado"))
			p.append(_paso("La tabla", "Mírela. Así está la cosa. Cada punto de aquí al final vale oro.", "", "tabla"))
			p.append(_paso("Lo que hay", "Esto es lo que hay. No son los mejores, pero son los que tenemos. Ábrame el plantel.", "Abre el plantel", "plantel", "tab:Mi plantel", "tab:Mi plantel"))
			p.append(_paso("El vestuario", "El problema no son las piernas, es la cabeza. Están hundidos. Si alguien puede levantarlos es usted, en el camarín.", "Entra al camarín", "plantel", "tab:Camarín", "tab:Camarín"))
			p.append(_paso("La táctica", "Y ordénelos. Un equipo que no sabe a qué juega pierde por tres. Uno ordenado, por uno. Y a veces empata.", "Ajusta la táctica", "plantel", "tab:Táctica", "tab:Táctica"))
			p.append(_paso("El primero", "El primero de los cinco es contra [b]%s[/b]. Mire quién viene, quién llega tocado y cómo juegan." % _rival(ctx), "Estudia al rival", "partido", "tab:Partido", "tab:Partido"))
			p.append(_paso("A la cancha", "Cuando esté listo, [b]Dirigir el partido[/b] y a la cancha. Y no se olvide de [b]guardar[/b]. Suerte. La vamos a necesitar.", "", "calendario"))
			p.append(_final("Cinco fechas. Si nos salva, en este club no se le olvida nunca."))
		"cantera":
			g["lugar"] = "Campo anexo · sábado por la mañana"
			g["sonido"] = "silbato"
			g["prologo"] = "Sábado, campo anexo. Chicos de doce años corriendo detrás de un balón con más ilusión que técnica. En la grada, padres, abuelos y un termo de café.\n\n[b]%s[/b] se acoda en la baranda a tu lado.\n\n[i]«De aquí sale el futuro de %s. Y ahora el futuro es tuyo.»[/i]" % [yo, club]
			var meta := int(ctx["meta_cantera"])
			p.append(_paso("El encargo", "Bienvenido. Tú no diriges al primer equipo: diriges a los que algún día lo serán. El club te pide [b]%s[/b] esta temporada, y te da un presupuesto de academia, no el de un plantel profesional." % ("%d debutantes" % meta if meta > 0 else "debutantes"), "", "estado"))
			p.append(_paso("La Academia", "Aquí viven los chicos de 10 a 16 años. De cada uno decides el entrenamiento, la comida, cuánto estudia y el carácter que forja. A los 16 suben al primer equipo tal como los hayas formado.", "Abre la Academia (Plantel → Cantera)", "plantel", "tab:Cantera", "tab:Cantera"))
			if not (ctx["chico"] as Dictionary).is_empty():
				p.append(_paso("Un nombre", "Fíjate en [b]%s[/b], %d años. Tiene algo. Lo que llegue a ser depende de lo que hagas con él estos años." % [ctx["chico"]["nombre"], int(ctx["chico"]["edad"])], "", "plantel"))
			if not (ctx["joven"] as Dictionary).is_empty():
				p.append(_ficha(ctx["joven"], "El que acaba de subir", "Y mira a [b]%s[/b]: %d años, ya en el primer equipo. Así se ve el trabajo bien hecho." % [ctx["joven"]["nombre"], int(ctx["joven"]["edad"])]))
			p.append(_paso("El primer equipo", "No es tuyo, pero tienes que conocerlo: ahí es donde tus chicos tienen que hacerse un hueco.", "Mira el plantel", "plantel", "tab:Mi plantel", "tab:Mi plantel"))
			p.append_array(_pasos_comunes(false))
			p.append(_final("Dentro de cinco años, cuando el estadio coree el nombre de uno de estos chicos, acuérdate de este sábado."))
		"imperio":
			g["lugar"] = "Notaría · la firma"
			g["sonido"] = "fichaje"
			g["prologo"] = "La firma tarda tres segundos. Con ella, %s es tuyo: el estadio, las deudas, la historia y la ilusión de [b]%s personas[/b].\n\n[b]%s[/b] te entrega las llaves del palco.\n\n[i]«Enhorabuena, jefe. Ahora nadie le puede echar. Pero tampoco hay a quién echarle la culpa.»[/i]" % [club, _miles(int(ctx["socios"])), yo]
			p.append(_paso("El dueño", "Usted manda. Un entrenador empleado, %s, dirige los partidos; usted decide todo lo demás. Y puede meter capital propio dos veces por temporada." % _dt_o(ctx), "", "estado"))
			p.append(_paso("La caja", "Lo primero, los números: [b]%s[/b] en caja. Ingresos, gastos y lo que debemos." % _caja(ctx), "Mira las finanzas", "dinero", "tab:Finanzas", "tab:Finanzas"))
			p.append(_paso("El estadio", "El estadio es el negocio: aforo, entradas, palcos, tiendas. Cada obra cuesta, pero cada asiento lleno paga.", "Visita el estadio", "grupos", "tab:Estadio", "tab:Estadio"))
			p.append(_paso("Las instalaciones", "Y lo que no se ve: ciudad deportiva, gimnasio, enfermería, academia. Un club grande se construye aquí.", "Revisa la infraestructura", "grupos", "chip:Club|infra", "chip:Club|infra"))
			p.append(_ficha_estrella(ctx, "Y el activo más caro del club: %s, media [b]%d[/b]. Vale más que la tribuna norte."))
			p.append(_paso("El mercado", "Si quiere un equipo a su medida, el mercado está abierto. Su dinero, sus reglas.", "Abre el mercado", "dinero", "tab:Mercado", "tab:Mercado"))
			p.append_array(_pasos_comunes(false))
			p.append(_final("Un consejo de alguien que ha visto pasar a muchos dueños: los clubes se pierden despacio y se arruinan de golpe."))
		"jeque":
			g["lugar"] = "Aeropuerto · pista privada"
			g["sonido"] = "ovacion"
			g["prologo"] = "El avión aterriza a mediodía. En la pista esperan cámaras, periodistas y un coche negro con los colores de %s.\n\n[b]%s[/b] baja la escalerilla contigo.\n\n[i]«El fondo ha comprado el club. El presupuesto no es un problema. El único problema sería no ganar.»[/i]" % [club, yo]
			p.append(_paso("Sin límite", "Bienvenido a su club. La caja es, a efectos prácticos, [b]infinita[/b]. Nadie le va a pedir cuentas. Solo títulos.", "", "estado"))
			p.append(_ficha_estrella(ctx, "Hoy el mejor de la plantilla es %s, media [b]%d[/b]. Con todo respeto: queremos a alguien mejor que él en cada puesto."))
			p.append(_paso("De compras", "El mercado es suyo. Busque a los mejores del mundo y haga ofertas que no puedan rechazar.", "Abre el mercado", "dinero", "tab:Mercado", "tab:Mercado"))
			p.append(_paso("El estadio", "Y un club así necesita un estadio a la altura. Amplíe, reforme, construya.", "Visita el estadio", "grupos", "tab:Estadio", "tab:Estadio"))
			p.append(_paso("La imagen", "El mundo entero va a mirar esta camiseta. Si quiere cambiarla, escudo y equipación están en [b]GENTE[/b].", "Mira la equipación", "grupos", "chip:Gente|kits", "chip:Gente|kits"))
			p.append_array(_pasos_comunes(false))
			p.append(_final("El fondo tiene paciencia. Poca, pero tiene."))
		"creador":
			g["lugar"] = "Un campo alquilado · día uno"
			g["sonido"] = "silbato"
			g["prologo"] = "Un campo alquilado, un escudo recién dibujado y un grupo de jugadores que nadie conoce. %s no existía ayer.\n\n[b]%s[/b], tu socio desde el primer día, te pasa el brazo por los hombros.\n\n[i]«Empezamos desde abajo del todo. Justo como queríamos.»[/i]" % [club, yo]
			p.append(_paso("Desde abajo", "Somos el último de %s. Nadie espera nada de nosotros, y eso es una ventaja: todo lo que venga es ganancia." % ctx["liga"], "", "estado"))
			p.append(_paso("Nuestra cara", "Lo primero es que se nos reconozca. El escudo y los colores son nuestros: los que tú elijas.", "Abre la Identidad Visual", "grupos", "chip:Gente|identidad", "chip:Gente|identidad"))
			p.append(_paso("La camiseta", "Y la camiseta. La que dentro de veinte años lleve un chico en la grada.", "Diseña la equipación", "grupos", "chip:Gente|kits", "chip:Gente|kits"))
			p.append(_paso("Los nuestros", "Estos son los que creyeron en el proyecto. Ábrelos y apréndete sus nombres.", "Abre el plantel", "plantel", "tab:Mi plantel", "tab:Mi plantel"))
			p.append(_paso("A qué jugamos", "Sin estrellas, lo que nos salva es el orden. Decide a qué juega este equipo.", "Ajusta la táctica", "plantel", "tab:Táctica", "tab:Táctica"))
			p.append(_paso("El primer rival", "Nuestro primer partido oficial: [b]%s[/b]. Mira quién es." % _rival(ctx), "Estudia al rival", "partido", "tab:Partido", "tab:Partido"))
			p.append_array(_pasos_comunes(true))
			p.append(_final("Guarda la entrada de hoy. Algún día valdrá una fortuna."))
		_:
			g["lugar"] = "%s · lunes, 7:40" % estadio
			g["sonido"] = "silbato"
			g["prologo"] = "Lunes, siete y cuarenta de la mañana. El taxi te deja frente al [b]%s[/b]. Hace frío y huele a césped recién cortado.\n\nEn la puerta, con las manos en los bolsillos, te espera [b]%s[/b].\n\n[i]«Bienvenido a %s, míster. Aquí la paciencia dura lo que dura una mala racha.»[/i]" % [estadio, yo, club]
			p.append(_paso("Lo que se espera", "Pase, pase. Le cuento lo que espera el directorio de usted esta temporada: [b]%s[/b].\n\nAhí arriba verá también la [b]confianza[/b] que le tenemos. Hoy es %d. Si baja mucho, no seré yo quien le pueda sostener." % [_obj(ctx), int(ctx["confianza"])], "", "estado"))
			p.append(_paso("El vestuario", "Vamos al vestuario. Estos son sus jugadores.", "Abre el plantel", "plantel", "tab:Mi plantel", "tab:Mi plantel"))
			p.append(_ficha_estrella(ctx, "Ese es %s, el mejor que tenemos: media [b]%d[/b]. La afición lo adora. Si lo sienta, más le vale ganar."))
			if not (ctx["joven"] as Dictionary).is_empty():
				p.append(_ficha(ctx["joven"], "La promesa", "Y no pierda de vista a [b]%s[/b]: %d años y un techo que ilusiona. Dele minutos y crecerá." % [ctx["joven"]["nombre"], int(ctx["joven"]["edad"])]))
			p.append(_paso("La pizarra", "La pizarra es suya: sistema, once titular, instrucciones. Aquí nadie le va a decir cómo jugar.", "Ajusta la táctica", "plantel", "tab:Táctica", "tab:Táctica"))
			p.append(_paso("El domingo", "El domingo jugamos %s contra [b]%s[/b]. Estúdielos: cómo juegan, quién llega tocado, qué dicen las casas de apuestas." % ["en casa" if bool(ctx["local"]) else "fuera", _rival(ctx)], "Estudia al rival", "partido", "tab:Partido", "tab:Partido"))
			p.append(_paso("El camarín", "Y ojo con el camarín. Si deja fuera al líder de un grupo muchas semanas, el grupo entero se le vuelve en contra.", "Visita el camarín", "plantel", "tab:Camarín", "tab:Camarín"))
			p.append_array(_pasos_comunes(true))
			p.append(_final("Le dejo trabajar. Nos vemos el domingo en el palco."))
	g["pasos"] = p
	return g

# ---------------------------------------------------------------------------
#  EL GUION
# ---------------------------------------------------------------------------

## Compatibilidad: los pasos de un modo con solo el nombre del club.
static func pasos_para(modo: String, club: String) -> Array[Dictionary]:
	return guion(modo, contexto(null, club))["pasos"]

static func visto(modo: String = "general") -> bool:
	var c := ConfigFile.new()
	if c.load(AJUSTES) != OK:
		return false
	return bool(c.get_value(SECCION, modo, false))

static func marcar_visto(modo: String = "general") -> void:
	var c := ConfigFile.new()
	c.load(AJUSTES)
	c.set_value(SECCION, modo, true)
	c.save(AJUSTES)

static func aspecto_mentor(modo: String, m: Dictionary) -> Dictionary:
	var pedido := {"pelo": "canoso"} if bool(m.get("canas", false)) else {}
	var c := ConfigFile.new()
	if c.load(AJUSTES) == OK:
		var guardado: Variant = c.get_value(SECCION_ASPECTO, modo, {})
		if guardado is Dictionary:
			for k: String in guardado:
				pedido[k] = guardado[k]
	return PersonaRealista.aspecto(String(m.get("semilla", modo)), pedido)

static func _cara_mentor(m: Dictionary, ctx: Dictionary) -> Texture2D:
	var j := Jugador.new()
	j.id = String(m["semilla"])
	j.nombre = String(m["nombre"])
	j.edad = 56 if bool(m.get("canas", false)) else 44
	if bool(m.get("canas", false)):
		j.look = {"peloC": "#9b9b98"}
	return Cara.textura(j, String(ctx["c1"]), String(ctx["c2"]), 84)

func _pintar_retrato(ctx: Dictionary) -> void:
	for h in _marco_cara.get_children():
		h.queue_free()
	if PersonaRealista.disponible():
		_marco_cara.add_child(PersonaRealista.retrato(_aspecto, Vector2i(100, 120), _fondo_retrato, "cara"))
	else:
		var r := TextureRect.new()
		r.custom_minimum_size = Vector2(84, 84)
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.texture = _cara_mentor(_guion["mentor"], ctx)
		_marco_cara.add_child(r)

static func guardar_aspecto_mentor(modo: String, asp: Dictionary) -> void:
	var c := ConfigFile.new()
	c.load(AJUSTES)
	var guardar := {}
	for k in ["ropa", "pelo", "piel", "pantalon"]:
		if asp.has(k):
			guardar[k] = asp[k]
	c.set_value(SECCION_ASPECTO, modo, guardar)
	c.save(AJUSTES)

func cambiar_aspecto(clave: String, valor: String, ctx: Dictionary = {}) -> void:
	_aspecto[clave] = valor
	guardar_aspecto_mentor(_modo, _aspecto)
	_pintar_retrato(ctx if not ctx.is_empty() else contexto(null))
	(self as Tutorial)._pintar_panel_aspecto(ctx)
