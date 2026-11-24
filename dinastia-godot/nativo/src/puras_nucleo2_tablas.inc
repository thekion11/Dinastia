// `calendario_p1.icono` (generada desde el GDScript: mismas cadenas, mismo orden de casos)
String DinastiaNativo::nuc_icono_calendario(const String &tipo) const {
	if (tipo == String::utf8("fiesta")) {
		return String::utf8("🎉");
	}
	if (tipo == String::utf8("memoria")) {
		return String::utf8("🕯️");
	}
	if (tipo == String::utf8("trabajo")) {
		return String::utf8("🛠️");
	}
	if (tipo == String::utf8("festividad")) {
		return String::utf8("🕊️");
	}
	return String::utf8("📅");
}

// `crisis_caja.concepto` (generada desde el GDScript: mismas cadenas, mismo orden de casos)
String DinastiaNativo::nuc_concepto_crisis(const String &tipo) const {
	if (tipo == String::utf8("multa")) {
		return String::utf8("Multa de la federación");
	}
	if (tipo == String::utf8("patrocinio")) {
		return String::utf8("Recorte del patrocinador");
	}
	return String::utf8("Sobrecoste de obra");
}

// `dialogos_ciudad.grupo` (generada desde el GDScript: mismas cadenas, mismo orden de casos)
String DinastiaNativo::nuc_grupo_dialogo(const String &animo) const {
	if (animo == String::utf8("euforia") || animo == String::utf8("bien")) {
		return String::utf8("pos");
	}
	if (animo == String::utf8("mal") || animo == String::utf8("crisis")) {
		return String::utf8("neg");
	}
	return String::utf8("neu");
}

// `formacion_propia.linea_de` (generada desde el GDScript: mismas cadenas, mismo orden de casos)
String DinastiaNativo::nuc_linea_de(const String &puesto) const {
	if (puesto == String::utf8("POR")) {
		return String::utf8("POR");
	}
	if (puesto == String::utf8("LD") || puesto == String::utf8("LI") || puesto == String::utf8("DFC") || puesto == String::utf8("CAD") || puesto == String::utf8("CAI")) {
		return String::utf8("DEF");
	}
	if (puesto == String::utf8("DC") || puesto == String::utf8("ED") || puesto == String::utf8("EI") || puesto == String::utf8("SD")) {
		return String::utf8("DEL");
	}
	return String::utf8("MED");
}

// `incidentes_ciudad.aviso` (generada desde el GDScript: mismas cadenas, mismo orden de casos)
String DinastiaNativo::nuc_aviso_incidente(const String &tipo) const {
	if (tipo == String::utf8("incendio")) {
		return String::utf8("🔥 Incendio en una calle del centro: salen los bomberos.");
	}
	if (tipo == String::utf8("accidente")) {
		return String::utf8("🚑 Accidente en la calle: salen la ambulancia y la policía.");
	}
	return String::utf8("🚓 Robo en un comercio: la policía va de camino.");
}

// `incidentes_ciudad.resuelto` (generada desde el GDScript: mismas cadenas, mismo orden de casos)
String DinastiaNativo::nuc_resuelto_incidente(const String &tipo) const {
	if (tipo == String::utf8("incendio")) {
		return String::utf8("🔥 El fuego está apagado. Los bomberos vuelven al parque.");
	}
	if (tipo == String::utf8("accidente")) {
		return String::utf8("🚑 Heridos atendidos. La calle vuelve a estar libre.");
	}
	return String::utf8("🚓 La policía detuvo al sospechoso.");
}

// `musica_libre.situacion_libre` (generada desde el GDScript: mismas cadenas, mismo orden de casos)
String DinastiaNativo::nuc_situacion_libre(const String &situacion) const {
	if (situacion == String::utf8("partido") || situacion == String::utf8("final") || situacion == String::utf8("celebracion") || situacion == String::utf8("grada")) {
		return String::utf8("");
	}
	if (situacion == String::utf8("parón") || situacion == String::utf8("paron")) {
		return String::utf8("paron");
	}
	return String::utf8("oficina");
}

// `tipo_titulo.nombre_escena` (generada desde el GDScript: mismas cadenas, mismo orden de casos)
String DinastiaNativo::nuc_nombre_escena(const String &e) const {
	if (e == String::utf8("escenario")) {
		return String::utf8("🏆 Levantar la copa");
	}
	if (e == String::utf8("palco")) {
		return String::utf8("🎖️ Palco y medallas");
	}
	if (e == String::utf8("fuegos")) {
		return String::utf8("🎆 Escenario y fuegos");
	}
	if (e == String::utf8("sobrio")) {
		return String::utf8("🤝 Abrazo en el centro");
	}
	if (e == String::utf8("foto")) {
		return String::utf8("📸 Foto con el trofeo");
	}
	if (e == String::utf8("manteo")) {
		return String::utf8("🙌 Mantear al DT");
	}
	if (e == String::utf8("champan")) {
		return String::utf8("🍾 Champán en el vestuario");
	}
	if (e == String::utf8("desfile")) {
		return String::utf8("🚌 Desfile en autobús");
	}
	if (e == String::utf8("pasillo")) {
		return String::utf8("👏 Pasillo del rival");
	}
	return e;
}
