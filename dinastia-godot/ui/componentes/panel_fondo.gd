class_name PanelFondo
extends RefCounted
## EL FONDO DE INVERSIÓN, EN MI CARRERA (26-9-2026): caja, valor, rentabilidad,
## lo que tienes (con vender) y los clubes que se pueden comprar (con comprar
## 10 % o 25 %).

static func pintar(lista: VBoxContainer, m: Mundo, al_cambiar: Callable) -> void:
	var f := m.fondo
	if f == null:
		return
	lista.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.ORO, "💼 TU FONDO DE INVERSIÓN"))
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Tema.TARJETA, Tema.RADIO, Tema.ORO))
	lista.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	caja.add_child(v)
	var rent := f.rentabilidad(m)
	v.add_child(Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, "Valor del fondo: %s" % Cesiones.dinero(f.valor_total(m))))
	v.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, "Caja: %s  ·  En clubes: %s  ·  Dividendos cobrados: %s" % [
		Cesiones.dinero(f.caja), Cesiones.dinero(f.valor_cartera(m)), Cesiones.dinero(f.dividendos_totales)]))
	v.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.BIEN if rent >= 0.0 else Color("e57373"), "Rentabilidad: %+.1f %%" % rent))
	var aviso := Tema.etiqueta(Tema.TAM_ROTULO, Tema.ORO, "")
	v.add_child(aviso)

	## Lo que tienes.
	if not f.cartera.is_empty():
		v.add_child(Tema.rotulo("Tus participaciones"))
		for cid: String in f.cartera:
			var c: Club = m.clubes.get(cid)
			if c == null:
				continue
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 8)
			v.add_child(fila)
			var et := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, "%s · %d %% · vale %s" % [c.nombre, int(round(float(f.cartera[cid]) * 100.0)),
				Cesiones.dinero(int(round(float(FondoInversion.valor_club(c)) * float(f.cartera[cid]))))])
			et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila.add_child(et)
			var bv := Button.new()
			bv.text = "Vender todo"
			bv.pressed.connect(func() -> void:
				var r := f.vender(m, c, 1.0)
				aviso.text = r
				if r == "":
					al_cambiar.call())
			fila.add_child(bv)

	## Dónde invertir: los clubes con más reputación del mundo que no son tuyos.
	v.add_child(Tema.rotulo("Dónde invertir"))
	var todos: Array = m.clubes.values().filter(func(c: Club) -> bool: return c.id != m.mi_club_id)
	todos.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
	for c2: Club in todos.slice(0, 14):
		var fila2 := HBoxContainer.new()
		fila2.add_theme_constant_override("separation", 8)
		v.add_child(fila2)
		var et2 := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, "%s (%s, rep. %d) · el club vale %s" % [c2.nombre, c2.pais, c2.rep, Cesiones.dinero(FondoInversion.valor_club(c2))])
		et2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		et2.clip_text = true
		fila2.add_child(et2)
		for pct: float in [0.1, 0.25]:
			var b := Button.new()
			b.text = "+%d %%" % int(pct * 100.0)
			b.pressed.connect(func() -> void:
				var r2 := f.comprar(m, c2, pct)
				aviso.text = r2
				if r2 == "":
					al_cambiar.call())
			fila2.add_child(b)
