@echo off
color 0B
echo ===================================================
echo   AURA COOK - TEK TIKLA RELEASES DERLEME ARACI
echo ===================================================
echo.
echo [1/4] Proje temizleniyor (flutter clean)...
call flutter clean
if %errorlevel% neq 0 (
    color 0C
    echo HATA: Temizlik islemi basarisiz oldu.
    pause
    exit /b %errorlevel%
)

echo.
echo [2/4] Paketler indiriliyor (flutter pub get)...
call flutter pub get
if %errorlevel% neq 0 (
    color 0C
    echo HATA: Paketler indirilemedi. internet baglantinizi kontrol edin.
    pause
    exit /b %errorlevel%
)

echo.
echo [3/4] Windows Derlemesi Baslatiliyor (flutter build windows)...
call flutter build windows --release --no-tree-shake-icons
if %errorlevel% neq 0 (
    echo UYARI: Windows derlemesi yapilamadi. C++ Visual Studio build araclariniz kurulu olmayabilir.
) else (
    echo.
    echo [+] Windows derlemesi basariyla tamamlandi!
    echo Hedef Klasor: build\windows\x64\runner\Release
)

echo.
echo [4/4] Android APK Derlemesi Baslatiliyor (flutter build apk)...
call flutter build apk --release --no-tree-shake-icons
if %errorlevel% neq 0 (
    echo UYARI: Android APK derlemesi yapilamadi. Android SDK/Java kurulu olmayabilir.
) else (
    echo.
    echo [+] Android APK derlemesi basariyla tamamlandi!
    echo Hedef Dosya: build\app\outputs\flutter-apk\app-release.apk
)

echo.
echo [*] Web Derlemesi Baslatiliyor (flutter build web)...
call flutter build web --release --no-tree-shake-icons
if %errorlevel% neq 0 (
    echo UYARI: Web derlemesi yapilamadi.
) else (
    echo.
    echo [+] Web derlemesi basariyla tamamlandi!
    echo Hedef Klasor: build\web
)

echo.
echo ===================================================
echo               ISLEM TAMAMLANDI!
echo ===================================================
echo.
echo GitHub Releases yuklemesi icin:
echo 1. "build\windows\x64\runner\Release" klasorunu .zip yapin ve GitHub Releases'e yukleyin.
echo 2. "build\app\outputs\flutter-apk\app-release.apk" dosyasini GitHub Releases'e yukleyin.
echo.
echo Web demo yayinlama icin:
echo "build\web" klasorundeki dosyalari GitHub Pages veya Firebase'e yukleyin.
echo.
pause
