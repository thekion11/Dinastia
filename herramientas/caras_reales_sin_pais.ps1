# ============================================================================
#  CARAS REALES, ULTIMA PASADA: POR NOMBRE, SIN MIRAR EL PAIS
# ============================================================================
#  Tras la pasada por pais quedan ~900 sin foto. Una parte grande de esos NO
#  es que no tengan retrato libre: es que su nacionalidad en Wikidata no es la
#  que el juego les asigna -doble nacionalidad, nacidos fuera, naturalizados-,
#  asi que la consulta "futbolistas de Chile" nunca los vio.
#
#  Aqui se pregunta al reves: se mandan los nombres EN LOTES con `VALUES` y se
#  pide cualquier futbolista con foto que se llame asi, venga de donde venga.
#  Son ~10 consultas para 900 nombres.
#
#  El riesgo de esto es el homonimo -dos futbolistas con el mismo nombre-, y
#  se asume a conciencia: es preferible la foto de otro "Diego Fernandez" que
#  un dibujo generico, y el propio HTML ya trabaja con nombres como clave.
#
#    powershell -ExecutionPolicy Bypass -File herramientas\caras_reales_sin_pais.ps1
# ============================================================================
$raiz = "C:\Users\Alumno\Desktop\Proyecto x"
$reportePath = "$raiz\dinastia-godot\datos\caras_reales_reporte.json"
$carpetaFotos = "$raiz\dinastia-godot\recursos\caras_reales"
$logPath = "$raiz\herramientas\caras_reales_sin_pais_log.txt"

$headers = @{
    "User-Agent" = "DinastiaFutbolManagerBot/1.0 (proyecto personal de aficionado, uso no comercial)"
    "Accept" = "application/sparql-results+json"
}
$headersDescarga = @{ "User-Agent" = "DinastiaFutbolManagerBot/1.0 (proyecto personal de aficionado, uso no comercial)" }

function Log($m) { Add-Content -Path $logPath -Value "$(Get-Date -Format 'HH:mm:ss')  $m" }

Add-Type -AssemblyName System.Web.Extensions
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue
$reporte = New-Object System.Collections.Generic.List[object]
foreach ($r in $ser.DeserializeObject((Get-Content -Raw -Path $reportePath -Encoding UTF8))) {
    $reporte.Add([PSCustomObject]$r)
}
function Guardar() { $reporte | ConvertTo-Json -Depth 4 | Set-Content -Path $reportePath -Encoding utf8 }

$pendientes = @($reporte | Where-Object { -not $_.encontrado })
Log "Sin foto al empezar: $($pendientes.Count)"
Write-Host "Sin foto al empezar: $($pendientes.Count)" -ForegroundColor Cyan

$LOTE = 90
$nuevos = 0
for ($inicio = 0; $inicio -lt $pendientes.Count; $inicio += $LOTE) {
    $fin = [Math]::Min($inicio + $LOTE - 1, $pendientes.Count - 1)
    $lote = $pendientes[$inicio..$fin]

    # VALUES con los nombres tal cual, etiquetados en es y en en: Wikidata
    # busca la etiqueta exacta, asi que se mandan los dos idiomas.
    $valores = ""
    foreach ($p in $lote) {
        $limpio = ([string]$p.nombre) -replace '"', ''
        $valores += " `"$limpio`"@es `"$limpio`"@en"
    }
    $sparql = @"
SELECT ?nombre ?img WHERE {
  VALUES ?nombre {$valores}
  ?p rdfs:label ?nombre ; wdt:P106 wd:Q937857 ; wdt:P18 ?img .
}
"@
    $url = "https://query.wikidata.org/sparql?format=json&query=" + [uri]::EscapeDataString($sparql)
    $res = $null
    for ($i = 0; $i -lt 3; $i++) {
        try { $res = Invoke-RestMethod -Uri $url -Headers $headers -TimeoutSec 180; break }
        catch { Log "SPARQL lote $inicio intento $($i+1): $($_.Exception.Message)"; Start-Sleep -Seconds 12 }
    }
    if (-not $res) { continue }

    $indice = @{}
    foreach ($b in $res.results.bindings) {
        $k = [string]$b.nombre.value
        if (-not $indice.ContainsKey($k)) { $indice[$k] = $b.img.value }
    }
    Log "lote $inicio-$fin : $($indice.Count) con foto"
    Write-Host "lote $inicio-$fin : $($indice.Count) con foto" -ForegroundColor Yellow

    foreach ($fila in $lote) {
        $nombre = [string]$fila.nombre
        if (-not $indice.ContainsKey($nombre)) { continue }
        try {
            $archivo = [System.IO.Path]::GetFileName([uri]::UnescapeDataString($indice[$nombre]))
            $qf = [uri]::EscapeDataString("File:" + $archivo)
            $info = Invoke-RestMethod -Headers $headersDescarga -TimeoutSec 60 `
                -Uri "https://commons.wikimedia.org/w/api.php?action=query&titles=$qf&prop=imageinfo&iiprop=url|extmetadata|size&iiurlwidth=400&format=json"
            Start-Sleep -Milliseconds 900
            $pagina = $info.query.pages.PSObject.Properties.Value | Select-Object -First 1
            if (-not $pagina.imageinfo) { continue }
            $ii = $pagina.imageinfo[0]
            $lic = $ii.extmetadata.LicenseShortName.value
            if ($lic -notmatch "^(CC |CC0|Public domain|PD)") { continue }
            $urlDescarga = if ($ii.thumburl) { $ii.thumburl } else { $ii.url }
            $ext = [System.IO.Path]::GetExtension($urlDescarga)
            if ($ext.Length -eq 0 -or $ext.Length -gt 5) { $ext = ".jpg" }
            $slug = ($nombre -replace '[^\w]+','_').Trim('_')
            $destino = Join-Path $carpetaFotos "$slug$ext"
            Invoke-WebRequest -Uri $urlDescarga -Headers $headersDescarga -OutFile $destino -ErrorAction Stop
            Start-Sleep -Milliseconds 600
            $fila.encontrado = $true
            $fila.licencia = $lic
            $fila.autor = $ii.extmetadata.Artist.value -replace '<[^>]+>',''
            $fila.archivo = "recursos/caras_reales/$slug$ext"
            $fila.nota = "rescatada sin filtro de pais"
            $nuevos++
            Log "OK $nombre"
        } catch {
            Log "error bajando $nombre : $($_.Exception.Message)"
        }
    }
    Guardar
    Start-Sleep -Seconds 2
}
Guardar
Log "TERMINADO. $nuevos caras nuevas."
Write-Host "TERMINADO. $nuevos caras nuevas." -ForegroundColor Green
