# ============================================================================
#  EXTRAER LA CAPA DE VISTAS A SU PROPIO FICHERO
# ============================================================================
#  Mueve las funciones v* (las que construyen el HTML de cada pantalla) de
#  js\juego.js a js\vistas.js, con su comentario de cabecera.
#
#  POR QUE ES SEGURO HACERLO, Y POR QUE SOLO ESTE GRUPO
#
#  El mapa de dependencias (mapa_dependencias.ps1) dio el dato que autoriza este
#  movimiento: de las 891 funciones del motor, **solo UNA se llama desde codigo
#  que corre al cargar la pagina** (guardarYa, desde un listener de cierre). Las
#  vistas no estan entre ellas: a v* la llama render() cuando el jugador cambia
#  de pestana, o sea mucho despues de que los dos ficheros esten cargados.
#
#  Y como las declaraciones `function` se izan, el orden entre ficheros da igual
#  mientras ninguno EJECUTE al cargar algo que viva en el otro.
#
#  No se mueve nada mas por ahora porque el resto del motor no esta agrupado por
#  temas: mercado, partido, cantera y finanzas estan entremezclados de principio
#  a fin y cortar por lineas daria ficheros revueltos.
#
#  Uso:  .\extraer_vistas.ps1  [-Simular]
# ============================================================================
param([switch]$Simular)

$raiz = Split-Path -Parent $PSScriptRoot
$js   = Join-Path $raiz "js\juego.js"
$dst  = Join-Path $raiz "js\vistas.js"
$html = Join-Path $raiz "dinastia-futbol-manager base.html"

$lineas = [IO.File]::ReadAllLines($js, [Text.Encoding]::UTF8)

# --- localizar cada funcion v* y su comentario de cabecera -------------------
$bloques = New-Object Collections.Generic.List[object]
for ($i = 0; $i -lt $lineas.Count; $i++) {
    if ($lineas[$i] -cmatch '^function\s+(v[A-Z][A-Za-z0-9_$]*)\s*\(') {
        $nombre = $Matches[1]
        # el cierre es la primera llave sola en columna 0
        $fin = -1
        for ($j = $i + 1; $j -lt $lineas.Count; $j++) {
            if ($lineas[$j] -eq '}') { $fin = $j; break }
            if ($lineas[$j] -cmatch '^function\s') { break }   # se torcio: no lo tocamos
        }
        if ($fin -lt 0) { continue }
        # Subir por el comentario de encima, para que la documentacion viaje con
        # su funcion en vez de quedarse huerfana en el otro fichero.
        #
        # OJO, ESTO YA ROMPIO EL JUEGO UNA VEZ: la version ingenua subia mientras
        # la linea "pareciera" comentario (empieza por /*, por * o acaba en */).
        # En un bloque de varias lineas, las de en medio no empiezan por *, asi
        # que la subida paraba a mitad y se llevaba el FINAL del comentario sin
        # su apertura. El texto suelto acababa en vistas.js como codigo y todo el
        # fichero moria con "SyntaxError: Unexpected identifier 'retrasa'" -y, por
        # ser un script externo con file://, el navegador solo decia
        # "Script error." sin numero de linea.
        # Ahora, si se topa con un cierre */ se sube hasta encontrar el /* que lo
        # abre; si no aparece, NO se lleva el comentario.
        $ini = $i
        $k = $i - 1
        while ($k -ge 0) {
            $t = $lineas[$k].Trim()
            if ($t -eq '') { break }
            if ($t.StartsWith('//')) { $ini = $k; $k--; continue }
            if ($t.EndsWith('*/')) {
                $j = $k; $abre = -1
                while ($j -ge 0) {
                    if ($lineas[$j].Trim().StartsWith('/*')) { $abre = $j; break }
                    $j--
                }
                if ($abre -ge 0) { $ini = $abre; $k = $abre - 1; continue }
                break
            }
            break
        }

        # INVARIANTE: un bloque bien cortado tiene las llaves cuadradas y un
        # numero PAR de acentos graves. Si no, el corte esta mal y no se mueve:
        # mas vale dejar una vista en su sitio que romper el fichero entero.
        $abre = 0; $cierra = 0; $tildes = 0
        for ($x = $ini; $x -le $fin; $x++) {
            $abre   += ([Regex]::Matches($lineas[$x], '\{')).Count
            $cierra += ([Regex]::Matches($lineas[$x], '\}')).Count
            $tildes += ([Regex]::Matches($lineas[$x], '`')).Count
        }
        if ($abre -ne $cierra -or ($tildes % 2) -ne 0) {
            Write-Host ("   SE OMITE {0}: el corte no cuadra (llaves {1}/{2}, acentos {3})" -f $nombre, $abre, $cierra, $tildes) -ForegroundColor Yellow
            $i = $fin
            continue
        }

        $bloques.Add([PSCustomObject]@{ Nombre = $nombre; Ini = $ini; Fin = $fin })
        $i = $fin
    }
}

$totalLineas = 0
foreach ($b in $bloques) { $totalLineas += ($b.Fin - $b.Ini + 1) }
Write-Host ("vistas encontradas: {0}   lineas a mover: {1:N0}" -f $bloques.Count, $totalLineas)
if ($Simular) { foreach ($b in $bloques) { Write-Host ("   {0,-26} {1}-{2}" -f $b.Nombre, ($b.Ini + 1), ($b.Fin + 1)) }; return }

# --- construir vistas.js -----------------------------------------------------
$cab = @()
$cab += "/* ============================================================================"
$cab += "   DINASTIA FUTBOL MANAGER - capa de vistas"
$cab += "   ============================================================================"
$cab += "   Las funciones v* construyen el HTML de cada pantalla y las llama render()."
$cab += "   Salieron de js\juego.js porque son el unico grupo grande y cohesionado que"
$cab += "   tenia el motor: 73 funciones que hacen lo mismo, tocan lo mismo y se llaman"
$cab += "   desde el mismo sitio."
$cab += ""
$cab += "   Se carga DESPUES de juego.js y eso no da problemas: las declaraciones"
$cab += "   `function` se izan, y ninguna vista se ejecuta al cargar la pagina -a v* la"
$cab += "   llama render() cuando el jugador cambia de pestana-. El mapa de dependencias"
$cab += "   lo confirmo: de las 891 funciones del motor solo una (guardarYa) corre"
$cab += "   durante la carga."
$cab += ""
$cab += "   Como el resto del motor, se carga con <script src>, NUNCA con"
$cab += "   <script type=`"module`">: el juego se abre con file:// y los modulos ES estan"
$cab += "   sujetos a CORS."
$cab += "   ============================================================================ */"
$cab += ""

$cuerpo = New-Object Collections.Generic.List[string]
foreach ($b in ($bloques | Sort-Object Nombre)) {
    for ($i = $b.Ini; $i -le $b.Fin; $i++) { $cuerpo.Add($lineas[$i]) }
    $cuerpo.Add("")
}
[IO.File]::WriteAllLines($dst, ($cab + $cuerpo), (New-Object Text.UTF8Encoding($false)))

# --- quitar esos bloques de juego.js ----------------------------------------
$fuera = New-Object 'System.Collections.Generic.HashSet[int]'
foreach ($b in $bloques) { for ($i = $b.Ini; $i -le $b.Fin; $i++) { [void]$fuera.Add($i) } }
$resto = New-Object Collections.Generic.List[string]
for ($i = 0; $i -lt $lineas.Count; $i++) { if (-not $fuera.Contains($i)) { $resto.Add($lineas[$i]) } }
[IO.File]::WriteAllLines($js, $resto, (New-Object Text.UTF8Encoding($false)))

# --- engancharlo en el HTML --------------------------------------------------
$h = [IO.File]::ReadAllText($html, [Text.Encoding]::UTF8)
if (-not $h.Contains('js/vistas.js')) {
    $h = $h.Replace('<script src="js/juego.js"></script>',
                    '<script src="js/juego.js"></script>' + "`r`n" + '<script src="js/vistas.js"></script>')
    [IO.File]::WriteAllText($html, $h, (New-Object Text.UTF8Encoding($false)))
}

Write-Host ""
Write-Host ("js\juego.js : {0:N0} lineas" -f $resto.Count)
Write-Host ("js\vistas.js: {0:N0} lineas" -f ($cab.Count + $cuerpo.Count))
