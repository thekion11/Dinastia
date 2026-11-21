// FUNCIONES PURAS DEL NÚCLEO EN C++ (4.ª tanda, 21-11-2026, orden 63). Mismas reglas que `puras_nucleo.cpp`: traducción literal de la
// gemela GDScript `<nombre>_gd`. Las tablas de texto con emojis (remitente_de, paletas_luces) se generaron desde el GDScript.
// Ninguna modifica sus argumentos (las que lo hacen, como `DisparadoresDia._nuevo`, no se portan: la prueba compara dos llamadas).
#include "dinastia_nativo.h"

#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/string.hpp>

#include <cmath>
#include <cstdint>
#include <vector>

using namespace godot;

// `Cesiones.nueva_oferta` (el orden de las claves es el del GDScript)
Dictionary DinastiaNativo::nuc_nueva_oferta(int64_t pedido) const {
	Dictionary d;
	d["fijo"] = (int64_t)std::round((double)pedido * 0.7 / 1000.0) * 1000;
	d["cuotas"] = (int64_t)0;
	d["bonos"] = (int64_t)0;
	d["pct"] = (int64_t)0;
	d["opaco"] = (int64_t)0;
	d["firma"] = (int64_t)0;
	d["clausula"] = false;
	d["intercambio"] = String("");
	return d;
}

// `Idiomas._tiene_letras`
bool DinastiaNativo::nuc_tiene_letras(const String &s) const {
	for (int64_t i = 0; i < s.length(); i++) {
		const int64_t c = (int64_t)s.unicode_at(i);
		if ((c >= 65 && c <= 90) || (c >= 97 && c <= 122) || (c >= 192 && c <= 687)) {
			return true;
		}
	}
	return false;
}

// `IdiomasInverso.normal`
String DinastiaNativo::nuc_normal_titulo(const String &texto) const {
	if (texto.length() < 2 || texto != texto.to_upper() || texto == texto.to_lower()) {
		return texto;
	}
	const String baja = texto.to_lower();
	return baja.substr(0, 1).to_upper() + baja.substr(1);
}

// `MercadoDT._sin_fecha`
Dictionary DinastiaNativo::nuc_sin_fecha(const Dictionary &d) const {
	Dictionary r = d.duplicate(false);
	r.erase("anio");
	r.erase("semana");
	return r;
}

// `Movil.remitente_de`
Array DinastiaNativo::nuc_remitente_de(const String &titulo, const String &cuerpo) const {
	struct Grupo {
		std::vector<String> palabras;
		String nombre;
		String emoji;
	};
	static const std::vector<Grupo> grupos = {
		{ { String::utf8("directiva"), String::utf8("confianza"), String::utf8("junta"), String::utf8("despedido"), String::utf8("presidente") }, String::utf8("Directiva"), String::utf8("🏛️") },
		{ { String::utf8("casa"), String::utf8("familia"), String::utf8("hijo"), String::utf8("pareja"), String::utf8("mascota") }, String::utf8("Familia"), String::utf8("🏠") },
		{ { String::utf8("oferta"), String::utf8("representante"), String::utf8("agente"), String::utf8("renovación"), String::utf8("contrato") }, String::utf8("Tu representante"), String::utf8("🦈") },
		{ { String::utf8("lesión"), String::utf8("lesion"), String::utf8("médico"), String::utf8("medico") }, String::utf8("Cuerpo médico"), String::utf8("🩺") },
	};
	const String t = (titulo + String(" ") + cuerpo).to_lower();
	for (const Grupo &g : grupos) {
		for (const String &p : g.palabras) {
			if (t.contains(p)) {
				Array r;
				r.append(g.nombre);
				r.append(g.emoji);
				return r;
			}
		}
	}
	return Array();
}

// `RecorridosRed.normalizar`
String DinastiaNativo::nuc_normalizar_codigo(const String &texto) const {
	String t = texto.strip_edges().to_upper().replace(" ", "").replace("-", "");
	if (!t.begins_with("PA")) {
		t = String("PA") + t;
	}
	const String cifras = t.substr(2);
	if (cifras.length() < 3 || cifras.length() > 4 || !cifras.is_valid_int()) {
		return "";
	}
	return t;
}

// `PartidoDespedida.por_linea` (lee `pos` de cada Jugador)
Dictionary DinastiaNativo::nuc_por_linea(const Array &lista) const {
	Dictionary n;
	n["POR"] = (int64_t)0;
	n["DEF"] = (int64_t)0;
	n["MED"] = (int64_t)0;
	n["DEL"] = (int64_t)0;
	static const StringName k_pos("pos");
	for (int64_t i = 0; i < lista.size(); i++) {
		Object *j = lista[i];
		const Variant pos = j->get(k_pos);
		n[pos] = (int64_t)n.get(pos, (int64_t)0) + 1;
	}
	return n;
}

// `RoperoDT.aplicar`
Dictionary DinastiaNativo::nuc_ropero_aplicar(const Dictionary &asp, const String &id, const Color &c1, const Color &c2) const {
	Dictionary a = asp.duplicate(false);
	if (id == "camiseta_club") {
		a["ropa"] = "polo";
		a["c_ropa"] = c1.to_html(false);
		a["c_ropa2"] = c2.to_html(false);
		a["manga_corta"] = true;
		a["corbata"] = false;
	} else if (id == "chandal") {
		a["ropa"] = String::utf8("chandal");
		a["c_ropa"] = c1.to_html(false);
		a["c_ropa2"] = c2.to_html(false);
		a["corbata"] = false;
	} else if (id == "bufanda_club") {
		a["bufanda"] = true;
	} else if (id == "gorra_club") {
		a["gorra"] = true;
	} else {
		return Dictionary();
	}
	return a;
}

// `CiudadP1.paletas_luces`
Array DinastiaNativo::nuc_paletas_luces() const {
	static const std::vector<std::pair<String, String>> filas = {
		{ String::utf8("#ffb75e"), String::utf8("Ámbar de sodio") },
		{ String::utf8("#fff4dc"), String::utf8("Blanco cálido") },
		{ String::utf8("#dff0ff"), String::utf8("Blanco frío") },
		{ String::utf8("#7ee0ff"), String::utf8("Cian") },
		{ String::utf8("#ff7ad1"), String::utf8("Magenta") },
		{ String::utf8("#8affa0"), String::utf8("Verde neón") },
		{ String::utf8("#ff6a4a"), String::utf8("Rojo brasa") },
	};
	Array r;
	for (const auto &f : filas) {
		Array par;
		par.append(f.first);
		par.append(f.second);
		r.append(par);
	}
	return r;
}

void DinastiaNativo::_bind_puras4() {
	ClassDB::bind_method(D_METHOD("nuc_nueva_oferta", "pedido"), &DinastiaNativo::nuc_nueva_oferta);
	ClassDB::bind_method(D_METHOD("nuc_tiene_letras", "s"), &DinastiaNativo::nuc_tiene_letras);
	ClassDB::bind_method(D_METHOD("nuc_normal_titulo", "texto"), &DinastiaNativo::nuc_normal_titulo);
	ClassDB::bind_method(D_METHOD("nuc_sin_fecha", "d"), &DinastiaNativo::nuc_sin_fecha);
	ClassDB::bind_method(D_METHOD("nuc_remitente_de", "titulo", "cuerpo"), &DinastiaNativo::nuc_remitente_de);
	ClassDB::bind_method(D_METHOD("nuc_normalizar_codigo", "texto"), &DinastiaNativo::nuc_normalizar_codigo);
	ClassDB::bind_method(D_METHOD("nuc_por_linea", "lista"), &DinastiaNativo::nuc_por_linea);
	ClassDB::bind_method(D_METHOD("nuc_ropero_aplicar", "asp", "id", "c1", "c2"), &DinastiaNativo::nuc_ropero_aplicar);
	ClassDB::bind_method(D_METHOD("nuc_paletas_luces"), &DinastiaNativo::nuc_paletas_luces);
}
