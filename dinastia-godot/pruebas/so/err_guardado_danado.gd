extends BaseSO
## ERRORES · guardado dañado de todas las formas que da un disco, una descarga cortada o un móvil sin batería: vacío, truncado, un bit cambiado,
## basura, cabecera con tamaño absurdo, JSON roto con firma válida. Ninguno cuelga ni revienta: se tira de la copia anterior (.bak) o se
## devuelve «sin partida» (null). Idéntico en todos los sistemas (solo cambia dónde está user://).
func _nombre() -> String:
	return "err_guardado_danado"

const RANURA := "prueba_so_danado"

func _escribir(ruta: String, bytes: PackedByteArray) -> void:
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	f.store_buffer(bytes)
	f.close()

func _probar() -> void:
	_titulo("ERRORES · guardado dañado [%s]" % sistema())
	var m := _mundo(20261105)
	Partida.borrar(RANURA)
	_comprobar(Partida.guardar(m, RANURA), "guardado inicial")
	m.avanzar_semana()
	_comprobar(Partida.guardar(m, RANURA), "segundo guardado (queda la copia de la semana anterior)")
	var ruta := Partida.ruta_de(RANURA)
	var bueno := FileAccess.get_file_as_bytes(ruta)
	_comprobar(bueno.size() > 1000, "el guardado ocupa %d bytes" % bueno.size())
	var casos := {}
	casos["vacío"] = PackedByteArray()
	casos["3 bytes"] = PackedByteArray([68, 73, 78])
	casos["truncado a la mitad"] = bueno.slice(0, bueno.size() / 2)
	var bit := bueno.duplicate()
	bit[bit.size() / 2] = bit[bit.size() / 2] ^ 0x10
	casos["un bit cambiado"] = bit
	var basura := PackedByteArray()
	basura.resize(5000)
	for i in basura.size():
		basura[i] = (i * 73 + 11) % 256
	casos["basura"] = basura
	var gigante := bueno.duplicate()
	gigante.encode_u32(4, 0x7fffffff)
	casos["tamaño declarado absurdo"] = gigante
	for caso: String in casos:
		_escribir(ruta, casos[caso])
		var t0 := Time.get_ticks_msec()
		var n := Partida.cargar(RANURA)
		var ms := Time.get_ticks_msec() - t0
		_comprobar(ms < 5000, "%s: no se cuelga (%d ms)" % [caso, ms])
		_comprobar(n != null and n.mi_club() != null, "%s: se recupera de la copia anterior" % caso)
		_comprobar(Partida.cargada_de_respaldo, "%s: avisa de que cargó el respaldo" % caso)
	## Sin copias y roto: «sin partida», no un mundo a medias.
	Partida.borrar(RANURA)
	_escribir(ruta, basura)
	_comprobar(Partida.cargar(RANURA) == null, "roto y sin copias → null")
	## JSON roto pero con firma y tamaño válidos.
	var crudo := "{\"version\": 2, \"semana\": ".to_utf8_buffer()
	_comprobar(PartidaArchivo.escribir(ruta, crudo), "se puede escribir un JSON roto bien firmado")
	_comprobar(Partida.cargar(RANURA) == null, "JSON roto con firma válida → null")
	## Ranura que no existe.
	_comprobar(Partida.cargar("no_existe_" + RANURA) == null, "ranura inexistente → null")
	Partida.borrar(RANURA)
