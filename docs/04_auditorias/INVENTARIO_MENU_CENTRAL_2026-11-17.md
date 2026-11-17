# INVENTARIO DEL MENÚ CENTRAL (17-11-2026)

Generado con `dinastia-godot/herramientas/inventario_menu_central.py` (lee `MenusLaterales.MENUS`, `TableroInicio.EQUIPO/CLUB`); la prueba `_probar_conexion_menu_central` (banco, grupo `menus`) y `pruebas/probar_conexion_menu_central.gd` (especiales.sh, xvfb) la hacen cumplir.

Todo submenú sale en la pestaña **Índice** (cuarta pestaña del menú central: cada menú del panel lateral con TODOS sus submenús como botones, leídos de `MenusLaterales.MENUS`) y, además, por el «☰» de la barra, L2/R2 y los atajos de teclado. La columna «Entrada directa» dice si ADEMÁS tiene tarjeta o botón propio.

## 1. Submenús del panel lateral (96 en 14 menús)

| Menú | Submenú | Destino (pestaña · sección / acción) | Entrada directa en el menú nuevo | Índice | ≡ |
|---|---|---|---|---|---|
| Plantel | Mi plantel | Mi plantel | Dirección del equipo > tarjeta «Mi plantel» | sí | sí |
| Plantel | Plantilla detallada | acción `plantilla_pes` | — | sí | sí |
| Plantel | Pizarra y dibujo | Táctica · pizarra | Dirección del equipo > tarjeta | sí | sí |
| Plantel | Órdenes de juego | Táctica · ordenes | — | sí | sí |
| Plantel | Balón parado y normas | Táctica · balon | — | sí | sí |
| Plantel | El once | Táctica · once | — | sí | sí |
| Plantel | Entrenamiento | Entrenar · semana | Dirección del equipo > tarjeta | sí | sí |
| Plantel | Pretemporada y horarios | Entrenar · pretemporada | — | sí | sí |
| Plantel | Desarrollo individual | Entrenar · desarrollo | — | sí | sí |
| Plantel | Enfermería | Enfermería | Dirección del equipo > tarjeta | sí | sí |
| Plantel | Academia | Cantera · academia | Dirección del equipo > tarjeta | sí | sí |
| Plantel | Juveniles | Cantera · juveniles | — | sí | sí |
| Plantel | Leyendas y linaje | Cantera · linaje | — | sí | sí |
| Plantel | Contratos | Contratos | Dirección del equipo > tarjeta | sí | sí |
| Partido | Próximo partido | Partido · previa | — | sí | sí |
| Partido | Informe y apuestas | Partido · informe | — | sí | sí |
| Partido | Los onces | Partido · onces | — | sí | sí |
| Partido | Calendario | Calendario | Inicio > tarjeta «Calendario» | sí | sí |
| Partido | Táctica | Táctica · pizarra | — | sí | sí |
| Partido | Elegir el once | Táctica · once | — | sí | sí |
| Dinero | Cuentas del club | Finanzas · cuentas | — | sí | sí |
| Dinero | Taquilla y tienda | Finanzas · taquilla | — | sí | sí |
| Dinero | Patrocinadores | Finanzas · patrocinio | Información del club > tarjeta | sí | sí |
| Dinero | Explotación comercial | Gente · comercial | — | sí | sí |
| Dinero | Banco y deuda | Finanzas · banco | — | sí | sí |
| Dinero | Libro de movimientos | Finanzas · libro | — | sí | sí |
| Dinero | Mercado de fichajes | Mercado | Dirección del equipo > tarjeta | sí | sí |
| Dinero | Jugadores libres | Libres | — | sí | sí |
| Competiciones | Ligas y clubes | Clubes · tablas | Información del club > tarjeta; Inicio > tabla de posiciones; Base de datos | sí | sí |
| Competiciones | Goleadores | Clubes · goleadores | — | sí | sí |
| Competiciones | Clásicos y rivales | Clubes · rivales | — | sí | sí |
| Competiciones | Copa | Copa | — | sí | sí |
| Competiciones | Continental | Continental | — | sí | sí |
| Competiciones | Selección | Selección | — | sí | sí |
| Competiciones | Ver otro club | acción `elegir_club` | — | sí | sí |
| Competiciones | Palmarés del mundo | acción `palmares_mundo` | — | sí | sí |
| Historia | Historia del club | Legado · club | Información del club > tarjeta | sí | sí |
| Historia | Tu carrera de entrenador | Legado · carrera | — | sí | sí |
| Historia | Retiro y sucesión | Legado · retiro | — | sí | sí |
| Historia | Documental de la temporada | acción `documental` | — | sí | sí |
| Historia | Capítulos de cada temporada | acción `capitulos` | — | sí | sí |
| Historia | Récords | Récords · records | Información del club > tarjeta | sí | sí |
| Historia | Memoria | Récords · memoria | — | sí | sí |
| Historia | Rivales | Récords · rivales | — | sí | sí |
| Historia | Vitrina | Récords · vitrina | — | sí | sí |
| Historia | Linaje | Cantera · linaje | — | sí | sí |
| Historia | Logros | Logros | — | sí | sí |
| Historia | Desafíos | Desafíos | — | sí | sí |
| Historia | Premios | Premios | — | sí | sí |
| Historia | Álbum y museo | acción `album` | — | sí | sí |
| Gente | Personal del club | Club · staff | Dirección del equipo > tarjeta | sí | sí |
| Gente | La gente del club | Gente · personas | — | sí | sí |
| Gente | Identidad visual | Gente · identidad | — | sí | sí |
| Gente | Equipación | Gente · kits | — | sí | sí |
| Gente | El club por dentro | Gente · interno | — | sí | sí |
| Gente | App, web y detalles del club | Gente · digital | — | sí | sí |
| Gente | Camarín | Camarín · clima | Dirección del equipo > tarjeta | sí | sí |
| Gente | Clanes y jerarquía | Camarín · grupos | — | sí | sí |
| Gente | Salud mental | Camarín · salud | — | sí | sí |
| Mi Carrera | Mi carrera | Club · carrera | Barra > «Oficina del DT» y tarjeta del DT (Inicio) | sí | sí |
| Mi Carrera | Directorio y consejeros | Club · directorio | — | sí | sí |
| Mi Carrera | Árbol de habilidades | Habilidades | — | sí | sí |
| Mi Carrera | Correo | Correo | Pie > «Mensajes» y tarjeta «Noticias y correo» (Inicio) | sí | sí |
| Mi Carrera | Normas y federación | Federación · reglamento | — | sí | sí |
| Operaciones | Hinchada y socios | Estadio · hinchada | Información del club > tarjeta; Inicio > «Hinchada y socios» | sí | sí |
| Operaciones | Feed de redes | Redes · redes | — | sí | sí |
| Operaciones | Sala de prensa | Redes · prensa | — | sí | sí |
| Operaciones | El ruido de fuera | Redes · debate | — | sí | sí |
| Operaciones | Comparar | Comparar | — | sí | sí |
| Mi Vida | Bienestar | Vida · bienestar | — | sí | sí |
| Mi Vida | Casa y auto | Vida · hogar | — | sí | sí |
| Mi Vida | Familia | Vida · familia | — | sí | sí |
| Mi Vida | Ver tu casa | acción `casa` | — | sí | sí |
| Mi Vida | Abrir el móvil | acción `movil` | — | sí | sí |
| Mi Vida | Minijuegos | acción `minijuegos` | — | sí | sí |
| Editar | Editor del mundo | Editor | — | sí | sí |
| Editar | Mi personaje | acción `mi_personaje` | — | sí | sí |
| Editar | Identidad visual | Gente · identidad | — | sí | sí |
| Editar | Equipación | Gente · kits | — | sí | sí |
| Editar | Diseño del estadio | Estadio · diseno | Información del club > tarjeta | sí | sí |
| Editar | Decorar mi casa | acción `casa` | — | sí | sí |
| Reglas | Glosario | Glosario | Pie > «Ayuda» | sí | sí |
| Reglas | Reglamento de la liga | Federación · reglamento | — | sí | sí |
| Reglas | Licencia y tribunal | Federación · licencia | — | sí | sí |
| Reglas | Asamblea y gobierno | Federación · asamblea | — | sí | sí |
| Ajustes | Dispositivo | Ajustes · pantalla | — | sí | sí |
| Ajustes | Sonido | Ajustes · audio | — | sí | sí |
| Ajustes | Interfaz | Ajustes · aspecto | — | sí | sí |
| Ajustes | Juego | Ajustes · juego | — | sí | sí |
| Ajustes | Accesibilidad | Ajustes · acceso | — | sí | sí |
| Ajustes | Partida y guardado | Ajustes · partida | — | sí | sí |
| Ciudad 3D | Diseño de la ciudad | Ciudad | — | sí | sí |
| Ciudad 3D | Entrar al estadio | acción `ver_estadio` | — | sí | sí |
| Estadio 3D | Diseño del estadio | Estadio · diseno | Información del club > tarjeta | sí | sí |
| Estadio 3D | Infraestructura | Club · infra | — | sí | sí |
| Estadio 3D | Verlo en 3D | acción `ver_estadio` | — | sí | sí |

Submenús sin tarjeta propia (se alcanzan por el Índice, el «☰», L2/R2 y atajos): **76 de 96**. Ninguno queda «SIN ENTRADA».

## 2. Accesorios del menú anterior

| Accesorio | Dónde estaba (menú anterior) | Por dónde se llega AHORA | Qué abre de verdad |
|---|---|---|---|
| Campana roja de avisos (`CampanasMenu`) | Tarjetas y pestañas del mosaico | Igual: `TableroInicio.tarjeta` la pone en cada tarjeta y `marcar_pestana` en las pestañas | La zona del aviso (avance por días) |
| Buscador global | Cabecera, siempre a la vista | Barra > «Base de datos» (cuadro con el buscador y puerta a «Ligas y clubes»); Índice > Accesos; tecla F3 | Ficha del jugador o del club |
| Botones Avanzar / Jugar / Saltar / Partido jugado / Temporada | Fila de la raíz | Pie del escaparate (los mismos `BotonesAvance`); pulsar de nuevo la pestaña «Avanzar en el tiempo» abre «Avanzar 1 día / Siguiente» | El avance por días y el partido |
| Selector (OptionButton de la raíz) | Fila de botones | Sigue en la raíz del menú anterior (oculta en PC mientras se ve el Inicio); su función (cambiar de club en modo libre) está en Ajustes > Partida y guardado | Ajustes |
| Despacho «🔔 N asuntos» (jugador que te busca, prensa, junta, cantera, personal, zona gris, crisis, casa) | `p._despacho` en la raíz | Inicio > tarjeta «Despacho» (alerta ámbar con N), pie > «● Despacho (N)», Índice > Accesos | Pantalla completa `EscaparatePanel` con `p._despacho` (misma lógica de `PantallaDespacho`) |
| Informe de la semana | Debajo del mosaico del Inicio | Información del club > tarjeta «Informe de la semana» (titular + contador); Índice > Accesos; sus avisos graves suman en «Mensajes» del pie | Pantalla completa `EscaparateInforme` (`InformeSemana.pintar_en`), cada aviso con botón a su pantalla |
| Mensajes y correo | Botón de la raíz | Pie > «Mensajes (N)» (sin leer + avisos graves); Inicio > tarjeta «Noticias y correo» | Submenú Correo |
| Ayuda y glosario | Botón de la raíz | Pie > «Ayuda»; Índice > Reglas > Glosario | Submenú Glosario |
| Accesos rápidos (favoritos de Ajustes) | Fila bajo el mosaico | Índice > Accesos (⭐ uno por favorito) | `_ir_a_pestana` de cada uno |
| Últimos resultados | Lista bajo el mosaico | Inicio > fila «Calendario» (primera tarjeta = último resultado); Calendario; Partido > Informe | Calendario / Récords |
| Línea de estado (`p._sub`: jornada, sueldos, media, objetivo, confianza) | Cabecera | Pie, en el hueco del medio (se recorta con «…») | Informativa |
| Objetivos «🎯 N» (`PanelObjetivos`) | Caja flotante | Pie > chip «🎯 N» | Despliega el panel de objetivos |
| Fecha y caja | Cabecera | Barra (caja pulsable → Cuentas del club); reloj del pie con Timer de 1 s | Cuentas del club |
| Escudo | Cabecera | Barra (pulsable → Identidad visual) | Identidad visual |
| Guardar / Cargar / otro mundo / ranuras | Ajustes | Barra > «Sistema»; Índice > Ajustes > Partida y guardado | Ajustes · partida |
| Atajos de teclado (`AtajosCentrales`) | Cualquier pantalla | Siguen activos (menú entero y cada submenú); L1/R1 recorren las 4 pestañas | Cada atajo |
| Tutorial (`Tutorial`, `CapaTutorial`) | Primera vez | Sin cambios (lo lanza `GuiaTutorial`) | Tarjetas de ayuda |
| Barra lateral izquierda (riel de iconos) | Siempre a la izquierda | Se oculta en el Inicio de PC; se conserva: «☰» de la barra (cajón completo), L2/R2 y atajos; se ve en cuanto se abre cualquier menú | Los 14 menús |

## 3. Pantallas perezosas (`Principal.PANTALLAS_PEREZOSAS`)

Las 12 (`club_vida`, `cantera`, `gente`, `finanzas`, `editor`, `identidad`, `plantel`, `ficha`, `despacho`, `legado`, `opciones`, `elegir_club`) se abren desde los submenús de la sección 1 (cada `tab` del panel lateral llama a `_abrir_perezosa`), así que están cubiertas por el Índice. La prueba `probar_conexion_menu_central` comprueba además que cada submenú abre su menú.

## 4. Al revés: cada tarjeta, pestaña y botón nuevo

| Elemento nuevo | Abre |
|---|---|
| Pestaña «Avanzar en el tiempo» | Inicio (DT, noticia, tabla, calendario, hinchada, despacho); re-pulsar = desplegable de avance |
| Pestañas «Dirección del equipo» e «Información del club» | Mosaico de 9 y 10 tarjetas: cada una abre su submenú (`TableroInicio.abrir` → `abrir_menu(id, i)`) |
| Pestaña «Índice» | Todos los submenús (`MenusLaterales.MENUS`) + accesos |
| Tarjeta «Oficina del DT» / atajo | Mi carrera |
| Tarjeta «Noticias y correo» | Correo |
| Tarjeta «Tabla de posiciones» | Ligas y clubes |
| Tarjeta «Calendario» | Calendario de semanas |
| Tarjeta «Hinchada y socios» | Hinchada y socios |
| Tarjeta «Despacho» | Pantalla completa del despacho |
| Tarjeta «Informe de la semana» | Pantalla completa del informe |
| Barra: ☰ | Cajón con todos los menús |
| Barra: Oficina del DT / Base de datos / Sistema | Mi carrera / buscador / Ajustes |
| Barra: escudo / caja | Identidad visual / Cuentas del club |
| Pie: Mensajes / Despacho / Ayuda / 🎯 / Avanzar… | Correo / despacho / Glosario / objetivos / botones de avance |

