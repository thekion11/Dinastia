# Avance por días: del diseño al juego (rama `avance-por-dias`)

Diseño aprobado por el dueño (16 y 17-11): `docs/04_auditorias/maqueta_avanzar_2026-11-16.html` (también publicada como artefacto). Reglas y decisiones: `docs/PLAN_GENERAL.md`, sección «AVANCE EN EL TIEMPO POR DÍAS». Esta rama es APARTE: no toca `main` ni la rama de trabajo; no hay PR hasta que el dueño lo pida.

## Qué existe hoy en el juego (y se reutiliza)
- `nucleo/eventos_fecha.gd` (`EventosFecha`): eventos de calendario por semana (liga, copa, continental, mercado, fin); `ui/componentes/calendario_semanas.gd` y `fila_proximos.gd` los muestran.
- `ui/componentes/evento_pantalla_completa.gd` (`EventoPantallaCompleta`): base de las pantallas completas.
- Menú de inicio: `TableroInicio` + `MosaicoTarjetas` (el mosaico REAL; las tarjetas de la maqueta son solo un ejemplo).
- Calendario por país (`nucleo/calendario.gd`, `Calendario.del_anio`): lo trabaja OTRA sesión (rama `ccr-bd198c7b-7akaeg`). Aquí NO se escribe ninguna fecha ni texto de memoria.

## Pasos (cada uno con su prueba, `banco.sh` en 0 fallos y ningún script de más de 450 líneas)
1. **Modelo de eventos del día** — HECHO en esta rama: `nucleo/eventos_dia.gd` (`EventosDia`: clase PARTIDO / PANTALLA / AVISO, zona de la campana, `del_dia`, `proxima_parada`, `plan_de_parada`) y `pruebas/probar_eventos_dia.tscn` (en `especiales.sh`, porque `banco.gd` está en 450 líneas y no admite secciones nuevas sin partirlo).
2. **Eventos nuevos como datos**: sorteos, fechas internacionales, objetivos de la directiva, renovación, ventas, sanciones, aniversario, gala, derbis (la maqueta los tiene; en el juego deben salir de `Mundo`/`Club`, no de una lista fija).
3. **Pantalla «Avanzar»**: calendario de dos semanas (lunes a domingo) que se desliza y cambia de mes solo, cursor con el escudo del club, parada en cada evento, decoración solo con el día encima (~2,4 s).
4. **Pantallas de evento a pantalla completa** con su animación (premio, propuesta, negociación, presentación, decisión, parte médico, balance); tras cerrar, vuelta al menú.
5. **Avisos con campana** en la tarjeta de su zona del `MosaicoTarjetas` y avance parado.
6. **Día de partido**: «Jugar partido» / «Saltar partido» donde estaba «Avanzar»; tras jugar, el menú «Jugar de nuevo / Ver partido / Jugar momentos específicos».
7. **Previa del partido** con sus seis pestañas (uniforme, estadio, saque inicial, plan de juego, opciones, cámara) y **HUD del partido** (marcador, minimapa, mando táctil con y sin balón; el partido en sí ya existe: `VistaEstadio`/motor C4).
8. **Sonido** por evento (muestras CC0 o generador) y símbolos (insignias) como recursos.
9. **C++**: pasar la lógica de `EventosDia` a `nativo/src` con esta versión GDScript como gemela exacta (`probar_nativo` debe dar «FIN. 0 fallos»).
10. **Enganche del calendario por país** cuando la otra sesión lo termine: MEMORIA = pantalla sobria (sin música ni animaciones), el resto = aviso.

## Diferencias maqueta ↔ juego a resolver
- La temporada del juego arranca el 1 de febrero y se cuenta por semanas (mercado de verano semanas 1-6, invierno 18-24, `Mundo.VENTANA_*`); la maqueta usa 300 días y 38 jornadas fijas.
- Los sonidos de la maqueta son sintetizados.
- El arte de la maqueta es código (SVG); para el juego conviene decidir si se sube de nivel con arte aparte (gratis y con licencia comercial).
