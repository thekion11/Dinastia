extends BaseIdea
## PAÍSES BAJOS DE VERDAD (01-11-2026, orden del dueño «clubes»: recrear de forma legal los clubes de League-Soccer). La liga
## inventada de `paises_extra.json` pasa a salir del pack real (`herramientas/liga_paises_bajos.py`): en la base ficticia los
## clubes llevan los nombres de siempre y jugadores con guiño; con el pack, los reales (Ajax, PSV…) y sus plantillas.

func _probar() -> void:
	_titulo("PAÍSES BAJOS: LIGA REAL Y FICTICIA")
	for real: bool in [false, true]:
		Datos.usar_base_real(real)
		var m := Mundo.new()
		m.generar(["NED"], 1234)
		var liga: Liga = null
		for l: Liga in m.ligas:
			if l.pais == "NED" and l.div == 1:   ## (10-11) desde las segundas divisiones hay otra liga NED (20 clubes, con el Jong): se mide la primera
				liga = l
		_comprobar(liga != null and liga.clubes.size() == 18, "%s: liga con 18 clubes (%d)" % ["real" if real else "ficticia", liga.clubes.size() if liga else 0])
		if liga == null:
			continue
		var grande: Club = liga.clubes[0]
		for c: Club in liga.clubes:
			if Nombres.limpiar(c.nombre) == ("Ajax" if real else "Amstel FC"):
				grande = c
		var reales := grande.plantilla.filter(func(j: Jugador) -> bool: return j.real)
		_comprobar(Nombres.limpiar(grande.nombre) == ("Ajax" if real else "Amstel FC") and reales.size() >= 12, "%s: %s con %d jugadores fijos" % ["real" if real else "ficticia", grande.nombre, reales.size()])
		var nombres := reales.map(func(j: Jugador) -> String: return Nombres.limpiar(j.nombre))
		_comprobar(nombres.has("Kenneth Taylor") == real, "%s: el nombre real solo sale con el pack (%s)" % ["real" if real else "ficticia", str(nombres.slice(0, 3))])
	Datos.usar_base_real(false)
