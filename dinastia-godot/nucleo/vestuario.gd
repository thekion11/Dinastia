class_name Vestuario
extends RefCounted
## El camarín: los grupos que se forman solos, la cabeza de cada jugador y el
## papel que le prometiste a cada uno.
##
## Son tres mecanismos distintos que comparten la misma materia prima —el humor
## del plantel— y por eso viven juntos:
##
##   1. LAS CAMARILLAS. Los jugadores se agrupan por nacionalidad minoritaria,
##      por edad y por representante. Cada grupo tiene un líder, y sentar al
##      líder tres semanas seguidas le baja el ánimo al grupo entero.
##   2. LA CABEZA. Ansiedad y confianza por jugador. La ansiedad sube con las
##      lesiones y la mala racha, y si se dispara el jugador pide ayuda y se
##      pierde un par de semanas.
##   3. EL ROL EN EL PLANTEL. Le prometes ser intocable o le dices que es
##      prescindible, y cada semana se comprueba si le estás cumpliendo.
##
## POR QUÉ ESTO NO ES DECORACIÓN. Todo lo de aquí termina en un número que el
## motor de partido ya lee:
##
##   · La moral entra en `Partido._media_linea()` como `0.9 + 0.002 * moral`.
##     Un vestuario roto pierde puntos de fuerza en cada línea, todas las
##     semanas. Es la vía principal, y la mueven las camarillas, el rol
##     incumplido y la deriva de satisfacción.
##   · `factor_ataque()` y `factor_defensa()` entran por `Club.bonus_ataque` /
##     `Club.bonus_defensa`, la puerta que el simulador consulta desde el primer
##     día. Ahí van la química de los hermanos, los roles tácticos del once y el
##     ánimo del vestuario.
##
## Un menú de camarín precioso que no toca ninguno de esos dos números sería el
## error que este proyecto ya ha pagado varias veces.
##
## POR QUÉ LLEVA SUS PROPIAS FICHAS. `Jugador` no tiene —ni va a tener— campos
## de ansiedad, clan, rol prometido ni hermano. En el HTML todo eso colgaba del
## jugador (`j.mente`, `j.clan`, `j.rolClub`, `j.rolPJ`, `j.hermanoDe`) y
## cualquiera de sus 847 funciones podía pisarlo. Aquí vive indexado por id de
## jugador, exactamente como hace `Medico` con el historial de lesiones.
##
## El azar sale SIEMPRE de `Azar`: una crisis de ansiedad puede costar un
## partido importante, y si no es repetible no se puede reproducir la partida
## que reporte el usuario.

## Lo que sale en el diario. La interfaz se engancha aquí; el simulador no sabe
## que hay una interfaz.
signal noticia(titulo: String, cuerpo: String)
## Un grupo del vestuario se ha hartado de que su líder no juegue.
signal clan_enfadado(clan: Dictionary, lider: Jugador)
## El jugador se rompió por dentro y pide ayuda: semanas de baja psicológica.
signal crisis_mental(j: Jugador, semanas: int)
## Le prometiste un papel y no se lo estás dando. `ratio` es su porcentaje real
## de titularidades.
signal rol_incumplido(j: Jugador, ratio: float)
## Dinero que sale por una terapia, para el libro de movimientos.
signal gasto(concepto: String, monto: int)
## Aparece un hermano (o un gemelo) de alguien del plantel.
signal hermanos_nuevos(nuevo: Jugador, base: Jugador, gemelos: bool)

# ---------------------------------------------------------------------------
#  NÚMEROS DEL HTML
# ---------------------------------------------------------------------------

## Cada cuántas semanas se vuelven a dibujar los grupos (`G.sem%6===0`).
const CADA_CUANTAS_SEMANAS := 6
## Un grupo necesita tres para existir. Con dos no es una camarilla, son dos
## que se sientan juntos.
const MIEMBROS_MINIMOS := 3
## Semanas seguidas con el líder fuera del once antes de que el grupo estalle.
const PACIENCIA_LIDER := 3
## Semanas de rol cumplido que hacen falta antes de juzgar nada. Con menos, un
## lesionado de dos semanas ya "incumplía" su promesa de titular.
const ROL_MINIMO_SEMANAS := 6
## Y a partir de aquí la ventana se cierra sola aunque todo vaya bien, para que
## la cuenta mire el mes que viene y no la temporada pasada.
const ROL_VENTANA_MAX := 12
## Ansiedad a partir de la cual el jugador puede quebrarse.
const ANSIEDAD_CRISIS := 82
## Ansiedad "de fábrica" del mundo: es la media de `R(4,34)`, el sorteo con el
## que nace todo el mundo en `initMente()`. Se usa como cero del factor de
## ánimo — ver `factor_animo()`.
const ANSIEDAD_NEUTRA := 19.0
## Cuánto pesa un punto de ansiedad en la fuerza del jugador. Sale tal cual de
## `fuerzaJug()`: `(1 - ansiedad * 0.0018)`.
const PESO_ANSIEDAD := 0.0018

## OJO: referencia DÉBIL al mundo, no fuerte.
##
## El mundo guarda su vestuario y el vestuario necesita ver el mundo (el club
## propio, el mercado de nombres, el cuerpo técnico). Con dos referencias
## normales eso es un ciclo, y RefCounted no recoge ciclos: al salir del banco
## de pruebas se quedaban 19.000 objetos sin liberar, porque un Mundo que no
## muere se lleva consigo sus 384 clubes y sus miles de jugadores. Ya han caído
## cuatro clases en esta trampa.
var _ref: WeakRef

## Los grupos del vestuario. Cada uno es un diccionario con: id, tipo, nombre,
## miembros (ids), lider (id), humor (-100..100) y fuera (semanas seguidas con
## el líder en el banco).
var camarillas: Array[Dictionary] = []

var _clan_de: Dictionary = {}      ## id de jugador -> id de camarilla
var _mente: Dictionary = {}        ## id de jugador -> ficha mental
var _rol: Dictionary = {}          ## id de jugador -> clave de ROL_PLANTEL
var _rol_cuenta: Dictionary = {}   ## id de jugador -> {"pj": int, "min": int}
var _rol_tactico: Dictionary = {}  ## id de jugador -> clave de ROLES
var _hermano: Dictionary = {}      ## id de jugador -> id de su hermano

func _init(mundo: Mundo) -> void:
	_ref = weakref(mundo)

func _mundo() -> Mundo:
	return _ref.get_ref() as Mundo

func _club() -> Club:
	var m := _mundo()
	return m.mi_club() if m != null else null

# ---------------------------------------------------------------------------
#  1 · LAS CAMARILLAS
# ---------------------------------------------------------------------------

## Vuelve a dibujar los grupos del vestuario.
##
## La regla que hace que esto no sea un listado de nacionalidades: el país
## MAYORITARIO no forma camarilla, porque ese no es un grupo, es "el equipo".
## Solo las minorías se juntan. Y si una supuesta minoría pasa de la mitad del
## plantel tampoco cuenta, que es el caso del club con dos colonias grandes.
##
## TRAMPA QUE SE ARREGLA AQUÍ: el HTML creaba los grupos con `humor:0` cada vez
## que llamaba a esta función, y la llamaba en diecinueve sitios (tras cada
## fichaje, cada cambio de once, cada carga de partida). El resultado es que el
## enfado de un grupo se borraba antes de llegar a nada y `chequeo_clanes()` no
## se notaba nunca. Aquí el humor y la cuenta de paciencia SOBREVIVEN al
## redibujado si el grupo sigue existiendo con el mismo id. Las fórmulas no se
## tocan; lo que se arregla es que lleguen a aplicarse.
func armar() -> Array[Dictionary]:
	var previos := {}
	for cl in camarillas:
		previos[String(cl["id"])] = cl
	camarillas.clear()
	_clan_de.clear()
	var c := _club()
	if c == null or c.plantilla.is_empty():
		return camarillas
	var pl := c.plantilla

	## Índice de posición en la plantilla. Sirve para romper empates SIEMPRE
	## igual: `sort_custom` de Godot no es estable y sin esto dos partidas con
	## la misma semilla podían elegir líderes distintos.
	var orden := {}
	for i in pl.size():
		orden[pl[i].id] = i

	## --- Colonias por nacionalidad ---
	var por_pais: Dictionary = {}
	for j in pl:
		if not por_pais.has(j.pais):
			por_pais[j.pais] = []
		(por_pais[j.pais] as Array).append(j.id)
	var mayor := ""
	var mayor_n := -1
	for p: String in por_pais:
		var n: int = (por_pais[p] as Array).size()
		if n > mayor_n:
			mayor_n = n
			mayor = p
	var bandera: Dictionary = Datos.tabla("BANDERA")
	if bandera == null:
		bandera = {}
	for p: String in por_pais:
		if p == mayor:
			continue
		var ids: Array = por_pais[p]
		if float(ids.size()) > float(pl.size()) * 0.5:
			continue
		if ids.size() < MIEMBROS_MINIMOS:
			continue
		var nom := "Colonia %s %s" % [String(bandera.get(p, "")), p]
		camarillas.append(_montar_clan("n_" + p, "nacion", nom.strip_edges(), ids, orden, false, previos))

	## --- Veteranos y camada joven ---
	var vets: Array = []
	var jov: Array = []
	for j in pl:
		if j.edad >= 30:
			vets.append(j.id)
		if j.edad <= 21:
			jov.append(j.id)
	if vets.size() >= MIEMBROS_MINIMOS:
		camarillas.append(_montar_clan("vets", "veterania", "Los históricos", vets, orden, false, previos))
	## A los jóvenes los lidera el de más POTENCIAL, no el de más media: en ese
	## grupo el que manda es al que todos ven llegando, no el que hoy juega.
	if jov.size() >= MIEMBROS_MINIMOS:
		camarillas.append(_montar_clan("jov", "cantera", "La camada joven", jov, orden, true, previos))

	## --- Representados por el mismo agente ---
	var por_agente: Dictionary = {}
	for j in pl:
		var a := agente_de(j)
		if not por_agente.has(a):
			por_agente[a] = []
		(por_agente[a] as Array).append(j.id)
	for a: String in por_agente:
		var ids_ag: Array = por_agente[a]
		if ids_ag.size() >= MIEMBROS_MINIMOS:
			camarillas.append(_montar_clan("ag_" + a, "agencia", "Representados por " + a, ids_ag, orden, false, previos))

	## Cada jugador pertenece al PRIMER grupo que lo contiene, no a todos. Si se
	## repartiera el mismo enfado por tres vías, un extranjero veterano con
	## agente conocido cobraría el triple que su compañero de al lado.
	for j in pl:
		for cl in camarillas:
			if (cl["miembros"] as Array).has(j.id):
				_clan_de[j.id] = cl["id"]
				break
	return camarillas

func _montar_clan(cid: String, tipo: String, nombre: String, ids: Array,
		orden: Dictionary, por_potencial: bool, previos: Dictionary) -> Dictionary:
	var m := _mundo()
	var lista := ids.duplicate()
	lista.sort_custom(func(a: String, b: String) -> bool:
		var ja := _jugador(a)
		var jb := _jugador(b)
		var va := 0
		var vb := 0
		if ja != null:
			va = ja.pot if por_potencial else ja.ovr
		if jb != null:
			vb = jb.pot if por_potencial else jb.ovr
		if va != vb:
			return va > vb
		return int(orden.get(a, 0)) < int(orden.get(b, 0)))
	var viejo: Dictionary = previos.get(cid, {})
	return {
		"id": cid,
		"tipo": tipo,
		"nombre": nombre,
		"miembros": lista,
		"lider": (String(lista[0]) if not lista.is_empty() else ""),
		"humor": int(viejo.get("humor", 0)),
		"fuera": int(viejo.get("fuera", 0)),
	}

## El agente que representa a un jugador. Es una elección ESTABLE, no un sorteo:
## sale del hash de su id, igual que en el HTML, para que el mismo jugador tenga
## siempre el mismo representante partida tras partida. Si se sorteara, las
## camarillas por agencia se rehicieran solas cada seis semanas.
func agente_de(j: Jugador) -> String:
	var lista: Array = Datos.tabla("AGENTES")
	if lista == null or lista.is_empty():
		return "sin agente"
	## El mismo hash del HTML: `s*17 + código`, truncado a 32 bits sin signo.
	var h := 3
	for i in j.id.length():
		h = (h * 17 + j.id.unicode_at(i)) & 0xFFFFFFFF
	var fila: Array = lista[h % lista.size()]
	return Nombres.limpiar(String(fila[0]))

func clan_de(j: Jugador) -> Dictionary:
	var cid: String = String(_clan_de.get(j.id, ""))
	return clan_por_id(cid)

func clan_por_id(cid: String) -> Dictionary:
	for cl in camarillas:
		if String(cl["id"]) == cid:
			return cl
	return {}

## Qué pasa cuando sientas al líder de un grupo.
##
## No estalla a la primera: hay tres semanas de paciencia, y un líder lesionado
## o sancionado no cuenta —nadie se enfada porque no juegue el que no puede
## jugar—. Cuando estalla, el golpe lo cobran TODOS los miembros del grupo, que
## es lo que convierte una decisión sobre un jugador en un problema de plantel.
func chequeo_clanes(once_ids: Array) -> void:
	if camarillas.is_empty():
		return
	var c := _club()
	if c == null:
		return
	for cl in camarillas:
		var lider := _jugador(String(cl["lider"]))
		if lider == null or lider.club_id != c.id:
			continue
		var dentro: bool = once_ids.has(cl["lider"])
		if not dentro and lider.lesion <= 0 and lider.suspension <= 0:
			cl["fuera"] = int(cl["fuera"]) + 1
			if int(cl["fuera"]) >= PACIENCIA_LIDER:
				## EL LIDER DEL ARBOL ES INMUNE A LAS REBELIONES.
				## `Entrenamiento.vestuario_de_hierro()` estaba escrita y no la
				## llamaba nadie: el nodo «Lider» costaba un punto y las camarillas
				## se le sublevaban igual. Con el, el enfado se apaga solo.
				var m_ves := _mundo()
				if m_ves != null and m_ves.entrenamiento != null and m_ves.entrenamiento.vestuario_de_hierro():
					cl["fuera"] = 0
					continue
				cl["humor"] = clampi(int(cl["humor"]) - Azar.ent(6, 14), -100, 100)
				for id: String in cl["miembros"]:
					var j := _jugador(id)
					if j == null or j.club_id != c.id:
						continue
					_mover_moral(j, -Azar.ent(1, 4))
					_mover_ansiedad(j, Azar.ent(1, 4))
				cl["fuera"] = 0
				clan_enfadado.emit(cl, lider)
				if Azar.suerte(0.45):
					noticia.emit("🧨 Ruido en el camarín",
						"«%s» no digiere que %s lleve semanas fuera del once. El grupo bajó el ánimo y alguien filtró la interna a la prensa." % [cl["nombre"], lider.nombre])
		else:
			cl["fuera"] = 0
			if int(cl["humor"]) < 0:
				cl["humor"] = clampi(int(cl["humor"]) + 2, -100, 100)

## Sentar a todos a hablar. Puede salir peor de lo que entró: si la reunión
## fracasa el grupo se enfada más, y eso es lo que hace que mediar sea una
## decisión y no un botón de arreglarlo todo.
##
## El psicólogo del HTML (`G.staff.psi`) no existe en este cuerpo técnico; su
## papel lo hacen el espacio de bienestar y la guardería, que es de donde sale
## `Instalaciones.calma_del_vestuario()`. El bono del DT «mediador» entra igual
## que en el HTML.
func mediar(clan_id: String) -> Dictionary:
	var cl := clan_por_id(clan_id)
	if cl.is_empty():
		return {"ok": false, "txt": "ese grupo ya no existe"}
	var m := _mundo()
	var psi := 0.0
	var bono := 0.0
	if m != null:
		if m.obras != null:
			psi = float(m.obras.calma_del_vestuario())
		if m.entrenamiento != null:
			bono = m.entrenamiento.bono_mediacion()
	var p := clampf(0.42 + 0.06 * psi + bono, 0.1, 0.95)
	var c := _club()
	if Azar.suerte(p):
		cl["humor"] = clampi(int(cl["humor"]) + Azar.ent(15, 32), -100, 100)
		for id: String in cl["miembros"]:
			var j := _jugador(id)
			if j == null or c == null or j.club_id != c.id:
				continue
			_mover_moral(j, Azar.ent(2, 6))
			_mover_ansiedad(j, -Azar.ent(3, 8))
		return {"ok": true, "txt": "Reunión productiva: el grupo baja las armas"}
	cl["humor"] = clampi(int(cl["humor"]) - Azar.ent(3, 10), -100, 100)
	return {"ok": false, "txt": "La reunión terminó peor de lo que empezó"}

# ---------------------------------------------------------------------------
#  2 · LA CABEZA
# ---------------------------------------------------------------------------

## La ficha mental de un jugador, creándola si es la primera vez que se pregunta
## por él. Nace con el sorteo del HTML: los chicos llegan más nerviosos, los
## frágiles arrastran el miedo a romperse otra vez y los líderes tienen más
## confianza de salida.
func mente(j: Jugador) -> Dictionary:
	if not _mente.has(j.id):
		var ansiedad := Azar.ent(4, 34)
		if j.edad < 20:
			ansiedad += 10
		if j.rasgo == "fragil":
			ansiedad += 8
		var confianza := Azar.ent(45, 80)
		if j.rasgo == "lider":
			confianza += 10
		_mente[j.id] = {
			"ansiedad": clampi(ansiedad, 0, 100),
			"confianza": clampi(confianza, 0, 100),
			"terapia": 0,
			"descanso": 0,
			"baja": 0,
		}
	return _mente[j.id]

func ansiedad(j: Jugador) -> int:
	return int(mente(j)["ansiedad"])

func confianza(j: Jugador) -> int:
	return int(mente(j)["confianza"])

## Cómo está de la cabeza, en una palabra y un color. Los cuatro escalones son
## los del HTML: el jugador tiene que poder leer de un vistazo a quién no puede
## sacar el domingo.
func estado_mental(j: Jugador) -> Dictionary:
	var a := ansiedad(j)
	if a >= 70:
		return {"txt": "Al límite", "color": "#e05555"}
	if a >= 48:
		return {"txt": "Tenso", "color": "#e0a832"}
	if a >= 26:
		return {"txt": "Normal", "color": "#8ea595"}
	return {"txt": "Enchufado", "color": "#4caf6d"}

## El pulso semanal de la cabeza del plantel.
func _proceso_mental() -> void:
	var c := _club()
	if c == null:
		return
	var m := _mundo()
	## Lo que calma al vestuario cada semana: bienestar y guardería, por el
	## doble si el DT es psicólogo, más medio punto si hay comedor propio.
	var psi := 0.0
	if m != null:
		if m.obras != null:
			psi = float(m.obras.calma_del_vestuario())
			if m.obras.nivel("cocina") > 0:
				psi += 0.5
		if m.entrenamiento != null:
			psi *= m.entrenamiento.factor_calma()
	for j in c.plantilla:
		var f := mente(j)
		if int(f["terapia"]) > 0:
			f["terapia"] = int(f["terapia"]) - 1
			f["ansiedad"] = clampi(int(f["ansiedad"]) - Azar.ent(4, 9), 0, 100)
		if int(f["descanso"]) > 0:
			f["descanso"] = int(f["descanso"]) - 1
			f["ansiedad"] = clampi(int(f["ansiedad"]) - Azar.ent(6, 12), 0, 100)
			j.fisico = clampi(j.fisico + 6, 10, 100)
		var d := -psi * 0.8
		if j.lesion > 0:
			d += float(Azar.ent(1, 4))
		if j.moral < 40:
			d += float(Azar.ent(1, 3))
		if j.moral > 75:
			d -= 1.0
		## El vaivén de una semana cualquiera. Sin él la ansiedad de un plantel
		## tranquilo se queda clavada en cero y deja de significar nada.
		d += 1.0 if Azar.suerte(0.3) else -1.0
		f["ansiedad"] = clampi(int(round(float(f["ansiedad"]) + d)), 0, 100)

		if int(f["ansiedad"]) >= ANSIEDAD_CRISIS and int(f["baja"]) <= 0 and Azar.suerte(0.10):
			f["baja"] = Azar.ent(1, 3)
			crisis_mental.emit(j, int(f["baja"]))
			noticia.emit("🧠 %s pide ayuda" % j.nombre,
				"El jugador reconoce que no está bien: ansiedad, insomnio y miedo a fallar. El club le da %d semana(s) de baja psicológica. Puedes acelerarlo con terapia desde su ficha." % int(f["baja"]))
		if int(f["baja"]) > 0:
			f["baja"] = int(f["baja"]) - 1
			## La baja psicológica se cobra por la MISMA puerta que una lesión,
			## porque es la única que el once y el simulador miran. Se escribe
			## `lesion` a mano y no con `j.lesionar()` a propósito: esa señal
			## dispara el parte médico y saldría un diagnóstico traumatológico
			## inventado para alguien que lo que tiene es la cabeza.
			j.lesion = maxi(j.lesion, 1 if int(f["baja"]) > 0 else 0)

## Terapia deportiva pagada por el club. Devuelve "" si se contrató, o el
## motivo por el que no. Cuesta una parte fija escalada al tamaño del club más
## dos semanas de su sueldo: al crack se le trae el especialista caro.
func dar_terapia(j: Jugador) -> String:
	var c := _club()
	if c == null:
		return "no diriges ningún club"
	var f := mente(j)
	if int(f["terapia"]) > 0:
		return "ya está en terapia"
	var costo := Eco.escalar(3000.0, float(c.rep)) + int(round(float(j.sueldo) * 2.0))
	if costo > c.saldo:
		return "no hay caja: cuesta %d y tienes %d" % [costo, c.saldo]
	c.mover_saldo(-costo)
	f["terapia"] = Azar.ent(3, 5)
	f["ansiedad"] = clampi(int(f["ansiedad"]) - Azar.ent(8, 16), 0, 100)
	gasto.emit("Terapia deportiva · " + j.nombre, costo)
	return ""

## Apartarlo de la convocatoria para que despeje. No cuesta dinero, cuesta
## tenerlo fuera: por eso es una decisión y no un botón gratis.
func descanso_mental(j: Jugador) -> String:
	var f := mente(j)
	if int(f["descanso"]) > 0:
		return "ya está descansando"
	f["descanso"] = Azar.ent(1, 2)
	f["ansiedad"] = clampi(int(f["ansiedad"]) - Azar.ent(10, 20), 0, 100)
	_mover_moral(j, 3)
	noticia.emit("Descanso mental para " + j.nombre,
		"Lo apartas de la convocatoria por unos días para que despeje la cabeza. Vuelve más entero.")
	return ""

# ---------------------------------------------------------------------------
#  3 · EL ROL EN EL PLANTEL
# ---------------------------------------------------------------------------

## La tabla del HTML: [clave, nombre, descripción, minutos que exige, factor de
## sueldo, delta de moral al firmarlo].
func tabla_roles() -> Array:
	var t: Variant = Datos.tabla("ROL_PLANTEL")
	return t if t is Array else []

## La ficha de un rol. Si la clave no existe cae en "rotación", que es el papel
## neutro: nadie se queda sin rol por una errata.
func def_rol(clave: String) -> Array:
	var t := tabla_roles()
	for fila: Array in t:
		if String(fila[0]) == clave:
			return fila
	if t.size() > 2:
		return t[2] as Array
	return []

func indice_rol(clave: String) -> int:
	var t := tabla_roles()
	for i in t.size():
		if String((t[i] as Array)[0]) == clave:
			return i
	return -1

func rol_plantel(j: Jugador) -> String:
	return String(_rol.get(j.id, "rotacion"))

## Lo que pide de sueldo según el papel prometido. El protagonismo se paga: un
## intocable cuesta un 30% más que el mismo jugador de rotación. Los contratos
## largos abaratan la semana y los cortos la encarecen.
func pide_con_rol(j: Jugador, rol: String, anios: int) -> int:
	var base := int(round(float(j.sueldo) * 1.15))
	var r := def_rol(rol)
	if r.is_empty():
		return base
	var f_anios := 0.94 if anios >= 4 else (1.0 if anios == 3 else (1.06 if anios == 2 else 1.14))
	return int(max(30.0, round(float(base) * float(r[4]) * f_anios / 10.0) * 10.0))

## ¿Acepta el jugador ese papel? Un crack no firma de suplente y un suplente no
## se cree lo de intocable.
##
## La comparación es DENTRO DE SU DEMARCACIÓN, no de su línea. Con la línea
## entera, el mejor lateral derecho del club salía "sexto de diez defensas" y no
## podía exigir ser titular, mientras el cuarto central se creía intocable
## contando a los laterales por detrás.
func acepta_rol(j: Jugador, rol: String) -> Dictionary:
	var c: Club = null
	var m := _mundo()
	if m != null:
		c = m.clubes.get(j.club_id)
	var dem := _demarcacion(j)
	var rivales: Array[Jugador] = []
	if c != null:
		for x in c.plantilla:
			if _demarcacion(x) == dem:
				rivales.append(x)
	rivales.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	var ranking := rivales.find(j)
	if ranking < 0:
		ranking = 0
	var idx := indice_rol(rol)
	if idx < 0:
		return {"ok": false, "txt": "Ese papel no existe."}
	## El mejor de su puesto no acepta menos que titular; el quinto no exige ser
	## intocable.
	var max_acepta := 3 if ranking <= 1 else (4 if ranking <= 2 else 5)
	var min_acepta := 0 if ranking <= 0 else (1 if ranking <= 2 else 2)
	if idx < min_acepta and j.ovr < 78:
		return {"ok": false, "txt": "Le estás prometiendo más de lo que es: sabe que no lo va a cumplir y no se fía."}
	if idx > max_acepta:
		return {"ok": false, "txt": "Se considera demasiado importante para ese papel. Ofrécele algo mejor o búscate a otro."}
	return {"ok": true, "txt": ""}

## Cambia el papel de un jugador fuera de la mesa de renovación. Prometer más es
## gratis; rebajarle el escalafón duele, y duele en la moral, que es lo que el
## motor lee cada minuto.
func cambiar_rol(j: Jugador, rol: String) -> Dictionary:
	var ac := acepta_rol(j, rol)
	if not ac["ok"]:
		_mover_moral(j, -2)
		return {"ok": false, "txt": "No acepta ese papel", "d_moral": -2}
	var antes := indice_rol(rol_plantel(j))
	var ahora := indice_rol(rol)
	fijar_rol(j, rol)
	var d := 0
	if ahora > antes:
		d = -(ahora - antes) * 5
		_mover_moral(j, d)
		return {"ok": true, "txt": "Se lo tomó mal: %d de moral" % d, "d_moral": d}
	elif ahora < antes:
		d = (antes - ahora) * 4
		_mover_moral(j, d)
		return {"ok": true, "txt": "Le has subido el escalafón", "d_moral": d}
	return {"ok": true, "txt": "", "d_moral": 0}

## Escribe el rol sin negociar ni mover moral. La usan la renovación y la carga
## de partida, que ya han hecho sus propias cuentas. La ventana de cumplimiento
## se pone a cero: la promesa nueva se juzga desde hoy, no con lo que pasó bajo
## la anterior.
func fijar_rol(j: Jugador, rol: String) -> void:
	_rol[j.id] = rol
	_rol_cuenta[j.id] = {"pj": 0, "min": 0}

## Cada semana se comprueba si le estás cumpliendo lo prometido.
##
## La cuenta es por SEMANAS, no por minutos: una semana suma a la ventana y, si
## además estaba en el once, suma a las cumplidas. Es exactamente lo que hace el
## HTML y evita tener que instrumentar el simulador para contar minutos.
func _chequeo_roles(once_ids: Array) -> void:
	var c := _club()
	if c == null:
		return
	for j in c.plantilla:
		if not _rol.has(j.id):
			continue
		var cta: Dictionary = _rol_cuenta.get(j.id, {"pj": 0, "min": 0})
		cta["pj"] = int(cta["pj"]) + 1
		if once_ids.has(j.id):
			cta["min"] = int(cta["min"]) + 1
		_rol_cuenta[j.id] = cta
		if int(cta["pj"]) < ROL_MINIMO_SEMANAS:
			continue
		var r := def_rol(rol_plantel(j))
		if r.is_empty():
			continue
		var exig := float(r[3])
		var ratio := float(cta["min"]) / float(cta["pj"])
		if ratio < exig - 0.16:
			_mover_moral(j, -Azar.ent(2, 5))
			rol_incumplido.emit(j, ratio)
			if Azar.suerte(0.18):
				noticia.emit("Malestar de " + j.nombre,
					"Le prometiste ser %s y lleva %d%% de titularidades. Su agente ya llamó dos veces." % [String(r[1]).to_lower(), int(round(ratio * 100.0))])
			_rol_cuenta[j.id] = {"pj": 0, "min": 0}
		elif ratio > exig + 0.2 and rol_plantel(j) != "intocable":
			## Le estás dando MÁS de lo prometido: eso también se nota, aunque
			## poco. Al intocable no, porque ya tiene todo lo que se puede tener.
			_mover_moral(j, 2)
			_rol_cuenta[j.id] = {"pj": 0, "min": 0}
		elif int(cta["pj"]) >= ROL_VENTANA_MAX:
			_rol_cuenta[j.id] = {"pj": 0, "min": 0}

# ---------------------------------------------------------------------------
#  3B · LAS SOLICITUDES DEL PLANTEL
# ---------------------------------------------------------------------------
## `SOLICITUDES` del HTML: un jugador viene a hablar contigo con una petición
## concreta -"podrán hacer exigencias y solicitudes"-, y hay que decirle que sí
## o que no, cada una con su propia consecuencia. Vivía en el HTML como una
## función suelta (`solicitudDeJugador()`/`resolverSolicitud()`) sin clase que
## la contuviera; aquí entra en `Vestuario` porque es exactamente la misma
## materia prima que el resto del fichero -moral, rol, ánimo del plantel-.
##
## Clave, título, texto si aceptas, texto si rechazas.
const SOLICITUDES := [
	["minutos", "Pide más minutos", "Le prometes subirle el rol un escalón.", "Se lo niegas y lo asume como puede."],
	["sueldo", "Pide mejora de sueldo", "Le subes un 12% la ficha.", "Le dices que no hay presupuesto."],
	["salida", "Pide salir del club", "Lo pones en la lista de transferibles.", "Le dices que cuentas con él."],
	["compa", "Pide que fiches a un compatriota", "Le prometes buscar a alguien de su país.", "Le dices que el mercado no da para eso."],
	["descanso", "Pide días libres", "Le das dos días de descanso.", "Le recuerdas que se entrena igual."],
	["instal", "Se queja de las instalaciones", "Le prometes que hay obras en camino.", "Le dices que se aguante."],
	["capitan", "Quiere ser capitán", "Le das la cinta.", "Mantienes al capitán actual."],
]

## Solo una activa a la vez -igual que `G.solicitud`-: {"pid", "k"}, o vacío.
var solicitud: Dictionary = {}

func def_solicitud(clave: String) -> Array:
	for fila: Array in SOLICITUDES:
		if String(fila[0]) == clave:
			return fila
	return []

## El jugador con la solicitud activa, o null si no hay ninguna o ya no está
## en el plantel -se fue, lo vendiste-, que es cuando se descarta sola.
func jugador_de_solicitud() -> Jugador:
	if solicitud.is_empty():
		return null
	var c := _club()
	if c == null:
		return null
	for j in c.plantilla:
		if j.id == String(solicitud.get("pid", "")):
			return j
	solicitud = {}
	return null

## Sortea una petición nueva, si toca. La lista de candidatos depende de la
## situación real de cada uno -no es un sorteo puro-, igual que en el HTML:
## solo entra en juego quien de verdad tiene motivo para pedir algo. Devuelve
## el titular para la noticia, o "" si esta semana no pasó nada.
func sortear_solicitud(obras: Instalaciones = null) -> String:
	if not solicitud.is_empty():
		return "" ## solo una a la vez
	var c := _club()
	if c == null:
		return ""
	var disponibles: Array[Jugador] = []
	for j in c.plantilla:
		if j.lesion <= 0:
			disponibles.append(j)
	if disponibles.size() < 12:
		return ""
	var j: Jugador = Azar.uno(disponibles)
	var candidatos: Array[String] = []
	var cta: Dictionary = _rol_cuenta.get(j.id, {"pj": 0, "min": 0})
	var pj := int(cta.get("pj", 0))
	var r := def_rol(rol_plantel(j))
	if pj >= 5 and not r.is_empty() and (float(cta.get("min", 0)) / float(pj)) < float(r[3]) - 0.15:
		candidatos.append("minutos")
	if j.ovr >= c.rep - 2 and float(j.sueldo) < float(j.valor) * 0.0009:
		candidatos.append("sueldo")
	if j.moral < 38:
		candidatos.append("salida")
	## "compa": no hay ningún compañero de su mismo país -CHI en el HTML, aquí
	## el país del CLUB: la idea es "es extranjero aquí", no "no es chileno".
	if j.pais != c.pais:
		var solo := true
		for x in c.plantilla:
			if x.id != j.id and x.pais == j.pais:
				solo = false
				break
		if solo:
			candidatos.append("compa")
	if j.fisico < 58:
		candidatos.append("descanso")
	if obras != null and obras.nivel("ct") + obras.nivel("med") < 3:
		candidatos.append("instal")
	if j.edad >= 28 and j.ovr >= c.rep - 4 and not j.capitan:
		candidatos.append("capitan")
	if candidatos.is_empty():
		return ""
	var k := String(Azar.uno(candidatos))
	solicitud = {"pid": j.id, "k": k}
	var d := def_solicitud(k)
	var titular := "%s %s." % [j.nombre, String(d[1]).to_lower()]
	## Mismo patrón que `Prensa.sortear_evento()`: la señal específica -aquí
	## solo el estado, `solicitud`- viaja siempre junto a un `noticia` genérico,
	## que es al que ya está enganchada la interfaz. Sin esto, el asunto
	## aparecía en el despacho pero no avisaba de que había llegado uno nuevo.
	noticia.emit("Un jugador quiere hablar contigo", "%s Te espera en el despacho." % titular)
	return titular

## Sí o no a la solicitud activa. Devuelve el titular y el cuerpo para la
## noticia, o vacío si no había ninguna pendiente.
func resolver_solicitud(si: bool) -> Dictionary:
	var j := jugador_de_solicitud()
	if j == null:
		return {}
	var k := String(solicitud.get("k", ""))
	var d := def_solicitud(k)
	solicitud = {}
	if d.is_empty():
		return {}
	if si:
		match k:
			"minutos":
				var t := tabla_roles()
				var idx := maxi(0, indice_rol(rol_plantel(j)) - 1)
				if idx < t.size():
					fijar_rol(j, String((t[idx] as Array)[0]))
				_mover_moral(j, 9)
			"sueldo":
				j.sueldo = int(round(float(j.sueldo) * 1.12))
				_mover_moral(j, 8)
			"salida":
				j.transferible = true
				_mover_moral(j, 4)
			"compa":
				## `Cantera.prometer_compatriota()` -motor listo, sin nadie que lo
				## llamara- vive en otra clase: `Vestuario` no conoce `Cantera`,
				## así que solo se mueve la moral aquí y el llamado cruzado lo
				## hace quien orquesta la semana (`Mundo.avanzar_semana()`).
				_mover_moral(j, 7)
			"descanso":
				j.fisico = clampi(j.fisico + 16, 10, 100)
				_mover_moral(j, 6)
			"instal":
				_mover_moral(j, 4)
			"capitan":
				var c := _club()
				if c != null:
					for x in c.plantilla:
						x.capitan = false
				j.capitan = true
				_mover_moral(j, 12)
		return {"jugador": j, "clave": k, "titulo": "Acuerdo con %s" % j.nombre, "cuerpo": String(d[2])}
	## El rechazo golpea distinto según lo que le negaste. "salida" en el HTML
	## suma DOS golpes seguidos -4 y luego otros 6-, que en la práctica son 10:
	## se deja aquí como un solo número correcto en vez de portar el doble golpe
	## letra por letra, porque el aviso original decía "perdiste 4" cuando en
	## los hechos perdía 10 -un desfase entre el texto y el efecto real, no una
	## regla a propósito-.
	var golpe := 10 if k == "salida" else (6 if k == "capitan" else (9 if k == "sueldo" else 7))
	_mover_moral(j, -golpe)
	return {"jugador": j, "clave": k, "titulo": "Le dijiste que no a %s" % j.nombre,
		"cuerpo": "%s Perdió %d de moral." % [String(d[3]), golpe]}

## Los cuatro frentes por los que un jugador está o no a gusto: los minutos que
## le prometiste, cómo se ve él en sus últimos partidos, si lo pones en su
## puesto y en qué instalaciones entrena.
##
## De aquí sale la deriva semanal de la moral, que es la vía por la que todo
## este fichero llega al marcador.
func satisfaccion(j: Jugador) -> Dictionary:
	return _satisfaccion(j, _slots_del_once())

## Igual, pero con las ranuras ya calculadas. Armar el once cuesta un sorteo por
## ranura sobre la plantilla entera, y la deriva semanal pregunta por los
## veinticuatro jugadores: sin esto se rearmaba el equipo veinticuatro veces
## para pintar el mismo dibujo.
func _satisfaccion(j: Jugador, slots: Dictionary) -> Dictionary:
	var r := def_rol(rol_plantel(j))
	var exig := float(r[3]) if not r.is_empty() else 0.38

	## 1 · minutos frente a lo prometido
	var cta: Dictionary = _rol_cuenta.get(j.id, {"pj": 0, "min": 0})
	var cumple := 0.5
	if int(cta["pj"]) > 0:
		cumple = clampf(float(cta["min"]) / float(cta["pj"]), 0.0, 1.0)
	elif j.partidos > 0:
		cumple = 0.6
	var v_min := clampf(50.0 + (cumple - exig) * 140.0, 0.0, 100.0)

	## 2 · su propio rendimiento, con las cinco últimas notas
	var nn := j.notas.slice(maxi(0, j.notas.size() - 5))
	var nota := 6.2
	if not nn.is_empty():
		var s := 0.0
		for x in nn:
			s += float(x)
		nota = s / float(nn.size())
	var v_rend := clampf((nota - 4.5) * 100.0 / 4.0, 0.0, 100.0)

	## 3 · comodidad táctica: si juega fuera de puesto, sufre
	var apt := _aptitud(j, String(slots.get(j.id, j.pos_e)))
	var v_tact := clampf(40.0 + (apt - 0.8) * 260.0, 0.0, 100.0)

	## 4 · instalaciones del club
	var inst := 0
	var m := _mundo()
	if m != null and m.obras != null:
		inst = m.obras.nivel("ct") + m.obras.nivel("med") + m.obras.nivel("gim") + m.obras.nivel("cocina")
	var v_inst := clampf(float(inst) * 100.0 / 14.0 + 22.0, 0.0, 100.0)

	var total := int(round(v_min * 0.34 + v_rend * 0.28 + v_tact * 0.20 + v_inst * 0.18))
	return {
		"min": int(round(v_min)),
		"rend": int(round(v_rend)),
		"tact": int(round(v_tact)),
		"inst": int(round(v_inst)),
		"total": total,
	}

## La moral deriva hacia el nivel de satisfacción, un 6% por semana. Es lenta a
## propósito: un plantel descontento se desinfla en un mes, no en un domingo.
func _proceso_satisfaccion() -> void:
	var c := _club()
	if c == null:
		return
	var slots := _slots_del_once()
	for j in c.plantilla:
		var s: int = _satisfaccion(j, slots)["total"]
		j.moral = clampi(int(round(float(j.moral) + (float(s) - float(j.moral)) * 0.06)), 10, 99)

# ---------------------------------------------------------------------------
#  4 · LO QUE LLEGA AL MARCADOR
# ---------------------------------------------------------------------------

## Los roles tácticos del HTML: [nombre, grupo, Δataque, Δdefensa, atributos que
## lo hacen bueno].
func tabla_roles_tacticos() -> Dictionary:
	var t: Variant = Datos.tabla("ROLES")
	return t if t is Dictionary else {}

## Los roles que puede desempeñar una línea concreta (POR/DEF/MED/DEL).
func roles_de_grupo(grupo: String) -> Array:
	var salida: Array = []
	var t := tabla_roles_tacticos()
	for k: String in t:
		if String((t[k] as Array)[1]) == grupo:
			salida.append(k)
	return salida

## El rol que se le supone a una demarcación si nadie le ha dicho otra cosa.
func rol_tactico_por_defecto(demarcacion: String) -> String:
	match Datos.grupo(demarcacion):
		"POR": return "porArea"
		"DEF": return "centralMar" if demarcacion == "DFC" else "latDef"
		"MED":
			if demarcacion == "MCD":
				return "pivote"
			return "organizad" if demarcacion == "MCO" else "boxToBox"
		_: return "nueveFijo" if demarcacion == "DC" else "extAbierto"

func rol_tactico(j: Jugador) -> String:
	return String(_rol_tactico.get(j.id, rol_tactico_por_defecto(j.pos_e)))

func fijar_rol_tactico(j: Jugador, rol_id: String) -> void:
	if tabla_roles_tacticos().has(rol_id):
		_rol_tactico[j.id] = rol_id

## Cuánto encaja el jugador en el rol que le pediste. Se mira SOLO los atributos
## que ese rol usa contra su propia media: un central de 80 con 90 de marca es
## un gran central marcador, y el mismo central es un mal central de salida.
func aptitud_rol(j: Jugador, rol_id: String) -> float:
	var t := tabla_roles_tacticos()
	if not t.has(rol_id) or j.atributos.is_empty():
		return 1.0
	var claves: Array = (t[rol_id] as Array)[4]
	var s := 0.0
	var n := 0
	for k: String in claves:
		if j.atributos.has(k):
			s += float(j.atributos[k])
			n += 1
	if n == 0:
		return 1.0
	return clampf(0.88 + (s / float(n) - float(j.ovr)) * 0.012, 0.82, 1.14)

## Efecto agregado de los roles individuales sobre el equipo. Se divide entre
## once porque el reparto es por jugador: un once entero de llegadores suma
## mucho ataque y regala la espalda.
func bonus_roles(once: Array) -> Dictionary:
	var t := tabla_roles_tacticos()
	var a := 0.0
	var d := 0.0
	for j: Jugador in once:
		var r := rol_tactico(j)
		if not t.has(r):
			continue
		var fila: Array = t[r]
		var apt := aptitud_rol(j, r)
		a += float(fila[2]) * apt
		d += float(fila[3]) * apt
	return {"att": 1.0 + a / 11.0, "def": 1.0 + d / 11.0}

## Química de hermanos: solo cuenta si comparten el once. Un 1,8% por pareja,
## que es poco y es de los dos lados —ataque y defensa—, exactamente como en el
## HTML: es un guiño, no una estrategia.
func bonus_hermanos(once: Array) -> float:
	var ids := {}
	for j: Jugador in once:
		ids[j.id] = true
	var n := 0
	for j: Jugador in once:
		var h := String(_hermano.get(j.id, ""))
		if h != "" and ids.has(h):
			n += 1
	return 1.0 + (float(n) / 2.0) * 0.018

## Lo que el nerviosismo del vestuario le quita al equipo.
##
## En el HTML esto vivía dentro de `fuerzaJug()`, jugador a jugador
## (`1 - ansiedad*0.0018`). Aquí no se puede: `Partido._media_linea()` no es mío
## y `Jugador` no guarda la ansiedad. Se aplica agregado sobre el once, que da
## prácticamente el mismo número porque la fuerza de línea ya es una media.
##
## Y se mide CONTRA `ANSIEDAD_NEUTRA`, no contra cero: los otros 383 clubes no
## simulan su camarín, así que su ansiedad se queda en la de fábrica. Midiendo
## desde cero, tu equipo sería el único penalizado del mundo por existir. Con el
## cero puesto en la media del mundo, un vestuario normal vale 1,0 y solo se
## mueve el que está mejor o peor que el resto.
func factor_animo(once: Array) -> float:
	if once.is_empty():
		return 1.0
	var s := 0.0
	for j: Jugador in once:
		s += 1.0 - (float(ansiedad(j)) - ANSIEDAD_NEUTRA) * PESO_ANSIEDAD
	return clampf(s / float(once.size()), 0.85, 1.05)

## Los dos multiplicadores que aporta el vestuario, calculados de una vez porque
## comparten el mismo once y el mismo recorrido.
##
## Quien los combina con el resto es `Mundo.aplicar_bonificadores()`, que es el
## único sitio del proyecto que escribe en `Club.bonus_ataque` /
## `Club.bonus_defensa`. Aquí no se escribe en el club a propósito: dos sistemas
## escribiendo el mismo campo se pisan, y cargar la partida dejaba el equipo con
## el doble de bonificación.
func factores(c: Club = null) -> Dictionary:
	var club := c if c != null else _club()
	if club == null:
		return {"ata": 1.0, "def": 1.0}
	var once: Array = club.once()
	if once.is_empty():
		return {"ata": 1.0, "def": 1.0}
	var hermanos := bonus_hermanos(once)
	var roles := bonus_roles(once)
	var animo := factor_animo(once)
	return {
		"ata": hermanos * float(roles["att"]) * animo,
		"def": hermanos * float(roles["def"]) * animo,
	}

func factor_ataque(c: Club = null) -> float:
	return float(factores(c)["ata"])

func factor_defensa(c: Club = null) -> float:
	return float(factores(c)["def"])

# ---------------------------------------------------------------------------
#  5 · HERMANOS Y GEMELOS
# ---------------------------------------------------------------------------

func hermano_de(j: Jugador) -> String:
	return String(_hermano.get(j.id, ""))

## Los declara hermanos. Está expuesto para que la cantera o un evento puedan
## emparentar a dos que ya existen sin tener que crear a nadie.
func emparentar(a: Jugador, b: Jugador) -> void:
	_hermano[a.id] = b.id
	_hermano[b.id] = a.id

## Un hermano más en el plantel, al empezar la temporada y solo tres de cada
## diez años. Un 22% de las veces es gemelo: misma edad, media casi idéntica y
## los mismos atributos con tres puntos de margen.
##
## El apellido se copia del hermano, que es lo que hace que la broma se entienda
## sin explicarla en ningún texto.
func generar_hermanos() -> Jugador:
	if not Azar.suerte(0.30):
		return null
	var c := _club()
	var m := _mundo()
	if c == null or m == null:
		return null
	var candidatos: Array[Jugador] = []
	for j in c.plantilla:
		if j.edad <= 23 and not _hermano.has(j.id):
			candidatos.append(j)
	if candidatos.is_empty():
		return null
	var base: Jugador = candidatos[Azar.ent(0, candidatos.size() - 1)]
	var gemelo := Azar.suerte(0.22)
	var edad := base.edad if gemelo else clampi(base.edad + Azar.ent(-3, 3), 16, 24)
	var ovr := base.ovr + Azar.ent(-2, 2) if gemelo else base.ovr + Azar.ent(-8, 6)
	var nuevo := m.crear_jugador(c, base.pos, base.pos_e, edad, ovr)
	nuevo.pais = base.pais
	var apellido := base.nombre.split(" ")[base.nombre.split(" ").size() - 1]
	var pila: Array = Datos.tabla("NOMBRES")
	var nombre_pila := String(Azar.uno(pila)) if pila != null and not pila.is_empty() else "Hermano"
	nuevo.nombre = "%s %s" % [Nombres.limpiar(nombre_pila), apellido]
	if gemelo:
		## El gemelo no es un jugador nuevo: es una copia con ruido. Se le
		## reparten los atributos del hermano con tres puntos de margen y hay
		## que volver a tasarlo, o el valor seguiría siendo el del sorteo.
		for k: String in nuevo.atributos:
			if base.atributos.has(k):
				nuevo.atributos[k] = clampi(int(base.atributos[k]) + Azar.ent(-3, 3), 22, 99)
		nuevo.tasar()
	c.plantilla.append(nuevo)
	emparentar(nuevo, base)
	hermanos_nuevos.emit(nuevo, base, gemelo)
	if gemelo:
		noticia.emit("👯 Llegan los gemelos " + apellido,
			"El club incorpora a %s, hermano gemelo de %s. Se parecen tanto que el utilero ya se equivocó dos veces. Juntos en cancha se entienden sin mirarse." % [nuevo.nombre, base.nombre])
	else:
		noticia.emit("👨‍👦 Un hermano más en el plantel",
			"%s (%d años, %s) sube al primer equipo. Es hermano de %s: jugar juntos les da un plus." % [nuevo.nombre, nuevo.edad, nuevo.pos_e, base.nombre])
	return nuevo

# ---------------------------------------------------------------------------
#  EL PULSO
# ---------------------------------------------------------------------------

## Una semana de vestuario, en el orden del HTML: primero la cabeza, después los
## grupos, después las promesas y al final la deriva de moral, que es la que
## recoge todo lo anterior.
##
## Los grupos se redibujan cada seis semanas y no cada una: un plantel no cambia
## de camarillas todos los lunes, y rehacerlas cada semana borraba la cuenta de
## paciencia antes de que llegara a tres.
func semana(sem: int) -> void:
	var c := _club()
	if c == null:
		return
	var once_ids: Array = []
	for j: Jugador in c.once():
		once_ids.append(j.id)
	_proceso_mental()
	chequeo_clanes(once_ids)
	_chequeo_roles(once_ids)
	_proceso_satisfaccion()
	if sem % CADA_CUANTAS_SEMANAS == 0:
		armar()

## Lo que le toca al vestuario al empezar la temporada.
func nueva_temporada() -> void:
	generar_hermanos()
	armar()

## Lo que la interfaz necesita para el panel de "te falta revisar", sin tener
## que recorrer el plantel por su cuenta.
func resumen() -> Dictionary:
	var c := _club()
	var ansiosos := 0
	var en_baja := 0
	if c != null:
		for j in c.plantilla:
			if ansiedad(j) >= 60:
				ansiosos += 1
			if int(mente(j)["baja"]) > 0:
				en_baja += 1
	var molestos := 0
	for cl in camarillas:
		if int(cl["humor"]) < -25:
			molestos += 1
	return {
		"grupos": camarillas.size(),
		"molestos": molestos,
		"ansiosos": ansiosos,
		"en_baja": en_baja,
		"factor_ataque": factor_ataque(),
		"factor_defensa": factor_defensa(),
	}

# ---------------------------------------------------------------------------
#  AYUDAS
# ---------------------------------------------------------------------------

func _jugador(id: String) -> Jugador:
	var c := _club()
	if c == null or id == "":
		return null
	for j in c.plantilla:
		if j.id == id:
			return j
	return null

# ---------------------------------------------------------------------------
#  LA CHARLA DEL ENTRETIEMPO
# ---------------------------------------------------------------------------
#
# `charla()` del HTML. Vive aquí y no en la pantalla del partido porque toca lo
# mismo que todo este archivo -moral y ansiedad, jugador a jugador- y porque así
# el banco puede comprobar que sacudir al equipo cuando va ganando es mala idea.
#
# La gracia del sistema es que **no hay un tono bueno**. Cada tono tiene un
# margen de efecto (`ef`), y los de más recorrido son también los que más pueden
# hundirte: "Sacudir" va de -9 a +14. Y el rasgo del jugador decide si le sienta
# bien: a un líder o a una muralla les va la exigencia, a un frágil o a un
# cerebro el elogio. Gritarle al frágil le sube la ansiedad y le baja la moral.

## clave -> [nombre, icono, efecto mínimo, efecto máximo, delta de ansiedad,
##           qué clase de jugador lo agradece]
const TONOS := {
	"calma":   ["Calmar", "🧘", 0, 5, -8, "elogio"],
	"animar":  ["Elogiar", "👏", 2, 7, -5, "elogio"],
	"exigir":  ["Exigir", "☝️", -3, 9, 2, "exigencia"],
	"furia":   ["Sacudir", "🔥", -9, 14, 9, "exigencia"],
	"tactico": ["Pizarra", "📋", 1, 5, -3, ""],
	"senalar": ["Señalar a uno", "🎯", -6, 10, 6, "exigencia"],
}

## Qué prefiere oír cada perfil. Los que no están en la tabla se lo toman igual
## venga como venga: no todo el mundo tiene carácter marcado.
const PREFIERE := {
	"lider": "exigencia", "muralla": "exigencia",
	"fragil": "elogio", "cerebro": "elogio",
}

## Da la charla al once. Devuelve qué pasó, para que la pantalla lo cuente.
##
## El psicólogo del cuerpo técnico -`Staff.nivel("psi")`- suma a los dos
## extremos del margen: con un buen psicólogo hasta una bronca sale mejor,
## que es exactamente para lo que se le paga.
func charla(once: Array, tono: String) -> Dictionary:
	if not TONOS.has(tono):
		tono = "calma"
	var t: Array = TONOS[tono]
	var psi := 0
	var m := _mundo()
	if m != null and m.staff != null:
		psi = m.staff.nivel("psi")
	var suben := 0
	var bajan := 0
	for j: Jugador in once:
		var prefiere := String(PREFIERE.get(j.rasgo, ""))
		var gusta := String(t[5])
		var d := Azar.ent(int(t[2]) + psi, int(t[3]) + psi)
		if gusta != "" and prefiere != "":
			d += Azar.ent(2, 5) if prefiere == gusta else -Azar.ent(2, 6)
		var extra := 4 if (prefiere != "" and gusta != "" and prefiere != gusta) else 0
		_mover_ansiedad(j, int(t[4]) + extra)
		## Un jugador desbordado no escucha: por encima de 72 de ansiedad, la
		## charla le llega peor haga lo que haga el entrenador.
		if ansiedad(j) > 72:
			d -= Azar.ent(2, 6)
		_mover_moral(j, d)
		if d > 2:
			suben += 1
		elif d < 0:
			bajan += 1
	var reaccion := "el mensaje llega a medias"
	if suben > bajan + 3:
		reaccion = "el camarín reacciona, salen enchufados"
	elif bajan > suben:
		reaccion = "a varios no les cayó bien; hay caras largas"
	return {
		"tono": tono, "nombre": String(t[0]), "icono": String(t[1]),
		"suben": suben, "bajan": bajan, "reaccion": reaccion,
	}

## `charlaLibre()`: el tono se DEDUCE de lo que escribes. Es de las cosas más
## baratas del HTML y de las que más hacen por meterte en el papel — decir
## "así no, señores" y ver que el equipo lo acusa vale más que elegir "Exigir"
## en una lista. El orden de las comprobaciones importa: un grito con palabrota
## es furia aunque además diga "tranquilos".
func tono_de_texto(texto: String) -> String:
	var t := texto.to_lower()
	if _tiene(t, ["!!", "carajo", "mierda", "puta", "ya basta", "dejen de"]):
		return "furia"
	if _tiene(t, ["vergüenza", "verguenza", "inaceptable", "basta", "despierten",
			"jugando mal", "así no", "asi no", "ridícul", "ridicul", "desastre", "regalan"]):
		return "exigir"
	if _tiene(t, ["tranquil", "calma", "confi", "confío", "confio", "bien",
			"sigan", "paciencia", "así se juega", "asi se juega", "orgullo"]):
		return "animar"
	if _tiene(t, ["línea", "linea", "presi", "banda", "pelota", "espacio",
			"marca", "orden", "salida", "bloque", "contra"]):
		return "tactico"
	return "calma"

func _tiene(texto: String, claves: Array) -> bool:
	for k: String in claves:
		if texto.contains(k):
			return true
	return false

func _mover_moral(j: Jugador, d: int) -> void:
	j.moral = clampi(j.moral + d, 10, 99)

func _mover_ansiedad(j: Jugador, d: int) -> void:
	var f := mente(j)
	f["ansiedad"] = clampi(int(f["ansiedad"]) + d, 0, 100)

## La demarcación agrupada de POSD ("LAT", "DFC", "MED"...), que es con la que
## se compara el escalafón dentro del puesto.
func _demarcacion(j: Jugador) -> String:
	var posd := Datos.posd()
	if posd.has(j.pos_e):
		return String((posd[j.pos_e] as Dictionary).get("d", "MED"))
	return "MED"

## Qué ranura de la formación ocupa cada uno de los once de hoy.
##
## `Club.once()` devuelve a los jugadores EN EL ORDEN de las ranuras de FORMS,
## así que la posición en el array es la posición en la pizarra. Es la única
## forma de saber quién está jugando fuera de puesto sin tocar `Jugador`.
func _slots_del_once() -> Dictionary:
	var c := _club()
	if c == null:
		return {}
	var forms: Dictionary = Datos.tabla("FORMS")
	if forms == null:
		return {}
	var d: Dictionary = forms.get(c.tactica.formacion, forms.get("4-3-3", {}))
	var ranuras: Array = d.get("s", [])
	var once: Array = c.once()
	var salida := {}
	for i in mini(once.size(), ranuras.size()):
		salida[(once[i] as Jugador).id] = String((ranuras[i] as Array)[0])
	return salida

## Cuánto rinde en la demarcación donde lo pones, de 0 a 1. En su puesto vale 1;
## un portero de campo (o al revés) se queda en 0,60, y el resto sale de comparar
## su media ponderada en ese puesto con su media real.
func _aptitud(j: Jugador, demarcacion: String) -> float:
	if demarcacion == "" or demarcacion == j.pos_e:
		return 1.0
	if (Datos.grupo(demarcacion) == "POR") != j.es_portero():
		return 0.60
	return clampf(float(j.media_en(demarcacion)) / float(maxi(1, j.ovr)), 0.70, 1.0)

# ---------------------------------------------------------------------------
#  GUARDAR
# ---------------------------------------------------------------------------

## Solo se guarda lo que dice algo. La ficha mental de un jugador tranquilo, sin
## terapia y sin baja es la que le tocaría igual al recrearla, y escribir miles
## de diccionarios idénticos engorda la partida sin aportar nada: el guardado ya
## costó una depuración entera por tamaño.
##
## La ansiedad SÍ se guarda siempre que exista ficha, porque se sortea al nacer y
## no se puede reconstruir: perderla haría que cargar la partida barajara de
## nuevo la cabeza de todo el plantel.
func a_dic() -> Dictionary:
	return {
		"camarillas": camarillas.duplicate(true),
		"clan_de": _clan_de.duplicate(),
		"mente": _mente.duplicate(true),
		"rol": _rol.duplicate(),
		"rol_cuenta": _rol_cuenta.duplicate(true),
		"rol_tactico": _rol_tactico.duplicate(),
		"hermano": _hermano.duplicate(),
		"solicitud": solicitud.duplicate(),
	}

func desde_dic(d: Dictionary) -> void:
	camarillas.clear()
	for x: Dictionary in d.get("camarillas", []):
		camarillas.append({
			"id": String(x.get("id", "")),
			"tipo": String(x.get("tipo", "")),
			"nombre": String(x.get("nombre", "")),
			"miembros": x.get("miembros", []),
			"lider": String(x.get("lider", "")),
			"humor": int(x.get("humor", 0)),
			"fuera": int(x.get("fuera", 0)),
		})
	_clan_de = (d.get("clan_de", {}) as Dictionary).duplicate()
	_mente.clear()
	var fichas: Dictionary = d.get("mente", {})
	for id: String in fichas:
		var f: Dictionary = fichas[id]
		_mente[id] = {
			"ansiedad": int(f.get("ansiedad", 20)),
			"confianza": int(f.get("confianza", 60)),
			"terapia": int(f.get("terapia", 0)),
			"descanso": int(f.get("descanso", 0)),
			"baja": int(f.get("baja", 0)),
		}
	_rol = (d.get("rol", {}) as Dictionary).duplicate()
	_rol_cuenta.clear()
	var cuentas: Dictionary = d.get("rol_cuenta", {})
	for id: String in cuentas:
		var x: Dictionary = cuentas[id]
		_rol_cuenta[id] = {"pj": int(x.get("pj", 0)), "min": int(x.get("min", 0))}
	_rol_tactico = (d.get("rol_tactico", {}) as Dictionary).duplicate()
	_hermano = (d.get("hermano", {}) as Dictionary).duplicate()
	solicitud = (d.get("solicitud", {}) as Dictionary).duplicate()

# ---------------------------------------------------------------------------
#  EL SUCESO DE LA SEMANA (`eventoSemanal()` del HTML)
# ---------------------------------------------------------------------------
#
# Una cosa pequeña por semana en el camarín. Ninguna decide un partido y juntas
# son lo que hace que un plantel se sienta un grupo de personas: el polémico se
# va de fiesta, el líder reúne a todos, el killer se queda practicando, alguien
# cumple años y la joya golpea la puerta.
#
# CADA SUCESO NACE DE UN RASGO REAL de alguien de tu plantilla. Si nadie tiene el
# rasgo, ese suceso no puede pasar, y por eso fichar a un polémico se nota en el
# vestuario aunque no juegue: es lo que separa un rasgo de una etiqueta.
#
# AQUÍ SE COBRA LA NORMA «MULTAS», que estaba en el menú desde el porte y no la
# leía nadie: se podía encender el reglamento interno y no se aplicaba una sola
# multa en toda una carrera. Y aquí se cobra el nodo «Duro» del árbol del
# entrenador (`multas_dobles()`), que estaba escrito y tampoco se llamaba.

const MULTA_BASE := 300000.0

func suceso_semanal() -> Dictionary:
	var m := _mundo()
	if m == null:
		return {}
	var mio := m.mi_club()
	if mio == null or mio.plantilla.is_empty():
		return {}
	## Se sortea entre los sucesos POSIBLES, no entre todos: si el catálogo fuera
	## fijo, saldría "arenga del líder" en un plantel sin ningún líder.
	var posibles: Array[String] = ["cumple"]
	if not _con_rasgo(mio, "polemico").is_empty():
		posibles.append("lio")
	if not _con_rasgo(mio, "lider").is_empty():
		posibles.append("arenga")
	if not _con_rasgo(mio, "killer").is_empty():
		posibles.append("racha")
	if not _jovenes(mio).is_empty():
		posibles.append("joya")
	var cual := String(Azar.uno(posibles))
	match cual:
		"lio": return _suceso_lio(m, mio)
		"arenga": return _suceso_arenga(mio)
		"racha": return _suceso_racha(mio)
		"joya": return _suceso_joya(mio)
		_: return _suceso_cumple(mio)

func _con_rasgo(c: Club, rasgo: String) -> Array[Jugador]:
	var salida: Array[Jugador] = []
	for j: Jugador in c.plantilla:
		if j.rasgo == rasgo:
			salida.append(j)
	return salida

func _jovenes(c: Club) -> Array[Jugador]:
	var salida: Array[Jugador] = []
	for j: Jugador in c.plantilla:
		if j.edad <= 20:
			salida.append(j)
	return salida

## EL LÍO NOCTURNO. El único suceso que le cuesta algo al club, y el único donde
## las normas internas hacen algo: con el reglamento encendido entra la multa y
## al multado le baja más la moral. El nodo «Duro» del árbol la dobla.
func _suceso_lio(m: Mundo, mio: Club) -> Dictionary:
	var lista := _con_rasgo(mio, "polemico")
	var j: Jugador = lista[Azar.ent(0, lista.size() - 1)]
	for x: Jugador in mio.plantilla:
		x.moral = clampi(x.moral - 2, 10, 99)
	var extra := ""
	var multa := 0
	if bool(m.normas.get("multas", false)):
		multa = Eco.escalar(MULTA_BASE, float(mio.rep))
		if m.entrenamiento != null and m.entrenamiento.multas_dobles():
			multa *= 2
			extra = " Con tu mano dura, la multa fue el doble de lo habitual: %s." % Cesiones.dinero(multa)
		else:
			extra = " El club aplicó la multa del reglamento interno: %s." % Cesiones.dinero(multa)
		mio.mover_saldo(multa)
		j.moral = clampi(j.moral - 3, 10, 99)
	noticia.emit("Lío nocturno: %s" % j.nombre,
		"Fotos del jugador de fiesta a mitad de semana. El camarín queda tocado y la prensa afila el lápiz.%s" % extra)
	if m.prensa != null:
		m.prensa._mover_funa(Azar.ent(3, 8))
	return {"tipo": "lio", "jugador": j, "multa": multa}

func _suceso_arenga(mio: Club) -> Dictionary:
	var lista := _con_rasgo(mio, "lider")
	var j: Jugador = lista[Azar.ent(0, lista.size() - 1)]
	for x: Jugador in mio.plantilla:
		x.moral = clampi(x.moral + 3, 10, 99)
	noticia.emit("Arenga de %s" % j.nombre,
		"Reunió al plantel a puertas cerradas: «aquí nadie se esconde». El grupo sale enchufado.")
	return {"tipo": "arenga", "jugador": j}

func _suceso_racha(mio: Club) -> Dictionary:
	var lista := _con_rasgo(mio, "killer")
	var j: Jugador = lista[Azar.ent(0, lista.size() - 1)]
	j.forma = clampi(j.forma + 8, 20, 99)
	noticia.emit("Racha de %s" % j.nombre,
		"Se queda después de cada práctica definiendo. Huele gol.")
	return {"tipo": "racha", "jugador": j}

func _suceso_joya(mio: Club) -> Dictionary:
	var lista := _jovenes(mio)
	var j: Jugador = lista[Azar.ent(0, lista.size() - 1)]
	j.forma = clampi(j.forma + 6, 20, 99)
	noticia.emit("La joya pide pista",
		"%s la rompió en la práctica y golpea la puerta de la titularidad." % j.nombre)
	return {"tipo": "joya", "jugador": j}

func _suceso_cumple(mio: Club) -> Dictionary:
	var j: Jugador = mio.plantilla[Azar.ent(0, mio.plantilla.size() - 1)]
	for x: Jugador in mio.plantilla:
		x.moral = clampi(x.moral + 1, 10, 99)
	j.moral = clampi(j.moral + 4, 10, 99)
	noticia.emit("Cumpleaños en el camarín",
		"El plantel sorprendió a %s con torta y bromas. Buen ambiente." % j.nombre)
	return {"tipo": "cumple", "jugador": j}
