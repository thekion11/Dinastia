extends Node
## LA OLA Y LA ONDA DE LA GRADA (20-10-2026, M-036/044) vistas desde el campo
## mirando la tribuna de enfrente (la cámara de TV la corta): foto sin nada, con la ola pasando y con la onda de un gol.
##   herramientas/captura.sh res://pruebas/captura_ola.tscn
var _vista: VistaEstadio
var _n := 0
var _ola: OlaGrada
var _fotos := 0

func _ready() -> void:
	Calidad.elegida = Calidad.ALTO
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var par := mundo.proximo_partido()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))

func _foto(nombre: String) -> void:
	_fotos += 1
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/ola_%d_%s.png" % [_fotos, nombre])
	print("FOTO ", nombre)

func _process(_d: float) -> void:
	for k in ["_intro", "_ceremonia"]:
		var x: Variant = _vista.get(k)
		if x != null and is_instance_valid(x) and x.activa:
			x.terminar()
			return
	var motor: MotorJugable = _vista.get("_motor")
	if motor == null:
		return
	var raiz: Node3D = _vista.get("_raiz3d")
	## Se cuenta desde que empieza el juego (antes, la intro y la ceremonia).
	_n += 1
	match _n:
		58:
			## Una cámara mirando la tribuna de enfrente entera (la de TV la corta).
			var cam := Camera3D.new()
			raiz.add_child(cam)
			cam.global_position = Vector3(-15, 16, 0)
			cam.look_at(Vector3(60, 9, 0))
			cam.fov = 70.0
			cam.current = true
		60:
			OlaGrada.mirar(raiz, Vector3.ZERO, 0.0)
			_foto("quieta")
			_ola = OlaGrada.lanzar(raiz, "ola")
			for m: ShaderMaterial in OlaGrada.materiales(raiz):
				## Que pase justo por la grada de enfrente de la cámara.
				m.set_shader_parameter("ola_inicio", 0.6)
		61:
			_ola.set_process(false)
			_ola.edad = 2.2
			_ola._escribir(2.2)
		64:
			_foto("ola")
			_ola.edad = 4.2
			_ola._escribir(4.2)
		67:
			_foto("ola_mas")
			_ola.queue_free()
			var o := OlaGrada.lanzar(raiz, "onda", Vector3(0, 0, -62))
			o.set_process(false)
			o.edad = 2.6
			o._escribir(2.6)
		70:
			_foto("onda")
			## De cerca: las cabezas hacia el balón (M-049) y la protesta (M-045).
			var cam2 := Camera3D.new()
			raiz.add_child(cam2)
			cam2.global_position = Vector3(30, 4.5, 6)
			cam2.look_at(Vector3(44, 5.5, 0))
			cam2.fov = 55.0
			cam2.current = true
			## Que la vista no vuelva a escribir el balón de verdad encima.
			_vista.set_process(false)
		72:
			OlaGrada.mirar(raiz, Vector3(0, 0, -60))
		74:
			_foto("mira_izq")
			OlaGrada.mirar(raiz, Vector3(0, 0, 60))
		76:
			_foto("mira_der")
			var p := OlaGrada.lanzar(raiz, "protesta")
			p.set_process(false)
			p.edad = 1.2
			p._escribir(1.2)
		78:
			_foto("protesta")
			get_tree().quit()
