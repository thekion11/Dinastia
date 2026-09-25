# ============================================================================
#  SINCRONIZAR "Proyecto x" CON EL DRIVE, EN LOS DOS SENTIDOS
# ============================================================================
#  La carpeta local ES la carpeta sincronizada. No se hace una copia aparte a
#  proposito: duplicarlo todo en el disco seria justo lo contrario de lo que se
#  busca, que es que sobre espacio.
#
#  Lo que subes desde aqui aparece en Drive/DINASTIA, y lo que dejes tu en
#  Drive/DINASTIA (recursos nuevos, modelos...) baja aqui al sincronizar.
#
#  Uso:
#    .\drive_sincronizar.ps1 -Primera    <- SOLO la primera vez (siembra el par)
#    .\drive_sincronizar.ps1             <- de aqui en adelante, en los 2 sentidos
#    .\drive_sincronizar.ps1 -SoloSubir  <- empujar sin traer nada
#    .\drive_sincronizar.ps1 -Ensayo     <- enseña que haria, sin tocar nada
# ============================================================================
param(
	[switch]$Primera,
	[switch]$SoloSubir,
	[switch]$Ensayo
)

$rclone = Join-Path $PSScriptRoot "rclone\rclone.exe"
$raiz   = Split-Path -Parent $PSScriptRoot
$remoto = "dinastia:DINASTIA"

if (-not (Test-Path $rclone)) { Write-Host "Falta rclone" -ForegroundColor Red; exit 1 }

& $rclone lsd "dinastia:" --max-depth 1 *> $null
if ($LASTEXITCODE -ne 0) {
	Write-Host ""
	Write-Host "  El Drive no esta conectado todavia." -ForegroundColor Yellow
	Write-Host "  Ejecuta primero:  .\drive_conectar.ps1" -ForegroundColor Yellow
	exit 1
}

# bisync se cae con "directory not found" si la carpeta de destino no existe
# todavia. Crearla es inofensivo: si ya esta, no hace nada.
& $rclone mkdir $remoto *> $null

# Lo que nunca hay que sincronizar: cache de Godot, temporales del banco de
# pruebas y el propio Godot portable (960 MB que no pintan nada en la nube).
$excluir = @(
	"--exclude", "visor3d/.godot/**",
	"--exclude", "herramientas/godot/**",
	"--exclude", "herramientas/rclone/**",
	"--exclude", "herramientas/salida/**",
	"--exclude", "_test_harness.html",
	"--exclude", "**/*.tmp",
	"--exclude", "**/Thumbs.db"
)
$comunes = @("--progress", "--transfers", "4", "--checkers", "8")
if ($Ensayo) { $comunes += "--dry-run" }

if ($SoloSubir) {
	Write-Host "  subiendo (solo de aqui hacia Drive)..." -ForegroundColor Cyan
	& $rclone copy $raiz $remoto @excluir @comunes
} elseif ($Primera) {
	# --resync le dice a rclone cual es la version buena de partida. Solo la
	# primera vez: si se usa siempre, machaca en vez de sincronizar.
	Write-Host "  primera sincronizacion (sembrando el par local <-> Drive)..." -ForegroundColor Cyan
	& $rclone bisync $raiz $remoto --resync --resync-mode newer @excluir @comunes
} else {
	Write-Host "  sincronizando en los dos sentidos..." -ForegroundColor Cyan
	& $rclone bisync $raiz $remoto @excluir @comunes
}

Write-Host ""
Write-Host "  --- lo que hay ahora en el Drive ---" -ForegroundColor Cyan
& $rclone size $remoto
