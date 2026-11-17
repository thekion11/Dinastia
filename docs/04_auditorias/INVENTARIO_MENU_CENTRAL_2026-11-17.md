# INVENTARIO DEL MENÚ CENTRAL (17-11-2026)

Generado con `dinastia-godot/herramientas/inventario_menu_central.py` (lee `MenusLaterales.MENUS`, `TableroInicio.EQUIPO/CLUB`); la prueba `_probar_conexion_menu_central` (banco, grupo `menus`) y `pruebas/probar_conexion_menu_central.gd` (especiales.sh, xvfb) la hacen cumplir.

**Diseño aprobado por el dueño (17-11):** la barra lateral izquierda (los 14 iconos de `MenusLaterales.MENUS`, con su ☰, el cajón de submenús, L2/R2 y los atajos) está SIEMPRE visible, también en el Inicio; cada menú se abre en su portada (mosaico de tarjetas, una por submenú) y todos sus submenús siguen un clic más allá. La barra de arriba (color del club) NO repite esos menús: «Avanzar en el tiempo», «Despacho · N», «Mensajes · N», escudo (→ Identidad visual), «Oficina del DT», «Base de datos», «Sistema», la caja (→ Cuentas del club) y la fecha. La columna «Entrada directa» dice si el submenú tiene ADEMÁS una tarjeta o botón propio en el Inicio.

## 1. Submenús del panel lateral (95 en 14 menús)

| Menú | Submenú | Destino (pestaña · sección / acción) | Entrada directa desde el Inicio | Barra lateral |
|---|---|---|---|---|
| Plantel | Mi plantel | Mi plantel | — | sí |
| Plantel | Pizarra y dibujo | Táctica · pizarra | — | sí |
| Plantel | Órdenes de juego | Táctica · ordenes | — | sí |
| Plantel | Balón parado y normas | Táctica · balon | — | sí |
| Plantel | El once | Táctica · once | — | sí |
| Plantel | Entrenamiento | Entrenar · semana | — | sí |
| Plantel | Pretemporada y horarios | Entrenar · pretemporada | — | sí |
| Plantel | Desarrollo individual | Entrenar · desarrollo | — | sí |
| Plantel | Enfermería | Enfermería | — | sí |
| Plantel | Academia | Cantera · academia | — | sí |
| Plantel | Juveniles | Cantera · juveniles | — | sí |
| Plantel | Leyendas y linaje | Cantera · linaje | — | sí |
| Plantel | Contratos | Contratos | — | sí |
| Plantel | Plantilla detallada | acción `plantilla_pes` | — | sí |
| Partido | Próximo partido | Partido · previa | — | sí |
| Partido | Informe y apuestas | Partido · informe | — | sí |
| Partido | Los onces | Partido · onces | — | sí |
| Partido | Calendario | Calendario | Inicio > tarjeta «Calendario» | sí |
| Partido | Táctica | Táctica · pizarra | — | sí |
| Partido | Elegir el once | Táctica · once | — | sí |
| Dinero | Cuentas del club | Finanzas · cuentas | Barra > caja | sí |
| Dinero | Taquilla y tienda | Finanzas · taquilla | — | sí |
| Dinero | Patrocinadores | Finanzas · patrocinio | — | sí |
| Dinero | Explotación comercial | Gente · comercial | — | sí |
| Dinero | Banco y deuda | Finanzas · banco | — | sí |
| Dinero | Libro de movimientos | Finanzas · libro | — | sí |
| Dinero | Mercado de fichajes | Mercado | — | sí |
| Dinero | Jugadores libres | Libres | — | sí |
| Competiciones | Ligas y clubes | Clubes · tablas | Inicio > tabla de posiciones; barra > Base de datos | sí |
| Competiciones | Goleadores | Clubes · goleadores | — | sí |
| Competiciones | Clásicos y rivales | Clubes · rivales | — | sí |
| Competiciones | Copa | Copa | — | sí |
| Competiciones | Continental | Continental | — | sí |
| Competiciones | Selección | Selección | — | sí |
| Competiciones | Ver otro club | acción `elegir_club` | — | sí |
| Competiciones | Palmarés del mundo | acción `palmares_mundo` | — | sí |
| Historia | Historia del club | Legado · club | — | sí |
| Historia | Tu carrera de entrenador | Legado · carrera | — | sí |
| Historia | Retiro y sucesión | Legado · retiro | — | sí |
| Historia | Documental de la temporada | acción `documental` | — | sí |
| Historia | Capítulos de cada temporada | acción `capitulos` | — | sí |
| Historia | Récords | Récords · records | — | sí |
| Historia | Memoria | Récords · memoria | — | sí |
| Historia | Rivales | Récords · rivales | — | sí |
| Historia | Vitrina | Récords · vitrina | — | sí |
| Historia | Linaje | Cantera · linaje | — | sí |
| Historia | Logros | Logros | — | sí |
| Historia | Desafíos | Desafíos | — | sí |
| Historia | Premios | Premios | — | sí |
| Historia | Álbum y museo | acción `album` | — | sí |
| Gente | Personal del club | Club · staff | — | sí |
| Gente | La gente del club | Gente · personas | — | sí |
| Gente | Identidad visual | Gente · identidad | Barra > escudo | sí |
| Gente | Equipación | Gente · kits | — | sí |
| Gente | El club por dentro | Gente · interno | — | sí |
| Gente | App, web y detalles del club | Gente · digital | — | sí |
| Gente | Camarín | Camarín · clima | — | sí |
| Gente | Clanes y jerarquía | Camarín · grupos | — | sí |
| Gente | Salud mental | Camarín · salud | — | sí |
| Mi Carrera | Mi carrera | Club · carrera | Barra > «Oficina del DT» y tarjeta del DT (Inicio) | sí |
| Mi Carrera | Directorio y consejeros | Club · directorio | — | sí |
| Mi Carrera | Árbol de habilidades | Habilidades | — | sí |
| Mi Carrera | Correo | Correo | Pie > «Mensajes» y tarjeta «Noticias y correo» (Inicio) | sí |
| Mi Carrera | Normas y federación | Federación · reglamento | — | sí |
| Operaciones | Hinchada y socios | Estadio · hinchada | Inicio > tarjeta «Hinchada y socios» | sí |
| Operaciones | Feed de redes | Redes · redes | — | sí |
| Operaciones | Sala de prensa | Redes · prensa | — | sí |
| Operaciones | El ruido de fuera | Redes · debate | — | sí |
| Operaciones | Comparar | Comparar | — | sí |
| Mi Vida | Bienestar | Vida · bienestar | — | sí |
| Mi Vida | Casa y auto | Vida · hogar | — | sí |
| Mi Vida | Familia | Vida · familia | — | sí |
| Mi Vida | Ver tu casa | acción `casa` | — | sí |
| Mi Vida | Abrir el móvil | acción `movil` | — | sí |
| Mi Vida | Minijuegos | acción `minijuegos` | — | sí |
| Editar | Editor del mundo | Editor | — | sí |
| Editar | Mi personaje | acción `mi_personaje` | — | sí |
| Editar | Identidad visual | Gente · identidad | Barra > escudo | sí |
| Editar | Equipación | Gente · kits | — | sí |
| Editar | Diseño del estadio | Estadio · diseno | — | sí |
| Editar | Decorar mi casa | acción `casa` | — | sí |
| Reglas | Glosario | Glosario | Pie > «Ayuda» | sí |
| Reglas | Reglamento de la liga | Federación · reglamento | — | sí |
| Reglas | Licencia y tribunal | Federación · licencia | — | sí |
| Reglas | Asamblea y gobierno | Federación · asamblea | — | sí |
| Ciudad 3D | Diseño de la ciudad | Ciudad | — | sí |
| Ciudad 3D | Entrar al estadio | acción `ver_estadio` | — | sí |
| Estadio 3D | Diseño del estadio | Estadio · diseno | — | sí |
| Estadio 3D | Infraestructura | Club · infra | — | sí |
| Estadio 3D | Verlo en 3D | acción `ver_estadio` | — | sí |
| Ajustes | Dispositivo | Ajustes · pantalla | — | sí |
| Ajustes | Sonido | Ajustes · audio | — | sí |
| Ajustes | Interfaz | Ajustes · aspecto | — | sí |
| Ajustes | Juego | Ajustes · juego | — | sí |
| Ajustes | Accesibilidad | Ajustes · acceso | — | sí |

Submenús sin tarjeta propia en el Inicio (se alcanzan por la barra lateral siempre visible, L2/R2 y atajos): **86 de 95**. Ninguno queda «SIN ENTRADA».

## 2. Accesorios del menú anterior

| Accesorio | Dónde estaba (menú anterior) | Por dónde se llega AHORA | Qué abre de verdad |
|---|---|---|---|
| Barra lateral izquierda (riel de 14 iconos con Ajustes al final, ☰, cajón de submenús, L2/R2, atajos) | Siempre a la izquierda | SIEMPRE visible, también en el Inicio (`esconder_riel(false)`); en el PC de la oficina su «Entrar al club» se esconde | Los 14 menús y sus submenús |
| Campana roja de avisos (`CampanasMenu`) | Tarjetas y pestañas | `TableroInicio.tarjeta` la pone en cada tarjeta y `marcar_pestana` en la pestaña | La zona del aviso |
| Buscador global | Cabecera | Barra > «Base de datos» (cuadro con el buscador y puerta a «Ligas y clubes»); tecla F3 | Ficha del jugador o del club |
| Avanzar / Jugar / Saltar / Partido jugado / Temporada | Fila de la raíz | Pie del Inicio (los mismos `BotonesAvance`); re-pulsar «Avanzar en el tiempo» abre «Avanzar 1 día / Siguiente» | El avance por días y el partido |
| Despacho «🔔 N asuntos» | `p._despacho` en la raíz | Barra > «Despacho · N» (ámbar), Inicio > tarjeta «Despacho» (con N, o próximo hito y favoritos si no hay asuntos) | `EscaparatePanel` con `p._despacho` (misma lógica de `PantallaDespacho.asuntos_pendientes`) |
| Informe de la semana | Bajo el mosaico | Barra > «Mensajes · N» | `EscaparateInforme`: correo, noticias recientes e informe (`InformeSemana.pintar_en`), cada aviso con botón a su pantalla |
| Mensajes y correo | Botón de la raíz | Barra > «Mensajes · N» (sin leer + avisos graves) y tarjeta «Noticias y correo» | Submenú Correo |
| Ayuda y glosario | Botón de la raíz | Pie > «Ayuda»; barra lateral > Reglas > Glosario | Submenú Glosario |
| Accesos rápidos (favoritos de Ajustes) | Fila bajo el mosaico | Franja inferior del Inicio (⭐ uno por favorito; sin favoritos, los cuatro más usados) y despacho vacío | `_ir_a_pestana` |
| Últimos resultados | Lista bajo el mosaico | Fila «Calendario» (primera tarjeta = último resultado); Calendario | Calendario |
| Forma (últimos 5) | Tarjeta «Forma» | QUITADA del Inicio por orden del dueño (`EscaparateSubs._forma` queda en el código para Plantel o Competiciones: pendiente de colocar) | — |
| Línea de estado (`p._sub`) | Cabecera | QUITADA del Inicio por orden del dueño; sus datos están en el dato de las portadas: Mi carrera (objetivo y confianza), Cuentas del club (caja y sueldos), Mi plantel (media), Hinchada (socios), Ligas y clubes (jornada o «pretemporada») — `DatoTarjeta` | Informativa |
| Objetivos «🎯 N» | Caja flotante | Pie > chip «🎯 N» | Despliega `PanelObjetivos` |
| Fecha y caja | Cabecera | Barra: solo la fecha corta (el saldo ya no sale en el menú central: solo en Finanzas); reloj del pie con Timer de 1 s | — |
| Escudo | Cabecera | Barra, centrado (→ Identidad visual) | Identidad visual |
| Guardar / Cargar / ranuras / créditos | Ajustes > Partida y guardado | Barra > «Sistema» (panel: guardar y cargar, ayuda y glosario, créditos, salir al menú inicial, salir del juego). «Partida y guardado» SALIÓ del menú Ajustes lateral | Ajustes · partida (`_ir_a_chip`) |
| Atajos de teclado (`AtajosCentrales`) | Cualquier pantalla | Siguen activos; en el Inicio, L2/R2 abren el primer/último menú de la barra lateral | Cada atajo |
| Tutorial | Primera vez | Sin cambios (`GuiaTutorial`) | Tarjetas de ayuda |
| Levantarse del PC / Entrar al club | Cajón lateral | Barra de arriba, extremo derecho, con icono dibujado: «Levantarse del PC» dentro de `PcOficina` (Esc también; autoguarda al levantarse y al cerrar el juego), «Entrar al club» fuera | `PcOficina.apagar` / `ver_estadio` |
| Selector (OptionButton) | Fila de la raíz | Sigue en la raíz del menú anterior (oculta); cambio de club en Ajustes > Partida | Ajustes |
| Mosaicos de «Dirección del equipo» e «Información del club» | Pestañas del Inicio | Quedan en el código (`EscaparateSubs`, `EscaparateIndice`, `EscaparateArte*`) para usarlos como portada de menús; hoy cada menú lateral usa su portada de siempre (`PortadaMosaico`) | — |

## 3. Pantallas perezosas (`Principal.PANTALLAS_PEREZOSAS`)

Las 12 (`club_vida`, `cantera`, `gente`, `finanzas`, `editor`, `identidad`, `plantel`, `ficha`, `despacho`, `legado`, `opciones`, `elegir_club`) se abren desde los submenús de la sección 1 (cada `tab` del panel lateral llama a `_abrir_perezosa`), así que están cubiertas por la barra lateral; `despacho` además por «Despacho · N». La prueba `probar_conexion_menu_central` abre CADA submenú que no es una acción y comprueba menú y submenú.

## 4. Al revés: cada tarjeta, pestaña y botón nuevo

| Elemento nuevo | Abre |
|---|---|
| Pestaña «Avanzar en el tiempo» | Inicio; re-pulsar = desplegable de avance |
| Barra: «Despacho · N» / «Mensajes · N» | Pantalla completa del despacho / de mensajes e informe (Esc o «Volver» cierran) |
| Barra: escudo (centrado, dentro de su altura) | Identidad visual |
| Barra: Oficina del DT / Base de datos / Sistema | Mi carrera / buscador / Ajustes |
| Tarjetas del Inicio: Oficina del DT, Noticias y correo, Tabla de posiciones, Calendario, Hinchada y socios, Despacho | Mi carrera, Correo, Ligas y clubes, Calendario de semanas, Hinchada y socios, pantalla del despacho |
| Pie: Avanzar…, 🎯, Levantarse del PC / Entrar al club, Ayuda | Botones de avance, objetivos, PC / estadio, Glosario |
| Barra lateral (14 iconos) | Cada menú en su portada |

## 5. Pendiente (anotado)

- Despacho: las 3 imágenes por estado están DIBUJADAS con formas planas (`EscaparateArte`), no renderizadas con el motor 3D como pidió Auditoría.
- DT: la figura lleva la ropa del color del club pero no una chaqueta/chándal con escudo; su retrato no se ha rehecho.
- La forma (G/E/P) no tiene sitio todavía (Plantel o Competiciones): `EscaparateSubs._forma` queda en el código.
- Mosaicos de «Dirección del equipo» e «Información del club» (`EscaparateSubs`, `EscaparateIndice`, `EscaparateArte*`): sin uso hoy; pueden servir de portadas de menús.

