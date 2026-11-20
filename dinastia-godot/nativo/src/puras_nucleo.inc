	// --- funciones puras del núcleo (20-11-2026, orden 63; nativo/src/puras_nucleo.cpp). Cada una = su gemela `<nombre>_gd` en GDScript. ---
	static void _bind_puras();
	int64_t nuc_cuota_francesa(int64_t deuda, double tasa, int64_t cuotas) const;
	Array nuc_pascua(int64_t anio) const;
	bool nuc_es_avenida_columna(int64_t i) const;
	bool nuc_es_avenida_fila(int64_t j) const;
	bool nuc_agente_aprieta(int64_t clientes, int64_t confianza) const;
	double nuc_por_edad(int64_t edad) const;
	int64_t nuc_alcanza(int64_t prestigio) const;
	double nuc_puntos_mundial(double nota, int64_t goles, int64_t asist, int64_t titulos) const;
	int64_t nuc_xp_para(int64_t n) const;
	int64_t nuc_clave_dia(int64_t anio, int64_t semana, int64_t dia) const;
	int64_t nuc_abs_semana(int64_t anio, int64_t semana) const;
	int64_t nuc_mes_de(int64_t semana) const;
	Array nuc_orden_de_semillas(int64_t n) const;
	int64_t nuc_socios_de(int64_t aforo, int64_t rep) const;
	int64_t nuc_rr(int64_t n) const;
	String nuc_puesto_de(double x, double y) const;
	bool nuc_es_letra(int64_t c) const;
	int64_t nuc_techo_tope(int64_t techo, int64_t ovr) const;
	int64_t nuc_delta_de(int64_t peso, bool cumplido) const;
	int64_t nuc_hueco(int64_t minuto, int64_t minuto_fin, int64_t restantes) const;
	double nuc_prob_tiro_3d(double dist, double lateral, bool tapada, double tiro_attr) const;
	double nuc_cuota(double p) const;
	double nuc_curva_hora(int64_t hora) const;
	int64_t nuc_delegacion(int64_t rep) const;
	double nuc_dir_equipo(int64_t eq) const;
	bool nuc_toca_olimpicos(int64_t anio) const;
	// --- fin funciones puras ---
