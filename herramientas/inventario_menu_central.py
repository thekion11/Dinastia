#!/usr/bin/env python3
"""INVENTARIO del menú central (17-11-2026): lee de ui/componentes/menus_laterales.gd (MENUS), tablero_inicio.gd (EQUIPO/CLUB) y escaparate_*.gd
cada submenú del panel lateral y por dónde se llega ahora desde el menú nuevo. Escribe docs/04_auditorias/INVENTARIO_MENU_CENTRAL_2026-11-17.md (la parte de
accesorios está a mano en `ACCESORIOS` de este archivo, verificada contra el código).
   python3 dinastia-godot/herramientas/inventario_menu_central.py"""
import re, sys
from ruta_segura import ruta_segura
RAIZ = "dinastia-godot/"
def leer(r): return open(ruta_segura(RAIZ + r), encoding="utf-8").read()
menus = leer("ui/componentes/menus_laterales.gd")
tablero = leer("ui/componentes/tablero_inicio.gd")
def lista(nombre):
    m = re.search(r"const %s := \[(.*?)\]" % nombre, tablero, re.S)
    return re.findall(r'"([^"]+)"', m.group(1))
EQUIPO, CLUB = lista("EQUIPO"), lista("CLUB")
filas, actual = [], None
for ln in menus.split("\n"):
    m = re.search(r'\{"id": "(\w+)", "icono": "[^"]+", "nombre": "([^"]+)"', ln)
    if m:
        actual = (m.group(1), m.group(2))
        continue
    s = re.search(r'\{(?:"tab": "([^"]*)",)?\s*(?:"secc": "([^"]*)",)?\s*(?:"accion": "([^"]*)",)?\s*(?:"secc": "([^"]*)",)?\s*"label": "([^"]+)"', ln)
    if s and actual and "SUBS_MUNDO" not in ln:
        tab, secc, accion, secc2, label = s.groups()
        filas.append((actual, tab or "", secc or secc2 or "", accion or "", label))
        if ln.strip().startswith("]") : pass
# el bloque SUBS_MUNDO_ABIERTO (ciudad apagada) no cuenta: se corta el análisis en él
corte = menus.index("const SUBS_MUNDO_ABIERTO")
validas = []
total_antes = menus[:corte]
actual, filas = None, []
for ln in total_antes.split("\n"):
    m = re.search(r'\{"id": "(\w+)", "icono": "[^"]+", "nombre": "([^"]+)"', ln)
    if m:
        actual = (m.group(1), m.group(2)); continue
    s = re.search(r'"label": "([^"]+)"', ln)
    if s and actual:
        tab = re.search(r'"tab": "([^"]*)"', ln); secc = re.search(r'"secc": "([^"]*)"', ln); acc = re.search(r'"accion": "([^"]*)"', ln)
        filas.append((actual, tab.group(1) if tab else "", secc.group(1) if secc else "", acc.group(1) if acc else "", s.group(1)))
ACCESORIOS = """## 2. Accesorios del menú anterior

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
"""
TARJETA = {}
TARJETA["Mi carrera"] = "Barra > «Oficina del DT» y tarjeta del DT (Inicio)"
TARJETA["Identidad visual"] = "Barra > escudo"
TARJETA["Cuentas del club"] = "Barra > caja"
TARJETA["Correo"] = "Pie > «Mensajes» y tarjeta «Noticias y correo» (Inicio)"
TARJETA["Glosario"] = "Pie > «Ayuda»"
TARJETA["Calendario"] = "Inicio > tarjeta «Calendario»"
TARJETA["Ligas y clubes"] = "Inicio > tabla de posiciones; barra > Base de datos"
TARJETA["Hinchada y socios"] = "Inicio > tarjeta «Hinchada y socios»"
out = ["# INVENTARIO DEL MENÚ CENTRAL (17-11-2026)", "",
       "Generado con `dinastia-godot/herramientas/inventario_menu_central.py` (lee `MenusLaterales.MENUS`, `TableroInicio.EQUIPO/CLUB`); la prueba `_probar_conexion_menu_central` (banco, grupo `menus`) y `pruebas/probar_conexion_menu_central.gd` (especiales.sh, xvfb) la hacen cumplir.",
       "", "**Diseño aprobado por el dueño (17-11):** la barra lateral izquierda (los 14 iconos de `MenusLaterales.MENUS`, con su ☰, el cajón de submenús, L2/R2 y los atajos) está SIEMPRE visible, también en el Inicio; cada menú se abre en su portada (mosaico de tarjetas, una por submenú) y todos sus submenús siguen un clic más allá. La barra de arriba (color del club) NO repite esos menús: «Avanzar en el tiempo», «Despacho · N», «Mensajes · N», escudo (→ Identidad visual), «Oficina del DT», «Base de datos», «Sistema», la caja (→ Cuentas del club) y la fecha. La columna «Entrada directa» dice si el submenú tiene ADEMÁS una tarjeta o botón propio en el Inicio.", "",
       "## 1. Submenús del panel lateral (%d en %d menús)" % (len(filas), len({f[0][0] for f in filas})), "",
       "| Menú | Submenú | Destino (pestaña · sección / acción) | Entrada directa desde el Inicio | Barra lateral |", "|---|---|---|---|---|"]
for (mid, mn), tab, secc, acc, label in filas:
    dest = ("acción `%s`" % acc) if acc else ("%s%s" % (tab, (" · " + secc) if secc else ""))
    directa = TARJETA.get(label) or "—"
    out.append("| %s | %s | %s | %s | sí |" % (mn, label, dest, directa))
sin = [l for (_, _, _, _, l) in filas if l not in TARJETA]
out += ["", "Submenús sin tarjeta propia en el Inicio (se alcanzan por la barra lateral siempre visible, L2/R2 y atajos): **%d de %d**. Ninguno queda «SIN ENTRADA»." % (len(sin), len(filas)), ""]
out += [ACCESORIOS]
open(ruta_segura("docs/04_auditorias/INVENTARIO_MENU_CENTRAL_2026-11-17.md"), "w", encoding="utf-8").write("\n".join(out) + "\n")
print("%d submenús; %d sin tarjeta propia" % (len(filas), len(sin)))
