# Etapas finales del proyecto (pedidas el 8-10-2026)

Pedido del usuario, palabra por palabra: «agrega 5 etapas más al proyecto:
1 ultra pulido, 2 más realismo en las texturas y personajes, 3 optimización
mediante código, 4 realismo visual en infraestructura y personajes, 5 mejora
físicas, movimientos más naturales, que no se puedan atravesar los objetos, y
más físicas».

Se hacen en este orden, una detrás de otra, con la regla de siempre:
cada etapa termina con banco en «FIN. 0 fallos», `prueba_modos` en «FIN MODOS.
0 fallos», capturas de antes y después, y este documento al día.

Lo que es 🔒 del dueño (builds, keystore, licencias, música, FPS en su equipo)
sigue siendo suyo. Sin descargas que la red bloquee: todo se hace con lo que ya
hay en el repositorio y con código.

---

## Etapa 1 · Ultra pulido

El objetivo es que nada se vea ni se sienta «a medio hacer».

- **Recorrido completo con capturas.** Menús, ciudad, estadio, partido,
  Carrera de Jugador, minijuegos y metro. Para cada cosa rara que salga: una
  línea en la lista de este documento, y se arregla.
- **Rótulos flotantes.** Los letreros del mapa se ven dentro de los recorridos
  y hay letreros que tapan otros. Hay que unificar tamaños y distancias de
  aparición.
- **Cámaras.** Que ninguna cámara se meta en paredes, techos ni cabezas: en la
  ciudad, el estadio, el metro, las instalaciones y el partido.
- **Textos.** Que nada se corte ni se desborde en los 9 idiomas. Revisar las
  frases nuevas (portero, galería, obras) en el pipeline de traducción.
- **Avisos del motor.** Que los registros de arranque, ciudad, partido y cierre
  queden sin errores ni avisos (las fugas de nodos al salir, etc.).
- **Transiciones.** Fundidos al entrar y salir de la ciudad, del estadio y del
  partido. Sonido de puertas y pasos donde falte.

Se comprueba con las hojas de capturas por zona y con un registro limpio.

## Etapa 2 · Más realismo en texturas y personajes

- **Materiales del mundo.** Hormigón, asfalto, césped, madera, metal y cristal,
  con relieve y rugosidad coherentes. También hay que revisar los colores que
  aún salen apagados o negros en el modo de compatibilidad (móvil), como el
  hormigón y los árboles que ya se arreglaron.
- **Ropa.** Tejidos con relieve (punto de camiseta, traje, chándal), arrugas
  simples por normal map y escudo bordado.
- **Piel y caras.** Que el método aprobado de caras llegue a TODOS los cuerpos:
  la gente de la ciudad, el personal y los hinchas cercanos, no solo los
  jugadores.
- **Pelo.** Los cortes medidos, con mechones y brillo, también en los NPC.

Se comprueba con capturas lado a lado (antes/después) en luz de día, tarde y
noche, y en los dos renderizadores (escritorio y móvil).

## Etapa 3 · Optimización mediante código

- **Medir antes de tocar.** Un banco de rendimiento con tiempos de construcción
  de la ciudad, el estadio y el partido, más fotogramas por segundo y número de
  llamadas de dibujo en escenas fijas. Las cifras se guardan aquí.
- **Instanciado.** MultiMesh para todo lo repetido (mobiliario urbano,
  ventanas, butacas lejanas, gente lejana) y materiales compartidos en caché.
- **Niveles de detalle (LOD) y distancia de visibilidad.** Para edificios,
  gente, coches y rótulos. Ocultar lo que está bajo tierra o dentro de
  edificios cuando no se ve.
- **Construcción por partes.** La ciudad se levanta repartida en varios
  fotogramas, sin bloquear la pantalla.
- **Lógica.** Que la IA de peatones, el tráfico y el personal se actualice
  cada pocos fotogramas según la distancia. Sin búsquedas en todo el árbol de
  nodos en cada fotograma.
- **Memoria.** Cerrar las fugas de nodos y recursos que aparecen al salir.

Se comprueba repitiendo el banco de rendimiento: cada mejora con su cifra.

## Etapa 4 · Realismo visual en infraestructura y personajes

- **Edificios.** Fachadas con ventanas de verdad (marcos, profundidad,
  interiores falsos), cornisas, balcones, aire acondicionado, toldos, y
  suciedad y desgaste en las bases.
- **Calles.** Bordillos con altura, alcantarillas, marcas viales gastadas y
  baches. Iluminación nocturna con conos de luz.
- **Estadio.** Estructura y escaleras de acceso, vomitorios, barandillas,
  cubiertas con cerchas, publicidad con relieve, y bancos y túnel con detalle.
- **Personajes.** Proporciones y siluetas variadas (edad, complexión, ropa por
  oficio y clima), accesorios (mochilas, móviles, paraguas con lluvia) y
  gente en grupos.

Se comprueba con capturas de los mismos encuadres que en la etapa 2.

## Etapa 5 · Física y movimientos naturales

- **Que nada se atraviese.** Colisión real en ciudad y estadio, con cuerpos
  (`CharacterBody3D`) y formas en edificios, mobiliario, coches, gente, puertas,
  paredes y gradas. Hoy el paseo usa rectángulos de huella: hay que pasar a
  colisión de verdad o completarla donde falte.
- **Peatones y personal.** Que se esquiven entre ellos y esquiven al jugador,
  con rutas que rodean los obstáculos.
- **Movimiento del personaje.** Aceleración y frenada, giro suave, inclinación
  al correr, pasos sincronizados con el suelo y escaleras y rampas de verdad.
- **Animaciones.** Mezcla suave entre parado, andar y correr según la
  velocidad, y pies que no patinan.
- **Más físicas.** Balón con giro y bote realistas; objetos que se pueden
  empujar (balones, conos, papeleras); puertas físicas; coches con suspensión
  simple y choques que frenan; ropa y redes con movimiento.

Se comprueba con pruebas en el banco (no atravesar paredes, coches y gente; el
balón conserva la energía) y con capturas o vídeo de movimiento.

---

## Estado

| Etapa | Estado |
|---|---|
| 1 · Ultra pulido | **hecha (8-10)** · hoja `pruebas/capturas/etapa1_resumen.png` |
| 2 · Texturas y personajes | en curso |
| 3 · Optimización | pendiente |
| 4 · Realismo visual | pendiente |
| 5 · Física y movimiento | pendiente |

## Lista de cosas raras (Etapa 1)

- [x] Estadio distinto en la ciudad y en el partido (semilla y club). 8-10.
- [x] Gente del día de partido como «palos» (cápsulas). 8-10.
- [x] Hormigón y copas de árboles negros en el modo de compatibilidad. 8-10.
- [x] Taquillas y letrero de vestuarios tapando la entrada. 8-10.
- [x] La pared pintada del vestuario tapaba la puerta por dentro. 8-10.
- [x] El diálogo del portero no se cerraba al alejarse. 8-10.
- [x] 122 frases del estadio 2.0 sin traducir (8 idiomas). Herramienta:
      `pruebas/frases_sin_traducir.gd` + `pruebas/frases_2_0.gd`. 8-10.
- [x] Aviso de suavizado (FXAA/TAA) en el modo de compatibilidad. 8-10.
- [x] Fuga al cerrar: ciclo Roles ↔ Reputación y referencias estáticas. 8-10.
- [x] La cámara de la calle se metía dentro de los edificios. 8-10.
- [x] Saltos de golpe al cruzar puertas, escaleras y galería: ahora fundido. 8-10.
- [x] Nombres del personal gigantes de cerca. 8-10.
- [x] Metro: andén elevado blanco quemado, murales con letras enormes en la
      ventana del tren, plano de la red blanco por detrás. 8-10.
- [x] Karting: pilotos cabezones del kit (cabeza del tamaño del kart) → pilotos
      con proporciones de persona. 8-10.
- [x] Menú de inicio: las motas del fondo se dibujaban encima de textos y
      botones; ahora van detrás del contenido. 8-10.
- [x] Revisados sin cosas raras graves: partido 3D (marcador, nombres, radar,
      grada) y minijuegos de autógrafos, pesca, penales y tiro libre. 8-10.
- [x] Informe de la semana sin traducir (frases con números): 10 patrones nuevos
      en los 8 idiomas y traducción antes de la viñeta. «Documental de la
      temporada» traducido. 8-10.
- [x] Fondo «bokeh» de los menús: los círculos se cortaban en cuadrados. 8-10.
- [x] Fundido de entrada al abrir la ciudad 3D, el estadio y el partido. 8-10.
- [x] Revisada la Carrera de Jugador (creación, semana, partido, córner). 8-10.
- [x] El sonido «puerta» se pedía y no existía (silencio): creado, más pasos al andar a pie. 8-10.
- [x] (Pedido 8-10) Partículas del menú más bonitas (chispas con halo que titilan y se mecen + luces bokeh, teñidas por portada) y PORTADA que cambia sola cada 30 s con fundido. Captura: pruebas/captura_portada_rota.tscn.

### Segunda pasada de la etapa 1 (8-10, pedida: «siento que puedes hacerlo mejor»)
Recorrido TOTAL de la interfaz (`pruebas/captura_recorrido_total.tscn`: principal,
9 menús y las 42 pestañas, en hojas `recorrido_N.png`). Encontrado y arreglado:
- [x] El panel de OBJETIVOS tapaba la ficha del jugador en todas las pestañas a
      1600x900: plegado por defecto hasta 1900 px, con el número de pendientes.
- [x] «Vida» y «Habilidades» salían VACÍAS (no estaban en el pintado diferido).
- [x] «Editor» y «Libres» empujaban la ficha fuera de la pantalla: filas que se
      parten y desplazamiento horizontal dentro de la hoja.
- [x] Fondo de «Mi carrera»: manchas amarillas → hilos de luz finos.
