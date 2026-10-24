# Comparación con el informe externo (61/100)

Hecha el 29-9-2026. Cada punto del informe (`INFORME_DINASTIA.md`, sobre la versión del 25-9) se comprobó contra el código actual, no contra la documentación.

Estados:
- ✅ resuelto y con prueba;
- 🟡 resuelto en parte;
- ⬜ sigue pendiente;
- 🔒 depende del dueño (builds, claves, PC real).

## 1. Problemas técnicos (sección 3.2)

| Problema del informe | Estado | Cómo está hoy |
|---|---|---|
| `principal.gd` monolítico (14.640 líneas) | ✅ | 6.388 líneas. 243 funciones repartidas en 14 pantallas de `ui/pantallas/`, más componentes en `ui/componentes/`. Validado con el recorrido de 106 pantallas y 463 botones. |
| Arquitectura portada del HTML | 🟡 | El núcleo sigue siendo el portado. Todo lo nuevo (carrera de jugador, motor jugable, menús, idiomas) está escrito ya para Godot. |
| Animaciones 3D no aptas | 🟡 | 333 movimientos por jugador. Los 20 tiros artesanales ya parecen un golpeo. Falta revisarlos jugada a jugada con el juego en marcha. |
| Señales conectadas a objetos muertos | ✅ | Auditoría de las 315 conexiones hecha. El banco la vigila. |
| ZIP de 134 bytes en `entregas/` | 🔒 | Son punteros LFS. Hay que generar los builds en un PC. |
| `export_credentials.cfg` en el repo | 🔒 | Ya no está en el repo (lo ignora `.gitignore`). La contraseña vieja sigue en el historial: hay que cambiarla. |
| Archivos grandes sin LFS | ✅ | Decisión tomada: sin LFS, con excepciones en `.gitattributes`. Las capturas de prueba viven en `pruebas/capturas/` (el importador las ignora y los builds las excluyen). |

## 2. Jugabilidad (secciones 4.3 y 4.4)

| Problema o sistema prometido | Estado | Cómo está hoy |
|---|---|---|
| Simulación de partido subdesarrollada | 🟡 | Botón «Simular hasta el final», jugadas prehechas y árbitro con gestos. La novedad es el **motor jugable** de la Carrera de Jugador: física del balón, reglas e IA de los 21 jugadores. |
| La charla del descanso bloquea el partido | ✅ | Corregido, con prueba en el banco y `pruebas/prueba_descanso_3d.gd`. |
| Rueda de prensa no interactiva | 🟡 | Las respuestas cambian la relación con la prensa y las facetas del DT. La charla escrita deduce el tono. Sin IA conversacional real. |
| Modos de rol sin diferencia | ✅ | Dueño, DT y Presidente tienen acciones exclusivas. Además hay cuatro modos más: Crear tu Club, Retos, Fondo de Inversión y **Carrera de Jugador**. |
| Tácticas no visuales | ✅ | Pizarra táctica con las formaciones en la cancha. |
| Vida personal sin implementar | ✅ | Casa 3D interactiva, teléfono con 7 apps, Tribuna (redes), familia, bienestar, casa y auto. |
| IA conversacional en charlas | ⬜ | Pendiente. Idea: que sea opcional y use la clave del propio jugador. |
| Árbol de habilidades del DT | ✅ | 15 maestrías de 30 niveles. |
| Clanes y camarillas | ✅ | `nucleo/vestuario.gd`. |
| Salud mental de jugadores | ✅ | Ansiedad, descanso mental y psicólogo. |
| Guerra de representantes | 🟡 | Superagente, agencias del plantel, guerra de ofertas y agente propio en la Carrera de Jugador. Falta el mini-juego de negociación dedicado. |
| Mundial y selecciones | ✅ | `nucleo/selecciones.gd`: prenómina, fechas FIFA y Mundial. |
| Copas de Asia, Oceanía y África | ✅ | 8 confederaciones. |
| Celebraciones de gol procedurales | ✅ | Repertorio según el carácter del jugador y celebración propia de cada uno. |
| Tutorial interactivo | ✅ | Prólogo, mentor con datos de tu partida y misiones por modo. |

## 3. Visual (sección 5.2)

| Problema | Estado | Cómo está hoy |
|---|---|---|
| El partido 3D es un «boceto» | 🟡 | 333 animaciones, celebraciones por carácter, gestos del árbitro, banca con suplentes, DT, camarógrafos y guardias. La grada tiene butacas 3D en toda su superficie y público sentado mirando al campo (29-9). |
| Patada con pose de salto | ✅ | Tiene carrera, cadera, brazo de equilibrio y pierna de apoyo flexionada. |
| Presentador del sorteo provisional | 🔒 | En pausa a pedido del usuario. |
| El color del uniforme contamina el menú | ✅ | Cuatro capas independientes: club, uniforme, escudo e interfaz. |
| Sin rostros en el campo | ⬜ | En espera: «la cara 2D moldeada sobre el modelo 3D» no se toca sin permiso. |
| Estadio limitado | ✅ | 6 formas, hasta 5 bandejas y 150.000 personas. Cada club juega en un estadio parecido al suyo real. Colores por sección y cinemática de fichajes. |
| Sin uniformes variados | ✅ | 130 diseños, patrocinadores y diseñador a pantalla completa. Además hay 8 balones con 3 dibujos de paneles. |

## 4. Rendimiento (sección 6.3)

| Problema | Estado | Cómo está hoy |
|---|---|---|
| `principal.gd` lento de compilar | ✅ | Pasó de 14.640 a 6.388 líneas. |
| Generación sin caché | ✅ | Los retratos se cachean en `cara.gd`. |
| Sin LOD | 🟡 | Rendimiento adaptativo en 5 escalones: SSAO, sombras, butacas livianas y FSR al 80 % y al 67 %. La calidad se elige Media, Alta o Ultra. Las filas lejanas usan la butaca liviana. No hay LOD por distancia en la ciudad. |
| Vídeo a calidad MJPEG 0,55 | 🟡 | El vídeo promocional se graba aparte y a mejor calidad. |
| Android sin documentar | 🔒 | Hay preset de exportación. Falta probarlo en un teléfono real. |

## 5. Fallos numerados (sección 7)

- Resueltos: todos los marcados como «corregidos» en el informe y, además:
  - 1: descanso;
  - 9: color del uniforme;
  - 10: botón de la segunda parte separado;
  - 11: patada;
  - 19: caché de caras;
  - 20: reconversión de puesto con rendimiento bajo durante semanas;
  - 21: los contratos vencen;
  - 22: selecciones.
- En manos del dueño: 12 (presentador), 13 y 17 (builds) y 16 (contraseña del historial).

## 6. Contenido (sección 8.2)

De los 15 puntos «prometidos pero no implementados»:
- **11 hechos:**
  - psicología del vestuario;
  - Mundial y selecciones;
  - copas de 8 confederaciones;
  - árbol de habilidades;
  - celebraciones;
  - tutorial;
  - rendimiento por puesto (1 en el natural, 0,975 en un secundario y 0,60 fuera de sitio);
  - personalización del DT;
  - diseños de estadio;
  - capacidad hasta 150.000;
  - uniformes.
- **2 parciales:** representantes y vida personal jugable. La vida personal está completa para el DT y como carrera para el jugador.
- **2 pendientes:**
  - IA conversacional;
  - banderas en el estudio del sorteo y la rueda de prensa (comprobado: no hay ninguna).

Más allá de lo que pedía el informe:
- 24 ligas y 384 clubes; el informe pedía 15-20 ligas.
- 9 idiomas: castellano, inglés, portugués, francés, italiano, alemán, catalán, polaco y turco.
- Carrera de Jugador con control real.
- Menús a pantalla completa.
- Logros, cromos, museo y mundo heredado.

## 7. Nueva puntuación (mismas categorías y pesos)

Es una **estimación propia**, hecha con los criterios del informe. No es una evaluación externa.

| Categoría | Peso | Antes | Ahora | Por qué |
|---|---|---|---|---|
| Arquitectura técnica | 15 % | 64 | 72 | `principal.gd` a menos de la mitad, 14 pantallas y 1 banco con 0 fallos. Siguen la base portada del HTML y los builds pendientes. |
| Jugabilidad | 20 % | 65 | 74 | Descanso, simulación, pizarra, tutorial y 7 modos, entre ellos uno jugable con control real. La táctica sigue por debajo de FM. |
| Visual / 3D | 15 % | 52 | 64 | Estadios, grada completa, 130 uniformes, celebraciones y cinemáticas. Faltan caras en el campo y revisar las animaciones jugada a jugada. |
| Rendimiento | 10 % | 70 | 70 | Hay rendimiento adaptativo, pero la grada completa cuesta un 30 % más de triángulos y no hay FPS medidos en un PC real. |
| Contenido | 20 % | 68 | 80 | 24 ligas, 8 confederaciones, selecciones, 9 idiomas y la Carrera de Jugador. |
| Pulido | 10 % | 45 | 60 | Objetivos siempre visibles, menús nuevos y traducción. La narración sigue solo en castellano y falta probar en hardware real. |
| Originalidad | 10 % | 55 | 68 | El «drama humano» ya está: redes, casa, salud mental, camarillas y siete modos. |
| **Total** | | **61** | **≈71** | |

Cuenta: 10,8 + 14,8 + 9,6 + 7,0 + 16,0 + 6,0 + 6,8 = **71,0**.

## 8. Lo que queda para pasar de 71 a 75-80

1. **Probar en un PC y un teléfono reales** (dueño): FPS, builds y Android. Es lo que más sube el pulido y el rendimiento.
2. **Caras en el campo** (cuando se dé permiso para tocar la cara 2D→3D).
3. **Revisar las animaciones jugada a jugada** con el partido en marcha.
4. **Carrera de Jugador v2**: fuera de juego, cambios, más eventos y selección jugable.
5. **IA conversacional opcional** en charlas y prensa.
6. **Mini-juego de representantes.**
7. **Traducir la narración** (noticias, prensa, vestuario), al menos al inglés.
8. **Banderas en el estudio** del sorteo y la rueda de prensa.
