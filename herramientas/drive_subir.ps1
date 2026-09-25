# ============================================================================
#  PASO 2 - SUBIR EL PROYECTO AL DRIVE  (esto ya lo puede lanzar el asistente)
# ============================================================================
#  Sube "Proyecto x" a la carpeta  DINASTIA/  del Drive conectado en el paso 1.
#
#  Uso:
#    .\drive_subir.ps1                -> sube todo lo que ha cambiado
#    .\drive_subir.ps1 -Solo recursos -> sube solo una carpeta
#    .\drive_subir.ps1 -Pesadas       -> sube SOLO lo que conviene descargar del
#                                        portatil (sorpresa, respaldos, apk,
#                                        datos-navegador) para liberar espacio
#
#  NOTA IMPORTANTE sobre el espacio: lo que NO hay que borrar en local es
#  herramientas\godot\ (960 MB, pero sin el no se compila ni se renderiza nada),
#  recursos\equipaciones\ (el visor las lee en caliente), visor3d\ y el HTML.
# ============================================================================
param(
	[string]$Solo = "",
	[switch]$Pesadas,
	[string]$Remoto = "dinastia:DINASTIA"
)

$rclone = Join-Path $PSScriptRoot "rclone\rclone.exe"
$raiz = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path $rclone)) { Write-Host "Falta rclone" -ForegroundColor Red; exit 1 }

# ¿Esta conectado el Drive?
& $rclone lsd "dinastia:" --max-depth 1 *> $null
if ($LASTEXITCODE -ne 0) {
	Write-Host "El Drive no esta conectado todavia. Ejecuta primero drive_conectar.ps1" -ForegroundColor Yellow
	exit 1
}

# Ficheros que no tiene sentido subir nunca
$excluir = @(
	"--exclude", "visor3d/.godot/**",
	"--exclude", "**/*.tmp",
	"--exclude", "_test_harness.html",
	"--exclude", "herramientas/salida/**"
)

if ($Pesadas) {
	$carpetas = @("sorpresa", "respaldos", "apk", "datos-navegador")
} elseif ($Solo -ne "") {
	$carpetas = @($Solo)
} else {
	$carpetas = @("")   # todo
}

foreach ($c in $carpetas) {
	$origen = if ($c -eq "") { $raiz } else { Join-Path $raiz $c }
	$destino = if ($c -eq "") { $Remoto } else { "$Remoto/$c" }
	if (-not (Test-Path $origen)) { Write-Host "  (no existe: $c)"; continue }
	Write-Host ""
	Write-Host "  subiendo $(if($c -eq ''){'TODO'}else{$c}) -> $destino" -ForegroundColor Cyan
	& $rclone copy $origen $destino @excluir --progress --transfers 4 --checkers 8
}

Write-Host ""
Write-Host "  --- que hay ahora en el Drive ---" -ForegroundColor Cyan
& $rclone size $Remoto
