extends "res://ui/principal_p9.gd"
## [Capa 10/19 de `principal.gd`] _cargar_preferencias, _anotar, _noticia_contratos, _sorteo_me_toca, _siguiente_sorteo, _encolar_sorteo … (+2)

func _cargar_preferencias() -> void:
	var cf := ConfigFile.new()
	if cf.load(PREFS) != OK:
		return
	## Cada lectura se valida contra lo que existe HOY. Un archivo de una version
	## vieja puede nombrar una paleta que ya no esta, y quedarse sin colores por
	## eso seria peor que ignorar la linea.
	var p := String(cf.get_value("aspecto", "paleta", _paleta))
	if PALETAS.has(p):
		_paleta = p
	var f := String(cf.get_value("aspecto", "forma_tarjeta", _forma_tarjeta))
	if FORMAS_TARJETA.has(f):
		_forma_tarjeta = f
	_brillo_tarjetas = bool(cf.get_value("aspecto", "brillo_tarjetas", _brillo_tarjetas))
	var fo := String(cf.get_value("aspecto", "fondo", _fondo_elegido))
	## `ROTAR_FONDO` no está en `Fondo.NOMBRES` -es un valor especial, no un
	## fondo-, así que hay que dejarlo pasar aparte o al reabrir el juego se
	## perdería la rotación y volvería a uno fijo.
	if fo == "" or fo == ROTAR_FONDO or Fondo.NOMBRES.has(fo):
		_fondo_elegido = fo
	_rotar_diseno = bool(cf.get_value("aspecto", "rotar_diseno", true))
	var em := String(cf.get_value("aspecto", "estilo_menu", _estilo_menu))
	for e: Array in ESTILOS_MENU:
		if String(e[0]) == em:
			_estilo_menu = em
	var cl := String(cf.get_value("aspecto", "clima", _clima_elegido))
	if FondoAnimado.MODOS.has(cl):
		_clima_elegido = cl
	_clima_interactivo = bool(cf.get_value("aspecto", "clima_interactivo", _clima_interactivo))
	var mt := String(cf.get_value("aspecto", "marca_tarjeta", _marca_tarjeta))
	if MarcaPanel.ESTILOS.has(mt):
		_marca_tarjeta = mt
	var tp := String(cf.get_value("aspecto", "tipografia", _tipografia))
	if TIPOGRAFIAS.has(tp):
		_tipografia = tp
	var idi := String(cf.get_value("juego", "idioma", Idiomas.idioma))
	if idi == "es" or Idiomas.NOMBRES.has(idi):
		Idiomas.idioma = idi
	_velocidad_partido = clampi(int(cf.get_value("juego", "velocidad_partido", _velocidad_partido)), 1, 3)
	Musica.encendida = bool(cf.get_value("musica", "encendida", Musica.encendida))
	Musica.volumen = clampf(float(cf.get_value("musica", "volumen", Musica.volumen)), 0.0, 1.0)
	var mp := String(cf.get_value("musica", "pieza", Musica.pieza))
	if mp == "" or Musica.PIEZAS.has(mp):
		Musica.pieza = mp
	Musica.automatica = bool(cf.get_value("musica", "automatica", Musica.automatica))
	_escala_texto = clampf(float(cf.get_value("texto", "escala", _escala_texto)), 0.7, 1.6)
	_daltonico = bool(cf.get_value("texto", "daltonico", _daltonico))
	_zoom_interfaz = clampf(float(cf.get_value("pantalla", "zoom", _zoom_interfaz)), 0.7, 1.6)
	_modo_tv = bool(cf.get_value("pantalla", "modo_tv", _modo_tv))
	VestidorQ.ropa_aparte = bool(cf.get_value("pantalla", "ropa_aparte", VestidorQ.ropa_aparte))
	Cara.usar_fotos = bool(cf.get_value("pantalla", "caras_foto", Cara.usar_fotos))
	## 0 = «sin límite» (antes el clampi lo volvía 30 al recargar).
	var fps_g := int(cf.get_value("pantalla", "fps", _fps_elegido))
	_fps_elegido = 0 if fps_g == 0 else clampi(fps_g, 30, 240)
	ContadorFps.visible_pref = bool(cf.get_value("pantalla", "contador_fps", false))
	_modo_experto = bool(cf.get_value("juego", "modo_experto", _modo_experto))
	Sonido.encendido = bool(cf.get_value("sonido", "encendido", Sonido.encendido))

func _anotar(titulo: String, cuerpo: String) -> void:
	_bandeja.push_front({"titulo": titulo, "cuerpo": cuerpo, "semana": mundo.semana, "anio": mundo.anio, "leida": false})
	## Lo que pasa también se comenta en Tribuna (las redes del móvil).
	if mundo.redes != null:
		mundo.redes.desde_noticia(mundo, titulo, cuerpo)
	## Y si es cosa de alguien (la directiva, la familia...), te escribe.
	if mundo.movil != null:
		var de := Movil.remitente_de(titulo, cuerpo)
		if not de.is_empty():
			mundo.movil.recibir(String(de[0]), String(de[1]), "%s %s" % [titulo, cuerpo], mundo.anio, mundo.semana)
	if _bandeja.size() > BANDEJA_MAX:
		_bandeja.resize(BANDEJA_MAX)

## Complementa a `_escribir()`, no lo reemplaza: `_escribir()` sigue pintando
## el registro exactamente igual que antes -no se le tocó una línea, cero
## riesgo de que una captura ya verificada cambie de aspecto-, esto solo
## archiva la misma noticia en la bandeja de "Correo" para poder filtrarla y
## marcarla leída más tarde.
func _noticia_contratos(titulo: String, cuerpo: String) -> void:
	_escribir("[color=#c9a227][b]%s[/b][/color] %s" % [titulo, cuerpo])
	_anotar(titulo, cuerpo)

## Solo si tu club está dentro. Es la diferencia entre una ceremonia y un peaje.
func _sorteo_me_toca(d: Dictionary) -> bool:
	var mio := mundo.mi_club()
	if mio == null:
		return false
	if String(d["tipo"]) == "grupos":
		for g: Array in d["grupos"]:
			if g.has(mio):
				return true
		return false
	for par: Array in d["parejas"]:
		if par[0] == mio or par[1] == mio:
			return true
	return false

func _siguiente_sorteo() -> void:
	if _sorteo_abierto or _cola_sorteos.is_empty():
		return
	_sorteo_abierto = true
	var d: Dictionary = _cola_sorteos.pop_front()
	var v := Sorteo.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(v)
	v.terminado.connect(func() -> void:
		v.queue_free()
		_sorteo_abierto = false
		_refrescar()
		_siguiente_sorteo())
	if String(d["tipo"]) == "grupos":
		v.abrir_grupos(String(d["clave"]), d["grupos"], mundo.mi_club())
	else:
		v.abrir_eliminatoria(String(d["clave"]), String(d["ronda"]), d["parejas"], mundo.mi_club())

func _encolar_sorteo(d: Dictionary) -> void:
	if not _sorteo_me_toca(d):
		return
	_cola_sorteos.append(d)
	_siguiente_sorteo()

## El resultado de TU club en SU torneo continental -mismo trato que ya tiene
## `copa` en `_conectar_noticias()`, portado aquí el 14-9-2026-: campeón, ronda
## superada y el premio de pasar de la fase de grupos. `Continental extends
## Copa` hereda las tres señales de siempre; hasta hoy ninguna estaba
## conectada -ganar el trofeo más grande del juego no avisaba de nada-.
func _conectar_mi_continental() -> void:
	var c := mundo.mi_continental()
	if c == null or c.has_meta("_ui_conectado"):
		return
	c.set_meta("_ui_conectado", true)
	c.campeon_proclamado.connect(func(campeon: Club) -> void:
		if campeon == mundo.mi_club():
			Aviso.mostrar(self, "dinero", "🏆", "Campeón de %s" % c.nombre,
				"El trofeo continental es tuyo. Entra el premio de campeón a la caja."))
	c.ronda_terminada.connect(func(nombre_ronda: String, resultados: Array) -> void:
		for r: Dictionary in resultados:
			if r.get("pasa") == mundo.mi_club():
				Aviso.mostrar(self, "dinero", "🎟️", "Pasas de ronda en %s" % c.nombre,
					"%s superada. Cada eliminatoria continental que se gana es premio." % nombre_ronda, "ronda_superada")
				return)
	c.grupos_terminados.connect(func(clasificados: Array) -> void:
		if clasificados.has(mundo.mi_club()):
			Aviso.mostrar(self, "dinero", "🎟️", "Clasificas a cuartos de %s" % c.nombre,
				"Terminas entre los ocho de la fase de grupos: cobras el premio de clasificación.", "ronda_superada"))

## Conecta la cinemática de sorteo (todos los continentales: es un espectáculo,
## no un peaje) y el resultado de TU club en el suyo (ver
## `_conectar_mi_continental()`). Hay que volver a llamarla tras CADA
## resorteo -al tomar el mando y en cada cierre de temporada, ver
## `_nueva_temporada()`-, porque `Continental.sortear()` siempre crea
## instancias NUEVAS: conectar solo la primera vez dejaba sin sorteo visible y
## sin aviso de resultado la Champions/Libertadores desde la segunda temporada
## en adelante. El candado por objeto es necesario además porque `mundo.copa`
## SÍ persiste entre cambios de club -mismo bug ya cazado hoy en
## `federacion.noticia`-: sin él, cada despido/trotamundos/oferta aceptada
## sumaba OTRA conexión sobre el mismo `copa`, y una sola eliminatoria abría la
## MISMA cinemática de sorteo una vez por cada cambio de club de la partida.
func _conectar_sorteos() -> void:
	for k: String in mundo.continentales:
		var t: Continental = mundo.continentales[k]
		if t.has_meta("_ui_conectado_sorteo"):
			continue
		t.set_meta("_ui_conectado_sorteo", true)
		var clave := k
		t.sorteo_grupos.connect(func(grupos: Array) -> void:
			_encolar_sorteo({"tipo": "grupos", "clave": clave, "grupos": grupos}))
		t.sorteo_eliminatoria.connect(func(ronda: String, parejas: Array) -> void:
			_encolar_sorteo({"tipo": "cruces", "clave": clave, "ronda": ronda, "parejas": parejas}))
	if mundo.copa != null and not mundo.copa.has_meta("_ui_conectado_sorteo"):
		mundo.copa.set_meta("_ui_conectado_sorteo", true)
		mundo.copa.sorteo_eliminatoria.connect(func(ronda: String, parejas: Array) -> void:
			_encolar_sorteo({"tipo": "cruces", "clave": "copa", "ronda": ronda, "parejas": parejas}))
	_conectar_mi_continental()
