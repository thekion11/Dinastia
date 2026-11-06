// Ver dinastia_nativo.h. Cada función sigue paso a paso a su original en GDScript.
#include "dinastia_nativo.h"
#include "din_tracy.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/variant/vector3i.hpp>

#include <cmath>
#include <unordered_map>
#include <vector>

using namespace godot;

void DinastiaNativo::_bind_methods() {
	ClassDB::bind_method(D_METHOD("rampa", "src", "lut"), &DinastiaNativo::rampa);
	ClassDB::bind_method(D_METHOD("alisado", "pos", "nor", "idx"), &DinastiaNativo::alisado);
	ClassDB::bind_method(D_METHOD("terreno", "ruido", "detalle", "lado", "celdas", "baldosas", "llano_radio", "llano_trans", "alto", "monte", "monte_alto", "monte_radio"), &DinastiaNativo::terreno);
	ClassDB::bind_method(D_METHOD("hierba", "manchas", "semilla"), &DinastiaNativo::hierba);
	ClassDB::bind_method(D_METHOD("tracy_activo"), &DinastiaNativo::tracy_activo);
	ClassDB::bind_method(D_METHOD("tracy_zona_ini", "nombre"), &DinastiaNativo::tracy_zona_ini);
	ClassDB::bind_method(D_METHOD("tracy_zona_fin"), &DinastiaNativo::tracy_zona_fin);
	ClassDB::bind_method(D_METHOD("tracy_fotograma"), &DinastiaNativo::tracy_fotograma);
	ClassDB::bind_method(D_METHOD("once_asignar_libres", "ranuras", "libres", "grupo_de", "orden"), &DinastiaNativo::once_asignar_libres);
}

PackedByteArray DinastiaNativo::rampa(const PackedByteArray &src, const PackedByteArray &lut) const {
	DIN_ZONA("rampa");
	PackedByteArray dst;
	const int64_t n = src.size();
	dst.resize(n * 4);
	if (lut.size() < 256 * 4) {
		return dst;
	}
	const uint8_t *s = src.ptr();
	const uint8_t *l = lut.ptr();
	uint8_t *d = dst.ptrw();
	for (int64_t i = 0; i < n; i++) {
		const int o = int(s[i]) * 4;
		d[i * 4] = l[o];
		d[i * 4 + 1] = l[o + 1];
		d[i * 4 + 2] = l[o + 2];
		d[i * 4 + 3] = l[o + 3];
	}
	return dst;
}

namespace {
struct HashV3i {
	size_t operator()(const Vector3i &v) const {
		return (size_t(uint32_t(v.x)) * 73856093u) ^ (size_t(uint32_t(v.y)) * 19349663u) ^ (size_t(uint32_t(v.z)) * 83492791u);
	}
};
struct IgualV3i {
	bool operator()(const Vector3i &a, const Vector3i &b) const { return a == b; }
};
} // namespace

Array DinastiaNativo::alisado(const PackedVector3Array &pos, const PackedVector3Array &nor, const PackedInt32Array &idx) const {
	DIN_ZONA("alisado");
	const int64_t n = pos.size();
	PackedFloat32Array c0;
	PackedFloat32Array c1;
	c0.resize(n * 4);
	c1.resize(n * 3);
	Array salida;
	if (n == 0) {
		salida.push_back(c0);
		salida.push_back(c1);
		return salida;
	}
	// Soldar los vértices duplicados en las costuras de UV (misma posición).
	std::unordered_map<Vector3i, int, HashV3i, IgualV3i> id_de;
	std::vector<int> soldado(n);
	std::vector<Vector3> unicos;
	for (int64_t i = 0; i < n; i++) {
		const Vector3 r = (pos[i] * real_t(10000.0)).round();
		const Vector3i k(int32_t(r.x), int32_t(r.y), int32_t(r.z));
		auto it = id_de.find(k);
		if (it == id_de.end()) {
			it = id_de.emplace(k, int(unicos.size())).first;
			unicos.push_back(pos[i]);
		}
		soldado[i] = it->second;
	}
	const int64_t m = int64_t(unicos.size());
	std::vector<std::vector<int>> vecinos(m);
	const int64_t ni = idx.size();
	auto tiene = [](const std::vector<int> &v, int x) {
		for (int y : v) {
			if (y == x) {
				return true;
			}
		}
		return false;
	};
	for (int64_t t = 0; t < ni - 2; t += 3) {
		const int a = soldado[idx[t]];
		const int b = soldado[idx[t + 1]];
		const int c = soldado[idx[t + 2]];
		const int pares[3][2] = { { a, b }, { b, c }, { c, a } };
		for (const auto &par : pares) {
			const int u = par[0];
			const int w = par[1];
			if (!tiene(vecinos[u], w)) {
				vecinos[u].push_back(w);
			}
			if (!tiene(vecinos[w], u)) {
				vecinos[w].push_back(u);
			}
		}
	}
	// Taubin: un paso que encoge (lambda) y otro que infla (mu). Como en GDScript: la media en
	// Vector3 (32 bits) y el factor `f` (64 bits) convertido a 32 al multiplicar.
	std::vector<Vector3> p = unicos;
	std::vector<Vector3> q;
	for (int it = 0; it < 110; it++) {
		const double f = (it % 2 == 0) ? 0.62 : -0.5;
		q = p;
		for (int64_t i = 0; i < m; i++) {
			const std::vector<int> &vs = vecinos[i];
			if (vs.empty()) {
				continue;
			}
			Vector3 media;
			for (int v : vs) {
				media += p[v];
			}
			media /= real_t(double(vs.size()));
			q[i] = p[i] + (media - p[i]) * real_t(f);
		}
		p.swap(q);
	}
	// Normales de la superficie alisada.
	std::vector<Vector3> ns(m);
	for (int64_t t = 0; t < ni - 2; t += 3) {
		const int a2 = soldado[idx[t]];
		const int b2 = soldado[idx[t + 1]];
		const int c2 = soldado[idx[t + 2]];
		const Vector3 fn = (p[b2] - p[a2]).cross(p[c2] - p[a2]);
		ns[a2] += fn;
		ns[b2] += fn;
		ns[c2] += fn;
	}
	float *d0 = c0.ptrw();
	float *d1 = c1.ptrw();
	for (int64_t i = 0; i < n; i++) {
		const int w2 = soldado[i];
		const Vector3 nr = i < nor.size() ? nor[i] : Vector3();
		Vector3 sn = ns[w2].normalized();
		if (double(sn.dot(nr)) < 0.0) {
			sn = -sn;
		}
		const double relleno = double((p[w2] - pos[i]).dot(nr));
		d0[i * 4] = sn.x;
		d0[i * 4 + 1] = sn.y;
		d0[i * 4 + 2] = sn.z;
		d0[i * 4 + 3] = float(CLAMP(relleno, -0.035, 0.03));
		d1[i * 3] = nr.x;
		d1[i * 3 + 1] = nr.y;
		d1[i * 3 + 2] = nr.z;
	}
	salida.push_back(c0);
	salida.push_back(c1);
	return salida;
}

// `Jugador.media_en(demarcacion)` sin memoria: media ponderada de los atributos presentes (en el orden de `ks`); sin pesos, o con suma de pesos <= 0, vale `ovr`.
// `val`/`hay` son los atributos del jugador ya leídos (por índice de clave); `ids` dice qué clave de `val` es cada `ks[i]`.
static int64_t media_en_cpp(const std::vector<double> &val, const std::vector<uint8_t> &hay, const std::vector<int> &ids, const PackedFloat64Array &ws, int64_t ovr) {
	if (ids.empty()) {
		return ovr;
	}
	double suma = 0.0;
	double peso_total = 0.0;
	for (size_t i = 0; i < ids.size(); i++) {
		if (hay[ids[i]]) {
			suma += val[ids[i]] * ws[i];
			peso_total += ws[i];
		}
	}
	if (peso_total <= 0.0) {
		return ovr;
	}
	return int64_t(std::round(suma / peso_total)); // int(round(x)): redondeo lejos de cero y luego truncado, como GDScript
}

PackedInt32Array DinastiaNativo::once_asignar_libres(const Dictionary &ranuras, const Array &libres, const Dictionary &grupo_de, const PackedInt32Array &orden) const {
	DIN_ZONA("once_asignar_libres");
	const PackedStringArray puestos = ranuras["puestos"];
	const Array ks_r = ranuras["ks"];
	const Array ws_r = ranuras["ws"];
	const PackedStringArray grupos = ranuras["grupos"];
	const PackedByteArray por_r = ranuras["por"];
	const int64_t n = libres.size();
	const int64_t ns = puestos.size();
	PackedInt32Array res;
	res.resize(ns);
	for (int64_t i = 0; i < ns; i++) {
		res.set(i, -1);
	}
	// Las claves de atributo que piden las ranuras, sin repetir, y para cada ranura el índice de cada una de sus claves.
	std::vector<String> claves;
	std::vector<std::vector<int>> ids_r(ns);
	for (int64_t i = 0; i < ns; i++) {
		const PackedStringArray ks = ks_r[i];
		for (int64_t q = 0; q < ks.size(); q++) {
			int id = -1;
			for (size_t c = 0; c < claves.size(); c++) {
				if (claves[c] == ks[q]) {
					id = int(c);
					break;
				}
			}
			if (id < 0) {
				id = int(claves.size());
				claves.push_back(ks[q]);
			}
			ids_r[i].push_back(id);
		}
	}
	// Cada libre, leído una sola vez.
	std::vector<String> pos_e(n);
	std::vector<int64_t> ovr(n);
	std::vector<Array> sec(n);
	std::vector<double> fa(n);
	std::vector<double> fb(n);
	std::vector<uint8_t> por(n);
	std::vector<String> ge(n);
	std::vector<std::vector<double>> val(n, std::vector<double>(claves.size(), 0.0));
	std::vector<std::vector<uint8_t>> hay(n, std::vector<uint8_t>(claves.size(), 0));
	for (int64_t k = 0; k < n; k++) {
		Object *o = libres[k];
		pos_e[k] = o->get("pos_e");
		ovr[k] = int64_t(o->get("ovr"));
		sec[k] = o->get("pos_sec");
		fa[k] = 0.7 + 0.003 * double(int64_t(o->get("forma")));
		fb[k] = 0.9 + 0.002 * double(int64_t(o->get("moral")));
		por[k] = pos_e[k] == String("POR") ? 1 : 0;
		ge[k] = grupo_de.get(pos_e[k], String(""));
		const Dictionary attr = o->get("atributos");
		for (size_t c = 0; c < claves.size(); c++) {
			const Variant a = attr.get(claves[c], Variant());
			if (a.get_type() != Variant::NIL) {
				val[k][c] = double(a);
				hay[k][c] = 1;
			}
		}
	}
	std::vector<uint8_t> tomado(n, 0);
	for (int64_t oi = 0; oi < orden.size(); oi++) {
		const int i = orden[oi];
		const String puesto = puestos[i];
		const int puesto_por = por_r[i];
		const String grupo_puesto = grupos[i];
		const PackedFloat64Array ws = ws_r[i];
		int64_t mejor_k = -1;
		double mejor_v = -1.0;
		for (int64_t k = 0; k < n; k++) {
			if (tomado[k] == 1 || int(por[k]) != puesto_por) {
				continue;
			}
			double encaja = 1.0;
			const bool su_puesto = pos_e[k] == puesto;
			if (!su_puesto) {
				const bool en_sec = sec[k].has(puesto);
				encaja = en_sec ? 0.94 : 0.86;
				if (!en_sec && grupo_puesto != ge[k]) {
					encaja = 0.62;
				}
			}
			const int64_t me = media_en_cpp(val[k], hay[k], ids_r[i], ws, ovr[k]);
			const int64_t en_puesto = su_puesto ? me : (me < ovr[k] ? me : ovr[k]);
			const double v = ((double(en_puesto) * encaja) * fa[k]) * fb[k];
			if (v > mejor_v) {
				mejor_v = v;
				mejor_k = k;
			}
		}
		if (mejor_k >= 0) {
			tomado[mejor_k] = 1;
			res.set(i, int32_t(mejor_k));
		}
	}
	return res;
}

// ---- Tracy opcional (ver din_tracy.h) ----
#ifdef DIN_TRACY
static std::vector<TracyCZoneCtx> g_zonas_gd;
static std::vector<CharString> g_nombres_gd; // vivos mientras la zona esté abierta (Tracy copia el nombre al abrirla)
bool DinastiaNativo::tracy_activo() const { return true; }
void DinastiaNativo::tracy_zona_ini(const String &nombre) const {
	g_nombres_gd.push_back(nombre.utf8());
	const CharString &n = g_nombres_gd.back();
	const uint64_t loc = ___tracy_alloc_srcloc_name(0, "gdscript", 8, "gdscript", 8, n.get_data(), (size_t)n.length(), 0);
	g_zonas_gd.push_back(___tracy_emit_zone_begin_alloc(loc, 1));
}
void DinastiaNativo::tracy_zona_fin() const {
	if (g_zonas_gd.empty()) {
		return;
	}
	___tracy_emit_zone_end(g_zonas_gd.back());
	g_zonas_gd.pop_back();
	g_nombres_gd.pop_back();
}
void DinastiaNativo::tracy_fotograma() const { ___tracy_emit_frame_mark(nullptr); }
#else
bool DinastiaNativo::tracy_activo() const { return false; }
void DinastiaNativo::tracy_zona_ini(const String &) const {}
void DinastiaNativo::tracy_zona_fin() const {}
void DinastiaNativo::tracy_fotograma() const {}
#endif
