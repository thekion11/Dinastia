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

## Anexo: PES 6 como inspiración (solo documentación pública, nada copiado)
Fuente: notas de investigación `docs/ball_physics.md` de Subarasheese/pes6decomp (verificado en la nota con trazas de una partida en PCSX2).
No se copia código ni datos; solo se toman ideas y órdenes de magnitud, convertidos a SI (1 m/s ≈ 1088 unidades de velocidad del juego; 255 unidades/m).

| Aspecto | PES 6 (convertido) | Real | Motor Dinastía |
|---|---|---|---|
| Gravedad | ≈10,4 m/s² (un poco más que real: «peso» de juego) | 9,81 | 9,81 |
| Arrastre aire | **cuadrático**, ≈0,0143·v² | ≈0,0122·v² | lineal 0,12·v |
| Arrastre a alta velocidad | por encima de ≈20,7 m/s resta ≈8,3 m/s a la v usada en el cálculo (modela la «crisis de arrastre» de las costuras) | cae Cd al pasar ~17 m/s | no existe |
| Rebote en césped | 0,53-0,63 según velocidad | ≈0,5-0,7 | 0,58 fijo |
| Pérdida horizontal al botar | 6-15 % y más si cae fuerte | similar | 10 % fijo |
| Sustentación por giro | ∝ v²·giro, solo en el aire | ∝ v·ω | ∝ v·ω |
| Viento | solo por encima de ≈25 cm de altura | — | no existe |
| Rodadura | resta constante ≈1,1 m/s² + parte proporcional | 0,5-1 m/s² | 1,4 m/s² constante |
| Saltitos al rodar rápido con giro | hasta ≈4 cm aleatorios | — | no existe |

Conclusiones: (1) el arrastre cuadrático con ≈0,013-0,014 es lo correcto y coincide con la física real; (2) rebote 0,58 está bien, pero mejor
variable con la velocidad de caída; (3) ideas baratas y visibles: arrastre reducido a >20 m/s, viento leve en vuelo alto, saltitos mínimos al rodar;
(4) la fracción de rodadura «98,27 % por fotograma» de la nota no dice a qué velocidad se midió: no usarla sin vídeo real.

## No hecho
- Ghidra / FIFA 17 / PES 6 PC: no hay binarios del juego en este contenedor (y no se obtienen de fuentes no oficiales). Si el dueño tiene su copia, puede
  correr Ghidra en su PC y compartir solo números (no el ejecutable ni assets) para añadirlos a este informe.
- Modelos de esos juegos: no se extraen (copyright). Se usan los del Drive con licencia confirmada.
- Comparación visual con vídeo real: pendiente de vídeo.
