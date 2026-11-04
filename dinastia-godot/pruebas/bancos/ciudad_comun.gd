extends RefCounted
## Lo común de los tres bancos de la ciudad (construcción, vida, transporte): abrir la ciudad entera como la abre el juego (`VistaCiudad`),
## esperar a que lo diferido termine (`completa`) y a que el árbol se quede quieto, y entregar el constructor.

## Devuelve {"vc": VistaCiudad, "cb": CityBuilder, "m": Mundo}. `semilla` y `calidad` fijan el mundo y la calidad; `Azar` se siembra igual que en las pruebas por partes.
static func abrir(dueno: Node, semilla := 777, calidad := Calidad.MEDIO) -> Dictionary:
	Calidad.elegida = calidad
	Partido.limpiar_contexto()
	var m := Mundo.new()
	var paises: Array[String] = ["CHI"]
	m.generar(paises, semilla)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	Azar.sembrar(4242)
	var vc := VistaCiudad.new()
	dueno.add_child(vc)
	await vc.abrir(c, m.obras, m.ciudad, m.perfil_estadio_de(c))
	var cb: Node = vc.get("_ciudad")
	for i in 6000:
		if bool(cb.get("completa")):
			break
		await dueno.get_tree().process_frame
	var antes := -1
	var quietos := 0
	for i in 240:
		await dueno.get_tree().process_frame
		var ahora := vc.find_children("*", "", true, false).size()
		quietos = quietos + 1 if ahora == antes else 0
		antes = ahora
		if quietos >= 8:
			break
	return {"vc": vc, "cb": cb, "m": m}
