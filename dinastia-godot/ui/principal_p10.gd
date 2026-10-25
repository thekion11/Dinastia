extends "res://ui/principal_p9.gd"
## [Capa 10/17 de `principal.gd`] _anotar, _noticia_contratos, _guardar, _autoguardar_si_toca, _deshacer, _cargar_preferencias … (+5)

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

## EL CICLO DE LA PARTIDA (nueva, cargar, guardar, deshacer) vive en
## `ui/principal/ciclo_partida.gd` (fase 0). Puentes para Opciones y pruebas.
func _guardar() -> void:
	_partida.guardar()

func _autoguardar_si_toca() -> void:
	_partida.autoguardar_si_toca()

func _deshacer() -> void:
	_partida.deshacer()

## LAS PREFERENCIAS viven en `ui/principal/preferencias.gd` (fase 0). Puentes:
## los llaman `_ready()`, Ajustes, Opciones y las pruebas.
func _cargar_preferencias() -> void:
	_prefs.cargar()

func _guardar_preferencias() -> void:
	_prefs.guardar()

## LAS NOTICIAS DEL MUNDO viven en `ui/principal/noticias.gd` (fase 0). Puente:
## lo llaman al cargar, al cambiar de club, al deshacer, las pantallas y las
## pruebas. Se puede llamar varias veces (ver la cabecera de esa clase).
func _conectar_noticias() -> void:
	_noticias.conectar()

## LOS SORTEOS viven en `ui/principal/sorteos.gd` (fase 0). Estos tres son
## puentes: los llaman el resto de capas, las pantallas y las pruebas.
func _conectar_sorteos() -> void:
	_sorteos.conectar()

func _conectar_mi_continental() -> void:
	_sorteos.conectar_mi_continental()

func _encolar_sorteo(d: Dictionary) -> void:
	_sorteos.encolar(d)
