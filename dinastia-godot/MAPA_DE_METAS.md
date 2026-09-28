# Mapa de metas de Dinastía

Hecho el 28-9-2026 a partir de dos fuentes:
- el **informe externo** del 28-9, que puntúa el juego con 61/100;
- el **plan de trabajo** que venía siguiendo, en `ROADMAP.md`.

Antes de escribir cada meta se comprobó contra el código. El informe se hizo sobre la versión del 25-9 y sobre la documentación, así que varias de sus carencias ya estaban resueltas.

Estados:
- ✅ hecho y probado en el banco;
- 🔨 en curso;
- ⬜ por hacer;
- 🔒 depende de algo externo (lo gestiona el dueño).

```
 FASE A — MÍNIMO JUGABLE        FASE B — EARLY ACCESS          FASE C — VERSIÓN 1.0
 (lo que bloquea jugar)         (lo que hace falta vender)     (lo que lo hace distinto)
 ────────────────────────       ────────────────────────       ────────────────────────
 ✅ Descanso sin bloqueo         ✅ 20+ uniformes               ✅ Drama humano: redes
 ✅ Simular hasta el final       ✅ Árbol de habilidades        ⬜ Charlas con IA real
 ✅ Tutorial inmersivo           ✅ Selecciones y Mundial       ⬜ Representantes (mini-juego)
 ✅ Uniforme ≠ color del menú    ✅ Copas de 8 confederaciones  ✅ Salud mental y camarillas
 ✅ Pizarra táctica              ✅ Camarillas en el vestuario  ⬜ Celebraciones por jugador
 🔨 Animaciones de partido       ✅ Estadios de 5 bandejas      ⬜ Editor avanzado (+100)
 🔒 Builds de entrega            ⬜ Dividir principal.gd        ⬜ Carrera de jugador
 🔒 Contraseña del keystore      ⬜ Mercado avanzado            ⬜ Logros e historial
                                 ⬜ Insolvencia y reglamento    ⬜ Multijugador asíncrono
```

## Fase A — Mínimo jugable (objetivo: 65/100)

| Meta | Estado | Qué hay / qué falta |
|---|---|---|
| El descanso no bloquea el partido | ✅ | El reloj del 3D arranca donde va el partido. El 3D se para en el 45' y abre el camarín. Hay prueba en el banco y `pruebas/prueba_descanso_3d.gd`. |
| Simular el partido entero | ✅ | Botón "⏭ Simular hasta el final" en la vista 3D y en la de texto. |
| Tutorial interactivo | ✅ | Tutorial inmersivo: prólogo, mentor con datos de tu partida y misiones por modo. |
| Color del uniforme separado del menú | ✅ | Cuatro capas independientes: club, uniforme, escudo e interfaz. |
| Vista táctica de cancha | ✅ | `ui/componentes/pizarra_tactica.gd`. |
| Animaciones de partido creíbles | 🔨 | 333 movimientos por jugador (23 tiros, 20 pases, 13 atajadas, 31 regates, lesiones y árbitro). Falta una revisión visual jugada a jugada. |
| Builds de entrega | 🔒 | Los ZIP de `entregas/` son punteros LFS. Hay que generarlos en un PC y subirlos fuera de LFS. |
| Secretos fuera del repo | 🔒 | `export_credentials.cfg` ya no está en el repo. La contraseña vieja sigue en el historial y hay que cambiarla. |

## Fase B — Early Access (objetivo: 72-75/100)

| Meta | Estado | Qué hay / qué falta |
|---|---|---|
| Uniformes variados | ✅ | 130 diseños (40 nuevos: 20 de dos colores y 20 de tres), patrocinadores en la camiseta y diseñador a pantalla completa. |
| Árbol de habilidades del DT | ✅ | Árbol, 15 maestrías de 30 niveles, vista en grande. |
| Selecciones y Mundial | ✅ | `nucleo/selecciones.gd`. |
| Copas continentales | ✅ | Libertadores, Sudamericana, Champions, Europa League, Asia, África, Oceanía y Concacaf. |
| Psicología del vestuario | ✅ | Camarillas, ansiedad y roles, en `nucleo/vestuario.gd`. |
| Estadios variados | ✅ | Seis formas, hasta 5 bandejas y 150.000 personas. El estadio sigue al real de cada club. |
| Reputación por facetas | ✅ | Niveles del club y siete facetas del DT con efectos reales. |
| Modos de juego | ✅ | Crear tu Club, Retos y Fondo de Inversión. ⬜ Carrera de Jugador. |
| **Dividir `principal.gd`** | ⬜ | 15.189 líneas. Hay que sacar los paneles a `ui/componentes/` y bajar de 10.000. |
| Mercado avanzado (bloque 37) | ⬜ | Cláusulas, pagos a plazos y co-propiedad. |
| Insolvencia (bloque 38) | ⬜ | Concurso de acreedores, administración y descenso administrativo. |
| Reglamento y federación (bloques 39-40) | ⬜ | Fair play financiero y límite de extranjeros por liga. |
| Editor de competiciones (bloque 42) | ⬜ | Crear ligas y copas propias. |

## Fase C — Versión 1.0 (objetivo: 80-85/100)

| Meta | Estado | Qué hay / qué falta |
|---|---|---|
| **Vida del personaje y redes sociales** | ✅ | Casa 3D interactiva, teléfono con 7 apps, Tribuna con tu cuenta y la del club. Falta que los jugadores también publiquen. |
| Charlas con IA conversacional | ⬜ | Hoy la charla escrita deduce el tono de lo que escribes. Falta una IA real, opcional y con clave del jugador. |
| Representantes con agencia propia | ⬜ | Mini-juego de negociación con agentes que tienen su propia cartera. |
| Celebraciones de gol por jugador | ⬜ | Cada jugador con su festejo, según su carácter. |
| Editor avanzado | ⬜ | Más de 100 variaciones de caras, uniformes y estadios desde el juego. |
| Carrera de Jugador | ⬜ | Jugar como futbolista, no como DT. Es el modo más grande que queda. |
| Logros e historial | ⬜ | Logros, récords y estadísticas históricas. |
| Multijugador asíncrono | ⬜ | Ligas entre amigos. Opcional. |

## Lo que se pidió el 28-9 (hecho)

| Meta | Estado |
|---|---|
| Mapa de metas (este documento) | ✅ |
| El móvil bien agarrado en la mano: muñeca orientada, palma contra el dorso, pose de lectura | ✅ |
| Teléfono con pantalla de inicio, 7 apps (Tribuna, Mensajes, Noticias, Banco, Calendario, Fotos, Ajustes) y personalización (fondo, funda, letra) | ✅ |
| Foto de perfil: la cara de tu personaje o una imagen de tu galería | ✅ |
| Acceso a la cuenta del club por un evento, cierre de sesión animado y entrada con usuario y clave | ✅ |
| Escena de la casa más natural: cielo con nubes que se mueven, 26.000 briznas con viento, árboles con copa de varias masas, agua con oleaje, pájaros | ✅ |
| Escena interactiva: tomar un café, mirar el paisaje, cámara libre y pasar al atardecer con farolas | ✅ |

## Cómo se mide

- **Cada meta cerrada tiene prueba en el banco** (`pruebas/banco.gd`, 0 fallos) y, si se ve, una captura en `pruebas/`.
- La puntuación se recalcula con las siete categorías del informe:
  - arquitectura;
  - jugabilidad;
  - visual;
  - rendimiento;
  - contenido;
  - pulido;
  - originalidad.
- Estimación actual: **~68/100**. Se cerró la Fase A salvo las entregas, que dependen del dueño, y casi toda la Fase B de contenido.
