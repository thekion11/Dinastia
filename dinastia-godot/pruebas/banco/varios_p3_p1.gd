extends "res://pruebas/banco/varios_p2.gd"
## [Capa 3b de `varios.gd`, entre la 3 y la 2] _estadio_tramos: tramos del estadio propio.

## TRAMO: mismo criterio que Bandeja, con los tercios en blanco heredando el patrón de su tribuna.
func _estadio_tramos(m: Mundo, p: Dictionary, mio: Club, rival: Club) -> void:
	## TRAMO (22-9-2026, Fase 3 de "el estadio por MODULOS", ultima de las
	## tres): mismo criterio que Bandeja -apagado no cambia una clave,
	## prendido solo cambia lo que se reformo-, mas la resolucion de los
	## tercios en blanco. Con `personalizar_bandejas` YA prendido (bloque de
	## arriba) para probar de paso que las dos fases conviven: la tribuna sur
	## tiene ahora un `bandeja_sur_asientoP` propio ("damero"), asi que sus
	## tercios en blanco tienen que heredar ESE valor, no el global.
	_comprobar(not p.has("tramos"), "sin personalizar_tramos, el perfil no trae la clave tramos")
	_comprobar(m.estadio.reformar(mio, {"personalizar_tramos": true}, m.obras) == "",
		"se puede activar mezclar patrones por tercios")
	_comprobar(m.estadio.reformar(mio, {"tramo_sur_2": "moteado"}, m.obras) == "",
		"se puede reformar solo el tercio 2 de la tribuna sur")
	m.estadio.terminar_obra()
	var p3 := m.perfil_estadio_de(mio)
	_comprobar(p3.has("tramos"), "con el interruptor activo, el perfil SI trae tramos")
	var tramos: Dictionary = p3.get("tramos", {})
	var tramos_sur: Array = tramos.get("sur", [])
	_comprobar(tramos_sur.size() == 3, "la tribuna sur trae sus 3 tercios (dio %d)" % tramos_sur.size())
	_comprobar(String(tramos_sur[0]) == "damero" and String(tramos_sur[2]) == "damero",
		"los tercios 1 y 3 en blanco heredan 'damero' -el de Bandeja, no el global- (dio %s y %s)" % [
			tramos_sur[0] if tramos_sur.size() > 0 else "?", tramos_sur[2] if tramos_sur.size() > 2 else "?"])
	_comprobar(String(tramos_sur[1]) == "moteado", "el tercio 2 quedo con el patron reformado")
	for lado in ["norte", "este", "oeste"]:
		var t_lado: Array = tramos.get(lado, [])
		_comprobar(t_lado.size() == 3 and t_lado[0] == t_lado[1] and t_lado[1] == t_lado[2]
			and String(t_lado[0]) == String(p3.get("asientoP", "")),
			"la tribuna %s (sin tercios propios) sale con sus 3 tercios iguales al patron global" % lado)
	## El rival nunca disenio nada: nunca trae ni bandejas ni tramos.
	_comprobar(not m.perfil_estadio_de(rival).has("tramos"), "el rival nunca trae la clave tramos")
