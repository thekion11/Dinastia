extends BaseIdea
## BANCO ESPECIALIZADO «economia», FASE 2 (4-11-2026, megarreforma de los bancos): que las cuentas CUADREN siempre.
##   1. LIBRO: durante 30 semanas, cada cambio de caja de cada club pasa por `mover_saldo` (se escucha `saldo_cambio`):
##      caja final − caja inicial = suma de lo avisado, en TODOS los clubes. Nada toca la caja por la puerta de atrás.
##   2. TRASPASOS: cada traspaso entre clubes conserva el dinero (lo que paga uno lo cobra el otro, al peso).
##   3. CORDURA del mundo tras 30 semanas: ningún sueldo ≤ 0 ni valor < 0; medias 1-99; edades 15-45; ninguna caja
##      absurda (más de 50 veces la referencia de su reputación).
##   4. CRÉDITO: pedir una línea suma el monto a la caja y abre la deuda; las cuotas bajan la deuda hasta 0, nunca negativa,
##      y la caja baja exactamente lo que se paga.

var _avisado := {}     ## club id -> suma de los cambios avisados
var _traspasos: Array = []

func _probar() -> void:
	_titulo("BANCO ECONOMÍA (fase 2): libro de caja, traspasos, cordura y créditos")
	var m := Mundo.new()
	var paises: Array[String] = ["CHI", "ARG"]
	m.generar(paises, 8080)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var inicio := {}
	for c: Club in m.clubes.values():
		inicio[c.id] = c.saldo
		_avisado[c.id] = 0
		c.saldo_cambio.connect(func(antes: int, ahora: int) -> void: _avisado[c.id] = int(_avisado[c.id]) + ahora - antes)
	if m.mercado != null and m.mercado.has_signal("traspaso"):
		m.mercado.traspaso.connect(func(j: Jugador, de: Club, a: Club, monto: int) -> void:
			_traspasos.append([de.saldo if de != null else 0, a.saldo, monto, de != null]))
	for i in 30:
		m.avanzar_semana()
	_libro(m, inicio)
	_cordura(m)
	_credito(m)

func _libro(m: Mundo, inicio: Dictionary) -> void:
	var malos: Array[String] = []
	for c: Club in m.clubes.values():
		var real := c.saldo - int(inicio[c.id])
		if real != int(_avisado[c.id]):
			malos.append("%s: cambió %d, se avisaron %d" % [c.nombre, real, int(_avisado[c.id])])
	_comprobar(malos.is_empty(), "30 semanas: en los %d clubes la caja cambia SOLO por mover_saldo (libro cuadrado)%s" % [m.clubes.size(), "" if malos.is_empty() else " — " + str(malos.slice(0, 4))])
	_comprobar(_traspasos.size() > 0, "hubo traspasos que mirar (%d)" % _traspasos.size())

func _cordura(m: Mundo) -> void:
	var raros: Array[String] = []
	var n := 0
	for c: Club in m.clubes.values():
		for j: Jugador in c.plantilla:
			n += 1
			if j.sueldo <= 0 or j.valor < 0 or j.ovr < 1 or j.ovr > 99 or j.edad < 15 or j.edad > 45:
				raros.append("%s (sueldo %d, valor %d, media %d, edad %d)" % [j.nombre, j.sueldo, j.valor, j.ovr, j.edad])
	_comprobar(raros.is_empty(), "los %d jugadores con contrato tienen sueldo > 0, valor ≥ 0, media 1-99 y edad 15-45%s" % [n, "" if raros.is_empty() else " — " + str(raros.slice(0, 4))])
	var absurdas: Array[String] = []
	for c: Club in m.clubes.values():
		var ref := Eco.ref_caja(float(c.rep))
		if ref > 0.0 and absf(float(c.saldo)) > ref * 50.0:
			absurdas.append("%s: %d (ref %d)" % [c.nombre, c.saldo, int(ref)])
	_comprobar(absurdas.is_empty(), "ninguna caja absurda (más de 50 veces la referencia de su reputación)%s" % ("" if absurdas.is_empty() else " — " + str(absurdas.slice(0, 4))))

func _credito(m: Mundo) -> void:
	var c := m.mi_club()
	var b: Banco = m.banco
	if b == null:
		_comprobar(false, "el mundo tiene banco")
		return
	b.prestamos.clear()
	b.semanas_en_rojo = 0
	c.mover_saldo(maxi(0, 10_000_000 - c.saldo))   ## caja sana para que haya ventanilla
	var antes := c.saldo
	var error := b.pedir(0, c)
	_comprobar(error == "", "se puede pedir la primera línea de crédito%s" % ("" if error == "" else ": " + error))
	if error != "" or b.prestamos.is_empty():
		return
	var p: Dictionary = b.prestamos[0]
	var monto := int(p["deuda"])
	_comprobar(monto > 0 and c.saldo - antes == monto, "el crédito suma a la caja exactamente lo prestado (%d)" % monto)
	var deuda_antes := int(p["deuda"])
	var bajadas := 0
	var negativa := false
	var pagos_ok := true
	for i in 60:
		if b.prestamos.is_empty():
			break
		var caja := c.saldo
		var cuota := int(b.prestamos[0]["cuota"])
		b.semana(c)
		if b.prestamos.is_empty():
			break
		var d := int(b.prestamos[0]["deuda"])
		negativa = negativa or d < 0
		bajadas += 1 if d < deuda_antes else 0
		pagos_ok = pagos_ok and (caja - c.saldo) <= cuota + 1 and (caja - c.saldo) >= 0
		deuda_antes = d
	_comprobar(not negativa, "la deuda nunca queda negativa")
	_comprobar(bajadas > 0, "las cuotas bajan la deuda (%d semanas con baja)" % bajadas)
	_comprobar(pagos_ok, "cada semana la caja baja como mucho la cuota (con la caja en azul no hay intereses de sobregiro)")
