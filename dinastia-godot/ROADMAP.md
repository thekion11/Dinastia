# RUTA DE DESARROLLO — DINASTÍA

## PLAN MAESTRO, SEXTA RONDA (pedido del 26-9-2026)

La lista del usuario se ordena por bloques C1 a C19. Cada bloque dice qué hay hoy, qué hacer y su
viabilidad:
- ✅ se puede hacer con lo que hay;
- 🟡 necesita datos o una decisión;
- ⛔ no se hace, y se explica por qué.

Va **antes** que las tandas 4 y 5 de la quinta ronda (B8–B10, B12, B14, B15): el usuario pidió
primero cuidar las **situaciones ilógicas**.

### C1. Coherencia: nada que contradiga la lógica ✅ (primero)
- **Pantalla del estadio** — **HECHO (26-9)**:
  - la tabla, los goleadores y el resultado se ven en una esquina de la transmisión (antes eran
    una mota al fondo);
  - enseña la competición que se juega: en copa los cruces, en el continental el grupo o los
    cruces (antes, siempre la liga del local).
- **Escudos de la sala de prensa** — **HECHO (26-9)**:
  - ya mostraban el escudo actual;
  - ahora también hay rueda tras copa y continental, con los escudos de esa competición.
- **Cambiar escudo o camiseta es noticia grande** — **HECHO (26-9)**:
  - portada, pregunta en la próxima rueda de prensa y comentario del mentor;
  - la afición opina (a unos les gusta, a otros no).
- **El clima del estadio es el de la ciudad** — **HECHO (26-9)** (`nucleo/clima.gd`):
  - hoy el «clima» es una opción del diseñador del estadio, y eso es ilógico;
  - el clima de cada partido saldrá del país y la época del año;
  - afectará a los jugadores (calor, lluvia, nieve, altura) y se nombrará en la rueda de prensa.
- **Auditoría de otras ilógicas**: recorrido por pantallas y sistemas buscando contradicciones.
  Cada una encontrada se anota aquí.

### C2. El banquillo ✅ — HECHO (26-9)
- Plataforma, butaca con respaldo del color del club por jugador, pared, techo y frente de
  metacrilato.
- Botín completo con el tobillo del color secundario, y media hasta la rodilla: ya no se ven
  descalzos.
- Manos sobre las rodillas en la pose sentada.
Mejorar el banquillo (estructura, asientos, techo) y los pies de los suplentes: que apoyen en el
suelo y no atraviesen nada.

### C3. Clubes de cantera con filosofía propia (ej.: Athletic Club) ✅ — HECHO (26-9)
- `nucleo/regiones.gd`.
- `Jugador.region` existe y se guarda.
- Los españoles ya no son todos vascos: bolsa general y bolsa vasca, con un ~9 % de vascos.
- El Athletic («Abando AC» en la base ficticia) solo admite a jugadores de Euskal Herria **por
  origen, no por pasaporte**: un nacido en Bilbao que juega con otra selección entra. La regla
  vale para la IA, para ti, en el mercado y con los agentes libres.
- Su cantera sube con más media y más techo.
- **Corrección de un dato**: el Athletic no ficha solo a jugadores de la ciudad de Bilbao. Su
  política es fichar a jugadores **nacidos o formados en Euskal Herria**:
  - País Vasco;
  - Navarra;
  - el País Vasco francés.
- **Hacer**:
  - una regla de club «solo cantera o región» que el mercado respete, para la IA y para ti si lo
    diriges;
  - más peso de la cantera en ese club;
  - apellidos de los canteranos según su región y nacionalidad (vascos en el Athletic).
- 🟡 Hace falta un dato de **región de origen** en los jugadores, que hoy solo tienen
  nacionalidad. Se añade para los clubes que lo necesiten.

### C4. Historia real de los clubes 🟡 — HECHO (26-9): generada en la base ficticia, real en el pack
- Fundación, estadio, títulos, apodos, rivalidades y datos.
- En la base ficticia (la de por defecto), historia generada coherente.
- En el pack real separable, datos reales.
- 🟡 Los datos reales se cargan en el pack real, no en el juego público (misma regla legal que
  los nombres).

### C5. Instituciones con poder ✅ — HECHO (26-9)
- Presidente de la federación con nombre, corriente y mandato de 4 años, con elecciones y
  noticia. Sus mociones salen antes y hace campaña por ellas.
- Club: presidente, tres accionistas con su porcentaje y su exigencia, y junta trimestral en el
  despacho. Un accionista harto presenta moción de censura.
- Queda: presidente de la confederación continental y cambios de formato de competición.
- **Presidentes de federación y confederación** con nombre y agenda:
  - proponen y cambian reglas (cupos de extranjeros, VAR, formato de copa, calendario, límite
    salarial);
  - hoy ya existe una asamblea que vota el VAR: se amplía.
- **Presidente de tu club, accionistas y reuniones con la directiva**: juntas trimestrales,
  votos y exigencias.

### C6. Medios nuevos y entrevistas más naturales ✅ — HECHO (26-9)
- Entrevistas «al paso» de streamers, podcasts y canales de hinchas: preguntas inesperadas que
  mueven seguidores.
- Streamers, podcasts y entrevistas «al paso» (en el aeropuerto, a la salida del entrenamiento):
  cortas, sin preparar y con preguntas inesperadas.
- Hoy ya existe la rueda formal (B5) y la de pie de campo.

### C7. Hablar con jugadores, presentaciones, minijuegos y exámenes ✅ — HECHO (26-9)
- **Charlas uno a uno** con memoria y promesas que se cobran.
- **Presentación de fichajes**, en el estadio o en la sala de prensa.
- **Minijuego de penales** con un portero que aprende.
- **Licencia C/B/A/Pro** con examen de reglamento vigente y táctica.
- Queda: el minijuego de tiro libre y la trivia del club.
- **Conversación individual con cualquier jugador**: moral, minutos, contrato, vida personal.
  Con tono y memoria, como la rueda de prensa.
- **Presentación de fichajes**: foto con la camiseta y rueda breve; cinemática pendiente de B3.
- **Minijuegos**: penales de práctica, tiro libre al travesaño, trivia del club.
- **Exámenes**: licencia de entrenador (UEFA C → Pro) con preguntas; al aprobar se desbloquean
  ventajas.

### C8. Lesiones absurdas fuera del campo ✅ — HECHO (26-9)
- 14 casos, una cada ~14 semanas, sin `Azar`.
- El toque de queda evita las de noche.
Resbalón en la ducha, mordedura del perro, videojuego, celebración familiar… Son poco
frecuentes, tienen su noticia y se pueden prevenir con normas del vestuario.

### C9. Contratos y jornada laboral según la ley de cada país (2026) 🟡 — HECHO (26-9); México y Egipto marcados para revisar
- Tipos de contrato (profesional, formativo, cesión) y jornada según la ley laboral vigente.
- Ejemplo: en Chile la ley de 40 horas baja a 42 horas semanales en abril de 2026.
- 🟡 Cada país necesita su dato verificado antes de ponerlo en el juego. Se hará por tandas de
  países, con la fuente anotada.

### C10. Instalaciones más profundas ✅ — HECHO (26-9)
- Más niveles (de 5 a 10) y más detalle visible en la ciudad.
- **Trabajadores** con nombre y personalidad en cada instalación: médico jefe, cocinero,
  utilero, jardinero…
- **Eventos** propios de cada instalación: la caldera de la piscina se rompe, el cocinero
  renuncia, una inspección sanitaria…

### C11. Más cantera ✅ — HECHO (26-9)
Visitar entrenamientos de juveniles, eventos (torneo internacional sub-17, un chico que quiere
dejarlo, padres exigentes) y promociones con ceremonia.

### C12. Las otras ramas del club ✅ — HECHO (26-9)
Fútbol femenino, juveniles, futsal y otros deportes, con más peso: resultados propios,
presupuesto, noticias e impacto en la reputación.

### C13. Calendario real: días nacionales y fechas de memoria ✅ — HECHO (26-9)
- Independencias, día del trabajador (1 de mayo) y fechas nacionales de cada país.
- **11 de septiembre** en Chile (1973) y en EE. UU. (2001) como jornada de memoria, con respeto:
  minuto de silencio y sin festejos.
- Eventos internacionales y nacionales reales (Mundial, Juegos Olímpicos, Copa América…).
- El mentor explica cada fecha.

### C14. Mejorar el globo terráqueo ✅ — HECHO (26-9)
Relieve, fronteras y capitales, países con datos (liga, clubes, ranking) y clic para ver la
ficha del país.

### C15. Política y Estado 🟡 — HECHO (26-9), partidos y personas ficticios
- **Elecciones según la estructura de cada país** (presidencial, parlamentaria, monarquía
  parlamentaria…) y una conversación breve del mentor que explica cómo funciona ese Estado.
- Gobiernos con distintas posturas que influyen en el fútbol y la ciudad: subvenciones,
  seguridad en estadios, impuestos, obras públicas.
- 🟡 **Regla**: partidos y políticos **ficticios** y posturas neutrales. Nada de partidos ni
  personas reales: es terreno sensible y el juego se publica.

### C16. Religión 🟡 — HECHO (26-9), solo festividades del país
- **Sí**: festividades por país en el calendario (Navidad, Ramadán, Semana Santa, Diwali…) y su
  efecto (partidos en fechas especiales, jugadores que ayunan).
- ⛔ **No**: atribuir una religión real a jugadores que imitan a personas reales identificables.
  Es un dato personal sensible.
- Alternativa: un rasgo **ficticio y opcional** del jugador generado, nunca copiado de una
  persona real.

### C17. Ficha de los jugadores «simulados» ✅ / ⛔ en parte — HECHO (26-9)
- **Sí**: pierna débil, número, estadísticas por temporada, historial de premios por año,
  nacionalidad, edad, posición y club.
- ⛔ **No**: la situación sentimental real de personas reales.
- Alternativa: vida personal **generada** (pareja, hijos) para todos los jugadores, sin copiar a
  nadie real.

### C18. Comparar con los videos de referencia 🟡
- En `marca/referencia/` están `ea_fc25_referencia.mp4` y `ejemplo-partido.mp4`, más
  fotogramas ya extraídos.
- En este entorno no hay `ffmpeg` para extraer más: se trabaja con los fotogramas existentes, y
  el usuario puede añadir más capturas.
- Se hará una tabla de «ellos / nosotros» por aspecto (cámara, HUD, jugadores, estadio,
  menús).

### C20. La portada como periódico ✅ — HECHO (26-9)
- Pedido con una imagen de referencia de otro juego: cabecera de color, franja, titular enorme,
  bajada con la cara del protagonista, tabla de la liga y foto.
- Seis cabeceras propias del juego: El Pelotazo, Diario La Banda, Tribuna Deportiva, ¡Golazo!,
  La Pizarra y El Crack.
- Contenido real de la partida.
- Se abre desde el archivo de portadas y sola tras cada partido que sale en portada (se puede
  desactivar).
- Se guarda como imagen en `user://portadas/`.

### C19. Revisar pendientes del informe y auditoría final ✅
- Al final de este gran plan: repaso del informe externo (62/100), del LEEME, de todos los
  «queda» de las rondas y una partida larga de prueba.
- Informe final al usuario.

### ORDEN
1. **Tanda A**: C1 (coherencia), C2 (banquillo) y C3 (clubes de cantera).
2. **Tanda B**: C5 (instituciones), C6 (medios nuevos), C7 (hablar con jugadores,
   presentaciones, minijuegos, exámenes) y C8 (lesiones absurdas).
3. **Tanda C**: C10 (instalaciones), C11 (cantera), C12 (ramas) y C17 (ficha del jugador).
4. **Tanda D**: C13 (calendario), C14 (globo), C15 (política), C16 (religión), C4 (historia) y
   C9 (contratos).
5. **Después**: las tandas 4 y 5 de la quinta ronda. Al final, C18 y C19.


## PLAN MAESTRO, QUINTA RONDA (pedido del 25-9-2026)

Pedido completo del usuario:
*"infraestructura del estadio, cinemáticas en las acciones, mejoras visuales y de texto, ciudad 3D y
su funcionamiento, optimización, menú propio estilo Los Sims para personalizar al personaje, mayor
realismo, ropa y accesorios, mascotas 3D en el campo, eventos con mejor animación, mini animaciones
para que el juego se sienta vivo, música libre en español, tipos de simulación de partido, ajustes
en una barra desplegable, integración visual, más estadios, entrevistas, nuevos eventos, y revisar
lo que falta del LEEME y de los archivos profundos"*.

**Cómo leer este plan.** Cada bloque dice:
- qué hay HOY, verificado contra el código el 25-9 y no de memoria;
- qué se hará, en pasos;
- cómo se comprueba que quedó bien;
- si es viable ahora:
  - ✅ viable con lo que hay;
  - 🟡 viable pero depende de algo externo (un asset, una licencia, una prueba en un PC real);
  - ⛔ no viable hoy, con el motivo.

Orden sugerido al final. Regla de siempre: cada bloque se cierra con el banco en 0 fallos, capturas
reales y commit + push.

### B1. Ajustes del partido en una barra desplegable ✅ (pequeño, primero)
- **Hoy**: `ui/estadio.gd` pinta sueltos sobre la transmisión el modo Manager/Jugador, Nombres,
  Velocidad y las cámaras.
- **Hacer**:
  - un botón ⚙ que despliega un cajón lateral animado con modo, nombres, velocidad, cámara, calidad
    gráfica, volumen de grada y de música, y los rótulos de jugada;
  - en pantalla solo quedan el marcador, el reloj y el ⚙.
  - El cajón recuerda su estado (`user://ajustes.cfg`) y se cierra solo a los 6 s sin tocarlo.
  - Mismo patrón en `ui/partido_vivo.gd` (velocidades, "Ver en 3D", "Al próximo gol", "Al final").
- **Comprobar**: captura con el cajón cerrado y abierto, y cada ajuste cambia algo de verdad (banco).

### B2. Tipos de simulación de partido ✅
- **Hoy** existen cuatro formas de jugar un partido:
  - "Simular sin dirigir" y "Simular toda la temporada" (resultado directo);
  - el partido en vivo de texto (`PartidoVivo`);
  - la transmisión 3D (`estadio.gd`);
  - el modo Jugador (FC).

  Están repartidas en botones distintos y sin nombre común.
- **Hacer**:
  - Un selector único antes de cada partido, con cinco modos:
    1. **Instantáneo**: solo el resultado.
    2. **Resumen**: texto con los momentos clave, 30 s.
    3. **Radar 2D**: la pizarra táctica en vivo (ya existe `radar_partido.gd`).
    4. **3D destacados**: la simulación corre y la cámara solo muestra las jugadas de peligro, con
       repetición.
    5. **3D completo**.
  - Más el modo Jugador (FC) aparte.
  - Preferencia por competición (por ejemplo, la copa en 3D y la liga en resumen).
- **Comprobar**: los cinco modos dan el MISMO resultado con la misma semilla (la simulación no
  depende de cómo se mira); ya hay precedente en el banco.

### B3. Cinemáticas en las acciones ✅
- **Hoy** hay escenas cinemáticas solo en el sorteo (`sorteo_escena3d.gd`), la rueda de prensa
  (`rueda_prensa_escena3d.gd`) y la salida del túnel (sonido y cámara).
- **Hacer**: un director de cinemáticas común (`visor/cinematica.gd`) con planos definidos como
  datos (cámara, objetivo, duración, curva y corte) y saltables con un clic. Momentos:
  - Partido:
    - salida del túnel con los dos equipos en fila;
    - himno y saludo;
    - gol, con repetición desde dos ángulos (ya se graba la jugada, falta la cámara);
    - roja con el jugador saliendo;
    - lesión con camilla;
    - final con festejo o lamento.
  - Fuera del partido:
    - presentación de un fichaje (estadio con el jugador y la camiseta);
    - firma de contrato;
    - campeón con levantamiento de copa;
    - ascenso y descenso;
    - despido del DT;
    - inauguración de obra (la ciudad 3D con la grúa que se retira).
- **Comprobar**: una prueba recorre cada cinemática y captura el primer, el medio y el último
  plano; ninguna deja la cámara dentro de una malla (se comprueba la distancia a la geometría).

### B4. Eventos: más, y mejor contados ✅
- **Hoy** hay 16 eventos de prensa (`nucleo/prensa.gd`: agente, espía, filtración, hostil, lobby
  arbitral, provocación, retiro joven, virus FIFA…) más los de vestuario y directiva. Se resuelven
  con una tarjeta de texto (`_pintar_decision`).
- **Hacer**:
  - Presentar cada evento con ilustración o escena 3D corta (el personaje implicado con
    `PersonaRealista`), sonido propio y consecuencias visibles después (titular, cambio de moral
    con animación).
  - **Eventos nuevos** (de `instruciones profundas/instrucciones_extras.txt`, no encontrados en el
    código):
    - juegos mentales en el túnel: provocar al DT rival o presionar al árbitro localista;
    - escándalo en redes con un video viral;
    - capitán que pide hablar;
    - hincha fallecido y minuto de silencio;
    - jugador que pide cambio de posición;
    - patrocinador que exige aparecer en una rueda de prensa;
    - apuestas ilegales investigadas;
    - huelga de jugadores por sueldos impagos;
    - derbi con amenaza de seguridad.

    Cada uno con al menos dos salidas y un efecto que dure semanas.
- **Comprobar**: el banco sortea cada evento con semilla fija y aplica cada salida, sin cuelgues y
  con el efecto medible.

### B5. Entrevistas ✅ / IA conversacional ⛔
- **Hoy** la rueda de prensa tiene sala 3D, planos de cámara y preguntas de opción múltiple.
- **Hacer**:
  - periodistas con personalidad (sensacionalista, técnico, local, extranjero) y memoria de tus
    respuestas anteriores;
  - repreguntas;
  - **lenguaje corporal**: un temporizador. Si tardas en responder, los periodistas "huelen sangre"
    y la siguiente pregunta aprieta más (está en los archivos profundos);
  - tono de respuesta (calma, soberbia, evasiva) con efecto en árbitros, directiva y vestuario;
  - titulares del día siguiente citando tu frase;
  - entrevista de pie a pie de campo al terminar el partido, más corta.
- ⛔ **"Charla con IA que evalúa tu tono libre"**: necesita un modelo de lenguaje en línea, con
  coste por uso y sin funcionar sin conexión. Alternativa viable ✅: texto libre con un
  clasificador local de palabras clave y tono (ya existe `_charla_libre()` en el camarín, se
  amplía).

### B6. Infraestructura del estadio, a fondo ✅
- **Hoy**:
  - 16 estilos, 6 formas y hasta 5 bandejas (150.000 personas);
  - tramos por tribuna, componentes, pista de atletismo, banderas, pantallas en rotación y vallas
    LED.
- **Hacer**:
  1. **Colores por sección** (pedido del usuario, sin empezar, ver 2-sexies): cada bandeja, arcos,
     red, líneas, focos, LED, banquillos y butacas por separado.
  2. **Exterior del estadio**: fachada (ladrillo, vidrio, membrana, hormigón), accesos, taquillas,
     tienda, estacionamiento y entorno.
  3. **Instalaciones internas visibles**: palcos VIP, zona de prensa, sala de trofeos y museo,
     vestuarios. Cada una con su coste, mantenimiento e ingreso en `nucleo/estadio_propio.gd`.
  4. **Obras por etapas**: andamios y grúa en 3D mientras se construye, con plazo real y aforo
     reducido durante la obra.
  5. **Techo retráctil y césped híbrido o artificial**, con efecto en lesiones y en el clima.
  6. **Más estilos**: 16 → 24 (coliseo, estadio-caja inglés, estadio de montaña con ladera,
     flotante, cúpula, estadio del desierto, sudamericano de hormigón, japonés moderno) y
     capacidad sin tope artificial, como Dream League (hoy 150.000).
  7. **Túnel navegable** (2-septies), cuando exista el modo caminar.
- **Comprobar**: `captura_formas_estadio.gd` ampliada a todos los estilos, sin nada flotando ni
  atravesado (auditoría automática de mallas contra el césped y las gradas).
- **Hecho (25-9-2026)**: 1 (colores por sección), 2 (fachada y exterior: taquillas, tienda,
  estacionamiento), 5 (superficie con efecto en lesiones y desgaste; techo retráctil sin
  lluvia dentro) y 6 (24 estilos). Queda:
  - 3 (instalaciones internas visibles);
  - 4 (obras con andamios y grúa);
  - 7 (túnel navegable);
  - la paleta de las vallas LED;
  - las formas geométricas nuevas (hoy los estilos nuevos combinan las 6 formas existentes).

### B7. Ciudad 3D y su funcionamiento ✅
- **Hoy**: `ui/ciudad_vista.gd` (340 líneas) muestra `CityBuilder` y `nucleo/ciudad.gd` lleva
  terrenos, negocios, vecinos, permisos y seguridad; hay coches importados que no se usan.
- **Hacer**:
  - clic en cada edificio para abrir su ficha y construir o mejorar desde el 3D;
  - obra con etapas visibles;
  - día/noche según la hora del juego;
  - tráfico con los coches ya importados y peatones de `PersonaRealista` en baja resolución;
  - días de partido con la ciudad llena y banderas en las calles;
  - indicadores flotantes (ingreso semanal, humor del barrio);
  - eventos de ciudad (protesta vecinal, festival, obra pública que corta un acceso);
  - cámara libre con órbita y zoom.
- **Comprobar**: construir desde el 3D mueve el dinero igual que desde el panel (banco), y hay
  capturas de día, noche y día de partido.
- **Hecho (25-9-2026)**:
  - clic con ficha y construcción desde el 3D;
  - obra con andamio y grúa;
  - rótulos flotantes y el humor del barrio;
  - día de partido;
  - cámara libre.

  El día/noche y el tráfico ya existían. Queda:
  - peatones de `PersonaRealista`;
  - eventos de ciudad (protesta, festival, corte de acceso);
  - que la hora del ciclo siga la del juego.

### B8. Personaje propio: creador estilo Los Sims ✅ / 🟡
- **Hoy**: `PanelAspectoDT` es un retrato 2D (`CaraDT`: corte, volumen, traje) y el mentor usa
  `PersonaRealista` recoloreable, sin esqueleto.
- **Hacer**:
  - **Pantalla propia a pantalla completa**: el personaje 3D girando en un estudio con luz de 3
    puntos y pestañas a los lados (Cuerpo · Cara · Pelo · Ropa · Accesorios · Guardarropa), con
    deshacer, aleatorio y guardado de conjuntos.
  - **Cuerpo** ✅: estatura, complexión, hombros y barriga, con escalas de huesos sobre el modelo
    Quaternius con esqueleto.
  - **Cara** 🟡: forma de cara, nariz, ojos, mandíbula y barba. Requiere un modelo con blendshapes;
    el candidato es MakeHuman (CC0), exportado por Blender con `herramientas/blender_a_glb.py` en
    el PC del usuario, porque en la nube no hay Blender.
  - **Pelo** ✅: mallas de pelo intercambiables con color.
- **Comprobar**: el personaje creado aparece igual en la rueda de prensa, en la banda y en las
  cinemáticas (el mismo `aspecto` guardado en la partida).

### B9. Ropa y accesorios ✅
- **Hacer**:
  - un catálogo de prendas: traje, chándal, abrigo largo, polo, camisa, bufanda, gorra, gafas,
    reloj, auriculares, anillo de campeón;
  - cada prenda es una malla sujeta a un hueso (`BoneAttachment3D`) o una capa del shader, con
    color y patrón (se reutilizan los 26 patrones del shader de equipación);
  - una tienda que se desbloquea con logros y dinero del DT (conecta con "invertir el salario" de
    los archivos profundos);
  - ropa según el clima (abrigo en invierno).
- **Assets** 🟡: prendas CC0 (Quaternius "Modular Character Outfits", ya usado; Kenney) o hechas en
  Blender.

### B10. Mascotas 3D en el campo ✅ / 🟡
- **Hoy** no existe sistema de mascota (`mundo.gd` lo documenta; el "peluche de la mascota" del
  HTML quedó fuera).
- **Hacer**:
  - Una mascota por club, elegida o generada: un animal ligado al escudo (león, águila, lobo, toro,
    perro) o una persona disfrazada.
  - En el campo:
    - sale con los equipos;
    - baila en la banda en el entretiempo;
    - festeja los goles del local;
    - se desanima con los goles en contra.
  - Además, peluche en la tienda con ingreso comercial, nivel de popularidad y evento "la mascota
    se hace viral".
- **Assets** 🟡: animales animados CC0 de Quaternius (Ultimate Animated Animals); la persona
  disfrazada con `PersonaRealista` y una cabeza grande.

### B11. Mini animaciones y "juego vivo" ✅
- **Interfaz**:
  - transiciones entre pestañas;
  - cifras que cuentan hacia arriba (dinero, media);
  - tarjetas que aparecen escalonadas y botones con rebote;
  - aviso de gol que late;
  - reloj de la semana animado.
- **Mundo**:
  - banderas del estadio con viento (shader);
  - público con olas en los goles;
  - clima con partículas (lluvia, nieve, niebla; hoy solo se oye);
  - pájaros en el menú;
  - fondo del menú con el estadio de tu club de noche.
- **Personas**: el DT en la banda reacciona (brazos, se agacha, patea una botella; está en los
  archivos profundos) y los suplentes calientan (dominadas y trote, ya empezado).
- **Comprobar**: el coste en FPS de cada una medido en `diagnostico_fps_partido`, con una opción
  "animaciones reducidas" en Ajustes.

### B12. Música libre en español 🟡
- **Hoy**: `nucleo/musica.gd` compone 6 piezas en el momento, sin archivos, y suben o bajan con la
  partida.
- **Hacer**:
  - sumar una radio del club con canciones de licencia libre: CC BY o CC BY-SA, **nunca NC** si el
    juego se va a vender;
  - buscar en español en Jamendo, Free Music Archive y ccMixter (cumbia, rock latino, pop, himnos
    de hinchada);
  - cada pista con su crédito en una pantalla de créditos musicales;
  - la música procedural se queda para los momentos que cambian (partido, tensión).
- 🟡 Las canciones con voz en español y licencia libre son pocas: hay que elegirlas a mano, y el
  usuario debe aprobar cada una.
- 🟡 `*.ogg` va por LFS en `.gitattributes` y desde la nube no se puede subir a LFS: hay que hacer
  una excepción como con `assets/personas/*.glb`, o que el usuario las suba desde su PC.

### B13. Mejoras visuales, de texto e integración visual ✅
- **Visual**:
  - un sistema de diseño único (`ui/tema.gd`: colores, tipografías, radios, sombras, espaciados)
    aplicado a todas las pantallas; hoy hay estilos repartidos en `principal.gd`;
  - llevar a todas las pantallas el patrón de tarjeta con anillo de `TableroInicio`;
  - iconos propios en vez de emojis;
  - la grada con textura estirada (pendiente del análisis externo).
- **Texto**:
  - revisión completa de ortografía, tono y coherencia (tú/usted, términos de fútbol del mismo
    país);
  - textos de eventos y noticias más largos y con variantes;
  - un glosario ampliado.
- **Integración**: que el 3D y el 2D compartan colores y tipografía (los rótulos del partido 3D con
  la misma fuente de la interfaz).

### B14. Optimización y velocidad ✅
- **Hoy**:
  - arranque 0,9 s;
  - estadio 2,9 s;
  - `principal.gd` con 14.300 líneas;
  - el retrato real ya no decodifica fotos grandes.
- **Hacer**:
  1. **Medir antes de tocar**: el perfilador de Godot sobre avanzar una semana, avanzar una
     temporada, abrir el plantel y abrir el estadio.
  2. Simular en segundo plano (hilo) las ligas que no son la tuya.
  3. Caché de pantallas que no cambian.
  4. Compilar los shaders de antemano (evita tirones la primera vez).
  5. Nivel de detalle de jugadores y público por distancia.
  6. Seguir partiendo `principal.gd` (plantel, mercado, club).
  7. Guardado incremental.
- **Comprobar**: una tabla de tiempos antes/después en el LEEME, cada número medido 3 veces.
- 🟡 Medir en el PC modesto real (Intel UHD): aquí solo hay render por software.

### B15. Mayor realismo ✅
- **Hoy**: lo pedido en los archivos profundos está hecho en buena parte:
  - vestuario con clanes y salud mental;
  - representantes y redes ("funas");
  - árbitros con perfil tarjetero;
  - interinato, academia 10-16 y ocupación hostil;
  - espionaje y lobby arbitral.
- **Hacer**:
  - **Calibrar la simulación contra datos reales**: goles por partido, % de local, tarjetas,
    lesiones por temporada y distribución de resultados, con una prueba que juegue 10 temporadas y
    compare contra rangos reales.
  - Presupuestos y edades a escala FC en el pack real (pedido en los archivos profundos).
  - Crecimiento de media por temporada visible por jugador.
  - Exigencias de los jugadores (minutos, instalaciones, cómodo con la táctica).
- ⛔ "Estadísticas iguales a FC 26 y dorsales reales": datos con licencia de EA; solo vale en el
  pack privado del usuario, nunca en lo publicable.

### B16. Más variantes de estadio ✅
Ver B6.6. Además:
- estadios de los rivales con más forma y color propio (hoy 6 formas);
- estadios históricos o legendarios desbloqueables por logros;
- editor de fachada.

### B17. Revisión de faltantes: LEEME y archivos profundos
Cruzado contra el código el 25-9-2026 (`grep` por concepto), no de memoria.

**Ya hechos**, aunque el ROADMAP o las notas los daban por pendientes:
- el Modo Director de Cantera 10-16 (Fase 3.5, cerrado en la ronda del análisis externo);
- el selector de escudos especiales (`principal.gd`, `Escudo.especiales_desbloqueados()`);
- los eventos de ocupación hostil, virus FIFA, retiro joven, espía, filtración del agente,
  provocación y lobby arbitral;
- clanes, salud mental, representantes y funas;
- la tabla y los goleadores en la pantalla del estadio.

**Pendientes reales**, repartidos en los bloques de arriba:
- juegos mentales en el túnel → B4;
- charla con tono libre → B5;
- colores por sección → B6;
- mascota → B10;
- lenguaje corporal del DT en la banda → B11;
- invertir el salario del DT (licencias, acciones de clubes, agente propio) → B9 y un bloque de
  economía personal;
- "escuela táctica" que bautiza tu estilo;
- fondos buitre sobre juveniles (hay 3 archivos que lo mencionan, falta confirmar que tenga efecto);
- el mercado "a ciegas" sin atributos numéricos, como opción de dificultad;
- el Mundial y las copas de Asia, Oceanía y África (existen selecciones; falta revisar el torneo);
- los 5 bloques de la Fase 4 (mercado gris, insolvencia, reglamento, selecciones, meta).

**Nota**: el listado de 750 + 300 ideas se re-cruza por bloques antes de cada fase, porque en este
proyecto "estaba pendiente" resultó "ya estaba hecho" muchas veces.

**No viables hoy** ⛔, con su motivo:
- **IA conversacional en línea**: coste por uso, necesita conexión y es incierta en Android.
- **"Jugar 10 temporadas ×3 como humano"**: se reemplaza por pruebas automáticas de 10 temporadas
  con 3 semillas, que sí se pueden correr.
- **Estadísticas y dorsales de FC 26**: los datos tienen licencia.
- **Probar en un Android y en un PC modesto reales**: esta sesión no tiene esos dispositivos.
- **Caras por morphs sin un modelo nuevo**: ver B8.

### INVENTARIO DE MODELOS 3D SIN USAR (25-9-2026, a pedido del usuario)
Cruzado con el código (cada archivo buscado por nombre en `.gd`, `.tscn` y `.json`).

**Ya integrado hoy:** los peinados, la barba y las cejas de *Universal Base Characters* (CC0). Los
jugadores eran calvos; ahora llevan el corte de su retrato 2D (`visor/pelo_q.gd`).

**Sin usar**, cada uno con el bloque del plan donde encaja:

| Modelo | Dónde está | Licencia | Para |
|---|---|---|---|
| *Downtown City MegaKit* (153 piezas modulares: fachadas de ladrillo, cornisas, techos, calles, veredas, puertas) | `recursos/…MegaKit[Standard].zip` | CC0 (Quaternius) | B7 ciudad 3D: barrios de verdad alrededor del complejo |
| *Kenney Car Kit* (45 autos) | `recursos/modelos3d/cc0_web/kenney_car-kit` | CC0 | B7 tráfico y estacionamientos |
| 6 edificios de *Kenney City Kit Commercial* (building-b/d/f/h/j/l) | `assets/ciudad/kenney_comercial` | CC0 | B7 (ya importados, sin colocar) |
| `entrada-jugadores/model.glb` (entrada de jugadores) | `recursos/modelos3d/` | 🟡 confirmar fuente | B6 y B3: túnel y salida al campo |
| `soccer_field/Soccer Field.fbx` | `recursos/modelos3d/cc0_web` | CC0 | B16 como referencia de estadio pequeño o amateur |
| `staircase-modular-frame-steel` | `recursos/modelos3d/*.zip` | 🟡 confirmar | B6 escaleras y accesos exteriores |
| `movil-s26` (teléfono) | `recursos/modelos3d/` | 🟡 confirmar | B3 y B4: cinemática del DT leyendo redes, eventos virales |
| `oficina_dt` / `interior-15-minimalist` (interior) | `recursos/modelos3d/` | 🟡 confirmar | B3 despacho del DT: firmas, despidos, reuniones |
| `ciudad_complejo` / `3.zip` (complejo residencial) | `recursos/modelos3d/` | 🟡 confirmar | ya existe una versión en `assets/ciudad/complejo_residencial.glb` |
| `gt-racing-2-montreal` (circuito) | `recursos/modelos3d/*.zip` | 🟡 confirmar | sin uso claro: podría ser un evento de ciudad |
| *Modular Character Outfits – Fantasy* (Peasant, Ranger) | `recursos/…Fantasy[Standard].zip` | CC0 | B9 solo como base de capucha o abrigo; es ropa medieval |

Los 🟡 vienen de sitios de modelos (Sketchfab o similares) sin licencia anotada. Antes de publicar,
hay que confirmarla, igual que las demás filas 🟡 de `LICENCIAS.md`.

### ORDEN SUGERIDO
Primero lo que más se nota con menos riesgo, después lo que necesita assets externos.
1. **Tanda 1**: B1 (ajustes desplegables), B2 (tipos de simulación), B11 (mini animaciones de
   interfaz), B13 (sistema de diseño y texto). **Hecha (25-9-2026).**
2. **Tanda 2**: B3 (cinemáticas), B4 (eventos nuevos y presentación), B5 (entrevistas).
   **Hecha (25-9-2026)**; ver LEEME. Queda de B3: presentación de fichajes, trofeo, ascenso y
   descenso, despido e inauguración de obras.
3. **Tanda 3**: B6 y B16 (estadio a fondo y variantes), B7 (ciudad 3D).
4. **Tanda 4**: B8 y B9 (creador estilo Sims, ropa y accesorios), B10 (mascotas).
5. **Tanda 5**: B12 (música; necesita aprobación de las pistas), B14 (optimización medida) y B15
   (calibración de realismo con 10 temporadas × 3 semillas).

---


## ANÁLISIS EXTERNO DEL 25-9-2026 (62/100): lo hecho y lo que queda
Detalle completo en `LEEME.md`, arriba de todo.
- [x] Contraseña del keystore fuera del repositorio (`export_credentials.cfg`, no se sube).
  - [ ] **Dueño**: cambiar la contraseña, porque la vieja sigue en el historial de git.
- [x] Clubes, ligas, copas, árbitros y nombres ficticios por defecto; lo real va aparte en
  `datos/pack_real.json`, que los presets publicables excluyen.
- [x] Auditoría de licencias (`LICENCIAS.md`); todo lo 🔴 se excluyó de la exportación.
  - [ ] **Dueño**: confirmar la fuente de los 🟡 (Sketchfab, Meshy, mocap de Gumroad, Canva,
    texturas de la Tierra) o reemplazarlos. Lista en `LICENCIAS.md`.
- [x] Equipación pintada por shader, nombres sobre los jugadores y la columna misteriosa resuelta.
  - [ ] Pendiente: la grada con textura estirada. Mejoró al quitarle las sombras, pero no se rehízo
    su textura.
- [x] Tutorial guiado por modo, rehecho como tutorial inmersivo: prólogo, mentor con datos de tu partida y misiones por modo.
- [x] Modelo Ronaldo (`futbolista_cr7`) borrado del proyecto, con sus fuentes y su código.
- [x] Cubierta de los nombres reales activa con el pack real ("C0lo-C0lo"); las caras reales se mantienen.
- [x] Moneda seleccionable, academia de 10 a 16 años, contraste de la previa y buscador.
- [x] Rendimiento: arranque 12,3 s → 0,9 s, estadio 25,6 s → 2,9 s, triángulos -75 %, y calidad
  adaptativa por debajo de 40 FPS.
  - [ ] Medir los FPS en el PC modesto de verdad (Intel UHD); aquí solo hay render por software.
- [x] `principal.gd`: dos paneles más a componentes (`PanelAspectoDT`, `PanelClubDentro`), 14.395 líneas.
  **No** sacar de `Principal` lambdas conectadas a señales de `mundo` (el juego se cae al salir; ver
  `LEEME.md`).

## MODULARIZACIÓN DE `principal.gd` — CERRADA (25/26-9-2026): 15.589 → 14.640 líneas
Pedido explícito del usuario: reducir la fragilidad de un archivo monolítico del que depende todo
el juego -"15 mil líneas todas juntas una dependiente de otra es un gran riesgo". Cinco tandas,
cinco patrones distintos según el acoplamiento real de cada pantalla, todas verificadas con banco +
captura real pulsando botones de verdad, no solo mirando que pinten:
- [x] `ui/componentes/panel_mercado.gd` (`PanelMercado`) -componente de escena con estado propio
  (filtros, negociación activa)-.
- [x] `ui/componentes/tabla_competicion.gd` (`TablaCompeticion`) -clase estática, sin estado, para
  lo que solo "pinta datos" sin interacción propia-.
- [x] `ui/componentes/ficha_jugador_info.gd` (`FichaJugadorInfo`) -8 de las 14 funciones de la
  ficha del jugador: las de SOLO LECTURA (estadísticas, cabeza, promesa, habilidades, historial
  médico, vida personal, historial de crecimiento, informe ciego). Mismo patrón estático.
- [x] `ui/componentes/ficha_jugador_acciones.gd` (`FichaJugadorAcciones`) -las 5 funciones de la
  ficha que quedaban, con botones que mutan el mundo (desarrollo prioritario, reconversión, marca/
  fidelidad, similares, venta/rescisión). **No hizo falta el patrón de señales de `PanelMercado`
  que se estimaba aquí** (15-20 señales): al pintarse una sola vez por refresco de ficha, sin ciclo
  de vida propio, bastó una clase estática que recibe la acción como parámetro `Callable` -un
  tercer patrón, más liviano que señales para este caso concreto de "una sola pintada, no un nodo
  persistente"-. `principal.gd` sigue siendo dueño de la mutación real y se la pasa en un closure.
  Verificado pulsando los botones de verdad (`Button.pressed.emit()`), no solo mirando que pinten
  -la lección del bug crítico del mismo día-. De paso, la auditoría reveló y se borró
  `_responder_oferta()`, código muerto desde que `PanelMercado` se conectó por señal (reemplazada
  por `_responder_oferta_mercado`). `principal.gd`: 15.589 → 15.036 líneas en las tres tandas de
  hoy. Ver detalle en `LEEME.md`.
- [x] `ui/componentes/panel_finanzas.gd` (`PanelFinanzas`) -4 de las 5 funciones de la pestaña
  Finanzas: `pintar_balance_y_caja` (pura, sin botones), `pintar_auspicio`/`pintar_patrocinio`/
  `pintar_banco` (con `Callable`, mismo patrón que `FichaJugadorAcciones`). Confirmado con grep: eran
  531 líneas, más que el "~200 líneas" del plan externo -tercera vez que se repite esta
  subestimación-. `_pintar_finanzas` (precio de entrada, tienda, proyección anual, resumen, libro de
  movimientos) se queda en `principal.gd` como orquestador, igual que `_ver_ficha`. De paso se borró
  `_puesto_en_liga()`, otra función muerta -su único llamador era `_pintar_auspicio`, ya movido-.
  Verificado pulsando "Firmar" auspicio, lanzando una campaña y tomando un crédito de verdad, con un
  tropiezo real en la propia prueba (buscaba el botón de campaña por "contiene EUR" y encontraba el
  de la tienda del club) corregido antes de darla por buena. `principal.gd`: 15.036 → 14.707 líneas
  en esta tanda. Con las cuatro tandas de hoy: 15.589 → 14.707. Ver detalle en `LEEME.md`.
- [x] `ui/componentes/panel_plantel.gd` (`PanelPlantel`) -la pestaña "Mi plantel", la última de la
  lista. Aquí el tamaño SÍ era el esperado (67 líneas), pero apareció un acoplamiento nuevo: pintar
  una fila de jugador navega ella sola (abre ficha, cambia de pestaña) y el color de las cabeceras
  pasa por `_color_de_paleta()` -la traducción de TEMA, distinta de `_color_accesible()`/`_pal_*()`
  que usan los otros cuatro componentes-. Duplicar esas dos cosas habría creado una segunda fuente de
  verdad, así que se pasan como `Callable` -mismo espíritu que `FichaJugadorAcciones`, aplicado esta
  vez a pintar-y-navegar en vez de a mutar-. De paso, `COL_ACENTO` resultó ser `var` (cambia cada
  refresco al color del club), no `const` como los otros colores: se pasa como parámetro en vez de
  duplicarse mal. Verificado pulsando la cabecera NOMBRE (confirma que `_orden_plantel` cambia de
  verdad) y el nombre de un jugador (confirma que la navegación por `Callable` sigue abriendo su
  ficha). `principal.gd`: 14.707 → 14.640 líneas. **Con las cinco tandas de hoy: 15.589 → 14.640.**
  Ver detalle en `LEEME.md`.
- **LECCIÓN QUE SE REPITIÓ CUATRO VECES ESTA SESIÓN (mercado, ficha, finanzas, y de nuevo finanzas):
  un plan externo que no midió el código real siempre subestima el tamaño y el acoplamiento.** Antes
  de prometer una extracción, grep primero: cuántas funciones, cuántos botones, cuántos puntos de
  llamada de cada helper compartido. **Antes de cada extracción**: revisar si sus helpers
  (`_texto`/`_celda`/`_escudo`/`_dato`) dependen de estado de Principal más allá de colores -ya se
  encontró que `_texto()` aplica paleta + modo daltónico + escala de texto, que `_fila_jugador()`
  navega por su cuenta, y que `_color_de_paleta()` no es lo mismo que `_color_accesible()`-, para no
  repetir el hueco de coherencia visual del mercado.
- **CERRADA LA LISTA.** No queda ninguna pantalla grande de `principal.gd` sin medir ni sin decidir
  su patrón. Lo próximo, si el usuario lo pide, es repetir el mismo ejercicio sobre otros archivos
  grandes del proyecto (`stadium_builder.gd` 2.562 líneas, `mundo.gd` 2.555, `city_builder.gd` 2.543,
  `roles.gd` 1.959...), no ya sobre `principal.gd`.
- [x] **Red de seguridad estructural, cerrada**: `pruebas/banco.gd` ahora carga las tres escenas
  raíz (`inicio`/`eleccion_club`/`principal`) como primera prueba, así que un futuro archivo roto
  nunca más pasa desapercibido con "0 fallos". Ver `LEEME.md`, 25-9.

## NOTA URGENTE CERRADA (25-9-2026): `principal.gd` no compilaba, el juego no arrancaba
Código muerto del mercado viejo (`@deprecated`, nunca borrado) citaba una variable
(`_lista_mercado`) eliminada el día que se conectó `PanelMercado`. El banco no lo detectaba
porque no carga `principal.tscn`. Cerrado, verificado con arranque real + captura de la pestaña
Mercado + banco completo (0 fallos). Detalle en `LEEME.md`, primera sección. **Lección para la
próxima**: cuando se reemplaza una pantalla por un componente nuevo, borrar el código viejo EN EL
MISMO commit, no dejarlo "@deprecated hasta la siguiente tanda de limpieza" — ese código muerto es
justo lo que no cubre el banco headless.


Creado 14-9-2026, a pedido explícito del usuario: *"genera una ruta de desarrollo... para que puedas
trabajar de forma autónoma sin mi intervención porque tendrás todo bien establecido"*.

**Cómo usar este archivo (instrucciones para mí mismo, sesión futura):**
- Es el **plan hacia adelante**, ordenado por fases. `LEEME.md` sigue siendo el **historial** de lo ya
  hecho — este archivo no lo duplica, lo continúa.
- Trabajar las fases **en orden**, de arriba hacia abajo, salvo que el usuario pida otra cosa. Dentro
  de una fase, el orden de los puntos también es el de prioridad.
- Antes de empezar cualquier punto: **verificar contra el código actual, no fiarse de esta lista** —
  el patrón que más se ha repetido en este proyecto es "algo que sonaba pendiente ya estaba hecho".
  Grep primero, tocar código después.
- Al cerrar un punto: banco de pruebas (`herramientas\run_godot.ps1`) + una prueba nueva permanente en
  `pruebas\` si el hallazgo lo amerita, actualizar `LEEME.md` con la sección de la tanda, tachar aquí
  con `[x]`, y respaldo (`herramientas\respaldar.ps1`) al cerrar un lote.
- Criterio de "terminado" (no negociable, ver `dinastia-estandar-de-terminado` en memoria): se llega
  desde el menú Y se nota jugando. No basta con que la función exista.
- Si una fase entera se completa, dejar la marca de fecha y pasar a la siguiente sin preguntar —el
  usuario dio permiso permanente para encadenar tareas.
- **Reforzado el mismo 14-9-2026**: *"puedes trabajar completamente solo sin solicitarme absolutamente
  nada... trabajar sin molestar"*. Con este archivo en la mano, el listón para detenerse a preguntar es
  altísimo: prácticamente solo una operación irreversible que ni siquiera este mismo archivo anticipó
  (y el borrado permanente de archivos ni siquiera es algo que se pueda ejecutar directamente — ver
  Fase 0, se resuelve con un script de un clic, no preguntando).

---

## FASE 0 — Decisiones de una sola vez (antes de seguir)

### 0.1 El HTML original: ARCHIVADO — CERRADO (14-9-2026)
**Decisión (14-9-2026):** la migración está confirmada al 100% desde el 11-9 (73/73 pantallas) y ya
hubo dos auditorías totales (12-9, 14-9) sin nada grande perdido. El criterio que el propio usuario
fijó el 7-9 ("1. migrar, 2. auditar, 3. recién entonces borrar el HTML") está cumplido.

**Pero no se recomienda borrarlo, se recomienda ARCHIVARLO**, por dos razones concretas:
- **No libera espacio real**: el HTML + `js/` + `css/` pesan ~1,4 MB. Borrarlo no resuelve ningún
  problema de disco (el problema real de disco son los respaldos, ya resuelto con la regla de "un solo
  respaldo").
- **Se ha usado como referencia de verificación HOY MISMO**: el bug de "votar en la Federación estaba
  roto" se confirmó comparando contra `js/juego.js` línea por línea. Sin el original, esa clase de
  verificación se vuelve mucho más difícil -no hay forma de saber si un comportamiento raro del puerto
  es un bug de la migración o una fidelidad al original sin releer el JS-.

**Acción concreta**: mover `dinastia-futbol-manager base.html`, `js/`, `css/` a una carpeta
`archivo-html-original/` en la raíz del proyecto, con una nota (`LEEME-ARCHIVO.txt`) explicando que ya
no es el juego activo y por qué se conserva. Esto dijo el usuario que quiere -"deberíamos eliminar el
html no"-, y archivar cumple la intención (sacarlo de en medio) sin perder la red de seguridad.

**HALLAZGO QUE FRENA EL MOVIMIENTO FÍSICO (14-9-2026), hay que resolver esto primero**:
`JUGAR DINASTIA.exe` (`herramientas\Lanzador.cs`) y `JUGAR DINASTIA (nube).bat` -los dos accesos de un
clic en la raíz del proyecto- **todavía abren el HTML viejo**, no Godot. El segundo además sincroniza
con Google Drive antes de abrirlo (`rclone copy "dinastia:DINASTIA" .`). Si el usuario usa cualquiera
de los dos para "jugar", hoy mismo sigue abriendo la versión vieja sin que nada se lo avise. Antes de
archivar el HTML hay que:
1. Confirmar con el usuario cómo juega él de verdad hoy (¿`entregas\windows\DINASTIA.exe`? ¿otro
   camino?).
2. Reescribir `JUGAR DINASTIA (nube).bat` (y decidir si vale la pena arreglar el `.exe` o retirarlo)
   para que abra el build de Godot en vez del HTML -manteniendo la sincronización con Drive, que sigue
   siendo útil-.
3. Solo entonces mover el HTML/js/css sin dejar un lanzador roto apuntando a un archivo movido.
4. Actualizar además `herramientas\run_harness.ps1:20` (ruta hardcodeada al HTML) si se decide moverlo,
   para que `exportar_datos.js` -la herramienta que regenera `tablas.json` si el HTML cambiara- lo
   siga encontrando.

**[x] CERRADO (14-9-2026)**: el usuario confirmó que jugaba por PowerShell (no por los lanzadores
viejos, así que no venía jugando el HTML por error) y pidió arreglar los dos lanzadores. Hecho:
- `herramientas\Lanzador.cs` reescrito para abrir el PROYECTO de Godot directo
  (`Godot_v4.7.2-stable_win64.exe --path dinastia-godot`, sin ventana de consola) en vez del HTML, y
  recompilado a `JUGAR DINASTIA.exe` -verificado arrancando y matando el proceso, Godot sí abre-.
- `JUGAR DINASTIA (nube).bat` reescrito igual, conservando la sincronización con Drive (rclone) antes
  de abrir.
- `dinastia-futbol-manager base.html`, `js\`, `css\` movidos a `archivo-html-original\`, con una nota
  (`LEEME-ARCHIVO.txt`) explicando por qué se conservan y el detalle de que sus fotos de equipaciones
  no se ven si se abre directo desde ahí (rutas relativas a `recursos\`, que sigue en la raíz).
- `herramientas\run_harness.ps1:20` actualizado a la nueva ruta -sigue funcionando: escribe su copia
  de prueba en la raíz del proyecto, así que las rutas relativas del banco viejo no se rompen-.
- Banco de pruebas de Godot: 0 fallos, verificado después de mover todo.

### 0.2 Recompilar el build de entrega
Lo que hay en `entregas\` es del 8/10-9-2026 -antes de TODOS los arreglos de esta sesión (visor 3D
invisible, señales duplicadas, votar roto, Champions muda, etc.)-. Antes de dar cualquier cosa por
"lista para mostrar" hay que correr `herramientas\empaquetar.ps1` de nuevo. Barato, hacerlo apenas se
cierre la Fase 1.

---

## FASE 1 — Terminar de cerrar "conectores mudos" — CERRADA (14-9-2026)

Contexto: dos rondas de auditoría de `.connect(` ya habían cerrado 13 señales de Federación/Hinchada
(13/14-9) y 4 más en el resto de `nucleo/` (Champions/Libertadores, entrenamiento, vestuario, estadio
propio), las dos veces encontrando bugs reales grandes.

- [x] **Los ~250 `.connect(` de botones/pestañas en `ui/principal.gd`**: un agente los revisó los 315
  uno por uno (no solo muestreo) con un script que descarta automáticamente el patrón seguro ("nodo de
  Godot nuevo, creado en la misma función que lo conecta"). 251/315 son ese caso seguro; las 64
  restantes (`mundo.*` dentro de `_conectar_noticias()`/`_conectar_sorteos()`/`_conectar_mi_continental()`,
  más `liga`, `resized`, los popups) ya tenían su candado correcto -ninguna nueva encontrada-. Único
  ajuste: la nota de qué objetos "no se recrean" estaba mal -`prensa`, `selecciones` y `cantera` SÍ se
  recrean en `tomar_el_mando()` (`nucleo/mundo.gd:1633,1656,1657`), la lista correcta de los que NO se
  recrean es `federacion`, `estadio`, `cesiones`, `roles`, `mercado`, `eras`, `copa` y el propio `Mundo`.
- [x] Instancias que se resortean sin reconexión: el único caso real era el de Champions/Libertadores,
  ya cerrado en el lote anterior (`_conectar_sorteos()` ahora se llama también en `_nueva_temporada()`).
- [x] Confirmado (14-9): el "lobby institucional con árbitros" NO existe en el código -no es una
  falsa alarma, es un hueco real-. Pasa a la Fase 3 como contenido nuevo, no como conector.

**Veredicto**: no queda nada real por cerrar en esta veta. Fase cerrada del todo.

---

## FASE 2 — La piel 3D (la brecha más grande para "sentirse terminado")

Diagnóstico del 14-9-2026, jugando de verdad y no solo leyendo código: la interfaz 2D de gestión está
a nivel comercial (tablas, fichas, mercado, ficha de jugador). El 3D -partido, estadio, ciudad- todavía
se ve como boceto funcional. Esta es la fase que más notaría el usuario si se muestra el juego a
alguien de afuera.

- [x] **La rueda de prensa, primera pasada: CERRADO (14-9-2026).** El locutor sin rasgos se
  reemplazó por un `QuadMesh` con el retrato real de `CaraDT.textura()`, y luego se corrigió que
  siempre mostraba al jugador aunque el rol activo tuviera un DT empleado dando la rueda, y que el
  fondo mostraba marcas genéricas en vez de los escudos de tu liga. Detalle en `LEEME.md`, secciones
  "EL DT DE LA RUEDA DE PRENSA..." y "LA RUEDA DE PRENSA, SEGUNDA PASADA...". Verificado con captura
  real (incluido el caso "DT empleado") + prueba permanente + banco (0 fallos).
- [x] **La rueda de prensa, al nivel de producción del SORTEO: CERRADO (14-9-2026).** Sala completa
  (paredes + techo con truss), periodistas visibles (siluetas con luz de relleno propia, antes eran
  invisibles), y tres planos de cámara que cortan solos cada pocos segundos (de trabajo, general con
  FOV abierto a 58°, y lateral) -el FOV fijo no bastaba, tuvo que variar por plano también-. Balanceo
  mínimo añadido al retrato del DT para que no se lea como una foto fija en los planos alejados.
- [x] **El DT apoya las manos en el podio: CERRADO (14-9-2026).** Pedido explícito tras el gesto del
  sorteo ("invierte en eso"). Un antebrazo por lado, plano sobre la mesa -no en diagonal desde un
  hombro alto, que en el plano de cámara más cerrado quedaba pegado a la barbilla-, con vaivén mínimo
  independiente en cada mano. Detalle completo, con las dos vueltas que costó acertar la altura real
  del podio, en `LEEME.md`, sección "EL DT APOYA LAS MANOS EN EL PODIO". Verificado con captura real en
  los tres planos + banco (0 fallos).
- [x] **El presentador del sorteo: CERRADO (25-9-2026)** con el escaneo realista del Drive (`PersonaRealista`, ver LEEME, tercera ronda); el gato del menú no apareció en el Drive y sigue pendiente. Historia: **EN PAUSA a pedido del usuario (14-9-2026).** Se llegó a reemplazar
  la silueta de cajas por el humanoide real (`Futbolista`/`AnimMixamo`/`Vestidor`) y a corregir un
  ángulo de cámara que hacía ver el brazo "estirado" -detalle en `LEEME.md`, sección "EL PRESENTADOR
  DEL SORTEO"-, pero el usuario avisó que dejó un modelo 3D propio ("un tipo con tarjeta") en su Drive
  y prefiere rehacer el presentador con ese modelo en vez de seguir vistiendo al futbolista de traje.
  Pendiente: recibir ese modelo (arrastrado al chat, o con el conector de Drive cargado desde el
  arranque de una sesión nueva) y remontar `_montar_presentador_modelo()` sobre él. El mismo modelo
  serviría también para el público, y hay un modelo de un gato aparte para que interactúe con el menú
  inicial -anotado, sin empezar.
- [x] **El estadio, cámara "Principal (TV)": CERRADO (14-9-2026).** No era falta de textura -era la
  cámara literalmente encima del techo de la tribuna en estadios de 1 nivel, viendo su cara inferior a
  bocajarro-. Diagnosticado con un raycast real (no a ojo) y arreglado con un `minf()` en
  `camera_rig.gd`. Detalle completo en `LEEME.md`, sección "EL BLOQUE GRIS DEL ESTADIO...". Verificado
  con banco + prueba de regresión nueva + captura visual real: el campo se ve entero, sin el bloque.
  **"Detrás del arco" revisada con el mismo método y TAMBIÉN corregida**: el margen de 0,375 m sí era
  insuficiente -el mismo raycast confirmó que rozaba el techo en el 5-15% superior del encuadre-, y
  resultó ser la causa real del "bloque negro" que `dinastia-estadio-hueco-y-tunel-negro` documentó el
  13-9 sin diagnosticar (no era el cielo nocturno). Mismo arreglo aplicado. Las dos cámaras quedan
  cubiertas por la misma prueba de regresión.
- [x] **El letrero "Polideportivo": FALSA ALARMA, verificada y descartada (14-9-2026).** La captura
  que hizo sospechar (`sdfgi_on.png`) viene de `captura_sdfgi.gd`, una prueba que fuerza la cámara a
  65 m de altura para otra cosa (probar SDFGI) -muy por debajo de los 110 m con los que la cámara
  arranca de verdad (`ciudad_vista.gd:34`)-. Con la cámara REAL se generó
  `pruebas/cartel_ciudad_camara_real.png` (nuevo): los 6 carteles del mapa ("Centro comercial",
  "Piscina olímpica", "Zona industrial", etc.) se ven pequeños, legibles y bien proporcionados a sus
  edificios. Nada que arreglar aquí -otra vez el patrón de "verificar antes de anunciar un bug".
- [x] **Barrido de capturas 3D existentes: hecho (14-9-2026), sin hallazgos nuevos.** Revisadas
  `partido3d_*.png` (22 jugadores en cancha, animación e uniformes correctos), `diagnostico_tv.png`,
  `pantalla_estadio_3d_abierto.png` (nocturno, graderío y luces bien) y `pantalla_oficina_dt_aislada.png`
  (primer plano deliberado de un modelo, no la vista normal del jugador) -nada anómalo-. No se revisó
  cada una de las 130+ capturas de `pruebas/`, pero la muestra de vistas 3D centrales del juego
  (partido, estadio, ciudad) no mostró ningún caso nuevo del mismo patrón (bloque gris/textura rota).
  Si en el futuro algo se ve raro en una captura nueva: aplicar el mismo método que resolvió el bloque
  gris del estadio -no asumir la causa a ojo, escribir un raycast o aislar la geometría antes de tocar
  código-.
- [x] **Nivel "FIFA" del partido 3D: CERRADO (15/16-9-2026), sin necesitar API.** La parte de arte
  generado (`dinastia-herramientas-3d-ia`) sigue bloqueada por presupuesto de API, pero la parte de
  código/geometría no lo estaba y se hizo entera: balón con física real de arco y rodadura
  (`visor/balon_3d.gd`), 9 cámaras incluyendo POV y Tercera Persona (`visor/camera_rig.gd`), control
  manual de jugador estilo FC 26 (`visor/control_partido.gd`), radar táctico 2D (`ui/radar_partido.gd`)
  y arcos/redes de detalle real (`visor/stadium_builder.gd`). Detalle completo y verificación en
  `LEEME.md`, sección "EL PARTIDO 3D AL NIVEL FIFA...".

---

## FASE 3 — Sistemas grandes confirmados como pendientes, ordenados por impacto

Fuente: `LEEME.md` (cola del 12-9) + `dinastia-archivos-profundos-vs-codigo` (corregida hoy: de 5
"huecos baratos" que parecían pendientes, 4 ya estaban hechos -pizarra táctica, guerra de agentes, lío
nocturno, adaptación cultural-; el que de verdad falta es el que sigue en la lista de abajo).

1. **El estadio por MÓDULOS** -desarmar/rearmar el recinto con piezas 3D independientes en vez de
   reformar el conjunto completo o elegir entre 8 estilos enteros-. Decisión de diseño ya tomada
   (16-9-2026): las tres lógicas a la vez -bandeja, componentes, tramo-, en ese orden. Plan
   completo en `C:\Users\Alumno\.claude\plans\smooth-soaring-micali.md`.
   - [x] **Bandeja (16-9-2026): CERRADA.** Cada una de las 4 tribunas con su propio patrón de
     butacas y techo. Detalle y verificación en `LEEME.md`, sección "EL ESTADIO POR MÓDULOS, FASE 1".
   - [x] **Componentes (16-9-2026): CERRADA.** Túnel, banquillos, banderines de córner, tejido de
     red y dónde va el escudo -catálogos que ya existían y ya se cobraban, conectados al visor 3D
     por primera vez. Detalle y verificación en `LEEME.md`, sección "...FASE 2".
   - [x] **Tramo (estilos mixtos dentro de una misma tribuna): CERRADA (22-9-2026).** El spike del
     18-9 confirmó que el corte se sostiene visualmente con `uv1_scale.y=1`; esta tanda diseñó y
     conectó la fase completa -13 claves nuevas en `EST_DEF`, `EstadioPropio._tramos_personalizados()`,
     wiring real en `StadiumBuilder.build()`, UI en Club → Estadio-. De paso se evitó reintroducir a
     propósito el bug de "estática de TV" del 21-9 (el spike nunca había pasado por ese arreglo) y
     se encontró/corrigió un bug real de verificación (`Comercial.color_balon(mundo.comercial.balon,
     ...)` con `comercial` Nil, presente también en `captura_bandejas.gd`/`captura_componentes.gd`
     desde el 16-9 -esas capturas tampoco mostraban nunca el estadio real-). Detalle completo y
     verificación (datos + visual) en `LEEME.md`, sección "EL ESTADIO POR MÓDULOS, FASE 3 DE 3:
     TRAMO — CERRADA DE PUNTA A PUNTA". **Las tres lógicas del punto 1 quedan cerradas.**
2. [x] **Extender el espionaje de entrenamientos rivales a información táctica: CERRADO (22-9-2026).**
   `_pintar_juegos_mentales()` ahora suma mentalidad/presión/línea del rival, leídas de `rival.tactica`
   -mismo candado que el once probable-. Decisión deliberada: NO se le dio personalidad táctica a la
   IA (eso tocaría el balance de cada partido de la liga, no es una decisión de pantalla) -por eso casi
   todo rival lee "Equilibrada/Media/Media" siempre, documentado y verificado en pantalla, no
   escondido-. De paso, un bug real grande: un `:=` indexando un Array sin tipar rompía la carga
   ENTERA de `ui/principal.gd` y el banco headless no lo veía (no carga esa escena). Detalle completo
   en `LEEME.md`, sección "ESPIONAJE TÁCTICO DEL RIVAL, EXTENDIDO".
3. [x] **Lobby institucional explícito con árbitros: CERRADO (26-9-2026).** Un evento más en
   `Prensa._pool()`/`resolver()` (`"lobby_arbitral"`), sin interfaz nueva -mismo camino genérico de
   `Principal._pintar_decision()`-. Aparece solo si `Federacion.enojo_arbitral > 0` -es la mitad
   PROACTIVA que faltaba, complemento de `"reclamo"` (reactiva, ya existía) y del contador que ya
   encarece las apelaciones en `Federacion.apelar()`-. Asistir cuesta plata y baja el enojo, con 30%
   de filtrarse (funa + confianza de directiva); declinar no cambia nada. Verificado por motor
   (aparece/no aparece según el contador, cobra y baja el enojo de verdad) y con captura real del
   aviso en pantalla. Ver `LEEME.md`.

   ### 2-bis. LA PANTALLA DEL ESTADIO Y LAS VALLAS LED: CERRADO (23-9-2026)
   Sesión de una sola misión pedida por el usuario. La pantalla gigante pasa de un `Label` "0 - 0"
   (que además se cortaba) a **seis paneles en rotación** -marcador estilo transmisión, estadísticas,
   goleadores del partido, tabla de posiciones, máximos goleadores y bienvenida- más un corte a
   "¡GOOOL!" a pantalla completa. Y las 54 vallas de color liso del perímetro pasan a ser **LED con
   marca de verdad** (el club, DINASTÍA y cuatro de las 38 marcas de `MARCAS`, por hash del club)
   que cambian solas en ola. Detalle completo, con los tres bugs reales y los tres bugs de
   verificación que salieron por el camino, en `LEEME.md`, sección del 23-9.
   **Cierra el punto pendiente que arrastraba `dinastia-ideas-pendientes`** ("pantalla del estadio
   con tabla/goleadores dinámicos").

   ### 2-ter. ARQUITECTURA DEL ESTADIO Y PÚBLICO: PRIMERA PASADA (23-9-2026)
   Una auditoría (con agente) de `visor/stadium_builder.gd` buscando el patrón "medida en metros
   fija que solo cuadra con UNA forma y UN número de niveles" encontró **12 casos**. Se cerraron los
   6 de más impacto visual: la grada veía solo el 17% de su textura (atlas de UV del `BoxMesh`,
   medido con `pruebas/diagnostico_uv_caja.gd`), el público estaba reclinado 58,6°, el público de la
   textura se sorteaba en posición libre (ahora va en filas con escalones y escaleras), 4 de las 10
   lámparas de la corona flotaban sobre el campo, el cubo colgante nunca quedaba bajo cubierta y las
   esquinas del cuenco sobresalían 3,5 m hacia la cancha. Verificado con `pruebas/captura_formas_
   estadio.gd` (nuevo), que fotografía **las seis formas y los tres niveles** -hasta hoy todas las
   capturas del proyecto se sacaban con el mismo estadio, y por eso nada de esto se veía nunca-.

   - [x] **Los 12 hallazgos de la auditoría: CERRADOS (23-9-2026).** Los 6 últimos en la tercera
     tanda del día: el túnel anclado a 64 m fijos y sus tipos "arco"/"foso" (el arco plantado dentro
     del área grande, "foso" entero bajo el césped opaco o sea invisible), los dos banquillos
     superpuestos (el viejo recibía `dx` y no lo usaba), las vallas LED cruzando el dugout, el
     escudo de tribuna con tres posiciones fijas, las dos cámaras del `CameraRig` -incluida una
     cuyo `clampf(alto*0.55, 12.0, 34.0)` **nunca superaba su propio mínimo**, o sea código muerto-
     y las cuatro esquinas que desaparecían en "herradura".
   - [x] **Telones de hinchada y vomitorios: HECHOS (23-9-2026).** `PlaneMesh` hijos del `deck` en
     coordenadas locales, para que la inclinación la resuelva el nodo.
   - [x] **La hinchada, viva: HECHO (23-9-2026).** `visor/hinchada.gdshader`: se balancean con fase
     propia, saltan de a poco, la cabeza va en tono de piel en vez del color de la camiseta, y las
     estaturas varían ±10%. Y el público 3D llega a la ÚLTIMA fila, no a media grada (pedido
     directo del usuario) -se logró separando el presupuesto de vértices de las butacas del de los
     hinchas: una butaca cuesta 988 vértices y un hincha 70-.

   ### 2-quinquies. BANDEJAS DE VERDAD, ESQUINAS EN DIAGONAL Y CONECTORES (23-9-2026, sesión final)
   Pedido: *"el estadio debe ser modular... más bandejas y variantes para cuando uno agrande el
   estadio (máximo 150.000)"*. Reescrito `StadiumBuilder.build()`: cada tribuna ahora es N bandejas
   reales (10 m de fondo, 33° de rake, 3 m de peto entre una y la siguiente), no una rampa única que
   a 3 niveles llegaba a 58,6°. `NIVELES_MAX` sube de 3 a 5 (alturas 8/17,5/27/36,5/**46 m**), y
   `EstadioPropio.niveles_maximos()` sigue el nivel de la obra "Tribunas" hasta el final en vez de
   cortarse en 3. Las esquinas dejaron de ser un cubo (atlas de UV al 17%, ver
   `reference-godot-boxmesh-uv` en memoria) y pasan a ser grada real en diagonal, con hinchada.
   Se cerraron además los 12 hallazgos de una segunda auditoría (cancha pintada 64×100 en vez de
   68×105 -arreglado-, techos de esquina con z-fighting, burbuja de banquillo opaca, líneas de cal
   sin sombra, técnica del catálogo que se cobraba y no dibujaba nada: **pista de atletismo**
   (480.000, el capítulo más caro) y **banderas de hinchada** (tifo/bufandas/banderines), ahora
   ambas con geometría real. `visor/stadium_builder.gd` no se re-verificó con el banco completo tras
   el último arreglo de tipos (`Array[Color]`) por quedarse sin cupo de la sesión -**correr
   `herramientas\run_godot.ps1` antes de dar esto por cerrado del todo**, aunque
   `captura_formas_estadio.gd` (las 6 formas, hasta 5 bandejas) pasó en 0 fallos.

   ### 2-sexies. PEDIDO EXPLÍCITO DEL USUARIO, SIN EMPEZAR: colores por sección
   *"El estadio sea modular significa poder cambiar colores por sección, arco, líneas, bandejas una
   por una, cesped, pantalla, faros, luces nocturnas, LED, bancas, gradas, asientos."* Hoy
   `asiento1`/`asiento2`/`asiento3` son globales (con la excepción parcial de "bandejas"/"tramos" por
   tribuna, ya conectada). Falta: color independiente por CADA bandeja de CADA tribuna (no solo el
   patrón), color de poste/red por separado del de línea, y paleta propia para focos/vallas/LED. Es
   trabajo de `nucleo/estadio_propio.gd` (nuevas claves en `EST_DEF` + UI de Club→Estadio) antes que
   de `visor/`.

   ### 2-septies. PEDIDO EXPLÍCITO DEL USUARIO, SIN EMPEZAR: túnel navegable
   *"La zona del túnel deben ser más reales, a futuro el estadio será navegable con el
   protagonista."* Hoy `_tunel()` es decorado (una mole con boca, sin interior). Si el jugador va a
   caminar por ahí algún día, el túnel necesita profundidad real (un pasillo con `CollisionShape3D`,
   no una caja hueca) — anotado para cuando se diseñe el modo "caminar por el estadio", no antes.

   ### 2-quater. LO SIGUIENTE PARA EL ESTADIO, sin empezar
   - [ ] **El graderío por bandejas de verdad.** El fondo de la tribuna es 11 m FIJOS en las tres
     alturas, así que con 3 niveles la rampa queda a **58,6°** -ninguna grada real pasa de ~35-.
     Hoy se disimula contrarrotando butacas y hinchas para que queden de pie (lo cual es correcto:
     van sobre escalones), pero la rampa en sí sigue siendo demasiado empinada. El arreglo de
     verdad es partir la tribuna en 2-3 bandejas con su propio fondo y un pasillo entre ellas, que
     además es lo que se ve en `ea_fc25_referencia.mp4`. Es trabajo de geometría real, no un ajuste.
   - [ ] **Modelos 3D para camarógrafos y guardias** (candidato: `PersonaRealista`, que ya viste de traje; falta un uniforme) (el usuario recordó que hay personajes 3D
     disponibles): hoy son cajas. Son ~6 figuras, no miles, así que aquí sí cabe un modelo real
     -a diferencia del público, que tiene que seguir siendo `MultiMesh` sí o sí-.
   - [ ] **Nombre del jugador flotando sobre cada futbolista** con su barra de estado, como en
     `ejemplo-partido.mp4` (Soccer Manager). Es lo único grande de ese video que no se ha portado.
4. [x] **Animaciones de lenguaje corporal en la banda / "efecto banquillo" visual: CERRADO
   (22-9-2026).** Hasta ahora la banda estaba vacía -ni un suplente en ningún partido-. Ahora hasta 7
   suplentes por equipo (`visor/player_spawner.gd::spawn_banca()`) de pie junto a su banquillo -no
   sentados adentro, decisión de alcance explicada en `LEEME.md`-, y el banquillo del equipo que
   anota festeja con la animación real de gol (`ui/estadio.gd::_banca_celebra()`) y vuelve solo a la
   calma a los 3s. Detalle completo y verificación (datos + 3 capturas reales del ciclo antes/
   festejo/vuelta) en `LEEME.md`, sección "EL BANQUILLO YA NO ESTÁ VACÍO".
5. [x] **Modo Director de Cantera completo** (edades 10-16): CERRADO en la ronda del análisis
   externo (25-9-2026), ver `LEEME.md`.
6. [ ] **Juegos mentales en el túnel** antes de salir a la cancha: pasa al bloque B4 del plan
   maestro (arriba).

---

## FASE 4 — Lo que queda del listado de 750/300 ideas (más chico de lo que suena)

Fuente: `dinastia-pendientes` (última auditoría de ese listado, ~100 ideas de las 750 originales,
repartidas en 6 bloques). **Antes de escribir nada de esta fase: volver a cruzar contra el código
actual con un agente** -el patrón de "ya estaba hecho" se ha repetido tantas veces en este proyecto
que dar esta lista por vigente sin re-verificar sería el mismo error de siempre.

- [ ] **37/38 — Mercado avanzado y zonas grises**: guerra de ofertas, derechos de formación,
  superagente, fichaje impuesto por el dueño, apuestas, transparencia.
- [ ] **39/40 — Insolvencia y política interna**: renegociar deuda, resta de puntos, administrador
  externo, bonos de hinchas, tope salarial, refundación, cláusula de salida del DT. (Ojo: parte de
  esto puede solaparse con `Banco`, construido el 13/14-9 -revisar antes de reescribir.)
- [ ] **44/45 — Reglamento y federación fino**: historial por árbitro, cambios de reglas entre
  temporadas, criterios de desempate, playoffs de descenso, repechaje, corrupción federativa.
- [ ] **46 — Selecciones**: lista preliminar, conflicto club-selección (lo demás de este bloque ya
  está hecho según `dinastia-pendientes` v3.1).
- [ ] **47 — Competencias**: editor de campeonatos, sede de final fija. (Cabezas de serie y
  Apertura/Clausura ya existen.)
- [ ] **50 — Meta**: cromos, museo global, mundo heredado. (Nivel de perfil del gestor ya existe.)

---

## FASE 5 — Pedido explícitamente en espera (NO TOCAR sin permiso directo)

Estas dos las pidió el usuario **dejar anotadas y no implementar**, no están a medio hacer:

- [x] **Divisas seleccionables: CERRADO (25-9-2026)**, en la ronda del análisis externo.
- [ ] **La cara real 2D moldeada sobre el modelo 3D del jugador en el campo** (hoy son dos sistemas
  separados: retrato 2D y textura de cabeza del atlas 3D). Ya hay un plan técnico completo escrito en
  `LEEME.md` ("PEDIDO POR EL USUARIO, SIN HACER TODAVÍA", punto 3) para cuando se autorice.

---

## FASE 6 — Limpieza técnica de bajo valor (cuando sobre tiempo, nunca prioritario)

- [x] **7 funciones huérfanas en `entrenamiento.gd`: BORRADAS (26-9-2026)** -confirmado con grep
  (llamada directa y por `.call()` dinámico) en todo el proyecto antes de tocar nada: `subidas_de`,
  `dar_puntos`, `arbol_por_rama`, `rama_habilidad`, `minimo_habilidad`, `requisito_habilidad`,
  `dt_puede`. Ver `LEEME.md`.
- [x] **`visor/match_playback.gd::is_final()`: BORRADA (26-9-2026)**, mismo método de verificación.
- [x] **`principal.gd` ya no costaba de verdad: RESUELTO (25/26-9-2026)** con las cinco tandas de
  modularización de hoy (15.589 → 14.640 líneas). Ver la sección de arriba.

---

## Nota sobre "cosas nuevas que ya entré al juego" (mencionado por el usuario, 14-9-2026)

El usuario avisó que ha ido agregando contenido nuevo (ej. la ciudad mejorada) que puede no estar
reflejado del todo arriba. Antes de arrancar una fase grande (3 en adelante), vale la pena un barrido
rápido de `git log`-like -aquí no hay git, así que `Get-ChildItem -Recurse | Sort LastWriteTime` sobre
`nucleo/`+`ui/`+`visor/`- para ver qué se tocó recientemente y no esté ya anotado en `LEEME.md`.

---

## FASE 7 — Continuidad si el proyecto pasa a otra IA (ej. Google Antigravity)

Pedido explícito del usuario (14-9-2026): tener esto listo por si se le acaba la cuota de Claude y
necesita seguir con otro asistente mientras tanto. **Si estás leyendo esto porque eres esa otra IA:
bienvenido. Esta sección es para ti, autocontenida a propósito.**

### Lo primero que hay que entender: dónde vive el conocimiento de este proyecto

Todo lo que Claude sabe de este proyecto vive en DOS sitios, y solo uno de ellos viaja contigo:
1. **Dentro del proyecto** (lo que estás leyendo): `dinastia-godot/LEEME.md` (el historial completo,
   ~4000 líneas, ordenado con lo más reciente arriba) y este `ROADMAP.md` (el plan hacia adelante).
   **Esto SÍ lo tienes.**
2. **La memoria propia de Claude Code**, en una carpeta fuera del proyecto (`~/.claude/...`), con
   decenas de notas más pequeñas sobre preferencias del usuario, hallazgos puntuales y contexto de
   conversaciones pasadas. **Esto NO lo tienes, y no hay forma de que lo tengas.** Si algo de lo que
   sigue suena incompleto, es por eso — lee `LEEME.md` entero antes de asumir que algo no existe.

### Las reglas de oro (todas costaron tiempo real aprenderlas, no las repitas)

1. **"Portar, no reescribir."** El juego migró de un HTML/JavaScript monolítico (archivado en
   `archivo-html-original/`, ya NO es el juego activo) a este proyecto de Godot/GDScript. Las fórmulas
   de balance (economía, fichajes, partidos) se portaron TAL CUAL desde ese HTML — no se rediseñan
   porque "parecen raras", costó semanas de ajuste fino en su momento. Si dudas si un número o una
   condición es fiel al original, compáralo contra `archivo-html-original/js/juego.js` (o `vistas.js`
   para pantallas) antes de tocarlo.
2. **Verificar SIEMPRE con el banco de pruebas + una captura real, nunca solo "el código compila".**
   El patrón de bug más repetido en este proyecto es una función escrita y probada en aislado que
   nadie conectó a la interfaz — "quedó escrito" no es "quedó hecho". Comandos exactos más abajo.
3. **Antes de dar algo por "pendiente" o "faltante": grep primero.** Este proyecto tiene un historial
   largo de sistemas que "sonaban sin construir" y ya estaban hechos con otro nombre (pasó con la
   pizarra táctica, la guerra de agentes, el lío nocturno — los tres el mismo día, 14-9-2026). Nunca
   anunciar un hallazgo sin haber leído el código real primero.
4. **No silenciar stderr al probar código nuevo.** Si un script revienta a mitad de camino, Godot
   igual "termina" e imprime lo que haya antes del fallo — parece que todo salió bien y no fue así.
5. **Un solo respaldo activo**, no una pila de copias — ver Fase 0 / abajo, el disco de esta máquina
   es pequeño (SSD de 119 GB).
6. **El usuario es chileno.** Tutéalo, nunca voseo argentino ("vos", "tenés"). Español en todo.
7. **No asume que puedes ejecutar comandos de borrado permanente de archivos tú mismo** — si tu
   entorno sí puede, genial, pero confirma con el usuario antes igual: es la única clase de acción de
   esta lista que de verdad no tiene vuelta atrás sin un respaldo.

### Comandos que vas a necesitar (PowerShell, Windows)

```powershell
# Banco de pruebas headless (851+ comprobaciones, tarda ~2-3 min). SIEMPRE antes de dar algo por cerrado.
herramientas\run_godot.ps1 -Salida "herramientas\salida\mi_prueba.log"
# Revisa el .log Y el .err.txt del mismo nombre -el segundo es el stderr, nunca lo ignores-.

# Jugar de verdad (abre una ventana)
herramientas\run_godot.ps1 -Jugar

# Capturar una pantalla del juego jugando (deja pruebas/pantalla.png)
herramientas\run_godot.ps1 -Captura

# Si algo se queja de "Identifier X not declared" en cuarenta líneas seguidas:
herramientas\run_godot.ps1 -Reimportar

# Respaldo fechado (reemplaza al anterior, no se apila)
herramientas\respaldar.ps1 -Nombre "lo-que-sea-que-hiciste"
```

Para una verificación puntual de un hallazgo nuevo, el patrón que se usa en todo el proyecto es
escribir un script headless corto en `pruebas/nombre.gd` + su `.tscn` (ver cualquiera de los ya
escritos ahí como plantilla, por ejemplo `pruebas/captura_conectores_14_9.gd`) que instancia
`res://escenas/principal.tscn`, espera unos frames, y comprueba con `print("OK ...")`/`print("MAL
...")`. Se corre con `herramientas\run_godot.ps1 -Escena "res://pruebas/tu_script.tscn" -Salida
"herramientas\salida\tu_prueba.log"`.

### Estructura del proyecto, en una tabla

| Carpeta | Qué es |
|---|---|
| `dinastia-godot/nucleo/` | La lógica del juego (economía, partidos, plantillas...), sin interfaz |
| `dinastia-godot/ui/` | La interfaz — casi todo vive en `principal.gd` (15.000+ líneas, un archivo por diseño: cada función pinta una pantalla completa) |
| `dinastia-godot/visor/` | El 3D: estadio, ciudad, los 22 jugadores en cancha |
| `dinastia-godot/pruebas/` | El banco de pruebas (`banco.gd`) + capturas de verificación puntuales |
| `herramientas/` | Scripts de PowerShell (correr, empaquetar, respaldar) + el Godot portable |
| `archivo-html-original/` | El juego VIEJO, ya no activo, conservado como referencia de fórmulas |
| `respaldos/` | Copias fechadas completas — dejar solo la más reciente |

### Al terminar cualquier tanda de trabajo

Igual que se le pide a Claude: actualizar `LEEME.md` con una sección nueva (arriba del todo, con
fecha) describiendo qué se hizo y cómo se verificó, tachar el punto correspondiente en este
`ROADMAP.md` con `[x]`, y dejar un respaldo. Así, cuando el usuario vuelva a Claude (o a quien sea),
el trabajo queda legible sin tener que releer el chat.

---

Relacionado: `LEEME.md` (el historial completo), y en la memoria de Claude:
`dinastia-archivos-profundos-vs-codigo`, `dinastia-pendientes`, `dinastia-estandar-de-terminado`,
`dinastia-trabajo-autonomo`, `dinastia-feedback-invertir-en-lo-visual`.
