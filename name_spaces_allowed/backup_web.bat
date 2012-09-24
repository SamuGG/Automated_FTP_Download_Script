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

REM ruta al FTP. Puede venir con comillas, en cuyo caso hay que quitárselas.
SET REMOTEDIR=%~4

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
>>%TMPSCRIPT% ECHO cd "!REMOTEDIR!"
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


REM ---
REM Algunos FTP devuelven un listado tipo Unix y otros tipo Windows.
REM Si con la primera opción no consigue descargarse ningún subdirectorio, prueba con la segunda opción.
REM También es posible que el directorio raíz no contenga subdirectorios.

REM PROC = 1 indica que el listado de directorios es tipo Windows. Debe procesarlos la subrutina 'sub1'
REM ejemplo:
REM 07-30-12  05:58PM       <DIR>          css
REM 09-17-12  06:58PM       <DIR>          db

REM PROC = 2 indica que el listado de directorios es tipo Unix. Debe procesarlos la subrutina 'sub2'
REM ejemplo:
REM drwxrwxrwx   1 owner    group               0 Sep 19 10:23 css
REM drwxrwxrwx   1 owner    group               0 Sep 17 18:52 db
REM ---

ftp -v -i -s:"../%TMPSCRIPT%" %1 | findstr "<DIR>" > dirs-ftp.txt

SET PROC=1

REM comprueba si hay subdirectorios. supuestamente debe haber creado el archivo dirs-ftp.txt. Comprueba si está vacío.
for %%S in (dirs-ftp.txt) do if %%~zS equ 0 (
	ftp -v -i -s:"../%TMPSCRIPT%" %1 | findstr /b "d" > dirs-ftp.txt
	for %%T in (dirs-ftp.txt) do if %%~zT equ 0 ( goto :zipdownload ) else ( SET PROC=2 )
)
	
REM coge cada línea del archivo dirs-ftp.txt
for /F "tokens=*" %%A in (dirs-ftp.txt) do (
	set line=%%A
	if "!PROC!" == "1" ( call :sub1 line ) else ( call :sub2 line )
)
if "%line%" == "" del dirs-ftp.txt
goto :endsub1

:sub1
REM Coge el primer token a partir del cual queremos todo lo que sigue, es decir, del 4º en adelante
REM porque ahí empieza el nombre del subdirectorio.
for /F "tokens=4* delims= " %%A in ("%line%") do (
	set REMOTESUBDIR=%%A
	set line=%%B
)

REM Lo siguiente es necesario porque el nombre del subdirectorio puede contener espacios en blanco o varias palabras:
REM Si hay más tokens para seguir después del que partíamos, ya recorre el bucle de token en token (de 1 en 1)
if not "%line%" == "" (

	for /F "tokens=*" %%A in ("%line%") do (
		set REMOTESUBDIR=!REMOTESUBDIR! %%A
		set line=%%B
	)
	
)
call "%LOCALDIR%\backup_web_exclude_dirnames.bat" "!REMOTESUBDIR!"
REM sale de sub1
REM [ http://www.robvanderwoude.com/call.php ]
REM [ http://www.quepublishing.com/articles/article.aspx?p=1154761&seqNum=11 ]
goto :eof

REM por si acaso le diera por continuar por aquí al terminar la subrutina 'sub1', no queremos que ejecute la subrutina2 sin querer.
goto :endsub1

:sub2
REM Coge el primer token a partir del cual queremos todo lo que sigue, es decir, del 9º en adelante
REM porque ahí empieza el nombre del subdirectorio.
for /F "tokens=9* delims= " %%A in ("%line%") do (
	set REMOTESUBDIR=%%A
	set line=%%B
)

REM Lo siguiente es necesario porque el nombre del subdirectorio puede contener espacios en blanco o varias palabras:
REM Si hay más tokens para seguir después del que partíamos, ya recorre el bucle de token en token (de 1 en 1)
if not "%line%" == "" (

	for /F "tokens=*" %%A in ("%line%") do (
		set REMOTESUBDIR=!REMOTESUBDIR! %%A
		set line=%%B
	)
	
)
call "%LOCALDIR%\backup_web_exclude_dirnames.bat" "!REMOTESUBDIR!"
REM sale de sub2
goto :eof

:endsub1
REM en dirs_ftp.txt tendremos los nombres limpios de los subdirectorios en los que tenemos que entrar recursivamente
if not exist dirs_ftp.txt goto :zipdownload

REM entra en cada subdirectorio de dirs_ftp.txt y hace lo mismo recursivamente
for /F %%A in (dirs_ftp.txt) do call "%LOCALDIR%\backup_web_subdir.bat" %1 %2 %3 "!REMOTEDIR!" !PROC! "%%A"
del dirs_ftp.txt

:zipdownload

REM --- COMPRIMIR BACKUP
REM si el directorio local no está vacío, quiere decir que se ha descargado algo del FTP y que lo podemos comprimir
for /f %%i in ('dir /a /b') do goto ZIPCONTENT
goto :EMPTYDIR

:ZIPCONTENT
7z a -tzip -mx9 -mmt=on "..\%~nx5" .
goto :FIN

:EMPTYDIR
REM DEVOLVER QUE NO SE HA HECHO NINGUN BACKUP PORQUE NO HABIA ARCHIVOS
REM [ http://www.robvanderwoude.com/errorlevel.php ]
EXIT /B 1

:FIN
REM borra el script de acceso al FTP
cd ..
type NUL>%TMPSCRIPT%
del %TMPSCRIPT%

REM borra el directorio temporal local
rd /S /Q %TMPDIR%

REM -- SALIDA
REM [ http://www.robvanderwoude.com/errorlevel.php ]
REM echo %ERRORLEVEL%
EXIT /B %ERRORLEVEL%