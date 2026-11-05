extends BaseSO
## ERRORES · entradas inválidas a las funciones públicas más usadas: textos raros en `Idiomas.t`, tablas y países que no existen, semillas
## extremas al generar un mundo. Nada revienta (el lanzador falla ante cualquier SCRIPT ERROR) y los resultados son los neutros esperados.
func _nombre() -> String:
	return "err_entradas_invalidas"

func _probar() -> void:
	_titulo("ERRORES · entradas inválidas [%s]" % sistema())
	_respaldar_user()
	for idi: String in ["es", "de", "tr"]:
		_fijar_idioma(idi)
		var raros := ["", " ", "\n", "%s %d %", "$1 $2", "{x}", "\u0000", "🙂🙂🙂", "ñandú — «»", "A".repeat(20000), "[b]x[/b]", "\\", "%%%%"]
		var todo_bien := true
		for r: String in raros:
			var o := Idiomas.t(r)
			todo_bien = todo_bien and o is String
		_comprobar(todo_bien, "%s: t() acepta %d textos raros y devuelve cadenas" % [idi, raros.size()])
		_comprobar(Idiomas.t("A".repeat(20000)).length() >= 20000, "%s: un texto de 20000 letras vuelve entero" % idi)
	var mal := Idiomas.mayusculas("") == "" and Idiomas.mayusculas("ñ") != ""
	_comprobar(mal, "mayusculas() con vacío y con ñ")
	Idiomas.idioma = "xx"
	_comprobar(Idiomas.t("Plantel") is String, "un idioma desconocido no revienta t()")
	_fijar_idioma("es")
	## Datos
	_comprobar(Datos.tabla("TABLA_QUE_NO_EXISTE") == null or Datos.tabla("TABLA_QUE_NO_EXISTE") is Array, "tabla inexistente → null/vacía")
	_comprobar(not Datos.tiene("TABLA_QUE_NO_EXISTE"), "Datos.tiene() dice que no")
	_comprobar(Datos.grupo("") is String and Datos.grupo("ZZZ") is String, "grupo() con demarcación vacía o inventada")
	## Mundos con parámetros extremos: no revientan.
	for caso in [[["CHI"], 0], [["CHI", "ARG"], -1], [["CHI", "ARG"], 9223372036854775807], [["CHI", "ARG"], 1 << 40]]:
		var m := Mundo.new()
		var paises: Array[String] = []
		paises.assign(caso[0])
		m.generar(paises, caso[1])
		_comprobar(m.ligas.size() > 0, "generar(%s, semilla %d) crea ligas" % [str(caso[0]), caso[1]])
		m.tomar_el_mando(m.ligas[0].clubes[0].id)
		m.avanzar_semana()
		_comprobar(m.mi_club() != null and m.semana >= 1, "…y avanza una semana")
	var sin_paises := Mundo.new()
	var vacio: Array[String] = []
	sin_paises.generar(vacio, 5)
	_comprobar(sin_paises.ligas.size() > 0, "sin países indicados se generan TODOS (valor por defecto de generar): %d ligas" % sin_paises.ligas.size())
	var inventado := Mundo.new()
	var zzz: Array[String] = ["ZZZ"]
	inventado.generar(zzz, 5)
	_comprobar(inventado.ligas.size() == 0, "un país inexistente se ignora (%d ligas)" % inventado.ligas.size())
	_restaurar_user()
