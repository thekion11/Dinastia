extends Node
## Verifica que "Ath. Bilbao" solo ficha jugadores de España, corriendo el
## mercado de la IA muchas semanas seguidas y mirando quien entra a su
## plantel (22-9-2026, pedido del usuario: "eso debe integrarse en el
## mercado").
##
##   godot --path . --headless res://pruebas/diagnostico_bilbao_mercado.tscn

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["ESP"], 4711)
	var bilbao: Club = null
	for c: Club in m.clubes.values():
		if Nombres.limpiar(c.nombre) == "Ath. Bilbao":
			bilbao = c
			break
	if bilbao == null:
		print("MAL: no encontre Ath. Bilbao")
		get_tree().quit(1)
		return
	var extranjeros_antes := _contar_extranjeros(bilbao)
	print("Bilbao antes: %d jugadores, %d extranjeros" % [bilbao.plantilla.size(), extranjeros_antes])
	for semana in 100:
		m.mercado.mover(6)
	var extranjeros_despues := _contar_extranjeros(bilbao)
	print("Bilbao despues de 100 semanas de mercado IA: %d jugadores, %d extranjeros" % [
		bilbao.plantilla.size(), extranjeros_despues])
	## El plantel inicial (de "PLANTILLAS REALES", jugadores reales importados)
	## puede traer algun extranjero suelto de fabrica -eso no es lo que se
	## prueba aqui-. Lo que importa es que el MERCADO DE LA IA, corriendo 100
	## semanas seguidas, no le sume NINGUNO nuevo.
	print("FIN. 0 fallos" if extranjeros_despues <= extranjeros_antes \
		else "FIN. MAL: el mercado de la IA le sumo %d extranjeros nuevos" % (extranjeros_despues - extranjeros_antes))
	get_tree().quit()

func _contar_extranjeros(c: Club) -> int:
	var n := 0
	for j in c.plantilla:
		if j.pais != c.pais:
			n += 1
	return n
