class_name ProbarNativoSonido
extends RefCounted
## (19-11-2026) LA SÍNTESIS DEL SONIDO EN C++ = GDScript. Sintetiza los 214 sonidos del catálogo × 4 variantes con la extensión
## (`son_tono`, `son_ruido`, `son_mezclar`, `son_a_16`) y con las gemelas `_gd` de `nucleo/sonido_p1.gd`, y compara los bytes de
## cada WAV. Además, casos sueltos de cada primitiva (formas, duraciones cero, mezcla que alarga y mezcla que satura). Devuelve
## {fallos, textos}. Una instancia del script del autoload SIN árbol: no arranca su hilo de fondo.
static func probar(nat: Object) -> Dictionary:
	var fallos: Array[String] = []
	var s: Node = load("res://nucleo/sonido.gd").new()
	var nombres: Array = s.NOMBRES
	var t_gd := 0
	var t_cpp := 0
	var distintos := 0
	for nombre: String in nombres:
		for v in s.VARIANTES:
			var sal := float(v) / float(s.VARIANTES)
			s._nat = null
			var t0 := Time.get_ticks_usec()
			var a: PackedByteArray = s._sintetizar(nombre, sal).data
			var t1 := Time.get_ticks_usec()
			s._nat = nat
			var b: PackedByteArray = s._sintetizar(nombre, sal).data
			var t2 := Time.get_ticks_usec()
			t_gd += t1 - t0
			t_cpp += t2 - t1
			if a != b:
				distintos += 1
				if distintos <= 5:
					fallos.append("«%s» variante %d: %d bytes en GDScript, %d en C++, distintos" % [nombre, v, a.size(), b.size()])
	if distintos > 5:
		fallos.append("… y %d variantes más distintas" % (distintos - 5))
	## Primitivas sueltas, también lo que las recetas no usan (forma desconocida, duración 0, saturación).
	for forma: String in ["seno", "cuadrada", "sierra", "triangulo"]:
		for dur: float in [0.0, 0.00004, 0.37]:
			s._nat = null
			var a: PackedFloat32Array = s._tono(431.7, dur, 0.9, forma)
			s._nat = nat
			if a != s._tono(431.7, dur, 0.9, forma):
				fallos.append("tono %s de %s s distinto" % [forma, dur])
	for caso: Array in [[0.0, 300.0, 90.0, 0.05], [0.5, 2200.0, 2600.0, 0.7], [1.3, 60.0, 9000.0, 1.0], [0.2, 9000.0, 60.0, 0.3]]:
		s._nat = null
		var a: PackedFloat32Array = s._ruido(caso[0], caso[1], caso[2], caso[3])
		s._nat = nat
		if a != s._ruido(caso[0], caso[1], caso[2], caso[3]):
			fallos.append("ruido %s distinto" % [caso])
	for retraso: float in [0.0, 0.05, 2.0]:
		var dest_gd := PackedFloat32Array([0.9, -0.95, 0.3, 0.0])
		var dest_c := dest_gd.duplicate()
		var fuente := PackedFloat32Array([0.5, -0.5, 0.25, 0.75, -1.0])
		s._nat = null
		s._mezclar(dest_gd, fuente, retraso)
		s._nat = nat
		s._mezclar(dest_c, fuente, retraso)
		if dest_gd != dest_c:
			fallos.append("mezcla con retraso %s distinta (%d frente a %d muestras)" % [retraso, dest_gd.size(), dest_c.size()])
	var extremos := PackedFloat32Array([-2.0, -1.0, -0.99999, -0.5, 0.0, 0.00001, 0.5, 0.99999, 1.0, 3.0])
	s._nat = null
	var e_gd: PackedByteArray = s._a_wav(extremos).data
	s._nat = nat
	if e_gd != s._a_wav(extremos).data:
		fallos.append("paso a 16 bits distinto en los extremos")
	s.free()
	var textos: Array[String] = ["síntesis de %d sonidos × 4: GDScript %d ms, C++ %d ms" % [nombres.size(), t_gd / 1000, t_cpp / 1000]]
	return {"fallos": fallos, "textos": textos}
