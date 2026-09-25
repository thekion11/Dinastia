# Convierte un .fbx suelto a .glb, empaquetando las texturas de al lado.
# Distinto de blender_a_glb.py: ese abre un .blend YA CARGADO por Blender
# (-b entrada.blend); un .fbx no lo abre Blender de forma nativa, hay que
# arrancar con la escena vacia e IMPORTARLO como paso aparte.
#
#   blender.exe -b --python fbx_a_glb.py -- entrada.fbx salida.glb [ratio_decimado]
#
# El tercer argumento (opcional, 0-1) decima la malla igual que
# simplificar_a_glb.py -por ejemplo 0.15 deja el 15% de las caras-. Hace falta
# aparte de la rebaja de texturas: un modelo bajado de un banco de assets para
# un primer plano trae CIENTOS de miles de vertices, y de fondo en el
# horizonte de la ciudad ese detalle no se nota pero sí pesa.
#
# Blender 4.4 esta instalado en:
#   C:\Program Files\Blender Foundation\Blender 4.4\blender.exe
import bpy, sys, os

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if len(argv) < 2:
    print("USO: blender.exe -b --python fbx_a_glb.py -- entrada.fbx salida.glb [ratio_decimado]")
    sys.exit(1)
entrada = argv[0]
salida = argv[1]
ratio_decimado = float(argv[2]) if len(argv) > 2 else 1.0

bpy.ops.wm.read_factory_settings(use_empty=True)

# use_image_search: el FBX guarda la textura por nombre, y el fichero de
# verdad vive en una carpeta "textures" al lado de "source" -mismo patron
# que ya se documento para los .blend en blender_a_glb.py-. Blender la busca
# solo si se le pide.
bpy.ops.import_scene.fbx(filepath=entrada, use_image_search=True)

# Camaras y luces del autor no pintan nada dentro del juego: el visor pone
# las suyas.
for o in list(bpy.data.objects):
    if o.type in {'CAMERA', 'LIGHT'}:
        bpy.data.objects.remove(o, do_unlink=True)

if ratio_decimado < 1.0:
    antes = 0
    despues = 0
    for o in list(bpy.data.objects):
        if o.type != 'MESH':
            continue
        antes += len(o.data.vertices)
        bpy.context.view_layer.objects.active = o
        m = o.modifiers.new(name="dec", type='DECIMATE')
        m.decimate_type = 'COLLAPSE'
        m.ratio = ratio_decimado
        bpy.ops.object.modifier_apply(modifier=m.name)
        for p in o.data.polygons:
            p.use_smooth = True
        despues += len(o.data.vertices)
    print("VERTICES", antes, "->", despues)

# Los modelos de bancos de assets traen texturas a 4096 o hasta 4000x3300 -
# pensadas para un primer plano de arquitectura, no para un edificio de fondo
# en el horizonte de la ciudad. Sin bajarlas de tamano, un solo modelo puede
# pesar 100-200 MB en el .glb, lo que revienta el techo de 1 GB del proyecto
# y el tamano del APK. Se bajan a un maximo de 1024 px de lado -de sobra para
# verse bien a la distancia a la que se mira un edificio en este juego-,
# preservando la proporcion.
TOPE_LADO = 1024

sin_imagen = []
for img in bpy.data.images:
    if img.name == 'Render Result':
        continue
    if img.size[0] == 0:
        sin_imagen.append(img.name)
        print("TEXTURA", img.name, "SIN CARGAR (no la encontro use_image_search)")
        continue
    try:
        w, h = img.size[0], img.size[1]
        if max(w, h) > TOPE_LADO:
            factor = TOPE_LADO / max(w, h)
            nw, nh = max(1, int(w * factor)), max(1, int(h * factor))
            img.scale(nw, nh)
            print("TEXTURA", img.name, "reescalada", w, "x", h, "->", nw, "x", nh)
        if not img.packed_file:
            img.pack()
        print("TEXTURA", img.name, img.size[0], "x", img.size[1], "OK")
    except Exception as e:
        print("TEXTURA", img.name, "FALLO AL EMPAQUETAR:", e)

bpy.ops.export_scene.gltf(
    filepath=salida,
    export_format='GLB',
    export_yup=True,
    export_apply=True,
    export_materials='EXPORT',
    export_image_format='AUTO')
print("EXPORTADO", salida, os.path.getsize(salida), "bytes")
if sin_imagen:
    print("AVISO:", len(sin_imagen), "texturas quedaron sin encontrar:", sin_imagen)
