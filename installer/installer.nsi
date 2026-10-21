; =========================================================================
; Instalador Profesional NSIS para SGGI 2.0 (Windows Desktop)
; =========================================================================

Unicode True
ManifestDPIAware True
SetCompressor /SOLID lzma

; Definición de Constantes de la Aplicación
!define PRODUCT_NAME "SGGI 2.0"
!define PRODUCT_VERSION "2.0.0"
!define PRODUCT_PUBLISHER "SGGI"
!define PRODUCT_DESCRIPTION "Sistema de Gestión Integral para Gimnasios"
!define PRODUCT_EXE "sggi_desktop.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_DIR_REGKEY "Software\${PRODUCT_NAME}"

; Iconos de la Aplicación (Pesa de Gimnasio)
!define MUI_ICON "app_icon.ico"
!define MUI_UNICON "app_icon.ico"

; Inclusión de Bibliotecas Modern UI 2
!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"
!include "x64.nsh"

; Configuración Visual Modern UI
!define MUI_ABORTWARNING
!define MUI_HEADERIMAGE
!define MUI_COMPONENTSPAGE_NODESC

; -------------------------------------------------------------------------
; Páginas del Asistente de Instalación
; -------------------------------------------------------------------------
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

; Página Final con opción para ejecutar de inmediato
!define MUI_FINISHPAGE_RUN "$INSTDIR\${PRODUCT_EXE}"
!define MUI_FINISHPAGE_RUN_TEXT "Ejecutar ${PRODUCT_NAME} ahora"
!insertmacro MUI_PAGE_FINISH

; -------------------------------------------------------------------------
; Páginas del Asistente de Desinstalación
; -------------------------------------------------------------------------
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; Idioma del Instalador
!insertmacro MUI_LANGUAGE "Spanish"

; Metadatos del Archivo Instalador
Name "${PRODUCT_NAME}"
OutFile "Instalador_SGGI_2.0.exe"
InstallDir "$PROGRAMFILES64\${PRODUCT_NAME}"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
RequestExecutionLevel admin
BrandingText "${PRODUCT_NAME} - ${PRODUCT_DESCRIPTION}"

; -------------------------------------------------------------------------
; Función de Inicialización del Instalador
; -------------------------------------------------------------------------
Function .onInit
  ; Verificar si la aplicación ya se encuentra en ejecución
  FindProc:
    nsExec::ExecToStack 'cmd /c tasklist /FI "IMAGENAME eq ${PRODUCT_EXE}" | find /I "${PRODUCT_EXE}"'
    Pop $0
    Pop $1
    ${If} $0 == 0
      MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION \
        "${PRODUCT_NAME} se encuentra en ejecución.$\n$\nPor favor, cierre el sistema antes de continuar con la instalación." \
        IDRETRY FindProc
      Abort
    ${EndIf}
FunctionEnd

; -------------------------------------------------------------------------
; Sección Principal de Instalación
; -------------------------------------------------------------------------
Section "Aplicación Principal" SecMain
  SectionIn RO

  ; Crear directorio de instalación
  SetOutPath "$INSTDIR"

  ; Copiar todos los archivos generados en el build de Release
  File /r "..\build\windows\x64\runner\Release\*.*"

  ; Escribir clave de desinstalación en el Registro de Windows
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR"
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "DisplayName" "${PRODUCT_NAME} - ${PRODUCT_DESCRIPTION}"
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "QuietUninstallString" '"$INSTDIR\uninstall.exe" /S'
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\${PRODUCT_EXE},0"
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
  WriteRegDWORD HKLM "${PRODUCT_UNINST_KEY}" "NoModify" 1
  WriteRegDWORD HKLM "${PRODUCT_UNINST_KEY}" "NoRepair" 1

  ; Estimar tamaño de la instalación para Panel de Control
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKLM "${PRODUCT_UNINST_KEY}" "EstimatedSize" "$0"

  ; Crear el Desinstalador
  WriteUninstaller "$INSTDIR\uninstall.exe"

  ; Crear Accesos Directos en el Menú Inicio
  CreateDirectory "$SMPROGRAMS\${PRODUCT_NAME}"
  CreateShortcut "$SMPROGRAMS\${PRODUCT_NAME}\${PRODUCT_NAME}.lnk" "$INSTDIR\${PRODUCT_EXE}" "" "$INSTDIR\${PRODUCT_EXE}" 0
  CreateShortcut "$SMPROGRAMS\${PRODUCT_NAME}\Desinstalar ${PRODUCT_NAME}.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0

  ; Crear Acceso Directo en el Escritorio
  CreateShortcut "$DESKTOP\${PRODUCT_NAME}.lnk" "$INSTDIR\${PRODUCT_EXE}" "" "$INSTDIR\${PRODUCT_EXE}" 0
SectionEnd

; -------------------------------------------------------------------------
; Función de Inicialización del Desinstalador
; -------------------------------------------------------------------------
Function un.onInit
  ; Verificar si la aplicación está abierta al momento de desinstalar
  UnFindProc:
    nsExec::ExecToStack 'cmd /c tasklist /FI "IMAGENAME eq ${PRODUCT_EXE}" | find /I "${PRODUCT_EXE}"'
    Pop $0
    Pop $1
    ${If} $0 == 0
      MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION \
        "${PRODUCT_NAME} se encuentra en ejecución.$\n$\nPor favor, cierre el sistema para proceder con la desinstalación." \
        IDRETRY UnFindProc
      Abort
    ${EndIf}
FunctionEnd

; -------------------------------------------------------------------------
; Sección de Desinstalación
; -------------------------------------------------------------------------
Section "Uninstall"
  ; Eliminar accesos directos
  Delete "$DESKTOP\${PRODUCT_NAME}.lnk"
  Delete "$SMPROGRAMS\${PRODUCT_NAME}\${PRODUCT_NAME}.lnk"
  Delete "$SMPROGRAMS\${PRODUCT_NAME}\Desinstalar ${PRODUCT_NAME}.lnk"
  RMDir "$SMPROGRAMS\${PRODUCT_NAME}"

  ; Eliminar archivos de la aplicación
  RMDir /r "$INSTDIR"

  ; Limpiar Registro de Windows
  DeleteRegKey HKLM "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
SectionEnd
