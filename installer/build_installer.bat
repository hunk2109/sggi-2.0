@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

echo ============================================================================
echo   SGGI 2.0 - Generador de Instalador NSIS (Frontend EXE + Backend NestJS)
echo ============================================================================
echo.

set "FRONTEND_DIR=c:\develop\sggi 2.0"
set "BACKEND_DIR=C:\develop\gym-backend"
set "INSTALLER_DIR=%FRONTEND_DIR%\installer"
set "STAGING_BACKEND=%INSTALLER_DIR%\staging\backend"
set "OUTPUT_DIR=%INSTALLER_DIR%\output"

:: 1. Compilar Backend (NestJS -> dist/)
echo [1/4] Verificando compilacion del Backend (NestJS)...
cd /d "%BACKEND_DIR%" || exit /b 1
if not exist "%BACKEND_DIR%\dist\main.js" (
    call npm run build || exit /b 1
) else if "%~1"=="--rebuild" (
    call npm run build || exit /b 1
)
echo       [OK] Backend compilado en dist\main.js.
echo.

:: 2. Compilar Frontend (Flutter Windows Release)
echo [2/4] Verificando compilacion de Frontend Flutter Windows (Release)...
cd /d "%FRONTEND_DIR%" || exit /b 1
if not exist "%FRONTEND_DIR%\build\windows\x64\runner\Release\sggi_desktop.exe" (
    if not exist "%FRONTEND_DIR%\windows\flutter\ephemeral\cpp_client_wrapper\core_implementations.cc" (
        echo       Limpiando cache efimero de CMake/Flutter...
        call flutter clean
        call flutter pub get
    )
    call flutter build windows --release || exit /b 1
) else if "%~1"=="--rebuild" (
    call flutter build windows --release || exit /b 1
)
echo       [OK] Frontend listo en build\windows\x64\runner\Release\sggi_desktop.exe.
echo.

:: 3. Empaquetar archivos del Backend en un archivo tar ultrarrapido + node.exe
echo [3/4] Empaquetando Backend (dist + scripts Python + node_modules + node.exe)...
if exist "%STAGING_BACKEND%" rmdir /s /q "%STAGING_BACKEND%"
mkdir "%STAGING_BACKEND%"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

cd /d "%BACKEND_DIR%" || exit /b 1
"%SystemRoot%\System32\tar.exe" -cf "%STAGING_BACKEND%\backend_bundle.tar" ^
    --exclude="node_modules/.cache" ^
    --exclude="node_modules/typescript" ^
    --exclude="node_modules/@types" ^
    --exclude="node_modules/eslint*" ^
    --exclude="node_modules/@eslint*" ^
    --exclude="node_modules/@typescript-eslint*" ^
    --exclude="node_modules/typescript-eslint" ^
    --exclude="node_modules/jest*" ^
    --exclude="node_modules/@jest*" ^
    --exclude="node_modules/ts-jest" ^
    --exclude="node_modules/prettier*" ^
    --exclude="node_modules/supertest" ^
    --exclude="node_modules/puppeteer*" ^
    --exclude="node_modules/@puppeteer*" ^
    dist src/modules/sync/scripts package.json node_modules
if errorlevel 1 (
    echo [ERROR] Fallo al empaquetar backend_bundle.tar.
    exit /b 1
)

if exist "%BACKEND_DIR%\.env" (
    copy /Y "%BACKEND_DIR%\.env" "%STAGING_BACKEND%\.env" >nul
)

:: Incluir runtime portable de Node.js (node.exe)
for /f "delims=" %%i in ('where node 2^>nul') do (
    if not exist "%STAGING_BACKEND%\node.exe" (
        echo       Empaquetando runtime de Node.js: %%i
        copy /Y "%%i" "%STAGING_BACKEND%\node.exe" >nul
    )
)
echo       [OK] Paquete del Backend preparado.
echo.

:: 4. Ejecutar NSIS (makensis.exe)
echo [4/4] Generando instalador SGGI_2.0_Setup.exe con NSIS...
set "MAKENSIS="
if exist "C:\Program Files (x86)\NSIS\makensis.exe" set "MAKENSIS=C:\Program Files (x86)\NSIS\makensis.exe"
if exist "C:\Program Files\NSIS\makensis.exe" set "MAKENSIS=C:\Program Files\NSIS\makensis.exe"
if "%MAKENSIS%"=="" (
    for /f "delims=" %%i in ('where makensis 2^>nul') do set "MAKENSIS=%%i"
)

if "%MAKENSIS%"=="" (
    echo [ADVERTENCIA] No se encontro NSIS ^(makensis.exe^) instalado en la ruta estandar.
    echo               Instala NSIS con: winget install NSIS.NSIS
    exit /b 1
)

cd /d "%INSTALLER_DIR%"
"%MAKENSIS%" "sggi_installer.nsi"
if errorlevel 1 (
    echo [ERROR] Fallo la compilacion del script NSIS.
    exit /b 1
)

echo.
echo ============================================================================
echo   [EXITO] Instalador creado en:
echo   %OUTPUT_DIR%\SGGI_2.0_Setup.exe
echo ============================================================================
exit /b 0
