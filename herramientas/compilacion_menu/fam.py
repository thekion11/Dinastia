import re,json
from dom import *
capas=lambda n: re.match(r'res://ui/principal(_p\d+)?\.gd$',n) is not None
cadena={n for n in base if capas(n)}
cand=[(dom_b[n],n) for n in base if n!=ROOT and not capas(n) and idom[n] in cadena]
cand.sort(reverse=True)
def sub(n,out):
    out.add(n)
    for h in hijos[n]: sub(h,out)
fam={'ciudad':[], 'estadio_partido':[], 'pantallas':[], 'otros':[]}
for b,n in cand:
    nm=nombre.get(n,'')
    ruta=n
    if re.search(r'ciudad|city|metro|explorador|interior|vida_ciudad|casa_|peaton|trafico|paradero|autopista|teleferico',ruta): f='ciudad'
    elif not ruta.startswith('res://nucleo') and re.search(r'estadio|stadium|motor_jugable|partido|ocasion|vestuario|camera|tunel|anim_|jugable|cesped|arbitro',ruta): f='estadio_partido'
    elif re.search(r'ui/pantallas/|pantalla',ruta): f='pantallas'
    else: f='otros'
    fam[f].append((b,n,nm))
res={}
for f,l in fam.items():
    tb=sum(b for b,_,_ in l)
    print('%-16s %4d subárboles  %7.0f KB  %5.1f%%'%(f,len(l),tb/1024,100*tb/tot))
    res[f]=[(n,nm) for b,n,nm in l]
json.dump({'fam':res,'tot':tot},open('fam.json','w'))
print('--- otros (top 15)')
for b,n,nm in fam['otros'][:15]: print('  %6.0f KB %-22s %s'%(b/1024,nm,n.split('/')[-1]))

# GRUPOS CHICOS (3-11, tras cortar estadio/partido, ciudad y pantallas): personajes 3D, edificio del club, prensa 3D, kits, extras del partido y minijuegos.
# Cada clase raíz con su subárbol de dominadores; `cortar.py chicos` corta las referencias desde fuera.
GRUPOS_CHICOS={
 'personajes':['CreadorPersonaje','VestidorQ','PersonajeDT','PeloCapas','MascotaQ','FutbolistaQ','CaraMalla','PersonaRealista','PersonajeVida','PlayerSpawner'],
 'edificio':['EdificioClub','RecorridoClub','SalasClub','GaleriaClub','MuseoAmpliado'],
 'prensa3d':['RuedaPrensaEscena3D','PortadaPeriodico'],
 'kits':['DisenosKit','DisenadorKit','EscudoEmblemas'],
 'extras_partido':['Repeticion','CineGol','ControlFC','PanelControles','PartidoJugable'],
 'minijuegos':['SalaMinijuegos'],
}
chicos=[]
for g,cl in GRUPOS_CHICOS.items():
    for c in cl:
        p=clase.get(c)
        if p and p in base: chicos.append((p,c))
if 'res://ui/principal/rueda_prensa.gd' in base: chicos.append(('res://ui/principal/rueda_prensa.gd',''))
res['chicos']=chicos
json.dump({'fam':res,'tot':tot},open('fam.json','w'))
print('chicos:',len(chicos),'raíces')
