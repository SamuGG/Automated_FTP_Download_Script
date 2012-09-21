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
REM * Proceso principal que ejecuta el backup de archivos.                    *
REM 
REM * Parámetros de entrada:                                                  *
REM * %1 IP del servidor remoto                                               *
REM * %2 Username para conectar al FTP del servidor remoto                    *
REM * %3 Pasword para conectar al FTP del servidor remoto                     *
REM * %4 Ruta a la carpeta del FTP donde está la raíz de la web a descargar.  *
REM *    P.Ej. wwwroot/miweb                                                  *
REM * %5 Nombre completo del archivo local de destino y su ruta completa.     *
REM *    P.Ej. C:\MisBackups\miweb.zip                                        *
REM 
REM * Funciones:                                                              *
REM * Se conecta por FTP al servidor, descarga todo el árbol de archivos y    *
REM * carpetas a un subdirectorio temporal, comprime en zip dicho contenido   *
REM * y elimina el subdirectorio temporal.                                    *
REM * Todo el proceso es automático, sin que intervenga el ususario.          *
REM 
REM * La conexión al FTP se realiza mediante el comando ftp de Windows.       *
REM * La compresión a Zip se realiza mediante la utilidad 7zip descargable    *
REM * desde http://7-zip.org y que debe estar en la variable de entorno PATH. *
REM 
REM ---------------------------------------------------------------------------
REM NOTAS:
REM Atención! Esta solución es válida siempre y cuando ningún directorio ni
REM subdirectorio del FTP contengan espacios en el nombre.
REM Estoy trabajando en una solución mejorada para contemplar ese caso.
REM 


SETLOCAL ENABLEDELAYEDEXPANSION

REM --- INICIALIZACIÓN DE VARIABLES

REM directorio de este archivo .bat
REM [ http://www.microsoft.com/resources/documentation/windows/xp/all/proddocs/en-us/percent.mspx?mfr=true ]
SET LOCALDIR=%~dp0

REM --- DEBUG
REM ECHO Parametros pasados
REM ECHO [1] FTP IP ADDRESS = %1
REM ECHO [2] FTP USERNAME = %2
REM ECHO [3] FTP PASSWORD = %3
REM ECHO [4] RUTA FTP RAIZ WEB = %4
REM ECHO [5] RUTA Y NOMBRE COMPLETO DEL ARCHIVO DESTINO = %5

REM fecha y hora para nombrar archivos y carpetas temporales
SET TMPDATETIME=%date:~0,2%%date:~3,2%%date:~6,4%%time:~0,2%%time:~3,2%%time:~6,2%

REM directorio temporal donde se descarga del FTP
SET TMPDIR="tmp%TMPDATETIME%"

REM nombre del archivo de script para automatizar la descarga del FTP de manera desatendida
SET TMPSCRIPT="script%TMPDATETIME%.ftp"

REM en el directorio destino crea la carpeta temporal de descarga
cd %~dp5
md %TMPDIR%

REM llena el archivo de script para descargar del FTP de manera desatendida
REM [ http://www.robvanderwoude.com/ftp.php ]
REM [ http://technet.microsoft.com/en-us/library/bb490910.aspx ]
>%TMPSCRIPT% ECHO %2
>>%TMPSCRIPT% ECHO %3
REM cambia al directorio raíz de nuestra web
>>%TMPSCRIPT% ECHO cd %4
REM descarga de archivos en nuestra carpeta local
>>%TMPSCRIPT% ECHO binary
>>%TMPSCRIPT% ECHO mget *.*
REM ejecuta un listado amplio de archivos y carpetas
>>%TMPSCRIPT% ECHO ls -l
REM desconecta la sesión del FTP
>>%TMPSCRIPT% ECHO disconnect
>>%TMPSCRIPT% ECHO bye

REM cambia al directorio temporal de descarga
cd %TMPDIR%

REM ejecuta el script desatendido del FTP y pasa el listado amplio de archivos y directorios al comando FINDSTR
REM el cual filtra aquellos que empiecen por la letra "d" (de directory) y guarda la línea en el archivo dirs-ftp.txt
REM [ http://technet.microsoft.com/en-us/library/bb490907.aspx ]
ftp -v -i -s:"../%TMPSCRIPT%" %1 | findstr /b "d" > dirs-ftp.txt

REM si no hay subdirectorios, salta a la parte de comprimir
if not exist dirs-ftp.txt goto :zipdownload
	
REM coge de cada línea del archivo dirs-ftp.txt, el 9º token, que es el nombre del subdirectorio
for /F "tokens=9 delims= " %%A in (dirs-ftp.txt) do call "%LOCALDIR%\backup_web_exclude_dirnames.bat" %%A
del dirs-ftp.txt

REM en dirs_ftp.txt tendremos los nombres limpios de los subdirectorios en los que tenemos que entrar recursivamente
if not exist dirs_ftp.txt goto :zipdownload

REM entra en cada subdirectorio de dirs_ftp.txt y hace lo mismo recursivamente
for /F %%A in (dirs_ftp.txt) do call "%LOCALDIR%\backup_web_subdir.bat" %1 %2 %3 %4 %%A
del dirs_ftp.txt

:zipdownload
REM COMPRIMIR TODA LA DESCARGA
if not exist *.* goto fin
7z a -tzip -mx9 -mmt=on "..\%~nx5" .
goto :fin

:fin
REM borra el script de acceso al FTP
cd ..
type NUL>%TMPSCRIPT%
del %TMPSCRIPT%

REM borra el directorio temporal local
REM rd /S /Q %TMPDIR%

REM -- SALIDA
REM si desactivas la siguiente línea, la ventana de comandos se cerrará al terminar todo el proceso.
REM exit %ERRORLEVEL%