extends "res://pruebas/banco/base.gd"
## [Capa de `varios_p1.gd`, 21-11 refactor de forma] Secciones de «BASE FICTICIA»: el estado
## compartido va en las variables `_bf_*` (el orden de las comprobaciones y los textos son los de antes).

var _bf_reales_clubes := {}
var _bf_filas_reales: Array = []
var _bf_ligas_reales := {}
var _bf_copas_reales := {}
var _bf_arbitros_reales := {}
var _bf_jugadores_reales := {}
var _bf_filas_fic: Array = []
var _bf_m: Mundo


## Los nombres reales, sacados del pack, antes de quitarlo.
func _bf_leer_pack() -> void:
	_bf_reales_clubes = {}
	_bf_filas_reales = []
	for t in ["DATA_P1", "DATA_P2"]:
		for fila: Array in Datos.tabla(t):
			_bf_reales_clubes[Nombres.limpiar(String(fila[0])).to_lower()] = true
			_bf_filas_reales.append(fila)
	_bf_ligas_reales = {}
	var pl_real: Dictionary = Datos.tabla("PAISES_LIGAS")
	## Los países de `paises_extra.json` son ficticios en los dos modos (el pack no
	## los trae): sus clubes no cuentan como reales, pero no pueden pisar al pack.
	var extra: Dictionary = Datos.paises_extra().get("paises", {})
	var pack_pl: Dictionary = Datos._pack.get("PAISES_LIGAS", {})
	var pisados: Array = []
	for pais: String in pl_real:
		var de_extra := extra.has(pais) and not pack_pl.has(pais)
		if pack_pl.has(pais) and pl_real[pais] != pack_pl[pais]:
			pisados.append(pais)
		if not de_extra:
			_bf_ligas_reales[String(pl_real[pais].get("liga", ""))] = true
		for fila: Array in (pl_real[pais]["clubes"] as Array) + (pl_real[pais].get("segunda", {}).get("clubes", []) as Array):   ## (10-11) y su segunda división
			if not de_extra:
				_bf_reales_clubes[Nombres.limpiar(String(fila[0])).to_lower()] = true
			_bf_filas_reales.append(fila)
	_comprobar(pisados.is_empty(), "con el pack, los países extra no pisan ninguna liga real %s" % str(pisados))
	_bf_copas_reales = {}
	for k: String in (Datos.tabla("CONFED") as Dictionary):
		_bf_copas_reales[Nombres.limpiar(String(Datos.tabla("CONFED")[k]["n"]))] = true
	_bf_arbitros_reales = {}
	for fila: Array in Datos.tabla("ARBITROS"):
		_bf_arbitros_reales[Nombres.limpiar(String(fila[0]))] = true
	_bf_jugadores_reales = {}
	for club: String in (Datos.tabla("REALES") as Dictionary):
		for fila: Variant in Datos.tabla("REALES")[club]:
			_bf_jugadores_reales[String(fila).split("|")[0]] = true
	_linea("  el pack trae %d clubes y %d jugadores reales" % [_bf_reales_clubes.size(), _bf_jugadores_reales.size()])


## El pack se quita: la base ficticia no trae nombres reales ni guiños con nombre real.
func _bf_quitar_pack() -> void:
	var quedo := Datos.usar_base_real(false)
	_comprobar(not quedo and not Datos.base_real, "se puede quitar el pack")
	## Desde el 26-9-2026 la base SÍ trae plantillas, pero con nombres de guiño
	## (`herramientas/jugadores_guino.py`): ninguno puede ser un nombre real.
	var guinos_reales: Array = []
	var n_guinos := 0
	for club_f: String in (Datos.tabla("REALES") as Dictionary):
		for fila_f: Variant in Datos.tabla("REALES")[club_f]:
			n_guinos += 1
			var nf := String(fila_f).split("|")[0]
			if _bf_jugadores_reales.has(nf) or Nombres.vetado(nf):
				guinos_reales.append(nf)
	_comprobar(n_guinos > 0 and guinos_reales.is_empty(), "la base trae %d jugadores con guiño y ninguno con nombre real %s" % [n_guinos, str(guinos_reales.slice(0, 5))])
	_comprobar((Datos.tabla("EQUIP_REAL") as Dictionary).is_empty(), "ni fotos de equipaciones reales")


## Misma forma: fila a fila, todo igual salvo el nombre.
func _bf_misma_forma() -> void:
	_bf_filas_fic = []
	for t in ["DATA_P1", "DATA_P2"]:
		_bf_filas_fic.append_array(Datos.tabla(t))
	var pl_fic: Dictionary = Datos.tabla("PAISES_LIGAS")
	for pais: String in pl_fic:
		_bf_filas_fic.append_array(pl_fic[pais]["clubes"])
		_bf_filas_fic.append_array(pl_fic[pais].get("segunda", {}).get("clubes", []))   ## (10-11) y su segunda división
	var misma_forma := _bf_filas_fic.size() == _bf_filas_reales.size()
	if misma_forma:
		for i in _bf_filas_fic.size():
			if (_bf_filas_fic[i] as Array).slice(1) != (_bf_filas_reales[i] as Array).slice(1):
				misma_forma = false
				break
	_comprobar(misma_forma, "mismos %d clubes, en el mismo orden y con los mismos colores, reputación y aforo" % _bf_filas_fic.size())


## Ningún nombre real en el mundo generado (jugadores, clubes y equipaciones).
func _bf_mundo_sin_nombres() -> void:
	_bf_m = Mundo.new()
	_bf_m.generar([], 7)
	var clubes_reales_vistos: Array[String] = []
	var jugadores_marcados := 0
	var jugadores_reales_vistos := 0
	var con_equipacion := 0
	for c: Club in _bf_m.clubes.values():
		if _bf_reales_clubes.has(c.nombre.to_lower()):
			clubes_reales_vistos.append(c.nombre)
		if Jersey.fichero_real(c) != "":
			con_equipacion += 1
		for j: Jugador in c.plantilla:
			if j.real:
				jugadores_marcados += 1
			if _bf_jugadores_reales.has(j.nombre):
				jugadores_reales_vistos += 1
	_comprobar(_bf_m.clubes.size() == _bf_filas_fic.size(), "el mundo ficticio tiene sus %d clubes" % _bf_m.clubes.size())
	_comprobar(clubes_reales_vistos.is_empty(), "ningún club lleva un nombre real %s" % str(clubes_reales_vistos.slice(0, 5)))
	_comprobar(jugadores_marcados > 0 and jugadores_reales_vistos == 0, "los jugadores fijos llevan su guiño, no el nombre real (%d fijos, %d reales)" % [jugadores_marcados, jugadores_reales_vistos])
	## Antes del filtro de vetados salían 110 -"Mohamed Salah", "Christian
	## Pulisic", "Claudio Bravo"...-, porque varias bolsas de nombres eran la
	## convocatoria de una selección. Ahora el generador vuelve a sortear.
	_comprobar(jugadores_reales_vistos == 0, "ningún jugador generado se llama como uno real (%d)" % jugadores_reales_vistos)
	_comprobar(Nombres.vetado("Mohamed Salah") and Nombres.vetado("arturo vidal"),
		"el filtro reconoce a un real, sin importar mayúsculas")
	_comprobar(Nombres.vetado("Óscar Opazo"), "y con tildes: la huella de Godot es la misma que la de Python")
	_comprobar(not Nombres.vetado("Zacarías Quintupal"), "y deja pasar un nombre inventado")
	var huellas_legibles := 0
	for h: Variant in Datos.tabla("NOMBRES_VETADOS"):
		if String(h).contains(" "):
			huellas_legibles += 1
	_comprobar(huellas_legibles == 0 and (Datos.tabla("NOMBRES_VETADOS") as Array).size() == _bf_jugadores_reales.size(),
		"la base lleva %d huellas, ningún nombre legible" % (Datos.tabla("NOMBRES_VETADOS") as Array).size())
	_comprobar(con_equipacion == 0, "ningún club viste una equipación real (%d)" % con_equipacion)


## Ninguna liga, copa ni árbitro con nombre registrado en el mundo ficticio.
func _bf_sin_registrados() -> void:
	var ligas_mal: Array[String] = []
	for l: Liga in _bf_m.ligas:
		if _bf_ligas_reales.has(l.nombre) and not ["Primera División", "Primera B"].has(l.nombre):
			for marca in ["Premier", "Bundesliga", "Serie A", "Ligue 1", "La Liga", "Liga MX", "Brasileir", "Botola", "League", "J-Liga", "K-"]:
				if l.nombre.contains(marca):
					ligas_mal.append(l.nombre)
	_comprobar(ligas_mal.is_empty(), "ninguna liga con nombre registrado %s" % str(ligas_mal))
	var copas_mal: Array[String] = []
	for k: String in (Datos.tabla("CONFED") as Dictionary):
		var n := Nombres.limpiar(String(Datos.tabla("CONFED")[k]["n"]))
		if _bf_copas_reales.has(n) and n != "Copa África de Clubes" and n != "Liga de Oceanía":
			copas_mal.append(n)
	_comprobar(copas_mal.is_empty(), "ningún torneo continental con nombre registrado %s" % str(copas_mal))
	var arbitros_mal := 0
	for fila: Array in Datos.tabla("ARBITROS"):
		if _bf_arbitros_reales.has(Nombres.limpiar(String(fila[0]))):
			arbitros_mal += 1
	_comprobar(arbitros_mal == 0, "ningún árbitro real (%d)" % arbitros_mal)


## Las fotos reales y el guardado: la base se recuerda y vuelve al cargar.
func _bf_foto_y_guardado() -> void:
	## Una foto real no se enseña con la base ficticia aunque el jugador venga
	## marcado como real de un guardado viejo.
	var falso := _bf_m.clubes.values()[0].plantilla[0] as Jugador
	falso.real = true
	_comprobar(Cara.foto_real(falso) == null, "con la base ficticia no se enseña ninguna foto real")
	falso.real = false
	## El guardado recuerda la base y la vuelve a poner al cargar.
	_bf_m.mi_club_id = _bf_m.ligas[0].clubes[0].id
	var foto := Partida.instantanea(_bf_m)
	_comprobar(foto.get("base_real", true) == false, "el guardado anota que se jugó con la base ficticia")
	Datos.usar_base_real(true)
	var m2 := Partida.desde_instantanea(foto)
	_comprobar(m2 != null and not Datos.base_real, "y al cargarlo vuelve a la base ficticia aunque el pack estuviera puesto")
	## Un guardado sin la clave es anterior a todo esto: se jugó con lo real.
	foto.erase("base_real")
	var m3 := Partida.desde_instantanea(foto)
	_comprobar(m3 != null and Datos.base_real, "un guardado viejo (sin la clave) se carga con el pack real")
	## Y con el pack otra vez puesto, lo real vuelve entero.
	Datos.usar_base_real(true)
	var mr := Mundo.new()
	mr.generar(["CHI"], 7)
	var hay_colo := false
	for c: Club in mr.clubes.values():
		if Nombres.limpiar(c.nombre) == "Colo-Colo":
			hay_colo = true
	_comprobar(hay_colo, "con el pack puesto vuelve Colo-Colo")
	_bf_m = null
