# Script automatizado para compilar SGGI 2.0 y generar el Instalador NSIS
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Compilando SGGI 2.0 (Release Windows) " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

Set-Location -Path $PSScriptRoot

# 1. Compilar Flutter en modo Release
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error en la compilación de Flutter." -ForegroundColor Red
    exit 1
}

# 2. Compilar Instalador con NSIS
Write-Host "=========================================" -ForegroundColor Green
Write-Host " Generando Instalador con NSIS...       " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

$nsisPath = "C:\Program Files (x86)\NSIS\makensis.exe"
if (-not (Test-Path $nsisPath)) {
    $nsisPath = "C:\Program Files\NSIS\makensis.exe"
}

if (-not (Test-Path $nsisPath)) {
    Write-Host "makensis.exe no encontrado en Program Files." -ForegroundColor Red
    exit 1
}

& $nsisPath "installer\installer.nsi"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=========================================================" -ForegroundColor Green
    Write-Host " ¡Instalador generado exitosamente!                      " -ForegroundColor Green
    Write-Host " Ubicación: installer\Instalador_SGGI_2.0.exe           " -ForegroundColor Green
    Write-Host "=========================================================" -ForegroundColor Green
} else {
    Write-Host "Error al compilar el instalador NSIS." -ForegroundColor Red
}
