# ============================================================================
#  AUDITORIA DEL CODIGO EN GODOT (12-9-2026)
# ============================================================================
#  `auditar.ps1` audita js\ y la pagina HTML -el motor VIEJO- y en su seccion 5
#  solo mira `visor3d\scripts`, que tambien es el proyecto viejo: desde que el
#  juego se porto entero a Godot (ver dinastia-migracion-godot.md), el juego DE
#  VERDAD es `dinastia-godot\{ui,nucleo,visor}`, y esa carpeta paso de 4.451
#  lineas a **54.918** sin que ninguna auditoria la mirase. Este script audita
#  el proyecto activo. No reemplaza al viejo -sigue siendo la unica auditoria
#  de js\, y esa historia importa por "portar, no reescribir"-, es su
#  complemento para el codigo que de verdad compila el juego hoy.
#
#  GDScript no usa llaves: un bloque se cierra por INDENTACION, no por `}`. Por
#  eso la deteccion de "funcion larga" es distinta a la de auditar.ps1 -no se
#  puede reusar el contador de llaves-: se mide hasta la siguiente linea con
#  indentacion igual o menor a la de `func` que no sea vacia ni comentario.
#
#  Uso:  .\auditar_godot.ps1  [-Detalle]
# ============================================================================
param([switch]$Detalle)

$raiz    = Split-Path -Parent $PSScriptRoot
$proyecto = Join-Path $raiz "dinastia-godot"
$carpetas = @("ui", "nucleo", "visor")
$salida  = Join-Path $PSScriptRoot "salida"
if (-not (Test-Path $salida)) { New-Item -ItemType Directory -Path $salida -Force | Out-Null }
$informe = Join-Path $salida "auditoria_godot.txt"

$ficheros = @()
foreach ($c in $carpetas) {
    $p = Join-Path $proyecto $c
    if (Test-Path $p) { $ficheros += Get-ChildItem $p -Filter *.gd | Sort-Object Name }
}
if (-not $ficheros) { Write-Host "No encuentro .gd en $proyecto" -ForegroundColor Red; exit 1 }

$log = New-Object Collections.Generic.List[string]
function Anota([string]$s) { $log.Add($s); if ($Detalle) { Write-Host $s } }

Anota "AUDITORIA DE GODOT - DINASTIA - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Anota ("=" * 78)
Anota ""

# --- 1. tamano por fichero, ordenado de mayor a menor -----------------------
$info = @()
$totalLineas = 0
foreach ($f in $ficheros) {
    $lineas = [IO.File]::ReadAllLines($f.FullName)
    $totalLineas += $lineas.Count
    $info += [PSCustomObject]@{ Ruta = $f.FullName; Nombre = $f.Name; Carpeta = $f.Directory.Name; Lineas = $lineas.Count; Texto = $lineas }
}
Anota ("TAMANO: {0:N0} lineas en {1} ficheros" -f $totalLineas, $ficheros.Count)
Anota ""
Anota "LOS 15 FICHEROS MAS GRANDES (candidatos a trocear)"
foreach ($i in ($info | Sort-Object Lineas -Descending | Select-Object -First 15)) {
    Anota ("   {0,-10} {1,-30} {2,6} lineas" -f $i.Carpeta, $i.Nombre, $i.Lineas)
}
Anota ""

# --- 2. funciones declaradas dos veces EN EL MISMO AMBITO --------------------
# En GDScript esto SI es un error de sintaxis (a diferencia de JS) -PERO solo
# dentro del MISMO ambito-: un fichero puede traer una `class Interna:` con su
# propio `_init`, y eso es legal aunque el fichero ya tenga un `_init` propio a
# nivel raiz (le paso a `selecciones.gd`, con `class MundialClubes`). Agrupar
# solo por nombre daba un falso positivo. La indentacion de la palabra `func`
# es un proxy barato del ambito: dos funciones al mismo nivel de indentacion
# SI comparten ambito: si estan a niveles distintos, una esta dentro de una
# `class` anidada y no chocan.
Anota "1) FUNCIONES DUPLICADAS DENTRO DEL MISMO AMBITO (error de sintaxis en GDScript)"
$totalDup = 0
foreach ($i in $info) {
    $vistos = @{}
    foreach ($linea in $i.Texto) {
        $m = [Regex]::Match($linea, '^(\s*)(?:static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)')
        if (-not $m.Success) { continue }
        $clave = "{0}|{1}" -f $m.Groups[1].Value.Length, $m.Groups[2].Value
        if (-not $vistos.ContainsKey($clave)) { $vistos[$clave] = 0 }
        $vistos[$clave]++
    }
    $rep = $vistos.GetEnumerator() | Where-Object { $_.Value -gt 1 }
    if ($rep) {
        $totalDup += $rep.Count
        $lista = ($rep | ForEach-Object { "$($_.Name.Split('|')[1]) x$($_.Value)" }) -join ", "
        Anota ("   {0}: {1}" -f $i.Nombre, $lista)
    }
}
if ($totalDup -eq 0) { Anota "   ninguna" }
Anota ""

# --- 3. funciones largas, por INDENTACION ------------------------------------
$largas = New-Object Collections.Generic.List[object]
foreach ($i in $info) {
    $t = $i.Texto
    for ($ln = 0; $ln -lt $t.Count; $ln++) {
        $m = [Regex]::Match($t[$ln], '^(\s*)(?:static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)')
        if (-not $m.Success) { continue }
        $indentFunc = $m.Groups[1].Value.Length
        $nombre = $m.Groups[2].Value
        $fin = $t.Count
        for ($j = $ln + 1; $j -lt $t.Count; $j++) {
            $linea = $t[$j]
            if ($linea.Trim() -eq "" -or $linea.Trim().StartsWith("#")) { continue }
            # Cuenta espacios/tabs de cabecera, sin normalizar tab a N espacios:
            # el propio fichero es consistente consigo mismo (Godot fuerza tabs).
            $indentLinea = ($linea -replace '^(\s*).*', '$1').Length
            if ($indentLinea -le $indentFunc) { $fin = $j; break }
        }
        $largo = $fin - $ln
        if ($largo -ge 80) {
            $largas.Add([PSCustomObject]@{ Fichero = $i.Nombre; Nombre = $nombre; Linea = $ln + 1; Lineas = $largo })
        }
    }
}
$largas = $largas | Sort-Object Lineas -Descending
Anota ("2) FUNCIONES DE 80 LINEAS O MAS: {0}  (umbral mas bajo que en JS: en GDScript, sin llaves," -f $largas.Count)
Anota "   una funcion larga se hace dificil de leer antes)"
foreach ($f in ($largas | Select-Object -First 30)) {
    Anota ("   {0,-26} {1,-28} linea {2,-6} {3} lineas" -f $f.Fichero, $f.Nombre, $f.Linea, $f.Lineas)
}
if ($largas.Count -gt 30) { Anota ("   ... y {0} mas (ver informe completo)" -f ($largas.Count - 30)) }
Anota ""

# --- 4. marcas de trabajo pendiente ------------------------------------------
$todos = @()
foreach ($i in $info) {
    for ($j = 0; $j -lt $i.Texto.Count; $j++) {
        # SIN "#\s*TODO\b" SUELTO: esta base de código comenta en español, y los
        # comentarios de documentación (`##`) empiezan a menudo una frase con
        # "Todo" como palabra normal ("## Todo lo de abajo...", "## Todo esto
        # se apretó..."). Eso disparaba falsos positivos -la misma trampa que
        # ya se documentó para el audit de JS, pero con un patrón distinto-.
        # Solo cuentan las marcas que NINGÚN comentario normal escribiría:
        # "TODO:" con dos puntos, o FIXME/HACK/PENDIENTE.
        if ($i.Texto[$j] -cmatch '(TODO\s*:|FIXME\b|HACK\s*:|PENDIENTE\s*:)') {
            $todos += ("   {0}:{1}: {2}" -f $i.Nombre, ($j + 1), $i.Texto[$j].Trim().Substring(0, [Math]::Min(100, $i.Texto[$j].Trim().Length)))
        }
    }
}
Anota ("3) MARCAS DE TRABAJO PENDIENTE: {0}" -f $todos.Count)
foreach ($t in $todos) { Anota $t }
Anota ""

# --- 5. clases sin usar (class_name declarado, nunca referenciado) ----------
# Buscar en TODO el proyecto (no solo estas 3 carpetas), porque una clase de
# ui\ puede no citarse en nucleo\ y viceversa.
Anota "4) CLASES CON class_name QUE NADIE MENCIONA FUERA DE SU PROPIO FICHERO"
$todoElProyecto = Get-ChildItem $proyecto -Recurse -Filter *.gd -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\\.godot\\' }
$textoGlobal = ($todoElProyecto | ForEach-Object { [IO.File]::ReadAllText($_.FullName) }) -join "`n"
$clases = @{}
foreach ($f in $ficheros) {
    $m = [Regex]::Match([IO.File]::ReadAllText($f.FullName), '(?m)^class_name\s+([A-Za-z_][A-Za-z0-9_]*)')
    if ($m.Success) { $clases[$m.Groups[1].Value] = $f.Name }
}
## OJO: en este proyecto no todo se referencia por el nombre de la clase. Las
## pantallas completas se abren con `change_scene_to_file("res://escenas/x.tscn")`
## -por ruta, no por identificador-, y el .tscn engancha el script por RUTA DE
## FICHERO, no por `class_name`. Buscar solo el identificador en los .gd daba un
## falso positivo real: `EleccionClub` se usa así y el primer intento lo marcó
## como huérfano. Se cuenta tambien como uso que algun .tscn del proyecto
## apunte al propio fichero .gd.
$tscn = Get-ChildItem $proyecto -Recurse -Filter *.tscn -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\\.godot\\' }
$textoTscn = ($tscn | ForEach-Object { [IO.File]::ReadAllText($_.FullName) }) -join "`n"
$sinUso = 0
foreach ($c in $clases.Keys | Sort-Object) {
    $e = [Regex]::Escape($c)
    $usos = ([Regex]::Matches($textoGlobal, "(?<![A-Za-z0-9_])$e(?![A-Za-z0-9_])")).Count
    $nombreFichero = [Regex]::Escape($clases[$c])
    $enEscena = $textoTscn -match $nombreFichero
    if ($usos -le 1 -and -not $enEscena) { $sinUso++; Anota ("   {0,-24} (en {1})" -f $c, $clases[$c]) }
}
if ($sinUso -eq 0) { Anota "   ninguna" }
Anota ""

# --- 6. funciones que nadie parece llamar -------------------------------------
# El cheque mas ruidoso de los cinco, y a proposito el ultimo: en GDScript hay
# muchas formas legitimas de llamar algo sin que su nombre aparezca como
# identificador -`.call("nombre")` por reflexion (se uso varias veces esta
# misma sesion desde los arneses de prueba), señales conectadas por String, y
# sobre todo los CALLBACKS DEL MOTOR (_ready, _process...) que Godot llama solo
# sin que nadie los mencione nunca-. Se descartan los callbacks conocidos y se
# cuenta CUALQUIER aparicion del nombre en todo el proyecto (.gd Y .tscn), asi
# que esto es una lista de CANDIDATOS a revisar a mano, no una sentencia.
$callbacks = @(
    '_ready','_process','_physics_process','_init','_input','_unhandled_input',
    '_unhandled_key_input','_draw','_enter_tree','_exit_tree','_gui_input',
    '_notification','_to_string','_get_configuration_warnings','_validate_property',
    '_get_property_list','_set','_get'
)
$todoElTexto = $textoGlobal + "`n" + $textoTscn
$nuncaLlamadas = New-Object Collections.Generic.List[object]
foreach ($i in $info) {
    $vistos2 = @{}
    foreach ($linea in $i.Texto) {
        $m = [Regex]::Match($linea, '^\s*(?:static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)')
        if ($m.Success) { $vistos2[$m.Groups[1].Value] = $true }
    }
    foreach ($n in $vistos2.Keys) {
        if ($callbacks -contains $n) { continue }
        $e = [Regex]::Escape($n)
        ## SIN excluir lo precedido de "." -error del primer intento-: en
        ## GDScript un metodo casi siempre se llama como `objeto.nombre()`, asi
        ## que excluir el punto descartaba la forma NORMAL de llamar un metodo
        ## y disparo 332 "candidatas" que en realidad se usaban todas. El limite
        ## de palabra solo tiene que evitar pegarse a letras/digitos/guion bajo.
        $usos = ([Regex]::Matches($todoElTexto, "(?<![A-Za-z0-9_])$e(?![A-Za-z0-9_])")).Count
        if ($usos -le 1) { $nuncaLlamadas.Add([PSCustomObject]@{ Fichero = $i.Nombre; Nombre = $n }) }
    }
}
Anota ("5) FUNCIONES QUE NADIE PARECE LLAMAR (candidatas, revisar a mano -no cuenta lo que se ")
Anota ("   invoca por `.call()`/señal con nombre distinto al buscado): {0}" -f $nuncaLlamadas.Count)
foreach ($f in ($nuncaLlamadas | Sort-Object Fichero, Nombre)) {
    Anota ("   {0,-26} {1}" -f $f.Fichero, $f.Nombre)
}
Anota ""

[IO.File]::WriteAllText($informe, ($log -join "`r`n"), (New-Object Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "RESUMEN (proyecto activo: dinastia-godot)" -ForegroundColor Cyan
Write-Host ("  lineas totales:          {0:N0} en {1} ficheros" -f $totalLineas, $ficheros.Count)
Write-Host ("  DUPLICADAS en un fichero: {0}" -f $totalDup) -ForegroundColor $(if ($totalDup) { "Red" } else { "Green" })
Write-Host ("  funciones de 80+ lineas: {0}" -f $largas.Count) -ForegroundColor $(if ($largas.Count -gt 15) { "Yellow" } else { "Green" })
Write-Host ("  marcas de pendiente:     {0}" -f $todos.Count)
Write-Host ("  clases class_name sin uso externo: {0}" -f $sinUso) -ForegroundColor $(if ($sinUso) { "Yellow" } else { "Green" })
Write-Host ("  funciones candidatas a sin uso:     {0}" -f $nuncaLlamadas.Count) -ForegroundColor "Yellow"
Write-Host ""
Write-Host "informe completo: $informe"
