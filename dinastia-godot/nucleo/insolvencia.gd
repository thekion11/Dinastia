class_name Insolvencia
extends RefCounted
## LA INSOLVENCIA (28-9-2026, bloques 39-40 del plan maestro). `Banco` ya lleva
## los créditos, la renegociación, el bono social de la hinchada, la mora, el
## veedor y la liquidación. Aquí va lo que pasa por el camino:
##
##   - RESTA DE PUNTOS: cuando llega el veedor, la federación descuenta 6
##     puntos en la liga (una vez por temporada).
##   - EL ADMINISTRADOR Y EL TOPE SALARIAL: con veedor, la masa salarial queda
##     topada al 80 % de la que había; cada dos semanas, si se pasa, el
##     administrador vende al que más cobra a precio de saldo.
##   - TU CLÁUSULA DE SALIDA (si eres el DT): al entrar en mora puedes
##     activarla y marcharte sin mancha, o quedarte a pelearla.
##   - LA REFUNDACIÓN: una semana antes de la liquidación, la asamblea ofrece
##     refundar el club: se perdona la deuda a cambio de vender a los cinco
##     sueldos más altos, perder reputación y empezar de cero en la caja.
##
## Usa su propio generador para no mover otras tiradas de la simulación.

signal noticia(titulo: String, cuerpo: String)
signal movimiento(concepto: String, monto: int)

const PUNTOS_SANCION := 6
const TOPE := 0.8

var pendiente: Dictionary = {}
var sancion_anio := -1          ## la temporada en que ya se restaron puntos
var tope_salarial := 0          ## 0 = sin tope (sin veedor)
var refundado_anio := -1
var _rng := RandomNumberGenerator.new()

func _init() -> void:
	_rng.seed = 3940

func semana(m: Mundo) -> void:
	var c := m.mi_club()
	var b := m.banco
	if c == null or b == null or b.liquidado_ya:
		return
	var rojo := b.semanas_en_rojo
	## Cláusula de salida del DT, al entrar en mora.
	if rojo == Banco.SEM_MORA and pendiente.is_empty() and m.roles != null and m.roles.rol == Roles.DT:
		pendiente = {"id": "clausula",
			"texto": "El club entró en mora. Tu contrato tiene una cláusula de salida por impago: puedes activarla y marcharte sin mancha, o quedarte a pelearla con la gente.",
			"a": "Quedarme a pelearla", "b": "Activar la cláusula y salir"}
	## El veedor: resta de puntos y tope salarial.
	if b.hay_veedor():
		if sancion_anio != m.anio:
			sancion_anio = m.anio
			_restar_puntos(m, c)
		if tope_salarial <= 0:
			tope_salarial = int(round(float(c.masa_salarial()) * TOPE))
			noticia.emit("📉 Tope salarial", "El administrador concursal limita la masa salarial a %s por semana. Lo que sobre, se vende." % Cesiones.dinero(tope_salarial))
		if rojo % 2 == 0 and c.masa_salarial() > tope_salarial:
			_venta_forzada(m, c)
	elif c.saldo >= 0:
		tope_salarial = 0
	## La refundación, una semana antes de liquidar.
	var limite := Banco.SEM_LIQUIDACION + b.gracia_liquidacion
	if rojo == limite - 1 and refundado_anio != m.anio:
		pendiente = {"id": "refundacion",
			"texto": "Queda una semana para la liquidación. La asamblea de socios propone REFUNDAR el club: se perdona la deuda, pero se venden los cinco sueldos más altos y la reputación cae. Si no, el club se liquida y te vas.",
			"a": "Refundar el club", "b": "Dejar que se liquide"}

func _restar_puntos(m: Mundo, c: Club) -> void:
	for l in m.ligas:
		if l.clubes.has(c) and l.tabla_puntos.has(c.id):
			l.tabla_puntos[c.id]["pts"] = int(l.tabla_puntos[c.id]["pts"]) - PUNTOS_SANCION
			noticia.emit("⚖️ %d puntos menos" % PUNTOS_SANCION, "La federación sanciona a %s por impagos: le resta %d puntos en la tabla." % [c.nombre, PUNTOS_SANCION])
			return

## Vende al que más cobra a un club con caja, al 70 % de lo que vale.
func _venta_forzada(m: Mundo, c: Club) -> Jugador:
	if c.plantilla.size() <= 16:
		return null
	var caro: Jugador = null
	for j: Jugador in c.plantilla:
		if caro == null or j.sueldo > caro.sueldo:
			caro = j
	if caro == null:
		return null
	var monto := int(round(float(caro.valor) * 0.7))
	## Solo a un club con sitio (menos de 26) y, si es portero, con menos de
	## tres: antes iba siempre al de más reputación y la prueba larga encontró
	## un club con 51 jugadores y 8 porteros tras diez temporadas.
	var comprador: Club = null
	for otro: Club in m.clubes.values():
		if otro.id == c.id or otro.saldo < monto * 2 or otro.plantilla.size() >= 26:
			continue
		if caro.es_portero() and otro.plantilla.filter(func(x: Jugador) -> bool: return x.es_portero()).size() >= 3:
			continue
		if comprador == null or otro.rep > comprador.rep:
			comprador = otro
	if comprador == null:
		return null
	if m.cesiones != null:
		m.cesiones.vender(caro, comprador, monto, 0)
	else:
		comprador.mover_saldo(-monto)
		c.mover_saldo(monto)
		c.soltar(caro)
		comprador.fichar(caro)
	noticia.emit("🏷️ Venta forzada", "El administrador vende a %s a %s por %s, lejos de lo que vale." % [caro.nombre, comprador.nombre, Cesiones.dinero(monto)])
	return caro

func resolver(m: Mundo, op: String) -> Dictionary:
	if pendiente.is_empty():
		return {}
	var p := pendiente
	pendiente = {}
	var c := m.mi_club()
	match String(p["id"]):
		"clausula":
			if op == "b":
				if m.roles != null:
					m.roles.quedar_sin_banco()
				return {"titulo": "🚪 Activas la cláusula", "cuerpo": "Te vas por la puerta grande: el impago fue del club, no tuyo. Elige tu próximo destino.", "salio": true}
			if m.roles != null:
				m.roles.anotar_reputacion("leal", 4, "Te quedaste con el club en mora")
			if m.directiva != null:
				m.directiva.mover_confianza(5, "te quedaste en la crisis")
			return {"titulo": "🛡️ Te quedas", "cuerpo": "La gente lo sabe y lo agradece. Ahora hay que salir del pozo."}
		"refundacion":
			if op == "b":
				return {"titulo": "Sin refundación", "cuerpo": "La asamblea no insiste. La próxima semana, la liquidación."}
			refundado_anio = m.anio
			var vendidos: Array[String] = []
			for _i in 5:
				var j := _venta_forzada(m, c)
				if j == null:
					break
				vendidos.append(j.nombre)
			m.banco.prestamos.clear()
			m.banco.semanas_en_rojo = 0
			c.saldo = int(round(Eco.ref_caja(float(c.rep)) * 0.02))
			c.rep = maxi(5, c.rep - 12)
			tope_salarial = 0
			if m.roles != null:
				m.roles.anotar_reputacion("leal", 3, "Refundaste el club con los socios")
			noticia.emit("🔄 Club refundado", "Deuda perdonada, caja a cero y reputación en el suelo. Se fueron: %s." % (", ".join(vendidos) if not vendidos.is_empty() else "nadie más"))
			return {"titulo": "🔄 El club se refunda", "cuerpo": "Se salva el club. Empieza otra historia, más modesta."}
	return {}

func a_dic() -> Dictionary:
	return {"pend": pendiente.duplicate(true), "sancion": sancion_anio, "tope": tope_salarial, "refundado": refundado_anio}

func desde_dic(d: Dictionary) -> void:
	if d.is_empty():
		return
	pendiente = (d.get("pend", {}) as Dictionary).duplicate(true)
	sancion_anio = int(d.get("sancion", -1))
	tope_salarial = int(d.get("tope", 0))
	refundado_anio = int(d.get("refundado", -1))
