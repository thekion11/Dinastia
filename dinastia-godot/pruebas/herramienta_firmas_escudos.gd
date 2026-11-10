extends Node
## Herramienta (no es prueba): imprime la FIRMA del escudo de todos los clubes del mundo, igual que M-062 (`varios_p8.gd`), para `herramientas/aspecto_unicos.py`.
##   REAL=1 → con los nombres del pack real; sin REAL, la base pública. Misma semilla y mismo orden en las dos.
func _ready() -> void:
	Datos.usar_base_real(OS.get_environment("REAL") == "1")
	var m := Mundo.new()
	var paises: Array[String] = []
	for pais: String in (Datos.tabla("PAISES_LIGAS") as Dictionary):
		paises.append(pais)
	m.generar(paises, 5962)
	for c: Club in m.clubes.values():
		print("SIG|%s|%s|%s|%s|%s|%s|%s" % [Escudo.forma_de(c), Escudo.patron_de(c), c.color1.to_lower(), c.color2.to_lower(),
			Escudo.simbolo_de(c), Escudo.iniciales(c) if Escudo.simbolo_de(c) == "" else "", Nombres.limpiar(c.nombre)])
	get_tree().quit()
