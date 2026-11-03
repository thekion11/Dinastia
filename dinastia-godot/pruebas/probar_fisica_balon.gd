extends SceneTree
## Física del balón (3-11-2026): arrastre cuadrático, Magnus y rebote contra datos reales.
## Uso: godot --headless --path dinastia-godot -s res://pruebas/probar_fisica_balon.gd
## Debe terminar en «FIN. 0 fallos».
var _fallos := 0

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok   " if ok else "  FALLO ") + texto)
	if not ok:
		_fallos += 1

func _nuevo(pos: Vector3, v: Vector3, giro: Vector3) -> Balon3D:
	var b := Balon3D.new()
	root.add_child(b)
	b.position = pos
	b.disparar(v, giro)
	return b

func _correr(b: Balon3D, seg: float) -> void:
	var n := int(seg * 60.0)
	for i in n:
		b.avanzar(1.0 / 60.0)

func _process(_d: float) -> bool:
	## 1) Arrastre cuadrático: a 10 m/s casi no frena; a 30 m/s mucho más que lineal.
	var a := _nuevo(Vector3(0, 30, 0), Vector3(10, 0, 0), Vector3.ZERO)
	_correr(a, 0.5)
	_comprobar(absf(a.velocidad_vectorial.x - 9.4) < 0.5, "10 m/s pierde ~0,6 m/s en 0,5 s (%.2f)" % a.velocidad_vectorial.x)
	var c := _nuevo(Vector3(0, 30, 0), Vector3(30, 0, 0), Vector3.ZERO)
	_correr(c, 0.5)
	_comprobar(c.velocidad_vectorial.x < 28.0 and c.velocidad_vectorial.x > 25.0, "30 m/s pierde 2-5 m/s en 0,5 s (%.2f)" % c.velocidad_vectorial.x)
	## 2) Magnus: tiro libre a 25 m/s con ~50 rad/s curva 2-6 m en el primer segundo.
	var l := _nuevo(Vector3(0, 30, 0), Vector3(25, 0, 0), Vector3(0, 50, 0))
	_correr(l, 1.0)
	_comprobar(absf(l.position.z) > 2.0 and absf(l.position.z) < 6.0, "efecto 50 rad/s: curva %.1f m en 1 s" % absf(l.position.z))
	## 3) Rebote: cae de 5 m; cociente de velocidad vertical entre 0,5 y 0,65.
	var r := _nuevo(Vector3(0, 5, 0), Vector3.ZERO, Vector3.ZERO)
	var vmax := 0.0
	var vrebote := 0.0
	for i in 400:
		var antes := r.velocidad_vectorial.y
		r.avanzar(1.0 / 60.0)
		if antes < -1.2 and r.velocidad_vectorial.y > 0.0:
			vmax = -antes
			vrebote = r.velocidad_vectorial.y
			break
	_comprobar(vmax > 0.0 and vrebote / vmax > 0.5 and vrebote / vmax < 0.65, "restitución %.2f" % (vrebote / maxf(vmax, 0.001)))
	## 4) Rodadura: a 10 m/s recorre entre 20 y 40 m hasta pararse.
	var s := _nuevo(Vector3(0, 0.11, 0), Vector3(10, 0, 0), Vector3.ZERO)
	_correr(s, 20.0)
	_comprobar(s.position.x > 20.0 and s.position.x < 40.0, "rodando 10 m/s llega a %.1f m" % s.position.x)
	print("===== FIN. %d fallos" % _fallos)
	quit(1 if _fallos > 0 else 0)
	return true
