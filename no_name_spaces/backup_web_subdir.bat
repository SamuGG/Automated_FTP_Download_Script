@ECHO OFF
REM 
REM ===========================================================================
REM DESCARGA Y COMPRESIÓN DEL ÁRBOL DE DIRECTORIOS DE UN FTP (RECURSIVO)
REM ===========================================================================
REM
REM Autor: Samuel Granados García
REM Fecha: Sept. 2012
REM
REM ---------------------------------------------------------------------------
REM 
REM * Proceso recursivo que ejecuta el backup de archivos en cada subdirectorio
REM 
REM * Parámetros de entrada:                                                 *
REM * %1 IP del servidor remoto                                              *
REM * %2 Username para conectar al FTP del servidor remoto                   *
REM * %3 Pasword para conectar al FTP del servidor remoto                    *
REM * %4 Ruta a la carpeta del FTP donde está la carpeta descargar.          *
REM *    P.Ej. wwwroot/miweb/subfolder1                                      *
REM * %5 Nombre de la subcarpeta a descargar.                                *
REM *    P.Ej. subfolder2                                                    *
REM 
REM * Funciones:                                                             *
REM * Se conecta por FTP al servidor, se coloca en la subcarpeta deseada,    *
REM * descarga todo el árbol de archivos y subcarpetas al directorio local   *
REM * actual.                                                                *
REM 
REM * La conexión al FTP se realiza mediante el comando ftp de Windows.      *
REM 
REM ---------------------------------------------------------------------------
REM NOTAS:
REM Atención! Esta solución es válida siempre y cuando ningún directorio ni
REM subdirectorio del FTP contengan espacios en el nombre.
REM Estoy trabajando en una solución mejorada para contemplar ese caso.
REM 


SETLOCAL EnableDelayedExpansion

REM --- INICIALIZACIÓN DE VARIABLES

REM directorio de este archivo .bat
REM [ http://www.microsoft.com/resources/documentation/windows/xp/all/proddocs/en-us/percent.mspx?mfr=true ]
SET LOCALDIR=%~dp0

REM subdirectorio remoto al que hay que acceder
SET REMOTESUBDIR=%4/%5

REM --- DEBUG
REM ECHO Parametros pasados
REM ECHO [1] FTP IP ADDRESS = %1
REM ECHO [2] FTP USERNAME = %2
REM ECHO [3] FTP PASSWORD = %3
REM ECHO [4] RUTA SUBDIRECTORIO FTP = %4
REM ECHO [5] SUBDIRECTORIO LOCAL DE DESTINO = %5

REM en el directorio local actual crea el nuevo subdirectorio que va a descargar
md %5
cd %5

REM llena el archivo de script para descargar del FTP de manera desatendida
REM [ http://www.robvanderwoude.com/ftp.php ]
REM [ http://technet.microsoft.com/en-us/library/bb490910.aspx ]
>%TMPSCRIPT% ECHO %2
>>%TMPSCRIPT% ECHO %3
REM cambia al directorio raíz de nuestra web
>>%TMPSCRIPT% ECHO cd %REMOTESUBDIR%
REM descarga de archivos en nuestra carpeta local
>>%TMPSCRIPT% ECHO binary
>>%TMPSCRIPT% ECHO mget *.*
REM ejecuta un listado amplio de archivos y carpetas
>>%TMPSCRIPT% ECHO ls -l
REM desconecta la sesión del FTP
>>%TMPSCRIPT% ECHO disconnect
>>%TMPSCRIPT% ECHO bye

REM ejecuta el script desatendido del FTP y pasa el listado amplio de archivos y directorios al comando FINDSTR
REM el cual filtra aquellos que empiecen por la letra "d" (de directory) y guarda la línea en el archivo dirs-ftp.txt
REM [ http://technet.microsoft.com/en-us/library/bb490907.aspx ]
ftp -v -i -s:"%TMPSCRIPT%" %1 | findstr /b "d" > dirs-ftp.txt

REM si no hay subdirectorios, salta al final del proceso
if not exist dirs-ftp.txt goto :endsubdir

REM coge de cada línea del archivo dirs-ftp.txt, el 9º token, que es el nombre del subdirectorio
for /F "tokens=9 delims= " %%A in (dirs-ftp.txt) do call "%LOCALDIR%\backup_web_exclude_dirnames.bat" %%A
del dirs-ftp.txt

REM en dirs_ftp.txt tendremos los nombres limpios de los subdirectorios en los que tenemos que entrar recursivamente
if not exist dirs_ftp.txt goto :endsubdir

REM entra en cada subdirectorio de dirs_ftp.txt y se llama a sí mismo recursivamente
for /F %%A in (dirs_ftp.txt) do call "%LOCALDIR%\backup_web_subdir.bat" %1 %2 %3 %REMOTESUBDIR% %%A
del dirs_ftp.txt

:endsubdir

REM borra el script de acceso al FTP
type NUL>%TMPSCRIPT%
del %TMPSCRIPT%

REM vuelve al directorio local en el que estaba al principio
cd ..
