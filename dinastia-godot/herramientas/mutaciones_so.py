#!/usr/bin/env python3
"""MUTACIONES DE LAS PRUEBAS POR SISTEMA (5-11-2026). Para cada prueba de `pruebas/so/LISTA.txt`: se rompe A PROPÓSITO lo que vigila, se corre la prueba,
se comprueba que da FALLO y se deshace el cambio. Una prueba que sobrevive a su mutación no vigila lo que dice.

  python3 herramientas/mutaciones_so.py                 # las rápidas (~10 s cada una)
  python3 herramientas/mutaciones_so.py --lentas        # también las de pantalla (vis_*, ren_partido_presupuesto: minutos)
  python3 herramientas/mutaciones_so.py nombre ...      # solo esas
  python3 herramientas/mutaciones_so.py --markdown      # salida en tabla Markdown (para docs/04_auditorias/cobertura_pruebas_*.md)

Tipos: sub (cambia un texto de un archivo), crear (archivo nuevo), gordo (archivo enorme y vacío), copiar (una referencia pisa a otra).
Los archivos se restauran siempre (copia en memoria, o `git checkout` si es un archivo seguido por git). Sale con 1 si alguna sobrevive.
"""
import os, shutil, subprocess, sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PY = sys.executable

def sub(f, a, b):
    return ("sub", f, a, b)

MUT = {
    "com_idiomas_nueve_sin_vacios": ("una traducción vacía en el JSON", sub("datos/idiomas_extra.json", '"Plantel": "Squad"', '"Plantel": ""')),
    "com_idiomas_cambio_en_vivo": ("t() deja de traducir", sub("nucleo/idiomas.gd", 'if idioma == "es" or frase == "":\n\t\treturn frase', 'if true:\n\t\treturn frase')),
    "com_guardado_ida_vuelta": ("las partidas van a res:// (no escribible)", sub("nucleo/partida_p1.gd", 'const CARPETA := "user://partidas"', 'const CARPETA := "res://partidas_x"')),
    "com_arranque_autoloads": ("desaparece el autoload Registro", sub("project.godot", 'Registro="*res://nucleo/registro.gd"\n', "")),
    "com_entrada_por_sistema": ("el toque deja de emular el ratón", sub("project.godot", "pointing/emulate_mouse_from_touch=true", "pointing/emulate_mouse_from_touch=false")),
    "err_guardado_danado": ("se quita la comprobación de la huella MD5", sub("nucleo/partida_archivo.gd", "if crudo.size() != tam or _md5(crudo) != b.slice(8, 24):", "if crudo.size() != tam:")),
    "err_instantanea_invalida": ("se quita el rechazo de guardados sin claves", sub("nucleo/partida.gd", "for clave: String in CLAVES_IMPRESCINDIBLES:", "for clave: String in []:")),
    "err_pck_y_pack_ausentes": ("Parches busca otro prefijo", sub("nucleo/parches.gd", 'const PREFIJO := "parche_"', 'const PREFIJO := "otro_"')),
    "err_entradas_invalidas": ("mayusculas('') ya no es ''", sub("nucleo/idiomas.gd", "return texto.to_upper()", 'return texto.to_upper() + "x"')),
    "err_rafaga_entrada": ("un error de intérprete al recibir cualquier entrada", sub("nucleo/vida_global.gd", "func hay_partido() -> bool:", "func _input(_e: InputEvent) -> void:\n\tvar n: Object = null\n\tn.explotar()\n\nfunc hay_partido() -> bool:")),
    "err_poca_memoria": ("ante poca memoria la calidad sube en vez de bajar", sub("nucleo/vida_global.gd", "Calidad.elegida = Calidad.MINIMO\n\t\t\tCalidad.aplicar_viewport", "Calidad.elegida = Calidad.ALTO\n\t\t\tCalidad.aplicar_viewport")),
    "est_calendario_liga": ("la victoria suma 2 puntos en la tabla", sub("nucleo/liga.gd", 'a["pts"] += puntos_victoria; a["g"] += 1', 'a["pts"] += 2; a["g"] += 1')),
    "est_economia_invariantes": ("escalar() puede dar 0", sub("nucleo/economia.gd", "return int(max(1.0, round(n * pow(factor_club(rep), 0.62))))", "return int(round(n * pow(factor_club(rep), 0.62)))")),
    "est_datos_coherencia": ("a Argentina le falta su tier económico", sub("datos/tablas.json", '"ARG":0.75', '"ARG_X":0.75')),
    "est_datos_tablas_vs_codigo": ("el código pide una tabla que no existe", sub("nucleo/azar.gd", "func _ready() -> void:\n\tsembrar(0)", '# Datos.tabla("TABLA_FANTASMA")\nfunc _ready() -> void:\n\tsembrar(0)')),
    "est_partido_simulado_reglas": ("el visitante marca 20 goles de más", sub("nucleo/partido.gd", 'return {"local": goles_local, "visita": goles_visita}', 'return {"local": goles_local, "visita": goles_visita + 20}')),
    "int_nativo_por_sistema": ("la extensión C++ no carga aunque debería", sub("nucleo/nativo.gd", 'if OS.get_environment("DINASTIA_SIN_NATIVO") != "1" and ClassDB', "if false and ClassDB")),
    "int_paquetes_y_parches": ("Parches busca otro prefijo que el actualizador", sub("nucleo/parches.gd", 'const PREFIJO := "parche_"', 'const PREFIJO := "otro_"')),
    "int_flujo_menu_a_guardado": ("cargar no restaura los grupos del continental (la causa real de la divergencia)", sub("nucleo/partida.gd", "t.grupos_desde_dic(fila, m.clubes)", "pass")),
    "int_actualizador_por_sistema": ("el actualizador cree que todo es Android", sub("nucleo/actualizador.gd", 'return "android" if OS.has_feature("android") else "escritorio"', 'return "android"')),
    "vis_partido_forward": ("la referencia del partido es otra pantalla", ("copiar", "pruebas/so/referencias/menu_00_gl_compatibility.jpg", "pruebas/so/referencias/partido_tv_forward_plus.jpg"), "lenta"),
    "vis_partido_compat": ("la referencia del partido es otra pantalla", ("copiar", "pruebas/so/referencias/menu_00_gl_compatibility.jpg", "pruebas/so/referencias/partido_tv_gl_compatibility.jpg"), "lenta"),
    "vis_menu_pantallas": ("la referencia de una pantalla es otra", ("copiar", "pruebas/so/referencias/menu_03_gl_compatibility.jpg", "pruebas/so/referencias/menu_00_gl_compatibility.jpg"), "lenta"),
    "vis_pantallas_sin_vacios": ("cambiar de pestaña no hace nada", sub("ui/principal_p7.gd", "func _ir_a_pestana(titulo: String) -> void:\n", 'func _ir_a_pestana(titulo: String) -> void:\n\tif titulo != "":\n\t\treturn\n')),
    "vis_referencias_integras": ("dos referencias son la misma imagen", ("copiar", "pruebas/visual/referencias/plantel.jpg", "pruebas/visual/referencias/tactica.jpg")),
    "fun_azar_puro": ("ent(a,b) se pasa del rango", sub("nucleo/azar.gd", "return _rng.randi_range(a, b)", "return _rng.randi_range(a, b + 1)")),
    "fun_calendario_fechas": ("la Pascua se calcula con un día de error", sub("nucleo/calendario.gd", "var h := (19 * a + b - d - g + 15) % 30", "var h := (19 * a + b - d - g + 14) % 30")),
    "fun_formato_y_demarcaciones": ("los millones se escriben con K", sub("nucleo/economia.gd", 'cifra = "%.1fM" % (a / 1000000.0)', 'cifra = "%.1fK" % (a / 1000000.0)')),
    "fun_nativo_datos_aleatorios": ("la rampa en GDScript copia mal el canal verde", sub("visor/ruidos_fondo.gd", "dst[i * 4 + 1] = lut[o + 1]", "dst[i * 4 + 1] = lut[o]")),
    "ren_partido_presupuesto": ("(pendiente: el presupuesto se validó con valores medidos; una mutación cuesta ~3 min de pantalla)", None, "lenta"),
    "est_propiedades_semillas": ("la victoria suma 2 puntos en la tabla (en 50 mundos distintos)", sub("nucleo/liga.gd", 'a["pts"] += puntos_victoria; a["g"] += 1', 'a["pts"] += 2; a["g"] += 1')),
    "ren_menu_y_mundo_memoria": ("cada mundo generado retiene 80 MB", sub("nucleo/mundo_p3.gd", "func generar(paises: Array[String] = [], semilla_partida: int = 0) -> void:\n", "func generar(paises: Array[String] = [], semilla_partida: int = 0) -> void:\n\tvar _gran := PackedByteArray()\n\t_gran.resize(80000000)\n\tEngine.set_meta(\"fuga%d\" % Engine.get_meta_list().size(), _gran)\n")),
    "ren_peso_archivos": ("un archivo de datos de 131 MB", ("gordo", "datos/_gordo.bin", 131 * 1048576)),
    "ren_sin_tiempo_en_headless": ("una prueba afirma sobre los FPS sin pantalla", ("crear", "pruebas/_mut_fps.gd", 'extends Node\nfunc _p() -> void:\n\t_comprobar(Engine.get_frames_per_second() > 60, "fps")\n')),
}


def correr(nombre):
    p = subprocess.run([PY, os.path.join(RAIZ, "herramientas", "pruebas_so.py"), nombre], cwd=RAIZ, capture_output=True, text=True)
    sal = p.stdout + p.stderr
    return [l for l in sal.splitlines() if l.startswith(("OK", "FALLO"))][:1] or ["sin salida"]


def aplicar(m):
    """Devuelve la función que deshace el cambio."""
    k = m[0]
    if k == "sub":
        ruta = os.path.join(RAIZ, m[1])
        orig = open(ruta, encoding="utf-8", newline="").read()
        if m[2] not in orig:
            raise RuntimeError("el texto a cambiar ya no está en %s" % m[1])
        open(ruta, "w", encoding="utf-8", newline="").write(orig.replace(m[2], m[3], 1))
        return lambda: open(ruta, "w", encoding="utf-8", newline="").write(orig)
    if k == "copiar":
        origen, destino = os.path.join(RAIZ, m[1]), os.path.join(RAIZ, m[2])
        copia = open(destino, "rb").read()
        shutil.copyfile(origen, destino)
        return lambda: open(destino, "wb").write(copia)
    ruta = os.path.join(RAIZ, m[1])
    if k == "crear":
        open(ruta, "w", encoding="utf-8").write(m[2])
    else:
        with open(ruta, "wb") as f:
            f.truncate(m[2])
    return lambda: os.path.exists(ruta) and os.remove(ruta)


def main():
    a = sys.argv[1:]
    lentas = "--lentas" in a
    md = "--markdown" in a
    pedidas = [x for x in a if not x.startswith("--")]
    lista = [l.split("|")[0] for l in open(os.path.join(RAIZ, "pruebas", "so", "LISTA.txt"), encoding="utf-8") if l.strip() and not l.startswith("#")]
    sobreviven = 0
    filas = []
    for n in lista:
        if pedidas and n not in pedidas:
            continue
        ent = MUT.get(n)
        if ent is None:
            filas.append((n, "(sin mutación definida)", "FALTA"))
            sobreviven += 1
            continue
        desc, m = ent[0], ent[1]
        if len(ent) > 2 and ent[2] == "lenta" and not lentas and not pedidas:
            filas.append((n, desc, "no corrida (lenta)"))
            continue
        if m is None:
            filas.append((n, desc, "no mutada"))
            continue
        deshacer = aplicar(m)
        try:
            r = correr(n)[0]
        finally:
            deshacer()
        res = "DETECTADA" if r.startswith("FALLO") else "SOBREVIVE (%s)" % r[:20]
        sobreviven += res.startswith("SOB")
        filas.append((n, desc, res))
        print("%-34s %s" % (n, res), flush=True)
    if md:
        print("\n| prueba | mutación (lo que se rompe) | resultado |\n|---|---|---|")
        for f in filas:
            print("| `%s` | %s | %s |" % f)
    print("MUTACIONES: %d sobreviven" % sobreviven)
    return 1 if sobreviven else 0


if __name__ == "__main__":
    sys.exit(main())
