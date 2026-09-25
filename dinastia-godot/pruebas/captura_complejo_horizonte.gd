extends Node
## Mira la pieza extra del horizonte (complejo_residencial.glb) desde donde
## de verdad la coloca `CityBuilder._complejo_extra()` -radio 360, angulo
## 0.9-, para juzgar si a la distancia real del horizonte se lee bien o si
## tiene el mismo problema de "masa rota" que la oficina del DT.

var _n := 0

func _ready() -> void:
	var we := Calidad.entorno(Calidad.ALTO, Calidad.TARDE)
	add_child(we)
	add_child(Calidad.sol(Calidad.ALTO, Calidad.TARDE))
	var suelo := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(1000, 1000)
	suelo.mesh = pl
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.3, 0.5, 0.3)
	suelo.material_override = m
	add_child(suelo)

	var ciudad := CityBuilder.new()
	add_child(ciudad)
	ciudad._complejo_extra()

	var cam := Camera3D.new()
	add_child(cam)
	## Desde el centro del complejo, mirando hacia donde queda la pieza -mismo
	## angulo que usa el constructor-, como veria el jugador el horizonte
	## desde el borde del recinto.
	var pos := Vector3(sin(0.9) * 360.0, 0, cos(0.9) * 360.0)
	cam.position = Vector3(0, 40, 60)
	cam.look_at(pos + Vector3(0, 20, 0), Vector3.UP)
	print("pieza en: ", pos)

func _process(_d: float) -> void:
	_n += 1
	if _n == 16:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/pantalla_complejo_horizonte.png")
		print("captura guardada")
	if _n == 20:
		get_tree().quit()
