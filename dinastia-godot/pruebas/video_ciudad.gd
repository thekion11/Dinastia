extends Node
## GRABA EL VIDEO de la ciudad: una vuelta de camara completa mientras pasa un
## dia entero -amanece, mediodia, atardece, anochece con las farolas y las
## ventanas encendidas, y vuelve a amanecer-.
##
## Se graba con el escritor de peliculas que trae Godot (`--write-movie`), que
## renderiza a paso fijo: no depende de que la maquina llegue a 30 fps, cada
## fotograma se dibuja entero y se escribe. Por eso el video sale fluido en una
## Intel UHD que en vivo iria a tirones.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##         --fixed-fps 30 --write-movie ..\entregas\ciudad.avi \
##         res://pruebas/video_ciudad.tscn
##
## OJO: el escritor de peliculas IGNORA `get_tree().quit()` si se llama en el
## mismo fotograma en que arranca, y sobre todo hay que cerrarlo nosotros o el
## AVI se queda sin la cabecera y no lo abre ningun reproductor.

## 20 s a 30 fps y no 30 s: el AVI que escribe Godot es MJPEG, sin compresion
## entre fotogramas, asi que pesa ~2 MB por segundo a 1280x720. A 30 s se iba a
## 65 MB y no pasaba el limite de envio (30 MB). Con 20 s a 960x540 baja a ~24
## MB sin perder lo que hay que evaluar.
## OJO CON EL TAMAÑO: lo unico que de verdad mueve el peso del AVI es la
## DURACION. Se probo bajar de 1280x720 a 960x540 y a 880x496 y el fichero
## apenas cambio (~31 MB las tres veces); quitando 60 fotogramas si baja.
const FOTOGRAMAS := 385
const CICLO_VIDEO := 12.0        ## un dia entero en 12 s, para que entre en el video

var _n := 0
var _vista: VistaCiudad
var _mundo: Mundo

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4713)
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)
	## Un club con todo construido: es el mejor escaparate de lo que la
	## pantalla sabe enseñar.
	for k in _mundo.obras.niveles.keys():
		_mundo.obras.niveles[k] = 3
	_mundo.ciudad.terrenos = ["norte", "centro", "periferia", "ribera", "sur"]
	for n in ["hotel", "parking", "comercial", "clinica"]:
		_mundo.ciudad.negocios[n] = true

	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.abrir(_mundo.mi_club(), _mundo.obras, _mundo.ciudad,
		_mundo.perfil_estadio_de(_mundo.mi_club()))
	## Arranca de madrugada para que lo primero que se vea sea el amanecer.
	_vista.set("_hora", 4.6)
	_vista.set("_dist", 560.0)
	_vista.set("_alto", 175.0)
	_vista.set("_ang", 0.2)
	print("grabando %d fotogramas..." % FOTOGRAMAS)

func _process(delta: float) -> void:
	_n += 1
	## El ciclo del dia va MAS RAPIDO que en el juego: `VistaCiudad` lo mueve a
	## 120 s por vuelta, aqui hace falta que quepa un dia entero en el video.
	var h: float = float(_vista.get("_hora"))
	_vista.set("_hora", fposmod(h + delta * (24.0 / CICLO_VIDEO) - delta * (24.0 / 120.0), 24.0))
	## Y la camara da una vuelta completa en el mismo tiempo, bajando un poco
	## para acabar mas cerca del suelo que como empezo.
	var t: float = float(_n) / float(FOTOGRAMAS)
	_vista.set("_ang", 0.2 + t * TAU)
	_vista.set("_dist", lerpf(560.0, 420.0, t))
	_vista.set("_alto", lerpf(175.0, 120.0, t))
	if _n >= FOTOGRAMAS:
		print("listo")
		get_tree().quit()
