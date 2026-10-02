# One-time (idempotent) Android setup for Windows PowerShell: generates the Android
# project with `flutter create`, installs the home-screen widget files, and patches
# the manifest. Run from app/ with:  .\tool\setup_android.ps1
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

$pkgDir = 'com\biblepic\bible_pic'
flutter create --platforms=android --org com.biblepic --project-name bible_pic .
if ($LASTEXITCODE -ne 0) { throw 'flutter create failed' }

$kt = "android\app\src\main\kotlin\$pkgDir"
New-Item -ItemType Directory -Force $kt | Out-Null
New-Item -ItemType Directory -Force 'android\app\src\main\res\layout' | Out-Null
New-Item -ItemType Directory -Force 'android\app\src\main\res\xml' | Out-Null
Copy-Item 'android_widget\kotlin\VerseWidgetProvider.kt' $kt -Force
Copy-Item 'android_widget\res\layout\verse_widget.xml' 'android\app\src\main\res\layout\' -Force
Copy-Item 'android_widget\res\xml\verse_widget_info.xml' 'android\app\src\main\res\xml\' -Force

$manifest = 'android\app\src\main\AndroidManifest.xml'
$text = Get-Content $manifest -Raw
if ($text -notmatch 'VerseWidgetProvider') {
    $receiver = @'

        <receiver android:name=".VerseWidgetProvider" android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data android:name="android.appwidget.provider"
                android:resource="@xml/verse_widget_info" />
        </receiver>
'@
    $text = $text.Replace('</application>', $receiver + "    </application>")
    Set-Content $manifest $text -NoNewline
}

Write-Host 'Next: flutter pub get; dart run build_runner build --delete-conflicting-outputs'
Write-Host 'Confirm applicationId in android\app\build.gradle(.kts) is com.biblepic.bible_pic.'
