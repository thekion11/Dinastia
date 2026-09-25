class_name Banco
extends RefCounted
## LA DEUDA: créditos, cuotas y el camino a la liquidación.
##
## `vBanco()` del HTML. Es el único sistema del juego que puede TERMINAR una
## partida sin que pierdas un partido: doce semanas con la caja en rojo y el
## proyecto se liquida.
##
## POR QUÉ IMPORTA QUE EXISTA. Sin deuda, quedarse sin dinero es solo no poder
## fichar: molesto y reversible. Con deuda, la caja en rojo tiene un reloj
## corriendo —sobregiro, mora, veedor, liquidación— y eso convierte cada
## fichaje caro en una apuesta de verdad.
##
## La cuota es FRANCESA (cuota constante, intereses decrecientes), que es como
## funcionan los créditos de verdad y lo que hace que prepagar temprano ahorre
## mucho y prepagar tarde no ahorre casi nada.

signal movimiento(concepto: String, monto: int)
signal aviso(titulo: String, texto: String)
## El club se liquida: fin de la partida por la vía de la caja.
signal liquidado

## Los cuatro escalones del deterioro, en semanas con la caja en rojo.
const SEM_MORA := 4
const SEM_VEEDOR := 8
const SEM_LIQUIDACION := 12

## Interés semanal del sobregiro: lo que cuesta estar en números rojos aunque no
## debas nada a nadie.
const INTERES_SOBREGIRO := 0.015

## Como mucho dos líneas a la vez. Sin tope, la salida a cualquier apuro sería
## pedir otro crédito y la deuda dejaría de dar miedo.
const MAX_PRESTAMOS := 2

## nombre, tasa semanal, número de cuotas. De más barato y corto a más caro y
## largo: la banca seria presta poco tiempo, el prestamista rápido presta mucho.
const BANCOS := [
	["Banco del Deporte", 0.010, 26],
	["Caja Regional", 0.014, 40],
	["Financiera Rápida", 0.022, 60],
]

## El bono social: la hinchada compra deuda del club. Más barato que un banco y
## disponible incluso en mora, pero si el club se liquida sin pagarlo, la
## afición no lo olvida.
const TASA_BONO := 0.005
const CUOTAS_BONO := 52

var prestamos: Array = []      ## {banco, deuda, cuota, restan, tasa, renegociado, bono}
var semanas_en_rojo: int = 0
var liquidado_ya: bool = false

## LOS DOS CONSEJEROS QUE DECÍAN "SIN EFECTO" (13-9-2026). `Directiva.CONSEJEROS`
## ofrece "Consejero financiero" y "Consejero legal" desde antes de que esta
## clase existiera, con la descripción "sin efecto: aún no hay banco/sistema
## legal en Godot" -cierto EN SU MOMENTO, falso ahora que `Banco` existe: un
## jugador podía pagar 600.000 + 15.000/semana por un consejero que de verdad
## no hacía nada, sin que la interfaz avisara que ya se podía enganchar-.
## `Mundo` los pone al contratar/despedir, `Banco` no conoce a `Directiva`.
var descuento_sobregiro: float = 1.0     ## 1.0 = normal; el financiero lo baja
var gracia_liquidacion: int = 0          ## semanas de más antes de liquidar; el legal las da

## La cuota francesa: c = D·i / (1 − (1+i)^−n). Con interés cero se reparte a
## partes iguales, que es el caso límite de la misma fórmula.
static func cuota_francesa(deuda: int, tasa: float, cuotas: int) -> int:
	if cuotas <= 0:
		return deuda
	if tasa <= 0.0:
		return int(ceil(float(deuda) / float(cuotas)))
	var f := pow(1.0 + tasa, -float(cuotas))
	return int(ceil(float(deuda) * tasa / (1.0 - f)))

## Cuánto presta cada banco. Se escala a la reputación del club: a un grande le
## prestan más porque tiene con qué responder.
static func monto_linea(i: int, c: Club) -> int:
	var base := [1200000.0, 2600000.0, 5000000.0]
	return Eco.escalar(float(base[i % base.size()]), float(c.rep))

func en_mora() -> bool:
	return semanas_en_rojo >= SEM_MORA

func hay_veedor() -> bool:
	return semanas_en_rojo >= SEM_VEEDOR

## En qué estado está el club. Devuelve {estado, color, texto}.
func estado(c: Club) -> Dictionary:
	if c.saldo >= 0:
		return {"estado": "AL DÍA", "color": "verde",
			"texto": "La caja en azul. Los bancos te sonríen."}
	if semanas_en_rojo < SEM_MORA:
		return {"estado": "SOBREGIRO", "color": "ambar",
			"texto": "Caja en rojo: pagas un 1,5% semanal de intereses. Sanea antes de la cuarta semana o caes en mora."}
	if semanas_en_rojo < SEM_VEEDOR:
		return {"estado": "EN MORA", "color": "rojo",
			"texto": "Fichajes inhibidos y confianza cayendo. A la octava semana la asociación designa un veedor concursal."}
	return {"estado": "VEEDOR EN FUNCIONES", "color": "rojo",
		"texto": "Un veedor supervisa la caja. A las %d semanas en rojo, el proyecto se liquida y te vas." %
			(SEM_LIQUIDACION + gracia_liquidacion)}

## Pedir un crédito. Devuelve "" si se hizo, o el motivo por el que no.
func pedir(i: int, c: Club) -> String:
	if prestamos.size() >= MAX_PRESTAMOS:
		return "ya tienes dos líneas de deuda abiertas"
	if en_mora():
		return "en mora no hay ventanilla: ningún banco te abre una línea nueva"
	if i < 0 or i >= BANCOS.size():
		return "esa línea no existe"
	var b: Array = BANCOS[i]
	var monto := monto_linea(i, c)
	var tasa := float(b[1])
	var cuotas := int(b[2])
	prestamos.append({
		"banco": String(b[0]), "deuda": monto, "tasa": tasa,
		"cuota": cuota_francesa(monto, tasa, cuotas), "restan": cuotas,
		"renegociado": false, "bono": false,
	})
	c.mover_saldo(monto)
	movimiento.emit("Crédito de %s" % String(b[0]), monto)
	aviso.emit("Crédito concedido",
		"%s ingresa %s. La cuota se descuenta sola cada semana, llueva o truene." % [String(b[0]), Cesiones.dinero(monto)])
	return ""

## El bono social. Se puede emitir INCLUSO en mora: es el único salvavidas que
## queda cuando los bancos ya cerraron la puerta, y por eso lo paga la gente.
func emitir_bono(c: Club) -> String:
	if prestamos.size() >= MAX_PRESTAMOS:
		return "sin cupo: ya tienes dos líneas de deuda"
	for p: Dictionary in prestamos:
		if bool(p.get("bono", false)):
			return "ya hay un bono social vigente"
	var monto := Eco.escalar(900000.0, float(c.rep))
	prestamos.append({
		"banco": "Bono social de la hinchada", "deuda": monto, "tasa": TASA_BONO,
		"cuota": cuota_francesa(monto, TASA_BONO, CUOTAS_BONO), "restan": CUOTAS_BONO,
		"renegociado": false, "bono": true,
	})
	c.mover_saldo(monto)
	movimiento.emit("Bono social de la hinchada", monto)
	aviso.emit("La hinchada pone el dinero",
		"Se emite un bono social por %s. Lo compra la gente, a tasa baja. Que no se te olvide quién te sacó del pozo." % Cesiones.dinero(monto))
	return ""

## Cancelar de golpe. Ahorra todos los intereses que quedaban.
func prepagar(i: int, c: Club) -> String:
	if i < 0 or i >= prestamos.size():
		return "ese crédito no existe"
	var p: Dictionary = prestamos[i]
	var deuda := int(p["deuda"])
	if c.saldo < deuda:
		return "prepagar cuesta %s y no hay caja" % Cesiones.dinero(deuda)
	c.mover_saldo(-deuda)
	movimiento.emit("Prepago de %s" % String(p["banco"]), -deuda)
	prestamos.remove_at(i)
	return ""

## Renegociar: baja la cuota alargando el plazo, y sube la tasa. Una sola vez
## por crédito. Es el clásico: alivia hoy y cuesta más al final.
func renegociar(i: int) -> String:
	if i < 0 or i >= prestamos.size():
		return "ese crédito no existe"
	var p: Dictionary = prestamos[i]
	if bool(p["renegociado"]):
		return "ese crédito ya se renegoció una vez"
	p["tasa"] = float(p["tasa"]) * 1.35
	p["restan"] = int(round(float(p["restan"]) * 1.6))
	p["cuota"] = cuota_francesa(int(p["deuda"]), float(p["tasa"]), int(p["restan"]))
	p["renegociado"] = true
	return ""

## El pulso semanal: cobrar cuotas, aplicar el sobregiro y contar las semanas en
## rojo. Es donde el reloj corre.
func semana(c: Club) -> void:
	if c == null or liquidado_ya:
		return
	for i in range(prestamos.size() - 1, -1, -1):
		var p: Dictionary = prestamos[i]
		var interes := int(round(float(p["deuda"]) * float(p["tasa"])))
		var cuota: int = mini(int(p["cuota"]), int(p["deuda"]) + interes)
		c.mover_saldo(-cuota)
		movimiento.emit("Cuota de %s" % String(p["banco"]), -cuota)
		p["deuda"] = maxi(0, int(p["deuda"]) + interes - cuota)
		p["restan"] = int(p["restan"]) - 1
		if int(p["deuda"]) <= 0 or int(p["restan"]) <= 0:
			aviso.emit("Crédito saldado", "Terminas de pagar a %s." % String(p["banco"]))
			prestamos.remove_at(i)

	if c.saldo < 0:
		var recargo := int(round(float(-c.saldo) * INTERES_SOBREGIRO * descuento_sobregiro))
		if recargo > 0:
			c.mover_saldo(-recargo)
			movimiento.emit("Intereses de sobregiro", -recargo)
		semanas_en_rojo += 1
		_avisar_escalon(c)
	else:
		if semanas_en_rojo > 0:
			aviso.emit("Cuentas saneadas", "La caja vuelve al azul y el contador de semanas en rojo se pone a cero.")
		semanas_en_rojo = 0

## Los avisos de cada escalón. Se avisa EN el umbral y no antes: un aviso cada
## semana se convierte en ruido y se deja de leer.
func _avisar_escalon(c: Club) -> void:
	## `SEM_LIQUIDACION + gracia_liquidacion` no es una constante -depende del
	## Consejero legal-, y `match` en GDScript exige patrones constantes: con
	## eso como caso de un `match` ni siquiera compila ("Expression in match
	## pattern must be a constant"). Por eso este umbral se comprueba aparte,
	## con un `if`, y los otros dos -que sí son constantes de verdad- se
	## quedan en el `match`.
	match semanas_en_rojo:
		SEM_MORA:
			aviso.emit("El club entra en mora",
				"Cuatro semanas en rojo. Los fichajes quedan inhibidos y la confianza del directorio se resiente.")
		SEM_VEEDOR:
			aviso.emit("La asociación designa un veedor",
				"Ocho semanas en rojo. Un veedor concursal supervisa la caja del club. Quedan cuatro semanas para enderezarlo.")
	## `gracia_liquidacion` (el Consejero legal) mueve SOLO este umbral, no
	## los dos de arriba: lo que negocia es tiempo antes del cierre
	## definitivo, no que la mora deje de doler antes.
	if semanas_en_rojo == SEM_LIQUIDACION + gracia_liquidacion:
		liquidado_ya = true
		aviso.emit("El proyecto se liquida",
			"%d semanas con la caja en rojo. La asociación liquida el club y tu etapa aquí se acaba." %
				(SEM_LIQUIDACION + gracia_liquidacion))
		liquidado.emit()

func a_dic() -> Dictionary:
	return {"prestamos": prestamos.duplicate(true), "rojo": semanas_en_rojo, "liquidado": liquidado_ya}

func desde_dic(d: Dictionary) -> void:
	prestamos = (d.get("prestamos", []) as Array).duplicate(true)
	semanas_en_rojo = int(d.get("rojo", 0))
	liquidado_ya = bool(d.get("liquidado", false))
