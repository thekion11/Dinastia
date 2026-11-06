# Diseño: 7 niveles de calidad gráfica (6-11-2026) — BORRADOR para aprobar antes de tocar código

Orden del dueño: ULTRA BAJA, BAJA, MEDIA BAJA, MEDIA, MEDIA ALTA, ALTA, ULTRA ALTA. Defecto en TODOS los sistemas = ULTRA BAJA. Meta de ULTRA BAJA: < 130 llamadas de dibujo de media (ciudad + partido). «Partido ligero» sigue aparte.

## 0. Hallazgo previo (A1 y A2 ya existen en `main`)
- **A1 (resolución del 3D):** `Calidad.escala_3d()`: MÍNIMO 50 % por defecto (ajustable 35–100 %), MEDIO 100 % (ajustable 50–100 %), ALTO/ULTRA 100 %. Control en Ajustes: `AjusteResolucion3D`. Falta solo decidir una escala por defecto para los niveles nuevos (tabla §3).
- **A2 (sombra solar apagada en el escalón bajo):** `Calidad.sol()`: `shadow_enabled = nivel > MINIMO`, es decir, MÍNIMO ya no proyecta sombras, y el texto de Ajustes ya lo dice («sin sombras ni suavizado y el 3D a menor resolución»). Lo medido (partido, `medir_partido.tscn`, cámara de TV): MÍNIMO 338 llamadas, 387 062 triángulos, 137 MB; MEDIO 709 / 845 501 / 208 MB; ALTO 925 / 1 787 095 / 215 MB. Por tanto la sombra solar del escalón bajo ya está fuera; el −251 llamadas se refería a MEDIO.

## 1. Representación (cambio de bajo impacto)
Hoy: `enum { MINIMO = -1, MEDIO, ALTO, ULTRA }`, 89 comparaciones en código no de pruebas (17 `> MINIMO`, 17 `<= MINIMO`, 11 `>= ALTO`, 5 `>= ULTRA`, 5 `<= MEDIO`, 3 `== MINIMO`…).

Propuesta: `enum { ULTRA_BAJA = -3, BAJA = -2, MEDIA_BAJA = -1, MEDIA = 0, MEDIA_ALTA = 1, ALTA = 2, ULTRA_ALTA = 3 }` y alias `const MINIMO := ULTRA_BAJA`, `MEDIO := MEDIA`, `ALTO := ALTA`, `ULTRA := ULTRA_ALTA`. Efecto sobre las comparaciones viejas sin tocarlas: `<= MINIMO` = solo ULTRA BAJA; `> MINIMO` = todo lo demás; `>= ALTO` = ALTA y ULTRA ALTA (MEDIA ALTA se comporta como MEDIA); `<= MEDIO` = hasta MEDIA. Los niveles intermedios se refinan después con funciones con nombre en `Calidad` (`es_baja()`, `permite_sombras()`, `multiplicador_publico()`…), sustituyendo comparaciones por lotes pequeños con el banco en verde.

## 2. Migración de la configuración guardada
`[grafica] version_calidad`. Sin la clave (o 1) = esquema viejo: −1→ULTRA_BAJA(−3), 0→MEDIA(0), 1→ALTA(2), 2→ULTRA_ALTA(3). Con `version_calidad = 2` = esquema nuevo (−3..3, `clampi`). Al guardar siempre se escribe 2. Pruebas con archivos reales de −1, 0, 1, 2 y sin la clave, y que ningún camino suba el defecto (sin archivo, «restablecer», `CalidadAuto`, orquestador de mundo, `config_club_datos`) simulando plataformas con `OS.has_feature`/`es_compatibilidad`.

## 3. Tabla nivel × parámetro (a MEDIR con `hw_modesto.sh`; no se inventan cifras)
| Parámetro | ULTRA BAJA | BAJA | MEDIA BAJA | MEDIA | MEDIA ALTA | ALTA | ULTRA ALTA |
|---|---|---|---|---|---|---|---|
| Escala 3D | 50 % (hoy) | ? | ? | 100 % (hoy) | 100 % | 100 % | 100 % |
| Sombra solar | no (hoy) | ? | ? | sí, 2 cortes (hoy) | ? | 4 cortes, 420 m | ? |
| MSAA | x2→apagado (R01) | ? | ? | hoy | ? | x2 | ? |
| Público / peatones / tráfico | hoy | ? | ? | hoy | ? | hoy | ? |
| `mesh_lod_threshold`, distancia de dibujo, reflejos, debanding, texturas | por medir | | | | | | |
Medido hoy (partido): ULTRA BAJA 338 llamadas / 387 062 tri / 137 MB; MEDIA 709 / 845 501 / 208 MB; ALTA 925 / 1 787 095 / 215 MB. Cada escalón debe ser monótono en llamadas, triángulos y memoria: prueba `ren_calidad_monotona` (por escribir) que mide los 7 y falla si uno inferior cuesta más.

## 4. Pendiente de implementar (orden)
1. Enum + alias + migración + pruebas de migración y de defecto por plataforma.
2. `RendimientoAdaptativo` y `CalidadAuto` recorren los 7 niveles de uno en uno con histéresis.
3. Selector de 7 niveles en Ajustes, con frase corta por nivel (`Idiomas.t` + `sumar_traducciones.py`, 9 idiomas).
4. Recortes de ULTRA BAJA hacia < 130 llamadas (agrupar mallas, distancia de dibujo, oclusión, luces/sombras fuera, materiales compartidos), con captura antes/después con la cámara real.
5. Presupuestos por nivel en el banco extra de rendimiento.
6. Si `nativo/src` usa el nivel: mantener la copia GDScript idéntica y avisar (hoy no lo usa).
