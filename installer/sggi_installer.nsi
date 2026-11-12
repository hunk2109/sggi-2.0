; ============================================================================
; SGGI 2.0 - Script de Instalador NSIS (Frontend Flutter + Backend NestJS)
; ============================================================================
Unicode True
!include "MUI2.nsh"
!include "FileFunc.nsh"

; ----------------------------------------------------------------------------
; Información General del Producto
; ----------------------------------------------------------------------------
!define APP_NAME "SGGI 2.0"
!define APP_PUBLISHER "SGGI - Gestión Integral de Gimnasios"
!define APP_VERSION "2.0.0"
!define APP_EXE "sggi_desktop.exe"
!define UNINSTALL_REG_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\SGGI2"

Name "${APP_NAME} v${APP_VERSION}"
OutFile "output\SGGI_2.0_Setup.exe"

; Instalamos por defecto en C:\SGGI 2.0 para que el backend y scripts de Access
; tengan permisos completos de lectura/escritura (.env, logs, caché WhatsApp, .mdb)
InstallDir "C:\SGGI 2.0"
InstallDirRegKey HKLM "Software\SGGI2" "Install_Dir"
RequestExecutionLevel admin

SetCompressor /SOLID lzma
SetCompressorDictSize 32

; ----------------------------------------------------------------------------
; Interfaz Gráfica (Modern UI 2)
; ----------------------------------------------------------------------------
!define MUI_ICON "..\windows\runner\resources\app_icon.ico"
!define MUI_UNICON "..\windows\runner\resources\app_icon.ico"
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TITLE "Bienvenido al Instalador de ${APP_NAME}"
!define MUI_WELCOMEPAGE_TEXT "Este asistente instalará ${APP_NAME} (Aplicación de Escritorio + Servidor Backend Local + Conector ZKAccess/ZKTeco) en su computadora.$\r$\n$\r$\nSe recomienda cerrar cualquier instancia abierta de SGGI antes de continuar."

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

!define MUI_FINISHPAGE_RUN "$INSTDIR\${APP_EXE}"
!define MUI_FINISHPAGE_RUN_TEXT "Iniciar ${APP_NAME} ahora"
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "Spanish"

; ----------------------------------------------------------------------------
; Metadatos del Ejecutable Instalador
; ----------------------------------------------------------------------------
VIProductVersion "2.0.0.0"
VIAddVersionKey /LANG=${LANG_SPANISH} "ProductName" "${APP_NAME}"
VIAddVersionKey /LANG=${LANG_SPANISH} "CompanyName" "${APP_PUBLISHER}"
VIAddVersionKey /LANG=${LANG_SPANISH} "FileDescription" "Instalador Completo de ${APP_NAME} (Frontend + Backend)"
VIAddVersionKey /LANG=${LANG_SPANISH} "FileVersion" "${APP_VERSION}"
VIAddVersionKey /LANG=${LANG_SPANISH} "LegalCopyright" "Copyright (C) 2026 SGGI"

; ----------------------------------------------------------------------------
; Sección Principal de Instalación
; ----------------------------------------------------------------------------
Section "SGGI 2.0 (Cliente + Servidor Backend)" SecMain
  SectionIn RO

  ; Cerrar instancias previas si están en ejecución
  DetailPrint "Verificando procesos en ejecución..."
  nsExec::ExecToLog 'taskkill /F /IM "${APP_EXE}" /T'

  ; 1. Instalar Frontend Flutter (Release Bundle)
  DetailPrint "Instalando cliente de escritorio SGGI 2.0..."
  SetOutPath "$INSTDIR"
  File /r "..\build\windows\x64\runner\Release\*.*"

  ; 2. Instalar Backend Compilado (NestJS + Node.js Portable + Scripts ZKAccess)
  DetailPrint "Instalando servidor Backend y módulos de sincronización ZKAccess..."
  SetOutPath "$INSTDIR\backend"
  File /nonfatal "staging\backend\node.exe"
  File "staging\backend\backend_bundle.tar"

  DetailPrint "Descomprimiendo paquete del servidor Backend..."
  nsExec::ExecToLog '"$SYSDIR\tar.exe" -xf "$INSTDIR\backend\backend_bundle.tar" -C "$INSTDIR\backend"'
  Delete "$INSTDIR\backend\backend_bundle.tar"

  ; Copiar archivo .env solo si no existe previamente (preserva configuración en actualizaciones)
  SetOverwrite off
  File /nonfatal "staging\backend\.env"
  SetOverwrite on

  ; 3. Guardar rutas en el Registro de Windows y crear Desinstalador
  WriteRegStr HKLM "Software\SGGI2" "Install_Dir" "$INSTDIR"
  WriteRegStr HKLM "${UNINSTALL_REG_KEY}" "DisplayName" "${APP_NAME} - Gestión de Gimnasio"
  WriteRegStr HKLM "${UNINSTALL_REG_KEY}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegStr HKLM "${UNINSTALL_REG_KEY}" "DisplayIcon" "$INSTDIR\${APP_EXE}"
  WriteRegStr HKLM "${UNINSTALL_REG_KEY}" "Publisher" "${APP_PUBLISHER}"
  WriteRegStr HKLM "${UNINSTALL_REG_KEY}" "DisplayVersion" "${APP_VERSION}"
  WriteRegDWORD HKLM "${UNINSTALL_REG_KEY}" "NoModify" 1
  WriteRegDWORD HKLM "${UNINSTALL_REG_KEY}" "NoRepair" 1

  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKLM "${UNINSTALL_REG_KEY}" "EstimatedSize" "$0"

  WriteUninstaller "$INSTDIR\Uninstall.exe"

  ; 4. Crear Accesos Directos en Menú Inicio y Escritorio
  CreateDirectory "$SMPROGRAMS\${APP_NAME}"
  CreateShortCut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0
  CreateShortCut "$SMPROGRAMS\${APP_NAME}\Desinstalar ${APP_NAME}.lnk" "$INSTDIR\Uninstall.exe" "" "$INSTDIR\Uninstall.exe" 0
  CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0

  DetailPrint "Instalación de ${APP_NAME} completada exitosamente."
SectionEnd

; ----------------------------------------------------------------------------
; Sección de Desinstalación
; ----------------------------------------------------------------------------
Section "Uninstall"
  DetailPrint "Deteniendo servicios de SGGI 2.0..."
  nsExec::ExecToLog 'taskkill /F /IM "${APP_EXE}" /T'

  ; Eliminar accesos directos
  Delete "$DESKTOP\${APP_NAME}.lnk"
  Delete "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk"
  Delete "$SMPROGRAMS\${APP_NAME}\Desinstalar ${APP_NAME}.lnk"
  RMDir "$SMPROGRAMS\${APP_NAME}"

  ; Eliminar archivos de la aplicación (preservando .env y bases .mdb si el usuario reinstala)
  RMDir /r "$INSTDIR\data"
  RMDir /r "$INSTDIR\backend\dist"
  RMDir /r "$INSTDIR\backend\node_modules"
  RMDir /r "$INSTDIR\backend\src"
  Delete "$INSTDIR\backend\node.exe"
  Delete "$INSTDIR\backend\package.json"
  Delete "$INSTDIR\${APP_EXE}"
  Delete "$INSTDIR\*.dll"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR\backend"
  RMDir "$INSTDIR"

  ; Limpiar Registro
  DeleteRegKey HKLM "${UNINSTALL_REG_KEY}"
  DeleteRegKey HKLM "Software\SGGI2"
SectionEnd
