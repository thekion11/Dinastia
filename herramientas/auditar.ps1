# ============================================================================
#  AUDITORIA DEL CODIGO DE DINASTIA
# ============================================================================
#  Mide el estado real del codigo en vez de opinar sobre el. Saca un informe a
#  herramientas\salida\auditoria.txt y devuelve lo importante por pantalla.
#
#  Que busca, y por que cada cosa importa:
#
#   1. FUNCIONES DUPLICADAS. En JavaScript declarar dos veces la misma funcion
#      NO da error: la segunda pisa a la primera y la primera queda muerta. Es
#      la causa mas probable de "esta en el codigo pero no se ve en el juego",
#      y no la detecta ninguna prueba porque el juego no falla, solo hace otra
#      cosa. Es el hallazgo mas valioso de toda la auditoria.
#   2. FUNCIONES NUNCA LLAMADAS. Codigo muerto que hay que borrar o conectar.
#      Ojo: las que se llaman desde un onclick="" del HTML cuentan como usadas.
#   3. FUNCIONES DEMASIADO LARGAS. Una funcion de 300 lineas no se puede probar
#      ni entender; es donde se esconden los fallos.
#   4. PROFUNDIDAD DE ANIDAMIENTO. Cinco niveles de if dentro de for dentro de
#      if es donde el codigo deja de ser mantenible.
#   5. NUMEROS MAGICOS Y TODOs, para saber que queda a medias.
#
#  Uso:  .\auditar.ps1  [-Detalle]
# ============================================================================
param([switch]$Detalle)

$raiz    = Split-Path -Parent $PSScriptRoot
# El motor salio del HTML a js\juego.js (v3.31). Se auditan los dos: el HTML
# porque ahi viven los onclick que enganchan media interfaz, y el .js porque es
# donde esta el codigo. Un nombre que solo aparezca en un onclick del HTML NO es
# codigo muerto, asi que hay que mirar los dos juntos o salen falsos positivos.
# El motor se reparte ya en varios ficheros (juego.js el motor, vistas.js la
# interfaz). Se auditan TODOS los .js de js\ como un solo cuerpo, porque
# comparten ambito global: una funcion de vistas.js puede pisar a otra de
# juego.js exactamente igual que si estuvieran en el mismo fichero.
$ficherosJs = Get-ChildItem (Join-Path $raiz "js") -Filter *.js | Sort-Object Name
$paginaHtml = Join-Path $raiz "dinastia-futbol-manager base.html"
$salida  = Join-Path $PSScriptRoot "salida"
if (-not (Test-Path $salida)) { New-Item -ItemType Directory -Path $salida -Force | Out-Null }
$informe = Join-Path $salida "auditoria.txt"

if (-not $ficherosJs) { Write-Host "No encuentro ningun .js en js\" -ForegroundColor Red; exit 1 }

# Se concatenan en el mismo orden en que los carga el HTML, para que los numeros
# de linea del informe se puedan seguir fichero a fichero.
$texto = ""
$origen = New-Object Collections.Generic.List[string]
foreach ($f in $ficherosJs) {
    $c = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8)
    $texto += $c + "`n"
    foreach ($l in ($c -split "`r?`n")) { $origen.Add($f.Name) }
}
$textoBusqueda = $texto + "`n" + ([IO.File]::ReadAllText($paginaHtml, [Text.Encoding]::UTF8))
$lineas = $texto -split "`r?`n"
$log    = New-Object Collections.Generic.List[string]
function Anota([string]$s) { $log.Add($s); if ($Detalle) { Write-Host $s } }

Anota "AUDITORIA DE DINASTIA - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Anota ("=" * 78)
Anota ""
Anota "TAMANO"
foreach ($f in $ficherosJs) { Anota ("  js\{0,-12} {1,10:N0} bytes" -f $f.Name, $f.Length) }
Anota ("  TOTAL js:      {0:N0} bytes, {1:N0} lineas" -f $texto.Length, $lineas.Count)
Anota ("  pagina HTML: {0:N0} bytes" -f (Get-Item $paginaHtml).Length)

# --- inventario de funciones -------------------------------------------------
# Se recogen tanto las declaradas a nivel de raiz (^function x) como las
# anidadas, porque una duplicada anidada tapa igual a la de fuera.
$decl = @{}       # nombre -> lista de numeros de linea
for ($i = 0; $i -lt $lineas.Count; $i++) {
    $m = [Regex]::Match($lineas[$i], '^\s*function\s+([A-Za-z_$][A-Za-z0-9_$]*)\s*\(')
    if ($m.Success) {
        $n = $m.Groups[1].Value
        if (-not $decl.ContainsKey($n)) { $decl[$n] = New-Object Collections.Generic.List[int] }
        $decl[$n].Add($i + 1)
    }
}
Anota ("  funciones declaradas: {0}" -f $decl.Count)
Anota ""

# --- 1. duplicadas -----------------------------------------------------------
$dup = $decl.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 } | Sort-Object Name
Anota "1) FUNCIONES DECLARADAS MAS DE UNA VEZ  (la ultima gana; las anteriores son codigo muerto)"
if ($dup.Count -eq 0) { Anota "   ninguna" }
else { foreach ($d in $dup) { Anota ("   {0,-28} lineas {1}" -f $d.Name, ($d.Value -join ", ")) } }
Anota ""

# --- 2. nunca llamadas -------------------------------------------------------
# Se cuenta cada aparicion del nombre en todo el fichero. Si solo aparece en su
# propia declaracion, nadie la usa. Se cuentan tambien los onclick del HTML
# porque ahi es donde el juego engancha media interfaz.
$muertas = New-Object Collections.Generic.List[string]
foreach ($n in $decl.Keys) {
    # OJO: \b no sirve si el nombre acaba en $ (por ejemplo esc$), porque $ no es
    # caracter de palabra y el limite nunca casa: la funcion salia como "nunca
    # llamada" siendo de las mas usadas del juego. Se pone el limite a mano.
    $e = [Regex]::Escape($n)
    $usos = ([Regex]::Matches($textoBusqueda, "(?<![A-Za-z0-9_`$])$e(?![A-Za-z0-9_])")).Count
    if ($usos -le $decl[$n].Count) { $muertas.Add(("{0} (linea {1})" -f $n, $decl[$n][0])) }
}
Anota ("2) FUNCIONES QUE NADIE LLAMA: {0}" -f $muertas.Count)
foreach ($m in ($muertas | Sort-Object)) { Anota ("   $m") }
Anota ""

# --- 3. funciones largas -----------------------------------------------------
# Se mide contando llaves desde la declaracion hasta que se cierra el bloque.
$largas = New-Object Collections.Generic.List[object]
foreach ($n in $decl.Keys) {
    foreach ($ln in $decl[$n]) {
        $prof = 0; $fin = $ln; $abierto = $false
        for ($i = $ln - 1; $i -lt [Math]::Min($lineas.Count, $ln + 1200); $i++) {
            $l = $lineas[$i]
            $prof += ([Regex]::Matches($l, '\{')).Count
            $prof -= ([Regex]::Matches($l, '\}')).Count
            if (-not $abierto -and $prof -gt 0) { $abierto = $true }
            if ($abierto -and $prof -le 0) { $fin = $i + 1; break }
        }
        $largo = $fin - $ln + 1
        if ($largo -ge 120) { $largas.Add([PSCustomObject]@{ Nombre = $n; Linea = $ln; Lineas = $largo }) }
    }
}
$largas = $largas | Sort-Object Lineas -Descending
Anota ("3) FUNCIONES DE 120 LINEAS O MAS: {0}" -f $largas.Count)
foreach ($f in $largas) { Anota ("   {0,-30} linea {1,-6} {2} lineas" -f $f.Nombre, $f.Linea, $f.Lineas) }
Anota ""

# --- 4. TODOs y pendientes ---------------------------------------------------
$todos = @()
for ($i = 0; $i -lt $lineas.Count; $i++) {
    # OJO CON EL FILTRO: la primera version buscaba "TODO" a secas y daba 244
    # resultados... todos falsos. El codigo y los textos del juego estan en
    # espanol, y "TODO"/"TODOS"/"falta" son palabras corrientes ("SIMULAR TODO EL
    # PARTIDO", "TODOS LOS DESAFIOS"). Un informe con 244 pendientes inventados es
    # peor que no tener informe: hace perder el tiempo buscando lo que no existe.
    # Se buscan solo las marcas de verdad, con sus dos puntos o dentro de un
    # comentario, y sensible a mayusculas.
    if ($lineas[$i] -cmatch '(TODO\s*:|FIXME|HACK\s*:|XXX\s|//\s*TODO\b|/\*\s*TODO\b|PENDIENTE\s*:)') {
        $todos += ("   linea {0}: {1}" -f ($i + 1), $lineas[$i].Trim().Substring(0, [Math]::Min(110, $lineas[$i].Trim().Length)))
    }
}
Anota ("4) MARCAS DE TRABAJO PENDIENTE: {0}" -f $todos.Count)
foreach ($t in $todos) { Anota $t }
Anota ""

# --- 5. GDScript del visor ---------------------------------------------------
Anota "5) VISOR 3D (GDScript)"
$gd = Get-ChildItem (Join-Path $raiz "visor3d\scripts") -Filter *.gd -ErrorAction SilentlyContinue
$totalGd = 0
foreach ($f in ($gd | Sort-Object Name)) {
    $n = (Get-Content $f.FullName | Measure-Object -Line).Lines
    $totalGd += $n
    # duplicadas dentro del mismo fichero: en GDScript esto SI es error de sintaxis
    $nombres = Select-String -Path $f.FullName -Pattern '^(static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)' -AllMatches |
               ForEach-Object { $_.Matches[0].Groups[2].Value }
    $rep = $nombres | Group-Object | Where-Object { $_.Count -gt 1 }
    $aviso = if ($rep) { "  <-- DUPLICADAS: " + (($rep | ForEach-Object { $_.Name }) -join ", ") } else { "" }
    Anota ("   {0,-26} {1,5} lineas{2}" -f $f.Name, $n, $aviso)
}
Anota ("   total GDScript: {0:N0} lineas en {1} ficheros" -f $totalGd, $gd.Count)

[IO.File]::WriteAllText($informe, ($log -join "`r`n"), (New-Object Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "RESUMEN" -ForegroundColor Cyan
Write-Host ("  funciones JS:            {0}" -f $decl.Count)
Write-Host ("  DUPLICADAS (codigo muerto): {0}" -f $dup.Count) -ForegroundColor $(if ($dup.Count) { "Yellow" } else { "Green" })
Write-Host ("  nunca llamadas:          {0}" -f $muertas.Count) -ForegroundColor $(if ($muertas.Count) { "Yellow" } else { "Green" })
Write-Host ("  de 120+ lineas:          {0}" -f $largas.Count) -ForegroundColor $(if ($largas.Count -gt 10) { "Yellow" } else { "Green" })
Write-Host ("  marcas de pendiente:     {0}" -f $todos.Count)
Write-Host ("  GDScript:                {0:N0} lineas en {1} ficheros" -f $totalGd, $gd.Count)
Write-Host ""
Write-Host "informe completo: $informe"
