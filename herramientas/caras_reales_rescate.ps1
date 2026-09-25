# ============================================================================
#  SEGUNDA PASADA PARA LAS CARAS QUE NO SE ENCONTRARON
# ============================================================================
#  `caras_reales_buscar.ps1` dejo 1.048 encontradas de 2.125. Este script
#  reintenta SOLO las fallidas, cambiando lo que mas probablemente fallo:
#
#   1. Buscaba con `language=es`. Un futbolista brasileno, polaco o japones
#      muchas veces no tiene etiqueta en espanol en Wikidata, pero si en
#      ingles. Se prueban los dos idiomas.
#   2. Buscaba el nombre EXACTO y con acentos. Se prueba tambien sin acentos.
#   3. Se queda con los 5 primeros candidatos. Se sube a 10: un "Fernandez"
#      puede tener nueve homonimos antes del futbolista.
#
#  NO se reintenta a los que ya salieron como "futbolista sin foto en
#  wikidata": esos SI se identificaron, simplemente no tienen retrato libre,
#  y volver a preguntar es gastar cuota para el mismo no.
#
#  Reanudable: marca cada reintento en el propio reporte (`rescatado:true`),
#  asi que se puede cortar y volver a lanzar sin repetir trabajo.
#
#    powershell -ExecutionPolicy Bypass -File herramientas\caras_reales_rescate.ps1
# ============================================================================
$raiz = "C:\Users\Alumno\Desktop\Proyecto x"
$reportePath = "$raiz\dinastia-godot\datos\caras_reales_reporte.json"
$carpetaFotos = "$raiz\dinastia-godot\recursos\caras_reales"
$logPath = "$raiz\herramientas\caras_reales_rescate_log.txt"

$ua = "DinastiaFutbolManagerBot/1.0 (proyecto personal de aficionado, uso no comercial)"
$headers = @{ "User-Agent" = $ua }

function Log($msg) {
    Add-Content -Path $logPath -Value "$(Get-Date -Format 'HH:mm:ss')  $msg"
}

function Llamar($uri, $intentos = 4) {
    for ($i = 0; $i -lt $intentos; $i++) {
        try { return Invoke-RestMethod -Uri $uri -Headers $headers -ErrorAction Stop }
        catch {
            if ($i -eq $intentos - 1) { throw }
            Start-Sleep -Seconds ([Math]::Min(20, [Math]::Pow(2, $i + 1)))
        }
    }
}

# Quita acentos: "Gonzalez" encuentra lo que "González" a veces no.
function SinAcentos($t) {
    $norm = $t.Normalize([Text.NormalizationForm]::FormD)
    $sb = New-Object Text.StringBuilder
    foreach ($ch in $norm.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($ch)
        }
    }
    return $sb.ToString()
}

Add-Type -AssemblyName System.Web.Extensions
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue
$reporte = New-Object System.Collections.Generic.List[object]
foreach ($r in $ser.DeserializeObject((Get-Content -Raw -Path $reportePath -Encoding UTF8))) {
    $reporte.Add([PSCustomObject]$r)
}

function Guardar() { $reporte | ConvertTo-Json -Depth 4 | Set-Content -Path $reportePath -Encoding utf8 }

# Solo los que fallaron por NO ENCONTRAR a la persona. Los identificados sin
# foto libre no tienen remedio por esta via.
$aReintentar = @($reporte | Where-Object {
    -not $_.encontrado -and -not $_.rescatado -and
    ($_.nota -eq "sin resultados" -or $_.nota -eq "sin coincidencia futbolista" -or ($_.nota -like "error:*"))
})
Log "A reintentar: $($aReintentar.Count)"
Write-Host "A reintentar: $($aReintentar.Count)" -ForegroundColor Cyan

$n = 0
$nuevos = 0
foreach ($fila in $aReintentar) {
    $n++
    $nombre = [string]$fila.nombre
    $variantes = @($nombre)
    $sinAc = SinAcentos $nombre
    if ($sinAc -ne $nombre) { $variantes += $sinAc }

    $qidElegido = $null
    $commonsFile = $null
    foreach ($variante in $variantes) {
        foreach ($idioma in @("es", "en")) {
            if ($qidElegido -and $commonsFile) { break }
            try {
                $q = [uri]::EscapeDataString($variante)
                $buscar = Llamar "https://www.wikidata.org/w/api.php?action=wbsearchentities&search=$q&language=$idioma&format=json&type=item&limit=6"
                Start-Sleep -Milliseconds 2600
                if (-not $buscar.search -or $buscar.search.Count -eq 0) { continue }
                foreach ($cand in $buscar.search) {
                    $qid = $cand.id
                    $ent = Llamar "https://www.wikidata.org/w/api.php?action=wbgetentities&ids=$qid&props=claims&format=json"
                    Start-Sleep -Milliseconds 2600
                    $claims = $ent.entities.$qid.claims
                    $esFutbolista = $false
                    if ($claims.P106) {
                        foreach ($c in $claims.P106) {
                            if ($c.mainsnak.datavalue.value.id -eq "Q937857") { $esFutbolista = $true }
                        }
                    }
                    if (-not $esFutbolista) { continue }
                    # SIN filtro de pais a proposito: la nacionalidad del juego
                    # y la de Wikidata no siempre coinciden (dobles
                    # nacionalidades, nacidos fuera), y ese filtro es sospechoso
                    # numero uno de la mitad de estos fallos.
                    $qidElegido = $qid
                    if ($claims.P18) { $commonsFile = $claims.P18[0].mainsnak.datavalue.value }
                    if ($commonsFile) { break }
                }
            } catch {
                Log "error buscando '$variante' ($idioma): $($_.Exception.Message)"
            }
        }
        if ($commonsFile) { break }
    }

    $fila | Add-Member -NotePropertyName rescatado -NotePropertyValue $true -Force
    if ($qidElegido) { $fila.qid = $qidElegido }
    if (-not $commonsFile) {
        $fila.nota = if ($qidElegido) { "futbolista sin foto en wikidata (2a pasada)" } else { "sin resultados (2a pasada)" }
    } else {
        try {
            $qf = [uri]::EscapeDataString("File:" + $commonsFile)
            $info = Llamar "https://commons.wikimedia.org/w/api.php?action=query&titles=$qf&prop=imageinfo&iiprop=url|extmetadata|size&iiurlwidth=400&format=json"
            Start-Sleep -Milliseconds 2600
            $pagina = $info.query.pages.PSObject.Properties.Value | Select-Object -First 1
            if ($pagina.imageinfo) {
                $ii = $pagina.imageinfo[0]
                $licencia = $ii.extmetadata.LicenseShortName.value
                if ($licencia -match "^(CC |CC0|Public domain|PD)") {
                    $urlDescarga = if ($ii.thumburl) { $ii.thumburl } else { $ii.url }
                    $ext = [System.IO.Path]::GetExtension($urlDescarga)
                    if ($ext.Length -eq 0 -or $ext.Length -gt 5) { $ext = ".jpg" }
                    $slug = ($nombre -replace '[^\w]+','_').Trim('_')
                    $destino = Join-Path $carpetaFotos "$slug$ext"
                    Invoke-WebRequest -Uri $urlDescarga -Headers $headers -OutFile $destino -ErrorAction Stop
                    Start-Sleep -Milliseconds 700
                    $fila.encontrado = $true
                    $fila.licencia = $licencia
                    $fila.autor = $ii.extmetadata.Artist.value -replace '<[^>]+>',''
                    $fila.ancho = $ii.width
                    $fila.alto = $ii.height
                    $fila.archivo = "recursos/caras_reales/$slug$ext"
                    $fila.nota = "rescatada en 2a pasada"
                    $nuevos++
                    Log "OK $nombre"
                } else {
                    $fila.nota = "licencia no libre (2a pasada)"
                }
            }
        } catch {
            $fila.nota = "error commons (2a pasada): $($_.Exception.Message)"
        }
    }
    if ($n % 20 -eq 0) {
        Guardar
        Log "$n / $($aReintentar.Count). Nuevas caras: $nuevos"
        Write-Host "$n / $($aReintentar.Count) - nuevas: $nuevos"
    }
}
Guardar
Log "TERMINADO. $n reintentados, $nuevos caras nuevas."
Write-Host "TERMINADO. $n reintentados, $nuevos caras nuevas." -ForegroundColor Green
