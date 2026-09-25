class_name Medico
extends RefCounted
## El parte médico: cuánto dura cada lesión, quién recae y qué cuesta acortarlo.
##
## Las 22 lesiones, sus plazos y su riesgo de recaída salen tal cual de la tabla
## LESIONES del HTML. No se redondean ni se "suavizan": un ligamento cruzado son
## 26-40 semanas porque con eso está equilibrada la temporada, y dejarlo en un
## par de meses convertiría la peor noticia del juego en un contratiempo.
##
## POR QUÉ ESTA CLASE LLEVA SU PROPIA FICHA
## El HTML colgaba del jugador media docena de campos sueltos —`lesTipo`,
## `lesTotal`, `lesRecaida`, `histLes`, `infMed`— que cualquiera de sus 847
## funciones podía pisar. Aquí `Jugador` solo sabe cuántas semanas le quedan
## fuera, que es lo único que necesitan el once y el simulador; el diagnóstico,
## el historial y los informes viven en `_fichas`, indexadas por id de jugador.
## Se paga con tener que guardarlas aparte (`a_dic`), y a cambio nadie puede
## corromper un historial médico sin pasar por esta puerta.
##
## El azar sale SIEMPRE de `Azar`. Una lesión decide una temporada, y si no es
## repetible no se puede reproducir la partida que reporte el usuario ni
## comparar dos ejecuciones del banco de pruebas.

## Diagnóstico nuevo. `causa` es el texto que remata la noticia ("durante el
## partido", "por sobrecarga de trabajo"): la interfaz la escribe, no la inventa.
signal lesion_nueva(j: Jugador, semanas: int, tipo: String, causa: String)
## Volvió antes de tiempo y se rompió otra vez. Va aparte de `lesion_nueva`
## porque para el entrenador es otra noticia: esta la provocó él.
signal recaida(j: Jugador, semanas: int, tipo: String)
signal recuperado(j: Jugador)
signal informe_listo(j: Jugador, informe: Dictionary)
signal gasto(concepto: String, monto: int)

## Gravedad que se le pide al catálogo. Son las tres del HTML (`sev`).
const LEVE := 0
const MEDIA := 1
const GRAVE := 2

## A partir de aquí una lesión cuenta como grave en el historial: es el umbral
## que castiga el valor de mercado y el que enciende el informe médico.
const SEM_GRAVE := 8
## Y a partir de aquí cuenta para el retiro forzado. Son dos números distintos a
## propósito: perder ocho semanas te devalúa, perder diez tres veces te retira.
const SEM_RETIRO := 10

## Cuántas lesiones se recuerdan por jugador. El HTML corta en diez y de ahí
## salen todas las cuentas del historial; guardar más movería los umbrales.
const HISTORIAL_MAX := 10

## Riesgo semanal del plan de entrenamiento por defecto del HTML (táctico,
## físico, técnico, fútbol, táctico y balón parado suman 6,0). El plan de la
## semana todavía no está portado, así que este es el valor neutro que usa el
## chequeo de fatiga mientras nadie le pase el suyo.
const CARGA_POR_DEFECTO := 6.0

## Tu club: los descuentos del cuerpo técnico solo valen para tus jugadores. Si
## se aplicaran a todos, contratar un jefe médico curaría antes también a los
## rivales, que es exactamente lo contrario de para lo que se le paga.
var mi_club_id: String = ""
var staff: Staff = null

## Días de baja que acumula tu plantel. Es el número que hace visible si el
## cuerpo médico sirve de algo: sin él, subir ese puesto es un botón a ciegas.
var dias_perdidos: int = 0

var _fichas: Dictionary = {}   ## id de jugador -> ficha médica

func _init(staff_propio: Staff = null, club_propio: String = "") -> void:
	staff = staff_propio
	mi_club_id = club_propio

# ---------------------------------------------------------------------------
#  CATÁLOGO
# ---------------------------------------------------------------------------

## Cada fila es [nombre, clase, mínimo, máximo, riesgo de recaída].
func catalogo() -> Array:
	var t: Variant = Datos.tabla("LESIONES")
	return t if t is Array else []

## Las tres bolsas del HTML. No son rangos de semanas sino filtros sobre el
## catálogo, y por eso una lesión leve sigue teniendo nombre propio: el jugador
## lee "rotura del gemelo", no "lesión media".
func _bolsa(sev: int) -> Array:
	var todas := catalogo()
	var pool: Array = []
	for fila: Array in todas:
		var minimo := int(fila[2])
		var maximo := int(fila[3])
		match sev:
			LEVE:
				if maximo <= 3:
					pool.append(fila)
			MEDIA:
				if minimo >= 2 and maximo <= 10:
					pool.append(fila)
			GRAVE:
				if maximo >= 8:
					pool.append(fila)
			_:
				pool.append(fila)
	## Si el filtro deja la bolsa vacía se sortea del catálogo entero antes que
	## no lesionar a nadie: quedarse sin lesión por un filtro es un fallo mudo.
	return pool if not pool.is_empty() else todas

## Gravedad de una lesión ocurrida en un partido: 12% grave y, si no, 50% media.
## El orden de los dos sorteos es el del HTML y consume el azar igual.
func severidad_en_partido() -> int:
	if Azar.suerte(0.12):
		return GRAVE
	if Azar.suerte(0.50):
		return MEDIA
	return LEVE

# ---------------------------------------------------------------------------
#  DIAGNOSTICAR
# ---------------------------------------------------------------------------

## Lesiona a un jugador y devuelve las semanas de baja.
##
## `anio` y `semana` solo se anotan en el historial, para poder contar "tres
## lesiones graves en pocos años". A cero significan "sin fecha": quien no lleve
## calendario sigue teniendo un historial utilizable.
func lesionar(j: Jugador, sev: int = MEDIA, causa: String = "", anio: int = 0, semana: int = 0) -> int:
	if j == null:
		return 0
	var pool := _bolsa(sev)
	if pool.is_empty():
		return 0
	var fila: Array = Azar.uno(pool)
	var sem := Azar.ent(int(fila[2]), int(fila[3]))
	## El frágil no solo se rompe más a menudo: también tarda más en volver.
	if j.rasgo == "fragil":
		sem = int(round(float(sem) * 1.3))
	## El HTML descontaba aquí un porcentaje por instalaciones, jefe médico y
	## kinesiólogo. De los tres solo existe el jefe médico, y su descuento ya
	## está escrito en `Staff.descuento_lesion` (resta semanas en vez de
	## multiplicar). Se usa ese y no se replica la fórmula vieja: el día que
	## cambie lo que aporta el médico, cambia en un solo sitio.
	if staff != null and j.club_id == mi_club_id:
		sem = staff.descuento_lesion(sem)
	sem = maxi(1, sem)

	var f := ficha(j)
	f["tipo"] = String(fila[0])
	f["clase"] = String(fila[1])
	f["total"] = sem              ## plazo original, para el % de rehabilitación
	f["riesgo_recaida"] = float(fila[4])
	var hist: Array = f["historial"]
	hist.append({"n": String(fila[0]), "sem": sem, "anio": anio, "semana": semana})
	while hist.size() > HISTORIAL_MAX:
		hist.remove_at(0)

	if j.club_id == mi_club_id:
		dias_perdidos += sem * 7
	## Pasa por `Jugador.lesionar` en vez de escribir `j.lesion` para que se
	## emita también la señal del propio jugador, que es a la que está
	## enganchada la interfaz del partido.
	j.lesionar(sem)
	## El historial pesa en el precio, así que hay que volver a tasar: es la
	## segunda lesión larga la que le hunde el valor de golpe.
	tasar(j)
	lesion_nueva.emit(j, sem, String(fila[0]), causa)
	return sem

# ---------------------------------------------------------------------------
#  LA FICHA
# ---------------------------------------------------------------------------

## La ficha médica de un jugador, creándola si es la primera vez. Devuelve el
## diccionario vivo, no una copia: quien la pide puede escribir en ella.
func ficha(j: Jugador) -> Dictionary:
	if not _fichas.has(j.id):
		_fichas[j.id] = {
			"tipo": "", "clase": "", "total": 0, "riesgo_recaida": 0.0,
			"terapia": 0, "informe": {}, "historial": [],
		}
	return _fichas[j.id]

## Qué tiene ahora mismo, vacío si está sano.
func diagnostico(j: Jugador) -> String:
	return String(ficha(j).get("tipo", "")) if j.lesion > 0 else ""

func historial(j: Jugador) -> Array:
	return ficha(j)["historial"]

## Porcentaje de rehabilitación cumplido. El tope es 99 a propósito: mientras le
## quede una semana no está recuperado, y un 100% en pantalla con el jugador
## todavía de baja es la clase de detalle que hace desconfiar de todo lo demás.
func pct_recuperado(j: Jugador) -> int:
	if j.lesion <= 0:
		return 100
	var total := maxi(int(ficha(j).get("total", j.lesion)), j.lesion)
	return clampi(int(round(float(total - j.lesion) * 100.0 / float(total))), 0, 99)

## Cuántas lesiones largas lleva encima. Es la medida de "cuerpo castigado" que
## usan el precio, el informe médico y el retiro forzado.
func lesiones_graves(j: Jugador, umbral: int = SEM_GRAVE) -> int:
	var n := 0
	for h: Dictionary in historial(j):
		if int(h.get("sem", 0)) >= umbral:
			n += 1
	return n

# ---------------------------------------------------------------------------
#  LO QUE EL HISTORIAL LE HACE AL PRECIO
# ---------------------------------------------------------------------------

## Dos lesiones de ocho semanas o más y el mercado deja de fiarse: -15%.
## No es un castigo moral, es cómo se ficha de verdad; nadie paga precio de
## catálogo por una rodilla con antecedentes.
func factor_valor(j: Jugador) -> float:
	return 0.85 if lesiones_graves(j) >= 2 else 1.0

## Tasa al jugador teniendo en cuenta su historial médico.
##
## `Jugador.tasar()` no puede hacerlo solo, porque el historial no vive en el
## jugador. Así que se tasa normal y se aplica el castigo encima, recalculando
## el sueldo desde el valor ya castigado, que es el orden del HTML. Al redondear
## dos veces (una en `tasar`, otra aquí) el resultado puede bailar menos de 100
## unidades respecto al original; a cambio la fórmula de tasar sigue viviendo en
## un solo sitio, que vale mucho más que esa diferencia.
func tasar(j: Jugador) -> void:
	j.tasar()
	var f := factor_valor(j)
	if is_equal_approx(f, 1.0):
		return
	j.valor = int(max(300.0, round(float(j.valor) * f / 100.0) * 100.0))
	j.sueldo = int(max(30.0, round(1.361 * pow(float(j.valor), 0.66) / 10.0) * 10.0))

# ---------------------------------------------------------------------------
#  RECAÍDA Y FATIGA
# ---------------------------------------------------------------------------

## Volver antes de tiempo. Solo recae quien ya está de alta pero con el físico
## por los suelos: el 0,35 es el freno del HTML, y sin él una pubalgia (0,32 de
## riesgo propio) se reabría casi una de cada tres semanas —no hay plantel que
## aguante eso.
##
## El HTML descontaba aquí un 12% por kinesiólogo. Ese puesto no existe en el
## cuerpo técnico portado y el jefe médico ya descuenta semanas al diagnosticar:
## meterlo también aquí sería cobrarle dos veces por el mismo nivel.
func chequeo_de_recaida(j: Jugador, anio: int = 0, semana: int = 0) -> int:
	var riesgo := float(ficha(j).get("riesgo_recaida", 0.0))
	if riesgo <= 0.0 or j.lesion > 0 or j.fisico >= 55:
		return 0
	if not Azar.suerte(riesgo * 0.35):
		return 0
	var sem := lesionar(j, MEDIA, "por volver antes de tiempo", anio, semana)
	recaida.emit(j, sem, String(ficha(j).get("tipo", "")))
	return sem

## Probabilidad de romperse esta semana por acumulación de trabajo.
##
## `carga` es el riesgo sumado de los seis días de entrenamiento: 0 con la
## semana entera de descanso, cerca de 13 machacando a diario. El físico bajo
## pesa un 50% más y el rasgo frágil un 60%: son los dos multiplicadores del
## HTML.
##
## Se mira `fisico` y no `forma` porque son cosas distintas: la forma es el
## momento del jugador —si la mete o no—, el físico es lo que le queda en las
## piernas, y lo que rompe un isquiotibial es lo segundo.
func riesgo_por_fatiga(j: Jugador, carga: float = CARGA_POR_DEFECTO) -> float:
	if j.lesion > 0:
		return 0.0
	var r := carga / 100.0
	r *= 1.0 - 0.08 * float(_nivel_medico(j))
	if j.rasgo == "fragil":
		r *= 1.6
	if j.fisico < 55:
		r *= 1.5
	return maxf(0.0, r * 0.09)

## Tira el dado de la fatiga. Devuelve las semanas de baja, o 0 si aguantó.
func chequeo_de_fatiga(j: Jugador, carga: float = CARGA_POR_DEFECTO, anio: int = 0, semana: int = 0) -> int:
	if j.lesion > 0:
		return 0
	if Azar.suerte(riesgo_por_fatiga(j, carga)):
		## La sobrecarga casi siempre deja una molestia y no una lesión seria:
		## solo una de cada cinco pasa de leve.
		return lesionar(j, MEDIA if Azar.suerte(0.20) else LEVE, "por sobrecarga de trabajo", anio, semana)
	## El frágil se rompe además en el gimnasio, sin partido y sin sobrecarga.
	## Es lo que hace que el rasgo se note incluso en una semana tranquila.
	if j.rasgo == "fragil" and j.fisico < 60 and Azar.suerte(0.04):
		return lesionar(j, LEVE, "en el gimnasio", anio, semana)
	return 0

func _nivel_medico(j: Jugador) -> int:
	if staff == null or j.club_id != mi_club_id:
		return 0
	return staff.nivel("medico")

# ---------------------------------------------------------------------------
#  LA SEMANA
# ---------------------------------------------------------------------------

## El parte médico de la semana para un plantel entero. Devuelve una lista de
## `{jugador, semanas, motivo}` con lo que ha pasado, para que la interfaz lo
## cuente sin tener que rastrear a nadie.
##
## OJO: aquí NO se descuenta la semana de baja de los lesionados. Eso ya lo hace
## `Mundo.avanzar_semana` sobre todos los jugadores del mundo, y repetirlo aquí
## curaría a tu plantel al doble de velocidad que al de los rivales: un fallo
## que no se ve en pantalla, solo en que tus lesionados vuelven antes de lo que
## dijo el parte.
func revisar_semana(c: Club, carga: float = CARGA_POR_DEFECTO, anio: int = 0, semana: int = 0) -> Array[Dictionary]:
	var partes: Array[Dictionary] = []
	if c == null:
		return partes
	for j in c.plantilla:
		rehabilitacion(j)
		var s := chequeo_de_fatiga(j, carga, anio, semana)
		if s > 0:
			partes.append({"jugador": j, "semanas": s, "motivo": "fatiga"})
			continue
		s = chequeo_de_recaida(j, anio, semana)
		if s > 0:
			partes.append({"jugador": j, "semanas": s, "motivo": "recaida"})
	return partes

## Gasta una semana de terapia intensiva, si la hay pagada, y con ella una
## semana extra de baja. Es lo ÚNICO que adelanta la recuperación por encima del
## descuento del jefe médico: si el médico acortara además todas las semanas por
## su cuenta, se le estaría pagando dos veces por el mismo nivel.
func rehabilitacion(j: Jugador) -> bool:
	var f := ficha(j)
	var quedan := int(f.get("terapia", 0))
	if quedan <= 0 or j.lesion <= 0:
		return false
	f["terapia"] = quedan - 1
	j.lesion -= 1
	if j.lesion <= 0:
		## Al recibir el alta se olvida la segunda opinión: la de la PRÓXIMA
		## lesión es otra lesión y se puede volver a pedir.
		_opiniones.erase(j.id)
		recuperado.emit(j)
	return true

# ---------------------------------------------------------------------------
#  LO QUE SE PAGA
# ---------------------------------------------------------------------------

## Acelerar una recuperación cuesta una parte fija escalada al tamaño del club y
## dos semanas del sueldo del jugador: al crack se le trae el especialista caro,
## al suplente no. Es lo que impide tratar al plantel entero por sistema.
func costo_terapia(j: Jugador, rep_club: int) -> int:
	return Eco.escalar(3000.0, float(rep_club)) + int(round(float(j.sueldo) * 2.0))

## Contrata la terapia. Devuelve "" si se hizo, o el motivo por el que no.
##
## En el HTML esta terapia alimentaba el sistema de salud mental (ansiedad,
## bajas psicológicas), que todavía no está portado. El precio no se toca y la
## duración tampoco —las mismas 3 a 5 semanas—, pero el efecto entra por la
## puerta que sí existe: cada una de esas semanas descuenta una de baja. Un
## botón de gastar dinero que no se nota en ningún número es un botón roto.
func terapia(j: Jugador, c: Club) -> String:
	if j.lesion <= 0:
		return "no está lesionado"
	var f := ficha(j)
	if int(f.get("terapia", 0)) > 0:
		return "ya está en terapia intensiva"
	var costo := costo_terapia(j, c.rep)
	if costo > c.saldo:
		return "no hay caja: cuesta %d y tienes %d" % [costo, c.saldo]
	c.mover_saldo(-costo)
	f["terapia"] = Azar.ent(3, 5)
	gasto.emit("Terapia deportiva · " + j.nombre, costo)
	return ""

## El informe médico de un jugador AJENO: saber qué compras antes de comprarlo.
## La parte que depende del valor (un 0,4%) es la que hace que revisar a una
## estrella cueste de verdad y no se pidan informes de medio mundo.
func costo_informe(j: Jugador, rep_club: int) -> int:
	return Eco.escalar(9000.0, float(rep_club)) + int(round(float(j.valor) * 0.004))

## Encarga el informe. Devuelve "" si se hizo, o el motivo por el que no.
## En el HTML se pagaba del presupuesto de ojeo, que no está portado: sale de la
## caja del club, que es la única bolsa que hay.
## `segundaOpinion()` del HTML: pagar por un segundo diagnóstico de una lesión.
## Puede acortar el plazo, alargarlo o confirmarlo, y **un buen cuerpo médico
## hace que el primer diagnóstico ya fuera bueno**: menos que corregir, pero
## también menos sorpresas desagradables. Se paga una vez por lesión.
func segunda_opinion(j: Jugador, c: Club) -> Dictionary:
	if j == null or j.club_id != c.id:
		return {"error": "ese jugador no es tuyo"}
	if j.lesion <= 0:
		return {"error": "no está lesionado"}
	if _opiniones.has(j.id):
		return {"error": "ya pediste una segunda opinión de esta lesión"}
	var coste := coste_segunda_opinion(j, c)
	if c.saldo < coste:
		return {"error": "caja insuficiente: cuesta %d" % coste}
	c.mover_saldo(-coste)
	gasto.emit("Segunda opinión médica: %s" % Nombres.limpiar(j.nombre), -coste)
	_opiniones[j.id] = true
	var nivel := _nivel_medico(j)
	var r := Azar.f()
	var delta := 0
	var texto := ""
	if r < 0.34 - float(nivel) * 0.02:
		delta = -maxi(1, int(round(float(j.lesion) * (0.25 + Azar.f() * 0.3))))
		texto = "El segundo especialista es más optimista: la lesión es menos grave de lo que parecía y el plazo se acorta."
	elif r < 0.52 - float(nivel) * 0.03:
		delta = maxi(1, int(round(float(j.lesion) * (0.2 + Azar.f() * 0.35))))
		texto = "Mala noticia: la segunda resonancia muestra un daño mayor. Hay que alargar la baja para no arriesgar una recaída."
	else:
		texto = "El segundo informe confirma punto por punto el diagnóstico del cuerpo médico. Dinero bien gastado en tranquilidad."
	j.lesion = maxi(1, j.lesion + delta)
	return {"ok": true, "delta": delta, "texto": texto, "coste": coste, "semanas": j.lesion}

func coste_segunda_opinion(j: Jugador, c: Club) -> int:
	return Eco.escalar(6000, c.rep) + int(round(float(j.sueldo) * 1.5))

var _opiniones: Dictionary = {}   ## id de jugador -> ya pidió opinión de ESTA lesión

func informe(j: Jugador, c: Club, anio: int = 0) -> String:
	var f := ficha(j)
	if not (f["informe"] as Dictionary).is_empty():
		return "ya tienes su informe médico"
	var costo := costo_informe(j, c.rep)
	if costo > c.saldo:
		return "no hay caja: cuesta %d y tienes %d" % [costo, c.saldo]
	c.mover_saldo(-costo)
	var inf := {"riesgo": riesgo_declarado(j), "graves": lesiones_graves(j), "anio": anio}
	f["informe"] = inf
	gasto.emit("Informe médico de " + j.nombre, costo)
	informe_listo.emit(j, inf)
	return ""

func informe_de(j: Jugador) -> Dictionary:
	return ficha(j)["informe"]

## El veredicto en una palabra. El frágil sin historial sale "medio-alto" y no
## "bajo": el informe está para avisar de lo que va a pasar, no solo de lo que
## ya pasó.
func riesgo_declarado(j: Jugador) -> String:
	var graves := lesiones_graves(j)
	if graves >= 2:
		return "alto"
	if graves == 1:
		return "medio"
	return "medio-alto" if j.rasgo == "fragil" else "bajo"

# ---------------------------------------------------------------------------
#  CUANDO EL CUERPO DICE BASTA
# ---------------------------------------------------------------------------

## Retiro forzado: tres lesiones de diez semanas o más y la rodilla ya no
## responde. No se aplica a los chicos —antes de los 27 se vuelve de casi todo—
## y ni siquiera entonces es seguro: es una probabilidad que crece con cada
## lesión larga. Quien lo llame se encarga de sacarlo del mundo; aquí solo se
## dictamina.
func retiro_forzado(j: Jugador) -> bool:
	var graves := lesiones_graves(j, SEM_RETIRO)
	if graves < 3 or j.edad < 27:
		return false
	return Azar.suerte(0.18 + 0.05 * float(graves))

# ---------------------------------------------------------------------------
#  GUARDAR
# ---------------------------------------------------------------------------

## Solo se guardan las fichas con algo dentro. En un mundo de once mil jugadores
## la inmensa mayoría no se ha lesionado nunca, y escribir once mil diccionarios
## vacíos engorda la partida sin decir nada: el guardado ya costó una depuración
## entera por tamaño.
# ---------------------------------------------------------------------------
#  EL DEPARTAMENTO MÉDICO VISTO DE FUERA
# ---------------------------------------------------------------------------
#
# Tres cosas que `vMedico()` enseña y que aquí no existían. Las tres responden a
# la misma pregunta —¿mi cuerpo médico es bueno o no?— y ninguna se puede
# contestar mirando un jugador: hacen falta el ACUMULADO de la temporada y la
# comparación con los otros clubes.

## El brote: una gripe que se lleva a media plantilla unos días. Vacío si no hay.
var brote: Dictionary = {}

## Dónde estás en la liga por semanas perdidas. Devuelve tu puesto, el total de
## clubes, tus semanas y la media.
##
## Los otros clubes no llevan ficha médica -sería guardar 384 historiales para
## nada-, así que su cifra se ESTIMA a partir de lo que se sabe de ellos: los
## que tienen mejor reputación tienen mejor cuerpo médico y pierden menos. No es
## una simulación, es una referencia, y como tal se presenta.
func ranking_liga(mio: Club, liga: Liga) -> Dictionary:
	if liga == null or mio == null:
		return {"puesto": 1, "total": 1, "mias": dias_perdidos / 7, "media": dias_perdidos / 7}
	var cifras: Array = []
	var suma := 0
	for c: Club in liga.clubes:
		var n := (dias_perdidos / 7) if c == mio else _estimar_semanas(c)
		cifras.append({"club": c, "n": n})
		suma += n
	cifras.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["n"]) < int(b["n"]))
	var puesto := 1
	for i in cifras.size():
		if (cifras[i] as Dictionary)["club"] == mio:
			puesto = i + 1
	return {
		"puesto": puesto, "total": cifras.size(),
		"mias": dias_perdidos / 7,
		"media": int(round(float(suma) / float(maxi(1, cifras.size())))),
	}

## La estimación para los clubes de la IA: alrededor de la media, peor cuanto
## más modesto es el club. El hash del id la hace ESTABLE —el mismo club da
## siempre la misma cifra dentro de una temporada— porque un ranking que baila
## en cada repintado no se puede leer.
func _estimar_semanas(c: Club) -> int:
	var h := 0
	for i in c.id.length():
		h = (h * 31 + c.id.unicode_at(i)) & 0x7FFFFFFF
	var base := 26.0 - float(c.rep - 50) * 0.16
	return maxi(4, int(round(base + float(h % 11) - 5.0)))

## Arranca un brote. Lo llama el pulso semanal cuando toca: unos cuantos tocados
## a la vez, que es lo que obliga a rotar de verdad.
func iniciar_brote(c: Club, cuantos: int, semanas: int) -> void:
	brote = {"n": cuantos, "semanas": semanas}
	var sanos: Array[Jugador] = []
	for j in c.plantilla:
		if j.lesion <= 0:
			sanos.append(j)
	Azar.barajar(sanos)
	for i in mini(cuantos, sanos.size()):
		var j2: Jugador = sanos[i]
		j2.fisico = clampi(j2.fisico - Azar.ent(18, 34), 20, 100)

func avanzar_brote() -> void:
	if brote.is_empty():
		return
	brote["semanas"] = int(brote["semanas"]) - 1
	if int(brote["semanas"]) <= 0:
		brote = {}

func a_dic() -> Dictionary:
	var f := {}
	for id: String in _fichas:
		var x: Dictionary = _fichas[id]
		var sin_historial: bool = (x["historial"] as Array).is_empty()
		var sin_informe: bool = (x["informe"] as Dictionary).is_empty()
		if sin_historial and sin_informe and int(x.get("terapia", 0)) <= 0:
			continue
		f[id] = x
	return {"dias": dias_perdidos, "fichas": f, "brote": brote.duplicate()}

func desde_dic(d: Dictionary) -> void:
	dias_perdidos = int(d.get("dias", 0))
	brote = (d.get("brote", {}) as Dictionary).duplicate()
	_fichas.clear()
	var f: Dictionary = d.get("fichas", {})
	for id: String in f:
		var x: Dictionary = f[id]
		_fichas[id] = {
			"tipo": String(x.get("tipo", "")),
			"clase": String(x.get("clase", "")),
			"total": int(x.get("total", 0)),
			"riesgo_recaida": float(x.get("riesgo_recaida", 0.0)),
			"terapia": int(x.get("terapia", 0)),
			"informe": x.get("informe", {}),
			"historial": x.get("historial", []),
		}
