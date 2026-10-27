extends BaseIdea
## EL DESAFÍO «SIN DINERO» (27-10-2026, fila 951): promete «sin créditos bancarios» y `Banco.pedir` no lo comprobaba.

func _probar() -> void:
	_titulo("DESAFÍOS · SIN DINERO: SIN CRÉDITOS BANCARIOS")
	var m := Mundo.new()
	m.generar(["CHI"], 41)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	var saldo := c.saldo
	_comprobar(m.banco.pedir(0, c) == "" and c.saldo > saldo, "sin el desafío, el banco abre la línea")
	var m2 := Mundo.new()
	m2.generar(["CHI"], 41)
	m2.tomar_el_mando(m2.ligas[0].clubes[0].id)
	m2.desafios.append("pobreza")
	m2.aplicar_desafios()
	var c2 := m2.mi_club()
	var antes := c2.saldo
	var r := m2.banco.pedir(0, c2)
	_comprobar(r != "" and m2.banco.prestamos.is_empty() and c2.saldo == antes, "con «Sin dinero» ninguna línea se abre (%s)" % r)
	_comprobar(m2.banco.pedir(2, c2) != "", "ni la más grande")
	_comprobar(m2.banco.emitir_bono(c2) == "", "pero el bono social (la hinchada, no un banco) sigue disponible")
	## Cargar la partida no lo pierde.
	var m3 := Partida.desde_instantanea(Partida.instantanea(m2))
	_comprobar(m3.tiene_desafio("pobreza") and m3.banco.pedir(1, m3.mi_club()) != "", "tras guardar y cargar sigue sin créditos")
