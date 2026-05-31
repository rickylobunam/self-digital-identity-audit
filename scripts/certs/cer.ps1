# Local HTTPS certificate generation for development (Windows PowerShell)
# Generates self-signed certificates for localhost development
# IMPORTANT: These certificates are for LOCAL DEVELOPMENT ONLY
# Never use these in production

#Requires -Version 5.0

param(
    [string]$CertDir = ".certs",
    [string]$CertName = "localhost"
)

$ErrorActionPreference = "Stop"

# Certificate paths
$KeyFile = Join-Path $CertDir "$CertName.key"
$CertFile = Join-Path $CertDir "$CertName.crt"
$PfxFile = Join-Path $CertDir "$CertName.pfx"

# Create certificate directory
if (-not (Test-Path $CertDir)) {
    New-Item -ItemType Directory -Path $CertDir -Force | Out-Null
    Write-Host "✓ Created directory: $CertDir" -ForegroundColor Green
}

Write-Host ""
Write-Host "🔐 SDIA Local HTTPS Certificate Generator (Windows)" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  IMPORTANT: These certificates are for LOCAL DEVELOPMENT ONLY" -ForegroundColor Yellow
Write-Host "   Do not use in production." -ForegroundColor Yellow
Write-Host ""

# Check if mkcert is available on Windows
$mkcertPath = $null
try {
    $mkcertPath = (Get-Command mkcert -ErrorAction SilentlyContinue).Source
}
catch {
    # mkcert not found
}

if ($mkcertPath) {
    Write-Host "✓ Using mkcert for certificate generation..." -ForegroundColor Green
    Write-Host ""
    
    # Check if local CA is installed
    $caRoot = & $mkcertPath -CAROOT 2>$null
    if (-not $caRoot) {
        Write-Host "Installing local CA (you may need admin privileges)..." -ForegroundColor Yellow
        & $mkcertPath -install
    }
    
    # Generate certificates for localhost
    Write-Host "Generating certificates for localhost..." -ForegroundColor Green
    & $mkcertPath `
        -key-file $KeyFile `
        -cert-file $CertFile `
        localhost 127.0.0.1 "::1"
    
    Write-Host ""
    Write-Host "✅ Certificates generated with mkcert:" -ForegroundColor Green
    Write-Host "   Key:  $KeyFile"
    Write-Host "   Cert: $CertFile"
    Write-Host ""
    Write-Host "📌 Your local CA has been installed in your system trust store." -ForegroundColor Cyan
    Write-Host "   Browsers will recognize these certificates as valid." -ForegroundColor Cyan
    
}
else {
    Write-Host "⚠️  mkcert not found. Using PowerShell self-signed certificate..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Generating self-signed certificate..." -ForegroundColor Green
    
    # Create self-signed certificate using PowerShell
    $cert = New-SelfSignedCertificate `
        -DnsName "localhost", "127.0.0.1", "::1" `
        -FriendlyName "SDIA Local Development" `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -NotAfter (Get-Date).AddDays(365) `
        -HashAlgorithm SHA256 `
        -KeyLength 2048 `
        -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.1")
    
    # Export private key (requires additional handling on Windows)
    # For simplicity, export as PFX format which includes the key
    $pfxPassword = ConvertTo-SecureString -String "localdev" -AsPlainText -Force
    Export-PfxCertificate -Cert $cert -FilePath $PfxFile -Password $pfxPassword | Out-Null
    
    Write-Host ""
    Write-Host "✅ Self-signed certificate generated:" -ForegroundColor Green
    Write-Host "   PFX:  $PfxFile"
    Write-Host ""
    Write-Host "📌 IMPORTANT: Browser will show security warning" -ForegroundColor Yellow
    Write-Host "   This is expected for self-signed certificates." -ForegroundColor Yellow
    Write-Host "   You can safely proceed ('Advanced' → 'Proceed')." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🔑 PFX Password: localdev" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "📁 Certificate location: $CertDir/" -ForegroundColor Cyan
Get-ChildItem -Path $CertDir | Format-Table -Property Name, Length, LastWriteTime
Write-Host ""
Write-Host "🚀 Next steps:" -ForegroundColor Green
Write-Host "   1. Update your local development server config to use these files" -ForegroundColor Green
Write-Host "   2. Restart your dev server (make dev)" -ForegroundColor Green
Write-Host "   3. Navigate to https://localhost:5173 (frontend)" -ForegroundColor Green
Write-Host "      or https://localhost:3000 (backend)" -ForegroundColor Green
Write-Host ""
Write-Host "🔒 Security reminder:" -ForegroundColor Yellow
Write-Host "   - These certificates are NOT valid outside localhost" -ForegroundColor Yellow
Write-Host "   - Do NOT commit these files (see .gitignore)" -ForegroundColor Yellow
Write-Host "   - Regenerate if you change hostnames or IPs" -ForegroundColor Yellow
