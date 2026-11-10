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

## Pendiente
- La orden dice «Triángulo / X = espacio». Con un mando de PlayStation la X es el botón que pulsa la tecla enfocada, así que solo se
  puso Triángulo. ¿Para «X» el dueño se refiere al botón X de Xbox (el Cuadrado de PlayStation, que ya borra)? Es decisión del dueño.
- La reunión con la directiva marca la respuesta con la aguja del selector en cruz más que con el aro del foco: es su diseño
  (`SelectorDireccional`).
