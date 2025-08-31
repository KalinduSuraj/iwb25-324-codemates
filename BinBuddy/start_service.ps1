# BinBuddy Service Startup Script
# This script starts the unified BinBuddy service on port 8084

Write-Host "Starting BinBuddy Waste Management Service..."
Write-Host "Service will be available at: http://localhost:8084"
Write-Host ""

# Change to the BinBuddy directory
Set-Location -Path "d:\my\ballerina\iwb25-324-codemates\BinBuddy"

# Start the service
Write-Host "Compiling and starting service..."
bal run

# Keep the window open if there's an error
if ($LASTEXITCODE -ne 0) {
    Write-Host "Service failed to start. Press any key to exit..."
    Read-Host
}
