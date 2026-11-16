param(
  [ValidateSet('run', 'build')]
  [string]$Action = 'build',
  [string]$GoogleWebClientId = '',
  [string]$GoogleServerClientId = '',
  [string]$VapidKey = ''
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$firebaseFile = Join-Path $projectRoot 'android\app\google-services.json'
$workerFile = Join-Path $projectRoot 'web\firebase-messaging-sw.js'
$flutter = (Get-Command flutter -ErrorAction SilentlyContinue).Source
if (-not $flutter) {
  $flutter = 'C:\flutter\bin\flutter.bat'
}

if (-not (Test-Path $firebaseFile)) {
  throw 'Missing android\app\google-services.json. Copy the local Firebase Android configuration into that path.'
}
if (-not (Test-Path $flutter)) {
  throw 'Flutter was not found on PATH or at C:\flutter\bin\flutter.bat.'
}

$firebase = Get-Content $firebaseFile -Raw | ConvertFrom-Json
$apiKey = $firebase.client[0].api_key[0].current_key
$projectId = $firebase.project_info.project_id
$senderId = $firebase.project_info.project_number
$webOptions = [ordered]@{
  FIREBASE_WEB_API_KEY = $apiKey
  FIREBASE_WEB_APP_ID = '1:100221373274:web:d151778a6250e880f08163'
  FIREBASE_AUTH_DOMAIN = "$projectId.firebaseapp.com"
  GOOGLE_WEB_CLIENT_ID = $GoogleWebClientId
  GOOGLE_SERVER_CLIENT_ID = $GoogleServerClientId
  FIREBASE_VAPID_KEY = $VapidKey
}
$tempOptions = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString() + '.json')
$workerConfig = [ordered]@{
  apiKey = $apiKey
  authDomain = "$projectId.firebaseapp.com"
  projectId = $projectId
  storageBucket = $firebase.project_info.storage_bucket
  messagingSenderId = $senderId
  appId = '1:100221373274:web:d151778a6250e880f08163'
  measurementId = 'G-PMHMBYXY9TG'
} | ConvertTo-Json -Compress
$worker = @"
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');
firebase.initializeApp($workerConfig);
const messaging = firebase.messaging();
messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  self.registration.showNotification(notification.title || 'SRIT SKOLARO', {
    body: notification.body || '',
    icon: '/icons/Icon-192.png'
  });
});
"@

try {
  $webOptions | ConvertTo-Json | Set-Content -Path $tempOptions -Encoding utf8
  Set-Content -Path $workerFile -Value $worker -Encoding utf8
  Push-Location $projectRoot
  if ($Action -eq 'run') {
    & $flutter run -d chrome "--dart-define-from-file=$tempOptions"
  } else {
    & $flutter build web "--dart-define-from-file=$tempOptions"
  }
  $result = $LASTEXITCODE
  if ($result -ne 0) {
    exit $result
  }
} finally {
  Pop-Location
  Remove-Item -LiteralPath $tempOptions -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $workerFile -Force -ErrorAction SilentlyContinue
}
