#!/usr/bin/env python3
"""LO COMÚN A `ligas_completas.py` Y `segundas_divisiones.py` (13-11-2026, pulido de código: estaba copiado en los dos, 49 líneas
duplicadas según SonarCloud). Aquí viven `UNLEET`, `limpio` (el mismo algoritmo que `base_ficticia.limpiar`, copiado para no importar
circularmente), `quitar_clubes` / `anadir_clubes` (lo que hace `asegurar` en `ligas_completas`) y `estadios_por_aforo`."""

# Nombre real limpio (sin dígitos) -> ficticio; `base_ficticia.py` lo suma a `CLUBES`.
UNLEET = {"0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "8": "b", "9": "g"}


def limpio(n):
    """Mismo algoritmo que `base_ficticia.limpiar` (copiado para no importar circularmente)."""
    def letra(c):
        u = ord(c)
        return (65 <= u <= 90) or (97 <= u <= 122) or (0xC0 <= u <= 0x17F)
    o = ""
    for i, c in enumerate(n):
        if c in UNLEET and ((i > 0 and letra(n[i - 1])) or (i + 1 < len(n) and letra(n[i + 1]))):
            o += UNLEET[c]
        else:
            o += c
    return o


def asegurar_clubes(real: dict, quitar: dict, nuevos: list) -> None:
    """Quita de cada liga los clubes de `quitar` y añade al final los de `nuevos` que faltan (idempotente)."""
    fuera = {limpio(n) for l in quitar.values() for n in l}
    for pais, d in real["PAISES_LIGAS"].items():
        d["clubes"] = [f for f in d["clubes"] if limpio(f[0]) not in fuera]
    for tabla in ("REALES", "EQUIP_REAL"):
        for k in [k for k in real.get(tabla, {}) if limpio(k) in fuera]:
            del real[tabla][k]
    for pais, nombre, _fic, c1, c2, media, aforo, _f, _e in nuevos:
        clubes = real["PAISES_LIGAS"][pais]["clubes"]
        if all(limpio(f[0]) != limpio(nombre) for f in clubes):
            clubes.append([nombre, c1, c2, media, aforo])


def estadios_por_aforo(nuevos: list) -> dict:
    """Arquitectura del estadio de cada club nuevo, según su aforo (clave = nombre real limpio) para `estadios_reales.ESTADIOS`."""
    from estadios_reales_p2 import e
    sal = {}
    for f in nuevos:
        aforo = f[6]
        niv = 1 if aforo < 15000 else (2 if aforo < 40000 else 3)
        forma = "ingles" if aforo < 8000 else ("rect" if aforo < 40000 else "oval")
        techo = "sin" if aforo < 8000 else ("parcial" if aforo < 40000 else "anillo")
        sal[limpio(f[1])] = e(forma, niv, techo, False, "torres", "hormigon", "")
    return sal
