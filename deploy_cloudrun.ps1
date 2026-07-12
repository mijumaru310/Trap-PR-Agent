# deploy_cloudrun.ps1
# Build flutter web and copy to backend for deployment

$ErrorActionPreference = "Stop"

Write-Host "========================================"
Write-Host "Trap-PR Agent Deployment Prep Script"
Write-Host "========================================"

# 1. Build Frontend
Write-Host "`n[1/2] Building Flutter Web App..."
cd frontend
flutter build web
if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter build failed."
    exit 1
}
cd ..

# 2. Copy Build
Write-Host "`n[2/2] Copying build files to backend..."
$SourcePath = "frontend\build\web"
$DestPath = "backend\static"

if (Test-Path $DestPath) {
    Remove-Item -Recurse -Force $DestPath
}

New-Item -ItemType Directory -Path $DestPath | Out-Null
Copy-Item -Recurse -Force "$SourcePath\*" "$DestPath\"

Write-Host "`n========================================"
Write-Host "Deployment prep complete!"
Write-Host "Run the following commands to deploy to Cloud Run:"
Write-Host "----------------------------------------"
Write-Host "cd backend"
Write-Host "gcloud run deploy trap-pr-agent --source ."
Write-Host "========================================"
