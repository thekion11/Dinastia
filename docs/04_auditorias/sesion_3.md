# Sesión 3 (26-10-2026) — rama `ccr-76d707c5-dwse9h-s3`

Tareas: rendimiento de menús, peatones que esquivan (ciudad), textos fijos del núcleo a claves traducibles y las
peticiones 2 y 8 de la sesión 2. Cada bloque con su prueba en `pruebas/ideas/s3_*` y el banco en «FIN. 0 fallos».

## 1. Rendimiento de menús: nodos creados por vuelta

**Medida.** `fugas_menus` solo mide lo que queda vivo (no crece). La prueba nueva `pruebas/ideas/s3_rotacion_menus.gd`
hereda su vuelta (todos los menús y submenús, cada chip, 8 fichas) y cuenta cada nodo que entra en el árbol
(`node_added`), separando los NUEVOS de los que solo se mudan de sitio (la pantalla de menú mueve el contenido de la
Principal a su hueco y lo devuelve), y apunta quién lo crea con `Engine.capture_script_backtraces()` (4 funciones de `ui/`).

| | antes | después |
|---|---:|---:|
| nodos NUEVOS por vuelta | 111 178 | 17 447 (−84 %) |
| nodos que se mudan de sitio | 54 960 | 32 310 |
| total que entra en el árbol | 166 138 | 49 757 (−70 %) |

**Causa.** `Principal._refrescar()` (en `ui/principal_p9.gd`) repintaba en CADA refresco —cada chip, cada submenú—
la tabla de la liga (~23 000 nodos por vuelta), el plantel (~26 000), el mercado (~26 000), el tablero de inicio
(~11 000) y la ficha (~10 000) aunque estuvieran ocultos. El resto de pestañas ya iban por `_perezoso()`.

**Arreglo.** Esas cinco pasan también por `_perezoso()`: si se ven, se pintan en el acto como antes; si no, quedan
pendientes y `_pintar_pendientes()` las pinta (y traduce) el primer fotograma en que se ven, con los datos de ese
momento. El título de la tabla se sigue poniendo siempre (es un texto). En `_ver_ficha()` (principal_p8) una ficha
pedida a mano borra la diferida, para que nunca la pise una vieja. Lo que se ve no cambia.

**Comprobado:** `s3_rotacion_menus` (exige ≤ la mitad de la línea base), `fugas_menus`, `uipl_plantel`, `uipl_textos`,
`uifi_gestion`, `uico_competicion`, `uiid_identidad`, mini-banco gestion/competicion/textos y
`captura_verificar_tabla|mercado|plantel` (sus dos «MAL» —verde daltónico del mercado y cabecera NOMBRE— fallan igual
sin el cambio: son de esas pruebas viejas de captura, no de esto).

## 2. Ciudad: peatones que esquivan de lado, ceder el paso y choque de coches

**Antes.** Un peatón que alcanzaba a otro de su ruta se quedaba detrás para siempre; ante el jugador se paraba en
seco a 1,6 m; y dos peatones de frente por la misma acera (rutas distintas) **se atravesaban** (0,01 m, medido).
Además, por un fallo de la condición (`alto < 0.3` es verdad también para los coches, que van a altura 0), los
coches frenaban a 1,6 m del jugador y no a los 7 m que decía el comentario: se medía 1,3 m.

**Ahora** (`visor/trafico_ciudad.gd`, `_p1.gd`). Cada peatón lleva `lado`, metros hacia su derecha respecto al eje de
su ruta (hasta ±0,8 m: la acera mide 4 m y la ruta va a 2,4 m del bordillo). `_colocar` lo aplica y gira un poco el
cuerpo hacia donde se aparta (`giro_lado`, hasta 0,6 rad, suavizado):
- al alcanzar a otro de su ruta se aparta al lado con sitio y le adelanta; con 0,6 m de lado entre ellos ya no se
  estorban; mantiene el lado hasta dejarle atrás y luego vuelve al eje (1,2 m/s de paso lateral);
- de frente con otro peatón, los dos se apartan a SU derecha y siguen a medio paso (antes: se atravesaban);
- ante el jugador, desde 3 m se aparta al lado contrario y aminora; solo se para si aún te roza a menos de 1 m;
- mientras dura la esquiva no cambia de lado (con el otro justo en el eje, el ruido le hacía bailar sin moverse);
- los coches vuelven a parar a ~7 m de ti (6,7 m medidos) en vez de a 1,3 m;
- al reaparecer cerca (`reciclar_peatones`) el lado vuelve a 0.
Los cruces en perpendicular siguen como estaban (uno espera al otro: es lo natural en un paso de cebra).

**Pruebas.** `pruebas/ideas/s3_peatones_esquivan.gd` (10 comprobaciones: adelanta al parado sin bajar de 0,7 m,
se aparta 0,7 m y vuelve al eje; de frente se cruzan a 1,06 m sin pararse; rodea al jugador a 0,7 m; el coche para a
6,7 m). Con el código anterior fallan 5 de ellas. `pmov_ceder` y `pmov_choque_coches` siguen en verde.

**Coste.** `sonda_explorador` (la ciudad real, 311 móviles, 25 a menos de 150 m): `trafico._process` 1,24 ms antes y
1,23 ms después. Cruce lleno a propósito (`pruebas/ideas/s3_coste_cruce.gd`: 64 peatones y 16 coches en 40 m, todos
en el nivel de detalle caro): 2,40 → 2,66 ms (+10 %), porque casi nadie se para y el que no se para hace la
comprobación entera. Probé a reutilizar la dirección de la rejilla en `_cede_paso` y no ganaba nada: lo quité.

**Capturas con la cámara real** (Forward+, `pruebas/captura_s3_ciudad.tscn`, `MODO=pie|coche`), en
`/tmp/capturas/s3/` (no se suben): `s3_peaton_1` (el vecino de verde a 1,9 m ya apartado 0,7 m),
`s3_peaton_2` (te pasa al lado), `s3_cede_coche` (el camión de la basura parado a 6,7 m de ti en un cruce),
`s3_choque_coche` (conduciendo contra su trasera: tu coche queda en 0 km/h pegado al parachoques, sin atravesarlo).
Visto de paso: en la primera tanda un vecino salía de detrás de un quiosco verde de la acera de la avenida
(1005, −500); la sonda de la captura no encontró ningún punto de ruta de peatones dentro de un obstáculo fijo a menos
de 120 m (0 de 427), así que el quiosco no estorba la ruta: solo tapaba la vista.

## 3. Textos fijos del núcleo a claves estables (petición 7 de la sesión 2)

**Antes.** `MesaAgente` devolvía las frases castellanas con las cifras dentro (««Así no.» Baja a 62 %. (Duda…)»),
`Negociacion` devolvía `prefiere` y `motivo` en castellano (y a la razón le pegaba un punto, con lo que ya no era
clave), y el `Movil` guardaba en la partida el mensaje ya montado (la clave del community manager, o «título cuerpo»
de una noticia). La interfaz traducía la frase entera: solo funcionaba si algún patrón de regex la reconocía.

**Ahora.**
- `nucleo/mesa_agente.gd`: todo sale ya traducido de plantillas fijas (`Idiomas.t("«Así no.» Baja a %d %%. %s") % […]`),
  la señal y «(Mira el reloj.)» por separado, el nombre por defecto del agente también. `ui/componentes/mesa_agente_ui.gd`
  deja de traducirlo otra vez.
- `nucleo/negociacion.gd`: `prefiere` y el `txt` del motivo salen traducidos; la razón se traduce y DESPUÉS se le pone
  el punto. `panel_mercado.gd` los pinta tal cual y `ui/principal_p14.gd` (registro de la negociación) pasa sus seis
  mensajes a plantillas con `Idiomas.t` (antes iban enteros en castellano con nombre y cifras dentro).
- `nucleo/movil.gd`: `recibir(de, icono, texto, anio, semana, args := [], trad_args := false)`; `texto` es la plantilla
  y `args` los datos, se guardan así y `Movil.texto(msj)` traduce al enseñar (cambiar de idioma cambia también los
  mensajes viejos; los guardados antes siguen saliendo como antes). La clave del CM (`redes_p1.gd`) y las noticias
  reenviadas (`principal_p10.gd`, con `trad_args`) ya van así. `telefono_p2.gd` usa `Movil.texto`. Los errores de la
  foto de perfil salen traducidos.
- Traducciones: 20 claves × 8 idiomas con `sumar_traducciones.py` (parche en `/tmp/trad_s3.json`); las 11 de la mesa
  salen de las plantillas de los patrones de la sesión 2 (cambiando `$1` por `%d`/`%s`), las otras 9 escritas aquí.

**Prueba** `pruebas/ideas/s3_textos_nucleo.gd`: 292 frases de la mesa (4 perfiles × 4 tipos × 3 caminos: regatear,
farol, ceder, plantarse, irse) en los 8 idiomas sin un trozo de castellano ni restos de formato, ninguna igual a la
castellana, y el castellano igual que antes; la contraoferta de una negociación real en los 9 idiomas con `prefiere`
traducido; un mensaje del móvil guardado y cargado por JSON que, al pasar a inglés, sale en inglés con sus datos.
`uite_movil_textos`, `uite_movil_navegacion`, `uite_traducciones`, `trad_textos`, `uifi_asuntos` y el grupo `textos`
del banco en verde.

Fuera de mi encargo y aún en castellano fijo: `Mercado.abrir_negociacion` («ese jugador ya es tuyo», vetos de
desafío) y las `razones` de `Mercado.deseo_de_venir` con cifras («Viene de un club más grande: %d de reputación…»),
que siguen dependiendo de patrones.

## 4. Peticiones de la sesión 2 (plan §9)

**Petición 2 (hecha).** `nucleo/idiomas.gd` `_t`: antes de partir en oraciones mira si, quitando el icono de delante
(solo símbolos desde U+2000 y espacios: «, ¿ y ( se quedan), la frase entera es una clave o un patrón. Antes, con
«🙏 Buenas, míster. ¿Un pan para el camino?» se traducía la primera oración sola y el resto quedaba en castellano;
ahora sale «🙏 Hello, boss. A loaf for the road?» (comprobado en `s3_textos_nucleo`). `Telefono._t_icono` ya no hace
falta para eso; lo dejo (lo usan otras pantallas) y no cambia nada.

**Petición 8 (no hecha).** La rueda de prensa 2D vive en `ui/principal_p17.gd`, que la sesión principal está tocando
ahora mismo: queda en el plan para quien tenga ese archivo.

## 5. Defectos visuales que anotó la sesión 2 (encargo ampliado, plan §9)

Todo con la cámara real (Forward+, `pruebas/captura_s3_interfaz.tscn`; `FINANZAS=1 BAJAR=flujo|px` para finanzas),
capturas en `/tmp/capturas/s3/` (no se suben). Prueba `pruebas/ideas/s3_defectos_visuales.gd` (13 comprobaciones).
No se tocan datos de caras ni colores de piel: solo el dibujo y la cámara.

- **Caras como cuadros negros** (`visor/retrato3d.gd`). Los retratos 3D sí se generan, de uno en uno (21 del plantel
  en ~8 s); lo negro era (1) el marcador provisional, que era el color del club oscurecido (negro con un club negro),
  y (2) a 22 px el busto de pecho para arriba dejaba la cara en unos 6 píxeles sobre una camiseta y un fondo casi
  negros. Ahora el marcador lleva una silueta clara de cabeza y hombros, el fondo nunca baja de luminosidad 0,2
  (`fondo_de`) y, hasta 40 px de alto (las filas de las listas), la cámara encuadra la cabeza y el cuello de la
  camiseta (`ALTO_CABEZA`, caché aparte). Ficha, móvil y demás tamaños siguen de pecho para arriba.
  Capturas `s3_caras_1` (marcador) y `s3_caras_2` (retratos ya hechos: se reconocen las caras).
- **Club negro.** Las miniaturas de forma, patrón y camiseta de un club oscuro van sobre un fondo claro
  (`EscudoMuestras.boton(..., claro)`; `oscuro()` = luminosidad < 0,2); `Principal._escudo` pone un halo claro y
  redondo detrás de un escudo oscuro (solo esos clubes: pocos nodos), y las iniciales contrastan con el fondo del
  escudo (`color_escudo1`, parte de la petición 9). Captura `s3_identidad`.
- **Flujo de caja en rampa.** Era el resultado del año partido en 12 (en la interfaz, `panel_finanzas.gd`, no en el
  núcleo). Ahora `FlujoCaja.saldos_por_mes` (`ui/componentes/flujo_caja.gd`) recorre las 48 semanas que vienen como
  las cobra el motor: la taquilla la semana en que juegas en casa según el calendario de tu liga, y el resto
  (televisión, patrocinio, socios, tienda, sueldos, estructura, operación) en el cierre de cada 4 semanas, con la
  temporada volviendo a la semana 1 al acabar la liga más larga. Captura `s3_flujo`. Honestidad: con estas cifras
  el cierre de mes pesa mucho más que la taquilla, así que la curva sigue subiendo casi recta; ahora los escalones
  son los de verdad (un mes con dos partidos en casa sube más). Lo que no muestra es el pasado: el libro de
  movimientos guarda solo 60 apuntes (`Mundo.LIBRO_MAX`, zona prohibida), no da para 12 meses de historia.
- **Cifras pegadas a la barra.** `Principal._dato` (petición 6) y `PanelFinanzas._dato` dejan 14 px de aire a la
  derecha con un `StyleBoxEmpty` compartido (sin nodos nuevos). Captura `s3_finanzas_2300`.
- **Mando 3D con «…».** `MandoGiratorio._lineas`: la etiqueta va en dos líneas cuando hay sitio entre filas (paso
  ≥ 30 px) y con más ancho si el panel lo permite (hasta 150 px); solo se recorta si ni así cabe.
  Captura `controles/controles.jpg` («Estadísticas del partido», «Táctica rápida: más ofensiva» enteras).
- **«Forma».** La rejilla del escudo usa la clave nueva `Forma del escudo` («Crest shape», 8 idiomas); «Forma»
  queda para la forma física («Form»). Falta el mismo cambio en `ui/entrada/config_club_pasos.gd:149` (zona de la
  sesión principal; anotado en el plan §9).

Visto de paso, sin tocar: la portada del periódico pinta la cara del jugador en 2D (no el retrato 3D) y el escudo
del club sin iniciales.

## 6. Petición 2 (icono con varias oraciones)

Ya estaba hecha en el bloque 4 (commit ddcf5734): ver arriba.

## 7. Pruebas visuales automáticas (plan §10)

`herramientas/visual.sh` (compara) y `herramientas/visual.sh referencias` (rehace las referencias tras un cambio
visual querido). Escena `pruebas/visual/visual.tscn`: un mundo de semilla fija (20261026) entra en la Principal por
`Principal.mundo_pregenerado`, se salta el tutorial de bienvenida y recorre 20 pantallas (inicio, plantel, táctica,
entrenar, enfermería, cantera, contratos, calendario, finanzas, mercado, clubes, copa, correo, estadio, identidad,
personal, récords, redes, ajustes de interfaz, glosario) con Forward+ a 1280×720. Tarda ~1 min 20 s sin GPU.

- **Referencias:** `pruebas/visual/referencias/*.jpg`, 640×360 al 85 %, 40–60 KB cada una (1,1 MB en total),
  archivos normales (los JPG no van a LFS en `.gitattributes`); la carpeta lleva `.gdignore` para que Godot no las
  importe.
- **Comparación:** reducidas a 320×180, por bloques de 10×10 (~40×40 px reales). Un bloque cambia si su diferencia
  media pasa del 4 %; la pantalla CAMBIÓ con 2 bloques o más. Las que cambian dejan en `/tmp/visual/` la foto actual
  y un mapa con lo distinto en rojo.
- **Estabilidad:** antes de cada foto espera a que la cola de retratos 3D esté vacía y a que la pantalla se quede
  quieta (dos fotogramas seguidos sin bloques distintos), con animaciones reducidas (solo en memoria) y el reloj a
  ×10. Sin eso las referencias pillaban filas y miniaturas a mitad de su fundido.
- **Calibración** (dos pasadas seguidas sin cambios): 0 de 20 cambiadas. El único bloque con ruido es siempre el
  retrato 3D de la ficha (pose algo distinta en cada pasada, hasta 7,6 %): un bloque solo no basta para fallar.
- **Sensibilidad** (variable `SABOTAJE`, solo para esto): cambiar el nombre de la cabecera → 20 de 20 cambiadas;
  esconder el panel de objetivos → 20 de 20; teñir la tabla oscura ×0,75 de verde y azul → 0 de 20. Es decir: ve
  textos y paneles que cambian o faltan; NO ve un cambio de tono suave sobre zonas oscuras.
- **Prueba sin pantalla:** `pruebas/ideas/s3_visual_metrica.gd` (iguales = 0 bloques, un rótulo de 90×40 px se ve,
  el ruido del JPG no cuenta).

No está en `especiales.sh` porque necesita Vulkan (lavapipe); se lanza aparte.

## 8. Accesibilidad básica (Game Accessibility Guidelines, nivel básico)

Prueba `pruebas/ideas/s3_accesibilidad.gd` (14 comprobaciones); captura `s3_acceso` (`CONTRASTE=1 ACCESO=1`).

- **Reasignar teclas y botones.** Lo del partido ya se reasignaba en Controles (`Mando.reasignar`, desde Ajustes →
  Dispositivo → «Controles del partido»). Faltaba moverse por los menús: `ui/componentes/teclas_interfaz.gd`
  (`TeclasInterfaz`) reasigna Aceptar, Volver y Pestaña anterior/siguiente (una tecla y un botón del mando cada
  una), en Ajustes → Accesibilidad → «Teclas de la interfaz» con «Cambiar» (escucha la siguiente tecla o botón; Esc
  cancela) y «Restaurar las teclas de fábrica». Se guarda en `user://teclas_interfaz.cfg` (aparte de
  `controles.cfg`) y se aplica al final de `Principal._preparar_mando`. Una tecla no hace dos cosas: se le quita a
  las otras. Ojo: si el jugador le pasa a «Aceptar» la tecla de «Volver», «Volver» se queda sin tecla hasta que le
  ponga otra (igual que en Controles); el ratón sigue funcionando.
- **Contraste alto.** Paleta nueva «Contraste alto» (fondo y panel negros y opacos, texto blanco, suave casi
  blanco, bordes marcados) con interruptor en Ajustes → Accesibilidad; al apagarlo vuelve la paleta anterior. El
  salto mínimo de luminosidad de `_con_contraste` sube de 0,42 a 0,6 con ella. `Tema.contraste` lleva lo mismo a lo
  que se pinta con `Tema.*` (texto, suave, bordes y paneles de `caja()`). De paso, la **petición 3 de la sesión 2**:
  `_refrescar` vuelca `_daltonico` y `_escala_texto` en `Tema` (antes no llegaban al teléfono, avisos, competición).
- **Fallo previo arreglado al probarlo:** con cualquier paleta que no fuera la de por defecto, `_color_de_paleta`
  pasaba los colores de FONDO (`COL_PANEL`, `COL_FONDO`, `COL_BORDE`) por el empuje de contraste pensado para
  letras, y las píldoras (Dispositivo, Sonido, chips de días…) salían gris claro con letra blanca. Ahora esos tres
  devuelven los de la paleta.
- **Ningún dato solo con color.** Las zonas de la tabla (campeón, continental, ascenso, promoción, descenso) solo se
  distinguían por el color del número del puesto (con el nombre en un tooltip, que con mando no se ve): ahora llevan
  símbolo (★ ◆ ▲ ↕ ▼) junto al puesto, en la tabla lateral y en la ficha de competición, y en la leyenda. En el
  plantel, «joven con margen» era solo verde: lleva «↗» (lo rojo ya llevaba 🩹 o 🚫); leyenda traducida a los 8.
  Revisado y ya bien: la racha (letras G/E/P), los niveles con ●/○, las cifras de finanzas con su signo, el modo
  daltónico con muestra.
- Textos nuevos: 10 claves × 8 idiomas.

Lo que queda del nivel básico (en el plan §10): lector de pantalla mínimo, reasignar las teclas propias del menú
lateral y del móvil, y repasar el contraste alto en las pantallas 3D y en las capas a pantalla completa.
