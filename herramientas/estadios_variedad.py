"""ESTADIOS CON VARIEDAD GENERADA POR CLUB (10-11-2026, encargo del líder tras la auditoría: «99 perfiles para 1.069 clubes»).
Los clubes cuyo estadio no tiene arquitectura escrita a mano (fila con `rasgo` vacío, focos «torres», fachada «hormigon» y sin pista: la regla fija por aforo de
`importar_pais.py`, `segundas_divisiones.py` y `ligas_completas.py`) salían casi todos como «rect» o «ingles» de 1 a 3 niveles. Aquí se les da, de forma DETERMINISTA
(sale solo del nombre limpio del club, su aforo real y sus colores: misma base, mismos estadios), forma, niveles, techo, focos, fachada, pista, butacas, esquinas abiertas
y colores de fachada y techo, siempre dentro de lo que el constructor del estadio sabe dibujar y de lo que cabe en su aforo.
Lo escrito a mano (estadios reales con su arquitectura) NO se toca. Lo llama `base_ficticia.py` antes de volcar la tabla `ESTADIO_CLUB`."""
import hashlib

FORMAS = {   # por aforo: (hasta, formas posibles)
    "chico": ["dos", "rect", "ingles", "estrecho", "principal", "ingles", "rect"],
    "medio": ["ingles", "rect", "herradura", "cuenco", "asimetrico", "principal", "estrecho", "rect", "oval"],
    "grande": ["cuenco", "oval", "ingles", "rect", "herradura", "asimetrico", "oval"],
    "enorme": ["cuenco", "oval", "caldera", "oval", "cuenco"],
}
TECHOS = {"chico": ["sin", "sin", "parcial", "visera"], "medio": ["parcial", "parcial", "visera", "anillo", "sin", "total"], "grande": ["anillo", "parcial", "total", "anillo", "visera"],
          "enorme": ["anillo", "total", "anillo", "membrana"]}
FOCOS = ["torres", "torres", "torres", "mixto", "corona", "halo", "torres", "mixto"]
FACHADAS = ["hormigon", "hormigon", "hormigon", "hormigon", "metal", "metal", "ladrillo", "vidrio"]
ASIENTOS_P = ["franjas", "liso", "moteado", "degrade", "bicolor", "sectores", "diagonal", "franjas"]
ESQUINAS = ["noreste", "noroeste", "sureste", "suroeste"]


def _h(clave: str, sal: str) -> int:
    return int(hashlib.md5((sal + "|" + clave).encode("utf-8")).hexdigest()[:8], 16)


def _tamano(aforo: int) -> str:
    return "chico" if aforo < 10000 else ("medio" if aforo < 30000 else ("grande" if aforo < 60000 else "enorme"))


def _mezcla(hexa: str, con: str, t: float) -> str:
    a = [int(hexa[i:i + 2], 16) for i in (1, 3, 5)]
    b = [int(con[i:i + 2], 16) for i in (1, 3, 5)]
    return "#%02x%02x%02x" % tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def es_automatico(fila: dict) -> bool:
    return not fila.get("rasgo") and fila.get("focos") == "torres" and fila.get("fachada") == "hormigon" and not fila.get("pista")


def arquitectura(clave: str, aforo: int, c1: str, c2: str) -> dict:
    t = _tamano(aforo)
    forma = FORMAS[t][_h(clave, "forma") % len(FORMAS[t])]
    techo = TECHOS[t][_h(clave, "techo") % len(TECHOS[t])]
    niveles = {"chico": 1, "medio": 1 + _h(clave, "niv") % 2, "grande": 2 + (_h(clave, "niv") % 4 == 0), "enorme": 3 - (_h(clave, "niv") % 4 == 0)}[t]
    if forma in ("dos", "estrecho", "principal"):
        niveles = min(niveles, 2)   # una caja de dos tribunas no sube a tres bandejas
    if forma == "caldera":
        niveles = 3
    pista = t in ("grande", "enorme") and _h(clave, "pista") % 6 == 0
    fachada = FACHADAS[_h(clave, "fachada") % len(FACHADAS)]
    if techo == "membrana":
        fachada = "membrana"
    fila = {"forma": forma, "niveles": int(niveles), "techo": techo, "pista": pista, "focos": FOCOS[_h(clave, "focos") % len(FOCOS)],
            "fachada": fachada, "rasgo": "", "asientoP": ASIENTOS_P[_h(clave, "asientoP") % len(ASIENTOS_P)]}
    ## Colores: la fachada toma un tono apagado del club; el techo, gris claro o el segundo color suavizado.
    if _h(clave, "fcol") % 5 < 2 and fachada in ("hormigon", "metal", "ladrillo"):
        fila["fachadaCol"] = _mezcla(c1, "#bdbdbd", 0.55)
    if _h(clave, "tcol") % 4 == 0 and techo not in ("sin",):
        fila["techoCol"] = _mezcla(c2, "#e8e8e8", 0.65)
    if t == "chico" and forma in ("ingles", "rect") and _h(clave, "esq") % 4 == 0:
        fila["esquinas_abiertas"] = [ESQUINAS[_h(clave, "esqn") % 4]]
    return fila


def aplicar(estadios: dict, datos: dict) -> int:
    """`estadios`: clave limpia -> fila (se cambia en el sitio); `datos`: clave limpia -> (aforo, c1, c2). Devuelve cuántas filas se variaron."""
    n = 0
    for clave, fila in estadios.items():
        if clave in datos and es_automatico(fila):
            aforo, c1, c2 = datos[clave]
            nueva = dict(fila)   # conserva lo que no es arquitectura (escudo, camiseta, butacas del estadio real…)
            nueva.update(arquitectura(clave, int(aforo), c1, c2))
            estadios[clave] = nueva
            n += 1
    return n
