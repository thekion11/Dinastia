extends "res://nucleo/mundo_p3_p1.gd"
## (Parte 2 de 2 de `mundo_p3.gd`.)

func anotar_eficacia(formacion: String, gf: int, gc: int) -> void:
	if formacion == "":
		return
	if not eficacia_tactica.has(formacion):
		eficacia_tactica[formacion] = {"pj": 0, "pg": 0, "pe": 0, "pp": 0, "gf": 0, "gc": 0}
	var f: Dictionary = eficacia_tactica[formacion]
	f["pj"] = int(f["pj"]) + 1
	f["gf"] = int(f["gf"]) + gf
	f["gc"] = int(f["gc"]) + gc
	if gf > gc:
		f["pg"] = int(f["pg"]) + 1
	elif gf == gc:
		f["pe"] = int(f["pe"]) + 1
	else:
		f["pp"] = int(f["pp"]) + 1

## Los dos desafíos que se juegan en un solo partido: el invicto se acaba con
## la primera derrota -no empate, derrota- y el del clásico solo aprieta si
## ADEMÁS perdiste contra un rival de verdad.
func _chequear_desafios_tras_partido(gf: int, gc: int, rival: Club) -> void:
	var perdio := gf < gc
	if tiene_desafio("invicto") and perdio and fin_partida.is_empty():
		fin_partida = {"motivo": "invicto", "anio": anio, "semana": semana}
	if tiene_desafio("derbis") and perdio and es_clasico(mi_club(), rival):
		if directiva != null:
			## `mover_confianza()` solo recibe un DELTA, así que el objetivo absoluto
			## -la mitad de la confianza actual, redondeada, tal cual el HTML
			## (`Math.round(G.confianza*0.5)`)- se calcula primero y se resta el
			## delta que hace falta para llegar ahí. Restar directamente la mitad
			## redondeada (`-round(confianza*0.5)`) no es lo mismo con confianza
			## impar: con 55 de confianza daba 27 en vez de los 28 del HTML.
			var objetivo := int(round(float(directiva.confianza) * 0.5))
			directiva.mover_confianza(objetivo - directiva.confianza,
				"perdiste el clásico -desafío activo, cuesta el doble-")

## La MISMA generación, repartida entre fotogramas (7-11, meta «< 200 ms por carga»): cada club se crea igual y en el mismo orden (mismo mundo para la misma semilla), pero
## tras cada trozo de `ms_trozo` ms se cede un fotograma para que la pantalla siga viva. Devuelve cuando termina (`await`).
## `sigue` (12-11, fallo n.º 1 del plan): si se da y deja de ser válida o devuelve false (la pantalla que la pidió se fue), la generación
## se ABANDONA en el siguiente trozo sin tocar lo global (`LeyesPais.clubes_mundo`, `Meta.heredar_proximo`, `LigasActivas`).
func generar_por_trozos(paises: Array[String] = [], semilla_partida: int = 0, ms_trozo := 25.0, sigue := Callable()) -> void:
	_generar_inicio(semilla_partida)
	var arbol := Engine.get_main_loop() as SceneTree
	var t0 := Time.get_ticks_usec()
	for f: Dictionary in _fuentes_de_liga(paises):
		var liga := Liga.new(f["nombre"], f["pais"], int(f.get("division", 1)))
		if liga.division() == 1 and ReglasAscenso.tiene(liga.pais):
			liga.plazas_descenso = int(ReglasAscenso.de(liga.pais)["bajan"])   ## (10-11) los descensos reales del país
		for fila: Array in f["clubes"]:
			_generar_club(liga, f, fila)
			if arbol != null and float(Time.get_ticks_usec() - t0) / 1000.0 >= ms_trozo:
				await arbol.process_frame
				if abandonada(sigue):
					return
				t0 = Time.get_ticks_usec()
		liga.preparar()
		ligas.append(liga)
	await Reales.aplicar_por_trozos(self, ms_trozo)
	if abandonada(sigue):
		return
	_generar_cierre()

static func abandonada(sigue: Callable) -> bool:
	return not sigue.is_null() and (not sigue.is_valid() or not bool(sigue.call()))
