@echo off
chcp 65001 > nul
echo ========================================
echo  DORON — Seed et Migration Firebase
echo ========================================
echo.

cd /d "C:\Users\marcg\Desktop\Doron-claude-app-testing-audit-kKgRw"

REM Verifier flutter
where flutter >nul 2>&1
if errorlevel 1 (
    REM Essayer fvm
    where fvm >nul 2>&1
    if errorlevel 1 (
        echo [ERREUR] Flutter non trouve dans le PATH.
        echo Ouvre ce fichier depuis un terminal Flutter.
        echo.
        echo Lance plutot les commandes manuellement :
        echo   flutter run -t lib/scripts/migrate_existing_products.dart
        echo   flutter run -t lib/scripts/seed_products_v4.dart
        pause
        exit /b 1
    ) else (
        set FLUTTER=fvm flutter
    )
) else (
    set FLUTTER=flutter
)

echo [1/2] Migration tags existants Firebase...
echo     Cette etape ajoute les nouveaux tags (occasion, saison, popularite)
echo     a tous les produits existants dans Firebase.
echo.
%FLUTTER% run -t lib/scripts/migrate_existing_products.dart --release
if errorlevel 1 (
    echo [WARN] Migration terminee avec avertissements. Continuer...
)

echo.
echo [2/2] Insertion des 160 nouveaux produits (v4)...
echo     Categories: ado fille, homme 55+, couple, animaux, eco, auto, DIY, hiver
echo.
%FLUTTER% run -t lib/scripts/seed_products_v4.dart --release
if errorlevel 1 (
    echo [WARN] Seed v4 termine avec avertissements.
)

echo.
echo ========================================
echo  TERMINE ! Verifier Firebase Console.
echo ========================================
pause
