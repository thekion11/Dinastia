extends RefCounted
## LAS PREFERENCIAS DEL JUGADOR (fase 0: sale de `Principal`, capas 10 y 19).
##
## Una sola responsabilidad: leer y escribir `Principal.PREFS`
## (`user://preferencias.cfg`), el archivo con el aspecto, el idioma, la
## música, la accesibilidad y la pantalla. NO van en la partida: son tuyas, no
## de tu club (ver el comentario de `PREFS` en `principal_p3.gd`).
##
## Interfaz: `cargar()` y `guardar()`. Principal la posee (`_prefs`) y conserva
## `_cargar_preferencias()` y `_guardar_preferencias()` como puentes (los llaman
## Ajustes, Opciones y varias pruebas).
##
## Los valores siguen viviendo donde se usan (las variables `_paleta`,
## `_escala_texto`... de Principal y los autoload `Musica`, `Sonido`,
## `Idiomas`...): esta clase solo los vuelca y los recupera. `RefCounted` basta:
## no conecta señales ni cuelga nodos.

var p: Principal

## Lo escrito la última vez. Principal se repinta en CADA refresco del juego
## -no solo al tocar un ajuste- y Ajustes llama a `guardar()` al repintarse, así
## que sin esto se escribiría el archivo en cada clic sin que hubiera cambiado
## nada.
var _firma: String = ""

func _init(principal: Principal) -> void:
	p = principal

## Lee el archivo y aplica cada valor. Sin archivo (primera vez) no toca nada:
## se quedan los valores por defecto.
func cargar() -> void:
	var cf := ConfigFile.new()
	if cf.load(Principal.PREFS) != OK:
		return
	## Cada lectura se valida contra lo que existe HOY. Un archivo de una version
	## vieja puede nombrar una paleta que ya no esta, y quedarse sin colores por
	## eso seria peor que ignorar la linea.
	var pal := String(cf.get_value("aspecto", "paleta", p._paleta))
	if Principal.PALETAS.has(pal):
		p._paleta = pal
	var f := String(cf.get_value("aspecto", "forma_tarjeta", p._forma_tarjeta))
	if Principal.FORMAS_TARJETA.has(f):
		p._forma_tarjeta = f
	p._brillo_tarjetas = bool(cf.get_value("aspecto", "brillo_tarjetas", p._brillo_tarjetas))
	var fo := String(cf.get_value("aspecto", "fondo", p._fondo_elegido))
	## `ROTAR_FONDO` no está en `Fondo.NOMBRES` -es un valor especial, no un
	## fondo-, así que hay que dejarlo pasar aparte o al reabrir el juego se
	## perdería la rotación y volvería a uno fijo.
	if fo == "" or fo == Principal.ROTAR_FONDO or Fondo.NOMBRES.has(fo):
		p._fondo_elegido = fo
	p._rotar_diseno = bool(cf.get_value("aspecto", "rotar_diseno", true))
	var em := String(cf.get_value("aspecto", "estilo_menu", p._estilo_menu))
	for e: Array in Principal.ESTILOS_MENU:
		if String(e[0]) == em:
			p._estilo_menu = em
	var cl := String(cf.get_value("aspecto", "clima", p._clima_elegido))
	if FondoAnimado.MODOS.has(cl):
		p._clima_elegido = cl
	p._clima_interactivo = bool(cf.get_value("aspecto", "clima_interactivo", p._clima_interactivo))
	var mt := String(cf.get_value("aspecto", "marca_tarjeta", p._marca_tarjeta))
	if MarcaPanel.ESTILOS.has(mt):
		p._marca_tarjeta = mt
	var tp := String(cf.get_value("aspecto", "tipografia", p._tipografia))
	if Principal.TIPOGRAFIAS.has(tp):
		p._tipografia = tp
	var idi := String(cf.get_value("juego", "idioma", Idiomas.idioma))
	if idi == "es" or Idiomas.NOMBRES.has(idi):
		Idiomas.idioma = idi
	p._velocidad_partido = clampi(int(cf.get_value("juego", "velocidad_partido", p._velocidad_partido)), 1, 3)
	Musica.encendida = bool(cf.get_value("musica", "encendida", Musica.encendida))
	Musica.volumen = clampf(float(cf.get_value("musica", "volumen", Musica.volumen)), 0.0, 1.0)
	var mp := String(cf.get_value("musica", "pieza", Musica.pieza))
	if mp == "" or Musica.PIEZAS.has(mp):
		Musica.pieza = mp
	Musica.automatica = bool(cf.get_value("musica", "automatica", Musica.automatica))
	p._escala_texto = clampf(float(cf.get_value("texto", "escala", p._escala_texto)), 0.7, 1.6)
	p._daltonico = bool(cf.get_value("texto", "daltonico", p._daltonico))
	p._zoom_interfaz = clampf(float(cf.get_value("pantalla", "zoom", p._zoom_interfaz)), 0.7, 1.6)
	p._modo_tv = bool(cf.get_value("pantalla", "modo_tv", p._modo_tv))
	VestidorQ.ropa_aparte = bool(cf.get_value("pantalla", "ropa_aparte", VestidorQ.ropa_aparte))
	Cara.usar_fotos = bool(cf.get_value("pantalla", "caras_foto", Cara.usar_fotos))
	## 0 = «sin límite» (antes el clampi lo volvía 30 al recargar).
	var fps_g := int(cf.get_value("pantalla", "fps", p._fps_elegido))
	p._fps_elegido = 0 if fps_g == 0 else clampi(fps_g, 30, 240)
	ContadorFps.visible_pref = bool(cf.get_value("pantalla", "contador_fps", false))
	p._modo_experto = bool(cf.get_value("juego", "modo_experto", p._modo_experto))
	Sonido.encendido = bool(cf.get_value("sonido", "encendido", Sonido.encendido))

## Escribe el archivo, solo si algo cambió desde la última vez.
##
## La firma es el propio archivo en texto (`encode_to_text()`), no una cadena
## aparte con los mismos campos: antes había dos listas que mantener a la par
## -la firma y los `set_value`- y un ajuste nuevo que se añadiera solo a la
## segunda no se habría guardado nunca por sí solo.
func guardar() -> void:
	var cf := ConfigFile.new()
	cf.set_value("aspecto", "paleta", p._paleta)
	cf.set_value("aspecto", "forma_tarjeta", p._forma_tarjeta)
	cf.set_value("aspecto", "brillo_tarjetas", p._brillo_tarjetas)
	cf.set_value("aspecto", "fondo", p._fondo_elegido)
	cf.set_value("aspecto", "clima", p._clima_elegido)
	cf.set_value("aspecto", "marca_tarjeta", p._marca_tarjeta)
	cf.set_value("aspecto", "tipografia", p._tipografia)
	cf.set_value("aspecto", "estilo_menu", p._estilo_menu)
	cf.set_value("aspecto", "rotar_diseno", p._rotar_diseno)
	cf.set_value("juego", "idioma", Idiomas.idioma)
	cf.set_value("juego", "velocidad_partido", p._velocidad_partido)
	cf.set_value("musica", "encendida", Musica.encendida)
	cf.set_value("musica", "volumen", Musica.volumen)
	cf.set_value("musica", "pieza", Musica.pieza)
	cf.set_value("musica", "automatica", Musica.automatica)
	cf.set_value("aspecto", "clima_interactivo", p._clima_interactivo)
	cf.set_value("texto", "escala", p._escala_texto)
	cf.set_value("texto", "daltonico", p._daltonico)
	cf.set_value("pantalla", "zoom", p._zoom_interfaz)
	cf.set_value("pantalla", "modo_tv", p._modo_tv)
	cf.set_value("pantalla", "ropa_aparte", VestidorQ.ropa_aparte)
	cf.set_value("pantalla", "caras_foto", Cara.usar_fotos)
	cf.set_value("pantalla", "fps", p._fps_elegido)
	cf.set_value("pantalla", "contador_fps", ContadorFps.visible_pref)
	cf.set_value("juego", "modo_experto", p._modo_experto)
	cf.set_value("sonido", "encendido", Sonido.encendido)
	var firma := cf.encode_to_text()
	if firma == _firma:
		return
	_firma = firma
	cf.save(Principal.PREFS)
