// EL TRÁFICO DE LA CIUDAD 3D, EN C++ (18-11-2026, orden del dueño: la ciudad a C++, sin tocar lo visual).
// Traducción LITERAL de `TraficoCiudad._process` (visor/trafico_ciudad.gd) y de sus auxiliares: `Ruta.en`, `_rejilla_paso`,
// `_cede_paso`, `_en_hueco`, `_lateral`, `_mirar_delante`, `_esquivar`, `tapa_al_jugador`, `sirena_cerca`, `_colocar` y la parte
// numérica de `MovimientoNatural.marcha/girar`. Mismas operaciones en el mismo orden y misma precisión (float de 64 bits donde
// GDScript usa `float`; de 32 donde usa Vector2/Vector3) y MISMO ORDEN de llamadas a `randf()` (comparte el azar global del motor).
// Lo que sigue en GDScript (animaciones, gestos, semáforos, mirada) se llama de vuelta con `call`. La versión GDScript
// (`_paso_gd`) se queda de respaldo (Android/Web sin binario) y de referencia: `pruebas/probar_nativo_ciudad.tscn`.

#include "dinastia_nativo.h"
#include "trafico_comun.h"

#include <godot_cpp/variant/utility_functions.hpp>

#include <cmath>

using namespace godot;
using namespace godot::trafico;

// Copia en caché de `_controles` por instancia de TraficoCiudad: se rehace si cambia `_ver_controles` o el número de rutas con controles.
const std::vector<Ctl> *Paso::controles_de(int64_t ruta) {
	struct Cache {
		int64_t ver = -1;
		int64_t n = -1;
		std::unordered_map<int64_t, std::vector<Ctl>> por_ruta;
	};
	static std::unordered_map<uint64_t, Cache> cache;
	Cache &c = cache[uint64_t(tr->get_instance_id())];
	if (c.ver != ver_controles || c.n != int64_t(controles.size())) {
		c.por_ruta.clear();
		const Array claves = controles.keys();
		for (int64_t i = 0; i < claves.size(); i++) {
			const Array lista = controles[claves[i]];
			std::vector<Ctl> v;
			v.reserve(size_t(lista.size()));
			for (int64_t j = 0; j < lista.size(); j++) {
				const Dictionary d = lista[j];
				v.push_back({ double(d["s"]), int64_t(d["eje"]) });
			}
			c.por_ruta[int64_t(claves[i])] = v;
		}
		c.ver = ver_controles;
		c.n = int64_t(controles.size());
	}
	auto it = c.por_ruta.find(ruta);
	return it == c.por_ruta.end() ? nullptr : &it->second;
}

void Paso::cargar_estado() {
	static std::unordered_map<uint64_t, Est> cache;
	est = &cache[uint64_t(tr->get_instance_id())];
	if (est->ver != ver_estado) {
		*est = Est();
		est->ver = ver_estado;
	}
	const int64_t n = vehiculos.size();
	for (int64_t i = int64_t(est->alto.size()); i < n; i++) {
		const Dictionary v = vehiculos[i];
		est->dt.push_back(double(v.get(k.dt, 0.0)));
		est->alto.push_back(double(v[k.alto]));
		est->lod.push_back(int8_t(int64_t(v.get(k.lod, 0))));
		est->tdt.push_back(v.has(k.dt) ? 1 : 0);
		est->tlod.push_back(v.has(k.lod) ? 1 : 0);
	}
}

void Paso::paso(double delta_real, bool hay_cam, const Vector3 &ojo, const Vector3 &adelante, bool hay_jugador, const Vector3 &pj, int64_t cuadro) {
	rejilla_paso(hay_cam, ojo);
	const int64_t n = vehiculos.size();
	for (int64_t idx = 0; idx < n; idx++) {
		Dictionary v = vehiculos[idx];
		if (bool(v.get(k.oculto, false))) {
			continue;
		}
		const int64_t nivel = est->lod[size_t(idx)];
		if (nivel > 0 && (idx + cuadro) % (nivel == 1 ? 3 : 12) != 0) {
			est->dt[size_t(idx)] += delta_real;
			est->tdt[size_t(idx)] = 1;
			continue;
		}
		const double delta = delta_real + est->dt[size_t(idx)];
		est->dt[size_t(idx)] = 0.0;
		est->tdt[size_t(idx)] = 1;
		if (hay_cam) {
			Node3D *nv = nodo_de(v, k);
			if (nv != nullptr) {
				const Vector3 q = nv->get_position();
				const double ax = std::abs(double(q.x) - double(ojo.x));
				const double az = std::abs(double(q.z) - double(ojo.z));
				const double lejos = ax > az ? ax : az;
				const int64_t nl = lejos < 150.0 ? 0 : (lejos < 260.0 ? 1 : 2);
				pausar_anim(v, nl == 2 || double(adelante.dot(q - ojo)) < -3.0);
				est->lod[size_t(idx)] = int8_t(nl);
				est->tlod[size_t(idx)] = 1;
			}
		}
		if (gf(v, k.espera, 0.0) > 0.0) {
			v[k.espera] = double(v[k.espera]) - delta;
			if (double(v[k.espera]) <= 0.0 && v.has(k.pausa)) {
				v.erase(k.pausa);
				tr->call("_cb_peaton_reanuda", v);
			}
			continue;
		}
		const bool es_peaton = bool(v.get(k.peaton, false));
		if (es_peaton && UtilityFunctions::randf() < 0.0004 * delta * 60.0 * gf(v, k.rut_pausa, 1.0)) {
			v[k.espera] = UtilityFunctions::randf_range(3.0, 9.0);
			v[k.pausa] = true;
			tr->call("_cb_peaton_espera", v, UtilityFunctions::randf());
			continue;
		}
		double avance = double(v[k.vel]) * delta;
		if (gf(v, k.susto, 0.0) > 0.0) {
			v[k.susto] = double(v[k.susto]) - delta;
			avance *= SUSTO_PASO;
		}
		const int64_t ruta_i = int64_t(v[k.ruta]);
		const double s0 = double(v[k.s]);
		const double largo = ruta(ruta_i).largo;
		bool frena = false;
		const bool suave = !es_peaton;
		double vact = gf(v, k.vact, double(v[k.vel]));
		double tope = INFINITY;
		double aterriza = -1.0;
		double mira = 12.0;
		if (suave) {
			const double m2 = vact * vact / (2.0 * PLAN) + 2.0;
			mira = 12.0 > m2 ? 12.0 : m2;
		}
		const std::vector<Ctl> *cs = semaforos != nullptr ? controles_de(ruta_i) : nullptr;
		if (cs != nullptr) {
			for (const Ctl &c : *cs) {
				const double d = Math::fposmod(c.s - s0, largo);
				const bool visto = suave ? d < mira : (d < avance + 0.5 && d < 12.0);
				const int64_t eje = c.eje;
				// `peatonal` y `verde` no tienen efectos: solo se consultan si el control está a la vista (el resultado es el mismo).
				bool libre = true;
				if (visto) {
					static const StringName n_peatonal("peatonal"), n_verde("verde");
					libre = es_peaton ? String(semaforos->call(n_peatonal, eje)) == "v" : bool(semaforos->call(n_verde, eje));
				}
				if (visto && !libre) {
					if (es_peaton && !bool(v.get(k.pidio, false))) {
						v[k.pidio] = true;
						semaforos->call("pulsa_npc", eje);
						tr->call("_gesto", v, String("saludo_mano"));
					}
					const double r0 = d - 0.3 > 0.0 ? d - 0.3 : 0.0;
					avance = suave ? (avance < r0 ? avance : r0) : r0;
					const double tp = std::sqrt(2.0 * PLAN * r0);
					tope = tope < tp ? tope : tp;
					frena = true;
					break;
				}
			}
		}
		if (es_peaton && !frena) {
			v.erase(k.pidio);
		}
		if (suave && !sirenas.is_empty()) {
			Node3D *nn = nodo_de(v, k);
			if (nn != nullptr) {
				Vector3 pp, dd;
				ruta_en(ruta(ruta_i), s0, pp, dd);
				if (sirena_cerca(nn->get_position(), dd, vact)) {
					tope = 0.0;
					frena = true;
				}
			}
		}
		if (v.has(k.faros) && bool(v[k.frena]) != frena) {
			v[k.frena] = frena;
			luz_freno(v, frena ? 1.0 : 0.0);
		}
		if (v.has(k.paradas)) {
			const Array ps = Variant(v[k.paradas]);
			for (int64_t pi = 0; pi < ps.size(); pi++) {
				const double d2 = Math::fposmod(double(ps[pi]) - s0, largo);
				if (suave && d2 < mira) {
					const double r0 = d2 - 0.3 > 0.0 ? d2 - 0.3 : 0.0;
					const double tp = std::sqrt(2.0 * PLAN * r0);
					tope = tope < tp ? tope : tp;
				}
				double umbral = avance;
				if (suave) {
					const double a = 0.35;
					const double b = vact * delta;
					umbral = a > b ? a : b;
				}
				if (d2 < umbral) {
					aterriza = d2 + 0.05;
					avance = d2 + 0.05;
					v[k.espera] = double(v.get(k.espera_parada, 8.0));
					break;
				}
			}
		}
		if (v.has(k.cola)) {
			const Array col = en_cola[ruta_i];
			for (int64_t oi = 0; oi < col.size(); oi++) {
				const Dictionary o = col[oi];
				if (mismo_movil(o, v, k)) {
					continue;
				}
				const double d3 = Math::fposmod(double(o[k.s]) - s0, largo);
				if (d3 < 9.0 + avance) {
					const double r0 = d3 - 8.0 > 0.0 ? d3 - 8.0 : 0.0;
					avance = avance < r0 ? avance : r0;
				}
				if (suave && d3 < mira + 9.0) {
					const double r1 = d3 - 9.0 > 0.0 ? d3 - 9.0 : 0.0;
					const double c2 = double(o.get(k.vact, o[k.vel])) + std::sqrt(2.0 * PLAN * r1);
					tope = tope < c2 ? tope : c2;
				}
			}
		}
		if (es_peaton) {
			lateral(v, delta, VEL_LATERAL);
			mirar_delante(v, s0, delta);
		} else if (v.has(k.lat_obj) || gf(v, k.lat, 0.0) != 0.0) {
			lateral(v, delta, VEL_ADELANTA);
		}
		if (es_peaton && peatones_ruta.has(ruta_i)) {
			const Array pr = peatones_ruta[ruta_i];
			for (int64_t oi = 0; oi < pr.size(); oi++) {
				Dictionary o = pr[oi];
				if (mismo_movil(o, v, k)) {
					continue;
				}
				const double d4 = Math::fposmod(double(o[k.s]) - s0, largo);
				const bool separados = std::abs(gf(v, k.lat, 0.0) - gf(o, k.lat, 0.0)) > SEPARA_LADO;
				if (d4 < 2.5) {
					if (separados) {
						const double a = gf(v, k.t_lat, 0.0);
						v[k.t_lat] = a > 1.0 ? a : 1.0;
						continue;
					}
					if (gf(o, k.espera, 0.0) > 0.0 || gf(o, k.cediendo, 0.0) > 0.0 || double(o[k.vel]) < double(v[k.vel]) * 0.9) {
						esquivar(v, gf(o, k.lat, 0.0), 1.0);
					}
				} else if (Math::fposmod(s0 - double(o[k.s]), largo) < 1.2 && separados) {
					const double a = gf(v, k.t_lat, 0.0);
					v[k.t_lat] = a > 0.5 ? a : 0.5;
				}
				if (d4 < 0.9 + avance && !separados) {
					const double r0 = d4 - 0.9 > 0.0 ? d4 - 0.9 : 0.0;
					avance = avance < r0 ? avance : r0;
					if (gf(o, k.espera, 0.0) <= 0.0 && UtilityFunctions::randf() < 0.004) {
						tr->call("_charlar", v, o);
						avance = 0.0;
					}
				}
			}
		}
		if (hay_jugador && avance > 0.0) {
			Node3D *nodo_v = nodo_de(v, k);
			if (nodo_v != nullptr) {
				const Vector3 np = nodo_v->get_position();
				const Vector3 rel = Vector3(real_t(double(pj.x) - double(np.x)), 0, real_t(double(pj.z) - double(np.z)));
				if (double(rel.length_squared()) < 256.0) {
					Vector3 pp, dir_v;
					ruta_en(ruta(ruta_i), s0, pp, dir_v);
					const bool peaton = es_peaton;
					Node3D *jn = Object::cast_to<Node3D>(jugador);
					if (tapa_al_jugador(np, dir_v, peaton ? 1.25 : 5.7, peaton ? 0.4 : 1.0, pj, double(jn->get_rotation().y), huella)) {
						avance = 0.0;
						if (peaton && double(huella.y) < 0.6) {
							const double lado_j = double(Vector3(dir_v.z, 0, -dir_v.x).dot(rel));
							esquivar(v, gf(v, k.lat, 0.0) + lado_j, lado_j > 0.0 ? -1.0 : 1.0);
						}
					}
				}
			}
		}
		if (avance > 0.0 && cede_paso(v, idx, delta)) {
			avance = 0.0;
			if (v.has(k.faros) && !bool(v[k.frena])) {
				v[k.frena] = true;
				luz_freno(v, 1.0);
			}
		}
		if (suave && delta > 0.0) {
			const double vv = double(v[k.vel]);
			const double objetivo = vv < tope ? vv : tope;
			const double ganancia = tope < vv ? 1.0 / delta : 6.0;
			double a_pedida = (objetivo - vact) * ganancia;
			a_pedida = a_pedida < -FRENADA ? -FRENADA : (a_pedida > ARRANQUE ? ARRANQUE : a_pedida);
			const double a_act = Math::move_toward(gf(v, k.aact, 0.0), a_pedida, TIRON * delta);
			const double nv = vact + a_act * delta;
			vact = nv > 0.0 ? nv : 0.0;
			v[k.aact] = a_act;
			if (avance < vact * delta) {
				vact = avance / delta;
			} else {
				avance = vact * delta;
			}
			if (aterriza >= 0.0) {
				avance = aterriza;
			}
			if (gf(v, k.espera, 0.0) > 0.0) {
				vact = 0.0;
			}
			v[k.vact] = vact;
		}
		if (es_peaton && hay_jugador && nivel == 0) {
			Node3D *nv2 = nodo_de(v, k);
			if (nv2 != nullptr) {
				const Vector3 d = pj - nv2->get_position(); // distance_squared_to(pj) = (pj - pos).length_squared()
				tr->call("_cb_mirada", v, double(d.length_squared()), delta);
			}
		}
		if (es_peaton) {
			avance = marcha(v, avance, double(v[k.vel]) * delta, delta);
		}
		v[k.s] = s0 + avance;
		colocar(v, delta);
	}
}


// `TraficoCiudad._paso_nativo`: el cuerpo entero de `_process` (ver `visor/trafico_ciudad.gd`). `sirenas` = `TraficoCiudad.sirenas`.
void DinastiaNativo::trafico_paso(Object *tr, double delta_real, bool hay_cam, const Vector3 &ojo, const Vector3 &adelante, bool hay_jugador, const Vector3 &pj, const Array &sirenas) const {
	if (tr == nullptr) {
		return;
	}
	Paso p(tr);
	p.vehiculos = tr->get("_vehiculos");
	p.rutas_v = tr->get("_rutas");
	p.rutas.resize(size_t(p.rutas_v.size()));
	p.controles = tr->get("_controles");
	p.ver_controles = int64_t(tr->get("_ver_controles"));
	p.ver_estado = int64_t(tr->get("_ver_estado"));
	p.en_cola = tr->get("_en_cola");
	p.peatones_ruta = tr->get("_peatones_ruta");
	p.semaforos = static_cast<Object *>(tr->get("semaforos"));
	p.jugador = static_cast<Object *>(tr->get("jugador"));
	p.huella = tr->get("jugador_huella");
	p.libre_fn = tr->get("libre_fn");
	const Dictionary lctx = tr->get("libre_ctx");
	if (!lctx.is_empty()) {
		p.ctx_ok = true;
		p.rej_obst = lctx["obst"];
		p.rej_circ = lctx["circ"];
		p.c_radio = double(lctx["radio"]);
		p.c_limite = double(lctx["limite"]);
		p.c_celda_obst = double(lctx["celda_obst"]);
		p.c_celda_circ = double(lctx["celda_circ"]);
		p.c_rio_x = double(lctx["rio_x"]);
		p.c_celda_av = double(lctx["celda_av"]);
		p.c_ancho_av = double(lctx["ancho_av"]);
	}
	p.sirenas = sirenas;
	const int64_t cuadro = int64_t(tr->get("_cuadro")) + 1;
	tr->set("_cuadro", cuadro);
	p.cargar_estado();
	p.paso(delta_real, hay_cam, ojo, adelante, hay_jugador && p.jugador != nullptr, pj, cuadro);
}


// `TraficoCiudad.volcar_estado_nativo`: escribe `lod` y `dt` de cada móvil en su diccionario (solo los que GDScript ya habría creado).
void DinastiaNativo::trafico_volcar(Object *tr) const {
	if (tr == nullptr) {
		return;
	}
	Paso p(tr);
	p.vehiculos = tr->get("_vehiculos");
	p.ver_estado = int64_t(tr->get("_ver_estado"));
	p.cargar_estado();
	for (int64_t i = 0; i < p.vehiculos.size(); i++) {
		Dictionary v = p.vehiculos[i];
		if (p.est->tdt[size_t(i)] != 0) {
			v[p.k.dt] = p.est->dt[size_t(i)];
		}
		if (p.est->tlod[size_t(i)] != 0) {
			v[p.k.lod] = int64_t(p.est->lod[size_t(i)]);
		}
	}
}
