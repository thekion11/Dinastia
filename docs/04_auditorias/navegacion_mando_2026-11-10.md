# Navegación con mando y teclado: auditoría (10-11-2026)

Encargo de la líder: orden 26 (el FOCO es uno de los puntos débiles) y orden 33 (con mando, «Cuadrado borra, R2 confirma»).

## Cómo se midió
`pruebas/auditoria_foco_mando.tscn` (en `especiales.sh todo`, ~10 min). Abre la pantalla principal con un mando simulado
(`FocoMando.forzar`) y recorre:
- las 35 pestañas;
- los 9 menús laterales;
- dos eventos a pantalla completa: la reunión con la directiva y la rueda de prensa.

Antes contesta la reunión de inicio de temporada, que se abre sola. En cada pantalla comprueba:
- **foco al entrar:** hay foco visible y no cae en un campo de texto (abriría el teclado en pantalla sin pedirlo);
- **trampas:** 30 pulsaciones de cruceta simuladas sin que el foco se pierda, quede en algo oculto o, en las capas que van encima
  (menús y eventos), salga de ellas;
- **alcance:** qué parte de los controles se alcanza con la cruceta desde el primero;
- **foco visible:** el control enfocado tiene un estilo de foco que se ve.

Además, el TECLADO EN PANTALLA con la orden 33. Con `FOTOS=1` (con pantalla) saca el foco de 3 pantallas: Plantel, Ajustes y
Competiciones.

## Hallazgos (antes)
- **11 pestañas sin foco ni forma de leerlas con mando:** Copa, Continental, Enfermería, Logros, Selección, Comparar, Récords,
  Camarín, Glosario, Premios y Desafíos no tienen controles. El foco quedaba en nada: la cruceta no hacía nada y no había forma de
  desplazarse por el contenido.
- **Pestañas que se montan tarde, sin foco:** Mercado (33 controles) y Vida (9). El botón que recibía el foco se liberaba al
  reconstruirse la pestaña.
- **Foco en un campo de texto al entrar:** Estadio y Editor. Con mando se abría el teclado en pantalla nada más llegar.
- **Los 9 menús laterales dejaban escapar el foco:** la cruceta lo llevaba a los botones de la pantalla de detrás (17-23
  controles visitados fuera del menú; solo 1 alcanzable dentro).
- **La rueda de prensa también lo dejaba escapar:** un botón «⤢» de detrás.
- **Listas largas:** las zonas de desplazamiento tenían `follow_focus` apagado. El foco iba a botones fuera de la vista y, en la
  última fila visible, se quedaba CLAVADO: lo siguiente está recortado por el borde y la búsqueda de vecinos de Godot lo ignora.
  En Finanzas se alcanzaban 6 de 17 controles, en Contratos 24 de 107 y en Táctica 55 de 108.
- **Teclado en pantalla:** no tenía nada de la orden 33.
- **Total: 38 fallos.**

## Arreglos
- **`FocoMando`:**
  - `primero` no elige campos de texto;
  - `enfocar` reintenta unos fotogramas si la pestaña aún se monta y, si no hay ningún control, enfoca la zona de desplazamiento
    (`desplazable`), que la cruceta arriba/abajo mueve;
  - `aislar` / `liberar` / `aislar_mientras`: mientras una capa está encima, lo de detrás deja de ser enfocable
    (`focus_behavior_recursive`, Godot 4.5+). Lo usan `PantallaMenu` y la rueda de prensa.
- **`GuardianFoco`** (nuevo, lo monta la principal), solo con mando:
  - recupera el foco si se pierde, queda en algo oculto o sale de la capa de encima (menús, diálogos a pantalla completa y eventos
    `EventoPantallaCompleta`, que son capas de lienzo);
  - al cambiar el foco, desplaza las zonas que lo contienen hasta dejarlo a la vista;
  - en arriba/abajo dentro de una zona, si Godot no encuentra vecino porque lo siguiente está recortado, va al control más cercano
    en esa dirección.
  - Si el foco está fuera de la principal (el teclado en pantalla) no lo toca.
- **Teclado en pantalla (orden 33):** CUADRADO borra, R2 confirma (✔ Aceptar), TRIÁNGULO pone un espacio y L2 cambia
  mayúsculas/minúsculas; las teclas lo dicen («⌫ (□)», «Aceptar (R2)», «Espacio (△)», «Mayús (L2)»). Los gatillos cuentan una vez
  por pulsación. En los menús R2/L2 siguen cambiando de bloque: la orden es para escribir, como dice el plan.

Resultado: **0 fallos**. En todas las pantallas con controles se alcanza el 100 %. Siguen en verde `ate_atajos_menus`,
`aud4_teclado_solo` y el banco.

## 2.ª parte: eventos, temporada y editor de formación
Encargo de la líder: las mismas comprobaciones en las pantallas a pantalla completa y en el editor de formación.
`pruebas/auditoria_foco_eventos.tscn` (en `especiales.sh todo`, ~2 min) hereda la prueba anterior y recorre:
- de la selección: la oferta del cargo, la fecha FIFA, el partido de un torneo y la convocatoria (61 controles);
- el festejo de un título, el aviso y la ceremonia del partido de despedida (Leyendas de un club de otro país), el calendario y el
  palmarés del mundo;
- la ficha de competición con la FASE FINAL de una liga que la tiene (Argentina);
- el final de temporada (`ResumenTemporada`);
- el editor de formación (Táctica → «Editar posiciones»).
Las ligas y ofertas de trabajo que salen en pestañas (Legado, Récords, Inicio, Despacho) ya estaban en la 1.ª parte.

Hallazgos:
- **Ficha de competición:** la cruceta a izquierda o derecha sacaba el foco a la pantalla de detrás (16 de 30 pulsaciones).
- **Editor de formación, una TRAMPA:** la cruceta solo movía la ficha y Aceptar pasaba a la siguiente, así que con mando no se podía
  salir del campo. Al abrirlo, el foco se quedaba en el botón «Editar posiciones», ya desactivado. El campo, un `Control` a secas,
  no dibujaba ningún foco, y la prueba anterior lo daba por bueno porque el tema le devolvía un estilo que nunca dibuja.
- Todo lo demás (selección, festejo, despedida, calendario, palmarés, final de temporada) ya pasaba.

Arreglos:
- La ficha de competición aísla lo de detrás mientras está abierta (`FocoMando.aislar_mientras`).
- **Editor de formación** (como el «Editar posición» del PES):
  - la cruceta ELIGE la ficha más cercana en esa dirección;
  - Aceptar la AGARRA (aro dorado más grande) y la cruceta la mueve;
  - Aceptar o Atrás la suelta;
  - si no hay ficha en esa dirección, el foco SALE del campo: abajo, a «Guardar»; desde la fila de botones, arriba vuelve al campo;
  - al abrirlo el foco va al campo, que dibuja un marco dorado cuando está enfocado;
  - Tab sigue cambiando de ficha, y el ratón y el dedo, igual que antes;
  - el texto de ayuda lo explica, en los 9 idiomas.
- **Capas de evento apiladas** (salió con pantalla): al cerrar la temporada se abren las cinemáticas de sorteo pendientes y los eventos
  a pantalla completa, que van en capas de lienzo (siempre encima), pero el foco podía quedarse en un control tapado. Ahora:
  - toda `EventoPantallaCompleta` aísla lo de debajo mientras está abierta;
  - `FocoMando.aislar` lleva la cuenta por control, así que con dos capas apiladas lo de debajo solo vuelve a ser enfocable al cerrar
    la última;
  - `GuardianFoco.capa_arriba` mira primero las capas de lienzo.
- La prueba exige además que, en una capa modal, el foco empiece DENTRO de ella, y si se pierde dice a dónde se fue.
  `SOLO_FIN=1` lanza solo el final de temporada.
- `GuardianFoco` respeta los controles que usan la cruceta (meta `cruceta_propia`). La prueba exige que un `Control` a secas
  dibuje su propio foco (meta `foco_visible`).

Resultado: **0 fallos** en las 13 pantallas, sin pantalla y con ella. La 1.ª parte y el banco siguen en verde.

## Pendiente
- La tarjeta del tutorial plegada («💡 Táctica», abajo a la derecha) tapa en parte lo último de la lista: en el editor de formación,
  el botón «Cancelar». La lista se puede desplazar y la tarjeta es de otro rediseño (3-11), así que no la toqué.
- La orden dice «Triángulo / X = espacio». Con un mando de PlayStation la X es el botón que pulsa la tecla enfocada, así que solo se
  puso Triángulo. ¿Para «X» el dueño se refiere al botón X de Xbox (el Cuadrado de PlayStation, que ya borra)? Es decisión del dueño.
- La reunión con la directiva marca la respuesta con la aguja del selector en cruz más que con el aro del foco: es su diseño
  (`SelectorDireccional`).
