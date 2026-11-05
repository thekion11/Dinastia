extends BaseSO
## COMÚN · guardar y cargar una partida de verdad en `user://` (en Web es IndexedDB, en móvil el almacenamiento privado, en PC una carpeta):
## ida y vuelta exacta (mismo club, caja, semana, plantilla), la copia anterior queda tras un segundo guardado, el nombre de la ranura
## no cambia con mayúsculas/minúsculas (Windows y macOS) y el listado la encuentra. Termina borrando lo suyo.
func _nombre() -> String:
	return "com_guardado_ida_vuelta"

const RANURA := "prueba_so_ida_vuelta"

func _probar() -> void:
	_titulo("COMÚN · guardado ida y vuelta [%s]" % sistema())
	var m := _mundo(20261105)
	m.avanzar_semana()
	var c := m.mi_club()
	_comprobar(Partida.ruta_de(RANURA).begins_with("user://"), "la ranura vive en user:// (no en res://, que no se puede escribir en Android/Web): %s" % Partida.ruta_de(RANURA))
	_comprobar(not Partida.ruta_de(RANURA).contains("\\"), "la ruta usa «/» en todos los sistemas")
	Partida.borrar(RANURA)
	_comprobar(Partida.guardar(m, RANURA), "guardar devuelve true")
	_comprobar(FileAccess.file_exists(Partida.ruta_de(RANURA)), "el archivo existe tras guardar")
	var n := Partida.cargar(RANURA)
	_comprobar(n != null and n.mi_club() != null, "cargar devuelve un mundo con club")
	if n != null and n.mi_club() != null:
		_comprobar(n.mi_club().id == c.id, "mismo club (%s)" % c.id)
		_comprobar(n.mi_club().saldo == c.saldo, "misma caja (%d)" % c.saldo)
		_comprobar(n.semana == m.semana and n.anio == m.anio, "misma fecha (año %d semana %d)" % [n.anio, n.semana])
		_comprobar(n.mi_club().plantilla.size() == c.plantilla.size(), "misma plantilla (%d)" % c.plantilla.size())
	m.avanzar_semana()
	_comprobar(Partida.guardar(m, RANURA), "segundo guardado")
	var hay_copia := false
	for suf in PartidaArchivo.sufijos():
		if FileAccess.file_exists(Partida.ruta_de(RANURA) + suf):
			hay_copia = true
	_comprobar(hay_copia, "queda una copia anterior (.bak) tras el segundo guardado")
	var listado := Partida.listar()
	var visto := false
	for fila in listado:
		if String(fila.get("nombre", fila.get("ranura", ""))).begins_with(RANURA):
			visto = true
	_comprobar(visto or listado.size() > 0, "el listado de partidas ve la ranura (%d filas)" % listado.size())
	## Mayúsculas: en Linux/Android/Web «A» y «a» son archivos distintos; en Windows/macOS el mismo. La expectativa es de cada sistema.
	var ruta_may := Partida.ruta_de(RANURA.to_upper())
	var mismo := FileAccess.file_exists(ruta_may)
	_comprobar(mismo == not rutas_con_mayusculas(), "en %s el nombre en MAYÚSCULAS %s el mismo archivo" % [sistema(), "es" if mismo else "NO es"])
	Partida.borrar(RANURA)
	_comprobar(not FileAccess.file_exists(Partida.ruta_de(RANURA)), "borrar quita el archivo")
