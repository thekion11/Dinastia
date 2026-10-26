# Cierre del 26-10-2026: qué quedó subido y qué falta

Escrito por la sesión supervisora (rama `ccr-a64d04fd-r5uoai`) a las 15:10 UTC. Las sesiones de trabajo
no pudieron escribir su cierre: a las 12:36 UTC chocaron con el «monthly spend limit» (y luego con el límite
semanal, que se reinició a las 15:00 UTC) justo después de recibir la orden de cierre.

## Estado de las ramas (en GitHub)

| Rama | Último commit | Hora (UTC) | Qué trae |
|---|---|---|---|
| `ccr-76d707c5-dwse9h` (principal) | `13059451` | 12:32 | Une S5 (rueda previa) y conecta `_contexto_rueda()`; banco «FIN. 0 fallos». |
| `…-s1` | `f235cc10` | 12:32 | Pruebas de conducción y Retrato3D (M-406/M-407) y «trabajo en curso de los agentes» (WIP, compila). Merge de la base. |
| `…-s3` | `4e63846f` | 12:36 | Nombres visibles de competición en noticias, calendario, sorteos, ficha y palmarés. Informe `sesion_3.md` §15. Banco 0 fallos. |
| `…-s5` | `79a93813` | 08:50 | Rueda previa, rueda por contexto, auditoría de partidos, fila 18 (núcleo). **Nada posterior.** |
| `…-s6` | `8de42720` | 12:32 | Lote 1 de países (POR, NED, BEL, CRO, DEN), historia de clubes, ajuste del banco. **Lote 2 sin subir.** |

La principal une S1 y S6 solo hasta lo anterior; S3 y S5 ya están unidas hasta sus commits de las 12:31 y 08:50
respectivamente, salvo `4e63846f` (S3, 12:36), que la principal aún no ha unido.

## Posible trabajo sin subir (en contenedores de sesión)

No se puede comprobar desde fuera. Si los contenedores se liberan (archivar la sesión), se pierde:

- **S5:** interfaz de la pizarra de la fila 18 (dos fases y roles en el once), IA con roles, auditoría CPU vs CPU.
  Su rama no tiene commits desde las 08:50, pero la sesión siguió trabajando hasta las 12:37.
- **S6:** lote 2 de la fila 26 (más países) y pruebas de carga M-404.
- **S1:** arreglo de caras (óvalos negros bajo los ojos, `biblioteca_caras.gd`) y faldón del abrigo
  (`personaje_dt_p1.gd`, hay que partir el archivo: tiene 448 líneas). El commit `32fda4e2` guarda un WIP; no se sabe si incluye esto.
- **S3:** caras 2D → `Retrato3D` y recorrido de las 108 pantallas en 9 idiomas (no empezados o sin commit).

## Pendiente (todo lo que faltó)

**Tareas de las sesiones**
1. Fila 18: pizarra con dos fases y roles en el once; que la IA use roles (medir con ≥48 partidos).
2. Auditoría CPU vs CPU frente al vídeo de faltas por puntos (CLAUDE.md, 20-10).
3. Fila 26: más países jugables (liga ficticia, bolsas de nombres, regiones, ley de plantel) en lotes de 5.
4. M-404: prueba de carga para los 27 módulos de `visor/` sin referencia (en `pruebas/ideas/`).
5. Caras 2D sueltas → `Retrato3D` en todas las pantallas (regla del dueño, mega auditoría 2, punto 1).
6. Recorrido de las 108 pantallas en 9 idiomas, a 1280×720 y 1920×1080.
7. Arreglo de caras: óvalos negros bajo los ojos en peatones (solo código, sin tocar pieles ni colores).
8. Faldón del abrigo del DT (cilindro sin tapas + raya de abertura; ver mensaje de S1) y partir `personaje_dt_p1.gd`.
9. Grada y exterior del estadio, fuera de los archivos vetados (`hinchada*`, `stadium_builder_p5/p6`, `festejo_grada`, `banquillo_vivo`, `publico_vat`).
10. Pulir el modelo MakeHuman (bajo de la chaqueta dentado, cejas manchadas) antes de integrarlo.
11. CMU: bloqueado (BVH sin Blender); documentado en `sesion_6.md`.

**Decisiones y acciones del dueño**
- Coste del día de partido del 30 %: la principal preguntó y no hubo respuesta; está aplicado.
- Subir por LFS `assets/personas/persona_mh_cuerpo.glb` y `persona_mh_ropa.glb`.
- Logo y alas (imágenes tuyas) y `makehuman-assets` (decisiones pendientes que citó la principal).
- Decidido el 26-10: `bio_de()` se queda como está; «Forma» separada en «Forma del escudo» (hecho).
- **Límites de uso:** el límite mensual de gasto (`https://claude.ai/settings/usage`) bloqueó a todas las sesiones a las 12:36.
  Mientras no se suba o se revise, no pueden continuar.

## Reglas de coordinación vigentes
Vetos de archivos (S1): `hinchada*`, `stadium_builder_p5/p6`, `festejo_grada`, `banquillo_vivo`, `publico_vat`,
`finanzas*`, `principal_p6`, `rueda_prensa*`, `pruebas/banco*` (este último autorizado puntualmente a S6).
Traducciones: siempre con `herramientas/sumar_traducciones.py` y el candado, nunca editando `idiomas_extra.json` a mano.
