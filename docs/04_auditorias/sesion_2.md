# Sesión 2: TODA LA INTERFAZ (25-10-2026)

Rama: `ccr-76d707c5-dwse9h-s2`. Encargo: `docs/01_metodo/sesiones/sesion_2.md`.

A mitad del trabajo, la sesión principal amplió el alcance por decisión del dueño. Esta sesión pasó a ser «toda la interfaz»: además de sus 4 paquetes (uipl, uifi, uico, uite) asumió los 4 de `sesion_3.md` (uiaj, uitm, uiid, trad). Se hizo en dos tandas de 4 subagentes. El límite de uso cortó dos veces a los subagentes; se reanudaron desde donde iban, sin perder trabajo, y se hizo un commit WIP cada ~40 min.

## Resultado del cierre

| Comprobación | Resultado |
|---|---|
| `herramientas/banco.sh` | **FIN. 0 fallos** |
| `herramientas/ideas.sh todo` | **16/16 pruebas de la sesión en 0 fallos** |
| `herramientas/especiales.sh todo` | 7 OK, 1 FALLO: «norma de 450 líneas», solo por `pruebas/banco_p25.gd` (497 líneas) |
| `herramientas/revisar_lineas.py` | Solo se pasa `pruebas/banco_p25.gd` |

`banco_p25.gd` ya tenía 497 líneas en la base (88b07609) y el banco está reservado, así que no se tocó. Hay que partirlo: queda para quien lleve el banco.

- **Revisión del jefe:** todos los archivos cambiados están en las zonas de la sesión. En las pruebas nuevas no hay tautologías.
- **Comprobación de las pruebas clave:** se verificó que fallan con el código viejo: `uifi_asuntos` (el código viejo pide 1364 px), `uite_movil_textos` (marca «Tribuna»), `uitm_lenguaje` (aviso) y `uiid_identidad` (editor).

## Qué hizo cada paquete

### uipl: plantel, ficha y cantera

**Plantel** (`panel_plantel.gd`):
- Línea de resumen: jugadores, media, edad media y no disponibles.
- Filtros por línea con su número de jugadores; el filtro sobrevive al reordenar.
- Cabeceras traducidas con ayuda; las de números van a la derecha.
- La columna de la media dice «MEDIA», no «MED» (chocaba con la sigla de centrocampistas).
- El nombre se queda el espacio sobrante. Antes los apellidos se cortaban incluso a 1920 y VALOR quedaba oculto a 1280.
- Leyenda de iconos y estados vacíos (plantel vacío y línea sin jugadores).

**Ficha** (`ficha_jugador_info/acciones.gd`):
- Todo pasa por `Idiomas.t`. La biografía se traduce frase a frase.
- Rótulo y valor alineados, con «…» y ayuda con el texto entero.
- **Regla del dueño:** `perfil_humano()` ya no inventa vida personal (religión, paternidad, duelos) para jugadores reales del pack real.

**Cantera:**
- El nombre de cada canterano abre su ficha.
- «Listos para debutar» son botones.
- Hay mensaje cuando no hay canteranos.
- Origen, mapa del talento y categorías, traducidos.

**Comprobación:** `uipl_plantel` y `uipl_textos` (esta daba 30 fallos antes de los arreglos); mini_banco gestion y textos en 0.

**Hallazgo de uipl, arreglado por el jefe:** con 7 asuntos o más, la fila de asuntos del despacho (`pantalla_despacho_p1.gd`) pedía ~1300 px. Desbordaba la pantalla ENTERA por la derecha, a 1280 y a 1920. Ahora es un `HFlowContainer` que salta de línea. La prueba `uifi_asuntos` abre 8 asuntos reales y comprueba que caben en 1280; con el código viejo pedía 1364 px y fallaba. La captura de cierre con la cámara real confirma el arreglo.

### uifi: finanzas, despacho y mercado

**Mercado:**
- **Fallo real:** gastaba el azar determinista de la partida (`Azar.ent` en `_objetivos()`). Bastaba mirar la pestaña o teclear en el buscador para que la misma semilla diera otra liga. Ahora usa su propio generador sembrado y la lista es estable durante la semana.
- **Fallo real:** filtrar borraba la mesa de negociación.
- La tabla de objetivos desbordaba a 1280. Ahora recorta con «…» y alinea las cifras a la derecha.

**Negociación con respuesta visible:**
- Tarjeta coloreada con la respuesta del club, por ejemplo «Faltan unos 960k EUR… Prefieren una cifra fija mayor».
- Barra «Cubre lo que piden» que se mueve con cada «+» y «−».
- Paciencia del club y del jugador.
- Con mando, el foco se conserva tras cada «+».

**Finanzas:**
- Gráfico del flujo de caja a 12 meses (`GraficoFinanzas`).
- Barra apilada de activo frente a pasivo.
- «(hoy)» en vez de «mes 0».
- Tabla de bancos alineada.

**Mesa del representante:**
- Desenlace en verde, rojo o neutro, con sonido.
- Foco dorado visible.

**Comprobación:** `uifi_gestion` (28 comprobaciones) y `uifi_asuntos`.

### uico: competición, gente, legado y periódico

**Zonas de la tabla:**
- Salen de las reglas del cierre de temporada (descenso, ascenso, promoción, `Continental.plazas()`), no «a ojo». En Chile bajan 2.
- Cada fila lleva barra de color y hay una leyenda «Si la liga terminara hoy».

**Ficha de competición rehecha:**
- Columnas fijas y rayado alterno; el club propio con fondo y borde.
- Copas nacionales y continentales: grupos, rondas, penales.
- Con mando, L1/R1 cambian de competición; antes cambiaban la pestaña de detrás.

**Otras mejoras:**
- **Siglas:** en inglés salía «P G E P»; ahora «P W D L».
- **Portada del periódico:** ni Esc ni B la cerraban; ahora sí. Botones centrados y tabla del pie alineada.

**Fallo real en Legado:** el examen de licencia y el botón de minijuegos se añadían a otra pestaña y desaparecían al repintar. Era el único acceso al examen. Ahora están en Legado → Carrera profesional.

**Comprobación:** `uico_competicion` (descenso, ascenso, promoción, alineación al píxel, cabe en 1280) y `uico_textos`.

### uite: teléfono, vida y redes

**Móvil:**
- Navegación con Esc/B paso a paso; el foco pasa al móvil y no se queda en la pantalla de detrás.
- Animación al abrir y al guardar, y fundido por app; con «Animaciones reducidas» todo es instantáneo.
- Aviso en píldora con filo rojo o dorado.

**Textos:**
- La red social Tribuna y el móvil, traducidos.
- Mi vida: los medidores se traducen antes de pasarlos a mayúsculas (antes salía «ESTRÉS» en inglés).
- Hechas las 3 traducciones pendientes: ocio, maestro/pupilo y postura del gobierno.

**Casa:** Esc sale de la casa 3D.

**Comprobación:** `uite_movil_textos` (daba 9 fallos antes), `uite_traducciones` y `uite_movil_navegacion`.

**Añadido del jefe al cierre:** trad tradujo «Tribuna» (la del estadio) como «Stand». El nombre de la app del móvil se marca como nombre propio y no se traduce. La prueba comprueba las dos cosas.

### uiaj: ajustes, controles y accesibilidad

- **Mando sin redibujos inútiles:** `DibujoMando` y `MandoGiratorio` usan setters con `queue_redraw` o una bandera. El SubViewport pasa a renderizarse una vez (`UPDATE_ONCE`). Con el mando quieto no hay ningún repintado (probado).
- **Etiquetas del mando 3D:** van en una capa encima, con placa oscura detrás; antes el mando las tapaba. Algunas largas aún salen recortadas con «…» («Estadísticas del…», «Táctica rápida: …»), aunque se leen.
- **Ajustes de vídeo:** vista previa y «¿Mantener?»; si nadie contesta, se deshace solo a los 12 s.
- **Pantalla de accesibilidad nueva:**
  - muestra del tamaño del texto;
  - muestra de la paleta para daltonismo;
  - vibración Normal / Suave / Sin vibración, con botón «Probar»;
  - nota honesta: no hay subtítulos porque el juego no tiene voces.
- **Pausa del DT usable con mando:** antes no había foco en ningún botón. Ahora hay foco, ayuda, «cambios: N de 5» y una marca de cansancio que no depende del color.
- **Teclas con nombre legible:** `Mando.nombre_tecla()` (↑←↓→, «Esc»).

**Comprobación:** `uiaj_mando` y `uiaj_ajustes`.

### uitm: lenguaje visual común

**`Tema`:** accesibilidad que por defecto deja todo igual: `daltonico`, `escala_texto`, `Tema.letra()`, `Tema.accesible()` y la paleta Okabe-Ito. Se aplica en `Tema.etiqueta` y `Tema.rotulo`.

**`Aviso`:**
- **Fallo real:** la salida corría a la vez que la espera. El aviso entraba y se iba en ~0,9 s y casi no se leía.
- **Fallo real:** si el padre se liberaba a media animación, la cola de avisos se quedaba muda para siempre.
- Con el ratón encima se vuelve casi transparente, para no tapar lo de debajo.

**Otros:**
- El menú lateral se traduce y el cajón queda por encima del consejo del presidente.
- En los diálogos, el foco lleva borde dorado de 2 px.
- `BotonFx` marca el foco que llega por teclado o mando.

**Comprobación:** `uitm_lenguaje` (con el código anterior, el aviso ya se iba a los 0,45 s).

### uiid: identidad, editor, diseñador del estadio y ciudad 2D

- **Miniaturas:** las rejillas de forma, patrón y estampado muestran el escudo o la camiseta del club con esa opción (104 miniaturas). Antes eran claves crudas como «banda_cinta».
- **Escudo:** se ve en color y en una tinta (`Escudo.textura_mono`), con iniciales.
- **Camisetas:** salen grandes y con su nombre.
- **Cachés acotadas:** cada paso del selector de color dejaba en memoria escudos nuevos sin límite.
- **Editor:**
  - **Fallo real:** barba, nariz, pecas, lunar y cicatriz no repintaban la cara.
  - Desplegables con letra normal (antes ~20 px) y nombres legibles con ayuda.
- **Diseñador del estadio:** sin barra horizontal a 1280.

**Comprobación:** `uiid_identidad` y `uiid_textos`. Al cierre, el jefe acotó un falso positivo de `uiid_textos`: el nombre ficticio de un patrocinador, «Lácteos del Sur», se tomaba por castellano.

### trad: traducciones

Textos vistos con pinta de castellano y sin traducir, antes → después:

| en | fr | de | tr | pl | it | pt | ca |
|---|---|---|---|---|---|---|---|
| 330→120 | 334→121 | 335→122 | 334→121 | 334→121 | 340→130 | 387→201 | 380→176 |

**Qué queda:**
- Casi todo son nombres propios.
- También las abreviaturas de posición (POR, DFC…): son una convención de todo el juego y no se tocaron.
- En pt, ca e it la cifra es más alta por falsos positivos: palabras que se escriben igual que en castellano.

**Parche:** unas 500 frases y 200 patrones.
- Los marcadores `%s`/`%d` van en el mismo orden en los 8 idiomas (comprobado).
- Los patrones se acotaron para no tragarse la oración siguiente.

**Código:** `nucleo/contratos.gd` (`tipo()` y `texto_jornada()`).

**Comprobación:** `trad_textos`.

**Añadidos del jefe en zonas de la sesión:**
- `mesa_agente_ui`: la frase del representante se traduce.
- `pantalla_despacho`: el perfil del periodista se traduce.
- Cantera: «(%d caps)», un anglicismo en la interfaz castellana, pasa a «(%d partidos con la selección)», con singular.
- Patrón turco «Tu club va N.º de M»: tenía `$1` y `$2` cruzados.

## Traducciones: cómo reaplicarlas al unir ramas

- **Parches:** `dinastia-godot/datos/trad_parches/s2_{uipl,uifi,uico,uite,uiaj,uitm,uiid,trad,jefe}.json`. Se aplican con `herramientas/sumar_traducciones.py`. Se quitaron de `s2_trad.json` las claves que otro parche s2 ya definía con otro valor, para que el resultado no dependa del orden.
- **`s2_sobrescrituras.json`:** valores que la sesión **sobrescribió** sobre la base, y que `sumar_traducciones.py` no pisaría: «Tribuna»→«Stand»… en 8 idiomas y el patrón turco corregido. Hay que aplicarlo con un script que tome `/tmp/idiomas.lock` y guarde con `json.dumps(ensure_ascii=False, indent=1)`.
- **Ojo:** «Tribuna» como nombre de la app del móvil se protege en `telefono*` con la meta `marca_sin_traducir`.

## Capturas (Forward+, cámara real; en `capturas_sesion_2/`, 960 px)

| Archivo | Qué se ve |
|---|---|
| `s2_mercado_negociacion.jpg` | Mesa de negociación a 1280: tarjeta «Contraoferta del club», barra «Cubre lo que piden» al 70 %, paciencia, cifras en columna. |
| `s2_competicion_zonas_en.jpg` | Ficha de liga en inglés a 1920: P W D L, club propio resaltado, barras de zona (campeón, continentales, 2 descensos), leyenda y últimos resultados. |
| `s2_controles_mando.jpg` | Controles de Xbox a 1280: etiquetas con placa sobre el mando y tabla que cabe. Siguen recortadas con «…» algunas etiquetas largas y «Space» sin traducir (petición 4). |
| `s2_escudo_miniaturas.jpg` | Identidad: escudo en color y en una tinta, rejilla de formas con miniaturas reales. |
| `s2_movil_tribuna_en.jpg` | Móvil en inglés a 1280: publicación, «Back him / With humour / Curt», comentarios traducidos, aviso en píldora. |
| `s2_plantel_asuntos.jpg` | Captura de CIERRE a 1280 con 7 asuntos: la fila salta de línea y la pantalla cabe. También se ven el resumen y los filtros del plantel. Defecto ajeno visible: las caras salen como cuadros negros. |

Las capturas antes/después completas de cada paquete (unas 80) quedaron en `/tmp/capturas/<paquete>/` del contenedor y no se suben.

## Defectos que siguen a la vista

- Las caras de la ficha y del plantel salen como cuadros negros en las capturas (`ui/cara`, retrato 3D).
- Las etiquetas del radar se cortan a 4 letras («Esti», «Colo»): `principal_p8` usa `.left(4)`.
- Con un club negro (Lautaro), las miniaturas de forma tienen poco contraste, y su escudo apenas se ve sobre fondo oscuro.
- El flujo de caja sale casi como una rampa: el núcleo reparte el resultado del año en 12 partes iguales.
- Las cifras de finanzas quedan pegadas a la barra de desplazamiento (ya pasaba antes).
- Récords: «RACHAS» sale a 0 en partidos simulados. Parece que `logros.rachas` solo cuenta los partidos dirigidos.

## Peticiones a otras zonas (la sesión principal ya tiene la lista; dijo que toma 1, 3, 4 y 6)

1. **`ui/principal.gd:5` `_input`:** con el móvil u otra capa encima abierta, L1/R1, L2/R2 y Ctrl+Q/E cambian la pestaña de detrás. Debería ignorarlos.
2. **`nucleo/idiomas.gd` `_t`:** no separa el icono inicial cuando el texto tiene varias oraciones. El móvil lo esquiva con `_t_icono`.
3. **Volcar los ajustes de accesibilidad en `Tema`** (código exacto de uitm):
   - en `ui/principal_p10.gd`, tras la línea 50: `Tema.escala_texto = _escala_texto` y `Tema.daltonico = _daltonico`;
   - en `ui/principal_p2.gd`, líneas 363 y 373: setters que hagan lo mismo.

   Sin esto, el daltonismo y el tamaño de letra no llegan a lo que se pinta con `Tema.*`.
4. **`visor/control_fc.gd:232`:** usar `Mando.nombre_tecla(ts[0])`; hoy sale «Space».
5. **`ui/principal_p8.gd`, final de `_ver_ficha()`:** añadir `_traducir_pantalla(_ficha)`. Al pulsar un jugador, la ficha queda en castellano hasta la semana siguiente. Además, el radar usa `.left(4)`.
6. **Principal:** la barra de desplazamiento de las columnas tapa el final de los valores de `_dato` (por ejemplo, «Rol actual» en Legado).
7. **Textos fijos del núcleo:** Negociación (`prefiere`/`motivo`), MesaAgente y Movil devuelven castellano fijo. La interfaz los traduce cuando hay clave; lo correcto serían claves estables.
8. **Rueda de prensa 2D:** está en `ui/principal_p17.gd` (`_abrir_rueda_pantalla_completa`), zona prohibida. No se ha pulido.
9. **Identidad en `ui/principal.gd:114-163`:** la vista previa del escudo no lleva iniciales (usar `_escudo(c, 54)`) y la muestra del color de acento es un rectángulo blanco grande. En `principal_p4.gd:157`, las iniciales deberían usar `c.color_escudo1()`.
10. **`ui/componentes/mentor_voz.gd`:** el consejo del presidente tapa la tabla 9 s. Propuesta: fundido con el ratón encima o `DURA` de ~6 s.
11. **`ui/pantallas/pantalla_opciones_p1.gd:244`:** distingue el error de la ciudad por la longitud del texto (`r.length() > 40`), así que «ya tienes peñas en todas partes» se toma como ciudad fundada. Es un fallo de lógica.
12. **Tildes:**
    - `principal_p2.gd:328`: «cabe mas» → «cabe más»;
    - `nucleo/prensa_p4_p1.gd:35`: «mas corta» → «más corta».
13. **Registro de `principal_p13:226`:** se escribe antes de cargar el idioma, así que «Mundo nuevo. Semilla» sale en castellano.
14. **`pruebas/banco_p25.gd`:** 497 líneas, más de 450.

## Para el dueño

- **`bio_de()` (nucleo/datos)** inventa la edad de debut y el origen de los jugadores reales. Ya no se inventa su vida personal, pero esto otro sigue. Decide si debe tratarse igual.
- **«Forma»** se usa para la forma del escudo y para la forma física del jugador, con una sola traducción («Form»). Hace falta separarlas en dos claves.
- **Capturas lentas:** sin GPU (lavapipe) las capturas son lentas. El FPS real sigue pendiente en hardware del dueño.
