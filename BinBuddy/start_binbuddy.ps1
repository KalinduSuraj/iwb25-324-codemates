# BinBuddy Service Launcher
# This script ensures the service runs from the correct directory

Write-Host "🚀 Starting BinBuddy Waste Management System..." -ForegroundColor Green
Write-Host "📍 Navigating to project directory..." -ForegroundColor Yellow

# Change to the correct directory
Set-Location "d:\my\ballerina\iwb25-324-codemates\BinBuddy"

# Verify we're in the right place
if (Test-Path "Ballerina.toml") {
    Write-Host "✅ Found Ballerina.toml - correct directory!" -ForegroundColor Green
} else {
    Write-Host "❌ Ballerina.toml not found - check directory path" -ForegroundColor Red
    exit 1
}

# Start the service
Write-Host "🔧 Building and starting BinBuddy services..." -ForegroundColor Yellow
Write-Host "📡 Main service will be available at: http://localhost:8084" -ForegroundColor Cyan
Write-Host "🔍 Health check: http://localhost:8084/health" -ForegroundColor Cyan
Write-Host "" 
Write-Host "Press Ctrl+C to stop the service" -ForegroundColor Magenta
Write-Host "================================" -ForegroundColor Yellow

# Run the service
bal run
