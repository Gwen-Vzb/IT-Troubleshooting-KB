@echo off
REM ================================================================
REM Script de redémarrage du service Spooler d'impression
REM A executer en tant qu'Administrateur
REM ================================================================

echo.
echo ========================================
echo  Redemarrage du service d'impression
echo ========================================
echo.

REM Vérification des droits administrateur
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERREUR : Ce script doit etre execute en tant qu'Administrateur
    echo Faites un clic droit sur le fichier et selectionnez "Executer en tant qu'administrateur"
    echo.
    pause
    exit /b 1
)

echo [%time%] Arret du service Spooler d'impression...
net stop spooler
if %errorLevel% neq 0 (
    echo ATTENTION : Erreur lors de l'arret du service
) else (
    echo Service arrete avec succes
)

echo.
echo [%time%] Nettoyage du dossier SPOOL...
del /Q /F /S "%systemroot%\System32\spool\PRINTERS\*.*" >nul 2>&1
if %errorLevel% equ 0 (
    echo Fichiers SPOOL supprimes
) else (
    echo Aucun fichier SPOOL a supprimer ou acces refuse
)

echo.
echo [%time%] Redemarrage du service Spooler d'impression...
net start spooler
if %errorLevel% neq 0 (
    echo ERREUR : Impossible de redemarrer le service
    echo.
    pause
    exit /b 1
) else (
    echo Service redemarre avec succes
)

echo.
echo ========================================
echo  Operation terminee avec succes !
echo ========================================
echo.
echo Le service d'impression a ete redemarre.
echo Vous pouvez maintenant reessayer d'imprimer.
echo.
pause
