# Física del balón: motor vs. datos reales (3-11)

Alcance: solo fuentes públicas (papers, documentación). NO se usó código decompilado, mapas de memoria ni assets de PES/FIFA
(copyright de Konami/EA; no publicable). `Subarasheese/pes6decomp` no apareció en la búsqueda web; sin URL exacta no se revisó.
Comparación visual con vídeo real: pendiente (no hay vídeo real accesible desde este contenedor).

## Comparación con `visor/balon_3d.gd`
Balón: masa 0,43 kg, radio 0,11 m, ρ aire 1,2 kg/m³, Cd ≈ 0,23 por encima de ~17 m/s (Alam et al., vía Pszota 2020).

| Parámetro | Motor | Real | Veredicto |
|---|---|---|---|
| Gravedad | 9,81 | 9,81 | OK |
| Arrastre | lineal `0,12·v` | cuadrático `≈0,0122·v²` | **Falla fuera de ~10 m/s** |
| Desaceleración a 5 / 10 / 20 / 30 m/s | 0,6 / 1,2 / 2,4 / 3,6 | 0,3 / 1,2 / 4,9 / 11,0 | Tiros fuertes no frenan: demasiado largos y planos |
| Restitución césped | 0,58 | ≈0,5-0,7 en césped; 0,73-0,82 en superficie dura | Plausible |
| Roce rodando | 1,4 m/s² | del orden de 0,5-1 m/s² (sin cifra publicada fiable) | Algo alto, medir con vídeo |
| Magnus | `0,02·(ω×v)` | CL ≈ 0,2-0,3, proporcional a v² | Revisar con la curva real |

## Propuesta (no aplicada; toca el motor y exige recompilar el nativo si hay copia C++)
1. Arrastre cuadrático: `a = -k·|v|·v`, `k ≈ 0,0122`.
2. Subir Magnus proporcionalmente a la velocidad, calibrar con un tiro libre real (curva de ~3-4 m a 25 m).
3. Bajar `ROCE_RODADA` a ~0,8 y medir con vídeo de pases rasos reales.
4. Cubrir con una sección del banco (distancia recorrida en 1 s a 10/20/30 m/s).

## Fuentes
- Carré, Goodwill, Haake 2005: https://eprints.whiterose.ac.uk/11156
- Pszota 2020 (revisión de arrastre): https://ojs.uni-miskolc.hu/index.php/multi/article/download/614/359/2775
- Temperatura y restitución del balón: https://shura.shu.ac.uk/5875
- Mod comunitario de física PES 6 (solo pista): https://mintlify.wiki/angelballay/pes6_game_physics_mod/configuration/inertia-bands
