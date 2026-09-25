class_name Tutorial
extends Control
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
const COL_BORDE := Color("3fa06a")
const COL_TEXTO := Color("e9eeea")
const COL_SUAVE := Color("8ea595")
const COL_ORO := Color("c9a227")
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
var _retrato: TextureRect
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

## El mentor de cada modo: quién te recibe el primer día. El nombre sale del
## club -siempre el mismo para el mismo club- y nunca de `Azar`, que es el
## generador de la partida y no se puede mover desde la interfaz.
const _PILAS := ["Ernesto", "Ramiro", "Aurelio", "Clemente", "Octavio", "Humberto", "Leopoldo",
	"Fausto", "Anselmo", "Rigoberto", "Teodoro", "Gilberto"]
const _APELLIDOS := ["Valdivia", "Arancibia", "Montalvo", "Echenique", "Sotomayor", "Quiroga",
	"Villaseca", "Bustamante", "Larrondo", "Iturriaga", "Cifuentes", "Barahona"]

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

# ---------------------------------------------------------------------------
#  EL GUION
# ---------------------------------------------------------------------------

## Compatibilidad: los pasos de un modo con solo el nombre del club.
static func pasos_para(modo: String, club: String) -> Array[Dictionary]:
	return guion(modo, contexto(null, club))["pasos"]

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

static func _ficha_estrella(ctx: Dictionary, frase: String) -> Dictionary:
	var e: Dictionary = ctx["estrella"]
	if e.is_empty():
		return _paso("La estrella", "Toque a cualquier jugador y su ficha se abre aquí: atributos, forma, moral, contrato.",
			"Abre la ficha de un jugador", "ficha", "ficha")
	return _ficha(e, "La estrella", frase % [e["nombre"], int(e["ovr"])])

static func _ficha(j: Dictionary, titulo: String, texto: String) -> Dictionary:
	return _paso(titulo, texto + "\n\nSu ficha lo dice todo: atributos, forma, moral, contrato.",
		"Abre la ficha de %s" % j["nombre"], "ficha", "ficha:%s" % j["id"], "ficha:%s" % j["id"])

static func _final(despedida: String) -> Dictionary:
	return {"titulo": "¡A jugar!", "texto": despedida, "final": true}

static func _obj(ctx: Dictionary) -> String:
	return String(ctx["objetivo"]).to_lower() if String(ctx["objetivo"]) != "" else "una temporada digna"

static func _caja(ctx: Dictionary) -> String:
	return String(ctx["caja"]) if String(ctx["caja"]) != "" else "lo justo"

static func _rival(ctx: Dictionary) -> String:
	return String(ctx["rival"]) if String(ctx["rival"]) != "" else "nuestro próximo rival"

static func _dt_o(ctx: Dictionary) -> String:
	return "[b]%s[/b]" % ctx["dt"] if String(ctx["dt"]) != "" else "el entrenador"

static func _miles(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

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

# ---------------------------------------------------------------------------
#  INTERFAZ
# ---------------------------------------------------------------------------

func iniciar(principal: Node, modo: String, club: String) -> void:
	_principal = principal
	var mundo: Mundo = null
	if principal != null and "mundo" in principal:
		mundo = principal.get("mundo")
	var ctx := contexto(mundo, club)
	_guion = guion(modo, ctx)
	_pasos = _guion["pasos"]
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	## Las cuatro sombras rodean el hueco del control resaltado: atenúan el
	## resto de la pantalla sin taparle los clics a nadie.
	for k in 4:
		var s := ColorRect.new()
		s.color = Color(0, 0, 0, 0.45)
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(s)
		_sombras.append(s)
	_marco = Panel.new()
	_marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var borde := StyleBoxFlat.new()
	borde.bg_color = Color(0, 0, 0, 0)
	borde.border_color = COL_ORO
	borde.set_border_width_all(3)
	borde.set_corner_radius_all(8)
	_marco.add_theme_stylebox_override("panel", borde)
	add_child(_marco)
	_construir_tarjeta(ctx)
	_construir_prologo(mundo, ctx)
	_tarjeta.visible = false
	_marco.visible = false
	_fase = "prologo"
	_escribir(_lbl_prologo, String(_guion["prologo"]))
	_sonar(String(_guion.get("sonido", "")))

func fase() -> String:
	return _fase

func guion_actual() -> Dictionary:
	return _guion

## EL PRÓLOGO: franjas de cine, el escudo, el lugar y la escena a máquina.
func _construir_prologo(mundo: Mundo, ctx: Dictionary) -> void:
	_prologo = Control.new()
	_prologo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_prologo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_prologo)
	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.02, 0.03, 0.03, 0.96)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prologo.add_child(fondo)
	## Un velo con el color del club, que sube desde abajo.
	var c1 := Color(String(ctx["c1"]))
	var grad := Gradient.new()
	grad.set_color(0, Color(c1, 0.0))
	grad.set_color(1, Color(c1, 0.38))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	var velo := TextureRect.new()
	velo.texture = gt
	velo.stretch_mode = TextureRect.STRETCH_SCALE
	velo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prologo.add_child(velo)
	## Las franjas negras de cine.
	for arriba: bool in [true, false]:
		var f := ColorRect.new()
		f.color = Color.BLACK
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		f.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if arriba else Control.PRESET_BOTTOM_WIDE)
		f.custom_minimum_size = Vector2(0, 66)
		## La de abajo crece hacia arriba: anclada al borde, crecer hacia
		## abajo la dejaría fuera de la pantalla.
		if not arriba:
			f.grow_vertical = Control.GROW_DIRECTION_BEGIN
		_prologo.add_child(f)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prologo.add_child(centro)
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(minf(720.0, get_viewport_rect().size.x - 48.0), 0)
	v.add_theme_constant_override("separation", 16)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(v)
	if mundo != null and mundo.mi_club() != null:
		var esc := TextureRect.new()
		esc.texture = Escudo.textura(mundo.mi_club(), 110)
		esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		esc.custom_minimum_size = Vector2(110, 110)
		esc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(esc)
	var lugar := Label.new()
	lugar.text = String(_guion.get("lugar", "")).to_upper()
	if int(ctx["anio"]) > 0:
		lugar.text += "  ·  TEMPORADA %d" % int(ctx["anio"])
	lugar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lugar.add_theme_font_size_override("font_size", 13)
	lugar.add_theme_color_override("font_color", COL_ORO)
	v.add_child(lugar)
	_lbl_prologo = RichTextLabel.new()
	_lbl_prologo.bbcode_enabled = true
	_lbl_prologo.fit_content = true
	_lbl_prologo.scroll_active = false
	_lbl_prologo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_prologo.add_theme_font_size_override("normal_font_size", 20)
	_lbl_prologo.add_theme_font_size_override("bold_font_size", 20)
	_lbl_prologo.add_theme_font_size_override("italics_font_size", 20)
	_lbl_prologo.add_theme_color_override("default_color", COL_TEXTO)
	v.add_child(_lbl_prologo)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 14)
	v.add_child(fila)
	var saltar := Button.new()
	saltar.text = "Saltar tutorial"
	saltar.flat = true
	saltar.add_theme_color_override("font_color", COL_SUAVE)
	saltar.pressed.connect(func() -> void: _terminar(false))
	fila.add_child(saltar)
	_btn_prologo = Button.new()
	_btn_prologo.text = "Entrar ▸"
	_btn_prologo.custom_minimum_size = Vector2(150, 40)
	_btn_prologo.add_theme_font_size_override("font_size", 16)
	_btn_prologo.pressed.connect(pulsar_prologo)
	fila.add_child(_btn_prologo)
	## Un clic en cualquier parte acaba de escribir la escena.
	_prologo.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and _escribiendo:
			_completar_escritura())

## "Entrar": si la escena se está escribiendo la completa; si no, pasa al
## primer día con el mentor.
func pulsar_prologo() -> void:
	if _escribiendo:
		_completar_escritura()
		return
	if _fase != "prologo":
		return
	_fase = "dialogo"
	var tw := create_tween()
	tw.tween_property(_prologo, "modulate:a", 0.0, 0.45)
	tw.tween_callback(_prologo.queue_free)
	_tarjeta.visible = true
	_tarjeta.modulate.a = 0.0
	create_tween().tween_property(_tarjeta, "modulate:a", 1.0, 0.45)
	_sonar("abrir")
	_mostrar(0)

## LA TARJETA DEL MENTOR: retrato, nombre y cargo, lo que dice, y la misión.
func _construir_tarjeta(ctx: Dictionary) -> void:
	var c1 := Color(String(ctx["c1"]))
	_tarjeta = PanelContainer.new()
	_tarjeta.mouse_filter = Control.MOUSE_FILTER_STOP
	var e := StyleBoxFlat.new()
	e.bg_color = Color(COL_FONDO, 0.97)
	e.border_color = c1.lerp(COL_BORDE, 0.35)
	e.set_border_width_all(2)
	e.border_width_top = 4
	e.set_corner_radius_all(12)
	e.shadow_color = Color(0, 0, 0, 0.55)
	e.shadow_size = 14
	e.content_margin_left = 16; e.content_margin_right = 18
	e.content_margin_top = 14; e.content_margin_bottom = 14
	_tarjeta.add_theme_stylebox_override("panel", e)
	var ancho := minf(ANCHO_TARJETA, get_viewport_rect().size.x - 24.0)
	_tarjeta.custom_minimum_size = Vector2(ancho, 0)
	add_child(_tarjeta)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	_tarjeta.add_child(h)
	## El retrato del mentor, con la misma cara procedural que los jugadores.
	var marco_cara := PanelContainer.new()
	var em := StyleBoxFlat.new()
	em.bg_color = c1.darkened(0.35)
	em.border_color = COL_ORO
	em.set_border_width_all(2)
	em.set_corner_radius_all(44)
	marco_cara.add_theme_stylebox_override("panel", em)
	marco_cara.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(marco_cara)
	_retrato = TextureRect.new()
	_retrato.custom_minimum_size = Vector2(84, 84)
	_retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_retrato.texture = _cara_mentor(_guion["mentor"], ctx)
	marco_cara.add_child(_retrato)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var cab := HBoxContainer.new()
	v.add_child(cab)
	var quien := VBoxContainer.new()
	quien.add_theme_constant_override("separation", 0)
	quien.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(quien)
	_lbl_nombre = Label.new()
	_lbl_nombre.text = String(_guion["mentor"]["nombre"])
	_lbl_nombre.add_theme_font_size_override("font_size", 17)
	_lbl_nombre.add_theme_color_override("font_color", COL_ORO)
	quien.add_child(_lbl_nombre)
	_lbl_cargo = Label.new()
	_lbl_cargo.text = String(_guion["mentor"]["cargo"])
	_lbl_cargo.add_theme_font_size_override("font_size", 12)
	_lbl_cargo.add_theme_color_override("font_color", COL_SUAVE)
	quien.add_child(_lbl_cargo)
	_lbl_progreso = Label.new()
	_lbl_progreso.add_theme_font_size_override("font_size", 12)
	_lbl_progreso.add_theme_color_override("font_color", COL_SUAVE)
	_lbl_progreso.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	cab.add_child(_lbl_progreso)
	_lbl_texto = RichTextLabel.new()
	_lbl_texto.bbcode_enabled = true
	_lbl_texto.fit_content = true
	_lbl_texto.scroll_active = false
	_lbl_texto.add_theme_font_size_override("normal_font_size", 15)
	_lbl_texto.add_theme_font_size_override("bold_font_size", 15)
	_lbl_texto.add_theme_font_size_override("italics_font_size", 15)
	_lbl_texto.add_theme_color_override("default_color", COL_TEXTO)
	_lbl_texto.custom_minimum_size = Vector2(ancho - 150.0, 0)
	_lbl_texto.mouse_filter = Control.MOUSE_FILTER_STOP
	_lbl_texto.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and _escribiendo:
			_completar_escritura())
	v.add_child(_lbl_texto)
	## La misión del paso, como una tarea con su casilla.
	_caja_mision = PanelContainer.new()
	var ms := StyleBoxFlat.new()
	ms.bg_color = Color(COL_ORO, 0.10)
	ms.border_color = Color(COL_ORO, 0.55)
	ms.set_border_width_all(1)
	ms.set_corner_radius_all(6)
	ms.content_margin_left = 10; ms.content_margin_right = 10
	ms.content_margin_top = 6; ms.content_margin_bottom = 6
	_caja_mision.add_theme_stylebox_override("panel", ms)
	v.add_child(_caja_mision)
	_lbl_mision = Label.new()
	_lbl_mision.add_theme_font_size_override("font_size", 13)
	_lbl_mision.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caja_mision.add_child(_lbl_mision)
	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 8)
	v.add_child(botones)
	var saltar := Button.new()
	saltar.text = "Saltar"
	saltar.flat = true
	saltar.add_theme_color_override("font_color", COL_SUAVE)
	saltar.pressed.connect(func() -> void: _terminar(false))
	botones.add_child(saltar)
	var empuje := Control.new()
	empuje.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botones.add_child(empuje)
	_btn_mostrar = Button.new()
	_btn_mostrar.text = "Muéstramelo"
	_btn_mostrar.pressed.connect(_hacer_por_mi)
	botones.add_child(_btn_mostrar)
	_btn_extra = Button.new()
	_btn_extra.text = "Ir al partido ▸"
	_btn_extra.visible = false
	_btn_extra.pressed.connect(func() -> void:
		_accion("tab:Partido")
		_terminar(true))
	botones.add_child(_btn_extra)
	_btn_atras = Button.new()
	_btn_atras.text = "◂"
	_btn_atras.tooltip_text = "Paso anterior"
	_btn_atras.pressed.connect(func() -> void: _mostrar(_i - 1))
	botones.add_child(_btn_atras)
	_btn_sig = Button.new()
	_btn_sig.custom_minimum_size = Vector2(110, 0)
	_btn_sig.pressed.connect(pulsar_siguiente)
	botones.add_child(_btn_sig)

static func _cara_mentor(m: Dictionary, ctx: Dictionary) -> Texture2D:
	var j := Jugador.new()
	j.id = String(m["semilla"])
	j.nombre = String(m["nombre"])
	j.edad = 56 if bool(m.get("canas", false)) else 44
	if bool(m.get("canas", false)):
		j.look = {"peloC": "#9b9b98"}
	return Cara.textura(j, String(ctx["c1"]), String(ctx["c2"]), 84)

## "Siguiente": completa el texto si se está escribiendo; si no, avanza.
func pulsar_siguiente() -> void:
	if _escribiendo:
		_completar_escritura()
		return
	if bool(paso_actual().get("final", false)):
		_terminar(true)
		return
	_mostrar(_i + 1)

func _mostrar(i: int) -> void:
	if i >= _pasos.size():
		_terminar(true)
		return
	_fase = "dialogo"
	_i = clampi(i, 0, _pasos.size() - 1)
	var paso := _pasos[_i]
	var final := bool(paso.get("final", false))
	var texto := String(paso["texto"])
	if final:
		texto = "[i]«%s»[/i]\n\n%s" % [texto, _resumen_misiones()]
	_escribir(_lbl_texto, texto)
	_lbl_progreso.text = "" if final else "%d / %d" % [_i + 1, _pasos.size() - 1]
	_btn_atras.visible = _i > 0 and not final
	_btn_sig.text = "¡A jugar!" if final else "Siguiente ▸"
	_btn_extra.visible = final and _puede_dirigir()
	_hecho_al_entrar = _hecho(paso)
	_t_cumplida = -1.0
	_pintar_mision()
	_t = 0.0
	_colocar()

func _puede_dirigir() -> bool:
	if _principal == null or not ("mundo" in _principal):
		return false
	var m: Mundo = _principal.get("mundo")
	return m != null and m.roles != null and m.roles.puede_alinear()

func _pintar_mision() -> void:
	var paso := paso_actual()
	_caja_mision.visible = paso.has("mision")
	_btn_mostrar.visible = paso.has("mostrar") and not _cumplidas.has(_i)
	if not paso.has("mision"):
		return
	var misiones := 0
	var n := 0
	for k in _pasos.size():
		if _pasos[k].has("mision"):
			misiones += 1
			if k <= _i:
				n = misiones
	if _cumplidas.has(_i):
		_lbl_mision.text = "✔  MISIÓN %d/%d · %s  —  ¡hecho!" % [n, misiones, paso["mision"]]
		_lbl_mision.add_theme_color_override("font_color", COL_HECHO)
	else:
		_lbl_mision.text = "🎯  MISIÓN %d/%d · %s" % [n, misiones, paso["mision"]]
		_lbl_mision.add_theme_color_override("font_color", COL_ORO)

func _resumen_misiones() -> String:
	var lineas: Array[String] = []
	for k in _pasos.size():
		if _pasos[k].has("mision"):
			var ok := _cumplidas.has(k)
			lineas.append("[color=#%s]%s  %s[/color]" % [
				(COL_HECHO if ok else COL_SUAVE).to_html(false), "✔" if ok else "·", _pasos[k]["mision"]])
	return "[b]Tu primer día:[/b] %d de %d misiones.\n%s\n\nPuedes repetir esto cuando quieras en [b]AJUSTES → Interfaz[/b]." % [
		_cumplidas.size(), lineas.size(), "\n".join(lineas)]

func paso_actual() -> Dictionary:
	return _pasos[_i] if _i < _pasos.size() else {}

func indice() -> int:
	return _i

func misiones_cumplidas() -> int:
	return _cumplidas.size()

func _hacer_por_mi() -> void:
	var paso := paso_actual()
	if paso.has("mostrar"):
		_accion(String(paso["mostrar"]))

func _accion(clave: String) -> void:
	if _principal != null and _principal.has_method("tutorial_accion"):
		_principal.call("tutorial_accion", clave)

func _hecho(paso: Dictionary) -> bool:
	if not paso.has("hecho") or _principal == null or not _principal.has_method("tutorial_hecho"):
		return false
	return bool(_principal.call("tutorial_hecho", String(paso["hecho"])))

func _terminar(completo: bool) -> void:
	terminado.emit(completo)
	queue_free()

func _sonar(nombre: String) -> void:
	if nombre != "" and Sonido.NOMBRES.has(nombre):
		Sonido.toca(nombre)

# --- máquina de escribir -----------------------------------------------------

func _escribir(lbl: RichTextLabel, texto: String) -> void:
	lbl.text = texto
	lbl.visible_characters = 0
	_escribiendo = true

func _etiqueta_activa() -> RichTextLabel:
	return _lbl_prologo if _fase == "prologo" else _lbl_texto

func escribiendo() -> bool:
	return _escribiendo

func _completar_escritura() -> void:
	var lbl := _etiqueta_activa()
	if lbl != null:
		lbl.visible_characters = -1
	_escribiendo = false

func _objetivo() -> Control:
	var paso := paso_actual()
	if _fase != "dialogo" or not paso.has("objetivo") or _principal == null or not _principal.has_method("tutorial_objetivo"):
		return null
	var c: Variant = _principal.call("tutorial_objetivo", String(paso["objetivo"]))
	if c is Control and is_instance_valid(c) and (c as Control).is_visible_in_tree():
		return c
	return null

func _process(delta: float) -> void:
	## Siempre por encima: los hubs y los avisos se cuelgan de la misma raíz
	## después de nosotros.
	if get_parent() != null and get_index() != get_parent().get_child_count() - 1:
		move_to_front()
	_t += delta
	if _escribiendo:
		var lbl := _etiqueta_activa()
		if lbl != null:
			var total := lbl.get_total_character_count()
			lbl.visible_characters = mini(total, lbl.visible_characters + maxi(1, int(ceil(LETRAS_SEG * delta))))
			if lbl.visible_characters >= total:
				_completar_escritura()
	if _fase == "prologo":
		_btn_prologo.text = "▸▸" if _escribiendo else "Entrar ▸"
		return
	var paso := paso_actual()
	## La misión se cumple cuando el jugador HACE la cosa: el paso pasa de
	## no-hecho a hecho. Si ya estaba hecho al llegar, primero tiene que dejar
	## de estarlo -si no, un paso se "cumpliría" solo sin que nadie tocara nada-.
	if _t_cumplida < 0.0 and paso.has("hecho") and not _cumplidas.has(_i) and _t > 0.3:
		var ahora := _hecho(paso)
		if ahora and not _hecho_al_entrar:
			_cumplidas[_i] = true
			_t_cumplida = _t
			_pintar_mision()
			_sonar("logro")
		elif not ahora:
			_hecho_al_entrar = false
	if _t_cumplida >= 0.0 and _t - _t_cumplida > 1.1:
		_t_cumplida = -1.0
		_mostrar(_i + 1)
		return
	_colocar()

## Coloca el marco, las sombras y la tarjeta. Se recalcula cada cuadro: el
## control resaltado puede moverse (una fila que se reconstruye, la ventana que
## cambia de tamaño). Sin objetivo, la tarjeta va abajo al centro, como el
## subtítulo de una conversación.
func _colocar() -> void:
	## La tarjeta vuelve a su tamaño mínimo: si no, se queda con el alto del
	## texto más largo que haya mostrado y los pasos cortos flotan en un hueco.
	_tarjeta.reset_size()
	var pantalla := get_viewport_rect().size
	var obj := _objetivo()
	if obj == null:
		_marco.visible = false
		_poner_sombras(Rect2(pantalla * 0.5, Vector2.ZERO), pantalla, true)
		_tarjeta.position = Vector2((pantalla.x - _tarjeta.size.x) * 0.5, maxf(8.0, pantalla.y - _tarjeta.size.y - 28.0))
		return
	var r := obj.get_global_rect().grow(6.0)
	_marco.visible = true
	_marco.position = r.position
	_marco.size = r.size
	## El latido: el borde respira para que el ojo lo encuentre.
	_marco.modulate.a = 0.65 + 0.35 * sin(_t * 5.0)
	_poner_sombras(r, pantalla, false)
	## La tarjeta debajo del objetivo si cabe; si no, encima; si tampoco, al
	## lado. Siempre dentro de la pantalla.
	var ts := _tarjeta.size
	var pos := Vector2(r.position.x, r.end.y + 12.0)
	if pos.y + ts.y > pantalla.y - 8.0:
		pos.y = r.position.y - ts.y - 12.0
	if pos.y < 8.0:
		pos = Vector2(r.end.x + 12.0, r.position.y)
		if pos.x + ts.x > pantalla.x - 8.0:
			pos.x = r.position.x - ts.x - 12.0
	pos.x = clampf(pos.x, 8.0, maxf(8.0, pantalla.x - ts.x - 8.0))
	pos.y = clampf(pos.y, 8.0, maxf(8.0, pantalla.y - ts.y - 8.0))
	_tarjeta.position = pos

func _poner_sombras(hueco: Rect2, pantalla: Vector2, todo: bool) -> void:
	if todo:
		_sombras[0].position = Vector2.ZERO
		_sombras[0].size = pantalla
		for k in range(1, 4):
			_sombras[k].size = Vector2.ZERO
		return
	var h := hueco
	_sombras[0].position = Vector2.ZERO
	_sombras[0].size = Vector2(pantalla.x, maxf(0.0, h.position.y))
	_sombras[1].position = Vector2(0, h.end.y)
	_sombras[1].size = Vector2(pantalla.x, maxf(0.0, pantalla.y - h.end.y))
	_sombras[2].position = Vector2(0, h.position.y)
	_sombras[2].size = Vector2(maxf(0.0, h.position.x), h.size.y)
	_sombras[3].position = Vector2(h.end.x, h.position.y)
	_sombras[3].size = Vector2(maxf(0.0, pantalla.x - h.end.x), h.size.y)
