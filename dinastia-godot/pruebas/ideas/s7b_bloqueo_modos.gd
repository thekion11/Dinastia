extends BaseIdea
## s7b · «EL BLOQUEO» DE MODOS (decisión del dueño, 27-10-2026; `DesbloqueoModos`). Apagado por defecto: todo
## abierto. Encendido, los modos de poder y de cargo se ganan con temporadas y títulos de todas tus partidas
## (`Meta`), y los de entrada siguen siempre abiertos. Se prueba sobre un archivo `Meta` aparte.

func _probar() -> void:
	_titulo("S7B: el bloqueo de modos")
	var antes := Meta.ruta
	Meta.ruta = "user://meta_prueba_bloqueo.json"
	if FileAccess.file_exists(Meta.ruta):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.ruta))
	_comprobar(not DesbloqueoModos.activo(), "por defecto está apagado: todo abierto")
	_comprobar(DesbloqueoModos.abierto("jeque") and DesbloqueoModos.abierto("fondo") and DesbloqueoModos.requisito("jeque") == "", "y se puede elegir el Jeque sin haber jugado")
	DesbloqueoModos.fijar_activo(true)
	_comprobar(DesbloqueoModos.activo(), "se enciende desde Ajustes y se guarda")
	for id: String in ["dt", "ayudante", "carrera-m", "retos", "tutorial"]:
		if not DesbloqueoModos.abierto(id):
			_comprobar(false, "el modo de entrada «%s» está siempre abierto" % id)
	_comprobar(not DesbloqueoModos.abierto("dir") and not DesbloqueoModos.abierto("imperio"), "encendido y sin jugar, Director Deportivo y Dueño están cerrados")
	_comprobar(DesbloqueoModos.requisito("dir").contains("temporada") and DesbloqueoModos.requisito("imperio").contains("título"), "y dicen qué falta (%s / %s)" % [DesbloqueoModos.requisito("dir"), DesbloqueoModos.requisito("imperio")])
	var m := Mundo.new()
	m.generar(["CHI"], 7171)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	Meta.fin_de_temporada(m)
	_comprobar(DesbloqueoModos.abierto("dir") and DesbloqueoModos.abierto("interino") and not DesbloqueoModos.abierto("cantera"), "una temporada cerrada abre Director Deportivo e Interino, pero no Cantera")
	Meta.registrar_trofeo(m, "Liga de prueba")
	_comprobar(DesbloqueoModos.abierto("imperio") and not DesbloqueoModos.abierto("jeque"), "el primer título abre Dueño de Club, no el Jeque")
	_comprobar(PantallaModos.jugable({"id": "imperio", "cat": "poder"}) and not PantallaModos.jugable({"id": "jeque", "cat": "poder"}), "el menú de modos lo respeta")
	DesbloqueoModos.fijar_activo(false)
	_comprobar(PantallaModos.jugable({"id": "jeque", "cat": "poder"}), "apagado otra vez, todo abierto")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.ruta))
	Meta.ruta = antes
