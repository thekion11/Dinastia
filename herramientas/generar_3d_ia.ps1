# ============================================================================
#  GENERAR UN MODELO 3D CON IA (fal.ai) A PARTIR DE UN TEXTO
# ============================================================================
#    .\generar_3d_ia.ps1 -Prompt "balon de futbol de cuero clasico, blanco y negro"
#    .\generar_3d_ia.ps1 -Prompt "trofeo dorado de copa, base de marmol" -Salida "recursos\modelos3d_ia\trofeo.glb"
#
#  Llama a fal.ai (https://fal.ai) con un texto y descarga el .glb resultante.
#  Godot 4 importa .glb sin conversor -es el mismo formato que ya usan los
#  modelos de dinastia-godot/visor/-.
#
#  HACE FALTA UNA API KEY (esto NO lo puede hacer el asistente por vos):
#    1. Crear cuenta gratis en https://fal.ai
#    2. Cargar una tarjeta (el gasto de un modelo suelto es de centavos de
#       dolar, no una suscripcion mensual - ver dinastia-herramientas-3d-ia
#       en la memoria del proyecto para la comparativa completa)
#    3. Generar una key en https://fal.ai/dashboard/keys
#    4. Guardarla como variable de entorno, UNA SOLA VEZ, con:
#         setx FAL_KEY "tu_key_aqui"
#       (despues de correr eso, cerrar y volver a abrir la terminal)
#
#  EL FORMATO DE LA API (fal.ai, documentado en fal.ai/docs, 10-9-2026):
#    - Se manda el trabajo con POST a https://queue.fal.run/{modelo}
#    - Como tarda, no da la respuesta al toque: hay que preguntar cada tantos
#      segundos "?ya terminaste?" (GET .../status) hasta que diga COMPLETED
#    - Recien ahi se pide el resultado de verdad (GET .../requests/{id})
#  Los tres pasos estan escritos abajo, uno detras del otro.
# ============================================================================
param(
  [Parameter(Mandatory = $true)][string]$Prompt,
  # fal-ai/hunyuan3d-v3/text-to-3d: buena calidad, texto a 3D directo.
  # Alternativas si esta no da el resultado esperado (cambiar aca, sin tocar
  # el resto del script): "fal-ai/trellis" (mas barato, TRELLIS de Microsoft),
  # "fal-ai/hunyuan3d/v2" (v2, mas probada).
  [string]$Modelo = "fal-ai/hunyuan3d-v3/text-to-3d",
  [string]$Salida = "",
  [int]$TopeSegundos = 300
)

$clave = $env:FAL_KEY
if (-not $clave) {
  Write-Host "Falta la API key de fal.ai." -ForegroundColor Red
  Write-Host "Pasos: crear cuenta en https://fal.ai -> cargar tarjeta -> generar key en" -ForegroundColor Yellow
  Write-Host "https://fal.ai/dashboard/keys -> correr: setx FAL_KEY `"tu_key`"" -ForegroundColor Yellow
  Write-Host "y volver a abrir la terminal antes de correr esto de nuevo." -ForegroundColor Yellow
  exit 1
}

$raiz = Split-Path -Parent $PSScriptRoot
if (-not $Salida) {
  $carpeta = Join-Path $raiz "recursos\modelos3d_ia"
  $nombre = ($Prompt -replace '[^a-zA-Z0-9]+', '_').Trim('_').ToLower()
  if ($nombre.Length -gt 40) { $nombre = $nombre.Substring(0, 40) }
  $Salida = Join-Path $carpeta "$nombre-$(Get-Date -Format 'yyyyMMdd-HHmmss').glb"
} else {
  $carpeta = Split-Path -Parent $Salida
}
if ($carpeta -and -not (Test-Path $carpeta)) { New-Item -ItemType Directory -Force $carpeta | Out-Null }

$headers = @{ Authorization = "Key $clave"; "Content-Type" = "application/json" }
$body = @{ prompt = $Prompt } | ConvertTo-Json

Write-Host "Pidiendo a fal.ai ($Modelo): `"$Prompt`"..." -ForegroundColor Cyan
$envio = Invoke-RestMethod -Uri "https://queue.fal.run/$Modelo" -Method Post -Headers $headers -Body $body
$requestId = $envio.request_id
if (-not $requestId) {
  Write-Host "fal.ai no devolvio un request_id. Respuesta completa:" -ForegroundColor Red
  $envio | ConvertTo-Json -Depth 5
  exit 2
}

# EL SONDEO. fal.ai no da la imagen/modelo al toque -tarda de verdad-, asi
# que hay que preguntar cada tres segundos hasta que diga COMPLETED. Igual que
# la trampa ya documentada del "banco que no tardaba": si esto se cuelga, es
# mejor un tope de tiempo explicito que quedarse esperando para siempre.
$statusUrl = "https://queue.fal.run/$Modelo/requests/$requestId/status"
$t0 = Get-Date
$estado = $null
do {
  Start-Sleep -Seconds 3
  $estado = Invoke-RestMethod -Uri $statusUrl -Headers $headers
  Write-Host "  estado: $($estado.status)"
  if (((Get-Date) - $t0).TotalSeconds -gt $TopeSegundos) {
    Write-Host "Se acabo el tiempo de espera ($TopeSegundos s) sin terminar." -ForegroundColor Red
    exit 3
  }
} while ($estado.status -ne "COMPLETED")

$resultado = Invoke-RestMethod -Uri "https://queue.fal.run/$Modelo/requests/$requestId" -Headers $headers
$glbUrl = $resultado.model_glb.url
if (-not $glbUrl -and $resultado.model_urls) { $glbUrl = $resultado.model_urls.glb.url }
if (-not $glbUrl) {
  Write-Host "No vino ningun .glb en la respuesta. Respuesta completa:" -ForegroundColor Red
  $resultado | ConvertTo-Json -Depth 5
  exit 4
}

Invoke-WebRequest -Uri $glbUrl -OutFile $Salida
$peso = [math]::Round((Get-Item $Salida).Length / 1MB, 2)
Write-Host "Listo: $Salida ($peso MB)" -ForegroundColor Green
Write-Host "Para usarlo en Godot: copialo o referencialo desde dinastia-godot\, Godot 4 importa .glb solo." -ForegroundColor Cyan
