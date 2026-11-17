# Avance por días: del diseño al juego (rama `avance-por-dias`)

Diseño aprobado por el dueño (16 y 17-11): `docs/04_auditorias/maqueta_avanzar_2026-11-16.html` (también publicada como artefacto). Reglas y decisiones: `docs/PLAN_GENERAL.md`, sección «AVANCE EN EL TIEMPO POR DÍAS». Esta rama es APARTE: no toca `main` ni la rama de trabajo; no hay PR hasta que el dueño lo pida.

## Qué existe hoy en el juego (y se reutiliza)
- `nucleo/eventos_fecha.gd` (`EventosFecha`): eventos de calendario por semana (liga, copa, continental, mercado, fin); `ui/componentes/calendario_semanas.gd` y `fila_proximos.gd` los muestran.
- `ui/componentes/evento_pantalla_completa.gd` (`EventoPantallaCompleta`): base de las pantallas completas.
- Menú de inicio: `TableroInicio` + `MosaicoTarjetas` (el mosaico REAL; las tarjetas de la maqueta son solo un ejemplo).
- Calendario por país (`nucleo/calendario.gd`, `Calendario.del_anio`): lo trabaja OTRA sesión (rama `ccr-bd198c7b-7akaeg`). Aquí NO se escribe ninguna fecha ni texto de memoria.

## Los eventos NACEN DE UNA CAUSA (decisión del dueño, 17-11)
Los eventos son detonables: pasan POR ALGO, no por un día fijo, y no importa que sean muchos. Tres orígenes (`EventosDia.ORIGEN_*`):
1. **Calendario** (fecha fija de verdad): partidos, sorteos, ventanas de mercado, cobros y sueldos, ventanas internacionales, gala y balances (`EventosFecha`).
2. **Calendario nacional del país** (`Calendario.del_dia`): memoria e independencia = PANTALLA de reflexión (`EventoReflexion`, la memoria sobria y sin efectos), trabajo / fiesta / festividad = AVISO. HECHO en `EventosDia.del_calendario`; todo el texto viene de `Calendario` y `DiasMemoria` (otra sesión, ya en `main`).
3. **Disparadores** (sin día fijo): cada día se evalúa una condición sobre el estado del club o el azar; si se cumple sale el evento CON SU MOTIVO. Los sistemas del juego ya se evalúan así (`semana()`, `sortear()`, `revisar()`): `directiva` (confianza, ultimátum, despido), `crisis_caja`/`insolvencia` (caja), `imprevistos` y `lesiones_absurdas` (azar), `premio_mensual` (media del mes), `eventos_cantera`, `precontratos`, `mesa_agente`, `cesiones`, `disciplina`/`federacion`, `retos_semana`, `ojeadores`, `charlas`. Cada uno aporta su disparador a un registro común; el avance los consulta día a día. Lo que programa otra causa (negociación y presentación tras aceptar una propuesta; lesión tras un partido) sí queda con fecha, pero porque tiene causa.
La maqueta (v8) ya funciona así: estado del club (moral, confianza de la directiva, prestigio, caja, racha, tarjetas), 20+ disparadores y el motivo visible; ver `docs/04_auditorias/EVENTOS_FALTANTES_2026-11-17.md` para los que faltan.

## Pasos (cada uno con su prueba, `banco.sh` en 0 fallos y ningún script de más de 450 líneas)
1. **Modelo de eventos del día** — HECHO en esta rama: `nucleo/eventos_dia.gd` (`EventosDia`: clase PARTIDO / PANTALLA / AVISO, zona de la campana, `del_dia`, `proxima_parada`, `plan_de_parada` y, desde el 17-11, `del_calendario` con el calendario nacional por país) y `pruebas/probar_eventos_dia.tscn` (en `especiales.sh`, porque `banco.gd` está en 450 líneas y no admite secciones nuevas sin partirlo).
2. **Registro de DISPARADORES** — PRIMERA TANDA HECHA: `nucleo/disparadores_dia.gd` (`DisparadoresDia.consultar(m, est)`) observa la directiva (ultimátum y despido), la crisis de caja (golpes avisados, con el texto de `CrisisCaja`), los imprevistos (con el texto del catálogo) y el jugador del mes (`PremioMensual` ahora anota la `semana`). REGLA: SOLO OBSERVA; la simulación semanal (`mundo_p5.gd`) ya ejecuta esos sistemas y aquí no se relanza ninguno (no gasta `Azar` ni mueve la partida); cada hecho sale UNA vez (`est["vistos"]`). Los textos nuevos de interfaz no se escriben aquí: el evento trae `causa` = {id, datos} y la pantalla la redacta con `Idiomas.t`. Prueba: `pruebas/probar_disparadores_dia.tscn` (en `especiales.sh`; 3 mundos). FALTAN los de `EVENTOS_FALTANTES_2026-11-17.md`: precontratos, mesa de agentes, cesiones, eventos de cantera, ojeadores, retos de la semana, charlas, federación, mercado de entrenadores y ofertas de selección.
3. **Pantalla «Avanzar»**: calendario de dos semanas (lunes a domingo) que se desliza y cambia de mes solo, cursor con el escudo del club, parada en cada evento, decoración solo con el día encima (~2,4 s).
4. **Pantallas de evento a pantalla completa** con su animación (premio, propuesta, negociación, presentación, decisión, parte médico, balance); tras cerrar, vuelta al menú.
5. **Avisos con campana** en la tarjeta de su zona del `MosaicoTarjetas` y avance parado.
6. **Día de partido**: «Jugar partido» / «Saltar partido» donde estaba «Avanzar»; tras jugar, el menú «Jugar de nuevo / Ver partido / Jugar momentos específicos».
7. **Previa del partido** con sus seis pestañas (uniforme, estadio, saque inicial, plan de juego, opciones, cámara) y **HUD del partido** (marcador, minimapa, mando táctil con y sin balón; el partido en sí ya existe: `VistaEstadio`/motor C4).
8. **Sonido** por evento (muestras CC0 o generador) y símbolos (insignias) como recursos.
9. **C++**: pasar la lógica de `EventosDia` a `nativo/src` con esta versión GDScript como gemela exacta (`probar_nativo` debe dar «FIN. 0 fallos»).
10. ~~Enganche del calendario por país~~ — HECHO en el paso 1 (`del_calendario`); falta que la pantalla «Avanzar» abra `EventoReflexion` para esas fechas y no la semanal de `DiasMemoria.pendiente`.

## Diferencias maqueta ↔ juego a resolver
- La temporada del juego arranca el 1 de febrero y se cuenta por semanas (mercado de verano semanas 1-6, invierno 18-24, `Mundo.VENTANA_*`); la maqueta usa 300 días y 38 jornadas fijas.
- Los sonidos de la maqueta son sintetizados.
- El arte de la maqueta es código (SVG); para el juego conviene decidir si se sube de nivel con arte aparte (gratis y con licencia comercial).
