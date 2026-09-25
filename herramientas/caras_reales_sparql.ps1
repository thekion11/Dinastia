# ============================================================================
#  CARAS REALES, TERCERA PASADA: UNA CONSULTA POR PAIS EN VEZ DE MILES
# ============================================================================
#  Las dos pasadas anteriores preguntaban jugador por jugador
#  (`wbsearchentities` + `wbgetentities` por cada candidato): hasta 24
#  llamadas por futbolista, 25.000 en total. Wikidata empezo a devolver 429
#  (Too Many Requests) y practicamente todo fallaba, incluso esperando 2,6 s
#  entre llamadas.
#
#  El enfoque correcto es al reves: **traer de golpe TODOS los futbolistas de
#  un pais que tengan foto** con una sola consulta SPARQL, y cruzar los
#  nombres AQUI, en local. Son ~40 consultas en total en vez de 25.000.
#
#  Ademas cruza por nombre NORMALIZADO (sin acentos, sin mayusculas), que es
#  justo lo que hacia fallar la busqueda literal: "Nicolas Zuniga" encuentra
#  lo que "Nicolás Zúñiga" no siempre encontraba.
#
#    powershell -ExecutionPolicy Bypass -File herramientas\caras_reales_sparql.ps1
# ============================================================================
$raiz = "C:\Users\Alumno\Desktop\Proyecto x"
$reportePath = "$raiz\dinastia-godot\datos\caras_reales_reporte.json"
$carpetaFotos = "$raiz\dinastia-godot\recursos\caras_reales"
$logPath = "$raiz\herramientas\caras_reales_sparql_log.txt"

$headers = @{
    "User-Agent" = "DinastiaFutbolManagerBot/1.0 (proyecto personal de aficionado, uso no comercial)"
    "Accept" = "application/sparql-results+json"
}
$headersDescarga = @{ "User-Agent" = "DinastiaFutbolManagerBot/1.0 (proyecto personal de aficionado, uso no comercial)" }

# Los mismos codigos de pais del juego -> entidad de Wikidata.
$paisWikidata = @{
    "CHI"="Q298"; "ARG"="Q414"; "ESP"="Q29"; "BRA"="Q155"; "FRA"="Q142"
    "ENG"="Q145"; "GER"="Q183"; "URU"="Q77"; "BEL"="Q31"; "NED"="Q55"
    "POL"="Q36"; "TUR"="Q43"; "SVN"="Q215"; "SVK"="Q214"; "NOR"="Q20"
    "GHA"="Q117"; "JPN"="Q17"; "CRO"="Q224"; "COL"="Q739"; "COD"="Q974"
    "PAR"="Q733"; "PER"="Q419"; "MEX"="Q96"; "ITA"="Q38"; "POR"="Q45"
    "USA"="Q30"; "CAN"="Q16"; "ECU"="Q736"; "BOL"="Q750"; "VEN"="Q717"
    "CRC"="Q800"; "SEN"="Q1041"; "MAR"="Q1028"; "NGA"="Q1033"; "CIV"="Q1008"
    "SUI"="Q39"; "AUT"="Q40"; "DEN"="Q35"; "SWE"="Q34"; "SCO"="Q145"
    "MKD"="Q221"; "PHI"="Q928"; "GUI"="Q1006"; "WAL"="Q25"; "IRL"="Q27"
    "GRE"="Q41"; "RUS"="Q159"; "UKR"="Q212"; "CZE"="Q213"; "ROU"="Q218"
    # Segunda tanda: los que la primera corrida reporto como "pais sin
    # mapear". Cada uno son decenas de caras que se estaban perdiendo por no
    # tener una linea aqui.
    "ALB"="Q222"; "ALG"="Q262"; "ANG"="Q916"; "BIH"="Q225"; "CMR"="Q1009"
    "EGY"="Q79"; "GNB"="Q1007"; "HAI"="Q790"; "HUN"="Q28"; "ISR"="Q801"
    "JAM"="Q766"; "JOR"="Q810"; "KOS"="Q1246"; "KVX"="Q1246"; "MLI"="Q912"
    "PAL"="Q219060"; "SLV"="Q792"; "SRB"="Q403"; "SYR"="Q858"; "TOG"="Q945"
    "TUN"="Q948"; "ZIM"="Q954"
}

function Log($m) { Add-Content -Path $logPath -Value "$(Get-Date -Format 'HH:mm:ss')  $m" }

function Normalizar($t) {
    $n = $t.Normalize([Text.NormalizationForm]::FormD)
    $sb = New-Object Text.StringBuilder
    foreach ($ch in $n.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($ch)
        }
    }
    return ($sb.ToString().ToLower() -replace '[^a-z0-9 ]', '').Trim()
}

Add-Type -AssemblyName System.Web.Extensions
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue
$reporte = New-Object System.Collections.Generic.List[object]
foreach ($r in $ser.DeserializeObject((Get-Content -Raw -Path $reportePath -Encoding UTF8))) {
    $reporte.Add([PSCustomObject]$r)
}
function Guardar() { $reporte | ConvertTo-Json -Depth 4 | Set-Content -Path $reportePath -Encoding utf8 }

# Los que siguen sin foto, agrupados por pais: solo hay que consultar los
# paises que de verdad tienen a alguien pendiente.
$pendientes = @($reporte | Where-Object { -not $_.encontrado })
Log "Sin foto: $($pendientes.Count)"
Write-Host "Sin foto: $($pendientes.Count)" -ForegroundColor Cyan

$porPais = @{}
foreach ($p in $pendientes) {
    $k = [string]$p.pais
    if (-not $porPais.ContainsKey($k)) { $porPais[$k] = New-Object System.Collections.Generic.List[object] }
    $porPais[$k].Add($p)
}

$nuevos = 0
foreach ($pais in $porPais.Keys) {
    $qid = $paisWikidata[$pais]
    if (-not $qid) { Log "pais sin mapear: $pais"; continue }
    $lista = $porPais[$pais]
    Write-Host "$pais : $($lista.Count) pendientes..." -ForegroundColor Yellow

    # UNA consulta: todos los futbolistas de ese pais que tengan foto, con su
    # etiqueta en espanol o en ingles (la que haya).
    $sparql = @"
SELECT ?nombreEs ?nombreEn ?img WHERE {
  ?p wdt:P106 wd:Q937857 ; wdt:P27 wd:$qid ; wdt:P18 ?img .
  OPTIONAL { ?p rdfs:label ?nombreEs . FILTER(LANG(?nombreEs)="es") }
  OPTIONAL { ?p rdfs:label ?nombreEn . FILTER(LANG(?nombreEn)="en") }
}
"@
    $url = "https://query.wikidata.org/sparql?format=json&query=" + [uri]::EscapeDataString($sparql)
    $res = $null
    for ($i = 0; $i -lt 3; $i++) {
        try { $res = Invoke-RestMethod -Uri $url -Headers $headers -TimeoutSec 180; break }
        catch { Log "SPARQL $pais intento $($i+1): $($_.Exception.Message)"; Start-Sleep -Seconds 10 }
    }
    if (-not $res) { continue }

    # Indice local: nombre normalizado -> url de imagen.
    $indice = @{}
    foreach ($b in $res.results.bindings) {
        foreach ($campo in @("nombreEs", "nombreEn")) {
            $v = $b.$campo
            if ($v -and $v.value) {
                $k = Normalizar $v.value
                if ($k -and -not $indice.ContainsKey($k)) { $indice[$k] = $b.img.value }
            }
        }
    }
    Log "$pais : $($indice.Count) futbolistas con foto en Wikidata"

    foreach ($fila in $lista) {
        $clave = Normalizar ([string]$fila.nombre)
        if (-not $indice.ContainsKey($clave)) { continue }
        $urlImg = $indice[$clave]
        try {
            # El nombre del archivo en Commons sale de la propia URL.
            $archivo = [System.IO.Path]::GetFileName([uri]::UnescapeDataString($urlImg))
            $qf = [uri]::EscapeDataString("File:" + $archivo)
            $info = Invoke-RestMethod -Headers $headersDescarga -TimeoutSec 60 `
                -Uri "https://commons.wikimedia.org/w/api.php?action=query&titles=$qf&prop=imageinfo&iiprop=url|extmetadata|size&iiurlwidth=400&format=json"
            Start-Sleep -Milliseconds 900
            $pagina = $info.query.pages.PSObject.Properties.Value | Select-Object -First 1
            if (-not $pagina.imageinfo) { continue }
            $ii = $pagina.imageinfo[0]
            $lic = $ii.extmetadata.LicenseShortName.value
            if ($lic -notmatch "^(CC |CC0|Public domain|PD)") {
                $fila.nota = "licencia no libre (sparql)"
                continue
            }
            $urlDescarga = if ($ii.thumburl) { $ii.thumburl } else { $ii.url }
            $ext = [System.IO.Path]::GetExtension($urlDescarga)
            if ($ext.Length -eq 0 -or $ext.Length -gt 5) { $ext = ".jpg" }
            $slug = ([string]$fila.nombre -replace '[^\w]+','_').Trim('_')
            $destino = Join-Path $carpetaFotos "$slug$ext"
            Invoke-WebRequest -Uri $urlDescarga -Headers $headersDescarga -OutFile $destino -ErrorAction Stop
            Start-Sleep -Milliseconds 600
            $fila.encontrado = $true
            $fila.licencia = $lic
            $fila.autor = $ii.extmetadata.Artist.value -replace '<[^>]+>',''
            $fila.ancho = $ii.width
            $fila.alto = $ii.height
            $fila.archivo = "recursos/caras_reales/$slug$ext"
            $fila.nota = "rescatada por sparql"
            $nuevos++
            Log "OK $($fila.nombre)"
        } catch {
            Log "error bajando $($fila.nombre): $($_.Exception.Message)"
        }
    }
    Guardar
    Write-Host "  $pais listo. Nuevas hasta ahora: $nuevos" -ForegroundColor Green
    Start-Sleep -Seconds 3
}
Guardar
Log "TERMINADO. $nuevos caras nuevas."
Write-Host "TERMINADO. $nuevos caras nuevas." -ForegroundColor Green
