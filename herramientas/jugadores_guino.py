"""LOS JUGADORES CON GUIÑO (26-9-2026).

Pedido del usuario: *"en cada partida los nombres de jugadores cambian; deberían
ser fijos y dar a entender a qué jugador representa, junto a sus medias"*.

La base ficticia no llevaba plantillas: cada partida inventaba los once con la
semilla. Ahora la base trae las MISMAS plantillas que el pack real (puesto,
edad, media y país de cada uno), pero con un nombre de guiño, al estilo de los
juegos de fútbol sin licencia: el nombre de pila se queda y el apellido cambia
dos letras por sonido parecido ("Vidal" -> "Bidar", "Sánchez" -> "Sanchis"),
así se reconoce a quién representa sin ser su nombre.

Todo es determinista (sale del propio nombre): el mismo jugador se llama igual
en todas las partidas y en todas las versiones de la base. Ningún guiño puede
coincidir con un nombre real del pack (se comprueba contra la lista entera).
"""

import hashlib
import re
import unicodedata

## Cambios de consonante por otra que suena parecido (sobre el apellido en
## minúsculas y sin tildes), de la más a la menos natural.
CONSONANTES = [
    (r"v", "b"), (r"b", "v"), (r"ll", "y"), (r"z", "s"), (r"ss", "s"), (r"tt", "t"),
    (r"qu", "k"), (r"c(?=[aou])", "k"), (r"k", "c"), (r"x", "j"), (r"ph", "f"), (r"th", "t"),
    (r"w", "v"), (r"ck", "k"), (r"rr", "r"), (r"ff", "f"), (r"gu(?=[ei])", "g"),
    (r"(?<=.)h", ""), (r"y(?=[aeiou])", "ll"), (r"(?<=[aeiou])s(?=[aeiou])", "z"),
    (r"(?<=[aeiou])d(?=[aeiou])", "t"), (r"(?<=[aeiou])t(?=[aeiou])", "d"),
    (r"(?<=[aeiou])g(?=[aou])", "c"), (r"(?<=[aeiou])p(?=[aeiou])", "b"),
    (r"(?<=[aeiou])n(?=[aeiou])", "ñ"), (r"(?<=[aeiou])l(?=[aeiou])", "r"),
    (r"(?<=[aeiou])r(?=[aeiou])", "l"), (r"(?<=[aeiou])m(?=[aeiou])", "n"),
]
## La vocal que se cambia es la primera DESPUÉS de la inicial: la terminación
## (lo que más se oye) se queda.
VOCALES = {"a": "e", "e": "i", "i": "e", "o": "u", "u": "o"}

PARTICULAS = {"de", "del", "da", "dos", "van", "von", "la", "le", "di", "el", "mc", "mac", "al", "bin", "ben"}


def sin_tildes(s):
    return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")


def _dist(a, b):
    ## Levenshtein corto.
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        cur = [i]
        for j, cb in enumerate(b, 1):
            cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (ca != cb)))
        prev = cur
    return prev[-1]


def _h(s):
    return int(hashlib.md5(s.encode("utf-8")).hexdigest()[:8], 16)


def _capitaliza(orig, nuevo):
    if not nuevo:
        return nuevo
    if orig[:1].isupper():
        return nuevo[0].upper() + nuevo[1:]
    return nuevo


def _vocal(palabra, desde=1):
    for i in range(desde, len(palabra) - 1):
        if palabra[i] in VOCALES:
            return palabra[:i] + VOCALES[palabra[i]] + palabra[i + 1:], i
    return palabra, -1


def guinar_palabra(palabra, semilla):
    """Cambia una palabra (un apellido) en dos letras, por sonido: una consonante
    parecida y la primera vocal interior."""
    base = sin_tildes(palabra).lower()
    if len(base) <= 2:
        return palabra
    actual = base
    aplicables = [r for r in CONSONANTES if re.search(r[0], base)]
    if aplicables:
        ## Entre las dos primeras aplicables elige el nombre (siempre la misma).
        pat, cambio = aplicables[semilla % min(2, len(aplicables))]
        actual = re.sub(pat, cambio, actual, count=1)
    if _dist(actual, base) < 2:
        actual, i = _vocal(actual, 1)
        if _dist(actual, base) < 2:
            actual, _ = _vocal(actual, i + 1 if i >= 0 else 1)
    if _dist(actual, base) < 2:
        actual = actual[:-1] + VOCALES.get(actual[-1], actual[-1]) if actual[-1] in VOCALES else actual + "e"
    return _capitaliza(palabra, actual)


def guinar(nombre, vetados_bajos=frozenset(), extra=0):
    """El nombre de guiño de un jugador real. Nombre de pila intacto; cambia el
    último apellido (o la única palabra si es un nombre de una sola)."""
    partes = nombre.split()
    if not partes:
        return nombre
    semilla = _h(nombre) + extra * 131
    ## La palabra que se cambia: la última que no sea partícula.
    idx = len(partes) - 1
    while idx > 0 and partes[idx].lower() in PARTICULAS:
        idx -= 1
    intento = 0
    while True:
        p = list(partes)
        p[idx] = guinar_palabra(partes[idx], semilla + intento)
        ## Con un solo nombre ("Pepe") o si aun así choca, se toca también otra.
        if len(p) > 1 and (intento > 0 or len(partes) == 1):
            j = 0 if idx != 0 else len(p) - 1
            p[j] = guinar_palabra(partes[j], semilla + 7 * intento)
        res = " ".join(p)
        if res.lower() != nombre.lower() and sin_tildes(res).lower() not in vetados_bajos:
            return res
        intento += 1
        if intento > 6:
            return res + "o"


def tabla_base(reales, clubes, limpiar):
    """`REALES` del pack -> `REALES` de la base: claves con el nombre ficticio
    del club y nombres de guiño. Mismo formato de fila (nombre|pos|edad|media|pais)."""
    vetados = set()
    for filas in reales.values():
        for f in filas:
            vetados.add(sin_tildes(limpiar(f.split("|")[0])).lower())
    veto = frozenset(vetados)
    salida = {}
    usados = set()
    for club, filas in reales.items():
        nombre_club = clubes.get(limpiar(club))
        if nombre_club is None:
            continue
        nuevas = []
        for f in filas:
            partes = f.split("|")
            real = limpiar(partes[0])
            g = guinar(real, veto)
            ## Dos jugadores distintos no pueden quedar con el mismo guiño.
            k = 0
            while g.lower() in usados:
                k += 1
                g = guinar(real, veto, k)
                if k > 12:
                    ## Último recurso: una inicial de segundo nombre.
                    g = g + " " + "ABCDEFGHIJKLMNOPRSTV"[k % 20] + "."
            usados.add(g.lower())
            partes[0] = g
            nuevas.append("|".join(partes))
        salida[nombre_club] = nuevas
    return salida


if __name__ == "__main__":
    for n in ["Arturo Vidal", "Alexis Sánchez", "Fernando de Paul", "Lionel Messi", "Cristiano Ronaldo",
              "Kylian Mbappé", "Erling Haaland", "Claudio Bravo", "Vicente Pizarro", "Pepe", "Vinícius Júnior"]:
        print(n, "->", guinar(n))
