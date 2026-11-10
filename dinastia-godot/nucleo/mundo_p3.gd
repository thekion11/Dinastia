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
