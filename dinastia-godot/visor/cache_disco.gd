class_name CacheDisco
extends RefCounted
## CACHÉ EN DISCO DE LO QUE SE CONSTRUYE AL ABRIR EL 3D (30-10-2026, rendimiento). Lo que el
## juego arma por código cada vez que arranca (la biblioteca de 349 animaciones de los
## futbolistas: 2,2-2,9 s la primera vez que se abre un estadio) se guarda en `user://cache/` y la
## siguiente sesión se carga en ~0,1 s.
##
## La huella de cada entrada incluye la versión del motor y del juego, el MD5 de los scripts que
## lo construyen y la fecha y el `.import` de los archivos fuente: si cambia cualquiera, la entrada
## vieja no se encuentra y se vuelve a construir (nunca se usa una caché de otro código).
## `DINASTIA_SIN_CACHE=1` la desactiva (para medir o para descartarla al depurar).

const CARPETA := "user://cache/"

static var _huellas: Dictionary = {}

static func activa() -> bool:
	return OS.get_environment("DINASTIA_SIN_CACHE") != "1"

## Huella de un grupo de archivos (scripts y fuentes). Se calcula una vez por sesión.
static func huella(grupo: String, archivos: PackedStringArray) -> String:
	if _huellas.has(grupo):
		return _huellas[grupo]
	var partes := PackedStringArray([Engine.get_version_info()["string"],
		str(ProjectSettings.get_setting("application/config/version", ""))])
	for a in archivos:
		partes.append(a)
		if FileAccess.file_exists(a):
			partes.append(FileAccess.get_md5(a))
			partes.append(str(FileAccess.get_modified_time(a)))
		if FileAccess.file_exists(a + ".import"):
			partes.append(FileAccess.get_md5(a + ".import"))
	var h := "|".join(partes).md5_text()
	_huellas[grupo] = h
	return h

## Los scripts de una carpeta cuyo nombre empieza por `prefijo` (para la huella).
static func scripts(carpeta: String, prefijos: PackedStringArray) -> PackedStringArray:
	var r := PackedStringArray()
	for f in DirAccess.get_files_at(carpeta):
		var nombre := f.trim_suffix(".remap")
		if not (nombre.ends_with(".gd") or nombre.ends_with(".gdc")):
			continue
		for p in prefijos:
			if nombre.begins_with(p):
				r.append(carpeta.path_join(nombre))
				break
	r.sort()
	return r

static func _ruta(clave: String) -> String:
	return CARPETA + clave.md5_text() + ".res"

## El recurso guardado con esa clave, o null si no hay (o no es del tipo esperado).
static func cargar(clave: String, tipo: String) -> Resource:
	if not activa():
		return null
	var ruta := _ruta(clave)
	if not FileAccess.file_exists(ruta):
		return null
	var r := ResourceLoader.load(ruta, tipo, ResourceLoader.CACHE_MODE_IGNORE)
	return r if r != null and r.is_class(tipo) else null

## Guarda el recurso (a un temporal y luego renombra: un cierre a medias no deja un archivo roto).
static func guardar(clave: String, r: Resource) -> void:
	if not activa() or r == null:
		return
	DirAccess.make_dir_recursive_absolute(CARPETA)
	var ruta := _ruta(clave)
	var tmp := ruta.get_basename() + ".tmp.res"
	if ResourceSaver.save(r, tmp, ResourceSaver.FLAG_COMPRESS) == OK:
		DirAccess.rename_absolute(tmp, ruta)
	else:
		DirAccess.remove_absolute(tmp)

## IMÁGENES (30-10-2026): PNG sin pérdida. Guardar se hace en otro hilo (no frena el juego).
static func _ruta_png(clave: String) -> String:
	return CARPETA + clave.md5_text() + ".png"

static func cargar_imagen(clave: String) -> Image:
	if not activa():
		return null
	var ruta := _ruta_png(clave)
	if not FileAccess.file_exists(ruta):
		return null
	return Image.load_from_file(ruta)

static func guardar_imagen(clave: String, img: Image) -> void:
	if not activa() or img == null or img.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(CARPETA)
	var ruta := _ruta_png(clave)
	var copia := img.duplicate() as Image
	WorkerThreadPool.add_task(func() -> void:
		if copia.save_png(ruta + ".tmp") == OK:
			DirAccess.rename_absolute(ruta + ".tmp", ruta))

