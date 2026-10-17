# Puntos débiles frente a otros juegos — 17-10-2026

Comparación hecha **contra el código actual** (búsquedas en el repositorio, no de
memoria) tras cerrar la MEGA AUDITORÍA 2. Referencias: FC 26 (partido), Football
Manager 26 (gestión), eFootball / DLS 26 (progresión), GTA V (ciudad).
Leyenda: impacto en lo que siente el jugador (A alto · M medio · B bajo) y coste
(1 poco · 2 medio · 3 mucho).

## 1. Partido (referencia FC 26)

| Punto débil | Qué hacen ellos | Dinastía hoy | Impacto / coste |
|---|---|---|---|
| **Sin prórroga ni tanda de penales en 3D** | Eliminatoria: prórroga 2×15 y tanda jugable, con cámara propia | El 3D acaba en el 90'; la tanda (`Partido.penales()`) se sortea fuera del césped. La Supercopa empatada la decide la reputación | **A / 2** |
| **Sin narración por voz** | Dos comentaristas con frases según la jugada | Narración de texto en 9 idiomas; en el 3D solo rótulos y sonidos de grada | A / 3 (pide audios: 🔒 del dueño o voz sintética) |
| **Sin roles/estilos por jugador** (PlayStyles) | Cada jugador tiene 2-6 rasgos que cambian lo que hace | Atributos y agresividad; ningún rasgo con efecto propio | M / 2 |
| **Instrucciones individuales** | Por jugador: quedarse atrás, incorporarse, marcar al hombre… | Pizarra de equipo (presión, línea, mentalidad) y tácticas rápidas | M / 2 |
| **Informe del rival antes del partido** | FM/FC muestran su once probable, su estilo y sus mejores | No hay pantalla previa con el rival | M / 1 |
| **Línea defensiva** | Trampa del fuera de juego, coberturas | El fuera de juego se pita bien, pero la defensa no lo provoca a propósito | M / 2 |
| Pies sin IK al golpear | Captura de movimiento | IK solo en las piernas del personaje de la ciudad | B / 2 |
| Clima en el partido | Lluvia, nieve, charcos | `Precipitacion` existe y se usa en el estadio | ✅ |

## 2. Gestión (referencia Football Manager 26)

| Punto débil | Dinastía hoy | Impacto / coste |
|---|---|---|
| **Dinámicas de vestuario sin «por qué»** | Existe el Camarín y la moral, pero no se explica qué la sube o baja (ya lo marcó el informe) | M / 1 |
| Análisis de datos post-partido | Hay xG, mapa de tiros y de calor (17-10); falta comparar con la media de la liga | B / 1 |
| Ojeadores | Existen (cantera, ojeadores) | ✅ |

## 3. Progresión (referencia eFootball / DLS 26)

| Punto débil | Dinastía hoy | Impacto / coste |
|---|---|---|
| Desbloquear modos jugando | 🤝 decisión del dueño, propuesta desde el 13-10 | M / 1 |
| Online / ranking | Fuera de alcance sin servidor | — |

## 4. Ciudad (referencia GTA V)

| Punto débil | Dinastía hoy | Impacto / coste |
|---|---|---|
| **Radio en el coche** | Conducción con cámara interior, sin música ni emisoras | M / 1 (con sonidos propios; música 🔒) |
| Recados con objetivo | Misiones en la ficha; en la ciudad hay minijuegos, pero pocos «ve de A a B» | M / 2 |
| Interior del coche modelado | Salpicadero 2D | B / 2 |

## 5. Ventajas propias (que ellos no tienen juntas)

Ciudad y estadio recorribles a pie y conectados, vida personal y familia, leyes
por país con multas, documental, modo foto, dinastías, Carrera de Jugador que pasa
a DT, VAR que decide con la posición real del goleador, 9 idiomas.

## 6. Orden propuesto (impacto ÷ coste)

1. **Prórroga y tanda de penales en el 3D** (A/2): lo que más se nota en copas.
2. ~~**Informe del rival** antes del partido~~ HECHO 17-10 (`ui/componentes/informe_rival.gd`).
3. **Por qué sube o baja la moral** en el Camarín (M/1).
4. **Roles por jugador** con efecto en el motor (M/2).
5. **Línea defensiva** que adelanta para dejar en fuera de juego (M/2).
6. Radio del coche con sonidos propios (M/1, sin música con licencia).
7. Narración por voz: decisión del dueño (audios).
