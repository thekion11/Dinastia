extends Node
## Cuatro fotos del mismo sitio a cuatro horas distintas: amanecer, mediodia,
## atardecer y noche cerrada. Es la prueba del ciclo del sol -sobre todo de la
## NOCHE, que es donde se rompen estas cosas: o se ve todo negro, o se ve igual
## que de dia con el cielo pintado de azul oscuro.
##
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 \
##         res://pruebas/captura_horas.tscn

## [hora, nombre, distancia, altura, angulo]
const HORAS := [
	[6.4, "hora_amanecer", 430.0, 120.0, 0.55],
	[12.5, "hora_mediodia", 430.0, 120.0, 0.55],
	[19.2, "hora_atardecer", 430.0, 120.0, 0.55],
	[23.0, "hora_noche", 430.0, 120.0, 0.55],
	## Un plano CERCA de las farolas del anillo: la prueba de que existen, de
	## que son negras y grandes y de que su luz es del color elegido.
	[22.0, "hora_farolas", 150.0, 32.0, 2.35],
]

var _n := 0
var _paso := 0
var _vista: VistaCiudad
var _mundo: Mundo

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4713)
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)
	for k in _mundo.obras.niveles.keys():
		_mundo.obras.niveles[k] = 3
	_mundo.ciudad.terrenos = ["norte", "centro", "periferia", "ribera", "sur"]
	for n in ["hotel", "parking", "comercial", "clinica"]:
		_mundo.ciudad.negocios[n] = true
	## Un color que NO es el de por defecto, para comprobar que el elegido
	## llega de verdad hasta las farolas del 3D.
	_mundo.ciudad.luces = "#7ee0ff"
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.abrir(_mundo.mi_club(), _mundo.obras, _mundo.ciudad,
		_mundo.perfil_estadio_de(_mundo.mi_club()))
	_vista.set("_girando", false)
	## El ciclo se detiene: cada foto es a su hora exacta, no a la que toque.
	_vista.call("alternar_ciclo")
	## Comprobación de que el color elegido llega de verdad a las farolas del
	## 3D y no se queda en el dato: se lee del propio nodo construido.
	var ciudad3d: Node = _vista.get("_ciudad")
	print("color elegido en Ciudad: %s   ·   color que usan las farolas: %s" % [
		_mundo.ciudad.luces, str(ciudad3d.get("_luz_color"))])
	var faros: Array = ciudad3d.get("_farolas_luz")
	print("farolas construidas: %d" % faros.size())

func _process(_d: float) -> void:
	_n += 1
	if _n < 14 or _paso >= HORAS.size():
		return
	var t := _n - 14
	if t % 8 != 0:
		return
	var i: int = t / 8
	if i % 2 == 0:
		var h: Array = HORAS[_paso]
		_vista.set("_hora", h[0])
		_vista.set("_dist", h[2])
		_vista.set("_alto", h[3])
		_vista.set("_ang", h[4])
		_vista.call("_aplicar_hora")
	else:
		var h2: Array = HORAS[_paso]
		if String(h2[1]) == "hora_farolas":
			var c3: Node = _vista.get("_ciudad")
			var fl: Array = c3.get("_farolas_luz")
			if fl.size() > 0:
				var l0: OmniLight3D = fl[0]
				print("farola[0]: energia=%.2f  visible=%s  rango=%.0f  pos=%s  color=%s" % [
					l0.light_energy, l0.visible, l0.omni_range, l0.global_position, l0.light_color])
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/%s.png" % String(h2[1]))
		print("captura %s (hora %.1f)" % [String(h2[1]), float(h2[0])])
		_paso += 1
		if _paso >= HORAS.size():
			get_tree().quit()
