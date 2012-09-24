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
REM *    P.Ej. "wwwroot/miweb/subfolder1"                                    *
REM * %5 Tipo de listado de directorios: 1=Windows, 2=Unix                   *
REM * %6 Nombre de la subcarpeta a descargar.                                *
REM *    P.Ej. "subfolder2"                                                  *
REM 
REM * Funciones:                                                             *
REM * Se conecta por FTP al servidor, se coloca en la subcarpeta deseada,    *
REM * descarga todo el árbol de archivos y subcarpetas al directorio local   *
REM * actual.                                                                *
REM 
REM * La conexión al FTP se realiza mediante el comando ftp de Windows.      *
REM 
REM ---------------------------------------------------------------------------
REM 


SETLOCAL EnableDelayedExpansion

REM --- INICIALIZACIÓN DE VARIABLES

REM Los parámetros 4 y 6 que son los nombres de directorio actual y siguiente, vienen entre comillas; hay que quitárselas
SET REMOTEDIR=%~4
SET REMOTESUBDIR=%~6

REM subdirectorio local donde se realizará la descarga
SET LOCALSUBDIR=!REMOTESUBDIR!

REM subdirectorio remoto al que hay que acceder
SET REMOTESUBDIR=!REMOTEDIR!/!REMOTESUBDIR!
REM por si acaso, elimina espacios en blanco antes y después del contenido de la variable
REM [ http://stackoverflow.com/questions/3001999/how-to-remove-trailing-and-leading-whitespace-for-user-provided-input-in-a-batch ]
CALL :TRIM !REMOTESUBDIR! REMOTESUBDIR

REM directorio de este archivo .bat
REM [ http://www.microsoft.com/resources/documentation/windows/xp/all/proddocs/en-us/percent.mspx?mfr=true ]
SET LOCALDIR=%~dp0

REM --- DEBUG
REM ECHO Parametros pasados
REM ECHO [1] FTP IP ADDRESS = %1
REM ECHO [2] FTP USERNAME = %2
REM ECHO [3] FTP PASSWORD = %3
REM ECHO [4] RUTA SUBDIRECTORIO FTP = %4
REM ECHO [5] SUBDIRECTORIO LOCAL DE DESTINO = %5

REM en el directorio local actual crea el nuevo subdirectorio que va a descargar
md "!LOCALSUBDIR!"
cd "!LOCALSUBDIR!"

REM llena el archivo de script para descargar del FTP de manera desatendida
REM [ http://www.robvanderwoude.com/ftp.php ]
REM [ http://technet.microsoft.com/en-us/library/bb490910.aspx ]
>%TMPSCRIPT% ECHO %2
>>%TMPSCRIPT% ECHO %3
REM cambia al directorio raíz de nuestra web
>>%TMPSCRIPT% ECHO cd "!REMOTESUBDIR!"
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

REM ---
REM Algunos FTP devuelven un listado tipo Unix y otros tipo Windows. Puede ser que la primera ejecución hay devuelto un tipo u otro, por eso reintentamos de la otra manera en caso de no haber subdirectorios recogidos de la 1ra manera.

REM PROC=1 indica que el listado de directorios es tipo Windows. Debe procesarlos con la subrutina 'sub1'
REM ejemplo:
REM 07-30-12  05:58PM       <DIR>          css
REM 09-17-12  06:58PM       <DIR>          db

REM PROC=2 indica que el listado de directorios es tipo Unix. Debe procesarlos con la subrutina 'sub2'
REM ejemplo:
REM drwxrwxrwx   1 owner    group               0 Sep 19 10:23 css
REM drwxrwxrwx   1 owner    group               0 Sep 17 18:52 db
REM ---

REM guarda el listado de subdirectorios, buscándolos según el tipo de listado que da este FTP: 1 = tipo Windows, 2 = tipo Unix
if "%5" == "1" (
	ftp -v -i -s:"%TMPSCRIPT%" %1 | findstr "<DIR>" > dirs-ftp.txt
) else (
	ftp -v -i -s:"%TMPSCRIPT%" %1 | findstr /b "d" > dirs-ftp.txt
)

REM comprueba si hay subdirectorios. supuestamente debe haber creado el archivo dirs-ftp.txt. Comprueba si está vacío.
for %%T in (dirs-ftp.txt) do if %%~zT equ 0 goto :endsubdir

REM coge cada línea del archivo dirs-ftp.txt y la procesa según el tipo de listado de directorios del FTP: sub1 = tipo Windows, sub2 = tipo Unix
for /F "tokens=*" %%A in (dirs-ftp.txt) do (
	set line=%%A
	if "%5" == "1" ( call :sub1 line ) else ( call :sub2 line )
)
goto :endsub1

:sub1
REM echo Entra en sub1 con line = %line%

REM Coge el primer token a partir del cual queremos todo lo que sigue, es decir, del 4º en adelante
REM porque ahí empieza el nombre del subdirectorio.
for /F "tokens=4* delims= " %%A in ("%line%") do (
	set REMOTESUBSUBDIR=%%A
	set line=%%B
)

REM Lo siguiente es necesario porque el nombre del subdirectorio puede contener espacios en blanco o varias palabras:
REM Si hay más tokens para seguir después del que partíamos, ya recorre el bucle de token en token (de 1 en 1)
if not "%line%" == "" (

	for /F "tokens=*" %%A in ("%line%") do (
		set REMOTESUBSUBDIR=!REMOTESUBSUBDIR! %%A
		set line=%%B
	)
	
)
call "%LOCALDIR%\backup_web_exclude_dirnames.bat" "!REMOTESUBSUBDIR!"
REM sale de sub1
REM [ http://www.robvanderwoude.com/call.php ]
REM [ http://www.quepublishing.com/articles/article.aspx?p=1154761&seqNum=11 ]
goto :eof

REM por si acaso le diera por continuar por aquí al terminar la subrutina 'sub1'
goto :endsub1

:sub2
REM Coge el primer token a partir del cual queremos todo lo que sigue, es decir, del 9º en adelante
REM porque ahí empieza el nombre del subdirectorio.
for /F "tokens=9* delims= " %%A in ("%line%") do (
	set REMOTESUBSUBDIR=%%A
	set line=%%B
)

REM Lo siguiente es necesario porque el nombre del subdirectorio puede contener espacios en blanco o varias palabras:
REM Si hay más tokens para seguir después del que partíamos, ya recorre el bucle de token en token (de 1 en 1)
if not "%line%" == "" (

	for /F "tokens=*" %%A in ("%line%") do (
		set REMOTESUBSUBDIR=!REMOTESUBSUBDIR! %%A
		set line=%%B
	)
	
)
call "%LOCALDIR%\backup_web_exclude_dirnames.bat" "!REMOTESUBSUBDIR!"
REM sale de sub2
REM [ http://www.robvanderwoude.com/call.php ]
REM [ http://www.quepublishing.com/articles/article.aspx?p=1154761&seqNum=11 ]
goto :eof

REM por si acaso le diera por continuar por aquí al terminar la subrutina 'sub2'
goto :endsub1

:TRIM
SET %2=%1
goto :eof

:endsub1

REM en dirs_ftp.txt tendremos los nombres limpios de los subdirectorios en los que tenemos que entrar recursivamente. Comprueba si hay.
if not exist dirs_ftp.txt goto :endsubdir
REM puede ser que el archivo exista por alguna razón y que esté vacío. Salta este caso también.
for %%S in (dirs_ftp.txt) do if %%~zS equ 0 goto :endsubdir

REM entra en cada subdirectorio de dirs_ftp.txt y se llama a sí mismo recursivamente
for /F "tokens=*" %%A in (dirs_ftp.txt) do call "%LOCALDIR%\backup_web_subdir.bat" %1 %2 %3 "!REMOTESUBDIR!" %5 "%%A"
del dirs_ftp.txt

:endsubdir

REM borra el script de acceso al FTP
type NUL>%TMPSCRIPT%
del %TMPSCRIPT%

if exist dirs-ftp.txt del dirs-ftp.txt

REM vuelve al directorio local en el que estaba al principio
cd ..