class_name EscaparateFrase
extends RefCounted
## LA FRASE DEL DT (17-11-2026): sale del estilo real del entrenador del club, de su táctica (formación, mentalidad, presión, línea) y del objetivo de la liga;
## cuatro plantillas (según el club) para que no sea la misma en todos. Todo pasa por `Idiomas.t`.

const _ESTILOS := {
	"ofensivo": "juego ofensivo y vertical", "defensivo": "bloque bajo y contragolpe",
	"motivador": "garra y carácter", "pizarron": "juego táctico y paciente",
}

static func _meta(p: Principal, c: Club) -> String:
	var puesto := 8
	if p.mundo != null and p.mundo.directiva != null:
		puesto = p.mundo.directiva.meta_puesto
	if puesto <= 3:
		return Idiomas.t("pelear el título")
	return Idiomas.t("clasificar a copas") if puesto <= 8 else Idiomas.t("asegurar la permanencia")

static func de(p: Principal, c: Club, nombre: String) -> String:
	var t: Tactica = c.tactica
	var est := String(Previa.dt_de(c).get("estilo", ""))
	var estilo := Idiomas.t(String(_ESTILOS.get(est, "juego táctico y paciente")))
	var ment := Idiomas.t(["defensiva", "equilibrada", "ofensiva"][clampi(int(t.mentalidad), 0, 2)])
	var pres := Idiomas.t(["repliegue y orden", "presión media", "presión alta"][clampi(int(t.presion), 0, 2)])
	var linea := Idiomas.t(["la línea baja", "la línea media", "la línea alta"][clampi(int(t.linea), 0, 2)])
	var corto := nombre.get_slice(" ", nombre.get_slice_count(" ") - 1) if nombre.find(" ") >= 0 else nombre
	match absi(hash("frase|" + c.id)) % 4:
		0: return Idiomas.t("%s apuesta por el %s con %s.") % [corto, t.formacion, estilo]
		1: return Idiomas.t("Con táctica %s, %s apuesta por %s.") % [ment, corto, estilo]
		2: return Idiomas.t("%s defiende con %s y busca %s.") % [corto, linea, _meta(p, c)]
	return Idiomas.t("%s quiere %s con %s y %s.") % [corto, _meta(p, c), t.formacion, pres]
