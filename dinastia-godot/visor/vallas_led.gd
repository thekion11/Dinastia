class_name VallasLed
extends Node3D
## LAS VALLAS LED DEL PERÍMETRO, con marca de verdad y cambiando solas.
##
## Sale de los dos videos de referencia del usuario, que coinciden en esto por
## encima de cualquier otra cosa del estadio:
##   - `marca/referencia/ea_fc25_referencia.mp4`: el anillo de paneles rodea el
##     campo entero y se lee "EA FC25" / "EA FC24" panel por panel, con cada
##     panel de un color distinto.
##   - `marca/referencia/ejemplo-partido.mp4` (Soccer Manager 2026): lo mismo,
##     con "SOCCER MANAGER 2026" repetido y alternando blanco y dorado.
##
## Hasta hoy `StadiumBuilder._vallas_publicidad()` ponía 54 cajas de COLOR LISO
## alternando tres tonos: la silueta estaba, el contenido no. Es la misma clase
## de hueco que tenía la pantalla gigante antes de esta misma tanda.
##
## POR QUÉ UN NODO Y NO SOLO GEOMETRÍA: una valla LED que nunca cambia es un
## cartel pintado. Cambiar el anuncio es lo que la delata como pantalla, y para
## eso hace falta algo vivo en el árbol. Este nodo es ese algo, y es barato a
## propósito -ver `_process()`.
##
## NO SE FUNDE ENTRE ANUNCIOS, CORTA EN SECO. Se probó pensar el fundido y se
## descartó por una razón concreta: `Label3D` con transparencia real (sin
## `ALPHA_CUT_DISCARD`) mete 54 superficies transparentes a ordenar delante de
## la grada, que es justo el tipo de cosa que produce parpadeos de ordenación;
## y con `ALPHA_CUT_DISCARD` el "fundido" sería el texto apareciendo de golpe
## igual. Una valla LED de verdad tampoco funde: corta.

## Cuánto dura cada anuncio en un panel.
const SEG := 5.0
## Desfase entre panel y panel, para que el anillo cambie en ola y no los 54 de
## golpe -que es lo que se ve en los dos videos-.
const DESFASE := 0.42

## {"texto": String, "fondo": Color, "tinta": Color}
var _anuncios: Array = []
## Un material por anuncio, creados una sola vez: 54 paneles comparten los 6.
var _materiales: Array[StandardMaterial3D] = []
## {"caja": MeshInstance3D, "label": Label3D, "fase": float, "ult": int}
var _paneles: Array = []
var _t := 0.0

func sembrar(anuncios: Array) -> void:
	_anuncios = anuncios
	_materiales.clear()
	for a: Dictionary in _anuncios:
		var m := StandardMaterial3D.new()
		var fondo: Color = a.get("fondo", Color(0.10, 0.11, 0.13))
		m.albedo_color = fondo
		m.roughness = 0.42
		m.metallic = 0.15
		## Emisión baja a propósito: es un panel encendido visto de lado, no un
		## foco. Con más se come el contraste del texto de encima (es el mismo
		## error que ya costó dos vueltas en la pantalla gigante el 22-9).
		m.emission_enabled = true
		m.emission = fondo
		m.emission_energy_multiplier = 0.16
		_materiales.append(m)

## Lo llama `StadiumBuilder._una_valla()` panel por panel. El `idx` decide con
## qué anuncio arranca cada uno: si todos empezaran por el primero, el anillo
## entero diría lo mismo a la vez y se leería como una pancarta, no como LED.
func registrar(caja: MeshInstance3D, label: Label3D, idx: int) -> void:
	var p := {"caja": caja, "label": label, "fase": float(idx) * DESFASE, "ult": -1}
	_paneles.append(p)
	_pintar(p, idx)

func _process(delta: float) -> void:
	if _anuncios.is_empty() or _paneles.is_empty():
		return
	_t += delta
	for p: Dictionary in _paneles:
		## Solo una división y una comparación por panel y por frame. El texto
		## de un `Label3D` reconstruye su malla al asignarlo, así que solo se
		## toca cuando el anuncio DE VERDAD cambió -no en cada frame-.
		var ciclo := int(floor((_t + float(p["fase"])) / SEG))
		if ciclo != int(p["ult"]):
			_pintar(p, ciclo)

func _pintar(p: Dictionary, ciclo: int) -> void:
	if _anuncios.is_empty():
		return
	p["ult"] = ciclo
	var a: Dictionary = _anuncios[posmod(ciclo, _anuncios.size())]
	var l: Label3D = p["label"]
	if is_instance_valid(l):
		l.text = String(a.get("texto", ""))
		l.modulate = a.get("tinta", Color.WHITE)
	var c: MeshInstance3D = p["caja"]
	if is_instance_valid(c):
		c.material_override = _materiales[posmod(ciclo, _materiales.size())]
