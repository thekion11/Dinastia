#!/usr/bin/env python3
"""Analisis estatico de GDScript en 3 metodos. Uso: analizar_gd.py <metodo> <salida.jsonl>
metodo: lint (gdlint) | forma (gdparse+gdformat) | ast (analizador propio)"""
import sys, re, json, subprocess, os, difflib
from multiprocessing import Pool
RAIZ = "/home/user/Dinastia"
LISTA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "lista.txt")

def hallazgo(f, l, regla, msg, sev="menor"):
    return {"archivo": f, "linea": l, "regla": regla, "mensaje": msg, "sev": sev}

def msg_sintaxis(txt):
    for ln in txt.splitlines():
        if ln.startswith(("Unexpected", "No terminal", "Unexpected token")) or "Unexpected" in ln[:12]:
            return ln.strip()[:160]
    return "error de sintaxis"

def m_lint(f):
    r = subprocess.run(["gdlint", f], cwd=RAIZ, capture_output=True, text=True)
    out = []
    for ln in (r.stdout + r.stderr).splitlines():
        m = re.match(r"^(.*?):(\d+): (Error|Warning): (.*) \(([\w-]+)\)$", ln)
        if m:
            out.append(hallazgo(f, int(m[2]), "gdlint:" + m[5], m[4]))
    if r.returncode not in (0, 1) or ("Unexpected" in r.stderr + r.stdout) or ("No terminal" in r.stderr + r.stdout):
        out.append(hallazgo(f, 0, "gdlint:fallo-analisis", msg_sintaxis(r.stdout + r.stderr), "alta"))
    return out

def m_forma(f):
    out = []
    src = open(os.path.join(RAIZ, f), encoding="utf-8", errors="replace").read()
    r = subprocess.run(["gdparse", f], cwd=RAIZ, capture_output=True, text=True)
    if r.returncode != 0:
        out.append(hallazgo(f, 0, "gdparse:sintaxis", msg_sintaxis(r.stdout + r.stderr), "alta"))
        return out
    r = subprocess.run(["gdformat", "--diff", f], cwd=RAIZ, capture_output=True, text=True)
    if r.returncode not in (0, 1) and "would reformat" not in r.stderr:
        pass
    for ln in (r.stdout + r.stderr).splitlines():
        m = re.match(r"^@@ -(\d+)", ln)
        if m:
            out.append(hallazgo(f, int(m[1]), "gdformat:formato", "bloque que gdformat reformatearia"))
    if "\r" in src:
        out.append(hallazgo(f, 0, "forma:crlf", "fin de linea CRLF"))
    if not src.endswith("\n"):
        out.append(hallazgo(f, 0, "forma:sin-salto-final", "falta salto de linea final"))
    return out

def m_ast(f):
    from gdtoolkit.parser import parser
    out = []
    src = open(os.path.join(RAIZ, f), encoding="utf-8", errors="replace").read()
    lines = src.split("\n")
    n = len(lines) - (1 if lines and lines[-1] == "" else 0)
    if n > 450:
        out.append(hallazgo(f, 1, "ast:archivo-largo", f"{n} lineas (norma del proyecto: <=450)", "alta"))
    for i, ln in enumerate(lines, 1):
        s = ln.strip()
        if re.search(r"#\s*(TODO|FIXME|HACK|XXX)\b", ln):
            out.append(hallazgo(f, i, "ast:pendiente", s[:120]))
        if re.match(r"^\s*print(_debug|_rich)?\(", ln) or re.match(r"^\s*breakpoint\b", ln):
            out.append(hallazgo(f, i, "ast:depuracion", s[:120]))
        if re.search(r"(==|!=)\s*-?\d+\.\d+\b|\b\d+\.\d+\s*(==|!=)", ln) and not s.startswith("#"):
            out.append(hallazgo(f, i, "ast:igualdad-flotante", s[:120], "media"))
        if re.match(r"^\s*#\s*(var|func|if|for|while|return|print)\b.*[:=(]", ln):
            out.append(hallazgo(f, i, "ast:codigo-comentado", s[:120]))
        if re.match(r"^ +\S", ln) and "\t" in ln[:len(ln)-len(ln.lstrip())]:
            out.append(hallazgo(f, i, "ast:indentacion-mixta", "tabs y espacios"))
        if re.search(r"\bawait\b.*\bawait\b", ln):
            out.append(hallazgo(f, i, "ast:await-doble", s[:120]))
        if re.search(r"\bpush_error\(|\bassert\(false", ln) is None and False:
            pass
    try:
        t = parser.parse(src, gather_metadata=True)
    except Exception as e:
        out.append(hallazgo(f, 0, "ast:no-parsea", str(e).splitlines()[0][:160], "alta"))
        return out
    cuerpos = {}
    for fn in t.find_data("func_def"):
        a, b = fn.meta.line, fn.meta.end_line
        nombre = "?"
        for h in fn.find_data("func_header"):
            for ch in h.children:
                if hasattr(ch, "type") and ch.type == "NAME":
                    nombre = str(ch); break
            break
        ln_f = b - a + 1
        if ln_f > 80:
            out.append(hallazgo(f, a, "ast:funcion-larga", f"{nombre}: {ln_f} lineas", "media" if ln_f > 150 else "menor"))
        cc = 1 + sum(1 for _ in fn.find_data("if_branch")) + sum(1 for _ in fn.find_data("elif_branch")) \
            + sum(1 for _ in fn.find_data("for_stmt")) + sum(1 for _ in fn.find_data("while_stmt")) \
            + sum(1 for _ in fn.find_data("and_test")) + sum(1 for _ in fn.find_data("or_test")) \
            + sum(1 for _ in fn.find_data("match_branch"))
        if cc > 15:
            out.append(hallazgo(f, a, "ast:complejidad-ciclomatica", f"{nombre}: {cc}", "alta" if cc > 30 else "media"))
        nargs = sum(1 for _ in fn.find_data("func_arg_regular")) + sum(1 for _ in fn.find_data("func_arg_inf")) \
            + sum(1 for _ in fn.find_data("func_arg_typed")) + sum(1 for _ in fn.find_data("func_arg_regular_assigned")) \
            + sum(1 for _ in fn.find_data("func_arg_typed_assigned")) + sum(1 for _ in fn.find_data("func_arg_inf_assigned"))
        if nargs > 6:
            out.append(hallazgo(f, a, "ast:muchos-parametros", f"{nombre}: {nargs}"))
        base = min((len(l) - len(l.lstrip("\t")) for l in lines[a:b] if l.strip()), default=0)
        prof = max((len(l) - len(l.lstrip("\t")) for l in lines[a:b] if l.strip()), default=0) - base
        if prof > 5:
            out.append(hallazgo(f, a, "ast:anidamiento", f"{nombre}: profundidad {prof}", "media"))
        cuerpo = "\n".join(l.strip() for l in lines[a:b] if l.strip() and not l.strip().startswith("#"))
        if ln_f >= 8:
            cuerpos.setdefault(cuerpo, []).append((nombre, a))
        # variables locales sin uso
        for v in fn.find_data("func_var_stmt"):
            for tk in v.scan_values(lambda x: hasattr(x, "type") and x.type == "NAME"):
                nm = str(tk)
                if nm.startswith("_"):
                    break
                usos = len(re.findall(r"\b" + re.escape(nm) + r"\b", "\n".join(lines[a - 1:b])))
                if usos <= 1:
                    out.append(hallazgo(f, v.meta.line, "ast:variable-sin-uso", f"{nm} en {nombre}"))
                break
    for cu, lst in cuerpos.items():
        if len(lst) > 1:
            for nm, a in lst:
                out.append(hallazgo(f, a, "ast:funcion-duplicada", f"{nm} identica a otra en el mismo archivo"))
    return out

METODOS = {"lint": m_lint, "forma": m_forma, "ast": m_ast}

def seguro(args):
    met, f = args
    try:
        return METODOS[met](f)
    except Exception as e:
        return [hallazgo(f, 0, met + ":excepcion", repr(e)[:160], "alta")]

if __name__ == "__main__":
    met, salida = sys.argv[1], sys.argv[2]
    fs = [l.strip() for l in open(LISTA) if l.strip()]
    with Pool(4) as p:
        res = p.map(seguro, [(met, f) for f in fs], chunksize=8)
    todos = sorted((h for r in res for h in r), key=lambda h: (h["archivo"], h["linea"], h["regla"], h["mensaje"]))
    with open(salida, "w") as o:
        for h in todos:
            o.write(json.dumps(h, ensure_ascii=False, sort_keys=True) + "\n")
    print(met, len(fs), "archivos,", len(todos), "hallazgos")
