@echo off
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
REM * Proceso que registra el nombre de un subdirectorio para entrar luego a  *
REM * descargar su contenido.                                                 *
REM 
REM * Simplemente comprueba que el nombre del directorio no comience por '_'  *
REM * ni sea igual a 'backup'.                                                *
REM 

set P1=%1

if /i "%P1%" neq "backup" (
	if  "%P1:~0,1%" neq "_" echo %P1% >> dirs_ftp.txt
)
