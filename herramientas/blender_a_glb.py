# Convierte un .blend a .glb (malla + UV + texturas + esqueleto + animaciones)
# para que Godot lo importe sin conversores ni abrir la interfaz de Blender.
#
#   blender.exe -b entrada.blend --python blender_a_glb.py -- salida.glb
#
# Blender 4.4 esta instalado en esta maquina en
# C:\Program Files\Blender Foundation\Blender 4.4\blender.exe
import bpy, sys, os

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
salida = argv[0] if argv else "salida.glb"

# Las camaras y luces del autor no pintan nada dentro del juego: el visor pone
# las suyas. Se quitan para que el .glb sea solo el personaje.
for o in list(bpy.data.objects):
    if o.type in {'CAMERA', 'LIGHT'}:
        bpy.data.objects.remove(o, do_unlink=True)

# Las texturas del .blend son REFERENCIAS a ficheros de al lado
# (../textures/face.png), y muy a menudo el nombre guardado NO coincide con el
# fichero que viene en el zip: el cr7.blend pedia "face.png" y lo que hay es
# "face2.png", asi que Blender no cargaba ninguna y el .glb salia sin texturas
# (modelo blanco en Godot, sin ningun error que lo avisara).
#
# Se busca cada imagen en las carpetas de texturas de al lado, primero por
# nombre exacto y despues por parecido, y se EMPAQUETA dentro del .glb.
import glob, difflib

base = os.path.dirname(bpy.data.filepath)
candidatos = []
for patron in ("textures", "Textures", "tex", "."):
    candidatos += glob.glob(os.path.join(base, "..", patron, "*"))
    candidatos += glob.glob(os.path.join(base, patron, "*"))
candidatos = [c for c in candidatos if os.path.isfile(c)]
por_nombre = {os.path.basename(c).lower(): c for c in candidatos}

for img in bpy.data.images:
    if img.name == 'Render Result':
        continue
    if img.size[0] == 0:  # no cargada: hay que buscarle el fichero
        # Se prueba con el NOMBRE de la imagen y con el de su ruta: en este
        # .blend el nombre ('arm.png') acierta y la ruta guardada no.
        nombres = [os.path.basename(img.name).lower()]
        if img.filepath:
            nombres.append(os.path.basename(img.filepath).lower())
        ruta = None
        for n in nombres:                      # 1) coincidencia exacta
            if n in por_nombre:
                ruta = por_nombre[n]
                break
        # Los separadores no son de fiar: el .blend pedia
        # "al nassr camisa detras.jpeg" y el fichero es
        # "al_nassr_camisa_detras.jpeg". Se comparan sin espacios ni guiones.
        def llano(s):
            return os.path.splitext(s)[0].replace(" ", "").replace("_", "").replace("-", "")

        if not ruta:                           # 2) mismo nombre, otra extension
            for n in nombres:
                for k, v in por_nombre.items():
                    if llano(k) == llano(n):
                        ruta = v
                        break
                if ruta:
                    break
        if not ruta:                           # 3) 'face' -> 'face2', y poco mas
            for n in nombres:
                raiz = os.path.splitext(n)[0].rstrip("0123456789_- ")
                if len(raiz) < 3:
                    continue
                iguales = [v for k, v in por_nombre.items() if os.path.splitext(k)[0].rstrip("0123456789_- ") == raiz]
                if len(iguales) == 1:
                    ruta = iguales[0]
                    break
        if ruta:
            img.filepath = ruta
            try:
                img.reload()
            except Exception as e:
                print("TEXTURA", img.name, "no se pudo recargar:", e)
        else:
            print("TEXTURA", img.name, "SIN FICHERO (no la encontre)")
            continue
    try:
        if not img.packed_file:
            img.pack()
        print("TEXTURA", img.name, "->", os.path.basename(img.filepath),
              img.size[0], "x", img.size[1],
              "OK" if img.packed_file else "SIN EMPAQUETAR")
    except Exception as e:
        print("TEXTURA", img.name, "FALLO:", e)

for a in bpy.data.actions:
    print("ACCION", a.name, "fotogramas", a.frame_range[0], "-", a.frame_range[1])
for o in bpy.data.objects:
    if o.type == 'ARMATURE':
        print("ARMATURE", o.name, "huesos", len(o.data.bones))
        print("PRIMEROS_HUESOS", [b.name for b in o.data.bones[:6]])

bpy.ops.export_scene.gltf(
    filepath=salida,
    export_format='GLB',
    export_yup=True,
    export_apply=True,
    export_skins=True,
    export_animations=True,
    export_materials='EXPORT',
    export_image_format='AUTO')
print("EXPORTADO", salida, os.path.getsize(salida), "bytes")
