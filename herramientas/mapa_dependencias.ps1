# ============================================================================
#  MAPA DE DEPENDENCIAS DE js\juego.js
# ============================================================================
#  Sirve para decidir CON DATOS como trocear el motor en modulos, en vez de
#  cortar por rangos de lineas y esperar que salga bien.
#
#  LO QUE HAY QUE ENTENDER ANTES DE MOVER UNA SOLA LINEA
#
#  · Las declaraciones `function f(){}` se IZAN (hoisting): existen en cuanto el
#    fichero que las contiene se ha ejecutado, sin importar el orden dentro de
#    el. Por eso se pueden repartir entre ficheros con libertad.
#  · Los `const` y `let` de primer nivel NO se izan de forma utilizable: usarlos
#    antes de su linea lanza ReferenceError. Su ORDEN es sagrado.
#  · Y lo mas peligroso: el CODIGO EJECUTABLE de primer nivel (una llamada
#    suelta, un addEventListener, un bucle que rellena una tabla) corre en el
#    momento exacto en que el navegador llega a esa linea. Si ese codigo llama a
#    una funcion que se ha movido a un fichero POSTERIOR, revienta al cargar.
#
#  Por eso este script separa tres cosas: declaraciones de funcion, constantes y
#  sentencias ejecutables sueltas. Las dos ultimas son las que atan el orden.
#
#  Uso:  .\mapa_dependencias.ps1
# ============================================================================
$raiz   = Split-Path -Parent $PSScriptRoot
$js     = Join-Path $raiz "js\juego.js"
$salida = Join-Path $PSScriptRoot "salida"
if (-not (Test-Path $salida)) { New-Item -ItemType Directory -Path $salida -Force | Out-Null }
$informe = Join-Path $salida "mapa_dependencias.txt"

$lineas = [IO.File]::ReadAllLines($js, [Text.Encoding]::UTF8)
$log = New-Object Collections.Generic.List[string]
function Anota([string]$s) { $log.Add($s) }

# --- 1. clasificar cada linea de PRIMER NIVEL --------------------------------
# Primer nivel = profundidad de llaves 0 al empezar la linea. Se lleva la cuenta
# de llaves ignorando las que van dentro de cadenas o comentarios de bloque, que
# en este fichero son muchas (plantillas HTML con { } por todas partes).
$prof = 0; $enBloque = $false
$funcs = New-Object Collections.Generic.List[object]
$consts = New-Object Collections.Generic.List[object]
$sueltas = New-Object Collections.Generic.List[object]
$actual = $null

for ($i = 0; $i -lt $lineas.Count; $i++) {
    $l = $lineas[$i]
    $profInicio = $prof

    # limpiar cadenas y comentarios para contar llaves de verdad
    $limpia = $l
    if ($enBloque) {
        if ($limpia -match '\*/') { $limpia = $limpia.Substring($limpia.IndexOf('*/') + 2); $enBloque = $false }
        else { $limpia = '' }
    }
    $limpia = [Regex]::Replace($limpia, '/\*.*?\*/', '')
    if ($limpia -match '/\*') { $limpia = $limpia.Substring(0, $limpia.IndexOf('/*')); $enBloque = $true }
    $limpia = [Regex]::Replace($limpia, '//.*$', '')
    $limpia = [Regex]::Replace($limpia, "'(\\.|[^'\\])*'", "''")
    $limpia = [Regex]::Replace($limpia, '"(\\.|[^"\\])*"', '""')
    $limpia = [Regex]::Replace($limpia, '`(\\.|[^`\\])*`', '``')

    # Se detecta el primer nivel por la COLUMNA 0, no llevando la cuenta de
    # llaves. Contarlas se probo primero y se desvia: son 20.700 lineas llenas de
    # plantillas HTML con llaves dentro de cadenas, y basta un caso raro para que
    # el contador no vuelva a cero nunca y 550 funciones de primer nivel pasen por
    # anidadas. Este fichero escribe SIEMPRE en la columna 0 lo que es global,
    # asi que esa convencion es una senal mas fiable que el analisis.
    if ($l.Length -gt 0 -and $l[0] -ne ' ' -and $l[0] -ne "`t" -and $limpia.Trim() -ne '') {
        $t = $limpia.Trim()
        if ($t -match '^function\s+([A-Za-z_$][A-Za-z0-9_$]*)') {
            $actual = [PSCustomObject]@{ Nombre = $Matches[1]; Ini = $i + 1; Fin = 0 }
            $funcs.Add($actual)
        }
        elseif ($t -match '^(const|let|var)\s+([A-Za-z_$][A-Za-z0-9_$]*)') {
            $consts.Add([PSCustomObject]@{ Nombre = $Matches[2]; Linea = $i + 1; Tipo = $Matches[1] })
        }
        elseif ($t -notmatch '^[})\];]' -and $t -notmatch '^(class|if|for|while|try|else|switch|do)\b') {
            # sentencia ejecutable suelta: una llamada, una asignacion a algo ya
            # existente, un addEventListener... Son las que fijan el orden.
            $sueltas.Add([PSCustomObject]@{ Linea = $i + 1; Texto = $t.Substring(0, [Math]::Min(120, $t.Length)) })
        }
    }

    $prof += ([Regex]::Matches($limpia, '\{')).Count
    $prof -= ([Regex]::Matches($limpia, '\}')).Count
    if ($prof -lt 0) { $prof = 0 }
    # el final de una funcion de primer nivel es la linea "}" en columna 0
    if ($actual -and $actual.Fin -eq 0 -and $l -eq "}") { $actual.Fin = $i + 1 }
}

Anota "MAPA DE DEPENDENCIAS - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Anota ("=" * 78)
Anota ""
Anota ("funciones de primer nivel : {0}" -f $funcs.Count)
Anota ("constantes de primer nivel: {0}" -f $consts.Count)
Anota ("SENTENCIAS SUELTAS        : {0}   <-- estas son las que atan el orden" -f $sueltas.Count)
Anota ""
Anota "SENTENCIAS EJECUTABLES DE PRIMER NIVEL"
Anota "  (cualquier funcion que estas llamen tiene que estar definida ANTES,"
Anota "   o sea en el mismo fichero o en uno cargado antes)"
foreach ($s in $sueltas) { Anota ("   linea {0,-7} {1}" -f $s.Linea, $s.Texto) }
Anota ""

# --- 2. que funciones llaman esas sentencias --------------------------------
$nombres = @{}
foreach ($f in $funcs) { $nombres[$f.Nombre] = $true }
$atadas = @{}
foreach ($s in $sueltas) {
    foreach ($m in [Regex]::Matches($s.Texto, '([A-Za-z_$][A-Za-z0-9_$]*)\s*\(')) {
        $n = $m.Groups[1].Value
        if ($nombres.ContainsKey($n)) { $atadas[$n] = $true }
    }
}
Anota ("FUNCIONES LLAMADAS DESDE CODIGO DE CARGA: {0}" -f $atadas.Count)
Anota ("   {0}" -f (($atadas.Keys | Sort-Object) -join ", "))
Anota ""

# --- 3. el grupo de VISTAS ---------------------------------------------------
# Las funciones v* son la capa de interfaz: devuelven HTML y las llama render().
# Es el unico grupo grande y cohesionado que tiene el fichero, asi que es el
# primer candidato natural a salir a un modulo propio.
$vistas = $funcs | Where-Object { $_.Nombre -cmatch '^v[A-Z]' }
$lineasVistas = 0
foreach ($v in $vistas) { if ($v.Fin -gt $v.Ini) { $lineasVistas += ($v.Fin - $v.Ini + 1) } }
Anota ("GRUPO DE VISTAS (v*): {0} funciones, {1:N0} lineas" -f $vistas.Count, $lineasVistas)
$vAtadas = $vistas | Where-Object { $atadas.ContainsKey($_.Nombre) }
Anota ("   de esas, llamadas desde codigo de carga: {0}" -f $vAtadas.Count)
foreach ($v in $vAtadas) { Anota ("      {0}" -f $v.Nombre) }
Anota ""
foreach ($v in ($vistas | Sort-Object Nombre)) {
    Anota ("   {0,-28} lineas {1}-{2}" -f $v.Nombre, $v.Ini, $v.Fin)
}

[IO.File]::WriteAllText($informe, ($log -join "`r`n"), (New-Object Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "MAPA DE DEPENDENCIAS" -ForegroundColor Cyan
Write-Host ("  funciones de primer nivel : {0}" -f $funcs.Count)
Write-Host ("  constantes de primer nivel: {0}" -f $consts.Count)
Write-Host ("  sentencias sueltas        : {0}" -f $sueltas.Count) -ForegroundColor Yellow
Write-Host ("  funciones atadas al orden : {0}" -f $atadas.Count) -ForegroundColor Yellow
Write-Host ("  grupo de vistas (v*)      : {0} funciones, {1:N0} lineas" -f $vistas.Count, $lineasVistas) -ForegroundColor Green
Write-Host ""
Write-Host "informe: $informe"
