class_name Negociacion
extends RefCounted
## "LA MESA DE NEGOCIACIÓN" del HTML (`abrirNegociacion`/`enviarOferta`/
## `cerrarFichaje`): la puerta de fichar de verdad, con dos partes que
## convencer por separado -el club vendedor primero, después el jugador y su
## agente- y una mesa que se puede alargar, romper o perder frente a un rival
## que anda detrás del mismo objetivo. `Mercado.fichar()`/`_intentar_fichar()`
## seguían siendo la puerta rápida de un solo golpe: esto es la puerta larga.
##
## UNA SIMPLIFICACIÓN DELIBERADA, decidida con el usuario: en el HTML cada
## ronda de mesa consume DÍAS de un calendario que Godot no lleva -el motor
## aquí avanza por SEMANAS, no por días-. Portar el conteo de días habría
## significado tocar cómo `Mundo`/`Liga` llevan el tiempo, un cambio de
## arquitectura mucho más grande que esta mesa. Aquí cada "enviar oferta" es
## una ronda, sin gastar tiempo de calendario -se puede negociar varias veces
## en la misma semana-. El arbol de perks del DT SI cuenta desde la auditoria:
## `Entrenamiento.bono_agentes()` baja el umbral que hay que alcanzar, que es lo
## que hacia `dtTiene('negociador'/'icono')` en el HTML. Queda fuera solo el
## acuerdo de agente en exclusiva (`G.exclusiva`), que es un empujon numerico
## pequeño y no la estructura de la mesa.
##
## El asentamiento del dinero -cuotas, bonos, porcentaje de venta futura,
## cláusula, pago opaco, derechos de formación, comisión- NO se reescribe
## aquí: se llama a `Cesiones.registrar_compromisos()`, que ya estaba escrita
## y probada para la cesión con opción de compra y nadie más la usaba.

var _ref: WeakRef

var jugador: Jugador
var club_vendedor_id: String
var ronda: int = 1
var pedido: int
var paciencia: int
var estado: String = "abierta"   ## abierta / rota / cerrada
var rival_id: String = ""
var acuerdo_club: bool = false

## Lo que se negocia CON EL CLUB.
var fijo: int = 0
var cuotas: int = 0
var bonos: int = 0
var pct: int = 0
var opaco: int = 0
var intercambio: Jugador = null

## Lo que se negocia CON ÉL.
var rol: String = "rotacion"
var anios: int = 3
var sueldo: int = 0
var firma: int = 0
var clausula: bool = false
var paciencia_jugador: int

const ORDEN_ROLES := ["intocable", "titular", "rotacion", "suplente", "promesa", "prescindible"]

func _init(mundo: Mundo, j: Jugador) -> void:
	_ref = weakref(mundo)
	jugador = j
	club_vendedor_id = j.club_id
	pedido = mundo.mercado.valor_pedido(j)
	paciencia = Azar.ent(3, 5)
	fijo = int(round(float(pedido) * 0.7 / 1000.0)) * 1000
	rol = _rol_sugerido(mundo, j)
	sueldo = _pide_fichaje(mundo, j, rol, anios)
	paciencia_jugador = Azar.ent(3, 4)
	rival_id = _rival_en_juego(mundo, j)

func _mundo() -> Mundo:
	return _ref.get_ref() as Mundo

# ---------------------------------------------------------------------------
#  AJUSTES DE LA MESA
# ---------------------------------------------------------------------------

func ajustar(campo: String, delta: int) -> void:
	var paso := maxi(1000, int(round(float(pedido) * 0.05 / 1000.0)) * 1000)
	match campo:
		"pct":
			pct = clampi(pct + delta * 5, 0, 50)
		"sueldo":
			sueldo = maxi(30, sueldo + delta * maxi(10, int(round(float(sueldo) * 0.05 / 10.0)) * 10))
		"anios":
			anios = clampi(anios + delta, 1, 5)
			sueldo = _pide_fichaje(_mundo(), jugador, rol, anios)
		"firma":
			firma = maxi(0, firma + delta * maxi(1000, int(round(float(sueldo) * 4.0 / 1000.0)) * 1000))
		"fijo":
			fijo = maxi(0, fijo + delta * paso)
		"cuotas":
			cuotas = maxi(0, cuotas + delta * paso)
		"bonos":
			bonos = maxi(0, bonos + delta * paso)
		"opaco":
			opaco = maxi(0, opaco + delta * paso)

func ajustar_rol(rol_nuevo: String) -> void:
	rol = rol_nuevo
	sueldo = _pide_fichaje(_mundo(), jugador, rol, anios)

func alternar_clausula() -> void:
	clausula = not clausula

func poner_intercambio(j2: Jugador) -> void:
	intercambio = null if intercambio == j2 else j2

# ---------------------------------------------------------------------------
#  LO QUE PERCIBE CADA LADO
# ---------------------------------------------------------------------------

## Lo que el club vendedor percibe de verdad que le estás ofreciendo -
## `valorPercibido()` del HTML: el dinero a plazos vale menos, los bonos
## todavía menos, y lo opaco vale más porque no paga comisión ni impuestos.
func valor_percibido() -> int:
	var v := float(fijo) + float(cuotas) * 0.82 + float(bonos) * 0.35 + (float(pct) / 100.0) * float(jugador.valor) * 0.45 + float(opaco) * 1.2
	if intercambio != null:
		v += float(intercambio.valor) * 0.88
	return int(round(v))

## Lo que sale de tu caja EL MISMO DÍA que se cierra: la parte fija, lo opaco,
## la prima y la comisión del agente sobre lo fijo.
func costo_inmediato() -> int:
	var m := _mundo()
	var com := m.cantera.comision(jugador, fijo) if m != null and m.cantera != null else 0
	return fijo + opaco + firma + com

# ---------------------------------------------------------------------------
#  UNA RONDA
# ---------------------------------------------------------------------------

## Envía la oferta actual y avanza una ronda. Devuelve un Dictionary con
## "tipo" describiendo qué pasó, para que la interfaz lo cuente:
## "sin_caja" | "rival_traspaso" | "rival_firma" | "jugador_no" (contraoferta
## del jugador) | "jugador_rota" | "club_pide_mas" (contraoferta del club) |
## "rota" | "cerrado".
func enviar_oferta() -> Dictionary:
	if estado != "abierta":
		return {"tipo": "cerrada"}
	var m := _mundo()
	var club: Club = m.clubes.get(club_vendedor_id)
	var mio := m.mi_club()
	if club == null or mio == null:
		estado = "rota"
		return {"tipo": "rota"}
	var inmediato := costo_inmediato()
	if inmediato > mio.saldo:
		return {"tipo": "sin_caja", "hace_falta": inmediato}

	var percibido := valor_percibido()
	var ratio := float(percibido) / float(maxi(1, pedido))
	var confianza_agente := 0.0
	if m.cantera != null:
		var nombre_ag := String(m.cantera.agente_de(jugador).get("nombre", ""))
		confianza_agente = float(m.cantera.confianza_de(nombre_ag)) * 0.02
	## EL ARBOL DEL ENTRENADOR EN LA MESA. `bono_agentes()` suma un 8% por
	## «Negociador» y un 6% por «Icono», y no la llamaba nadie: los dos nodos que
	## existen para negociar mejor no negociaban nada.
	var perks := m.entrenamiento.bono_agentes() if m.entrenamiento != null else 0.0
	var umbral := 0.97 - confianza_agente - perks - float(ronda - 1) * 0.04

	if acuerdo_club or ratio >= umbral:
		var primera_vez := not acuerdo_club
		acuerdo_club = true
		if rival_id != "":
			var rc: Club = m.clubes.get(rival_id)
			if rc != null and float(rc.saldo) >= float(pedido) * 0.9 and Azar.suerte(clampf(0.08 + float(ronda - 1) * 0.05, 0.04, 0.40)):
				var precio := int(round(float(pedido) * (0.95 + Azar.f() * 0.20) / 1000.0)) * 1000
				rc.mover_saldo(-precio)
				club.mover_saldo(precio)
				jugador.club_id = rc.id
				jugador.moral = clampi(jugador.moral - 6, 10, 99)
				estado = "rota"
				return {"tipo": "rival_firma", "club": rc, "precio": precio}
		var r := _respuesta_del_jugador(m)
		if bool(r.get("ok", false)):
			var resumen := _cerrar_fichaje(m)
			estado = "cerrada"
			return {"tipo": "cerrado", "resumen": resumen}
		ronda += 1
		paciencia_jugador -= 1
		if paciencia_jugador <= 0:
			estado = "rota"
			jugador.no_negociar_hasta = m.semana + 8
			return {"tipo": "jugador_rota", "motivo": r.get("txt", "")}
		return {"tipo": "jugador_no", "motivo": r.get("txt", ""), "pide": int(r.get("pide", 0)), "primera_vez": primera_vez}

	if rival_id != "":
		var rc2: Club = m.clubes.get(rival_id)
		var proba := clampf(0.10 + float((rc2.rep if rc2 != null else club.rep) - club.rep) * 0.012 + float(ronda - 1) * 0.06, 0.04, 0.55)
		if rc2 != null and float(rc2.saldo) >= float(pedido) * 0.9 and Azar.suerte(proba):
			var precio2 := int(round(float(pedido) * (0.92 + Azar.f() * 0.18) / 1000.0)) * 1000
			rc2.mover_saldo(-precio2)
			club.mover_saldo(precio2)
			jugador.club_id = rc2.id
			jugador.moral = clampi(jugador.moral - 6, 10, 99)
			estado = "rota"
			return {"tipo": "rival_traspaso", "club": rc2, "precio": precio2}

	ronda += 1
	paciencia -= 1
	if paciencia <= 0:
		estado = "rota"
		jugador.no_negociar_hasta = m.semana + 8
		return {"tipo": "rota"}
	var falta := int(round((float(pedido) * umbral - float(percibido)) / 1000.0)) * 1000
	var prefiere := "una cifra fija mayor"
	if cuotas > fijo:
		prefiere = "más dinero por delante y menos a plazos"
	elif bonos > fijo / 2:
		prefiere = "menos bonos y más garantizado"
	elif pct > 25:
		prefiere = "que te olvides del porcentaje y subas la parte fija"
	return {"tipo": "club_pide_mas", "falta": falta, "prefiere": prefiere}

func _respuesta_del_jugador(m: Mundo) -> Dictionary:
	var mio := m.mi_club()
	if m.vestuario != null:
		var acepta: Dictionary = m.vestuario.acepta_rol(jugador, rol)
		if not bool(acepta.get("ok", true)):
			return {"ok": false, "motivo": "rol", "txt": String(acepta.get("txt", "")), "pide": 0}
	var pide := _pide_fichaje(m, jugador, rol, anios)
	if sueldo < int(round(float(pide) * 0.92)):
		return {"ok": false, "motivo": "ficha", "txt": "", "pide": pide}
	var deseo: Dictionary = m.mercado.deseo_de_venir(jugador, mio)
	var d: float = float(deseo.get("p", 0.5))
	var dinero_f := clampf((float(sueldo) / float(maxi(1, pide)) - 1.0) * 0.9, -0.5, 0.35)
	var prima_ok := firma >= int(round(float(pide) * 4.0))
	var p := clampf(d + dinero_f + (0.10 if prima_ok else 0.0) + (0.08 if clausula else 0.0) +
		(0.04 if anios >= 4 else (-0.06 if anios <= 1 else 0.0)) + float(ronda - 1) * 0.03, 0.01, 0.97)
	if Azar.suerte(p):
		return {"ok": true, "motivo": "", "txt": "", "pide": pide}
	var razones: Array = deseo.get("razones", [])
	var peor := "No le termina de convencer el proyecto."
	for r: Dictionary in razones:
		if not bool(r.get("bien", true)):
			peor = String(r.get("txt", peor)) + "."
			break
	return {"ok": false, "motivo": "convencido", "txt": peor, "pide": pide}

func _cerrar_fichaje(m: Mundo) -> Dictionary:
	var club: Club = m.clubes.get(club_vendedor_id)
	var mio := m.mi_club()
	var oferta := {"fijo": fijo, "cuotas": cuotas, "bonos": bonos, "pct": pct, "clausula": clausula, "opaco": opaco, "firma": firma}
	var resumen: Dictionary = {}
	if m.cesiones != null:
		resumen = m.cesiones.registrar_compromisos(jugador, oferta, mio, club)
	else:
		mio.mover_saldo(-fijo)
		club.mover_saldo(fijo)
	club.soltar(jugador)
	mio.fichar(jugador)
	if m.vestuario != null:
		m.vestuario.fijar_rol(jugador, rol)
	jugador.anios_contrato = anios
	jugador.sueldo = sueldo
	jugador.pide_salir = false
	jugador.transferible = false
	jugador.moral = 78
	## La cláusula ya la pacta `registrar_compromisos()` -lee `oferta["clausula"]`
	## y llama a `pactar_clausula()` por dentro-: llamarla otra vez aquí sería
	## blindarlo dos veces con dos números distintos.
	if intercambio != null:
		mio.soltar(intercambio)
		club.fichar(intercambio)
	if m.roles != null:
		m.roles.usar_emergencia()
	resumen["rol"] = rol
	resumen["anios"] = anios
	resumen["sueldo"] = sueldo
	return resumen

# ---------------------------------------------------------------------------
#  AYUDANTES ESTÁTICOS -no dependen del estado de esta mesa, solo del Mundo-
# ---------------------------------------------------------------------------

## `rolPorMedia()` del HTML, pero sobre el ranking que ya usa `Vestuario.
## acepta_rol()` -que compara dentro de SU club actual, no del destino, así
## que se usa solo para saber si aceptaría el papel, no para rankearlo-.
static func _rol_sugerido(m: Mundo, j: Jugador) -> String:
	var destino := m.mi_club()
	if destino == null:
		return "titular"
	var ovrs: Array[int] = []
	for x in destino.plantilla:
		if x.id != j.id:
			ovrs.append(x.ovr)
	if ovrs.is_empty():
		return "titular"
	ovrs.sort()
	ovrs.reverse()
	var mejores := 0
	for o in ovrs:
		if o > j.ovr:
			mejores += 1
	var tope := mini(11, ovrs.size())
	var suma := 0
	for i in tope:
		suma += ovrs[i]
	var media_xi := float(suma) / float(tope)
	var k := "titular"
	if mejores <= 2 and float(j.ovr) >= media_xi + 4.0:
		k = "intocable"
	elif mejores <= 10:
		k = "titular"
	elif mejores <= 15:
		k = "rotacion"
	else:
		k = "suplente"
	if j.edad <= 21 and j.pot >= j.ovr + 8 and (k == "rotacion" or k == "suplente"):
		k = "promesa"
	if m.vestuario == null:
		return k
	if bool(m.vestuario.acepta_rol(j, k).get("ok", true)):
		return k
	var i0 := ORDEN_ROLES.find(k)
	for d in range(1, ORDEN_ROLES.size()):
		for i in [i0 - d, i0 + d]:
			if i >= 0 and i < ORDEN_ROLES.size() and bool(m.vestuario.acepta_rol(j, ORDEN_ROLES[i]).get("ok", false)):
				return ORDEN_ROLES[i]
	return k

## `pideFichaje()` del HTML: lo mismo que pide para renovar, más un recargo si
## no tiene ganas de venir -cuanto menos le apetece, más caro sale convencerlo.
static func _pide_fichaje(m: Mundo, j: Jugador, rol: String, anios_: int) -> int:
	var base := m.vestuario.pide_con_rol(j, rol, anios_) if m.vestuario != null else j.sueldo
	var mio := m.mi_club()
	var d := 0.5
	if m.mercado != null and mio != null:
		d = float(m.mercado.deseo_de_venir(j, mio).get("p", 0.5))
	var recargo := 1.0 + clampf((0.5 - d) * 1.5, -0.15, 0.80)
	return maxi(30, int(round(float(base) * recargo / 10.0)) * 10)

## `rivalEnJuego()` del HTML: cuanto más deseable -proyección, poco
## contrato-, más chance de que otro club también ande detrás.
static func _rival_en_juego(m: Mundo, j: Jugador) -> String:
	var deseo := clampf(0.12 + float(j.pot - j.ovr) * 0.012 + float(j.ovr - 62) * 0.006 + (0.08 if j.anios_contrato <= 1 else 0.0), 0.08, 0.55)
	if not Azar.suerte(deseo):
		return ""
	var pedido := m.mercado.valor_pedido(j)
	var candidatos: Array[Club] = []
	for c: Club in m.clubes.values():
		if c.id != m.mi_club_id and c.id != j.club_id and c.rep >= j.ovr - 12 and float(c.saldo) >= float(pedido) * 0.75:
			candidatos.append(c)
	if candidatos.is_empty():
		return ""
	return (candidatos[Azar.ent(0, candidatos.size() - 1)] as Club).id
