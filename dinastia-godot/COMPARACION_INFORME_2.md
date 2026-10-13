# Informe «Auditoría de diseño: Dinastía» (65/100) contra el código · 13-10-2026

El informe se hizo sobre un vídeo anterior: varias críticas ya estaban resueltas.
Estado real, sección por sección (✅ hecho · 🟡 parcial · ⏳ pendiente · 🤝 decisión tuya).

| § | Punto del informe | Estado |
|---|---|---|
| 2 | Bloquear modos de juego tras progresión (retos y carrera abiertos; Jeque, Ayudante y Cantera con logros) | 🤝 Es una decisión de diseño. Fácil de hacer; dime si lo quieres. |
| 3 | Feedback táctil de botones (hover/pulsado, 0,1 s) | ✅ `ui/boton_fx.gd`, para todos los botones |
| 4 | Quitar avatares «chibi» de la rueda de prensa y el teléfono fotorrealista | 🤝 Son piezas que pediste tú; el informe aconseja unificar el estilo. No las toqué. |
| 5 | Césped con normal map y franjas | ✅ (franjas y relieve en `stadium_builder`) |
| 5 | Sombras y SSAO en el campo | ✅ en Alta/Ultra; la calidad adaptativa las baja solas |
| 5 | Blob shadows (disco bajo cada jugador) | ⏳ |
| 5 | Corrección de color estilo TV | 🟡 hay ajuste por ambiente (`Ambience`); sin LUT propia |
| 6 | Crossfade de 0,1-0,2 s entre animaciones | ✅ en el modo jugable (`motor_jugable`) |
| 6 | Patinaje de pies / root motion; IK del pie al balón | 🟡 velocidad de animación ligada al movimiento; sin IK |
| 7 | Física del balón: gravedad, rozamiento, efecto Magnus, rebote | ✅ (`motor_jugable`: gravedad, arrastre, Magnus, botes, postes) |
| 8 | IA por zonas y línea táctica, no perseguir el balón | 🟡 formaciones por zonas; sin líneas de pase por raycast |
| 9 | Carrera de jugador: pase con potencia, ayuda de puntería, cámara cercana | 🟡 tiro con potencia y apuntado existen; cámara «Be a Pro» propia pendiente |
| 10-11 | Ciudad: calles, aceras, props, día/noche con ventanas encendidas, densidad, vida | ✅ casi todo (calles con nombre, aceras de baldosa, ventanas con marco y encendido, tráfico, peatones, metro) |
| 11 | Humo en chimeneas | ⏳ |
| 11 | Efecto tilt-shift (profundidad de campo) en la vista aérea | ⏳ solo Forward+; lo preparo si quieres |
| 12 | La ciudad alimenta el partido (Centro médico, Tienda, Academia...) | ✅ (instalaciones con efecto real) |
| 13 | Público con butacas/hinchas 3D, no carteles | ✅ |
| 13 | Conos de luz de los focos de noche | ✅ hoy (`_cono_de_luz`) |
| 13 | Techo sí/no como bonus de confianza local | ⏳ no verificado |
| 14 | Gráfico radial de atributos en la ficha | ✅ hoy (`ui/componentes/radar_atributos.gd`) |
| 14 | Pestaña «Dinámicas de vestuario» que explique la moral | 🟡 existe Camarín; falta el «por qué» |
| 15 | Rueda de prensa con consecuencias; no anunciar «respuestas libres» si no hay IA | 🟡 revisar el rótulo |
| 16 | Sorteo en estudio de TV, sin presentador flotando | ✅ rehecho el 25-9 |
| 17 | La casa del jugador dentro de la ciudad | ✅ finca con la Casa Grande; y ahora se entra a casas y bares |
| 18 | CSV con errores: decir la fila exacta | 🟡 el JSON dice la línea; revisar el CSV |
| 18 | «Recolector de basura» del historial (guardado) | ⏳ medir el tamaño del guardado a 20 temporadas |
| 19 | Instanciado y agrupado | ✅ (MultiMesh, troceo, LOD jerárquico) |
| 19 | Carga asíncrona con pantalla de carga | 🟡 pantalla de carga con consejos hoy; construcción aún en un solo hilo |
| 19 | Simulación en hilo secundario | ⏳ la semana tarda 150 ms con 6 ligas: no hace falta aún |
| 19 | Entradas de teclado atascadas al salir del teléfono | ⏳ probar |

**Lo que he hecho hoy a partir del informe:** feedback de botones, radar de atributos,
pantalla de carga con consejos (9 idiomas) y haces de luz de los focos.
**Pendiente que te propongo, por orden de valor:** (1) bloquear modos tras progresión;
(2) unificar el estilo de prensa y teléfono (decisión tuya); (3) blob shadows y
tilt-shift; (4) medir el guardado a 20 temporadas.
