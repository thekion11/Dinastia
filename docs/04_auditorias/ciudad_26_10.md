# Auditoría de la ciudad (26-10-2026)

Pedido del dueño: *«hay partes de la ciudad sin detalles y muy mejorables… analizar toda la ciudad, mejorar la
construcción y cuidar la coherencia»*. **Solo análisis y capturas: no se ha cambiado la ciudad.**
Capturas en `docs/04_auditorias/capturas_ciudad/` (`<zona>_aerea.jpg`, `<zona>_pie.jpg`, 1280×720, 11:00, Forward+).

## Resumen en cinco líneas
1. **Los edificios singulares son cajas con un adorno** (centro comercial, comisaría, ayuntamiento, universidad, escuela,
   cocheras, hospital, bomberos): desde el aire se leen por el rótulo, pero **a pie son una pared lisa**, sin puerta,
   escaparates, marquesina ni rótulo en la fachada.
2. **Los dos errores de construcción están cerrados** en la pasada C2 (la «Villa moderna» era una cúpula y el lago flotaba sobre los árboles): ver el final del documento.
3. **Grandes superficies vacías:** gasolineras, desguace, plaza mayor, barrios industriales (un edificio y una fila de contenedores
   por manzana) y las parcelas de césped del sur.
4. **Repetición:** `gasolinera` ×3 y `parque` ×5 son idénticos; los barrios «pisos» y «torres» repiten bloque y ventanas.
5. Lo mejor resuelto: **feria**, **puerto/puentes**, **parque de barrio** y las **casas del sur**; son la vara de medir del resto.

## Método
Guion `dinastia-godot/pruebas/ideas/f6c_captura_ciudad.tscn` (`herramientas/captura.sh res://pruebas/ideas/f6c_captura_ciudad.tscn`;
`ZONAS=cine,hospital` para elegir, `SOLO=pie` para repetir las tomas a pie). Por cada tipo de manzana de `CiudadExpansion`
(los usos de `ESPECIALES` por su nombre y un ejemplar de cada barrio, `barrio_<zona>_<uso>`): una toma **aérea** (cámara orbital, 120 m)
y otra **a pie** (primera persona, a 16 m del lado de la manzana, mirando de frente). 29 zonas, 58 tomas.
Código leído para cada hallazgo: `visor/ciudad_expansion_p7.gd` (los edificios singulares), `ciudad_expansion_p2.gd` (usos de zona).

## Por zona
Leyenda: **V** = vacío o caja lisa · **D** = desentona · **I** = incoherencia.

| Zona | Qué hay | Problemas |
|---|---|---|
| **Centro comercial** ([aérea](capturas_ciudad/centro_comercial_aerea.jpg) · [pie](capturas_ciudad/centro_comercial_pie.jpg)) | Una caja blanca de 16 m (90 % × 55 % de la manzana), tira de vidrio de 0,2 m y un parche de asfalto | **V** pared blanca de ~70 m sin puerta ni escaparates ni rótulo en la fachada; sin aparcamiento marcado; **D** el blanco puro contra el ladrillo de los vecinos |
| **Ayuntamiento** ([aérea](capturas_ciudad/ayuntamiento_aerea.jpg) · [pie](capturas_ciudad/ayuntamiento_pie.jpg)) | Caja crema con columnas en un lado y una torrecilla verde | **V** a pie, pared crema lisa; sin escalinata, bandera ni reloj; **D** columnas solo en una cara |
| **Plaza Mayor** ([aérea](capturas_ciudad/plaza_mayor_aerea.jpg) · [pie](capturas_ciudad/plaza_mayor_pie.jpg)) | Losa gris ~110 m, fuente azul, 4 árboles, un quiosco y la valla «LAUTARO FC» | **V** ~90 % de la losa vacía: sin bancos, farolas, soportales ni terrazas; **I** la valla del club tapa la esquina de la plaza |
| **Estación Central** ([aérea](capturas_ciudad/estacion_central_aerea.jpg) · [pie](capturas_ciudad/estacion_central_pie.jpg)) | Caja blanca con bóveda de cristal y una tira verde | **V** sin vías, andenes ni trenes visibles: es una nave con bóveda de cristal; **I** una estación sin nada de ferrocarril |
| **Mercado** ([aérea](capturas_ciudad/mercado_aerea.jpg) · [pie](capturas_ciudad/mercado_pie.jpg)) | Bóveda verde sobre un zócalo naranja | **V** sin puestos, toldos ni cajas de fruta; **D** verde y naranja saturados |
| **Cine** ([aérea](capturas_ciudad/cine_aerea.jpg) · [pie](capturas_ciudad/cine_pie.jpg)) | Caja morada con tira rosa | **V** sin marquesina, cartelera ni taquilla |
| **Hospital** ([aérea](capturas_ciudad/hospital_aerea.jpg) · [pie](capturas_ciudad/hospital_pie.jpg)) | Dos cajas blancas, cruz roja y helipuerto | **V** sin urgencias ni ambulancias; el helipuerto no tiene helicóptero |
| **Comisaría** ([aérea](capturas_ciudad/comisaria_aerea.jpg) · [pie](capturas_ciudad/comisaria_pie.jpg)) | Caja blanca con tira azul | **V** sin puerta, escudo ni coches patrulla |
| **Bomberos** ([aérea](capturas_ciudad/bomberos_aerea.jpg) · [pie](capturas_ciudad/bomberos_pie.jpg)) | Caja roja con tres portones blancos y torre de mangueras | Lo más legible de los servicios; **V** sin camión en los portones |
| **Gasolinera** ([aérea](capturas_ciudad/gasolinera_aerea.jpg) · [pie](capturas_ciudad/gasolinera_pie.jpg)) | Marquesina plana a 6 m y una caseta blanca | **V** los surtidores (una caja de 1,2 × 2 m) quedan **ocultos bajo la marquesina**; solar de asfalto enorme; **repetida ×3** |
| **Cocheras** ([aérea](capturas_ciudad/cocheras_aerea.jpg) · [pie](capturas_ciudad/cocheras_pie.jpg)) | Nave gris y 4 autobuses aparcados | **V** nave sin portones; los autobuses son buenos |
| **Desguace** ([aérea](capturas_ciudad/desguace_aerea.jpg) · [pie](capturas_ciudad/desguace_pie.jpg)) | Solar de asfalto, un montón de piezas pequeñas y una máquina | **V** el 95 % del solar vacío; sin valla ni chatarra apilada |
| **Escuela / Instituto** ([escuela](capturas_ciudad/escuela_aerea.jpg) · [instituto](capturas_ciudad/instituto_aerea.jpg)) | Caja naranja en L y patio verde; **los dos son el mismo modelo** (misma rama de código) | **V** sin ventanas visibles ni valla; el patio es un rectángulo verde sin canchas; **D** el naranja liso |
| **Universidad** ([aérea](capturas_ciudad/universidad_aerea.jpg) · [pie](capturas_ciudad/universidad_pie.jpg)) | Caja crema larga con un cono azul y césped | **V** sin escalinata ni columnas; **D** el cono flota sobre un tejado plano |
| **Villa moderna** ([aérea](capturas_ciudad_c2/villa_moderna_aerea_despues.jpg) · [pie](capturas_ciudad_c2/villa_moderna_pie_despues.jpg)) | Casa de dos plantas con ala y cochera (kit suburbano), acceso de coches, camino de losas y árboles | **V** el solar de 83 m sigue siendo mucho césped para tres edificios pequeños; sin piscina ni cerca |
| **Parque del Lago** ([aérea](capturas_ciudad_c2/parque_lago_aerea_despues.jpg) · [pie](capturas_ciudad_c2/parque_lago_pie_despues.jpg)) | Parque con caminos, estanque con orilla de arena, árboles, bancos, parterres y puestos | **V** el estanque no tiene patos, embarcadero ni vegetación de orilla |
| **Parque** ([aérea](capturas_ciudad/parque_aerea.jpg) · [pie](capturas_ciudad/parque_pie.jpg)) | Cruz de caminos, fuente, columpios, árboles y casetas | Bien resuelto; **repetido ×5** sin variaciones |
| **Feria** ([aérea](capturas_ciudad/feria_aerea.jpg) · [pie](capturas_ciudad/feria_pie.jpg)) | Noria, montaña rusa, casetas, edificio morado y árboles | **La mejor zona.** **D** el edificio morado es una caja lisa |
| **Puerto** ([aérea](capturas_ciudad/puerto_aerea.jpg) · [pie](capturas_ciudad/puerto_pie.jpg)) | Almacén marrón, grúa amarilla, 3 veleros, 2 puentes de piedra y contenedores | Bien; **V** el almacén es una caja sin puertas |
| **Casa Grande** ([aérea](capturas_ciudad/casa_grande_aerea.jpg) · [pie](capturas_ciudad/casa_grande_pie.jpg)) | Finca con seto, fuente, camino y **cuatro bloques de pisos** de colores | **I** la «casa» son cuatro edificios de pisos; 4 bloques en 220 × 220 m de césped |
| **Granja urbana** ([aérea](capturas_ciudad/granja_aerea.jpg) · [pie](capturas_ciudad/granja_pie.jpg)) | Ocho bancales verdes, un cobertizo rojo y un tractor | **V** sin cultivos distintos, vallas ni invernaderos |
| **Barrio sur (casas)** ([aérea](capturas_ciudad/barrio_sur_casas_aerea.jpg) · [pie](capturas_ciudad/barrio_sur_casas_pie.jpg)) | 8 casas por manzana con seto y camino | **V** parcelas de césped sin casas junto a la avenida; **D** mismas 4-5 casas repetidas |
| **Barrio este (pisos)** ([aérea](capturas_ciudad/barrio_este_pisos_aerea.jpg) · [pie](capturas_ciudad/barrio_este_pisos_pie.jpg)) | 6 bloques de pisos por manzana en dos filas | **V** manzana de asfalto con franjas de césped; **D** bloques iguales, solo cambia el color |
| **Barrio oeste industrial** ([aérea](capturas_ciudad/barrio_oeste_industrial_aerea.jpg) · [pie](capturas_ciudad/barrio_oeste_industrial_pie.jpg)) | Una nave con chimenea y una fila de contenedores por manzana gris | **V** más del 80 % de cada manzana vacía; **D** gris contra el césped de al lado |
| **Barrio centro (torres)** ([aérea](capturas_ciudad/barrio_centro_torres_aerea.jpg) · [pie](capturas_ciudad/barrio_centro_torres_pie.jpg)) | Anillo de comercios bajos de colores con **dos torres blancas** de ventanas en cuadrícula dentro del patio | **D** las torres, idénticas a las de otras manzanas, no dialogan con el anillo; **V** plantas bajas de las torres sin comercios |
| **Barrio centro / este (comercial)** ([centro](capturas_ciudad/barrio_centro_comercial_aerea.jpg) · [este](capturas_ciudad/barrio_este_comercial_aerea.jpg)) | Anillo de comercios bajos con patio verde, caminos y una torre aislada en el centro | Es el barrio mejor resuelto de la zona norte; **D** la torre suelta del patio |
| **Barrio oeste (pisos)** ([aérea](capturas_ciudad/barrio_oeste_pisos_aerea.jpg) · [pie](capturas_ciudad/barrio_oeste_pisos_pie.jpg)) | Seis bloques de pisos pequeños y blancos esparcidos por una manzana de asfalto, con dos franjas de césped | **V** el 90 % de la manzana es asfalto vacío; **D** bloques minúsculos junto a las torres enormes de al lado |

## Incoherencias transversales
- **Escalas:** un kit Kenney a ~1 m por casilla (casas, coches, mobiliario) convive con cajas de 16-20 m sin ventanas: la caja se lee como
  «maqueta de volumen» al lado de piezas con detalle.
- **Colores:** los singulares usan colores planos y saturados (rosa, morado, verde, naranja, rojo) que no salen de la paleta
  de los kits; los barrios usan el colormap pastel de Kenney.
- **Reutilización:** mismo plano para gasolinera ×3 y parque ×5; las manzanas «industriales», «pisos» y «torres» repiten composición.
- **Rótulos:** los carteles flotantes («Hospital», «Ayuntamiento»…) son el único indicio; ninguno está **sobre** la fachada.
- **Conexión con el transporte:** la Estación Central no tiene andén ni vías; el viaducto del metro (L1, franja roja) pasa pegado al hospital y a la
  comisaría; hay una entrada de cristal junto al hospital, pero ningún acceso peatonal marcado entre la entrada y los edificios.

## Lista priorizada de mejoras
Horas = estimación de una persona con el catálogo `Modulos` ya hecho; las piezas son de `assets/kenney/INVENTARIO.md`.

| # | Mejora | Pieza / método | Horas |
|---|---|---|---:|
| **P1-4** | **Fachada del centro comercial**: puertas dobles, escaparates en dos plantas, marquesina y rótulo SOBRE la pared; aparcamiento con plazas y farolas | `mini_mercado/` + `kit_edificios/` (paredes con ventana y puerta animada) | 6 |
| **P1-5** | Servicios (comisaría, hospital, ayuntamiento, escuela, instituto, cine, universidad): **plantilla de fachada** con zócalo, ventanas por pisos, puerta con marquesina y un rótulo en la pared | `edificios_modulares/` (bloques, ventanas, tejados) + `kit_edificios/` | 12 (≈1,5 por edificio) |
| **P1-6** | **Estación**: andén, vías y un tren parado; unir la boca de metro más cercana con una pasarela | `tren/` (103 piezas) | 6 |
| **P2-11** | **Casa Grande**: una casa grande de verdad (mansión de 3 volúmenes con porche) y los bloques de pisos fuera | `suburbano/` + `edificios_modulares/` | 5 |
| **P2-12** | **Barrios**: variar las casas (≥10 tipos) y rellenar las parcelas de césped vacías; bajos comerciales en «torres» y «pisos» | `suburbano/` (21 casas) + `edificios_modulares/` | 8 |
| **P3-13** | **Variantes** de gasolinera y de parque (3 cada una) | `Modulos.tomar/unir` | 4 |
| **P3-14** | **Paleta** única para los singulares (sacar rosa/morado/verde saturados) | ajuste de materiales en `ciudad_expansion_p7.gd` | 1 |
| **P3-15** | Granja: cultivos distintos, vallas e invernadero | `suburbano/` vallas + `comida/` | 3 |
| | **Total** | | **≈ 64** |

Orden recomendado: P0-3 (3 h, la gasolinera) → P1-4 y P1-5 (la plantilla de fachada sirve a 8 edificios) → P1-6/7 →
P2 por zona. Cada pasada, con captura antes y después desde `f6c_captura_ciudad` y veredicto del dueño (§2.2e del plan).

## Pendiente de esta auditoría
- No se midieron las rutas (semáforos sin cruce, aceras cortadas, calles sin salida): hace falta un recorrido en coche/metro que no
  cabe en las tomas por manzana. Se vio, en la toma del sur, una avenida que termina en césped junto al río.
- Las tomas son de día (11:00); la noche (farolas, ventanas, rótulos encendidos) no se ha revisado.

## Pasada C2 (27-10): fallos de construcción arreglados
Capturas antes / después en `docs/04_auditorias/capturas_ciudad_c2/` (`<zona>_<aerea|pie>_<antes|despues>.jpg`, mismo guion, 11:00, Forward+).

- **Villa moderna.** Causa: `oficina_dt.glb` trae una semiesfera de cielo de 103 × 52 × 103 m (`Sphere`); al medir la caja para escalar el modelo al solar,
  la semiesfera mandaba y salía una cúpula de ~75 m. Ahora `CiudadVilla` (`visor/ciudad_villa.gd`) arma una casa de dos plantas
  (máx. 11,5 m) con tres piezas del kit suburbano, acceso de coches, camino de losas hasta la calle y árboles. Antes:
  [aérea](capturas_ciudad_c2/villa_moderna_aerea_antes.jpg) · [pie](capturas_ciudad_c2/villa_moderna_pie_antes.jpg);
  después: [aérea](capturas_ciudad_c2/villa_moderna_aerea_despues.jpg) · [pie](capturas_ciudad_c2/villa_moderna_pie_despues.jpg).
- **Lago del parque.** Era un cilindro de radio 0,3 del parque (×1,4) elevado 0,18 m, encima de árboles, bancos y puestos. Ahora es más pequeño
  (radio 0,13), está en el cuadrante sur-este lejos de los puestos y parterres, a ras de suelo con orilla de arena, y los árboles se colocan fuera del
  agua y de su orilla. Antes: [aérea](capturas_ciudad_c2/parque_lago_aerea_antes.jpg) · [pie](capturas_ciudad_c2/parque_lago_pie_antes.jpg);
  después: [aérea](capturas_ciudad_c2/parque_lago_aerea_despues.jpg) · [pie](capturas_ciudad_c2/parque_lago_pie_despues.jpg).
- **Casa de la ribera.** Confirmado: mismo defecto (una cúpula blanca de ~25 m en la parcela). `CityBuilder._casa_ribera` quita ahora la semiesfera de cielo
  antes de medir y la casa moderna real sale a 22 m. Antes: [aérea](capturas_ciudad_c2/casa_ribera_aerea_antes.jpg) · [pie](capturas_ciudad_c2/casa_ribera_pie_antes.jpg);
  después: [aérea](capturas_ciudad_c2/casa_ribera_aerea_despues.jpg) · [pie](capturas_ciudad_c2/casa_ribera_pie_despues.jpg). Después de esta primera pasada se vio que las losas de roca flotaban y que había un árbol en mitad de la calzada; segunda pasada: se quitan las losas de terreno y rocas del glb (planas, por debajo de cero) y la casa se apoya en y=0, y el colocador de árboles (`_arbolado`) ya no planta sobre las calles de la ciudad grande ni sobre las del núcleo (`_vias`) — el fallo era general, la orla de cada parcela caía justo sobre las calles de acceso. Primera pasada (con rocas y árbol): [aérea](capturas_ciudad_c2/casa_ribera_aerea_intermedio.jpg) · [pie](capturas_ciudad_c2/casa_ribera_pie_intermedio.jpg).
  sobresale de la parcela (se ve en la aérea), y en la toma a pie del sur la tapa un árbol.
- **Gasolinera (P0-3).** `CiudadGasolinera` (`visor/ciudad_gasolinera.gd`): marquesina con faldón rojo, banda luminosa y cuatro pilares; islas de hormigón con bordillo rojo bajo los surtidores (que siguen siendo los de `RedesCiudad`, con su «Repostar»: no se tocan); tienda al fondo con `FachadaModular`; poste de precios en la esquina. Antes:
  [aérea](capturas_ciudad_c2/gasolinera_aerea_antes.jpg) · [pie](capturas_ciudad_c2/gasolinera_pie_antes.jpg); después: [aérea](capturas_ciudad_c2/gasolinera_aerea_despues.jpg) · [pie](capturas_ciudad_c2/gasolinera_pie_despues.jpg). Pendiente: el cartel de precios no se lee desde la aérea (solo el rótulo), el solar no tiene vallas ni conos, y no hay coches repostando.
- **Plaza Mayor (P1-7).** `CiudadPlaza` (`visor/ciudad_plaza.gd`): anillo de bancos alrededor de la fuente, ocho farolas, seis puestos de mercado a los lados (`montana_rusa/stall-*`), soportales al norte con la fachada modular de dos plantas (cafés) y terrazas con sombrilla delante. Antes:
  [aérea](capturas_ciudad_c2/plaza_mayor_aerea_antes.jpg) · [pie](capturas_ciudad_c2/plaza_mayor_pie_antes.jpg); después: [aérea](capturas_ciudad_c2/plaza_mayor_aerea_despues.jpg) · [pie](capturas_ciudad_c2/plaza_mayor_pie_despues.jpg). Pendiente: gente sentada en las terrazas y los bancos, mobiliario de los soportales y que la valla del club no tape la esquina.
- **Manzanas industriales (P2-9, parte).** `CiudadIndustrial` (`visor/ciudad_industrial.gd`): dos naves más, silos, torre de agua y cisterna, camiones, cajas y valla (hash de la posición: no toca el azar de `_rng`). Antes: [aérea](capturas_ciudad_c2/barrio_oeste_industrial_aerea_antes.jpg) · [pie](capturas_ciudad_c2/barrio_oeste_industrial_pie_antes.jpg);
  después: [aérea](capturas_ciudad_c2/barrio_oeste_industrial_aerea_despues.jpg) · [pie](capturas_ciudad_c2/barrio_oeste_industrial_pie_despues.jpg). Pendiente: el desguace, las cocheras y el resto de barrios.
- **Bomberos, cocheras y desguace (P2-9 y P2-10, parte).** `CiudadServicios` (`visor/ciudad_servicios.gd`): dos camiones de bomberos y una ambulancia ante los portones; cuatro portones con marco amarillo en la nave de las cocheras y valla; desguace con valla, doce coches siniestrados (algunos apilados y escorados) y montones de neumáticos. No consume `_rng` (no usa `_kit`). Antes y después:
  [bomberos](capturas_ciudad_c2/bomberos_aerea_antes.jpg) → [aérea](capturas_ciudad_c2/bomberos_aerea_despues.jpg) · [cercana](capturas_ciudad_c2/bomberos_cercana_despues.jpg);
  [cocheras](capturas_ciudad_c2/cocheras_aerea_antes.jpg) → [aérea](capturas_ciudad_c2/cocheras_aerea_despues.jpg) · [pie](capturas_ciudad_c2/cocheras_pie_despues.jpg);
  [desguace](capturas_ciudad_c2/desguace_aerea_antes.jpg) → [aérea](capturas_ciudad_c2/desguace_aerea_despues.jpg) · [pie](capturas_ciudad_c2/desguace_pie_despues.jpg). Pendiente: la fachada de bomberos sigue siendo una caja roja con portones blancos (plantilla de fachada P1-5); la toma a pie del sur sale de espaldas a veces (la cámara de `f6c` con DIST>0): se usa la aérea cercana (`ALTO`, `DISTA`).
- **Suelo de las explanadas (causa común).** En gasolinera, desguace y cocheras el suelo brillaba como agua (manchas blancas y azules). Causa: `Texturas.hormigon` (material `solar` de las explanadas) multiplicaba la rugosidad por ruido crudo de 0 a 1 y las manchas oscuras bajaban a ~0,05 (espejo con el sol). Arreglo en el origen: el ruido de rugosidad se remapea a 0,86-1 (`_ruido_claro`) y baja `metallic_specular`; vale para todo el hormigón del juego (también el del estadio, que ganaba el mismo brillo). Después: [desguace pie](capturas_ciudad_c2/desguace_pie_suelo_mate.jpg) · [aérea](capturas_ciudad_c2/desguace_aerea_suelo_mate.jpg) (antes: [pie](capturas_ciudad_c2/desguace_pie_despues.jpg)).
- **Mercado (P2-8).** `CiudadMercado` (`visor/ciudad_mercado.gd`): fachada modular con marquesina en la nave, hilera de seis puestos (`montana_rusa/stall-*`) delante y cuatro a los lados, cajas de fruta apiladas y barriles. Antes: [aérea](capturas_ciudad_c2/mercado_aerea_antes.jpg) · [pie](capturas_ciudad_c2/mercado_pie_antes.jpg); después: [aérea](capturas_ciudad_c2/mercado_aerea_despues.jpg) · [pie](capturas_ciudad_c2/mercado_pie_despues.jpg). Pendiente: gente comprando, la bóveda verde sigue lisa y la entrada no se lee como puerta.
- **Parque solar (recursos sin usar, periferia este).** `CiudadSolar` (`visor/ciudad_solar.gd`) sobre la celda (9, 3), que era un campo de cajas baratas: 32 mesas de paneles del kit industrial (`solar-panel-landscape-group`), subestación, dos molinos (`windmill-low`), camino de servicio y valla; registrada como la feria (`_lejanos` + `_sin_lejano`) para no mover el azar de nada más. Después: [aérea](capturas_ciudad_c2/parque_solar_aerea_despues.jpg). Pendiente: la toma a pie queda tapada por la valla (poner una puerta) y el campo no tiene rótulo.
- **Centro comercial (P1-4, parte) y plantilla de fachada (P1-5, primera pieza).** `FachadaModular` (`visor/fachada_modular.gd`) viste una cara con piezas de
  `edificios_modulares`: escaparates en planta baja, entrada de tres módulos con marquesina, tres pisos de ventanas y cornisa; se reutiliza en los demás singulares
  (`FachadaModular.montar(ex, x, z_frente, y0, ancho, pisos)`). Las recreativas de peluches pasan de 7 en fila a 3 junto a la puerta. Antes:
  [aérea](capturas_ciudad_c2/centro_comercial_aerea_antes.jpg) · [pie](capturas_ciudad_c2/centro_comercial_pie_antes.jpg); después:
  [aérea](capturas_ciudad_c2/centro_comercial_aerea_despues.jpg) · [pie](capturas_ciudad_c2/centro_comercial_pie_despues.jpg). Pendiente del centro comercial: rótulo
  sobre la fachada, aparcamiento con plazas y farolas, las puertas no se leen como puertas (solo ventanales) y las otras tres caras siguen lisas.
