// LOS BUCLES PESADOS, EN C++ (30-10-2026, rendimiento). Cada función es la traducción LITERAL
// de su versión GDScript (mismas operaciones, mismo orden y misma precisión: float de 64 bits
// donde GDScript usa `float`, de 32 donde usa Vector3), para dar los MISMOS bytes. Las pruebas
// lo comprueban (`pruebas/probar_nativo.tscn`); si la extensión no está (plataforma sin binario),
// el juego usa la versión GDScript (`Nativo` en nucleo/nativo.gd).
#pragma once

#include <godot_cpp/classes/animation.hpp>
#include <godot_cpp/classes/fast_noise_lite.hpp>
#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/random_number_generator.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/aabb.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/transform3d.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/quaternion.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>

namespace godot {

class DinastiaNativo : public RefCounted {
	GDCLASS(DinastiaNativo, RefCounted)

protected:
	static void _bind_methods();

public:
	// `RuidosFondo._con_rampa`: cada gris de `src` pasa a los 4 bytes RGBA de la tabla `lut`.
	PackedByteArray rampa(const PackedByteArray &src, const PackedByteArray &lut) const;
	// `VestidorQ._alisado`: [CUSTOM0, CUSTOM1] de la ropa (suavizado de Taubin).
	Array alisado(const PackedVector3Array &pos, const PackedVector3Array &nor, const PackedInt32Array &idx) const;
	// `TerrenoArreglos.calcular_gd`: las baldosas [vértices, normales, UV] del relieve de la ciudad.
	Array terreno(const Ref<FastNoiseLite> &ruido, const Ref<FastNoiseLite> &detalle, double lado, int celdas,
			int baldosas, double llano_radio, double llano_trans, double alto, const Vector2 &monte, double monte_alto,
			double monte_radio) const;
	// `CityBuilder._imagen_hierba_gd`: la textura de hierba (azar del motor, misma secuencia).
	Ref<Image> hierba(const Ref<Image> &manchas, int64_t semilla) const;
	// `OnceAuto.asignar_gd` (el once automático de `Club.once`, M-469): para cada ranura (en `orden`) el índice del libre que la ocupa (-1 si nadie).
	// `ranuras` = {puestos, ks, ws, grupos, por}; `libres` = los `Jugador` (se leen aquí: pos_e, ovr, pos_sec, atributos, forma, moral); `grupo_de` = {pos_e: grupo}.
	// Calcula `Jugador.media_en` con los mismos pasos (los atributos de cada jugador se leen una sola vez).
	Array once_armar(const Array &plantilla, const Dictionary &ranuras, const Dictionary &grupo_de, const PackedInt32Array &orden) const;
	PackedInt32Array once_asignar_libres(const Dictionary &ranuras, const Array &libres, const Dictionary &grupo_de, const PackedInt32Array &orden) const;
	// `Optimizar.obstaculo_multimalla` (el bucle por instancia de un MultiMesh): los círculos de choque como PackedVector3Array [x, z, radio]. `buf` = el buffer del MultiMesh (`paso` floats por instancia).
	PackedVector3Array obstaculos_multimalla(const Transform3D &nodo_t, const PackedFloat32Array &buf, int64_t paso, int64_t n, const AABB &base, double raiz_y, double min_alto, double max_base,
			const Dictionary &rej, double celda_rej) const;
	// `Partido._elegir_goleador` / `_elegir_asistente` (el sorteo ponderado de un once): índice en `once` del elegido, o -1 si no hay a quién. `r_unit` = la tirada ya hecha ([0,1)); `excluir` = el autor del gol
	// (null en el goleador); `pesos_rol` = el multiplicador de `RolTactico.peso` de cada candidato (vacío = sin roles).
	// `MotorJugable._cuerpos` (visor/motor_jugable_p11.gd, M-391): separa de dos en dos a los jugadores que se pisan (reparto por masa) y frena la velocidad con que se acercan. `jugadores` = los
	// diccionarios del motor ({node, vel, fuerza, aguante, ...}); mueve `node.position` y reescribe `vel`, igual que el GDScript. `minimo` = 2 × radio del cuerpo.
	void cuerpos_motor(const Array &jugadores, double minimo) const;
	// `MotorJugable._mover_fisica_gd` (visor/motor_jugable_p5.gd, 15-11): el movimiento de los 22 (velocidad, giro, empujón, posición, rumbo, inclinación y aguante). Devuelve 4 valores por jugador
	// [válido, velocidad, va_atrás, distancia_al_balón] para el bucle de animación, que sigue en GDScript. `coste_aguante` = [local, visitante] (el coste táctico del sprint).
	// `LeagueGuia._paso_gd`, en dos pasadas: índices de los que deciden clip este paso, y luego guía o marcha de todos ([cortes, guiados]).
	// `MotorLeague._calcular_sin_balon` entero (16-11, nativo/src/sin_balon_nativo.cpp): [destino, velocidad], o [] si hay que seguir en GDScript.
	Array league_calcular_sin_balon(const Array &ctx, const Dictionary &p, bool designado_disputa) const;
	Vector2 sb_destino_forma(const Array &ctx, const Array &equipos, const Dictionary &p, const Vector2 &forma, const String &puesto, const Dictionary &mezcla) const;
	// `MotorJugable._duelos`: parejas de rivales (sin porteros) a 1,3 m o menos, en orden ([i, j, …]; [-1] = más de 64 jugadores).
	PackedInt32Array duelos_parejas(const Array &jugadores) const;
	// `MotorJugable._disputas`: enfriamiento de los 22 y, con el balón suelto, el índice del que lo controla (-1 = nadie).
	int64_t disputas_inicio(const Array &jugadores, double delta, bool suelto, const Vector3 &b, double t, const Variant &pase_a_id, const PackedFloat64Array &arco_z, double area_x, double area_z) const;
	// `MotorColocacion.actualizar`: [más cercano al balón del local, del visitante] (3D, tope 40 m).
	PackedFloat64Array colocacion_cerca(const Array &jugadores, const Vector3 &b) const;
	// `MotorJugable._mover_jugadores`: la animación de los 22 ([código, escala] por jugador; con `aplicar`, también la pone).
	PackedFloat64Array animar_jugadores(const Array &jugadores, const PackedFloat64Array &res, double t, const Variant &poseedor_id, bool cansancio_real, bool league, bool aplicar) const;
	// `LeagueLocomocion._paso`: camino común de los 22 y, en orden, lo que hace GDScript (índice·2 = `_quizas_empezar`, índice·2+1 = `_uno`).
	PackedInt32Array loco_paso(const Array &jugadores, double t, double delta, int64_t poseedor, double recolocar) const;
	// `LeyesPais._ya_cumple`: tope de cupo en cancha y juveniles de la liga.
	bool leyes_ya_cumple(const Array &once, const String &pais, int64_t tope, const Array &juveniles, const String &criterio, const Array &ue, const Dictionary &clubes) const;
	// `Partido.fijar_clima(Clima.del_partido(…))`: [info, factor, factor del visitante].
	Array clima_partido(const String &pais, const String &pais_visita, int64_t semana, int64_t anio, const String &semilla, bool neutral, const Dictionary &globo) const;
	// `Partido.invalidar_fuerza`: `fuerza()` de los dos onces ([local, visitante]).
	Array fuerza_dos(const Array &once_l, const Array &once_v, Object *local, Object *visita, const Array &m) const;
	Dictionary fuerza_una(const Array &once, Object *c, Object *enfrente, const Array &m) const;
	// `Mundo._semana_del_plantel`: la semana de cada jugador del club (mismas tiradas de azar).
	void plantel_semana(const Array &plantilla, int64_t semana_global, int64_t suelo, int64_t semana, int64_t anio, const Ref<RandomNumberGenerator> &rng) const;
	// `LeagueGuia.paso`: pendientes + primera mitad de `decidir` ([índice, sp, rel, sp_des] de los que eligen clip).
	PackedFloat64Array guia_previo(const Array &jugadores, double t, int64_t poseedor) const;
	PackedInt32Array guia_pendientes(const Array &jugadores, double t) const;
	PackedInt32Array guia_seguir(const Array &jugadores, double t, double delta, int64_t usuario, bool marchas) const;
	PackedFloat64Array mover_jugadores_fisica(const Array &jugadores, const Vector3 &bpos, double delta, double t, bool hay_poseedor, const Variant &poseedor_id, bool poseedor_local, double a_max_base,
			double ancho, double largo, double giro_rapido, const PackedFloat64Array &coste_aguante) const;
	// El balón del motor de League (16-11, nativo/src/balon_nativo.cpp): `balon_prediccion` = el bucle de predicción de `MotorLeague._estado_sin_balon` (ya en el sistema de League, `_ls3`);
	// `balon_avanzar` = el bucle de pasos de 10 ms de `MotorLeague._mover_balon` (devuelve [p, vel, giro, resto]). Ambos llaman a la copia de `LeagueNucleo.fuerzas_balon`.
	PackedVector3Array balon_prediccion(const Vector3 &bp0, const Vector3 &bv0, const Dictionary &cfg, bool hay_poseedor, const Vector3 &vel_poseedor, int64_t total, double dt, double radio) const;
	Array balon_avanzar(const Vector3 &p0, const Vector3 &vel0, const Vector3 &giro0, double resto0, double delta, const Dictionary &cfg, const PackedFloat64Array &k) const;
	// La colocación y el historial de League (16-11, nativo/src/league_equipo_nativo.cpp): `LeagueNucleo.posicion_formacion` (con «mezcla» en `e`), `LeagueEquipo.acumular` y `LeagueEquipo.media_f`.
	Vector2 league_posicion_formacion(const Dictionary &e) const;
	Vector2 league_destino_forma(const PackedVector2Array &acum, const Vector2 &foco, const Vector2 &yo, const Vector2 &forma, const String &puesto, double lado, double posesion_desvanecida,
			double ofensividad, double lado_medio, double trampa_x, const Dictionary &mezcla) const;
	PackedVector2Array league_acumular(const PackedVector2Array &hist) const;
	double league_media_f(const PackedFloat32Array &hist, double ms) const;
	// `MotorLeague._mas_cercano_al(punto, local, [], 1)`: índice en `jugadores` del más cercano de un equipo, o -1.
	int64_t league_mas_cercano(const Array &jugadores, const Vector2 &punto, bool local) const;
	// Piezas de `MotorLeague._estado_sin_balon` / `_estado_league`: el más cercano de todos (por la raíz), el índice por id y la línea del penúltimo (`LeagueEquipo.linea_penultimo` con sus `xs`).
	int64_t league_mas_cercano_todos(const Array &jugadores, const Vector2 &punto) const;
	void league_indexar(const Array &jugadores, Dictionary destino) const;
	double league_linea_penultimo(const Array &jugadores, bool local, bool con_vel, double lado_, double balon_x) const;
	// `LeagueToques.alcanza`: la animación (de `por_tipo`, el catálogo del tipo) que antes toca el balón previsto, o {}. `r0`/`r1` = RADIO del tipo; `bono_vel` = 1 − normalizado(vel).
	Dictionary league_alcanza(const Dictionary &por_tipo, double r0, double r1, double bono_vel, const Vector2 &pos, const Vector2 &mirada, double vel, const PackedVector3Array &pred) const;
	// `LeagueNucleo.movimiento_campo` y `LeagueSinBalon.apoyo` (el apoyo ofensivo sin balón, con su campo de fuerzas).
	Vector2 league_movimiento_campo(const Array &campo, const Vector2 &actual, double amortigua) const;
	Vector2 league_apoyo(const Dictionary &e) const;
	// --- estado (agente C) ---
	// El estado por paso del motor de League (16-11, nativo/src/estado_nativo.cpp): `league_estado_base` = ms al balón de los dos equipos, el más cercano de todos y las 4 líneas del penúltimo en una pasada
	// (devuelve 7 valores, ver el .cpp); `league_cercanos_equipos` = `_mas_cercano_al(p, local, [], 1)` de los dos equipos; `league_registrar` = `LeagueEquipo.registrar` + `acumular` + `media_f(lado_hist, 6000)`
	// (devuelve [balon_hist, lado_hist, resto, acum, lado_medio]); `league_interferir_candidatos` = el filtro de `MotorLeague._interferir`.
	PackedFloat64Array league_estado_base(const Array &jugadores, const Vector2 &b, double lado0, double lado1) const;
	PackedInt32Array league_cercanos_equipos(const Array &jugadores, const Vector2 &punto) const;
	Array league_registrar(const PackedVector2Array &balon_hist, const PackedFloat32Array &lado_hist, double resto, const Vector2 &balon, double lado_posesion, double dt) const;
	PackedInt32Array league_interferir_candidatos(const Array &jugadores, bool rival_local, const String &usuario_id, double t, const Vector2 &bola) const;
	PackedInt32Array league_cortar_candidatos(const Array &jugadores, bool local_pasa, const String &usuario_id, double t, const Vector2 &bola) const;   // el filtro de `_cortar_pase`
	PackedInt32Array league_mas_cercanos(const Array &jugadores, const Vector2 &punto, bool local, int64_t cuantos, const PackedStringArray &excluidos) const;   // `_mas_cercano_al` con varios o excluidos (≤ 16 candidatos)
	// --- fin estado (agente C) ---
	// `Partido.simular_minuto()` x 90 de un cruce de la IA que nadie mira (nucleo/partido_rapido.gd): mismo orden de llamadas al azar; los sucesos raros vuelven a GDScript (`ayuda`).
	void simular_90(Object *p, Object *ayuda, const Dictionary &cfg, const Ref<RandomNumberGenerator> &rng, bool azar_propio) const;
	// `Partido._cerrar_notas()` (nucleo/partido.gd): nota final, forma y partidos de cada jugador del cruce, con la misma tirada de azar por jugador (`rng` = `Azar._rng`).
	void cerrar_notas(Object *p, const Ref<RandomNumberGenerator> &rng) const;
	// ¿El generador de azar del motor es el PCG32 que reproduce `simular_90`? (autocomprobación; si no, `simular_90` usa el del motor)
	bool pcg_coincide() const;
	// `Partido._media_linea` x 4 líneas ([POR, DEF, MED, DEL]) de un once (nucleo/partido_p1.gd, `fuerza`).
	PackedFloat64Array medias_linea(const Array &once, const Dictionary &grupo_de, const Dictionary &lateral_de, const Dictionary &banda_de, const Dictionary &impulsos, int64_t minuto, double arenga_mult,
			double ley_ex, const Dictionary &ex_de_mi_club, const String &ex_id) const;
	// LOCOMOCIÓN DE LEAGUE-SOCCER (10-11, league_nativo.cpp): `LeagueMovimiento.elegir` desde la consulta estricta (`grupos` = los cuadrantes de salida
	// {sale, pref, reposo1, clips}; `deseada` ya escalonada; `parado` = velocidad de entrada parado); devuelve el clip elegido (el mismo diccionario) o {}.
	Dictionary league_elegir(const Array &grupos, double sp, double rel, double deseada, bool parado, double mirar, const String &pie) const;
	// `LeagueAuto.legal_gd`: ¿es legal la intermedia (velocidades de entrada y salida como número 0-3, cuerpo de salida y de entrada, dirección)?
	bool league_legal(int64_t vi, int64_t vo, double cuerpo_sale, double cuerpo_ini, double a) const;
	// El bucle de huesos de `LeagueAuto.construir`: rellena `sal` mezclando `a1` y `a2` en `cuadros` (centésimas) con `mezclas` ([bias, orig] por cuadro) y gira la pelvis.
	void league_mezclar(const Ref<Animation> &sal, const Ref<Animation> &a1, const Ref<Animation> &a2, const PackedInt32Array &cuadros, const PackedFloat64Array &mezclas,
			double ang, const Quaternion &giro_padre) const;
	// --- portador (agente B) ---
	// La decisión con balón de League (16-11, nativo/src/league_portador_nativo.cpp): `LeagueNucleo.situacion`, `regate` y `decidir` (con `zona_tiro` = `LeagueNucleo.ZONA_TIRO`).
	Array league_situacion(const Vector2 &pos, const Vector2 &mov, double lado, const Array &rivales) const;
	Array league_regate(const Vector2 &pos, const Vector2 &mov, const Vector2 &mirada, double lado, const Array &cercanos, double mente, double ofensivo, double iman) const;
	Dictionary league_decidir(const Dictionary &yo, const Array &companeros, const Array &rivales, const Vector2 &mov_balon, double posesion, const Ref<RandomNumberGenerator> &azar, int64_t muestras,
			double zona_tiro) const;
	// --- fin portador (agente B) ---
	int64_t elegir_ponderado(const Array &once, const Dictionary &grupo_de, const Dictionary &bases, double base_def, const String &atr, const PackedFloat64Array &pesos_rol, double r_unit, Object *excluir) const;
};

} // namespace godot
