# Pasada visual de la ciudad n.º 1 (4-11-2026) — hoja antes/después
Capturas Forward+ (lavapipe, `herramientas/captura.sh`), calidad MEDIA, 13:00, cámara del explorador: `pruebas/captura_pasada_ciudad.tscn` (`FASE=antes|despues`, `SOLO=<zona>`), una toma aérea (55 m) y una a pie por zona: centro (plaza mayor, ayuntamiento, mercado, comercial, torres), barrios (pisos, casas, industrial, parque, gasolinera, puerto), estadio por fuera y transporte (paradero, metro). Las 11 primeras tomas de la tanda «antes» salieron de una sola carga (la máquina mata el proceso al pasar de ~12 tomas: se reparte en tandas con `SOLO`).

## Qué se vio y qué se cambió
| Zona | Problema | Cambio | Antes / después |
|---|---|---|---|
| Centro: ayuntamiento (y hospital, comisaría, cine, edificios «claros») | Cajas lisas: solo la cara sur llevaba la piel de fachada; por detrás y de lado, un bloque de plastilina sin una ventana | `MuroCivico.vestir`: el shader de fachada de las torres (ventanas por piso, azotea lisa, ventanas encendidas de noche) con el color de pared de cada edificio. Misma malla, un material por color: 0 llamadas más | `capturas_ciudad_c2/pasada1_centro_ayuntamiento_aerea_{antes,despues}.jpg` |
| Barrio industrial | Parcelas de un gris liso (`_mat_simple`) | Usan el hormigón con textura `_mat["solar"]` (el de los demás solares) | `capturas_ciudad_c2/pasada1_barrio_industrial_aerea_{antes,despues}.jpg` |

Calidad MÍNIMA: `medir_prologo` 1 120 llamadas (antes de la pasada 1 153; no sube).

## Visto y NO cambiado (para la siguiente pasada)
- Plaza mayor: un volumen crema liso al norte de la plaza (no identificado: parece una caja de soportales vista por detrás).
- Mercado municipal: nave de bóveda verde y base ocre lisas, sin puertas visibles por la cara norte; delante, una plaza de asfalto vacía con solo dos casetas.
- Parcelas industriales: muy vacías (una nave y contenedores por manzana).
- Césped de las casas: matas de hierba muy grandes y aisladas sobre un césped liso.
- Estadio por fuera: el campo muestra un corte diagonal entre franjas (sombra de la grada; no es un fallo del campo).
- Las tomas «a pie» de la plaza mayor y del ayuntamiento tienen la cámara dentro de un rótulo / del muro: es un problema de las posiciones de la toma, no de la ciudad.
