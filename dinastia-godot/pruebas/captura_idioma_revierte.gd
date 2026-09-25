extends Node
## Prueba del arreglo a `_traducir_pantalla()` (12-9-2026): el boton "Guardar"
## de la fila de acciones se construye UNA sola vez en `_construir()` y nunca
## se repinta. Antes del arreglo, la funcion no hacia nada si `Idiomas.idioma
## == "es"`, asi que ese boton se quedaba pegado en el ultimo idioma elegido
## para siempre y nunca volvia al castellano. Ciclo: es -> en -> es (debe
## volver a "Guardar") -> fr (debe cambiar de verdad, no quedarse en "Save").

var _n := 0
var _pantalla: Node
var _boton_guardar: Button

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _buscar_boton_guardar() -> Button:
	var botones: Node = _pantalla.get("_botones")
	for h in botones.get_children():
		if h is Button and (h as Button).text == "Guardar":
			return h
	return null

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		_boton_guardar = _buscar_boton_guardar()
		print("boton encontrado=%s texto inicial='%s'" % [_boton_guardar != null, _boton_guardar.text if _boton_guardar else "?"])
	if _n == 12:
		Idiomas.idioma = "en"
		_pantalla.call("_refrescar")
		print("tras pasar a EN: '%s'" % _boton_guardar.text)
	if _n == 14:
		Idiomas.idioma = "es"
		_pantalla.call("_refrescar")
		print("tras VOLVER a ES: '%s'  (debe ser Guardar)" % _boton_guardar.text)
	if _n == 16:
		Idiomas.idioma = "en"
		_pantalla.call("_refrescar")
		print("tras pasar a EN otra vez: '%s'" % _boton_guardar.text)
		Idiomas.idioma = "fr"
		_pantalla.call("_refrescar")
		print("tras EN->FR directo: '%s'  (no debe quedarse en Save)" % _boton_guardar.text)
	if _n == 18:
		Idiomas.idioma = "es"
		_pantalla.call("_refrescar")
		print("vuelta final a ES: '%s'" % _boton_guardar.text)
		get_tree().quit()
