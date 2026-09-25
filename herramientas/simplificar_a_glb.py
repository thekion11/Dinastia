# Simplifica una malla y la exporta a .glb, para poder repetirla miles de veces.
#
#   blender.exe -b --python simplificar_a_glb.py -- entrada.obj salida.glb 0.02 [escala]
#
# El tercer argumento es la PROPORCION de caras que se conservan (0.02 = 2%).
#
# POR QUE HACE FALTA
# El modelo de asientos de estadio que trajo el usuario tiene 38.916 vertices
# para una fila de tres butacas. Repetirlo por una grada entera son cientos de
# millones de vertices: ninguna maquina lo mueve, y menos una Intel UHD. Con la
# malla reducida al 2% la fila baja a unos cientos de vertices y se pueden poner
# miles de butacas en un MultiMesh sin despeinar los fotogramas. De lejos, que es
# donde se ven las gradas, la diferencia no se aprecia.
import bpy, sys, os

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
entrada = argv[0]
salida = argv[1] if len(argv) > 1 else "salida.glb"
ratio = float(argv[2]) if len(argv) > 2 else 0.05
escala = float(argv[3]) if len(argv) > 3 else 1.0

bpy.ops.wm.read_factory_settings(use_empty=True)

ext = os.path.splitext(entrada)[1].lower()
if ext == ".obj":
    bpy.ops.wm.obj_import(filepath=entrada)
elif ext == ".fbx":
    bpy.ops.import_scene.fbx(filepath=entrada)
else:
    bpy.ops.import_scene.gltf(filepath=entrada)

antes = 0
despues = 0
for o in list(bpy.data.objects):
    if o.type != 'MESH':
        continue
    antes += len(o.data.vertices)
    bpy.context.view_layer.objects.active = o
    m = o.modifiers.new(name="dec", type='DECIMATE')
    m.decimate_type = 'COLLAPSE'
    m.ratio = ratio
    bpy.ops.object.modifier_apply(modifier=m.name)
    # Suavizar las normales: los cantos vivos de una malla simplificada se ven
    # facetados, y con sombreado suave la butaca sigue leyendose redonda.
    for p in o.data.polygons:
        p.use_smooth = True
    if escala != 1.0:
        # La escala hay que APLICARLA a la malla, no dejarla en el nodo: quien la
        # use puede quedarse solo con el Mesh (para un MultiMesh, por ejemplo) y
        # entonces la escala del nodo se pierde. Paso esto una vez: cada "fila de
        # butacas" media 158 m dentro del estadio y tapaba todas las camaras.
        o.scale = (escala, escala, escala)
        bpy.context.view_layer.objects.active = o
        o.select_set(True)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        o.select_set(False)
    despues += len(o.data.vertices)

print("VERTICES", antes, "->", despues)
bpy.ops.export_scene.gltf(filepath=salida, export_format='GLB', export_apply=True,
                          export_yup=True, export_materials='EXPORT')
print("EXPORTADO", salida, os.path.getsize(salida), "bytes")
