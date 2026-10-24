extends "res://nucleo/vestuario_p1.gd"
## [Capa 2/4 de `vestuario.gd`] chequeo_clanes, mediar, estado_mental, _proceso_mental, dar_terapia, descanso_mental … (+13)

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

## La demarcación agrupada de POSD ("LAT", "DFC", "MED"...), que es con la que
## se compara el escalafón dentro del puesto.
func _demarcacion(j: Jugador) -> String:
	var posd := Datos.posd()
	if posd.has(j.pos_e):
		return String((posd[j.pos_e] as Dictionary).get("d", "MED"))
	return "MED"

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

## Escribe el rol sin negociar ni mover moral. La usan la renovación y la carga
## de partida, que ya han hecho sus propias cuentas. La ventana de cumplimiento
## se pone a cero: la promesa nueva se juzga desde hoy, no con lo que pasó bajo
## la anterior.
func fijar_rol(j: Jugador, rol: String) -> void:
	_rol[j.id] = rol
	_rol_cuenta[j.id] = {"pj": 0, "min": 0}

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
