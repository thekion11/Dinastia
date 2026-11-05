extends BaseSO
## FUNCIONES · el generador de azar del juego (`Azar`): misma semilla → misma secuencia en CUALQUIER sistema (Windows, Web, Android…; si la
## secuencia cambiara entre sistemas, los mundos con semilla también), rangos respetados, `barajar` es una permutación, `campana` recorta,
## semilla 0 elige una y la guarda (positiva) y dos semillas distintas dan secuencias distintas. Incluye valores de referencia fijos.
func _nombre() -> String:
	return "fun_azar_puro"

func _secuencia(semilla: int, n: int) -> Array:
	Azar.sembrar(semilla)
	var o: Array = []
	for i in n:
		o.append(Azar.ent(0, 1000))
	return o

func _probar() -> void:
	_titulo("FUNCIONES · Azar [%s]" % sistema())
	_comprobar(_secuencia(42, 50) == _secuencia(42, 50), "misma semilla, misma secuencia")
	_comprobar(_secuencia(42, 50) != _secuencia(43, 50), "otra semilla, otra secuencia")
	## Referencia fija: PCG32 de Godot con semilla 42 da lo mismo en todos los sistemas.
	var ref: Array = _secuencia(42, 5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var esperado: Array = []
	for i in 5:
		esperado.append(rng.randi_range(0, 1000))
	_comprobar(ref == esperado, "Azar.ent con semilla 42 = RandomNumberGenerator directo %s" % str(ref))
	var fijo := JSON.stringify(_secuencia(20261105, 8))
	print("  INFO  huella de referencia (semilla 20261105): ", fijo)
	_comprobar(fijo.md5_text() == JSON.stringify(_secuencia(20261105, 8)).md5_text(), "la huella es estable dentro del proceso")
	Azar.sembrar(7)
	var fuera := 0
	for i in 2000:
		var v := Azar.ent(-3, 4)
		var w := Azar.f()
		fuera += int(v < -3 or v > 4 or w < 0.0 or w >= 1.0)
	_comprobar(fuera == 0, "ent(-3,4) y f() respetan sus rangos en 2000 tiradas")
	_comprobar(Azar.ent(5, 2) == 5, "ent(a,b) con b<a devuelve a")
	_comprobar(Azar.uno([]) == null and Azar.uno([9]) == 9, "uno([]) = null; uno([9]) = 9")
	var si := 0
	for i in 4000:
		si += int(Azar.suerte(0.25))
	_comprobar(si > 800 and si < 1200, "suerte(0,25) acierta %d de 4000 (≈1000)" % si)
	_comprobar(not Azar.suerte(0.0) and Azar.suerte(1.0), "suerte(0) nunca; suerte(1) siempre")
	var recorte := 0
	for i in 1000:
		var c := Azar.campana(50.0, 100.0, 40.0, 60.0)
		recorte += int(c < 40.0 or c > 60.0)
	_comprobar(recorte == 0, "campana recorta a [min,max]")
	var a: Array = range(30)
	var b := a.duplicate()
	Azar.barajar(b)
	var ordenado := b.duplicate()
	ordenado.sort()
	_comprobar(ordenado == a and b != a, "barajar es una permutación distinta del orden original")
	var s := Azar.sembrar(0)
	_comprobar(s > 0 and Azar.semilla == s, "semilla 0 elige una positiva (%d) y la guarda" % s)
	Azar.sembrar(1)
