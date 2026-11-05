extends BaseSO
## ERRORES · poca memoria simulada: el sistema avisa (`NOTIFICATION_OS_MEMORY_WARNING`, que Android/iOS mandan de verdad) y el juego baja solo la
## calidad al mínimo; pasar a segundo plano y volver (pausa/reanudar) deja el árbol como estaba; y un guardado enorme no se carga si la
## cabecera declara más de lo permitido (tope contra memoria absurda). El aviso se manda a mano porque en PC no llega.
func _nombre() -> String:
	return "err_poca_memoria"

func _probar() -> void:
	_titulo("ERRORES · poca memoria y segundo plano [%s]" % sistema())
	_respaldar_user()
	var antes: int = Calidad.elegida
	Calidad.elegida = Calidad.MEDIO
	VidaGlobal.notification(Node.NOTIFICATION_OS_MEMORY_WARNING)
	_comprobar(Calidad.elegida == Calidad.MINIMO, "ante el aviso de poca memoria la calidad pasa a MÍNIMA (era %d)" % antes)
	## Segundo plano → vuelta (solo cambia el árbol en móvil; en PC no debe tocarlo).
	var pausado0 := get_tree().paused
	VidaGlobal.forzar_movil = true
	VidaGlobal.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_comprobar(get_tree().paused, "en móvil, pasar a segundo plano pausa el árbol")
	VidaGlobal.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await _frames(4)
	_comprobar(get_tree().paused == pausado0, "al volver, el árbol se reanuda")
	VidaGlobal.forzar_movil = false
	if not OS.has_feature("mobile"):
		VidaGlobal.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		_comprobar(not get_tree().paused, "en %s pasar a segundo plano NO pausa (solo el móvil)" % sistema())
		VidaGlobal.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		await _frames(3)
	## Cabecera con tamaño absurdo: se rechaza sin reservar memoria.
	var b := PartidaArchivo.MAGIA.to_ascii_buffer()
	b.resize(40)
	b.encode_u32(4, PartidaArchivo.MAX_CRUDO + 1)
	_comprobar(PartidaArchivo.desempaquetar(b).is_empty(), "un guardado que declara más de %d MB se rechaza" % (PartidaArchivo.MAX_CRUDO / 1048576))
	var enorme := PackedByteArray()
	enorme.resize(30)
	enorme.encode_u32(0, 0x7fffffff)
	_comprobar(PartidaArchivo.desempaquetar(enorme).is_empty(), "y también el formato viejo con tamaño gigante")
	## La memoria estática del proceso cabe en el tope del sistema (móvil: 1 GB como máximo en este punto del arranque).
	var mb := OS.get_static_memory_usage() / 1048576.0
	var tope := float(por_so({"movil": 1024, "web": 1024, "defecto": 4096}))
	_comprobar(mb < tope, "memoria estática %.0f MB < %.0f MB propio de %s" % [mb, tope, sistema()])
	Calidad.elegida = antes
	_restaurar_user()
