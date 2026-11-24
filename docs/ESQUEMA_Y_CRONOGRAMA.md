# Esquema y cronograma de Dinastía (para la sesión que retome)

Pedido por el dueño el 17-11: «un esquema con la jerarquía y el orden de las cosas». Léelo después de `CLAUDE.md`.
El detalle de cada punto vive en `docs/PLAN_GENERAL.md`; aquí solo está QUIÉN manda, CÓMO se entrega y EN QUÉ ORDEN se trabaja.
Se actualiza al cierre de cada jornada. Lo completado se borra.

## 1. Jerarquía

1. **El dueño** decide. Sus órdenes están en `CLAUDE.md` (numeradas) y sus ideas en `PLAN_GENERAL.md`.
2. **La sesión de auditoría** (orden 60) dirige: reparte, exige, verifica por su cuenta y es la ÚNICA que une a `main`.
3. **Las sesiones de trabajo** obedecen a la auditoría y le consultan a ella, cada una en su rama:

| Sesión | Rama | Qué lleva |
|---|---|---|
| Avance por días / menú central | `avance-por-dias` | menú central estilo PES, avance por días, decisiones, disparadores |
| Menú del partido (par de la anterior) | `avance-por-dias-menu` | previa, plan de juego, pausa, descanso y resultado, mando y táctil del partido |
| C++ y jugabilidad de C4 | `ccr-7b9a650f-dyqgi6` | extensión C++, goles del partido C4, sondas de medición |
| Aspecto del partido («AAA») | `ccr-8ca5e329-7uzbi2` | HUD de TV, cámara, césped, público, dorsales, animación |
| Parecido real | `parecido-real` | plantillas reales, rasgos, escudos y uniformes |

## 2. Cómo se entrega (regla de unión a `main`)

Una rama solo entra en `main` si la sesión la entrega con TODO esto en verde, y la auditoría lo repite en su máquina:

1. `main` al día fusionado en la rama (fusión de verdad, nunca aplastada dentro de un commit propio).
2. `dinastia-godot/herramientas/banco.sh` → «FIN. 0 fallos».
3. `python3 herramientas/revisar_lineas.py` → 0 archivos por encima de 450 líneas (cuenta `.gd`, `.cpp` y `.h`).
4. `pruebas/probar_nativo.tscn` → «FIN. 0 fallos»; `igualdad_motor` e `igualdad_mundo` con la huella anotada (si cambia: vieja y nueva, y por qué).
5. **Los bancos especializados del área** (`python3 herramientas/bancos_especiales.py <banco>`): el banco general NO ve todo. El 17-11 se colaron por no correrlos: 13 fallos de navegación del menú, nacionalidades sin bandera, un nombre real en los datos públicos, la táctica sin efecto en el simulado con C++ y un fallo de repetibilidad.
6. Lo visual: capturas en Forward+ con la cámara real, con 3 clubes de 3 países (orden 34), comparadas con las referencias del Drive.
7. Commits sin nombre de modelo. Las pruebas no se relajan para que pasen: se arregla la causa, o se justifica el cambio de la prueba.

## 3. Cronograma (orden de trabajo)

Se trabaja de arriba abajo. No se empieza un punto con el anterior en rojo.

**0. Dejar `main` sin fallos conocidos.** Correr `bancos_especiales.py --todos` sobre `main` y llevarlo a 0. Lista de fallos abiertos al cierre: `PLAN_GENERAL.md`, «ESTADO AL CIERRE DEL 17-11».

**1. Menú central con el diseño del dueño** (`PLAN_GENERAL.md`, «DISEÑO DEL MENÚ CENTRAL DECIDIDO POR EL DUEÑO»): barra lateral de antes siempre visible; barra superior con «lo demás»; ningún mini menú ni accesorio perdido; nada sin conectar; «Levantarse del PC»; prueba de alcance en el banco.

**2. Goles del partido C4** (4,6-5,0 por partido; real ~2,7): la causa medida son los remates de primera, solos, dentro del área. Siguiente paso: `C4_REMATE_PRIMERA` y, después, cortar el pase al área. Todas las tablas están en el plan.

**3. Aspecto del partido:** siluetas lejanas en calidad mínima sin coste, director de TV y repeticiones, audio de grada, iluminación.

**4. Parecido real:** los 111 países sin plantilla real (POR, BEL y TUR primero), más rasgos y escudos.

**5. Realismo de los jugadores 3D** (nota del dueño: «feos y poco realistas»): piel, manos, pelo, caras. Va DESPUÉS de 1-4.

**6. C++:** el partido está en ~44 % de su tiempo en C++ (la meta de la orden 58 es 50 %); se porta solo lo que gana ≥30 % medido, con gemela exacta.

## 4. Pendiente del dueño

- Probar en su laptop y en su teléfono: FPS reales, el menú nuevo con mando, el mando táctil (la nube no tiene GPU).
- Decidir: publicar o no los rasgos de jugadores medidos de fotos (cuantizados); Rust (evaluado: hoy no compensa); qué botones quiere en la barra superior si cambia la propuesta.
