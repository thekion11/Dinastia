# Revisión de eventos del avance por días: qué falta (17-11-2026)

Comparación de la maqueta (`maqueta_avanzar_2026-11-16.html`) con los sistemas que YA tiene el juego (`dinastia-godot/nucleo/`). Solo lectura; no se tocó código.
Clase: PARTIDO / PANTALLA (animación propia, pantalla completa) / AVISO (campana en la zona del menú). Los días de memoria y las fechas nacionales NO están aquí: los lleva la otra sesión con `Calendario`.

## Lo que la maqueta ya tiene (≈25 tipos)
Partidos (liga con derbis, copa, continental, amistosos), fichaje en 3 pasos, premio del mes, gala, 12 decisiones (vestuario, prensa, patrocinio, cantera, hinchada, primas, objetivos, mercado, renovación, venta, accionistas), lesión, sanción, patrocinio, cantera, convocatoria, sorteos, presentación de plantilla, aniversario, cierre de mercado, balance de mitad y de fin.

## Lo que FALTA, por prioridad (sistema del juego de donde sale)

### A. Imprescindibles (cambian cómo se juega)
| Evento | Sistema | Clase / zona |
|---|---|---|
| Confianza de la directiva, ultimátum y DESPIDO | `directiva.gd` («el día que te echan») | PANTALLA · directiva |
| Oferta de trabajo de otro club o de una selección | `mercado_dt.gd`, `cargo_seleccion.gd` | PANTALLA (decisión) |
| CIERRE DE TEMPORADA: ascensos, descensos, plazas continentales, fase final (EGY/ARG/MLS) | `ascensos_pais.gd`, `plazas_conti.gd`, `fase_final_liga.gd` | PANTALLA (falta: hoy solo hay «balance») |
| «El mercado ABRE» (la maqueta solo tiene «cierra») | `eventos_fecha.gd` (`mercado_abre`) | AVISO · mercado |
| Supercopa continental al empezar la temporada | `supercopas_conti.gd` | PARTIDO |
| Mundial de Clubes y Copa Intercontinental | `fifa_clubes.gd`, `mundial_clubes.gd`, `copa_intercontinental.gd` | PARTIDOS + sorteo |
| Torneos de selecciones (Mundial, Eurocopa, Copa América, Olímpicos, Finalissima) y el cargo de seleccionador | `torneo_selecciones.gd`, `finalissima.gd`, `olimpicos.gd`, `fecha_seleccion.gd` | parón + PARTIDOS (hoy la maqueta solo tiene «fecha internacional» genérica) |

### B. Importantes
| Evento | Sistema | Clase / zona |
|---|---|---|
| Crisis de caja, mora, crédito del banco, fondos de inversión | `crisis_caja.gd`, `insolvencia.gd`, `banco.gd`/`creditos.gd`, `fondo_inversion.gd` | PANTALLA/AVISO · finanzas |
| Pago de sueldos y cierre de cuentas trimestral; coste de viajes | `sueldos_pais.gd`, `viajes.gd` | AVISO · finanzas |
| Precontratos (jugador en su último año) | `precontratos.gd` | PANTALLA (decisión) · mercado |
| Mesa de agentes (mini-juego) y guerra de agentes | `mesa_agente.gd` | PANTALLA · mercado |
| Cesiones: oferta, vuelta, bonos por objetivos | `cesiones.gd` | AVISO/decisión · mercado |
| Contratos que vencen | `contratos.gd` | AVISO · equipo |
| Imprevistos con contexto (~40: intoxicación…) y lesiones absurdas fuera de la cancha | `imprevistos.gd`, `lesiones_absurdas.gd` | ALEATORIOS · PANTALLA |
| Eventos del club con diálogo (estilo «liga máster») | `eventos_club.gd` | ALEATORIOS · PANTALLA |
| Partido de despedida de las leyendas (fin de temporada) | `partido_despedida.gd` | PARTIDO especial |
| Federación: expediente, sanción al DT, apelación | `federacion.gd` | PANTALLA · directiva |
| Examen de licencia de entrenador | `licencia.gd` | PANTALLA |

### C. Complementarios (avisos)
| Evento | Sistema | Zona |
|---|---|---|
| Informe de ojeadores y hallazgos de la academia | `ojeadores.gd` | cantera / mercado |
| Eventos de cantera (captación, torneo juvenil, debut, ascenso) | `eventos_cantera.gd`, `academia.gd` | cantera |
| Retos de la semana (3 por partido) | `retos_semana.gd` | equipo |
| Charla individual con un jugador | `charlas.gd` | vestuario |
| Revisión de objetivos a mitad de temporada | `objetivos_en_vivo.gd`, `objetivos_club.gd` | prensa |
| Rumores y redes; entrevistas | `redes.gd`, `prensa.gd` | prensa |
| Hitos de jugadores (100 partidos, retiro, cumpleaños) | `jugador.gd`, `retiros` | equipo |
| Día del socio, campaña de abonos, peñas | `hinchada.gd` | prensa |
| Clima: partido suspendido o temporal | `clima.gd` | equipo |
| Reputación: hitos de prestigio | `reputacion.gd` | prensa |

### D. No son del avance (aparte)
La Ruta (modo jugador) tiene sus 14 eventos propios (`carrera_eventos_ruta.gd`); la ciudad 3D está apagada; las fechas de memoria y nacionales las trae `Calendario` (otra sesión).

## Decisiones de diseño que esta revisión deja abiertas
1. **Eventos ALEATORIOS** (imprevistos, eventos del club, crisis de caja, lesiones absurdas): no tienen día fijo. Propuesta: NO se marcan antes en el calendario; aparecen al llegar el cursor al día (con la espera con decoración). Los FIJOS (partidos, sorteos, mercado, premios, cierre) sí van marcados de antemano.
2. La zona **«directiva»** no existe en las 6 tarjetas de la maqueta; en el juego real corresponde a la pestaña «Dirección del equipo».
3. Frecuencia: la maqueta ya da ~120 paradas por temporada; sumar todo esto exige **límite por semana** (p. ej. máximo 1 evento aleatorio por semana y 2 avisos por día) y un ajuste de «Hasta el próximo evento».
