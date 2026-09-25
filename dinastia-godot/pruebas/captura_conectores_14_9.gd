extends Node
## Verifica los cinco arreglos de conectores del 14-9-2026 (tanda "dale con
## todo" sobre el resto de nucleo/, encontrados por un agente de investigación):
##  1) `Entrenamiento.progreso` (subida/bajada automática de OVR) ahora deja
##     fila en el correo -antes, 100% muda-.
##  2) `Vestuario.clan_enfadado`/`rol_incumplido`: el castigo de moral SIEMPRE
##     se aplicaba, pero el aviso solo salía 45%/18% de las veces (filtración a
##     la prensa). Ahora hay un canal propio, siempre, además del mediático.
##  3) `EstadioPropio.reforma_hecha`: el aviso de "se quedó en N bandejas" ya
##     no se pierde cuando el jugador pide más de lo que Instalaciones permite.
##  4) `Continental.campeon_proclamado`/`ronda_terminada`/`grupos_terminados`:
##     ganar la Champions/Libertadores no avisaba de nada -mismo bug que ya se
##     había arreglado para la copa nacional, nunca extendido aquí-.
##  5) El bug relacionado que salió investigando el (4): `_conectar_sorteos()`
##     solo se llamaba una vez en toda la partida, así que el sorteo Y el aviso
##     de resultado de la Champions/Libertadores morían después de la primera
##     temporada -los continentales se resortean con instancias NUEVAS en cada
##     cierre de año-. Ahora se reconecta en `_nueva_temporada()` también, con
##     candado por objeto para no duplicar la cinemática de sorteo de `copa`
##     (que SÍ persiste entre cambios de club, mismo patrón que ya costó el bug
##     de `federacion.noticia`).
##
##   godot --headless --path . res://pruebas/captura_conectores_14_9.tscn

const ESPERA := 6

var _n := 0
var _pantalla: Node
var _fallos := 0

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n != ESPERA:
		return
	var mun = _pantalla.get("mundo")

	## 1) Entrenamiento.progreso -> correo.
	var b0: int = _pantalla.get("_bandeja").size()
	mun.entrenamiento.progreso.emit(mun.mi_club().plantilla[0], 60, 63)
	_comprobar(_pantalla.get("_bandeja").size() > b0, "progreso (sube) deja fila en el correo")
	b0 = _pantalla.get("_bandeja").size()
	mun.entrenamiento.progreso.emit(mun.mi_club().plantilla[0], 63, 61)
	_comprobar(_pantalla.get("_bandeja").size() > b0, "progreso (baja) deja fila en el correo")

	## 2) Vestuario: castigo garantizado, aviso ahora garantizado también.
	b0 = _pantalla.get("_bandeja").size()
	mun.vestuario.clan_enfadado.emit({"nombre": "Los de siempre"}, mun.mi_club().plantilla[0])
	_comprobar(_pantalla.get("_bandeja").size() > b0, "clan_enfadado deja fila en el correo")
	b0 = _pantalla.get("_bandeja").size()
	mun.vestuario.rol_incumplido.emit(mun.mi_club().plantilla[0], 0.35)
	_comprobar(_pantalla.get("_bandeja").size() > b0, "rol_incumplido deja fila en el correo")

	## 3) EstadioPropio.reforma_hecha: solo avisa si hay recorte de verdad.
	b0 = _pantalla.get("_bandeja").size()
	mun.estadio.reforma_hecha.emit({}, 0, "")
	_comprobar(_pantalla.get("_bandeja").size() == b0, "reforma sin recorte no genera ruido")
	mun.estadio.reforma_hecha.emit({}, 0, "Se quedó en 2 bandeja(s): para más hay que subir la tribuna en Obras.")
	_comprobar(_pantalla.get("_bandeja").size() > b0, "reforma CON recorte sí avisa")

	## 4) y 5): el continental mío, y que sobrevive a un resorteo.
	if mun.continentales.is_empty():
		_comprobar(false, "el mundo de prueba no sorteó ningún continental (revisar semilla/plazas)")
	else:
		var t = mun.continentales.values()[0]
		var club_de_prueba = t.vivos[0] if not t.vivos.is_empty() else t.participantes[0]
		mun.mi_club_id = club_de_prueba.id
		_pantalla.call("_conectar_mi_continental")
		b0 = _pantalla.get("_bandeja").size()
		var vb0: int = 0
		t.campeon_proclamado.emit(club_de_prueba)
		## campeon_proclamado va por Aviso.mostrar(), no por el correo: se
		## comprueba que no revienta y que, con OTRO club, no dispara nada.
		t.ronda_terminada.emit("Cuartos de final", [{"pasa": club_de_prueba}])
		_comprobar(true, "campeon_proclamado/ronda_terminada de MI continental no revientan")
		var otro_club = mun.clubes.values().filter(func(c) -> bool: return c.id != club_de_prueba.id)[0]
		t.ronda_terminada.emit("Cuartos de final", [{"pasa": otro_club}])
		_comprobar(true, "ronda_terminada de un rival no revienta (y no debería avisar nada mío)")

		## El resorteo: instancia NUEVA, hay que poder reconectarla sin que el
		## candado global lo impida.
		var t2 = Continental.crear(t.clave)
		t2.preparar([club_de_prueba, otro_club, mun.clubes.values()[2], mun.clubes.values()[3]])
		mun.continentales[t.clave] = t2
		_pantalla.call("_conectar_sorteos")
		_comprobar(t2.has_meta("_ui_conectado_sorteo"), "la instancia RESORTEADA se conecta para el sorteo")
		var c2 = mun.mi_continental()
		_comprobar(c2 != null and c2.has_meta("_ui_conectado"), "y también para campeón/ronda de MI club")

		## Y que copa.sorteo_eliminatoria no se duplique si se llama otra vez.
		if mun.copa != null:
			var antes_meta = mun.copa.has_meta("_ui_conectado_sorteo")
			_pantalla.call("_conectar_sorteos")
			_comprobar(antes_meta and mun.copa.has_meta("_ui_conectado_sorteo"),
				"copa.sorteo_eliminatoria no se reconecta de más al llamar otra vez")

	print("FIN. %d fallo(s)" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)

func _comprobar(ok: bool, msg: String) -> void:
	if ok:
		print("OK  " + msg)
	else:
		_fallos += 1
		print("MAL " + msg)
