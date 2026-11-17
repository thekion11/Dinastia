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
"""
TARJETA = {}
for r in EQUIPO: TARJETA[r] = "Dirección del equipo > tarjeta"
for r in CLUB: TARJETA[r] = "Información del club > tarjeta"
TARJETA["Mi plantel"] = "Dirección del equipo > tarjeta «Mi plantel»"
TARJETA["Mi carrera"] = "Barra > «Oficina del DT» y tarjeta del DT (Inicio)"
TARJETA["Correo"] = "Pie > «Mensajes» y tarjeta «Noticias y correo» (Inicio)"
TARJETA["Glosario"] = "Pie > «Ayuda»"
TARJETA["Calendario"] = "Inicio > tarjeta «Calendario»"
TARJETA["Ligas y clubes"] = "Información del club > tarjeta; Inicio > tabla de posiciones; Base de datos"
TARJETA["Hinchada y socios"] = "Información del club > tarjeta; Inicio > «Hinchada y socios»"
out = ["# INVENTARIO DEL MENÚ CENTRAL (17-11-2026)", "",
       "Generado con `dinastia-godot/herramientas/inventario_menu_central.py` (lee `MenusLaterales.MENUS`, `TableroInicio.EQUIPO/CLUB`); la prueba `_probar_conexion_menu_central` (banco, grupo `menus`) y `pruebas/probar_conexion_menu_central.gd` (especiales.sh, xvfb) la hacen cumplir.",
       "", "Todo submenú sale en la pestaña **Índice** (cuarta pestaña del menú central: cada menú del panel lateral con TODOS sus submenús como botones, leídos de `MenusLaterales.MENUS`) y, además, por el «☰» de la barra, L2/R2 y los atajos de teclado. La columna «Entrada directa» dice si ADEMÁS tiene tarjeta o botón propio.", "",
       "## 1. Submenús del panel lateral (%d en %d menús)" % (len(filas), len({f[0][0] for f in filas})), "",
       "| Menú | Submenú | Destino (pestaña · sección / acción) | Entrada directa en el menú nuevo | Índice | ≡ |", "|---|---|---|---|---|---|"]
for (mid, mn), tab, secc, acc, label in filas:
    dest = ("acción `%s`" % acc) if acc else ("%s%s" % (tab, (" · " + secc) if secc else ""))
    directa = TARJETA.get(label) or "—"
    out.append("| %s | %s | %s | %s | sí | sí |" % (mn, label, dest, directa))
sin = [l for (_, _, _, _, l) in filas if l not in TARJETA]
out += ["", "Submenús sin tarjeta propia (se alcanzan por el Índice, el «☰», L2/R2 y atajos): **%d de %d**. Ninguno queda «SIN ENTRADA»." % (len(sin), len(filas)), ""]
out += [ACCESORIOS]
open(ruta_segura("docs/04_auditorias/INVENTARIO_MENU_CENTRAL_2026-11-17.md"), "w", encoding="utf-8").write("\n".join(out) + "\n")
print("%d submenús; %d sin tarjeta propia" % (len(filas), len(sin)))
