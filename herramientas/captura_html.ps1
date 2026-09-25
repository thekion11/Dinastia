# Captura una imagen de una pagina HTML servida en localhost, usando el
# protocolo CDP directo por WebSocket -no el flag --screenshot de Chrome, que
# en este equipo falla con "Multiple targets are not supported in headless
# mode" porque el propio Chrome instalado carga extensiones de componente
# (paginas de fondo / service workers) incluso con --user-data-dir nuevo, y
# el --screenshot de --headless=new exige que exista un solo target.
#
# Uso:
#   .\captura_html.ps1 -Url "http://localhost:5502/pagina.html" -Salida "salida\foto.png" [-Ancho 1280] [-Alto 3000] [-Puerto 9400] [-EsperaSeg 3]
param(
  [Parameter(Mandatory=$true)][string]$Url,
  [Parameter(Mandatory=$true)][string]$Salida,
  [int]$Ancho = 1280,
  [int]$Alto = 2000,
  [int]$Puerto = 9400,
  [int]$EsperaSeg = 3
)

if (-not (Split-Path -IsAbsolute $Salida)) { $Salida = Join-Path $PSScriptRoot $Salida }
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$perfil = Join-Path $env:TEMP ("dinastia_captura_html_" + [Guid]::NewGuid().ToString("N").Substring(0,8))

$proc = Start-Process -FilePath $chrome -ArgumentList @(
  "--headless=new","--disable-gpu","--remote-debugging-port=$Puerto","--user-data-dir=$perfil",
  "--window-size=$Ancho,$Alto","--disable-extensions","--disable-component-extensions-with-background-pages",
  $Url
) -PassThru

try {
  Start-Sleep -Seconds $EsperaSeg
  $targets = Invoke-RestMethod -Uri "http://localhost:$Puerto/json/list" -TimeoutSec 5
  $pageTarget = $targets | Where-Object { $_.type -eq "page" } | Select-Object -First 1
  if (-not $pageTarget) { throw "no aparecio ningun target de tipo 'page'" }
  $wsUrl = $pageTarget.webSocketDebuggerUrl

  $ws = New-Object System.Net.WebSockets.ClientWebSocket
  $ws.ConnectAsync([Uri]$wsUrl, [System.Threading.CancellationToken]::None).Wait()

  function Send-Cdp($sock, $json) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $seg = New-Object System.ArraySegment[byte] (,$bytes)
    $sock.SendAsync($seg, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [System.Threading.CancellationToken]::None).Wait()
  }
  function Receive-CdpFull($sock) {
    $sb = New-Object System.Text.StringBuilder
    $buffer = New-Object byte[] 1048576
    $seg = New-Object System.ArraySegment[byte] (,$buffer)
    do {
      $result = $sock.ReceiveAsync($seg, [System.Threading.CancellationToken]::None).Result
      $sb.Append([System.Text.Encoding]::UTF8.GetString($buffer, 0, $result.Count)) | Out-Null
    } while (-not $result.EndOfMessage)
    return $sb.ToString()
  }

  Send-Cdp $ws '{"id":1,"method":"Page.enable"}'
  Receive-CdpFull $ws | Out-Null
  Start-Sleep -Seconds 2

  Send-Cdp $ws '{"id":2,"method":"Page.captureScreenshot","params":{"format":"png"}}'
  $resp = Receive-CdpFull $ws

  $marker = '"data":"'
  $mi = $resp.IndexOf($marker)
  if ($mi -lt 0) { throw "respuesta sin 'data': $($resp.Substring(0,[Math]::Min(300,$resp.Length)))" }
  $startIdx = $mi + $marker.Length
  $endIdx = $resp.LastIndexOf('"}}')
  $b64 = $resp.Substring($startIdx, $endIdx - $startIdx)
  $bytes = [Convert]::FromBase64String($b64)
  New-Item -ItemType Directory -Force -Path (Split-Path $Salida) | Out-Null
  [System.IO.File]::WriteAllBytes($Salida, $bytes)
  Write-Output "OK  $Salida  ($($bytes.Length) bytes)"

  $ws.Dispose()
} finally {
  Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
}
