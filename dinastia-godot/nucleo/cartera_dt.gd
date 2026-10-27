class_name CarteraDT
extends RefCounted
## LA CARTERA DEL DT (27-10-2026, pieza A de `PLAN_DEL_LUNES.md` §2.2h; OK del líder: el dinero de la ciudad sale del BOLSILLO DEL DT, no del club).
## La CUENTA es `Roles.patrimonio` (todo lo que ya cobra y gasta el DT sigue funcionando); aquí se suma el EFECTIVO en el bolsillo, la TARJETA de
## débito (PIN de 4 cifras, límite diario, bloqueo tras tres PIN erróneos) y los últimos movimientos. Todo en euros y ficticio.
## UNIDADES: la cartera habla en EUROS de pantalla; `Roles.patrimonio` va en puntos internos (1 punto = `Eco.ECO` = 12 EUR). `cargo_pend` (0..11 €) guarda lo
## ya gastado del punto en curso, así cada euro cuenta sin tocar la economía del resto del juego.
## Los métodos devuelven "" si salió bien o un CÓDIGO de error ("bloqueada", "pin", "limite", "saldo", "importe"); la pantalla lo traduce con `Idiomas.t`.
const LIMITE_TARJETA := 600      ## € al día con tarjeta
const LIMITE_CAJERO := 500       ## € al día retirados en cajero
const SIN_PIN := 100             ## € hasta los que la tarjeta paga sin PIN (sin contacto)
const MAX_MOV := 30
const MAX_FALLOS := 3

var efectivo: int = 0
var cargo_pend: int = 0          ## € ya gastados del punto interno en curso (0..11)
var pin: String = "0000"
var pin_inicial: bool = true     ## sigue el PIN de fábrica: el cajero avisa de cambiarlo
var bloqueada: bool = false
var fallos_pin: int = 0
var dia_gasto: int = -1
var gastado_dia: int = 0
var retirado_dia: int = 0
var movimientos: Array = []      ## {"dia", "concepto", "importe", "via"}; importe negativo = sale dinero

static func unidad() -> int:
	return int(Eco.ECO)

## Euros que hay en la cuenta (el patrimonio en euros menos lo ya gastado del punto en curso).
func cuenta_eur(roles: Roles) -> int:
	return roles.patrimonio * unidad() - cargo_pend

## Dinero total del DT en euros: bolsillo + cuenta.
func total(roles: Roles) -> int:
	return efectivo + cuenta_eur(roles)

func _debitar(roles: Roles, eur: int) -> void:
	cargo_pend += eur
	var u := unidad()
	roles.patrimonio -= cargo_pend / u
	cargo_pend = cargo_pend % u

func _abonar(roles: Roles, eur: int) -> void:
	cargo_pend -= eur
	var u := unidad()
	while cargo_pend < 0:
		cargo_pend += u
		roles.patrimonio += 1

func _dia(dia: int) -> void:
	if dia != dia_gasto:
		dia_gasto = dia
		gastado_dia = 0
		retirado_dia = 0

func _apunta(dia: int, concepto: String, importe: int, via: String) -> void:
	movimientos.append({"dia": dia, "concepto": concepto, "importe": importe, "via": via})
	while movimientos.size() > MAX_MOV:
		movimientos.pop_front()

func pagar_efectivo(importe: int, concepto: String, dia: int) -> String:
	if importe <= 0:
		return "importe"
	if efectivo < importe:
		return "saldo"
	efectivo -= importe
	_apunta(dia, concepto, -importe, "efectivo")
	return ""

func pagar_tarjeta(roles: Roles, importe: int, concepto: String, pin_dado: String, dia: int) -> String:
	if importe <= 0:
		return "importe"
	if bloqueada:
		return "bloqueada"
	if pin_dado != pin:
		fallos_pin += 1
		if fallos_pin >= MAX_FALLOS:
			bloqueada = true
			return "bloqueada"
		return "pin"
	fallos_pin = 0
	return _cargo_tarjeta(roles, importe, concepto, dia)

## El cargo en sí (ya validado el PIN o el sin contacto): límite diario y saldo de la cuenta.
func _cargo_tarjeta(roles: Roles, importe: int, concepto: String, dia: int, simular := false) -> String:
	_dia(dia)
	if gastado_dia + importe > LIMITE_TARJETA:
		return "limite"
	if cuenta_eur(roles) < importe:
		return "saldo"
	if simular:
		return ""
	_debitar(roles, importe)
	gastado_dia += importe
	_apunta(dia, concepto, -importe, "tarjeta")
	return ""

## ¿Se podría cobrar `importe` (efectivo y, si no, tarjeta sin contacto)? "" = sí; si no, el código del motivo. No toca nada.
func puede_cobrar(roles: Roles, importe: int, dia: int) -> String:
	if importe <= 0:
		return "importe"
	if efectivo >= importe:
		return ""
	if bloqueada:
		return "bloqueada"
	if importe > SIN_PIN:
		return "pin"
	return _cargo_tarjeta(roles, importe, "", dia, true)

## Cobra en el comercio sin pantalla de PIN: primero el efectivo del bolsillo y, si no alcanza, la tarjeta sin contacto (hasta `SIN_PIN` €).
## Devuelve {"error": "" o código, "via": "efectivo" | "tarjeta"}.
func cobrar(roles: Roles, importe: int, concepto: String, dia: int) -> Dictionary:
	var motivo := puede_cobrar(roles, importe, dia)
	if motivo != "":
		return {"error": motivo, "via": ""}
	if efectivo >= importe:
		pagar_efectivo(importe, concepto, dia)
		return {"error": "", "via": "efectivo"}
	_cargo_tarjeta(roles, importe, concepto, dia)
	return {"error": "", "via": "tarjeta"}

## Cajero: pasa dinero de la cuenta al bolsillo (con comisión si el cajero es de otro banco).
func retirar(roles: Roles, importe: int, pin_dado: String, dia: int, comision := 0) -> String:
	if importe <= 0:
		return "importe"
	if bloqueada:
		return "bloqueada"
	if pin_dado != pin:
		fallos_pin += 1
		if fallos_pin >= MAX_FALLOS:
			bloqueada = true
			return "bloqueada"
		return "pin"
	_dia(dia)
	if retirado_dia + importe > LIMITE_CAJERO:
		return "limite"
	if cuenta_eur(roles) < importe + comision:
		return "saldo"
	fallos_pin = 0
	_debitar(roles, importe + comision)
	efectivo += importe
	retirado_dia += importe
	_apunta(dia, "Cajero", -importe - comision, "cajero")
	return ""

## Cajero: ingresa efectivo en la cuenta (sin límite, sin comisión).
func ingresar(roles: Roles, importe: int, dia: int) -> String:
	if importe <= 0:
		return "importe"
	if efectivo < importe:
		return "saldo"
	efectivo -= importe
	_abonar(roles, importe)
	_apunta(dia, "Ingreso", importe, "cajero")
	return ""

## Comprueba un PIN tecleado en un cajero: "" bien, "pin" mal (cuenta el fallo), "bloqueada" si ya estaba o se bloquea ahora.
func comprobar_pin(pin_dado: String) -> String:
	if bloqueada:
		return "bloqueada"
	if pin_dado == pin:
		fallos_pin = 0
		return ""
	fallos_pin += 1
	if fallos_pin >= MAX_FALLOS:
		bloqueada = true
		return "bloqueada"
	return "pin"

func intentos_restantes() -> int:
	return maxi(0, MAX_FALLOS - fallos_pin)

func cambiar_pin(viejo: String, nuevo: String) -> String:
	if bloqueada:
		return "bloqueada"
	if viejo != pin:
		return "pin"
	if nuevo.length() != 4 or not nuevo.is_valid_int():
		return "importe"
	pin = nuevo
	pin_inicial = false
	fallos_pin = 0
	return ""

## En la ventanilla el banco te identifica: pone un PIN nuevo de 4 cifras sin pedir el actual y quita el bloqueo.
func restablecer_pin(nuevo: String) -> String:
	if nuevo.length() != 4 or not nuevo.is_valid_int():
		return "importe"
	pin = nuevo
	pin_inicial = false
	desbloquear()
	return ""

## El banco la desbloquea (una llamada, sin coste): vuelve a contar los fallos.
func desbloquear() -> void:
	bloqueada = false
	fallos_pin = 0

func a_dict() -> Dictionary:
	return {"efectivo": efectivo, "cargo": cargo_pend, "pin": pin, "pin_inicial": pin_inicial, "bloqueada": bloqueada, "fallos": fallos_pin,
		"dia": dia_gasto, "gastado": gastado_dia, "retirado": retirado_dia, "mov": movimientos.duplicate(true)}

## Partida vieja (diccionario vacío): efectivo 0 y PIN de fábrica.
func desde_dict(d: Dictionary) -> void:
	efectivo = int(d.get("efectivo", 0))
	cargo_pend = int(d.get("cargo", 0))
	pin = String(d.get("pin", "0000"))
	pin_inicial = bool(d.get("pin_inicial", true))
	bloqueada = bool(d.get("bloqueada", false))
	fallos_pin = int(d.get("fallos", 0))
	dia_gasto = int(d.get("dia", -1))
	gastado_dia = int(d.get("gastado", 0))
	retirado_dia = int(d.get("retirado", 0))
	movimientos = (d.get("mov", []) as Array).duplicate(true)

## Clave de día para los límites diarios.
static func clave_dia(anio: int, semana: int, dia: int) -> int:
	return anio * 1000 + semana * 10 + dia

## Texto (ya traducido) de un código de error, para el cuadro del comercio.
static func texto_error(codigo: String, importe: int) -> String:
	match codigo:
		"bloqueada":
			return Idiomas.t("Tarjeta bloqueada: pasa por el banco para desbloquearla.")
		"pin":
			return Idiomas.t("Son %d €: a partir de 100 € la tarjeta pide el PIN. Saca efectivo en un cajero.") % importe
		"limite":
			return Idiomas.t("La tarjeta ha llegado al límite de gasto de hoy.")
	return Idiomas.t("No te llega el dinero: son %d € y no tienes efectivo ni saldo en la tarjeta.") % importe
